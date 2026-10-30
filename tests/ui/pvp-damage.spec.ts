import { expect, test, type Page } from '@playwright/test';

async function loadDuel(page:Page,reply=false,shield=false){
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const ids=await page.evaluate(async({reply,shield})=>{
  const gp='/src/engine/game.ts',sp='/src/application/saves.ts';const {createGame,transition}=await import(gp),{writeLocal}=await import(sp);
  const s=transition(createGame(['Ana','Bia'],42),{type:'start'}),owner=s.players[s.active],other=s.players.find((p:any)=>p.id!==owner.id);
  for(const p of s.players)p.city='araras';const attacker=reply?other:owner,target=reply?owner:other;
  s.encounter={kind:'combat',actorId:attacker.id,defenderId:other.id,betweenRounds:false,lootResolved:false};
  if(shield)s.cardState.pending.push({playerId:target.id,effect:'reduceDamage',amount:1});
  for(let seed=0;seed<10000;seed++){const n=(Math.imul(seed,1664525)+1013904223)>>>0;if(Math.floor(n/4294967296*6)+1===5){s.seed=seed;break;}}
  await writeLocal(s);return {attacker:attacker.id,target:target.id,targetName:target.name};
 },{reply,shield});
 await page.reload();await page.getByRole('button',{name:'Estou pronto'}).click();return ids;
}

for(const reply of [false,true])test(`acerto reduz a vida no resultado e no save (${reply?'resposta do defensor':'primeiro ataque'})`,async({page})=>{
 const ids=await loadDuel(page,reply);
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();const result=page.getByRole('dialog',{name:'Resultado do ataque'});
 const target=result.locator('.attack-participants article').nth(1).getByRole('meter');
 await expect(target).toHaveAttribute('aria-valuenow','6');await expect(target).toHaveAttribute('aria-valuenow','5');
 await expect(result).toContainText('Total 5 · Defesa 4+');await expect(result.locator('.attack-health-change')).toContainText('6 → 5');await expect(result).toContainText('perdeu 1 de vida.');
 const actual=await page.evaluate(async id=>{const sp='/src/application/saves.ts';const {readLocal,decodeSave}=await import(sp);return decodeSave(await readLocal()).game.players.find((p:any)=>p.id===id).vehicle.integrity;},ids.target);expect(actual).toBe(5);
 await result.getByRole('button',{name:'Continuar'}).click();await expect(page.getByRole('button',{name:'Estou pronto'})).toBeVisible();
});

test('acerto absorvido não anuncia perda de vida',async({page})=>{
 await loadDuel(page,false,true);await page.getByRole('button',{name:'Resolver próximo ataque'}).click();const result=page.getByRole('dialog',{name:'Resultado do ataque'});
 await expect(result).toContainText('Acerto absorvido');await expect(result.locator('.attack-health-change')).toContainText('6 → 6');await expect(result).toContainText('Escudo ou redução absorveu 1 de dano.');await expect(result).toContainText('Nenhum dano causado.');
 await expect(result.locator('.attack-participants article').nth(1).getByRole('meter')).toHaveAttribute('aria-valuenow','6');
});
