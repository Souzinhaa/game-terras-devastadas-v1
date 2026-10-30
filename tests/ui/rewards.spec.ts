import {expect,test} from '@playwright/test';
test('enemy defeat shows reward icons in a centered dialog',async({page})=>{
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async()=>{
  const gp='/src/engine/game.ts',hp='/src/engine/hostiles.ts',sp='/src/application/saves.ts';
  const {createGame,transition,makeVehicle}=await import(gp),{makeHostile}=await import(hp),{encodeSave}=await import(sp);
  let s=transition(createGame(['Ana','Bia'],42),{type:'start'});const p=s.players[s.active];p.city='araras';p.vehicle=makeVehicle(s,'pickup');p.stock.scrap=0;
  const t=s.territories['araras-1'];t.owner=null;t.hostile=makeHostile(s,'medium','territory',t.id);t.hostile.currentHealth=1;t.difficulty='medium';t.difficultyPending=false;
  const {hostileDefinition}=await import(hp);t.threat=hostileDefinition(t.hostile.definitionId).name;t.resistance=1;
  s=transition(s,{type:'conquer',territoryId:t.id});s.rules.attackDamage=20;
  for(let seed=1;seed<1000;seed++){const n=transition({...s,seed},{type:'attack'});if(!n.encounter){s.seed=seed;break;}}
  return encodeSave(s);
 });
 await page.locator('input[type=file]').setInputFiles({name:'reward.json',mimeType:'application/json',buffer:Buffer.from(raw)});
 await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();
 await page.getByRole('dialog',{name:'Rolagem de dados'}).getByRole('button',{name:'Continuar'}).click();
 const dialog=page.getByRole('dialog',{name:'Oponente derrotado'});await expect(dialog).toBeVisible();await expect(dialog).toContainText('morreu');const quantities=await dialog.locator('.reward-items strong').allTextContents();expect(quantities.reduce((sum,value)=>sum+Number(value),0)).toBeGreaterThanOrEqual(3);
 await expect(dialog.locator('.reward-items img').first()).toHaveAttribute('src',/sucata|combustivel/);
 await expect.poll(()=>dialog.locator('img').first().evaluate(el=>(el as HTMLImageElement).naturalWidth)).toBeGreaterThan(0);
 await dialog.getByRole('button',{name:'Continuar'}).click();await expect(dialog).toHaveCount(0);
});
