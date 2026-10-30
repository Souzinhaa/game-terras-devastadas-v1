import { expect, test, type Page } from '@playwright/test';

async function fixture(page:Page,combat=false){
 await page.goto('/');
 await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 await page.evaluate(async combat=>{
  const gp='/src/engine/game.ts',sp='/src/application/saves.ts';
  const {createGame,transition}=await import(gp),{writeLocal}=await import(sp);
  const s=transition(createGame(['Ana','Bia'],42),{type:'start'}),p=s.players[s.active];
  for(const player of s.players)player.city='araras';
  const t=s.territories['araras-1'];delete t.hostile;t.owner=p.id;t.threat=null;t.stock.scrap=4;
  if(combat){
   const target=s.players.find((player:any)=>player.id!==p.id);target.vehicle.integrity=1;
   s.encounter={kind:'combat',actorId:p.id,defenderId:target.id,betweenRounds:false,lootResolved:false};s.rules.attackDamage=20;
   for(let seed=0;seed<10000;seed++){const n=(Math.imul(seed,1664525)+1013904223)>>>0;if(Math.floor(n/4294967296*6)+1===6){s.seed=seed;break;}}
  }
  await writeLocal(s);
 },combat);
 await page.reload();await page.getByRole('button',{name:'Estou pronto'}).click();
}

test('melhoria usa sucata dos depósitos e preserva a identidade da partida',async({page})=>{
 await fixture(page);
 await page.getByRole('button',{name:'Ações do turno',exact:true}).click();
 await page.getByRole('button',{name:'Cuidar do veículo',exact:false}).click();
 await expect(page.getByRole('button',{name:'Melhorar para SUV'})).toBeEnabled();
 await page.getByRole('button',{name:'Melhorar para SUV'}).click();
 await expect(page.locator('.mini-model')).toContainText('SUV');
 const saved=await page.evaluate(async()=>{const sp='/src/application/saves.ts';const {readLocal,decodeSave}=await import(sp);return decodeSave(await readLocal()).game;});
 expect(saved.players[saved.active].vehicle.modelId).toBe('suv');expect(saved.actions).toBe(0);expect(saved.territories['araras-1'].stock.scrap).toBe(0);
 await page.screenshot({path:'test-results/lifecycle-upgrade.png',fullPage:true});
});

test('resultado mostra vida zero antes do renascimento e penalidade bloqueia o próximo turno',async({page})=>{
 await fixture(page,true);
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();
 const attack=page.getByRole('dialog',{name:'Resultado do ataque'});await expect(attack).toBeVisible();
 await expect(attack.locator('.attack-participants article').nth(1).getByRole('meter')).toHaveAttribute('aria-valuenow','0');
 await attack.getByRole('button',{name:'Continuar'}).click();
 const death=page.getByRole('dialog',{name:'Carro destruído'});await expect(death).toBeVisible();await expect(death).toContainText('primeira destruição');
 await page.screenshot({path:'test-results/lifecycle-respawn.png',fullPage:true});
 await death.getByRole('button',{name:'Continuar'}).click();
 await expect(page.locator('.board-vehicles .vehicle-block-marker')).toHaveCount(1);
 await page.getByRole('button',{name:'Ações do turno',exact:true}).click();await page.getByRole('button',{name:'Encerrar turno',exact:true}).click();
 await page.getByRole('button',{name:'Estou pronto'}).click();await page.getByRole('button',{name:'Iniciar turno · comprar geral'}).click();
 await page.getByRole('button',{name:'Ações do turno',exact:true}).click();
 await expect(page.getByRole('button',{name:'Cuidar do veículo',exact:false})).toBeDisabled();await expect(page.getByRole('button',{name:'Comprar ou usar cartas',exact:false})).toBeDisabled();
 await expect(page.getByRole('button',{name:'Encerrar turno',exact:true})).toBeEnabled();
});

