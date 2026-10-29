import manifest from '../data/catalog.json';
export type Deck = 'general' | 'improvements' | 'race' | 'events';
export type Effect =
 | { kind: 'roll'; scope: 'attack' | 'escape' | 'lootAttack' | 'lootDefense' | 'race'; amount: number }
 | { kind: 'damage'; amount: number } | { kind: 'reduceDamage'; amount: number }
 | { kind: 'resource'; resource: 'fuel' | 'scrap' | 'ammo' | 'tire' | 'battery' | 'water'; amount: number }
 | { kind: 'special'; code: string };
const effects: Record<string, Effect> = {
 G01:{kind:'roll',scope:'attack',amount:1},G02:{kind:'roll',scope:'attack',amount:-1},G03:{kind:'damage',amount:1},G04:{kind:'reduceDamage',amount:1},
 G05:{kind:'roll',scope:'escape',amount:1},G06:{kind:'roll',scope:'escape',amount:-1},G07:{kind:'roll',scope:'attack',amount:1},
 G09:{kind:'resource',resource:'fuel',amount:2},G11:{kind:'resource',resource:'scrap',amount:2},G12:{kind:'resource',resource:'ammo',amount:2},
 G13:{kind:'resource',resource:'tire',amount:1},G14:{kind:'resource',resource:'battery',amount:1},G24:{kind:'resource',resource:'water',amount:1},
 G19:{kind:'roll',scope:'lootAttack',amount:1},G20:{kind:'roll',scope:'lootDefense',amount:1},G21:{kind:'roll',scope:'race',amount:2},G22:{kind:'roll',scope:'race',amount:-2}
};
export const catalog = manifest.map(d => ({...d, deck: (d.id[0]==='G'?'general':d.id[0]==='E'||d.id[0]==='T'?'improvements':d.id[0]==='R'?'race':'events') as Deck,
 type: (d.id[0]==='G'?'general':d.id[0]==='E'?'equipment':d.id[0]==='T'?'territorial':d.id[0]==='R'?'race':'event') as 'general'|'equipment'|'territorial'|'race'|'event',
 unique:['E07','E08','E10','T05'].includes(d.id), effects:[effects[d.id] ?? {kind:'special',code:d.id} as Effect], description:d.rulesText, targetSelector:d.id, cost:0,
 imageUrl:`${import.meta.env.BASE_URL}assets/cards/${d.image}` }));
export const cardDefinition = (id: string) => catalog.find(d=>d.id===id || (id==='block'&&d.id==='G17') || (id==='unblock'&&d.id==='G18'));
export const tracks = [
 {id:'P01',name:'Araras–Limeira',distance:15,markers:[6,12],fee:3,scrap:3,improvements:1},
 {id:'P02',name:'Araras–Piracicaba',distance:21,markers:[7,14],fee:5,scrap:4,improvements:2},
 {id:'P03',name:'Rio Claro–Americana',distance:18,markers:[6,12],fee:4,scrap:3,improvements:2}
];
