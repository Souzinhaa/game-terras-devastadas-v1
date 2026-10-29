import { expect, test, type Page } from '@playwright/test';
async function loadCombat(page:Page,life=4,event=false,playerLife?:number){
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async({life,event,playerLife})=>{
  const enginePath='/src/engine/game.ts',savePath='/src/application/saves.ts';const {createGame}=await import(enginePath),{encodeSave}=await import(savePath);
  const s=createGame(['Ana','Bia'],42),p=s.players[s.active];p.city='araras';if(playerLife!==undefined)p.vehicle.integrity=playerLife;s.started=true;s.actions=0;s.seed=1000;
  const t=s.territories['araras-1'];delete t.hostile;t.owner=null;t.threat='Sobreviventes hostis';t.resistance=life;
  s.encounter={kind:'combat',actorId:p.id,betweenRounds:false,lootResolved:false,...event?{eventIntegrity:life}:{territoryId:t.id}};return encodeSave(s);
 },{life,event,playerLife});
 await page.locator('input[type=file]').setInputFiles({name:'vida.json',mimeType:'application/json',buffer:Buffer.from(raw)});await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
}
test('barras e animação identificam somente quem recebeu dano',async({page})=>{
 await loadCombat(page);const participants=page.locator('.combatants article');
 await expect(participants.nth(1).getByRole('meter')).toHaveAttribute('aria-valuenow','4');await expect(participants.nth(1).getByRole('meter')).toHaveAttribute('aria-valuemax','4');await expect(page.locator('.combatants .is-damaged')).toHaveCount(0);
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(participants.nth(1).getByRole('meter')).toHaveAttribute('aria-valuenow','3');await expect(participants.nth(1).locator('.health-loss')).toHaveText('−1 de vida');await expect(participants.nth(0).locator('.health-loss')).toHaveCount(0);
 await page.screenshot({path:'test-results/vida-dano.png',animations:'disabled'});
 await expect(participants.nth(1).locator('.health-loss')).toHaveCount(0);
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(participants.nth(0).getByRole('meter')).toHaveAttribute('aria-valuenow','7');await expect(participants.nth(0).locator('.health-loss')).toHaveText('−1 de vida');await expect(participants.nth(1).locator('.health-loss')).toHaveCount(0);
 await expect(page.locator('.action-receipt')).toContainText('Ana perdeu 1 de vida');
});
test('golpe final continua informando a perda de vida quando o combate termina',async({page})=>{
 await loadCombat(page,1);await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(page.locator('.combatants')).toHaveCount(0);await expect(page.locator('.action-receipt')).toContainText('Sobreviventes hostis: −1 de vida');
});
test('carregar participantes feridos mostra a vida atual sem fingir um novo dano',async({page})=>{
 await loadCombat(page,3,false,5);const participants=page.locator('.combatants article');await expect(participants.nth(0).getByRole('meter')).toHaveAttribute('aria-valuenow','5');await expect(participants.nth(1).getByRole('meter')).toHaveAttribute('aria-valuenow','3');await expect(page.locator('.combatants .health-loss')).toHaveCount(0);await expect(page.locator('.combatants .is-damaged')).toHaveCount(0);
});
test('derrota contra evento não informa dano falso ao inimigo',async({page})=>{
 await loadCombat(page,2,true,1);await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(page.locator('.combatants')).toHaveCount(0);await expect(page.locator('.action-receipt')).toContainText('Ana perdeu 1 de vida');await expect(page.locator('.action-receipt')).not.toContainText('Saqueadores');
});
test('redução de movimento mantém a indicação de dano sem tremor',async({page})=>{
 await page.emulateMedia({reducedMotion:'reduce'});await loadCombat(page);await page.getByRole('button',{name:'Resolver próximo ataque'}).click();const damaged=page.locator('.combatants article').nth(1);await expect(damaged.locator('.health-loss')).toHaveText('−1 de vida');expect(await damaged.evaluate(el=>getComputedStyle(el).animationName)).toBe('none');expect(await damaged.locator('.health-fill').evaluate(el=>getComputedStyle(el).transitionDuration)).toBe('0s');
});
