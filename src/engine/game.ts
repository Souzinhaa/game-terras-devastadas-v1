import { initHostiles, attachHostile, startHostileCombat, nextHostileRound, hostileEscapeModifier, assertHostiles, type HostileInstance, type HostileContext, type HostileConfig, type HostileTier } from './hostiles';
import { initCatalog, assertCatalog, drawCatalog, discardCatalog, resolveEvent, handleCardAction, playCatalog, cargoCapacity, tankCapacity, extraCargo, depotCapacity, equipment, takeModifier, resolveAttack, counterAttack, type CatalogState, type CardAction } from './cardRules';
import cities from '../data/cities.json';
import routes from '../data/routes.json';
import cards from '../data/cards.json';
import vehicles from '../data/vehicles.json';
import { laboratoryRules, rebalance, type RuleConfig } from './config';
export { cities, routes, cards, vehicles };
export const CONTENT_VERSION = '0.6.0';
export type ModelId = 'hatch' | 'sedan' | 'suv' | 'pickup' | 'moto';
export type Resource = 'fuel' | 'scrap' | 'tire' | 'battery' | 'water' | 'ammo';
export type Stock = Record<Resource, number>;
export interface Card { id: string; instanceId?: string; definitionId: string; type: 'general' | 'equipment' | 'territorial' | 'race' | 'event' }
export interface Vehicle { id: string; modelId: ModelId; integrity: number; fuelUnits: number; fixedEquipmentId: string; installed: string[]; conditions: string[] }
export interface Player { id: number; name: string; city: string; vehicle: Vehicle; stock: Stock; hand: Card[]; repairs: number; usedGeneral: boolean; deaths:number; skipTurns:number; penaltyActive:boolean; eliminated:boolean; eliminatedAtTurn?:number }
export interface Territory { hostile?: HostileInstance; difficulty?: HostileTier; difficultyPending?: boolean; installed?: string[]; id: string; city: string; label: string; owner: number | null; threat: string | null; resistance: number; explorations: number; stock: Stock }
export interface Block { sourceCardId?: string; sourceInstanceId?: string; routeId: string; by: number }
export interface FoundVehicle { city: string; vehicle: Vehicle; repairedOnTurn: number | null }
export interface Combat { eventHostile?: HostileInstance; hostileContext?: HostileContext; lastRoll?: {natural:number;total:number;defense:number;hit:boolean}; threatTurn?: boolean; eventIntegrity?: number; kind: 'combat'; territoryId?: string; defenderId?: number; actorId: number; betweenRounds: boolean; lootResolved: boolean }
export interface Game { finished?:boolean; winnerReason?:'survival'|'territory'; initialSeed?:number; victoryAnnouncements?: Record<string, {declaredTurn:number}>; travelAfterBlock?: boolean; hostileConfig?: HostileConfig; hostileDiscarded?: HostileInstance[]; cardState?: CatalogState; schemaVersion: 4; contentVersion: string; seed: number; nextId: number; turn: number; active: number; actions: number; started: boolean; moved: boolean; players: Player[]; territories: Record<string, Territory>; encounter: Combat | null; blocks: Block[]; found: FoundVehicle[]; localScrap: Record<string, number>; discarded: Card[]; log: string[]; rules: RuleConfig; winner: number | null }
export type Action = CardAction
 | { type: 'start' } | { type: 'move'; route: string } | { type: 'conquer'; territoryId: string }
 | { type: 'duel'; defenderId: number } | { type: 'attack' } | { type: 'escape'; route: string; playerId: number }
 | { type: 'explore'; territoryId: string } | { type: 'repair'; complex: boolean }
 | { type: 'transfer'; territoryId: string; resource: Resource; quantity: number; direction: 'deposit' | 'withdraw' }
 | { type: 'refuel'; quantity: number; unload?: boolean }
 | { type: 'playGeneral'; cardId: string; route: string }
 | { type: 'swap'; vehicleId: string } | { type: 'repairFound'; vehicleId: string }
 | { type: 'discard'; playerId?: number; territoryId?: string; resource: Resource | 'tank'; quantity: number }
 | { type: 'discardCard'; playerId: number; cardId: string }
 | { type:'upgradeVehicle'; modelId:ModelId }
 | { type: 'collectScrap'; quantity: number } | { type: 'end' };
