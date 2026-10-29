import { expect, test } from '@playwright/test';
test('hostil específico mostra arte completa, atributos, efeito e vida em combate',async({page})=>{
 await page.setViewportSize({width:390,height:844});await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async()=>{
  const gamePath='/src/engine/game.ts',hostilePath='/src/engine/hostiles.ts',savePath='/src/application/saves.ts';
  const {createGame,transition,makeVehicle}=await import(gamePath),{makeHostile}=await import(hostilePath),{encodeSave}=await import(savePath);
  let s=transition(createGame(['Ana','Bia'],42),{type:'start'});const p=s.players[s.active];p.city='araras';p.vehicle=makeVehicle(s,'pickup');p.vehicle.fuelUnits=15;
  const t=s.territories['araras-1'];t.owner=null;t.difficulty='hard';t.difficultyPending=false;t.hostile=makeHostile(s,'hard','territory',t.id);t.hostile.definitionId='H12';t.hostile.currentHealth=9;t.threat='Sentinela da sucata';t.resistance=9;
  s=transition(s,{type:'conquer',territoryId:t.id});s.seed=1000;return encodeSave(s);
 });
 await page.locator('input[type=file]').setInputFiles({name:'hostil.json',mimeType:'application/json',buffer:Buffer.from(raw)});await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 const enemy=page.locator('.combatants article').nth(1);await expect(enemy).toContainText('Sentinela da sucata');await expect(enemy).toContainText('Defesa 3+');await expect(enemy).toContainText('Dano 2');await expect(enemy).toContainText('CHAPA FRONTAL');await expect(enemy.getByRole('meter')).toHaveAttribute('aria-valuemax','9');
 const art=enemy.locator('.hostile-art img');await expect.poll(()=>art.evaluate(el=>(el as HTMLImageElement).naturalWidth)).toBe(1024);expect(await art.evaluate(el=>getComputedStyle(el).objectFit)).toBe('contain');
 await enemy.getByRole('button',{name:'Ampliar hostil Sentinela da sucata'}).click();const zoom=page.getByRole('dialog',{name:'Sentinela da sucata'});await expect(zoom).toBeVisible();await expect(zoom.locator('img')).toHaveAttribute('src',/H12.png/);await page.screenshot({path:'test-results/hostil-zoom.png',animations:'disabled'});await zoom.getByRole('button',{name:'Fechar ampliação'}).click();
 await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(enemy.getByRole('meter')).toHaveAttribute('aria-valuenow','9');await page.getByRole('button',{name:'Resolver próximo ataque'}).click();await expect(page.locator('.combatants article').first().getByRole('meter')).toHaveAttribute('aria-valuenow','8');expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);await page.screenshot({path:'test-results/hostil-combate.png',animations:'disabled'});
});
test('catálogo permite consultar as doze artes sem mudar a partida',async({page})=>{
 await page.goto('/');await page.getByRole('button',{name:'Sortear e iniciar'}).click();await page.getByRole('button',{name:'Estou pronto'}).click();await page.locator('.city.current').click();await page.getByText('Consultar os 12 hostis',{exact:true}).click();const catalog=page.locator('.hostile-catalog');await expect(catalog.locator('.catalog-card')).toHaveCount(12);await expect(catalog.getByText('Brutamontes blindado',{exact:true})).toBeVisible();await expect(page.getByRole('button',{name:'Iniciar turno · comprar geral'})).toBeEnabled();
});
