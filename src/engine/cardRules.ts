import { combatHostile, hostileDefinition, makeHostile, startHostileCombat, hostileContext, nextHostileRound, setHostileHealth, hostileAttackModifier, hostileDamageBonus, hostileHitReduction } from './hostiles';
import { catalog, cardDefinition, tracks, type Deck } from './catalog';
import { random, rollDie, recordCombatRoll, vehicleAttackBlock, model, routes, routeReason, makeVehicle, vehicles, type Game, type Player, type Card, type Action, type Resource, type Territory } from './game';
export interface CatalogState {
 decks: Record<Deck, Card[]>; discarded: Record<Deck, Card[]>; installed: Record<string, Card>;
 used: string[]; pending: {sourceCardId?:string;sourceInstanceId?:string;sourcePlayerId?:number;playerId:number; effect:'attack'|'damage'|'reduceDamage'|'fortificationReduction'|'escape'|'race'|'threat'|'threatDamage'|'lootAttack'|'lootDefense';amount:number}[];
 lastCard?: string; choice?: {card:Card; playerId:number; kind:'resource'|'inspect'|'raceTarget'; targets?:number[]};
 race?: {trackId:string; phase:'entry'|'running'; responses:number[]; entrants:{playerId:number;progress:number;markers:number[];next:number;withdrawn?:boolean;queued?:{sourceCardId:string;sourceInstanceId:string;amount:number}[]}[]; cursor:number; finalRound:boolean};
}
export type CardAction =
 | {type:'winch';instanceId:string;territoryId:string}
 | {type:'playCatalog';cardId:string;playerId?:number;targetId?:number;territoryId?:string;route?:string}
 | {type:'install';cardId:string;territoryId?:string;replaceId?:string} | {type:'removeUpgrade';instanceId:string;territoryId?:string}
 | {type:'buyImprovement'} | {type:'useEquipment';instanceId:string} | {type:'equipmentAttack';instanceId:string}
 | {type:'repairTerritory';territoryId:string} | {type:'loot';territoryId:string;resource:Resource}
 | {type:'cardChoice';resource?:Resource;targetId?:number;bottom?:boolean}
 | {type:'raceEntry';playerId:number;join:boolean} | {type:'raceRoll'};
