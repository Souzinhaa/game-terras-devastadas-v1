import { expect, test } from '@playwright/test';

test('Moto usa o asset e tanque confirmado; mapa antigo restaurado',async({page})=>{
 await page.setViewportSize({width:1280,height:900});await page.goto('/');await expect(page.getByRole('button',{name:'Importar JSON'})).toBeEnabled();
 await page.evaluate(async()=>{
  const gp='/src/engine/game.ts',sp='/src/application/saves.ts';const {createGame,transition}=await import(gp),{writeLocal}=await import(sp);
  const s=transition(createGame(['Ana','Bia'],42),{type:'start'}),p=s.players[s.active];p.city='araras';const t=s.territories['araras-1'];delete t.hostile;t.threat=null;t.owner=p.id;t.stock.scrap=4;await writeLocal(s);
 });
 await page.reload();await page.getByRole('button',{name:'Estou pronto'}).click();await page.getByRole('button',{name:'Ações do turno',exact:true}).click();await page.getByRole('button',{name:'Cuidar do veículo',exact:false}).click();
 await page.getByRole('button',{name:'Melhorar para Moto'}).click();await expect(page.locator('.mini-model')).toContainText('Moto');await expect(page.locator('.mini-vehicle-hud')).toContainText('10/10');await expect(page.locator('.mini-vehicle-hud img')).toHaveAttribute('src',/moto-cima/);
 await page.getByRole('button',{name:'Mapa',exact:true}).click();
 const santa=page.locator('.city').filter({has:page.locator('strong',{hasText:'Santa Cruz da Conceição'})}),leme=page.locator('.city').filter({has:page.locator('strong',{hasText:/^Leme$/})});
 const santaBox=await santa.boundingBox(),lemeBox=await leme.boundingBox();expect(santaBox!.x).toBeGreaterThan(lemeBox!.x);
 const dimensions=await page.locator('.map').evaluate(async node=>{
  const url=getComputedStyle(node).backgroundImage.match(/url\(["']?([^"')]+)["']?\)/)![1];const image=new Image();image.src=url;await image.decode();return {url,width:image.naturalWidth,height:image.naturalHeight};
 });expect(dimensions.url).toContain('mapa-expandido-v2.png');expect(dimensions.width).toBe(1448);expect(dimensions.height).toBe(1086);
 for(let i=0;i<6;i++)await page.getByRole('button',{name:'Ampliar mapa'}).click();await expect(page.locator('.zoom-controls output')).toHaveText('250%');
 expect(await page.locator('.map').evaluate(node=>node.getBoundingClientRect().width)).toBeGreaterThan(4096);
 await page.screenshot({path:'test-results/moto-map-zoom.png',animations:'disabled'});
});
