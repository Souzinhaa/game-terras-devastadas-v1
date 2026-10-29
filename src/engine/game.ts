import { initHostiles, migrateHostiles, attachHostile, startHostileCombat, nextHostileRound, hostileEscapeModifier, assertHostiles, type HostileInstance, type HostileContext, type HostileConfig, type HostileTier } from './hostiles';
import { initCatalog, assertCatalog, drawCatalog, discardCatalog, resolveEvent, handleCardAction, playCatalog, cargoCapacity, tankCapacity, extraCargo, depotCapacity, equipment, takeModifier, resolveAttack, counterAttack, type CatalogState, type CardAction } from './cardRules';
import cities from '../data/cities.json';
import routes from '../data/routes.json';
import cards from '../data/cards.json';
import vehicles from '../data/vehicles.json';
import { laboratoryRules, type RuleConfig } from './config';
export { cities, routes, cards, vehicles };
export const CONTENT_VERSION = '0.4.2';
export type ModelId = 'hatch' | 'sedan' | 'suv' | 'pickup';
export type Resource = 'fuel' | 'scrap' | 'tire' | 'battery' | 'water' | 'ammo';
export type Stock = Record<Resource, number>;
export interface Card { id: string; instanceId?: string; definitionId: string; type: 'general' | 'equipment' | 'territorial' | 'race' | 'event' }
export interface Vehicle { id: string; modelId: ModelId; integrity: number; fuelUnits: number; fixedEquipmentId: string; installed: string[]; conditions: string[] }
export interface Player { id: number; name: string; city: string; vehicle: Vehicle; stock: Stock; hand: Card[]; repairs: number; usedGeneral: boolean }
export interface Territory { hostile?: HostileInstance; difficulty?: HostileTier; difficultyPending?: boolean; installed?: string[]; id: string; city: string; label: string; owner: number | null; threat: string | null; resistance: number; explorations: number; stock: Stock }
export interface Block { sourceCardId?: string; sourceInstanceId?: string; routeId: string; by: number }
export interface FoundVehicle { city: string; vehicle: Vehicle; repairedOnTurn: number | null }
export interface Combat { eventHostile?: HostileInstance; hostileContext?: HostileContext; lastRoll?: {natural:number;total:number;defense:number;hit:boolean}; threatTurn?: boolean; eventIntegrity?: number; kind: 'combat'; territoryId?: string; defenderId?: number; actorId: number; betweenRounds: boolean; lootResolved: boolean }
export interface Game { hostileConfig?: HostileConfig; hostileDiscarded?: HostileInstance[]; cardState?: CatalogState; schemaVersion: 4; contentVersion: string; seed: number; nextId: number; turn: number; active: number; actions: number; started: boolean; moved: boolean; players: Player[]; territories: Record<string, Territory>; encounter: Combat | null; blocks: Block[]; found: FoundVehicle[]; localScrap: Record<string, number>; discarded: Card[]; log: string[]; rules: RuleConfig; winner: number | null }
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
 | { type: 'collectScrap'; quantity: number } | { type: 'end' };