export const emptyStock = (): Stock => ({ fuel: 0, scrap: 0, tire: 0, battery: 0, water: 0, ammo: 0 });
export const model = (p: Player | Vehicle) => { const id = 'vehicle' in p ? p.vehicle.modelId : p.modelId; const v = vehicles.find(v => v.id === id); if (!v) throw Error('Modelo desconhecido.'); return v; };
export const load = (p: Player) => Object.values(p.stock).reduce((a, b) => a + b, 0);
export const stockSize = (stock: Stock) => Object.values(stock).reduce((a, b) => a + b, 0);
export function vehicleAttackBlock(s:Game,p:Player):string|null {
 if(p.eliminated)return 'Jogador eliminado.';
 if(p.skipTurns>0||p.penaltyActive)return 'Carro bloqueado: recuperação até encerrar o turno de penalidade. Não pode atacar.';
 return null;
}
export function random(s: Game, max: number) { s.seed = (Math.imul(s.seed, 1664525) + 1013904223) >>> 0; return Math.floor(s.seed / 4294967296 * max); }
export interface CombatRollResult { attackerId:number; targetId?:number; natural:number; total:number; defense:number; hit:boolean; healthBefore:number; healthAfter:number; damage:number; prevented:number }
export interface DiceRoll { label:string; natural:number; combat?:CombatRollResult }
const diceCaptures=new WeakMap<Game,DiceRoll[]>();
export function rollDie(s:Game,label:string){const natural=random(s,6)+1;diceCaptures.get(s)?.push({label,natural});return natural;}
export function recordCombatRoll(s:Game,result:CombatRollResult){const roll=diceCaptures.get(s)?.at(-1);if(roll)roll.combat=result;}
const die = (s:Game,label='Ataque') => rollDie(s,label);
const note = (s: Game, message: string) => { s.log.push(`T${s.turn} · ${message}`); };
export function makeVehicle(s: Game, modelId: ModelId): Vehicle {
 const definition = vehicles.find(v => v.id === modelId)!;
 return { id: `vehicle-${s.nextId++}`, modelId, integrity: s.rules.combat[modelId].integrity, fuelUnits: 0, fixedEquipmentId: definition.fixedEquipmentId, installed: [], conditions: [] };
}
function draw(s: Game, p: Player) { if(s.cardState) drawCatalog(s, 'general', p); else p.hand.push({ id: `card-${s.nextId++}`, definitionId: cards.generals[random(s, cards.generals.length)].id, type: 'general' }); }
export function createGame(names: string[], seed: number, rules = laboratoryRules): Game {
 if (names.length < 2 || names.length > 4 || names.some(n => !n.trim()) || !Number.isSafeInteger(seed) || seed < 0 || seed > 0xffffffff) throw Error('Informe 2–4 nomes e uma seed inteira de 0 a 4294967295.');
 const s: Game = { schemaVersion: 4, contentVersion: CONTENT_VERSION, initialSeed:seed, seed, nextId: 1, turn: 1, active: 0, actions: 1, started: false, moved: false, players: [], territories: {}, encounter: null, blocks: [], found: [], localScrap: {}, discarded: [], log: [], rules: structuredClone(rules), winner: null, victoryAnnouncements: {}, travelAfterBlock: false };
 const availableCities = [...cities];
 initCatalog(s);initHostiles(s);
 for (const city of cities) {
  s.localScrap[city.id] = 0;
  for (let i = 1; i <= city.regions; i++) { const id = `${city.id}-${i}`; s.territories[id] = { id, city: city.id, label: `Setor ${i}`, owner: null, threat: null, resistance: rules.territoryIntegrity, explorations: 0, stock: emptyStock() };attachHostile(s,s.territories[id]); }
 }
 for (const [id, name] of names.entries()) {
  const city = availableCities.splice(random(s, availableCities.length), 1)[0];
  const vehicle = makeVehicle(s, 'hatch'); vehicle.fuelUnits = rebalance.setup.fuelUnits[vehicle.modelId];
  const p: Player = { id, name: name.trim(), city: city.id, vehicle, stock: { ...emptyStock(), scrap: 1 }, hand: [], repairs: 0, usedGeneral: false, deaths:0, skipTurns:0, penaltyActive:false, eliminated:false };
  draw(s, p); s.players.push(p);
  const t = s.territories[`${city.id}-${random(s, city.regions) + 1}`]; t.owner = id;t.resistance=rules.territoryIntegrity;t.threat = null;delete t.hostile;
 }
 for (let i = s.players.length - 1; i > 0; i--) { const j = random(s, i + 1); [s.players[i], s.players[j]] = [s.players[j], s.players[i]]; }
 note(s, 'Regras v0.6: todos começam de Hatch com duas vidas; ordem e posições sorteadas; combustível para 3 viagens, 1 sucata e 1 geral. Inicie o turno para comprar a geral da vez.');
 assertInvariants(s); return s;
}
export const cityTerritories = (s: Game, city: string) => Object.values(s.territories).filter(t => t.city === city);
export function points(s: Game, id: number) { return cities.reduce((total, c) => total + (cityTerritories(s, c.id).every(t => t.owner === id) ? c.regions >= 4 ? 1 : 0.5 : 0), 0); }
export function capacityIssues(s: Game): string[] {
 const issues: string[] = [];
 for (const p of s.players) {
  const v = model(p);
  if (load(p)+extraCargo(s,p) > cargoCapacity(s,p)) issues.push(`${p.name}: carga ${load(p)+extraCargo(s,p)}/${cargoCapacity(s,p)}`);
  if (p.vehicle.fuelUnits > tankCapacity(s,p)) issues.push(`${p.name}: tanque ${p.vehicle.fuelUnits}/${tankCapacity(s,p)}`);
  for (const [type, max] of [['general', 5], ['equipment', 3], ['territorial', 3]] as const) if (p.hand.filter(c => c.type === type).length > max) issues.push(`${p.name}: excedente de cartas ${type}`);
 }
 for (const t of Object.values(s.territories)) if (stockSize(t.stock) > depotCapacity(s,t)) issues.push(`${t.city}/${t.label}: depósito ${stockSize(t.stock)}/${depotCapacity(s,t)}`);
 return issues;
}
export function routeReason(s: Game, p: Player, routeId: string, checkFuel = true): string | null {
 const route = routes.find(r => r.id === routeId);
 if(p.eliminated||p.skipTurns>0||p.penaltyActive)return 'Jogador eliminado ou em recuperação.';
 if (!route || (route.from !== p.city && route.to !== p.city)) return 'Rota não adjacente.';
 if (!model(p).allowedSurfaces.includes(route.terrain)) return 'Terra: somente SUV, Caminhonete e Moto.';
 if (p.vehicle.conditions.includes('motor')) return 'Motor impede deslocamento.';
 if (route.terrain === 'rural' && p.vehicle.conditions.includes('suspension')) return 'Suspensão impede terra.';
 if (s.blocks.some(b => b.routeId === routeId)) return 'Ligação bloqueada nos dois sentidos.';
 if (checkFuel && p.vehicle.integrity === 0) return 'Carro inutilizado; execute reparo complexo.';
 if (checkFuel && p.vehicle.fuelUnits < model(p).consumption) return 'Combustível insuficiente.';
 return null;
}
export function travelCost(s: Game, routeId: string, playerId = s.players[s.active].id) {
 if (!routes.some(r => r.id === routeId)) throw Error('Rota inexistente.');
 const p = s.players.find(p => p.id === playerId); if (!p) throw Error('Jogador inexistente.'); return model(p).consumption;
}
function travel(s: Game, p: Player, routeId: string) {
 const reason = routeReason(s, p, routeId); if (reason) throw Error(reason);
 const route = routes.find(r => r.id === routeId)!; p.vehicle.fuelUnits -= model(p).consumption; p.city = route.from === p.city ? route.to : route.from;
 note(s, `${p.name} → ${p.city}; custo fixo ${model(p).consumption}.`);
}
function steal(s: Game, winner: Player, loser: Player) {
 const eligible = loser.hand.filter(c => c.type !== 'territorial' || s.rules.stealTerritorialCards);
 if (!eligible.length) return;
 const card = eligible[random(s, eligible.length)]; loser.hand = loser.hand.filter(c => c.id !== card.id); winner.hand.push(card);
 note(s, `${winner.name} recebeu 1 carta às cegas; instalados não são elegíveis.`);
}
export function localScrapAvailable(s:Game,p:Player):number {
 return p.stock.scrap+cityTerritories(s,p.city).filter(t=>t.owner===p.id).reduce((sum,t)=>sum+t.stock.scrap,0);
}
function payVehicleUpgrade(s:Game,p:Player) {
 if(localScrapAvailable(s,p)<5)throw Error('Melhoria exige 5 sucatas na carga ou nos depósitos próprios locais.');
 let remaining=5;
 const carried=Math.min(remaining,p.stock.scrap);p.stock.scrap-=carried;remaining-=carried;
 for(const t of cityTerritories(s,p.city).filter(t=>t.owner===p.id)){const amount=Math.min(remaining,t.stock.scrap);t.stock.scrap-=amount;remaining-=amount;}
}
function settleDeaths(s:Game,previous:Game) {
 for(const p of s.players){
  const before=previous.players.find(v=>v.id===p.id)!;
  if(p.eliminated||p.vehicle.integrity>0||before.vehicle.integrity<=0||before.vehicle.id!==p.vehicle.id)continue;
  p.deaths++;p.eliminated=p.deaths>=2;
  for(const card of p.hand)discardCatalog(s,card);p.hand=[];
  for(const key of p.vehicle.installed){const card=s.cardState?.installed[key];if(card){discardCatalog(s,card);delete s.cardState!.installed[key];}}
  p.stock=emptyStock();p.vehicle.fuelUnits=0;p.vehicle.installed=[];p.vehicle.conditions=[];p.repairs=0;p.usedGeneral=true;
  delete s.victoryAnnouncements?.[p.id];
  if(s.cardState){s.cardState.pending=s.cardState.pending.filter(effect=>effect.playerId!==p.id&&effect.sourcePlayerId!==p.id);const entrant=s.cardState.race?.entrants.find(v=>v.playerId===p.id);if(entrant)entrant.withdrawn=true;if(s.cardState.choice?.playerId===p.id)delete s.cardState.choice;else if(s.cardState.choice?.targets)s.cardState.choice.targets=s.cardState.choice.targets.filter(id=>id!==p.id);}
  if(s.encounter&&(s.players[s.active].id===p.id||s.encounter.defenderId===p.id))s.encounter=null;
  if(p.id===s.players[s.active].id){s.actions=0;s.moved=true;s.travelAfterBlock=false;}
  if(p.eliminated){
   p.eliminatedAtTurn=s.turn;p.skipTurns=0;p.penaltyActive=false;s.blocks=s.blocks.filter(block=>block.by!==p.id);
   for(const t of Object.values(s.territories))if(t.owner===p.id)t.owner=null;
   note(s,p.name+': segunda destruição; eliminado definitivamente. Territórios abandonados preservam defesa e depósito.');
  }else{
   p.vehicle=makeVehicle(s,'hatch');p.vehicle.fuelUnits=3;p.skipTurns=1;
   note(s,p.name+': primeira destruição; renasceu de Hatch na mesma cidade, com 1 vida e 3 combustíveis. Próximo turno perdido; cartas e itens do carro descartados.');
  }
 }
 const survivors=s.players.filter(p=>!p.eliminated);
 if(survivors.length<=1){s.finished=true;s.winner=survivors[0]?.id??null;s.winnerReason='survival';s.encounter=null;if(s.cardState){delete s.cardState.race;delete s.cardState.choice;}note(s,survivors.length?survivors[0].name+' venceu por ser o último sobrevivente.':'Partida encerrada sem sobreviventes.');}
 if(s.players[s.active].eliminated&&survivors.length>1&&!s.cardState?.race){do{s.active=(s.active+1)%s.players.length;}while(s.players[s.active].eliminated);s.turn++;s.started=false;s.actions=1;s.moved=false;s.travelAfterBlock=false;}
}
export function transition(previous: Game, action: Action, diceRolls?:DiceRoll[]): Game {
 if(previous.contentVersion!==CONTENT_VERSION)throw Error('Partida de edição anterior incompatível com v0.6. Original preservado; inicie uma nova partida.');
 const s = structuredClone(previous), p = s.players[s.active], r = s.rules;const combatBefore=s.encounter;if(diceRolls)diceCaptures.set(s,diceRolls);
 const resolving = ['discard', 'discardCard', 'transfer', 'refuel'].includes(action.type);
 if (capacityIssues(s).length && !resolving) throw Error('Resolva excedentes de carga, tanque, depósito ou mão antes de continuar.');
 if ((s.winner !== null||s.finished) && !resolving) throw Error('Partida encerrada.');
 if(p.eliminated&&!(s.cardState?.race&&(['raceRoll','cardChoice'].includes(action.type)||(action.type==='playCatalog'&&action.playerId!==undefined&&action.playerId!==p.id))))throw Error('Jogador eliminado.');
 if((p.penaltyActive||p.skipTurns>0)&&!['start','end','discard','discardCard'].includes(action.type)&&!(s.cardState?.race&&(['raceRoll','cardChoice'].includes(action.type)||(action.type==='playCatalog'&&action.playerId!==undefined&&action.playerId!==p.id))))throw Error('Penalidade: perca um turno inteiro.');
 if('playerId' in action&&action.playerId!==undefined&&['playCatalog','raceEntry'].includes(action.type)){const actor=s.players.find(v=>v.id===action.playerId);if(actor&&(actor.eliminated||actor.skipTurns>0||actor.penaltyActive))throw Error('Jogador indisponível durante eliminação ou penalidade.');}
 if (!s.started && action.type !== 'start' && !(capacityIssues(s).length && resolving)) throw Error('Inicie o turno para comprar a geral.');
 if (s.encounter && !['attack','escape','discard','discardCard','playCatalog','useEquipment','equipmentAttack'].includes(action.type)) throw Error('Resolva o combate antes de continuar.');
 if(s.cardState?.choice && !['cardChoice','discard','discardCard','transfer','refuel'].includes(action.type)) throw Error('Resolva a escolha da carta antes de continuar.');
 if(s.cardState?.race && !['raceEntry','raceRoll','playCatalog','useEquipment','cardChoice','discard','discardCard','transfer','refuel'].includes(action.type)) throw Error('Resolva a corrida antes de continuar.');
 const spend = () => { if (!s.actions) throw Error('Ação principal já utilizada.'); s.actions--; };
 const operational = () => { if (!p.vehicle.integrity) throw Error('Carro inutilizado; execute reparo complexo.'); };
 const local = (id: string, own = true) => { const t = s.territories[id]; if (!t || t.city !== p.city || (own && t.owner !== p.id)) throw Error('Escolha um território próprio na cidade atual.'); return t; };
 const quantity = (n: number) => { if (!Number.isSafeInteger(n) || n <= 0) throw Error('Quantidade deve ser inteira positiva.'); };
 if(!handleCardAction(s,action)) switch (action.type) {
  case 'start':
   if (s.started) throw Error('Turno já iniciado.');
   if(s.cardState){s.cardState.used=[];s.cardState.pending=[];}s.blocks = s.blocks.filter(b => b.by !== p.id); s.started = true; s.actions = 1; s.moved = false; p.repairs = 0; s.players.forEach(p => { p.usedGeneral = false; }); s.travelAfterBlock=false; cancelInvalidAnnouncements(s);
   if(p.skipTurns>0){p.skipTurns--;p.penaltyActive=true;s.actions=0;s.moved=true;note(s,p.name+': turno perdido pela destruição do carro; sem compra ou ações.');break;}
   if(s.victoryAnnouncements?.[p.id]){s.winner=p.id;s.winnerReason='territory';s.finished=true;note(s, `${p.name} sustentou 4 pontos até o próximo turno e venceu.`);break;}
   draw(s, p); note(s, `${p.name} comprou 1 geral; bloqueios próprios expiraram.`); break;
  case 'move': {
   operational(); if (!canTravelThisTurn(s)) throw Error('Viaje uma vez, antes da ação principal ou após G17.');
   travel(s, p, action.route); s.moved = true; s.travelAfterBlock=false;
   if(s.cardState) resolveEvent(s,p);
   break;
  }
  case 'conquer': {
   const blocked=vehicleAttackBlock(s,p);if(blocked)throw Error(blocked);operational(); const t = local(action.territoryId, false);
   if (t.owner === p.id) throw Error('Território já pertence ao jogador.');
   if (t.owner !== null && s.players.some(v=>v.id===t.owner&&v.city===p.city&&v.vehicle.integrity>0&&!v.eliminated&&!v.skipTurns&&!v.penaltyActive)) throw Error('Defensor pessoal presente: enfrente o carro antes de atacar a fortificação.');
   spend(); s.encounter = { kind: 'combat', territoryId: t.id, actorId: p.id, betweenRounds: false, lootResolved: false }; startHostileCombat(s,s.encounter);note(s, `${p.name} enfrenta ${t.threat??'a defesa territorial'}.`); break;
  }
  case 'duel': {
   const blocked=vehicleAttackBlock(s,p);if(blocked)throw Error(blocked);operational(); const defender = s.players.find(v => v.id === action.defenderId);
   if (!defender || defender.id === p.id || defender.city !== p.city || !defender.vehicle.integrity || defender.eliminated || defender.skipTurns>0 || defender.penaltyActive) throw Error('Oponente operacional precisa estar na mesma cidade.');
   spend(); s.encounter = { kind: 'combat', defenderId: defender.id, actorId: p.id, betweenRounds: false, lootResolved: false }; break;
  }
  case 'attack': {
   const e = s.encounter; if (!e) throw Error('Nenhum combate em curso.');
   if (e.betweenRounds) { nextHostileRound(s,e);e.betweenRounds = false; e.actorId = p.id; }
   if(e.threatTurn) { counterAttack(s,p);e.threatTurn=false;e.betweenRounds=true;if(s.cardState)s.cardState.used=s.cardState.used.filter(v=>!v.startsWith('round:'));break; }
   const attacker = s.players.find(v => v.id === e.actorId)!;
   const target = e.defenderId === undefined ? null : s.players.find(v => v.id === (attacker.id === p.id ? e.defenderId : p.id))!;
   const t = e.territoryId ? s.territories[e.territoryId] : null;
   if(s.cardState) {
    resolveAttack(s,attacker,target??undefined,r.attackDamage);
    if(s.encounter) {
     if(attacker.id===p.id) { if(target)e.actorId=target.id; else { e.threatTurn=true;if(e.hostileContext)e.hostileContext.stage='hostile_attack'; } }
     else {e.betweenRounds=true;e.actorId=p.id;}
     if(e.betweenRounds)s.cardState.used=s.cardState.used.filter(v=>!v.startsWith('round:'));
    }
   } else { const roll=die(s); if(roll>=r.defense){if(target)target.vehicle.integrity=Math.max(0,target.vehicle.integrity-r.attackDamage);else if(t)t.resistance=Math.max(0,t.resistance-r.attackDamage);}e.betweenRounds=true; }
   break;
  }
  case 'escape': {
   const e = s.encounter; if (!e || !e.betweenRounds) throw Error('Fuga somente entre rodadas.');
   const fleeing = s.players.find(v => v.id === action.playerId);
   if (!fleeing || ![p.id, e.defenderId].includes(fleeing.id)) throw Error('Jogador fora do combate.');
   const reason = routeReason(s, fleeing, action.route); if (reason) throw Error(reason);
   const opponent = e.defenderId === undefined ? undefined : s.players.find(v => v.id === (fleeing.id === p.id ? e.defenderId : p.id));
   if (opponent && !fleeing.hand.some(c => c.type !== 'territorial' || r.stealTerritorialCards)) throw Error('Fuga PvP exige carta elegível na mão.');
   const hostilePenalty=hostileEscapeModifier(s,e);const roll = die(s,'Fuga de '+fleeing.name) + r.combat[fleeing.vehicle.modelId].agility + equipment(s,fleeing,'E09').length + takeModifier(s,fleeing.id,'escape')+hostilePenalty; note(s, `Fuga: resultado ${roll}, alvo ${r.escapeTarget}+${hostilePenalty?' (hostil '+hostilePenalty+')':''}.`);
   if (roll >= r.escapeTarget) { travel(s, fleeing, action.route); if (opponent) steal(s, opponent, fleeing); s.encounter = null; }
   break;
  }
  case 'explore': {
   const t = local(action.territoryId); if (t.explorations >= r.explorationUses) throw Error('Três explorações já utilizadas.');
   spend(); t.explorations++;
   const found=emptyStock(),names:Record<Resource,string>={fuel:'combustível',scrap:'sucata',tire:'pneu',battery:'bateria',water:'água',ammo:'munição'};
   const quantity=r.lootQuantity+random(s,2);
   for(let i=0;i<quantity;i++){const resource=cards.resources[random(s,cards.resources.length)] as Resource;t.stock[resource]++;found[resource]++;}
   note(s, t.label+': '+(Object.keys(found) as Resource[]).filter(key=>found[key]>0).map(key=>found[key]+' '+names[key]).join(', ')+' no depósito. Retire os itens para usar.'); break;
  }
  case 'transfer': {
   quantity(action.quantity); const t = local(action.territoryId); if (!Object.hasOwn(t.stock, action.resource)) throw Error('Recurso inválido.');
   const source = action.direction === 'deposit' ? p.stock : t.stock, target = action.direction === 'deposit' ? t.stock : p.stock;
   if (source[action.resource] < action.quantity) throw Error('Estoque insuficiente.');
   source[action.resource] -= action.quantity; target[action.resource] += action.quantity; note(s, 'Transferência local livre; resolva eventual excedente.'); break;
  }
  case 'refuel':
   quantity(action.quantity);
   if (action.unload) { if (p.vehicle.fuelUnits < action.quantity) throw Error('Tanque insuficiente.'); p.vehicle.fuelUnits -= action.quantity; p.stock.fuel += action.quantity; }
   else { if (p.stock.fuel < action.quantity || p.vehicle.fuelUnits + action.quantity > tankCapacity(s,p)) throw Error('Reserva insuficiente ou capacidade do tanque excedida.'); p.stock.fuel -= action.quantity; p.vehicle.fuelUnits += action.quantity; }
   note(s, action.unload ? 'Combustível transferido para reserva na carga.' : 'Tanque abastecido com combustível da carga.'); break;
  case 'repair': {
   if(!p.vehicle.integrity)throw Error('Carro destruído não reativa por reparo; aplique a perda de vida.');
   const max = r.combat[p.vehicle.modelId].integrity, cost = action.complex ? r.complexRepairCost : r.simpleRepairCost;
   if (p.vehicle.integrity >= max || p.stock.scrap < cost) throw Error('Reparo desnecessário ou sucata insuficiente.');
   if (action.complex) spend(); else { if (!p.vehicle.integrity || p.repairs >= r.simpleRepairLimit) throw Error('Simples não reativa carro zero e é limitado por turno.'); p.repairs++; }
   p.stock.scrap -= cost; p.vehicle.integrity = Math.min(max, p.vehicle.integrity + (action.complex ? r.complexRepairAmount : r.simpleRepairAmount)); note(s, 'Reparo executado; posição preservada.'); break;
  }
  case 'playGeneral': {
   if(!s.cardState) throw Error('Partida antiga: reinicie para usar o catalogo.');
   playCatalog(s,{type:'playCatalog',cardId:action.cardId,route:action.route});break;
  }
  case 'upgradeVehicle': {
   operational();if(p.vehicle.modelId!=='hatch'||!['sedan','suv','pickup','moto'].includes(action.modelId))throw Error('Melhore o hatch para Sedã, SUV, Caminhonete ou Moto.');
   payVehicleUpgrade(s,p);spend();const old=p.vehicle,newVehicle=makeVehicle(s,action.modelId);newVehicle.fuelUnits=action.modelId==='moto'?10:old.fuelUnits;newVehicle.integrity=Math.min(newVehicle.integrity,old.integrity);newVehicle.installed=old.installed;newVehicle.conditions=old.conditions;p.vehicle=newVehicle;
   note(s,p.name+': veículo melhorado para '+model(p).name+' por 5 sucatas e uma ação; vida e vidas restantes preservadas.'+(action.modelId==='moto'?' Moto entregue com 10 combustíveis no tanque.':' Combustível preservado.'));break;
  }
  case 'repairFound': {
   const found = s.found.find(v => v.vehicle.id === action.vehicleId && v.city === p.city);
   if (!found || found.vehicle.integrity > 0 || p.stock.scrap < r.complexRepairCost) throw Error('Carro encontrado não precisa de reparo ou falta sucata.');
   spend(); p.stock.scrap -= r.complexRepairCost; found.vehicle.integrity = Math.min(r.combat[found.vehicle.modelId].integrity, r.complexRepairAmount); found.repairedOnTurn = s.turn; break;
  }
  case 'swap': {
   const found = s.found.find(v => v.vehicle.id === action.vehicleId && v.city === p.city);
   if (!found || found.vehicle.integrity === 0 || found.repairedOnTurn === s.turn) throw Error('Encontre carro operacional local; reparo precisa ocorrer em turno separado.');
   if(found.vehicle.modelId==='hatch')throw Error('A melhoria exige Sedã, SUV ou Caminhonete.');payVehicleUpgrade(s,p);spend();
   if(s.cardState)for(const key of p.vehicle.installed){const card=s.cardState.installed[key];if(card){discardCatalog(s,card);delete s.cardState.installed[key];}}
   const fuel = p.vehicle.fuelUnits; p.vehicle = structuredClone(found.vehicle); p.vehicle.fuelUnits += fuel; p.vehicle.installed = [];
   s.found = s.found.filter(v => v.vehicle.id !== found.vehicle.id); note(s, 'Troca sem reabastecimento: combustível somado, carga e mão preservadas; adicionais antigos descartados. Resolva excedentes.'); break;
  }
  case 'collectScrap':
   operational(); quantity(action.quantity); if (s.localScrap[p.city] < action.quantity) throw Error('Sucata local insuficiente.');
   s.localScrap[p.city] -= action.quantity; p.stock.scrap += action.quantity;
   break;
  case 'discard': {
   quantity(action.quantity);
   if (action.territoryId) { const t = s.territories[action.territoryId]; if (!t || stockSize(t.stock) <= depotCapacity(s,t) || action.resource === 'tank') throw Error('Depósito sem excedente.'); if (t.stock[action.resource] < action.quantity) throw Error('Estoque insuficiente.'); t.stock[action.resource] -= action.quantity; }
   else { const target = s.players.find(v => v.id === (action.playerId ?? p.id)); if (!target || (target.id !== p.id && load(target)+extraCargo(s,target) <= cargoCapacity(s,target) && target.vehicle.fuelUnits <= tankCapacity(s,target))) throw Error('Sem excedente desse jogador.');
    if (action.resource === 'tank') { if (target.vehicle.fuelUnits < action.quantity) throw Error('Tanque insuficiente.'); target.vehicle.fuelUnits -= action.quantity; }
    else { if (target.stock[action.resource] < action.quantity) throw Error('Estoque insuficiente.'); target.stock[action.resource] -= action.quantity; }
   }
   note(s, `Descarte escolhido: ${action.quantity} ${action.resource}.`); break;
  }
  case 'discardCard': {
   const target = s.players.find(v => v.id === action.playerId), card = target?.hand.find(c => c.id === action.cardId);
   if (!target || !card || (target.id !== p.id && target.hand.filter(c => c.type === card.type).length <= (card.type === 'general' ? 5 : 3))) throw Error('Descarte de carta inválido.');
   target.hand = target.hand.filter(c => c.id !== card.id); if(s.cardState)discardCatalog(s,card);else s.discarded.push(card); break;
  }
  case 'end':
   cancelInvalidAnnouncements(s);
   if(!p.penaltyActive&&p.skipTurns===0&&points(s,p.id)>=rebalance.victory.points&&!s.victoryAnnouncements?.[p.id]){(s.victoryAnnouncements??={})[p.id]={declaredTurn:s.turn};note(s,`${p.name} anunciou vitória territorial; adversários podem responder até seu próximo turno.`);}
   s.travelAfterBlock=false;
   p.penaltyActive=false;
   do {s.active = (s.active + 1) % s.players.length;} while(s.players[s.active].eliminated); s.turn++; s.started = false; s.moved = false; s.actions = 1; note(s, `Passagem para ${s.players[s.active].name}.`); break;
  default: throw Error('Comando desconhecido.');
 }
 settleDeaths(s,previous);
 if(combatBefore?.eventHostile&&!s.encounter)(s.hostileDiscarded??=[]).push(combatBefore.eventHostile);
 if(previous.encounter&&!s.encounter&&s.cardState){s.cardState.pending=s.cardState.pending.filter(v=>['race','lootAttack','lootDefense'].includes(v.effect));s.cardState.used=s.cardState.used.filter(v=>!v.startsWith('round:')&&!v.startsWith('combat:'));}
 cancelInvalidAnnouncements(s);
 assertInvariants(s); return s;
}
export function canTravelThisTurn(s: Game): boolean { const p=s.players[s.active];return !p.eliminated&&!p.skipTurns&&!p.penaltyActive&& !s.moved && !!(s.actions || s.travelAfterBlock); }
function cancelInvalidAnnouncements(s:Game){
 for(const id of Object.keys(s.victoryAnnouncements??{})){if(!s.players.some(p=>String(p.id)===id&&!p.eliminated&&p.skipTurns===0&&!p.penaltyActive&&points(s,p.id)>=rebalance.victory.points)){delete s.victoryAnnouncements![id];note(s,'Anúncio territorial cancelado: pontuação abaixo de 4.');}}
}
export function assertInvariants(s: Game): void {
 assertCatalog(s);assertHostiles(s);
 const integer = (n: number) => Number.isSafeInteger(n) && n >= 0;
 if(s.initialSeed!==undefined&&(!integer(s.initialSeed)||s.initialSeed>0xffffffff))throw Error('Seed inicial inválida.');
 if (s.schemaVersion !== 4 || !integer(s.seed) || s.seed > 0xffffffff || !integer(s.nextId) || !integer(s.turn) || s.turn < 1 || !integer(s.active) || s.active >= s.players.length || ![0,1].includes(s.actions) || s.players.length < 2 || s.players.length > 4 || typeof s.started !== 'boolean' || typeof s.moved !== 'boolean' || !Array.isArray(s.blocks) || !Array.isArray(s.found)) throw Error('Estado de turno inválido.');
 const ids = new Set<string>(), register = (id: string) => { if (typeof id !== 'string' || !id || ids.has(id)) throw Error('ID duplicado/inválido.'); ids.add(id); };
 const stock = (v: Stock) => { if (!v || Object.keys(v).length !== 6 || cards.resources.some(k => !integer(v[k as Resource]))) throw Error('Estoque precisa de unidades inteiras não negativas.'); };
 const vehicle = (v: Vehicle) => { register(v.id); const def = model(v); if (!integer(v.fuelUnits) || !integer(v.integrity) || v.fixedEquipmentId !== def.fixedEquipmentId || !Array.isArray(v.installed) || v.installed.length > 2 || v.installed.some(id => typeof id !== 'string') || !Array.isArray(v.conditions) || v.conditions.some(c => typeof c !== 'string')) throw Error('Veículo inválido.'); };
 const playerIds = new Set<number>();
 for (const p of s.players) { if (!integer(p.id) || playerIds.has(p.id) || typeof p.name !== 'string' || !p.name.trim() || !cities.some(c => c.id === p.city) || !integer(p.repairs) || typeof p.usedGeneral !== 'boolean' || !integer(p.deaths) || p.deaths>2 || !integer(p.skipTurns) || p.skipTurns>1 || typeof p.penaltyActive!=='boolean' || typeof p.eliminated!=='boolean' || (p.eliminatedAtTurn!==undefined&&(!integer(p.eliminatedAtTurn)||p.eliminatedAtTurn<1||p.eliminatedAtTurn>s.turn||!p.eliminated)) || p.eliminated!==(p.deaths===2) || (!p.eliminated&&p.vehicle.integrity===0) || (p.eliminated&&(p.vehicle.integrity!==0||p.skipTurns!==0||p.penaltyActive))) throw Error('Jogador inválido.'); playerIds.add(p.id); vehicle(p.vehicle); stock(p.stock); if (!Array.isArray(p.hand)) throw Error('Mão inválida.'); }
 for (const c of [...s.players.flatMap(p => p.hand), ...s.discarded]) { register(c.id); if (!['general','equipment','territorial','race','event'].includes(c.type) || typeof c.definitionId !== 'string') throw Error('Carta inválida.'); }
 const expected = cities.flatMap(c => Array.from({length:c.regions}, (_, i) => `${c.id}-${i+1}`));
 if (Object.keys(s.territories).length !== expected.length) throw Error('Esperadas 35 sub-regiões.');
 for (const id of expected) { const t = s.territories[id]; if (!t || t.id !== id || !id.startsWith(`${t.city}-`) || !cities.some(c => c.id === t.city) || (t.owner !== null && !playerIds.has(t.owner)) || !integer(t.resistance) || !integer(t.explorations) || t.explorations > s.rules.explorationUses || (t.threat !== null && typeof t.threat !== 'string')) throw Error('Território inválido.'); stock(t.stock); }
 for (const b of s.blocks) if (!routes.some(r => r.id === b.routeId) || !playerIds.has(b.by)) throw Error('Bloqueio inválido.');

 for (const f of s.found) { vehicle(f.vehicle); if (!cities.some(c=>c.id === f.city) || (f.repairedOnTurn !== null && !integer(f.repairedOnTurn))) throw Error('Descoberta inválida.'); }
 for (const c of cities) if (!integer(s.localScrap[c.id])) throw Error('Sucata local inválida.');
 if(s.contentVersion===CONTENT_VERSION){if(!s.victoryAnnouncements||typeof s.victoryAnnouncements!=='object'||Array.isArray(s.victoryAnnouncements)||typeof s.travelAfterBlock!=='boolean')throw Error('Estado de rebalanceamento inválido.');for(const [id,a] of Object.entries(s.victoryAnnouncements)){if(!s.players.some(p=>String(p.id)===id)||!a||!integer(a.declaredTurn)||a.declaredTurn<1||a.declaredTurn>s.turn)throw Error('Anúncio territorial inválido.');}}
 if (!Array.isArray(s.log) || s.log.some(v=>typeof v !== 'string') || (s.winner !== null && !playerIds.has(s.winner))) throw Error('Histórico/resultado inválido.');
 if (s.encounter) { const e = s.encounter; if (e.kind !== 'combat' || !playerIds.has(e.actorId) || (e.territoryId ? !s.territories[e.territoryId] : e.eventIntegrity===undefined && !playerIds.has(e.defenderId!)) || typeof e.betweenRounds !== 'boolean' || typeof e.lootResolved !== 'boolean') throw Error('Combate inválido.'); }
 if(s.encounter?.lastRoll){const roll=s.encounter.lastRoll;if(!integer(roll.natural)||roll.natural<1||roll.natural>6||!Number.isSafeInteger(roll.total)||!integer(roll.defense)||roll.defense>6||typeof roll.hit!=='boolean')throw Error('Resultado de combate inválido.');}
}