const log = (s:Game,text:string) => s.log.push(`T${s.turn} · ${text}`);
export function initCatalog(s:Game) {
 const state:CatalogState={decks:{general:[],improvements:[],race:[],events:[]},discarded:{general:[],improvements:[],race:[],events:[]},installed:{},used:[],pending:[]};
 for(const d of catalog) for(let i=0;i<d.copies;i++){const instanceId=`card-${s.nextId++}`;state.decks[d.deck].push({id:instanceId,instanceId,definitionId:d.id,type:d.type});}
 for(const deck of Object.values(state.decks)) shuffle(s,deck);
 s.cardState=state;
}
/** Migra somente conteúdo de cartas: preserva RNG, mãos, posição e recursos. */
export function migrateCatalog(s:Game) {
 if(s.cardState)return;
 const seed=s.seed;initCatalog(s);s.seed=seed;s.rules.raceEnabled=true;
 for(const card of [...s.players.flatMap(p=>p.hand),...s.discarded]){
  const d=cardDefinition(card.definitionId);if(!d)continue;
  card.definitionId=d.id;card.instanceId=card.id;const deck=s.cardState!.decks[d.deck],i=deck.findIndex(v=>v.definitionId===d.id);
  if(i>=0)deck.splice(i,1);
 }
}
export function assertCatalog(s:Game) {
 const c=s.cardState;if(!c)return;
 const ids=new Set<string>();
 const register=(card:Card)=>{const d=cardDefinition(card?.definitionId);if(!card||typeof card.id!=='string'||!card.id||ids.has(card.id)||!d||card.type!==d.type)throw Error('ID duplicado/inválido de carta.');ids.add(card.id);};
 for(const deck of ['general','improvements','race','events'] as const){if(!Array.isArray(c.decks?.[deck])||!Array.isArray(c.discarded?.[deck]))throw Error('Baralho inválido.');for(const card of [...c.decks[deck],...c.discarded[deck]]){register(card);if(cardDefinition(card.definitionId)?.deck!==deck)throw Error('Carta no baralho incorreto.');}}
 for(const card of [...s.players.flatMap(p=>p.hand),...s.discarded]){if(cardDefinition(card.definitionId))register(card);}
 if(!c.installed||!Array.isArray(c.pending)||!Array.isArray(c.used)||c.used.some(v=>typeof v!=='string'))throw Error('Estado das cartas inválido.');
 for(const [key,card] of Object.entries(c.installed)){if(key!==card.id)throw Error('Instalação inválida.');register(card);const references=[...s.players.flatMap(p=>p.vehicle.installed),...Object.values(s.territories).flatMap(t=>t.installed??[])].filter(v=>v===key);if(references.length!==1)throw Error('Instalação sem dono ou duplicada.');}
 const player=(id:number)=>s.players.some(p=>p.id===id);
 if(c.pending.some(v=>!player(v.playerId)||!Number.isSafeInteger(v.amount)||!['attack','damage','reduceDamage','fortificationReduction','escape','race','threat','threatDamage','lootAttack','lootDefense'].includes(v.effect)))throw Error('Modificador inválido.');
 if(c.choice&&(!player(c.choice.playerId)||!cardDefinition(c.choice.card.definitionId)||!['resource','inspect','raceTarget'].includes(c.choice.kind)))throw Error('Escolha inválida.');
 if(c.race){const r=c.race;if(!tracks.some(t=>t.id===r.trackId)||!['entry','running'].includes(r.phase)||!Array.isArray(r.responses)||new Set(r.responses).size!==r.responses.length||r.responses.some(v=>!player(v))||!Array.isArray(r.entrants)||new Set(r.entrants.map(v=>v.playerId)).size!==r.entrants.length||r.entrants.some(v=>!player(v.playerId)||!Number.isSafeInteger(v.progress)||v.progress<0||!Number.isSafeInteger(v.next)||!Array.isArray(v.markers))||!Number.isSafeInteger(r.cursor)||r.cursor<0||(r.phase==='running'&&(r.entrants.length<2||r.cursor>=r.entrants.length)))throw Error('Corrida inválida.');}
}
function shuffle(s:Game,deck:Card[]) { for(let i=deck.length-1;i>0;i--){const j=random(s,i+1);[deck[i],deck[j]]=[deck[j],deck[i]];} }
export function drawCatalog(s:Game,deck:Deck,p?:Player) {
 const c=s.cardState!; if(!c.decks[deck].length){c.decks[deck]=c.discarded[deck].splice(0);shuffle(s,c.decks[deck]);}
 const card=c.decks[deck].shift(); if(card&&p)p.hand.push(card); return card;
}
export function discardCatalog(s:Game,card:Card) { const d=cardDefinition(card.definitionId); if(d)s.cardState!.discarded[d.deck].push(card);else s.discarded.push(card); }
export const equipment = (s:Game,p:Player,id:string) => p.vehicle.installed.filter(key=>s.cardState?.installed[key]?.definitionId===id);
export const territorial = (s:Game,t:Territory,id:string) => (t.installed??[]).filter(key=>s.cardState?.installed[key]?.definitionId===id);
export const tankCapacity = (s:Game,p:Player) => model(p).tank+equipment(s,p,'E07').length*3;
export const cargoCapacity = (s:Game,p:Player) => model(p).capacity+equipment(s,p,'E08').length*2;
export const extraCargo = (s:Game,p:Player) => p.vehicle.installed.reduce((sum,key)=>sum+(cardDefinition(s.cardState?.installed[key]?.definitionId??'')?.extraCargo??0),0);
export const depotCapacity = (s:Game,t:Territory) => 10+territorial(s,t,'T04').length*5;
export const defenseMax = (s:Game,t:Territory) => s.rules.territoryIntegrity+territorial(s,t,'T01').length*2;
export const vehicleDefense = (s:Game,p:Player) => Math.min(6,s.rules.combat[p.vehicle.modelId].defense+equipment(s,p,'E04').length);
export function takeModifier(s:Game,id:number,effect:CatalogState['pending'][number]['effect']) { const c=s.cardState;if(!c)return 0;const n=c.pending.filter(v=>v.playerId===id&&v.effect===effect).reduce((n,v)=>n+v.amount,0);c.pending=c.pending.filter(v=>v.playerId!==id||v.effect!==effect);return n; }
function hurt(s:Game,p:Player,n:number,_winner?:Player) { p.vehicle.integrity=Math.max(0,p.vehicle.integrity-n); }
function gain(p:Player,resource:Resource,amount:number) { if(resource==='fuel')p.vehicle.fuelUnits+=amount;else p.stock[resource]+=amount; }
export function resolveEvent(s:Game,p:Player) {
 const card=drawCatalog(s,'events');if(!card)return;const c=s.cardState!;c.lastCard=card.definitionId;log(s,`Evento: ${cardDefinition(card.definitionId)!.name}.`);discardCatalog(s,card);
 switch(card.definitionId){
 case 'V01':case 'V02':break;
 case 'V03':p.stock.scrap++;break;case 'V04':p.vehicle.fuelUnits+=2;break;case 'V05':p.vehicle.fuelUnits=Math.max(0,p.vehicle.fuelUnits-1);break;
 case 'V06':hurt(s,p,1);break;
 case 'V07':if(Object.values(p.stock).some(n=>n>0))c.choice={card,playerId:p.id,kind:'resource'};break;
 case 'V08':p.stock.battery++;break;case 'V09':p.stock.tire++;break;
 case 'V10':c.choice={card,playerId:p.id,kind:'resource'};break;case 'V11':s.actions=0;break;
 case 'V12':case 'V13':case 'V14':if(s.rules.raceEnabled)c.race={trackId:`P0${Number(card.definitionId.slice(1))-11}`,phase:'entry',responses:s.players.filter(v=>v.eliminated||v.skipTurns>0||v.penaltyActive).map(v=>v.id),entrants:[],cursor:0,finalRound:false};else log(s,'Corrida desativada na configuração desta partida.');break;
 case 'V15':{s.actions=0;const hostile=makeHostile(s,'easy','event',card.id);s.encounter={kind:'combat',actorId:p.id,betweenRounds:false,lootResolved:false,eventIntegrity:hostile.currentHealth,eventHostile:hostile};startHostileCombat(s,s.encounter);break;}
 case 'V16':{const available=vehicles.filter(v=>!s.players.some(p=>p.vehicle.modelId===v.id)&&!s.found.some(f=>f.vehicle.modelId===v.id));if(available.length)s.found.push({city:p.city,vehicle:makeVehicle(s,available[random(s,available.length)].id as Player['vehicle']['modelId']),repairedOnTurn:null});break;}
 }
}
function targetPlayer(s:Game,id:number|undefined,fallback:Player) { const p=id===undefined?fallback:s.players.find(p=>p.id===id);if(!p||p.eliminated||p.skipTurns>0||p.penaltyActive)throw Error('Jogador alvo indisponível.');return p; }
function beforeAction(s:Game) { if(s.encounter||s.cardState?.race||!s.actions)throw Error('Use antes de uma ação, fora de combate/corrida.'); }
export function playCatalog(s:Game,a:Extract<CardAction,{type:'playCatalog'}>) {
 const c=s.cardState!,p=targetPlayer(s,a.playerId,s.players[s.active]),card=p.hand.find(v=>v.id===a.cardId&&v.type==='general'),d=cardDefinition(card?.definitionId??'');
 if(!card||!d||p.usedGeneral)throw Error('Carta indisponível ou cota geral já usada neste turno do mapa.');
 const target=targetPlayer(s,a.targetId,p),t=a.territoryId?s.territories[a.territoryId]:undefined,e=s.encounter;
 const pending=(effect:CatalogState['pending'][number]['effect'],amount:number,id=target.id)=>c.pending.push({effect,amount,playerId:id,sourceCardId:d.id,sourceInstanceId:card.id,sourcePlayerId:p.id});
 switch(d.id){
 case 'G01':case 'G02':case 'G03':case 'G04':case 'G07': {
 if(!e)throw Error('Declare antes de um ataque em combate.');
 const attacker=e.threatTurn?-1:e.betweenRounds?s.players[s.active].id:e.actorId;
 if(d.id==='G07'){if(!e.threatTurn)throw Error('Exige ataque de ameaça.');pending('threat',1,s.players[s.active].id);}
 else if(e.threatTurn&&d.id!=='G04'){if(e.territoryId&&a.territoryId!==e.territoryId)throw Error('Selecione a ameaça atacante.');pending(d.id==='G03'?'threatDamage':'threat',d.id==='G02'?-1:1,s.players[s.active].id);}
 else if(d.id==='G04'&&!e.threatTurn&&e.defenderId===undefined){if(e.territoryId&&a.territoryId!==e.territoryId)throw Error('Selecione a defesa que receberá o próximo ataque.');pending('fortificationReduction',1,attacker);}
 else {const expected=d.id==='G04'?(e.threatTurn?s.players[s.active].id:attacker===s.players[s.active].id?e.defenderId:s.players[s.active].id):attacker;
 if(expected===undefined||target.id!==expected)throw Error('Alvo incompatível com o próximo ataque.');pending(d.id==='G03'?'damage':d.id==='G04'?'reduceDamage':'attack',d.id==='G02'?-1:1); }break;}
 case 'G05':case 'G06':if(!e?.betweenRounds||![s.players[s.active].id,e.defenderId].includes(target.id))throw Error('Exige participante tentando fugir entre rodadas.');pending('escape',d.id==='G05'?1:-1);break;
 case 'G08':{beforeAction(s);const max=t?.hostile?hostileDefinition(t.hostile.definitionId)!.maxHealth:s.rules.territoryIntegrity;if(!t?.threat||t.owner!==null||t.resistance>=max||t.hostile&&!t.hostile.revealed)throw Error('Selecione ameaça revelada e danificada.');if(t.hostile)setHostileHealth(s,t.hostile,t.resistance+2);else t.resistance=Math.min(max,t.resistance+2);break;}
 case 'G09':beforeAction(s);gain(target,'fuel',1);break;
 case 'G10':beforeAction(s);if(!target.vehicle.integrity||target.vehicle.integrity>=s.rules.combat[target.vehicle.modelId].integrity)throw Error('Exige carro operacional danificado.');target.vehicle.integrity=Math.min(s.rules.combat[target.vehicle.modelId].integrity,target.vehicle.integrity+2);break;
 case 'G11':case 'G12':case 'G13':case 'G14':case 'G24':beforeAction(s);if(p.id!==s.players[s.active].id)throw Error('Somente antes de sua ação.');{const effect=d.effects[0];if(effect.kind==='resource')gain(p,effect.resource,effect.amount);}break;
 case 'G15':beforeAction(s);if(p.id!==s.players[s.active].id||!drawCatalog(s,'improvements',p))throw Error('Compra sem alvo legal.');break;
 case 'G16':beforeAction(s);if(s.moved||target.id!==s.players[s.active].id||!routes.some(r=>!routeReason(s,target,r.id)))throw Error('Exige viajante apto antes da viagem.');if(!c.decks.events.length){const top=drawCatalog(s,'events');if(top)c.decks.events.unshift(top);}if(!c.decks.events.length)throw Error('Baralho vazio.');c.choice={kind:'inspect',card:c.decks.events[0],playerId:p.id};break;
 case 'G17':case 'G18':beforeAction(s);{const route=routes.find(r=>r.id===a.route);if(!route)throw Error('Rota inexistente.');if(d.id==='G17'){if(p.id!==s.players[s.active].id||s.moved)throw Error('G17 somente no turno próprio, antes de viajar ou agir.');if(s.blocks.some(b=>b.by===p.id))throw Error('Um bloqueio próprio já está ativo.');const deposits=Object.values(s.territories).filter(t=>t.owner===p.id&&t.city===p.city);if(p.stock.scrap+deposits.reduce((n,t)=>n+t.stock.scrap,0)<1)throw Error('G17 exige 1 sucata própria local.');if(s.blocks.some(b=>b.routeId===route.id))throw Error('Rota já bloqueada.');s.blocks.push({routeId:route.id,by:p.id,sourceCardId:d.id,sourceInstanceId:card.id});if(s.players.some(v=>!v.eliminated&&!v.skipTurns&&!v.penaltyActive&&[route.from,route.to].includes(v.city)&&!routes.some(r=>routeReason(s,v,r.id,false)===null)))throw Error('Bloqueio deixaria carro presente sem saída compatível.');if(p.stock.scrap)p.stock.scrap--;else deposits.find(t=>t.stock.scrap>0)!.stock.scrap--;s.actions=0;s.travelAfterBlock=true;log(s,'Barricada: 1 sucata e ação principal consumidas; viagem posterior continua disponível.');}else{const i=s.blocks.findIndex(b=>b.routeId===route.id);if(i<0)throw Error('Rota não está bloqueada.');s.blocks.splice(i,1);}}break;
 case 'G19':case 'G20':beforeAction(s);if(!t||t.owner===null||t.owner===s.players[s.active].id||t.city!==s.players[s.active].city||!Object.values(t.stock).some(n=>n))throw Error('Selecione depósito rival local para disputa de saque.');pending(d.id==='G19'?'lootAttack':'lootDefense',1,d.id==='G19'?s.players[s.active].id:t.owner);break;
 case 'G21':case 'G22':{const race=c.race;if(!race||race.phase!=='running'||race.entrants[race.cursor]?.playerId!==target.id||!target.vehicle.integrity)throw Error('Declare antes do avanço do próximo participante.');pending('race',d.id==='G21'?1:-1);break;}
 case 'G23':beforeAction(s);if(!t||t.owner!==p.id||t.resistance>=defenseMax(s,t))throw Error('Selecione defesa própria danificada.');t.resistance=Math.min(defenseMax(s,t),t.resistance+2);break;
 default:throw Error('Efeito geral desconhecido.');
 }
 p.hand=p.hand.filter(v=>v.id!==card.id);discardCatalog(s,card);p.usedGeneral=true;log(s,`${p.name}: ${d.name}.`);
}
function remove(s:Game,key:string,t?:Territory) {const c=s.cardState!,card=c.installed[key];if(!card)throw Error('Melhoria inexistente.');if(t){t.installed=(t.installed??[]).filter(v=>v!==key);if(card.definitionId==='T01')t.resistance=Math.max(0,t.resistance-2);}else{const owner=s.players.find(v=>v.vehicle.installed.includes(key));if(!owner)throw Error('Equipamento sem dono.');owner.vehicle.installed=owner.vehicle.installed.filter(v=>v!==key);if(extraCargo(s,owner)>cargoCapacity(s,owner))throw Error('Retire primeiro o equipamento que ocupa carga extra.');}delete c.installed[key];discardCatalog(s,card);}
export function conquerUpgrades(s:Game,t:Territory) {for(const key of [...(t.installed??[])])remove(s,key,t);}
export function handleCardAction(s:Game,a:Action):boolean {
 const c=s.cardState;if(!c)return false;const p=s.players[s.active];
 switch(a.type){
 case 'winch':{if(s.encounter||c.race)throw Error('Guincho fora de combate/corrida.');const t=s.territories[a.territoryId],usage=`turn:${s.turn}:${a.instanceId}`;if(!equipment(s,p,'E11').includes(a.instanceId)||c.used.includes(usage)||!p.vehicle.integrity||!t||t.owner!==p.id||t.city!==p.city||s.localScrap[p.city]<1)throw Error('Guincho exige sucata local, depósito próprio e uso disponível.');s.localScrap[p.city]--;t.stock.scrap++;c.used.push(usage);return true;}
 case 'playCatalog':playCatalog(s,a);return true;
 case 'buyImprovement':if(s.encounter||c.race)throw Error('Compra fora de combate/corrida.');if(c.used.includes(`buy:${s.turn}`)||p.stock.scrap<3)throw Error('Compra limitada a uma por turno, custo 3 sucatas.');if(!drawCatalog(s,'improvements',p))throw Error('Baralho vazio.');p.stock.scrap-=3;c.used.push(`buy:${s.turn}`);return true;
 case 'install':{if(s.encounter||c.race)throw Error('Instale fora de combate/corrida.');const card=p.hand.find(v=>v.id===a.cardId&&v.type!=='general'),d=cardDefinition(card?.definitionId??'');if(!card||!d)throw Error('Melhoria indisponível.');
 if(card.type==='territorial'){const t=a.territoryId?s.territories[a.territoryId]:undefined;if(!t||t.owner!==p.id)throw Error('Selecione território próprio.');if(t.city!==p.city){if(!s.actions)throw Error('Instalação remota exige Administrar.');s.actions--;}
 t.installed??=[];if(a.replaceId){if(d.id!=='T06'||!t.installed.includes(a.replaceId))throw Error('Somente Reforma planejada permite substituir.');remove(s,a.replaceId,t);}if(t.installed.length>=2)throw Error('Dois espaços territoriais ocupados.');if(d.unique&&territorial(s,t,d.id).length)throw Error('Melhoria única já instalada.');t.installed.push(card.id);if(d.id==='T01')t.resistance+=2;
 }else{if(p.vehicle.installed.length>=2)throw Error('Dois espaços de equipamento ocupados.');if(d.unique&&equipment(s,p,d.id).length)throw Error('Equipamento único já instalado.');p.vehicle.installed.push(card.id);c.installed[card.id]=card;if(extraCargo(s,p)>cargoCapacity(s,p))throw Error('Carga extra do equipamento excede capacidade.');}
 c.installed[card.id]=card;p.hand=p.hand.filter(v=>v.id!==card.id);log(s,`${d.name} instalada; ajuste eventuais excedentes.`);return true;}
 case 'removeUpgrade':{if(s.encounter||c.race)throw Error('Retire fora de combate/corrida.');const t=a.territoryId?s.territories[a.territoryId]:undefined;if(t?(t.owner!==p.id||t.city!==p.city||!t.installed?.includes(a.instanceId)):!p.vehicle.installed.includes(a.instanceId))throw Error('Instalação não pertence ao jogador/local.');remove(s,a.instanceId,t);return true;}
 case 'repairTerritory':{beforeAction(s);const t=s.territories[a.territoryId];if(!t||t.owner!==p.id||p.stock.scrap<1||t.resistance>=defenseMax(s,t))throw Error('Defesa inválida ou falta sucata.');s.actions--;p.stock.scrap--;t.resistance=Math.min(defenseMax(s,t),t.resistance+2+territorial(s,t,'T06').length);return true;}
 case 'loot':{beforeAction(s);const t=s.territories[a.territoryId];if(!t||t.city!==p.city||t.owner===null||t.owner===p.id||!p.vehicle.integrity||!p.vehicle.fuelUnits||!t.stock[a.resource])throw Error('Depósito rival local com recursos obrigatório.');if(s.players.some(v=>v.id===t.owner&&v.city===p.city&&v.vehicle.integrity&&!v.eliminated&&!v.skipTurns&&!v.penaltyActive))throw Error('Defesa pessoal presente; resolva o duelo antes do saque.');s.actions--;p.vehicle.fuelUnits--;const attack=rollDie(s,'Saque de '+p.name)+takeModifier(s,p.id,'lootAttack'),defense=rollDie(s,'Defesa do saque')+1+takeModifier(s,t.owner,'lootDefense');if(attack>defense){const n=Math.min(territorial(s,t,'T05').length?1:2,t.stock[a.resource]);t.stock[a.resource]-=n;p.stock[a.resource]+=n;}else hurt(s,p,2);log(s,`Saque: ${attack} contra ${defense}.`);return true;}
 case 'useEquipment':{const card=c.installed[a.instanceId];if(!card)throw Error('Equipamento indisponível.');const owner=s.players.find(v=>v.vehicle.installed.includes(a.instanceId));if(!owner)throw Error('Equipamento sem dono.');const id=card.definitionId,e=s.encounter,race=c.race;let scope='';
 if(id==='E10'){if(!race||race.phase!=='running'||race.entrants[race.cursor]?.playerId!==owner.id)throw Error('Antes da própria rolagem de corrida.');scope=`race:${a.instanceId}`;c.pending.push({effect:'race',amount:2,playerId:owner.id,sourceCardId:id,sourceInstanceId:card.id,sourcePlayerId:owner.id});}
 else{if(!e)throw Error('Antes de um ataque em combate.');const attacker=e.threatTurn?-1:e.betweenRounds?p.id:e.actorId;const target=e.threatTurn?p.id:attacker===p.id?e.defenderId:p.id;
 if(id==='E06'){if(attacker!==owner.id)throw Error('Exige ataque próprio.');scope=`combat:${a.instanceId}`;c.pending.push({effect:'attack',amount:1,playerId:owner.id,sourceCardId:id,sourceInstanceId:card.id,sourcePlayerId:owner.id});}
 else if(id==='E05'||id==='E12'){if(target!==owner.id)throw Error('Exige ataque contra o próprio carro.');scope=`combat:${a.instanceId}`;c.pending.push({effect:'reduceDamage',amount:id==='E12'?2:1,playerId:owner.id,sourceCardId:id,sourceInstanceId:card.id,sourcePlayerId:owner.id});if(id==='E12')remove(s,a.instanceId);}
 else throw Error('Equipamento passivo ou arma; use o comando correspondente.');}
 if(c.used.includes(scope))throw Error('Benefício desta instância já utilizado.');c.used.push(scope);return true;}
 case 'equipmentAttack':{const e=s.encounter,card=c.installed[a.instanceId];if(!e||!card||!['E01','E02','E03'].includes(card.definitionId))throw Error('Arma adicional indisponível.');const owner=s.players.find(v=>v.vehicle.installed.includes(a.instanceId));if(!owner||e.threatTurn||owner.id!==(e.betweenRounds?p.id:e.actorId)||!owner.stock.ammo||c.used.includes(`round:weapon:${owner.vehicle.id}`))throw Error('Ataque exige vez, munição e uso disponível nesta rodada.');const target=e.defenderId===undefined?undefined:s.players.find(v=>v.id===(owner.id===p.id?e.defenderId:p.id));if(card.definitionId==='E03'&&!target)throw Error('Espingarda só pode mirar carros.');if(e.betweenRounds){nextHostileRound(s,e);e.betweenRounds=false;}owner.stock.ammo--;c.used.push(`round:weapon:${owner.vehicle.id}`);resolveAttack(s,owner,target,card.definitionId==='E02'?3:card.definitionId==='E03'?2:1,card.definitionId==='E02'?-1:0);return true;}
 case 'cardChoice':{const choice=c.choice;if(!choice)throw Error('Nenhuma escolha pendente.');const owner=s.players.find(v=>v.id===choice.playerId)!;
 if(choice.kind==='inspect'){if(a.bottom)c.decks.events.push(c.decks.events.shift()!);}
 else if(choice.kind==='resource'){if(choice.card.definitionId==='V07'){if(!a.resource||!owner.stock[a.resource])throw Error('Escolha recurso presente na carga.');owner.stock[a.resource]--;}else{if(a.resource!=='scrap'&&a.resource!=='ammo')throw Error('Escolha sucata ou munição.');owner.stock[a.resource]++;}}
 else {if(a.targetId===undefined||!choice.targets?.includes(a.targetId))throw Error('Escolha participante válido.');delete c.choice;resolveSurprise(s,choice.card,owner.id,a.targetId);processMarkers(s);if(!c.choice)advanceRace(s);return true;}delete c.choice;return true;}
 case 'raceEntry':{const race=c.race;if(!race||race.phase!=='entry'||race.responses.includes(a.playerId))throw Error('Inscrição indisponível.');const target=targetPlayer(s,a.playerId,p),track=tracks.find(t=>t.id===race.trackId)!;if(target.id===p.id&&target.vehicle.integrity&&!target.vehicle.conditions.includes('motor')&&target.vehicle.fuelUnits>=track.fee&&!a.join)throw Error('Revelador apto deve participar.');if(a.join){if(!target.vehicle.integrity||target.vehicle.conditions.includes('motor')||target.vehicle.fuelUnits<track.fee)throw Error('Carro ou combustível insuficiente.');target.vehicle.fuelUnits-=track.fee;race.entrants.push({playerId:target.id,progress:0,markers:[],next:0});}race.responses.push(target.id);if(race.responses.length===s.players.length){if(race.entrants.length<2){for(const v of race.entrants)s.players.find(p=>p.id===v.playerId)!.vehicle.fuelUnits+=track.fee;delete c.race;log(s,'Corrida cancelada: menos de dois inscritos; inscrições devolvidas. Rival neutro desativado.');}else{race.entrants.sort((a,b)=>(s.players.findIndex(p=>p.id===a.playerId)-s.active+s.players.length)%s.players.length-(s.players.findIndex(p=>p.id===b.playerId)-s.active+s.players.length)%s.players.length);race.phase='running';c.used=c.used.filter(k=>!k.startsWith('race:'));}}return true;}
 case 'raceRoll':{const race=c.race;if(!race||race.phase!=='running'||c.choice)throw Error('Corrida indisponível ou escolha pendente.');const entrant=race.entrants[race.cursor],owner=s.players.find(p=>p.id===entrant.playerId)!;if(owner.vehicle.integrity&&!entrant.withdrawn){const roll=rollDie(s,'Avanço de '+owner.name);entrant.progress+=Math.max(0,roll+entrant.next+takeModifier(s,owner.id,'race'));entrant.next=0;entrant.queued=[];log(s,`${owner.name}: dado ${roll}, posição ${entrant.progress}.`);processMarkers(s);}if(!c.choice)advanceRace(s);return true;}
 default:return false;
 }
}
export function resolveAttack(s:Game,attacker:Player,target:Player|undefined,damage:number,modifier=0) {
 const blocked=vehicleAttackBlock(s,attacker);if(blocked)throw Error(blocked);
 const e=s.encounter!,c=s.cardState!,t=e.territoryId?s.territories[e.territoryId]:undefined;
 const hostile=combatHostile(s,e),hostileDef=hostile?hostileDefinition(hostile.definitionId):undefined;
 const healthBefore=target?.vehicle.integrity??hostile?.currentHealth??t?.resistance??e.eventIntegrity??2;
 const roll=rollDie(s,'Ataque de '+attacker.name),defense=target?vehicleDefense(s,target):hostileDef?hostileDef.defense:t?Math.min(6,s.rules.defense+territorial(s,t,'T03').length):s.rules.defense;
 const attack=roll+modifier+takeModifier(s,attacker.id,'attack'),bonus=takeModifier(s,attacker.id,'damage'),reduction=target?takeModifier(s,target.id,'reduceDamage'):takeModifier(s,attacker.id,'fortificationReduction');
 e.lastRoll={natural:roll,total:attack,defense,hit:roll===6||(roll!==1&&attack>=defense)};
 if(roll===6||(roll!==1&&attack>=defense)){const absorption=hostileHitReduction(s,e),n=Math.max(0,damage+bonus-reduction-absorption);if(absorption)log(s,`Chapa frontal: -${absorption} dano no primeiro acerto.`);if(target)hurt(s,target,n,attacker);else if(hostile)setHostileHealth(s,hostile,hostile.currentHealth-n);else if(t)t.resistance=Math.max(0,t.resistance-n);else e.eventIntegrity=Math.max(0,(e.eventIntegrity??2)-n);}
 const healthAfter=target?.vehicle.integrity??hostile?.currentHealth??t?.resistance??e.eventIntegrity??0;
 const actualDamage=healthBefore-healthAfter,prevented=e.lastRoll.hit?Math.max(0,Math.min(healthBefore,damage+bonus)-actualDamage):0;
 recordCombatRoll(s,{attackerId:attacker.id,targetId:target?.id,...e.lastRoll,healthBefore,healthAfter,damage:actualDamage,prevented});
 log(s,`${attacker.name}: dado ${roll}, total ${attack}, defesa ${defense}+.`);
 if(target)log(s,`${target.name}: vida ${healthBefore} → ${healthAfter} (${actualDamage} de dano${prevented?`, ${prevented} absorvido(s)`:''}).`);
 if(hostile&&hostileDef&&hostile.currentHealth===0&&!e.lootResolved){const reward={easy:2,medium:3,hard:4}[hostileDef.tier]+random(s,2);const found={scrap:0,fuel:0};for(let i=0;i<reward;i++){const resource=random(s,2)===0?'scrap':'fuel';attacker.stock[resource]++;found[resource]++;}e.lootResolved=true;log(s,attacker.name+': '+[found.scrap?'+'+found.scrap+' sucata(s)':'',found.fuel?'+'+found.fuel+' combustível na reserva':''].filter(Boolean).join(', ')+' por derrotar '+hostileDef.name+'.');}
 if(target&&!target.vehicle.integrity)s.encounter=null;
 if(t&&!t.resistance){if(t.hostile){(s.hostileDiscarded??=[]).push(t.hostile);delete t.hostile;}conquerUpgrades(s,t);t.owner=attacker.id;t.threat=null;t.resistance=s.rules.territoryIntegrity;s.encounter=null;}
 if(!t&&!target&&e.eventIntegrity===0){s.encounter=null;log(s,'Ameaça de evento descartada; nenhum território concedido.');}
 if(!s.encounter)c.used=c.used.filter(v=>!v.startsWith('combat:')&&!v.startsWith('round:'));
}
export function counterAttack(s:Game,p:Player) {
 const e=s.encounter!,t=e.territoryId?s.territories[e.territoryId]:undefined,h=combatHostile(s,e),d=h?hostileDefinition(h.definitionId):undefined,context=hostileContext(s,e);if(h&&!h.currentHealth)return;if(context&&context.lastAttackRound===context.round)throw Error('Hostil já atacou nesta rodada.');const roll=rollDie(s,'Ataque de '+(d?.name??'ameaça')),ownModifier=hostileAttackModifier(s,e);
 const total=roll+ownModifier+takeModifier(s,p.id,'threat'),reduction=takeModifier(s,p.id,'reduceDamage'),bonus=takeModifier(s,p.id,'threatDamage');
 e.lastRoll={natural:roll,total,defense:vehicleDefense(s,p),hit:roll===6||(roll!==1&&total>=vehicleDefense(s,p))};if(e.lastRoll.hit&&hostileDamageBonus(s,e,roll))log(s,'Incêndio: 6 natural acertou, +1 dano imediato.');
 if(roll===6||(roll!==1&&total>=vehicleDefense(s,p)))hurt(s,p,Math.max(0,(d?.attackDamage??s.rules.attackDamage)+bonus+hostileDamageBonus(s,e,roll)+(t&&!h?territorial(s,t,'T02').length:0)-reduction));
 log(s,`Resposta da ameaça: dado ${roll}, total ${total}${d?' · '+d.name+' (modificador próprio '+ownModifier+')':''}.`);if(!p.vehicle.integrity)s.encounter=null;
}
function resolveSurprise(s:Game,card:Card,playerId:number,targetId?:number) {
 const c=s.cardState!,race=c.race!,self=race.entrants.find(v=>v.playerId===playerId)!,owner=s.players.find(v=>v.id===playerId)!;
 const others=race.entrants.filter(v=>!v.withdrawn&&v.playerId!==playerId&&s.players.find(p=>p.id===v.playerId)!.vehicle.integrity>0),all=race.entrants.filter(v=>!v.withdrawn&&s.players.find(p=>p.id===v.playerId)!.vehicle.integrity>0);
 let targets=others;if(card.definitionId==='R05')targets=all;if(card.definitionId==='R15')targets=others.filter(v=>v.progress===Math.max(...others.map(v=>v.progress)));if(card.definitionId==='R16')targets=others.filter(v=>v.progress===self.progress);
 if(['R05','R08','R09','R14','R15','R16'].includes(card.definitionId)&&targets.length&&targetId===undefined){c.choice={card,playerId,kind:'raceTarget',targets:targets.map(v=>v.playerId)};return;}
 const target=targets.find(v=>v.playerId===targetId),move=(n:number)=>self.progress=Math.max(0,self.progress+n);
 switch(card.definitionId){
 case 'R01':move(2);break;case 'R02':move(3);break;case 'R03':move(others.some(v=>v.progress>self.progress)?2:1);break;case 'R04':self.next+=2;(self.queued??=[]).push({sourceCardId:card.definitionId,sourceInstanceId:card.id,amount:2});break;
 case 'R05':if(target)target.progress+=2;break;case 'R06':move(-2);break;case 'R07':self.next-=2;(self.queued??=[]).push({sourceCardId:card.definitionId,sourceInstanceId:card.id,amount:-2});break;
 case 'R08':if(target)target.progress=Math.max(0,target.progress-2);else move(-1);break;
 case 'R09':hurt(s,owner,1);if(target)hurt(s,s.players.find(p=>p.id===target.playerId)!,1);break;
 case 'R10':hurt(s,owner,1);move(-1);break;case 'R11':hurt(s,owner,2);break;case 'R12':break;
 case 'R13':if(owner.vehicle.integrity)owner.vehicle.integrity=Math.min(s.rules.combat[owner.vehicle.modelId].integrity,owner.vehicle.integrity+1);break;
 case 'R14':move(1);if(target)target.progress++;break;case 'R15':if(target)target.progress=Math.max(0,target.progress-1);break;
 case 'R16':if(target)target.progress=Math.max(0,target.progress-1);else move(1);break;
 }
}
function processMarkers(s:Game) {const c=s.cardState!,race=c.race!;if(!race)return;const track=tracks.find(t=>t.id===race.trackId)!;
 for(const entrant of race.entrants){if(entrant.withdrawn||!s.players.find(p=>p.id===entrant.playerId)!.vehicle.integrity)continue;for(const marker of track.markers){if(entrant.progress>=marker&&!entrant.markers.includes(marker)){entrant.markers.push(marker);const card=drawCatalog(s,'race');if(card){c.lastCard=card.definitionId;discardCatalog(s,card);log(s,`Surpresa: ${cardDefinition(card.definitionId)!.name}.`);resolveSurprise(s,card,entrant.playerId);if(c.choice)return;}return processMarkers(s);}}}
 if(race.entrants.some(v=>!v.withdrawn&&v.progress>=track.distance&&s.players.find(p=>p.id===v.playerId)!.vehicle.integrity))race.finalRound=true;
}
export function advanceRace(s:Game) {const c=s.cardState!,race=c.race;if(!race||race.phase!=='running')return;const track=tracks.find(t=>t.id===race.trackId)!;
 race.cursor++;if(race.cursor>=race.entrants.length){race.cursor=0;const alive=race.entrants.filter(v=>s.players.find(p=>p.id===v.playerId)!.vehicle.integrity>0);if(race.finalRound||!alive.length){if(alive.length){let tied=alive.filter(v=>v.progress===Math.max(...alive.map(v=>v.progress)));while(tied.length>1){const rolls=tied.map(v=>({v,n:rollDie(s,'Desempate de '+s.players.find(p=>p.id===v.playerId)!.name)})),max=Math.max(...rolls.map(v=>v.n));tied=rolls.filter(v=>v.n===max).map(v=>v.v);}const winner=s.players.find(p=>p.id===tied[0].playerId)!;winner.stock.scrap+=track.scrap;for(let i=0;i<track.improvements;i++)drawCatalog(s,'improvements',winner);log(s,`${winner.name} venceu ${track.name}: ${track.scrap} sucatas e ${track.improvements} melhorias.`);}else log(s,'Corrida encerrada sem prêmio: todos os carros inutilizados.');delete c.race;c.pending=c.pending.filter(v=>v.effect!=='race');c.used=c.used.filter(v=>!v.startsWith('race:'));}}
}
