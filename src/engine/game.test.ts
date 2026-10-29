import { describe, expect, it } from 'vitest';
import { assertInvariants, capacityIssues, cities, cityTerritories, createGame, emptyStock, load, makeVehicle, model, points, routeReason, routes, transition, travelCost, vehicles, type Game, type ModelId } from './game';
import { decodeSave, encodeSave } from '../application/saves';
const setup = (id: ModelId = 'suv', seed = 42) => {
 let s = createGame(['Ana','Bia'],seed); s = transition(s,{type:'start'});
 // These regressions deliberately exercise legacy generic opponents. Hostile instances have their own suite.
 for(const t of Object.values(s.territories))delete t.hostile;
 const p=s.players[s.active]; p.city='araras'; p.vehicle=makeVehicle(s,id); p.vehicle.fuelUnits=model(p).tank;
 s.players[1].city='americana'; s.territories['araras-1'].owner=p.id; s.territories['araras-1'].threat=null;
 return s;
};
const active = (s: Game) => s.players[s.active];
const snapshotFailure = (s: Game, action: Parameters<typeof transition>[1], message?: string) => { const copy=structuredClone(s); expect(()=>transition(s,action)).toThrow(message); expect(s).toEqual(copy); };
function legacy(s: Game, unit: 'whole'|'half'='whole') {
 const envelope=JSON.parse(encodeSave(s)); envelope.schemaVersion=3; envelope.contentVersion='0.3.0'; envelope.state.schemaVersion=3; envelope.state.contentVersion='0.3.0'; envelope.fuelUnit=unit;
 if(unit==='half') { for(const p of envelope.state.players) {p.vehicle.fuelUnits*=2;p.stock.fuel*=2;} for(const t of Object.values(envelope.state.territories) as {stock:{fuel:number}}[]) t.stock.fuel*=2; for(const f of envelope.state.found) f.vehicle.fuelUnits*=2; }
 return envelope;
}
describe('conteúdo confirmado v0.4',()=>{
 it('tem quatro modelos com capacidades, tanque, consumo e superfícies exatos',()=>{
  expect(vehicles.map(v=>[v.id,v.capacity,v.tank,v.consumption,v.allowedSurfaces,v.additionalSlots])).toEqual([
   ['hatch',1,8,1,['paved'],2],['sedan',7,12,2,['paved'],2],['suv',6,12,2,['paved','rural'],2],['pickup',10,15,3,['paved','rural'],2]
  ]);
 });
 it('35 setores, 12 cidades, 8 pontos, IDs únicos e duas arestas Araras–Rio Claro',()=>{
  const s=createGame(['A','B'],42); expect(cities).toHaveLength(12); expect(Object.keys(s.territories)).toHaveLength(35);
  expect(cities.reduce((n,c)=>n+(c.regions>=4?1:.5),0)).toBe(8);
  expect(new Set(routes.map(r=>r.id)).size).toBe(routes.length);
  expect(routes.filter(r=>[r.from,r.to].includes('araras')&&[r.from,r.to].includes('rio-claro'))).toHaveLength(2);
  const seen=new Set(['araras']); for(let i=0;i<12;i++) for(const r of routes.filter(r=>r.terrain==='paved')) if(seen.has(r.from)||seen.has(r.to)){seen.add(r.from);seen.add(r.to);} expect(seen.size).toBe(12);
 });
 it('novas partidas têm tanque cheio, 1 sucata, fixo, 2 gerais e zero adicional; sorteio alcança quatro classes',()=>{
  const seen=new Set<string>();
  for(let seed=0;seed<60;seed++) { const s=createGame(['A','B','C','D'],seed); expect(s.started).toBe(false); const starts=new Set<string>();
   for(const p of s.players){seen.add(p.vehicle.modelId);starts.add(p.city);expect(p.vehicle.fuelUnits).toBe(model(p).tank);expect(p.stock).toEqual({...emptyStock(),scrap:1});expect(p.hand).toHaveLength(2);expect(p.hand.every(c=>c.type==='general')).toBe(true);expect(p.vehicle.installed).toEqual([]);expect(p.vehicle.fixedEquipmentId).toBe(model(p).fixedEquipmentId);expect(cityTerritories(s,p.city).filter(t=>t.owner===p.id)).toHaveLength(1);}
   expect(starts.size).toBe(4);assertInvariants(s);
  }expect(seen).toEqual(new Set(['hatch','sedan','suv','pickup']));
 });
 it('mesma seed reproduz ordem, IDs e ameaças sem alterar original',()=>{expect(createGame(['A','B'],72)).toEqual(createGame(['A','B'],72));const s=setup();const before=structuredClone(s);transition(s,{type:'move',route:'araras-leme'});expect(s).toEqual(before);});
});
describe('viagem, tanque e turno',()=>{
 it.each(['hatch','sedan','suv','pickup'] as ModelId[])('%s paga custo fixo mesmo cheio; viajar mantém ação principal',id=>{
  const s=setup(id),p=active(s);p.stock.scrap=model(p).capacity;const cost=model(p).consumption;
  expect(travelCost(s,'araras-leme')).toBe(cost);const next=transition(s,{type:'move',route:'araras-leme'});expect(active(next).vehicle.fuelUnits).toBe(p.vehicle.fuelUnits-cost);expect(active(next).city).toBe('leme');expect(next.actions).toBe(1);expect(next.moved).toBe(true);expect(next.log.join()).toContain('Evento:');snapshotFailure(next,{type:'move',route:'araras-leme'},'uma vez');
  const local=cityTerritories(next,'leme').find(t=>t.owner===null)!;expect(transition(next,{type:'conquer',territoryId:local.id}).actions).toBe(0);
 });
 it.each(['suv','pickup'] as ModelId[])('%s usa terra sem adicionais por superfície ou carga',id=>{const s=setup(id);active(s).stock.scrap=model(active(s)).capacity;const n=transition(s,{type:'move',route:'araras-artur-nogueira-terra'});expect(active(n).vehicle.fuelUnits).toBe(model(active(s)).tank-model(active(s)).consumption);});
 it.each(['hatch','sedan'] as ModelId[])('%s não pode usar terra',id=>snapshotFailure(setup(id),{type:'move',route:'araras-artur-nogueira-terra'},'somente SUV'));
 it('insuficiência de combustível e rota remota não alteram estado ou RNG',()=>{const s=setup('pickup');active(s).vehicle.fuelUnits=2;snapshotFailure(s,{type:'move',route:'araras-leme'},'insuficiente');snapshotFailure(s,{type:'move',route:'limeira-americana'},'adjacente');});
 it.each(['hatch','sedan','suv','pickup'] as ModelId[])('%s não abastece acima do tanque e combustível não ocupa carga',id=>{const s=setup(id);active(s).stock={...emptyStock(),fuel:1};snapshotFailure(s,{type:'refuel',quantity:1},'tanque');active(s).vehicle.fuelUnits--;const n=transition(s,{type:'refuel',quantity:1});expect(active(n).vehicle.fuelUnits).toBe(model(active(s)).tank);expect(load(active(n))).toBe(0);});
 it('depósito livre em todos os setores próprios locais; segunda unidade no hatch exige escolha',()=>{
  let s=setup('hatch'); const p=active(s);s.territories['araras-2'].owner=p.id;s.territories['araras-2'].stock.water=1;
  s=transition(s,{type:'transfer',territoryId:'araras-2',resource:'water',quantity:1,direction:'withdraw'});expect(load(active(s))).toBe(2);expect(capacityIssues(s)).not.toEqual([]);expect(s.actions).toBe(1);expect(active(s).vehicle.fuelUnits).toBe(8);
  snapshotFailure(s,{type:'end'},'excedentes');s=transition(s,{type:'transfer',territoryId:'araras-1',resource:'scrap',quantity:1,direction:'deposit'});expect(capacityIssues(s)).toEqual([]);expect(s.territories['araras-1'].stock.scrap).toBe(1);
 });
 it('compra geral uma vez no início, não no combate; inventário não consome água por turno',()=>{let s=createGame(['A','B'],4);expect(active(s).hand).toHaveLength(2);s=transition(s,{type:'start'});expect(active(s).hand).toHaveLength(3);snapshotFailure(s,{type:'start'},'já iniciado');const before=active(s).stock.water;s=transition(s,{type:'end'});expect(s.started).toBe(false);expect(s.players.find(p=>p.id===active(createGame(['A','B'],4)).id)!.stock.water).toBe(before);});
});
describe('bloqueios por carta',()=>{
 function scenario(id:ModelId){const s=setup(id);active(s).city='artur-nogueira';active(s).hand[0].definitionId='block';s.blocks=[{routeId:'conchal-artur-nogueira',by:s.players[1].id}];return s;}
 it.each(['suv','pickup'] as ModelId[])('terra é saída compatível para %s, mesmo sem combustível',id=>{const s=scenario(id);active(s).vehicle.fuelUnits=0;const n=transition(s,{type:'playGeneral',cardId:active(s).hand[0].id,route:'artur-nogueira-limeira'});expect(n.blocks).toHaveLength(2);expect(routeReason(n,active(n),'araras-artur-nogueira-terra',false)).toBeNull();});
 it.each(['hatch','sedan'] as ModelId[])('não considera terra como saída de %s',id=>{const s=scenario(id);snapshotFailure(s,{type:'playGeneral',cardId:active(s).hand[0].id,route:'artur-nogueira-limeira'},'sem saída');});
 it('avalia bloqueios acumulados, bidirecionalidade e expira no próximo início do autor',()=>{
  let s=scenario('pickup');s=transition(s,{type:'playGeneral',cardId:active(s).hand[0].id,route:'artur-nogueira-limeira'});const by=active(s).id;active(s).city='limeira';expect(routeReason(s,active(s),'artur-nogueira-limeira')).toContain('dois sentidos');
  s=transition(s,{type:'end'});s=transition(s,{type:'start'});expect(s.blocks.some(b=>b.by===by)).toBe(true);s=transition(s,{type:'end'});s=transition(s,{type:'start'});expect(s.blocks.some(b=>b.by===by)).toBe(false);
 });
});
describe('fuga e recuperação',()=>{
 function encounter(id:ModelId,pvp=true){const s=setup(id);s.rules.escapeTarget=1;s.players[1].city='araras';s.encounter={kind:'combat',actorId:active(s).id,betweenRounds:true,lootResolved:false,...(pvp?{defenderId:s.players[1].id}:{territoryId:'araras-2'})};return s;}
 it.each(['suv','pickup'] as ModelId[])('%s foge por terra pagando custo fixo sem novo evento',id=>{const s=encounter(id);active(s).vehicle.installed=['opaque-equipment'];const hand=active(s).hand.length;const n=transition(s,{type:'escape',route:'araras-artur-nogueira-terra',playerId:active(s).id});expect(active(n).city).toBe('artur-nogueira');expect(active(n).vehicle.fuelUnits).toBe(model(active(s)).tank-model(active(s)).consumption);expect(active(n).hand).toHaveLength(hand-1);expect(active(n).vehicle.installed).toEqual(['opaque-equipment']);expect(n.encounter).toBeNull();expect(n.log.join()).not.toContain('Evento:');});
 it('exige carta PvP, combustível, terreno e rota legal antes da rolagem',()=>{const s=encounter('pickup');active(s).hand=[];snapshotFailure(s,{type:'escape',route:'araras-artur-nogueira-terra',playerId:active(s).id},'carta');active(s).hand.push({id:'escape-card',definitionId:'block',type:'general'});active(s).vehicle.fuelUnits=2;snapshotFailure(s,{type:'escape',route:'araras-artur-nogueira-terra',playerId:active(s).id},'insuficiente');const hatch=encounter('hatch');snapshotFailure(hatch,{type:'escape',route:'araras-artur-nogueira-terra',playerId:active(hatch).id},'somente SUV');});
 it('contra ameaça dispensa carta e não cura danos territoriais na retirada',()=>{const s=encounter('suv',false);active(s).hand=[];s.territories['araras-2'].resistance=1;const n=transition(s,{type:'escape',route:'araras-leme',playerId:active(s).id});expect(n.territories['araras-2'].resistance).toBe(1);});
 it('simples não reativa carro zero; complexo recupera sem mudar posição',()=>{const s=setup();active(s).vehicle.integrity=0;active(s).stock.scrap=2;snapshotFailure(s,{type:'repair',complex:false},'não reativa');const n=transition(s,{type:'repair',complex:true});expect(active(n).vehicle.integrity).toBe(4);expect(active(n).city).toBe('araras');expect(n.actions).toBe(0);});
});
describe('troca, descoberta e domínio',()=>{
 it('troca local preserva combustível, carga, cartas e fixo novo; excedentes não somem',()=>{
  const s=setup('pickup'),p=active(s);p.vehicle.fuelUnits=11;p.vehicle.installed=['upgrade'];p.stock.scrap=5;
  const found=makeVehicle(s,'hatch');found.fuelUnits=1;s.found.push({city:p.city,vehicle:found,repairedOnTurn:null});const n=transition(s,{type:'swap',vehicleId:found.id});
  expect(active(n).vehicle.fuelUnits).toBe(12);expect(active(n).stock.scrap).toBe(5);expect(active(n).hand).toEqual(p.hand);expect(active(n).vehicle.installed).toEqual([]);expect(active(n).vehicle.fixedEquipmentId).toBe('fixed-hatch');expect(n.localScrap.araras).toBe(3);expect(capacityIssues(n)).toHaveLength(2);snapshotFailure(n,{type:'end'},'excedentes');
 });
 it('impede troca remota ou no mesmo turno de reparar encontrado',()=>{const s=setup();const f=makeVehicle(s,'pickup');s.found.push({city:'limeira',vehicle:f,repairedOnTurn:null});snapshotFailure(s,{type:'swap',vehicleId:f.id},'local');s.found[0].city='araras';s.found[0].repairedOnTurn=s.turn;snapshotFailure(s,{type:'swap',vehicleId:f.id},'separado');});
 it('conquista sem loot automático, restaura defesa; exploração é separada',()=>{
  let s=setup('pickup');const id='araras-2';s.territories[id].owner=null;s.territories[id].resistance=1;s.rules.attackDamage=10;s.seed=1000;
  s=transition(s,{type:'conquer',territoryId:id});for(let i=0;s.encounter&&i<100;i++)s=transition(s,{type:'attack'});
  expect(s.territories[id].owner).toBe(active(s).id);expect(s.territories[id].resistance).toBe(s.rules.territoryIntegrity);expect(s.territories[id].stock).toEqual(emptyStock());expect(s.territories[id].explorations).toBe(0);
  s.actions=1;const n=transition(s,{type:'explore',territoryId:id});expect(n.territories[id].explorations).toBe(1);expect(active(n).stock).toEqual(active(s).stock);expect(Object.values(n.territories[id].stock).reduce((a,b)=>a+b)).toBe(2);
 });
 it('pontos exigem todos os setores simultâneos',()=>{const s=setup();for(const t of Object.values(s.territories))t.owner=null;const id=active(s).id;s.territories['araras-1'].owner=id;expect(points(s,id)).toBe(0);for(const t of cityTerritories(s,'araras'))t.owner=id;expect(points(s,id)).toBe(.5);s.territories['araras-3'].owner=null;expect(points(s,id)).toBe(0);});
});
describe('save/load e migração sem perdas silenciosas',()=>{
 it.each(['hatch','sedan','suv','pickup'] as ModelId[])('carrega %s com tanque vazio sem aplicar kit inicial',id=>{const s=setup(id);active(s).vehicle.fuelUnits=0;active(s).stock=emptyStock();const loaded=decodeSave(encodeSave(s)).game;expect(active(loaded).vehicle.fuelUnits).toBe(0);expect(active(loaded).stock).toEqual(emptyStock());expect(active(loaded).hand).toEqual(active(s).hand);});
 it('round-trip conserva RNG, equipamentos, inteiros, posição, bloqueios e estado pendente',()=>{
  const s=setup('pickup');active(s).vehicle.fuelUnits=4;active(s).vehicle.installed=['armor'];active(s).stock.water=2;s.blocks.push({routeId:'araras-rio-claro',by:active(s).id});
  const n=decodeSave(encodeSave(s)).game;expect(n).toEqual(s);expect(transition(n,{type:'move',route:'araras-leme'})).toEqual(transition(s,{type:'move',route:'araras-leme'}));
 });
 it('converte ticks de meia unidade somente por schema explícito e não completa tanque',()=>{const s=setup('pickup');active(s).vehicle.fuelUnits=4;active(s).stock.fuel=2;const raw=JSON.stringify(legacy(s,'half'));const n=decodeSave(raw).game;expect(active(n).vehicle.fuelUnits).toBe(4);expect(active(n).stock.fuel).toBe(2);expect(n.seed).toBe(s.seed);expect(n.players.map(p=>p.vehicle.id)).toEqual(s.players.map(p=>p.vehicle.id));expect(JSON.stringify(JSON.parse(raw))).toBe(raw);});
 it('migra excesso de tanque/carga intacto para escolha; nunca reaplica o kit',()=>{const s=setup('hatch');active(s).vehicle.fuelUnits=10;active(s).stock.scrap=3;const n=decodeSave(JSON.stringify(legacy(s))).game;expect(active(n).vehicle.fuelUnits).toBe(10);expect(active(n).stock.scrap).toBe(3);expect(capacityIssues(n)).toHaveLength(2);snapshotFailure(n,{type:'end'},'excedentes');const resolved=transition(n,{type:'discard',resource:'scrap',quantity:2});expect(active(resolved).stock.scrap).toBe(1);});
 it('recusa unidade ausente, tick ímpar, versão futura, JSON inválido, IDs duplicados e negativos',()=>{
  const s=setup();const half=legacy(s,'half');half.state.players[0].vehicle.fuelUnits=3;expect(()=>decodeSave(JSON.stringify(half))).toThrow('sem perda');
  const missing=legacy(s);delete missing.fuelUnit;expect(()=>decodeSave(JSON.stringify(missing))).toThrow('incompatível');
  const future=JSON.parse(encodeSave(s));future.schemaVersion=9;expect(()=>decodeSave(JSON.stringify(future))).toThrow('Original preservado');
  expect(()=>decodeSave('{broken')).toThrow('Original preservado');expect(()=>decodeSave(JSON.stringify(s))).toThrow('sem versão');
  const invalid=structuredClone(s);active(invalid).vehicle.fuelUnits=-1;expect(()=>encodeSave(invalid)).toThrow();
  const duplicate=JSON.parse(encodeSave(s));duplicate.state.players[0].hand[0].id=duplicate.state.players[1].hand[0].id;expect(()=>decodeSave(JSON.stringify(duplicate))).toThrow('ID duplicado');
 });
 it('combates e transições preservam invariantes em 50 seeds',()=>{
  for(let seed=0;seed<50;seed++){let s=setup('pickup',seed);s.territories['araras-2'].owner=null;s=transition(s,{type:'conquer',territoryId:'araras-2'});for(let i=0;s.encounter&&i<200;i++){s=transition(s,{type:'attack'});assertInvariants(s);}expect(s.encounter).toBeNull();expect(decodeSave(encodeSave(s)).game).toEqual(s);}
 });
});

