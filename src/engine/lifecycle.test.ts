import { describe, expect, it } from 'vitest';
import { createGame, transition, emptyStock, makeVehicle, localScrapAvailable, vehicleAttackBlock, assertInvariants, type Game, type ModelId, type DiceRoll } from './game';
import { resolveEvent } from './cardRules';
import { decodeSave, encodeSave } from '../application/saves';
import { catalog } from './catalog';

const active=(s:Game)=>s.players[s.active];
function setup(count=2){
 let s=transition(createGame(['Ana','Bia','Cris'].slice(0,count),42),{type:'start'});
 for(const p of s.players){p.city='araras';p.stock=emptyStock();}
 for(const t of Object.values(s.territories)){delete t.hostile;t.owner=null;t.threat=null;}
 s.territories['araras-1'].owner=active(s).id;
 return s;
}
function give(s:Game,id:string,owner=active(s)){
 const d=catalog.find(card=>card.id===id)!;const deck=s.cardState!.decks[d.deck];const index=deck.findIndex(card=>card.definitionId===id);const card=deck.splice(index,1)[0];owner.hand.push(card);return card.id;
}
function seedForSix(){for(let seed=0;seed<10000;seed++){const next=(Math.imul(seed,1664525)+1013904223)>>>0;if(Math.floor(next/4294967296*6)+1===6)return seed;}throw Error('seed');}
function kill(s:Game,victimId:number){
 const attacker=s.players.find(p=>p.id!==victimId&&!p.eliminated)!;const victim=s.players.find(p=>p.id===victimId)!;victim.vehicle.integrity=1;s.rules.attackDamage=20;
 s.encounter={kind:'combat',actorId:attacker.id,defenderId:active(s).id===attacker.id?victimId:attacker.id,betweenRounds:false,lootResolved:false};s.seed=seedForSix();
 return transition(s,{type:'attack'});
}
describe('progressão e duas vidas v0.6',()=>{
 it('recuperacao bloqueia o carro ate encerrar a penalidade e o save preserva o motivo',()=>{
  let s=setup();const id=s.players.find(player=>player.id!==active(s).id)!.id;s=kill(s,id);
  expect(vehicleAttackBlock(s,s.players.find(player=>player.id===id)!)).toContain('recupera');
  const restored=decodeSave(encodeSave(s)).game;expect(vehicleAttackBlock(restored,restored.players.find(player=>player.id===id)!)).toContain('recupera');
  s=transition(s,{type:'end'});s=transition(s,{type:'start'});expect(vehicleAttackBlock(s,active(s))).toContain('recupera');
  s=transition(s,{type:'end'});expect(vehicleAttackBlock(s,s.players.find(player=>player.id===id)!)).toBeNull();
 });
 it('Caminho obstruido consome acao sem marcar o carro como em recuperacao',()=>{
  const s=setup(),p=active(s),events=s.cardState!.decks.events,index=events.findIndex(card=>card.definitionId==='V11');events.unshift(events.splice(index,1)[0]);resolveEvent(s,p);
  expect(s.actions).toBe(0);expect(vehicleAttackBlock(s,p)).toBeNull();
 });
 it('bloqueio de estrada não imobiliza o carro para combate local',()=>{
  const s=setup();s.blocks.push({routeId:'araras-leme',by:active(s).id});expect(vehicleAttackBlock(s,active(s))).toBeNull();
 });
 it.each([0,1,2])('resultado estruturado corresponde ao dano aplicado com redução %s',reduction=>{
  const s=setup(),attacker=active(s),target=s.players.find(p=>p.id!==attacker.id)!;
  s.encounter={kind:'combat',actorId:attacker.id,defenderId:target.id,betweenRounds:false,lootResolved:false};s.seed=seedForSix();
  if(reduction)s.cardState!.pending.push({playerId:target.id,effect:'reduceDamage',amount:reduction});
  const rolls:DiceRoll[]=[];const n=transition(s,{type:'attack'},rolls),after=n.players.find(p=>p.id===target.id)!;
  const damage=reduction?0:1;expect(after.vehicle.integrity).toBe(6-damage);
  expect(rolls[0].combat).toEqual({attackerId:attacker.id,targetId:target.id,natural:6,total:6,defense:4,hit:true,healthBefore:6,healthAfter:6-damage,damage,prevented:reduction?1:0});
  expect(n).toEqual(transition(s,{type:'attack'}));
 });
 it('inicia todos de hatch com carga 4, combustível 3 e duas vidas',()=>{
  const s=createGame(['A','B','C','D'],42);for(const p of s.players){expect(p.vehicle.modelId).toBe('hatch');expect(p.vehicle.fuelUnits).toBe(3);expect(p.deaths).toBe(0);expect(p.eliminated).toBe(false);}
 });
 it.each(['sedan','suv','pickup'] as ModelId[])('melhora para %s pagando cinco sucatas locais e uma ação sem curar ou reabastecer',modelId=>{
  const s=setup(),p=active(s);p.stock.scrap=3;s.territories['araras-1'].stock.scrap=3;p.vehicle.integrity=2;p.vehicle.fuelUnits=1;p.deaths=1;
  const n=transition(s,{type:'upgradeVehicle',modelId});expect(active(n).vehicle.modelId).toBe(modelId);expect(active(n).vehicle.integrity).toBe(2);expect(active(n).vehicle.fuelUnits).toBe(1);expect(active(n).deaths).toBe(1);expect(active(n).stock.scrap).toBe(0);expect(n.territories['araras-1'].stock.scrap).toBe(1);expect(n.actions).toBe(0);
 });
 it('não paga remotamente, não repete melhoria e não gasta custos em erro',()=>{
  const s=setup(),p=active(s);s.territories['limeira-1'].owner=p.id;s.territories['limeira-1'].stock.scrap=5;expect(localScrapAvailable(s,p)).toBe(0);const before=structuredClone(s);
  expect(()=>transition(s,{type:'upgradeVehicle',modelId:'suv'})).toThrow('5 sucatas');expect(s).toEqual(before);
  s.territories['araras-1'].stock.scrap=5;s.actions=0;const noAction=structuredClone(s);expect(()=>transition(s,{type:'upgradeVehicle',modelId:'suv'})).toThrow('principal');expect(s).toEqual(noAction);
  s.actions=1;let n=transition(s,{type:'upgradeVehicle',modelId:'suv'});n.actions=1;n.territories['araras-1'].stock.scrap=5;expect(()=>transition(n,{type:'upgradeVehicle',modelId:'sedan'})).toThrow('hatch');
 });
 it('primeira morte perde carga, tanque, cartas e adicionais; preserva depósitos e territórios',()=>{
  let s=setup();const victim=s.players.find(p=>p.id!==active(s).id)!,id=victim.id;victim.vehicle=makeVehicle(s,'suv');victim.vehicle.fuelUnits=8;victim.stock.scrap=3;victim.stock.water=1;
  const cardId=give(s,'E01',victim);victim.hand=victim.hand.filter(card=>card.id!==cardId);const installed=s.cardState!.decks.improvements;expect(installed.some(card=>card.id===cardId)).toBe(false);
  s.cardState!.installed[cardId]={id:cardId,instanceId:cardId,definitionId:'E01',type:'equipment'};victim.vehicle.installed=[cardId];give(s,'G11',victim);
  s.territories['araras-2'].owner=id;s.territories['araras-2'].stock.scrap=4;const attackerHand=active(s).hand.length;
  s=kill(s,id);const after=s.players.find(p=>p.id===id)!;
  expect(after.deaths).toBe(1);expect(after.eliminated).toBe(false);expect(after.vehicle.modelId).toBe('hatch');expect(after.vehicle.integrity).toBe(6);expect(after.vehicle.fuelUnits).toBe(3);expect(after.city).toBe('araras');expect(after.hand).toEqual([]);expect(after.stock).toEqual(emptyStock());expect(after.vehicle.installed).toEqual([]);expect(s.cardState!.installed[cardId]).toBeUndefined();expect(s.cardState!.discarded.improvements.some(card=>card.id===cardId)).toBe(true);expect(active(s).hand).toHaveLength(attackerHand);expect(s.territories['araras-2'].owner).toBe(id);expect(s.territories['araras-2'].stock.scrap).toBe(4);expect(s.encounter).toBeNull();assertInvariants(s);
 });
 it('pula o próximo turno inteiro sem comprar e protege o hatch até encerrar a penalidade',()=>{
  let s=setup();const id=s.players.find(p=>p.id!==active(s).id)!.id;s=kill(s,id);s.actions=1;expect(()=>transition(s,{type:'duel',defenderId:id})).toThrow('Oponente');
  s=transition(s,{type:'end'});expect(active(s).id).toBe(id);s=transition(s,{type:'start'});expect(active(s).hand).toEqual([]);expect(s.actions).toBe(0);expect(active(s).penaltyActive).toBe(true);expect(()=>transition(s,{type:'buyImprovement'})).toThrow('Penalidade');expect(()=>transition(s,{type:'move',route:'araras-leme'})).toThrow('Penalidade');
  s=transition(s,{type:'end'});s=transition(s,{type:'start'});s=transition(s,{type:'end'});s=transition(s,{type:'start'});expect(active(s).id).toBe(id);expect(active(s).penaltyActive).toBe(false);expect(active(s).hand).toHaveLength(1);expect(s.actions).toBe(1);
 });
 it('morte do jogador ativo encerra sua ação, além da penalidade futura',()=>{
  const s=setup(),id=active(s).id;const n=kill(s,id);expect(n.actions).toBe(0);expect(n.moved).toBe(true);expect(n.players.find(p=>p.id===id)!.skipTurns).toBe(1);expect(()=>transition(n,{type:'repair',complex:true})).toThrow('Penalidade');
 });
 it('segunda morte elimina, abandona setores e concede vitória por sobrevivência',()=>{
  const s=setup(),victim=s.players.find(p=>p.id!==active(s).id)!;victim.deaths=1;s.territories['araras-2'].owner=victim.id;s.territories['araras-2'].stock.water=2;s.territories['araras-2'].resistance=3;
  const n=kill(s,victim.id);expect(n.players.find(p=>p.id===victim.id)!.eliminated).toBe(true);expect(n.winner).toBe(active(s).id);expect(n.winnerReason).toBe('survival');expect(n.finished).toBe(true);expect(n.territories['araras-2'].owner).toBeNull();expect(n.territories['araras-2'].stock.water).toBe(2);expect(n.territories['araras-2'].resistance).toBe(3);expect(()=>transition(n,{type:'end'})).toThrow('encerrada');
 });
 it('eliminado não recebe novos turnos em partida de três jogadores',()=>{
  let s=setup(3);const victim=s.players.find(p=>p.id!==active(s).id)!;victim.deaths=1;s=kill(s,victim.id);expect(s.winner).toBeNull();
  for(let i=0;i<5;i++){s=transition(s,{type:'end'});expect(active(s).id).not.toBe(victim.id);s=transition(s,{type:'start'});}
 });
 it('save conserva vidas e penalidade; edição v0.5 é recusada sem conversão',()=>{
  let s=setup();s=kill(s,s.players.find(p=>p.id!==active(s).id)!.id);expect(decodeSave(encodeSave(s)).game).toEqual(s);
  const old=JSON.parse(encodeSave(s));old.contentVersion=old.state.contentVersion='0.5.0';expect(()=>decodeSave(JSON.stringify(old))).toThrow('Original preservado');
 });
 it('evento de viagem pode consumir vida e não deixa executar ação depois do renascimento',()=>{
  const s=setup(),id=active(s).id;active(s).vehicle.integrity=1;
  const deck=s.cardState!.decks.events,index=deck.findIndex(card=>card.definitionId==='V06');deck.unshift(deck.splice(index,1)[0]);
  const n=transition(s,{type:'move',route:'araras-leme'}),p=n.players.find(player=>player.id===id)!;
  expect(p.deaths).toBe(1);expect(p.city).toBe('leme');expect(p.vehicle.fuelUnits).toBe(3);expect(n.actions).toBe(0);expect(p.hand).toEqual([]);expect(p.skipTurns).toBe(1);
 });
 it('contra-ataque de ameaça consome vida e encerra o combate',()=>{
  const s=setup();active(s).vehicle.integrity=1;s.encounter={kind:'combat',territoryId:'araras-2',actorId:active(s).id,betweenRounds:false,lootResolved:false,threatTurn:true};s.seed=seedForSix();
  const n=transition(s,{type:'attack'});expect(active(n).deaths).toBe(1);expect(active(n).vehicle.modelId).toBe('hatch');expect(n.encounter).toBeNull();
 });
 it('morte em corrida não devolve o carro renascido à prova',()=>{
  let s=setup();const id=active(s).id;active(s).vehicle.integrity=1;
  s.cardState!.race={trackId:'P01',phase:'running',responses:s.players.map(p=>p.id),entrants:s.players.map(p=>({playerId:p.id,progress:5,markers:[],next:0})),cursor:0,finalRound:false};
  const deck=s.cardState!.decks.race,index=deck.findIndex(card=>card.definitionId==='R11');deck.unshift(deck.splice(index,1)[0]);s.seed=seedForSix();s=transition(s,{type:'raceRoll'});
  expect(active(s).deaths).toBe(1);expect(s.cardState!.race!.entrants[0].withdrawn).toBe(true);
  s=decodeSave(encodeSave(s)).game;const before=s.cardState!.race!.entrants[0].progress;
  s=transition(s,{type:'raceRoll'});if(s.cardState!.race){s=transition(s,{type:'raceRoll'});expect(s.cardState!.race?.entrants.find(p=>p.playerId===id)?.progress??before).toBe(before);}
 });
 it('segunda morte simultânea de todos encerra sem vencedor',()=>{
  let s=setup();for(const p of s.players){p.deaths=1;p.vehicle.integrity=1;}
  const owner=active(s),other=s.players.find(p=>p.id!==owner.id)!;
  const deck=s.cardState!.decks.race,index=deck.findIndex(card=>card.definitionId==='R09'),card=deck.splice(index,1)[0];s.cardState!.discarded.race.push(card);
  s.cardState!.race={trackId:'P01',phase:'running',responses:s.players.map(p=>p.id),entrants:s.players.map(p=>({playerId:p.id,progress:6,markers:[6],next:0})),cursor:0,finalRound:false};
  s.cardState!.choice={kind:'raceTarget',card,playerId:owner.id,targets:[other.id]};s=transition(s,{type:'cardChoice',targetId:other.id});
  expect(s.players.every(p=>p.eliminated)).toBe(true);expect(s.finished).toBe(true);expect(s.winner).toBeNull();expect(s.cardState!.race).toBeUndefined();assertInvariants(s);
 });
});
