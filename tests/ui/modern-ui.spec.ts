import { expect, test } from '@playwright/test';

for(const viewport of [{width:320,height:700},{width:1024,height:768}])test(`HUD e menu acessíveis em ${viewport.width}×${viewport.height}`,async({page})=>{
 await page.setViewportSize(viewport);await page.goto('/');await page.getByLabel('Jogadores').selectOption('4');
 await page.getByRole('button',{name:'Sortear e iniciar'}).click();await page.getByRole('button',{name:'Estou pronto'}).click();
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 await expect(page.getByRole('navigation',{name:'Navegar pelo jogo'}).getByRole('button')).toHaveText(['Mapa','Inventário']);
 const boxes=await page.locator('.turn-strip,.turn-guide,.players-strip,.mini-vehicle-hud,.game-navigation').evaluateAll(nodes=>nodes.map(el=>{const r=el.getBoundingClientRect();return {left:r.left,right:r.right,top:r.top,bottom:r.bottom};}));
 for(let a=0;a<boxes.length;a++)for(let b=a+1;b<boxes.length;b++){const x=boxes[a],y=boxes[b];expect(x.right<=y.left||y.right<=x.left||x.bottom<=y.top||y.bottom<=x.top).toBe(true);}
 const menu=page.getByRole('button',{name:'Opções da partida'});await menu.click();await expect(menu).toHaveAttribute('aria-expanded','true');await expect(page.getByRole('button',{name:'Exportar save'})).toBeVisible();
 await page.keyboard.press('Escape');await expect(menu).toHaveAttribute('aria-expanded','false');await expect(page.getByRole('button',{name:'Exportar save'})).toBeHidden();
 if(viewport.width===320){await expect.poll(async()=>{const targets=await page.locator('.game-navigation button,.turn-strip>.primary,.session-menu-trigger').evaluateAll(nodes=>nodes.map(el=>({w:el.getBoundingClientRect().width,h:el.getBoundingClientRect().height})));return targets.every(v=>v.w>=44&&v.h>=44);}).toBe(true);}
 await page.screenshot({path:`test-results/hud-${viewport.width}.png`,animations:'disabled'});
});
