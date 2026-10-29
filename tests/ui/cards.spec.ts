import { expect, test } from '@playwright/test';
test('preparar carta revela somente os alvos necessários e permite jogar',async({page})=>{
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async()=>{
  const enginePath='/src/engine/game.ts',savePath='/src/application/saves.ts';
  const {createGame}=await import(enginePath),{encodeSave}=await import(savePath);
  const s=createGame(['Ana','Bia'],42),p=s.players[s.active];s.started=true;p.vehicle.fuelUnits=0;
  const deck=s.cardState.decks.general,index=deck.findIndex((c:{definitionId:string})=>c.definitionId==='G09');p.hand.push(deck.splice(index,1)[0]);return encodeSave(s);
 });
 await page.locator('input[type=file]').setInputFiles({name:'alvo.json',mimeType:'application/json',buffer:Buffer.from(raw)});
 await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 await page.getByRole('navigation',{name:'Navegar pelo jogo'}).getByRole('button',{name:'Inventário',exact:true}).click();await page.getByRole('group',{name:'Inventário',exact:true}).getByRole('button',{name:'Cartas',exact:true}).click();await page.getByRole('button',{name:'Revelar',exact:true}).click();
 await expect(page.getByLabel('Jogador alvo',{exact:true})).toHaveCount(0);
 await page.locator('.hand-card').filter({has:page.getByText('Combustível de emergência',{exact:true})}).getByRole('button',{name:'Preparar',exact:true}).click();
 const composer=page.getByRole('region',{name:'Preparar Combustível de emergência'});await expect(composer).toBeVisible();await expect(composer.getByLabel('Jogador alvo')).toBeVisible();await expect(composer.getByLabel('Ligação alvo')).toHaveCount(0);
 await page.screenshot({path:'test-results/cards-redesign.png',animations:'disabled'});
 await composer.getByRole('button',{name:'Usar carta',exact:true}).click();await expect(composer).toHaveCount(0);await expect(page.locator('.mini-vehicle-hud>span').nth(1)).toContainText('2/');
});
for(const purchase of ['general','improvement'] as const)test(`compra de ${purchase} mostra a arte automaticamente`,async({page})=>{
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async(purchase)=>{
  const enginePath='/src/engine/game.ts',savePath='/src/application/saves.ts';
  const {createGame,makeVehicle}=await import(enginePath),{encodeSave}=await import(savePath);
  const state=createGame(['Ana','Bia'],42),p=state.players[state.active];
  p.vehicle=makeVehicle(state,'pickup');p.stock.scrap=3;state.started=purchase==='improvement';
  return encodeSave(state);
 },purchase);
 await page.locator('input[type=file]').setInputFiles({name:'compra.json',mimeType:'application/json',buffer:Buffer.from(raw)});
 await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 if(purchase==='general')await page.getByRole('button',{name:'Iniciar turno · comprar geral'}).click();
 else{
  await page.getByRole('navigation',{name:'Navegar pelo jogo'}).getByRole('button',{name:'Inventário',exact:true}).click();await page.getByRole('group',{name:'Inventário',exact:true}).getByRole('button',{name:'Cartas',exact:true}).click();
  await page.getByRole('button',{name:'Revelar',exact:true}).click();
  await page.getByRole('button',{name:'Comprar melhoria · 3 sucatas · uma por turno'}).click();
 }
 const popup=page.getByRole('dialog',{name:'Cartas recebidas'});await expect(popup).toBeVisible();
 await expect(popup.locator('img')).toHaveCount(0);await expect(popup.getByRole('button',{name:'Guardar carta'})).toHaveCount(0);
 await page.keyboard.press('Escape');await expect(popup).toBeVisible();
 await page.screenshot({path:`test-results/purchase-back-${purchase}.png`,animations:'disabled'});
 await page.getByRole('button',{name:'Virar carta',exact:true}).click();await expect(popup.locator('.draw-flip')).toHaveClass(/is-revealed/);
 expect(await popup.locator('.draw-flip-rotor').evaluate(el=>getComputedStyle(el).transitionProperty)).toContain('transform');
 const art=popup.locator('img');await expect(art).toBeVisible();await expect.poll(()=>art.evaluate(el=>(el as HTMLImageElement).naturalWidth)).toBe(1024);
 expect(await art.evaluate(el=>getComputedStyle(el).objectFit)).toBe('contain');
 await page.getByRole('button',{name:'Guardar carta',exact:true}).click();await expect(popup).toHaveCount(0);
 await expect(page.getByRole('status').first()).toHaveText('Salvo neste navegador');
});

