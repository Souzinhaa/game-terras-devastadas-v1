import { expect, test } from '@playwright/test';

for(const width of [390,1280])test(`placar final mostra classificação, carros e itens em ${width}px`,async({page})=>{
 await page.setViewportSize({width,height:900});await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 const winner=await page.evaluate(async()=>{
  const gp='/src/engine/game.ts',sp='/src/application/saves.ts';const {createGame,makeVehicle}=await import(gp),{writeLocal}=await import(sp);
  const s=createGame(['Ana','Bia','Cris'],42),winner=s.players[0];s.finished=true;s.winner=winner.id;s.winnerReason='survival';s.turn=8;
  winner.vehicle=makeVehicle(s,'suv');winner.vehicle.fuelUnits=2;winner.stock.scrap=3;winner.stock.water=1;
  for(const [index,p] of s.players.entries())if(index){p.eliminated=true;p.deaths=2;p.vehicle.integrity=0;p.vehicle.fuelUnits=0;p.hand.forEach((card:any)=>s.cardState.discarded.general.push(card));p.hand=[];p.stock.scrap=0;p.eliminatedAtTurn=index===1?7:3;}
  for(const t of Object.values(s.territories) as any[])if(t.owner!==null&&t.owner!==winner.id)t.owner=null;
  const depot=Object.values(s.territories).find((t:any)=>t.owner===winner.id) as any;depot.stock.fuel=4;
  await writeLocal(s);return winner.name;
 });
 await page.reload();const result=page.getByRole('dialog',{name:'Placar final'});await expect(result).toBeVisible();await expect(result).toContainText(`${winner} venceu por sobrevivência.`);await expect(result.locator('.final-player')).toHaveCount(3);
 const first=result.locator('.final-player').first();await expect(first.locator('h3')).toHaveText(winner);await expect(first).toContainText('SUV');await expect(first.locator('.final-position')).toHaveText('1º');await expect(first.getByRole('img',{name:'SUV, vista de cima'})).toBeVisible();await expect(first).toContainText('Itens nos depósitos');await expect(first.locator('.final-resources img')).toHaveCount(3);
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 await page.screenshot({path:`test-results/final-standings-${width}.png`,animations:'disabled'});
 await result.getByRole('button',{name:'Voltar ao mapa'}).click();await expect(result).toHaveCount(0);
 await page.getByRole('button',{name:'Opções da partida'}).click();
 await page.getByRole('button',{name:'Ver placar final'}).click();await expect(page.getByRole('dialog',{name:'Placar final'})).toBeVisible();
});