export const emptyStock = (): Stock => ({ fuel: 0, scrap: 0, tire: 0, battery: 0, water: 0, ammo: 0 });
export const model = (p: Player | Vehicle) => { const id = 'vehicle' in p ? p.vehicle.modelId : p.modelId; const v = vehicles.find(v => v.id === id); if (!v) throw Error('Modelo desconhecido.'); return v; };
export const load = (p: Player) => Object.values(p.stock).reduce((a, b) => a + b, 0);
export const stockSize = (stock: Stock) => Object.values(stock).reduce((a, b) => a + b, 0);
export function random(s: Game, max: number) { s.seed = (Math.imul(s.seed, 1664525) + 1013904223) >>> 0; return Math.floor(s.seed / 4294967296 * max); }
const die = (s: Game) => random(s, 6) + 1;
const note = (s: Game, message: string) => { s.log.push(`T${s.turn} · ${message}`); };
export function makeVehicle(s: Game, modelId: ModelId): Vehicle {
 const definition = vehicles.find(v => v.id === modelId)!;
 return { id: `vehicle-${s.nextId++}`, modelId, integrity: s.rules.combat[modelId].integrity, fuelUnits: 0, fixedEquipmentId: definition.fixedEquipmentId, installed: [], conditions: [] };
}
function draw(s: Game, p: Player) { if(s.cardState) drawCatalog(s, 'general', p); else p.hand.push({ id: `card-${s.nextId++}`, definitionId: cards.generals[random(s, cards.generals.length)].id, type: 'general' }); }
export function createGame(names: string[], seed: number, rules = laboratoryRules): Game {
 if (names.length < 2 || names.length > 4 || names.some(n => !n.trim()) || !Number.isSafeInteger(seed) || seed < 0 || seed > 0xffffffff) throw Error('Informe 2–4 nomes e uma seed inteira de 0 a 4294967295.');
 const s: Game = { schemaVersion: 4, contentVersion: CONTENT_VERSION, seed, nextId: 1, turn: 1, active: 0, actions: 1, started: false, moved: false, players: [], territories: {}, encounter: null, blocks: [], found: [], localScrap: {}, discarded: [], log: [], rules: structuredClone(rules), winner: null };
 const availableCities = [...cities];
 initCatalog(s);initHostiles(s);
 for (const city of cities) {
  s.localScrap[city.id] = 0;
  for (let i = 1; i <= city.regions; i++) { const id = `${city.id}-${i}`; s.territories[id] = { id, city: city.id, label: `Setor ${i}`, owner: null, threat: null, resistance: rules.territoryIntegrity, explorations: 0, stock: emptyStock() };attachHostile(s,s.territories[id]); }
 }
 for (const [id, name] of names.entries()) {
  const city = availableCities.splice(random(s, availableCities.length), 1)[0];
  const vehicle = makeVehicle(s, vehicles[random(s, vehicles.length)].id as ModelId); vehicle.fuelUnits = model(vehicle).tank;
  const p: Player = { id, name: name.trim(), city: city.id, vehicle, stock: { ...emptyStock(), scrap: 1 }, hand: [], repairs: 0, usedGeneral: false };
  draw(s, p); draw(s, p); s.players.push(p);
  const t = s.territories[`${city.id}-${random(s, city.regions) + 1}`]; t.owner = id;t.resistance=rules.territoryIntegrity;t.threat = null;delete t.hostile;
 }
 for (let i = s.players.length - 1; i > 0; i--) { const j = random(s, i + 1); [s.players[i], s.players[j]] = [s.players[j], s.players[i]]; }
 note(s, 'GDD v0.4: ordem, carros e posições sorteados; tanque cheio, 1 sucata e 2 gerais. Inicie o turno para comprar a geral da vez.');
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
 if (!route || (route.from !== p.city && route.to !== p.city)) return 'Rota não adjacente.';
 if (!model(p).allowedSurfaces.includes(route.terrain)) return 'Terra: somente SUV e Caminhonete.';
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
function disable(s: Game, loser: Player, winner?: Player) {
 if (winner) steal(s, winner, loser);
 s.discarded.push(...loser.hand.filter(c => c.type === 'equipment')); loser.hand = loser.hand.filter(c => c.type !== 'equipment');
 note(s, `${loser.name}: carro inutilizado, recuperável no local.`);
}
export function transition(previous: Game, action: Action): Game {
 const s = structuredClone(previous), p = s.players[s.active], r = s.rules;if(!s.hostileConfig&&s.contentVersion!==CONTENT_VERSION){migrateHostiles(s);s.contentVersion=CONTENT_VERSION;}const combatBefore=s.encounter;
 const resolving = ['discard', 'discardCard', 'transfer', 'refuel'].includes(action.type);
 if (capacityIssues(s).length && !resolving) throw Error('Resolva excedentes de carga, tanque, depósito ou mão antes de continuar.');
 if (s.winner !== null && !resolving) throw Error('Partida encerrada.');
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
   if(s.cardState){s.cardState.used=[];s.cardState.pending=[];}s.blocks = s.blocks.filter(b => b.by !== p.id); s.started = true; s.actions = 1; s.moved = false; p.repairs = 0; s.players.forEach(p => { p.usedGeneral = false; }); draw(s, p); note(s, `${p.name} comprou 1 geral; bloqueios próprios expiraram.`); break;
  case 'move': {
   operational(); if (s.moved || !s.actions) throw Error('Viaje uma vez, antes da ação principal.');
   travel(s, p, action.route); s.moved = true;
   if(s.cardState) resolveEvent(s,p);
   break;
  }
  case 'conquer': {
   operational(); const t = local(action.territoryId, false);
   if (t.owner === p.id) throw Error('Território já pertence ao jogador.');
   if (t.owner !== null && s.players.some(v=>v.id===t.owner&&v.city===p.city&&v.vehicle.integrity>0)) throw Error('Defensor pessoal presente: enfrente o carro antes de atacar a fortificação.');
   spend(); s.encounter = { kind: 'combat', territoryId: t.id, actorId: p.id, betweenRounds: false, lootResolved: false }; startHostileCombat(s,s.encounter);note(s, `${p.name} enfrenta ${t.threat??'a defesa territorial'}.`); break;
  }
  case 'duel': {
   operational(); const defender = s.players.find(v => v.id === action.defenderId);
   if (!defender || defender.id === p.id || defender.city !== p.city || !defender.vehicle.integrity) throw Error('Oponente operacional precisa estar na mesma cidade.');
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
   const hostilePenalty=hostileEscapeModifier(s,e);const roll = die(s) + r.combat[fleeing.vehicle.modelId].agility + equipment(s,fleeing,'E09').length + takeModifier(s,fleeing.id,'escape')+hostilePenalty; note(s, `Fuga: resultado ${roll}, alvo ${r.escapeTarget}+${hostilePenalty?' (hostil '+hostilePenalty+')':''}.`);
   if (roll >= r.escapeTarget) { travel(s, fleeing, action.route); if (opponent) steal(s, opponent, fleeing); s.encounter = null; }
   break;
  }
  case 'explore': {
   operational(); const t = local(action.territoryId); if (t.explorations >= r.explorationUses) throw Error('Três explorações já utilizadas.');
   spend(); t.explorations++; const resource = cards.resources[random(s, cards.resources.length)] as Resource;
   t.stock[resource] += r.lootQuantity; note(s, `${t.label}: ${r.lootQuantity} ${resource} no depósito (perfil genérico provisório).`); break;
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
   const max = r.combat[p.vehicle.modelId].integrity, cost = action.complex ? r.complexRepairCost : r.simpleRepairCost;
   if (p.vehicle.integrity >= max || p.stock.scrap < cost) throw Error('Reparo desnecessário ou sucata insuficiente.');
   if (action.complex) spend(); else { if (!p.vehicle.integrity || p.repairs >= r.simpleRepairLimit) throw Error('Simples não reativa carro zero e é limitado por turno.'); p.repairs++; }
   p.stock.scrap -= cost; p.vehicle.integrity = Math.min(max, p.vehicle.integrity + (action.complex ? r.complexRepairAmount : r.simpleRepairAmount)); note(s, 'Reparo executado; posição preservada.'); break;
  }
  case 'playGeneral': {
   if(!s.cardState) throw Error('Partida antiga: reinicie para usar o catalogo.');
   playCatalog(s,{type:'playCatalog',cardId:action.cardId,route:action.route});break;
  }
  case 'repairFound': {
   const found = s.found.find(v => v.vehicle.id === action.vehicleId && v.city === p.city);
   if (!found || found.vehicle.integrity > 0 || p.stock.scrap < r.complexRepairCost) throw Error('Carro encontrado não precisa de reparo ou falta sucata.');
   spend(); p.stock.scrap -= r.complexRepairCost; found.vehicle.integrity = Math.min(r.combat[found.vehicle.modelId].integrity, r.complexRepairAmount); found.repairedOnTurn = s.turn; break;
  }
  case 'swap': {
   const found = s.found.find(v => v.vehicle.id === action.vehicleId && v.city === p.city);
   if (!found || found.vehicle.integrity === 0 || found.repairedOnTurn === s.turn) throw Error('Encontre carro operacional local; reparo precisa ocorrer em turno separado.');
   spend(); s.localScrap[p.city] += r.swapScrap;
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
   s.active = (s.active + 1) % s.players.length; s.turn++; s.started = false; s.moved = false; s.actions = 1; note(s, `Passagem para ${s.players[s.active].name}.`); break;
  default: throw Error('Comando desconhecido.');
 }
 if(combatBefore?.eventHostile&&!s.encounter)(s.hostileDiscarded??=[]).push(combatBefore.eventHostile);
 if(previous.encounter&&!s.encounter&&s.cardState){s.cardState.pending=s.cardState.pending.filter(v=>['race','lootAttack','lootDefense'].includes(v.effect));s.cardState.used=s.cardState.used.filter(v=>!v.startsWith('round:')&&!v.startsWith('combat:'));}
 if (!s.encounter && !s.cardState?.race && !capacityIssues(s).length) s.winner = s.players.find(v => points(s, v.id) >= 4)?.id ?? null;
 assertInvariants(s); return s;
}
export function assertInvariants(s: Game): void {
 assertCatalog(s);assertHostiles(s);
 const integer = (n: number) => Number.isSafeInteger(n) && n >= 0;
 if (s.schemaVersion !== 4 || !integer(s.seed) || s.seed > 0xffffffff || !integer(s.nextId) || !integer(s.turn) || s.turn < 1 || !integer(s.active) || s.active >= s.players.length || ![0,1].includes(s.actions) || s.players.length < 2 || s.players.length > 4 || typeof s.started !== 'boolean' || typeof s.moved !== 'boolean' || !Array.isArray(s.blocks) || !Array.isArray(s.found)) throw Error('Estado de turno inválido.');
 const ids = new Set<string>(), register = (id: string) => { if (typeof id !== 'string' || !id || ids.has(id)) throw Error('ID duplicado/inválido.'); ids.add(id); };
 const stock = (v: Stock) => { if (!v || Object.keys(v).length !== 6 || cards.resources.some(k => !integer(v[k as Resource]))) throw Error('Estoque precisa de unidades inteiras não negativas.'); };
 const vehicle = (v: Vehicle) => { register(v.id); const def = model(v); if (!integer(v.fuelUnits) || !integer(v.integrity) || v.fixedEquipmentId !== def.fixedEquipmentId || !Array.isArray(v.installed) || v.installed.length > 2 || v.installed.some(id => typeof id !== 'string') || !Array.isArray(v.conditions) || v.conditions.some(c => typeof c !== 'string')) throw Error('Veículo inválido.'); };
 const playerIds = new Set<number>();
 for (const p of s.players) { if (!integer(p.id) || playerIds.has(p.id) || typeof p.name !== 'string' || !p.name.trim() || !cities.some(c => c.id === p.city) || !integer(p.repairs) || typeof p.usedGeneral !== 'boolean') throw Error('Jogador inválido.'); playerIds.add(p.id); vehicle(p.vehicle); stock(p.stock); if (!Array.isArray(p.hand)) throw Error('Mão inválida.'); }
 for (const c of [...s.players.flatMap(p => p.hand), ...s.discarded]) { register(c.id); if (!['general','equipment','territorial','race','event'].includes(c.type) || typeof c.definitionId !== 'string') throw Error('Carta inválida.'); }
 const expected = cities.flatMap(c => Array.from({length:c.regions}, (_, i) => `${c.id}-${i+1}`));
 if (Object.keys(s.territories).length !== expected.length) throw Error('Esperadas 35 sub-regiões.');
 for (const id of expected) { const t = s.territories[id]; if (!t || t.id !== id || !id.startsWith(`${t.city}-`) || !cities.some(c => c.id === t.city) || (t.owner !== null && !playerIds.has(t.owner)) || !integer(t.resistance) || !integer(t.explorations) || t.explorations > s.rules.explorationUses || (t.threat !== null && typeof t.threat !== 'string')) throw Error('Território inválido.'); stock(t.stock); }
 for (const b of s.blocks) if (!routes.some(r => r.id === b.routeId) || !playerIds.has(b.by)) throw Error('Bloqueio inválido.');

 for (const f of s.found) { vehicle(f.vehicle); if (!cities.some(c=>c.id === f.city) || (f.repairedOnTurn !== null && !integer(f.repairedOnTurn))) throw Error('Descoberta inválida.'); }
 for (const c of cities) if (!integer(s.localScrap[c.id])) throw Error('Sucata local inválida.');
 if (!Array.isArray(s.log) || s.log.some(v=>typeof v !== 'string') || (s.winner !== null && !playerIds.has(s.winner))) throw Error('Histórico/resultado inválido.');
 if (s.encounter) { const e = s.encounter; if (e.kind !== 'combat' || !playerIds.has(e.actorId) || (e.territoryId ? !s.territories[e.territoryId] : e.eventIntegrity===undefined && !playerIds.has(e.defenderId!)) || typeof e.betweenRounds !== 'boolean' || typeof e.lootResolved !== 'boolean') throw Error('Combate inválido.'); }
 if(s.encounter?.lastRoll){const roll=s.encounter.lastRoll;if(!integer(roll.natural)||roll.natural<1||roll.natural>6||!Number.isSafeInteger(roll.total)||!integer(roll.defense)||roll.defense>6||typeof roll.hit!=='boolean')throw Error('Resultado de combate inválido.');}
}