test('várias cartas são reveladas uma de cada vez, sempre pelo mesmo verso',async({page})=>{
 await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const raw=await page.evaluate(async()=>{
  const enginePath='/src/engine/game.ts',savePath='/src/application/saves.ts';const {createGame}=await import(enginePath),{encodeSave}=await import(savePath);
  const s=createGame(['Ana','Bia'],42);s.started=true;const p=s.players[s.active],other=s.players.find((v:{id:number})=>v.id!==p.id);other.vehicle.integrity=0;
  s.cardState.race={trackId:'P03',phase:'running',responses:[p.id,other.id],entrants:[{playerId:p.id,progress:30,markers:[6,12],next:0},{playerId:other.id,progress:0,markers:[],next:0}],cursor:1,finalRound:true};return encodeSave(s);
 });
 await page.locator('input[type=file]').setInputFiles({name:'premio.json',mimeType:'application/json',buffer:Buffer.from(raw)});await page.getByRole('button',{name:'Confirmar',exact:true}).click();await page.getByRole('button',{name:'Estou pronto'}).click();await page.getByRole('button',{name:'Rolar avanço'}).click();
 const popup=page.getByRole('dialog',{name:'Cartas recebidas'});await expect(popup.getByText('Carta 1 de 2')).toBeVisible();await expect(popup.locator('img')).toHaveCount(0);
 const back=await popup.locator('.draw-flip-back').innerText();await popup.getByRole('button',{name:'Virar carta',exact:true}).press('Enter');await popup.getByRole('button',{name:'Próxima carta',exact:true}).click();
 await expect(popup.getByText('Carta 2 de 2')).toBeVisible();await expect(popup.locator('img')).toHaveCount(0);expect(await popup.locator('.draw-flip-back').innerText()).toBe(back);
 await popup.getByRole('button',{name:'Virar carta',exact:true}).click();await popup.getByRole('button',{name:'Guardar carta',exact:true}).click();await expect(popup).toHaveCount(0);
});
test('cartas completas carregam sem corte, ampliam e mantêm privacidade entre jogadores',async({page})=>{
 await page.setViewportSize({width:390,height:844});
 await page.goto('/');await page.getByRole('button',{name:'Sortear e iniciar'}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 await page.getByRole('navigation',{name:'Navegar pelo jogo'}).getByRole('button',{name:'Inventário',exact:true}).click();await page.getByRole('group',{name:'Inventário',exact:true}).getByRole('button',{name:'Cartas',exact:true}).click();
 await page.getByRole('button',{name:'Revelar',exact:true}).click();
 const art=page.locator('.hand-card .card-art').first();await art.scrollIntoViewIfNeeded();
 const img=art.locator('img');await expect(img).toBeVisible();await expect.poll(()=>img.evaluate(el=>(el as HTMLImageElement).naturalWidth)).toBe(1024);
 expect(await img.evaluate(el=>getComputedStyle(el).objectFit)).toBe('contain');
 await art.click();await expect(page.locator('dialog[open]')).toHaveCount(1);await expect(page.locator('dialog[open] img')).toBeVisible();
 await page.screenshot({path:'test-results/card-zoom-mobile.png',animations:'disabled'});
 await page.getByRole('button',{name:'Fechar ampliação'}).click();await expect(page.locator('dialog[open]')).toHaveCount(0);
 const select=page.getByLabel('Mão do jogador',{exact:true});const values=await select.locator('option').evaluateAll(nodes=>nodes.map(n=>(n as HTMLOptionElement).value));await select.selectOption(values.find(v=>v!==values[0])!);
 await expect(page.locator('.hand-card')).toHaveCount(0);expect(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth)).toBe(true);
});