describe('regressões de fronteira',()=>{
 it('bloqueio protege também outro jogador de classe diferente',()=>{const s=setup('pickup');active(s).hand[0].definitionId='block';const other=s.players[1];other.city='artur-nogueira';other.vehicle=makeVehicle(s,'hatch');s.blocks=[{routeId:'conchal-artur-nogueira',by:active(s).id}];snapshotFailure(s,{type:'playGeneral',cardId:active(s).hand[0].id,route:'artur-nogueira-limeira'},'sem saída');});
 it('falha na fuga não dá ataque extra nem gasta carta ou combustível',()=>{const s=setup();s.players[1].city='araras';s.rules.escapeTarget=100;s.encounter={kind:'combat',actorId:active(s).id,defenderId:s.players[1].id,betweenRounds:true,lootResolved:false};const before=structuredClone(s);const n=transition(s,{type:'escape',route:'araras-leme',playerId:active(s).id});expect(active(n).hand).toEqual(active(before).hand);expect(active(n).vehicle).toEqual(active(before).vehicle);expect(n.encounter?.betweenRounds).toBe(true);expect(n.seed).not.toBe(s.seed);});
 it('excedente territorial conserva tudo até o jogador descartar',()=>{const s=setup();s.territories['araras-1'].stock.scrap=9;s.rules.lootQuantity=2;const n=transition(s,{type:'explore',territoryId:'araras-1'});expect(Object.values(n.territories['araras-1'].stock).reduce((a,b)=>a+b)).toBe(11);expect(capacityIssues(n)).not.toEqual([]);snapshotFailure(n,{type:'end'},'excedentes');});
 it('sexta geral exige escolha antes de prosseguir; combate não renova cota',()=>{const s=setup();s.started=false;active(s).usedGeneral=true;for(let i=0;i<2;i++)active(s).hand.push({id:`extra-${i}`,type:'general',definitionId:'block'});const n=transition(s,{type:'start'});expect(active(n).hand).toHaveLength(6);snapshotFailure(n,{type:'end'},'excedentes');const resolved=transition(n,{type:'discardCard',playerId:active(n).id,cardId:active(n).hand[0].id});expect(capacityIssues(resolved)).toEqual([]);active(resolved).usedGeneral=true;resolved.territories['araras-2'].owner=null;const combat=transition(resolved,{type:'conquer',territoryId:'araras-2'});expect(active(combat).usedGeneral).toBe(true);});
 it('comando inválido em runtime é recusado',()=>{const s=setup();snapshotFailure(s,{type:'desconhecido'} as never,'desconhecido');});
});
