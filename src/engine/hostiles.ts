import manifest from '../data/hostiles.json';
import { random, type Game, type Territory, type Combat } from './game';

export type HostileTier='easy'|'medium'|'hard';
export type HostileEffect=
 | {type:'attack_roll_modifier';value:number;trigger:'before_hostile_attack_roll';limit?:'first_attack_per_combat';consumeOn?:'roll_attempt'}
 | {type:'opponent_escape_roll_modifier';value:number;trigger:'before_opponent_escape_roll'}
 | {type:'damage_bonus';value:number;trigger:'hostile_attack_hit';condition:{naturalRollEquals:number}}
 | {type:'incoming_damage_reduction';value:number;minimumDamage:number;trigger:'first_attack_hit_received_per_combat';consumeOn:'hit'};
export interface HostileDefinition {id:string;name:string;tier:HostileTier;maxHealth:number;defense:number;attackDamage:number;attacksPerRound:number;copies:number;effectText:string;effects:HostileEffect[];image:string;sha256:string}
export interface HostileInstance {instanceId:string;definitionId:string;territoryId?:string;eventId?:string;currentHealth:number;revealed:boolean;origin:'territory'|'event'}
export interface HostileContext {hostileInstanceId:string;firstAttackUsed:boolean;firstHitReductionUsed:boolean;round:number;stage:'player_attack'|'hostile_attack'|'between_rounds';lastAttackRound?:number}
export interface HostileConfig {samplingMode:'with_replacement';unclassifiedTier:'easy';profile:'development';migration?:{instanceId:string;source:string;definitionId:string;previousHealth:number;health:number}[]}
export const hostiles=manifest.hostiles as HostileDefinition[];
export const hostileDefinition=(id:string)=>hostiles.find(d=>d.id===id);
export const hostileImage=(d:HostileDefinition)=>`${import.meta.env.BASE_URL}assets/hostiles/${d.image}`;
export const tierNames={easy:'Fácil',medium:'Médio',hard:'Difícil'};
export function initHostiles(s:Game){s.hostileConfig={samplingMode:'with_replacement',unclassifiedTier:'easy',profile:'development'};s.hostileDiscarded=[];}
export function makeHostile(s:Game,tier:HostileTier,origin:'territory'|'event',sourceId:string):HostileInstance {
 const allowed=hostiles.filter(d=>d.tier===tier);if(!allowed.length)throw Error('Nível de hostil inválido.');
 const definition=allowed[random(s,allowed.length)];
 return {instanceId:`hostile-${s.nextId++}`,definitionId:definition.id,currentHealth:definition.maxHealth,revealed:true,origin,...origin==='territory'?{territoryId:sourceId}:{eventId:sourceId}};
}
export function attachHostile(s:Game,t:Territory,tier:HostileTier='easy',pending=true){
 t.difficulty=tier;t.difficultyPending=pending;t.hostile=makeHostile(s,tier,'territory',t.id);const d=hostileDefinition(t.hostile.definitionId)!;t.threat=d.name;t.resistance=t.hostile.currentHealth;
}
export const combatHostile=(s:Game,e:Combat|null=s.encounter)=>e?.eventHostile??(e?.territoryId?s.territories[e.territoryId]?.hostile:undefined);
export function startHostileCombat(s:Game,e:Combat){const h=combatHostile(s,e);if(h){h.revealed=true;e.hostileContext={hostileInstanceId:h.instanceId,firstAttackUsed:false,firstHitReductionUsed:false,round:1,stage:'player_attack'};}}
export function hostileContext(s:Game,e:Combat){if(!e.hostileContext&&combatHostile(s,e))startHostileCombat(s,e);return e.hostileContext;}
export function nextHostileRound(s:Game,e:Combat){const context=hostileContext(s,e);if(context){context.round++;context.stage='player_attack';}}
export function setHostileHealth(s:Game,h:HostileInstance,value:number){h.currentHealth=Math.max(0,Math.min(hostileDefinition(h.definitionId)!.maxHealth,value));if(h.origin==='territory'){s.territories[h.territoryId!].resistance=h.currentHealth;}else if(s.encounter?.eventHostile?.instanceId===h.instanceId)s.encounter.eventIntegrity=h.currentHealth;}
export function territoryHealthMax(s:Game,t:Territory){return t.hostile?hostileDefinition(t.hostile.definitionId)!.maxHealth:s.rules.territoryIntegrity+(t.installed??[]).filter(key=>s.cardState?.installed[key]?.definitionId==='T01').length*2;}
export function hostileAttackModifier(s:Game,e:Combat){const h=combatHostile(s,e),context=hostileContext(s,e);if(!h||!context)return 0;let modifier=0;
 for(const effect of hostileDefinition(h.definitionId)!.effects)if(effect.type==='attack_roll_modifier'&&(!effect.limit||!context.firstAttackUsed))modifier+=effect.value;
 context.firstAttackUsed=true;context.lastAttackRound=context.round;context.stage='between_rounds';return modifier;
}
export function hostileDamageBonus(s:Game,e:Combat,natural:number){const h=combatHostile(s,e);return h?hostileDefinition(h.definitionId)!.effects.reduce((n,effect)=>n+(effect.type==='damage_bonus'&&effect.condition.naturalRollEquals===natural?effect.value:0),0):0;}
export function hostileHitReduction(s:Game,e:Combat){const h=combatHostile(s,e),context=hostileContext(s,e);if(!h||!context||context.firstHitReductionUsed)return 0;const effects=hostileDefinition(h.definitionId)!.effects.filter(effect=>effect.type==='incoming_damage_reduction');if(effects.length){context.firstHitReductionUsed=true;return effects.reduce((n,effect)=>n+effect.value,0);}return 0;}
export function hostileEscapeModifier(s:Game,e:Combat){const h=combatHostile(s,e);return h?hostileDefinition(h.definitionId)!.effects.reduce((n,effect)=>n+(effect.type==='opponent_escape_roll_modifier'?effect.value:0),0):0;}
/** Deterministic migration: never consumes RNG or re-rolls an existing hostile. */
export function migrateHostiles(s:Game):string[]{
 if(s.hostileConfig)return [];initHostiles(s);const mappings:NonNullable<HostileConfig['migration']>=[];s.hostileConfig!.migration=mappings;
 for(const t of Object.values(s.territories))if(t.owner===null&&t.threat){
  const health=t.resistance,eligible=hostiles.filter(d=>d.tier==='easy'&&d.maxHealth>=health),hash=[...t.id].reduce((n,c)=>(Math.imul(n,31)+c.charCodeAt(0))>>>0,0);
  const d=eligible[hash%eligible.length]??hostileDefinition('H03')!,source=t.threat;
  t.hostile={instanceId:`hostile-${s.nextId++}`,definitionId:d.id,currentHealth:Math.min(health,d.maxHealth),territoryId:t.id,origin:'territory',revealed:true};t.difficulty='easy';t.difficultyPending=true;t.resistance=t.hostile.currentHealth;t.threat=d.name;
  mappings.push({instanceId:t.hostile.instanceId,source,definitionId:d.id,previousHealth:health,health:t.resistance});
 }
 const e=s.encounter;if(e?.eventIntegrity!==undefined&&!e.eventHostile){const health=e.eventIntegrity,d=hostileDefinition(health>2?'H03':'H02')!;e.eventHostile={instanceId:`hostile-${s.nextId++}`,definitionId:d.id,currentHealth:Math.min(health,d.maxHealth),eventId:`legacy-event-${s.turn}`,revealed:true,origin:'event'};e.eventIntegrity=e.eventHostile.currentHealth;mappings.push({instanceId:e.eventHostile.instanceId,source:'V15 genérico',definitionId:d.id,previousHealth:health,health:e.eventIntegrity});}
 if(e){startHostileCombat(s,e);if(e.hostileContext)e.hostileContext.stage=e.threatTurn?'hostile_attack':e.betweenRounds?'between_rounds':'player_attack';}
 const clamped=mappings.filter(m=>m.health!==m.previousHealth).length;
 return [`Hostis antigos migrados por mapeamento determinístico; vida e RNG preservados${clamped?`, exceto ${clamped} valores acima dos máximos do catálogo (valores originais registrados)`:''}. Áreas sem nível usam a faixa fácil de desenvolvimento.`];
}
export function assertHostiles(s:Game){
 if(!s.hostileConfig)return;const config=s.hostileConfig;if(config.samplingMode!=='with_replacement'||config.unclassifiedTier!=='easy'||config.profile!=='development')throw Error('Configuração de hostis inválida.');
 const ids=new Set<string>();const register=(h:HostileInstance)=>{const d=hostileDefinition(h?.definitionId);if(!d||!h.instanceId||ids.has(h.instanceId)||!Number.isSafeInteger(h.currentHealth)||h.currentHealth<0||h.currentHealth>d.maxHealth||typeof h.revealed!=='boolean'||!['territory','event'].includes(h.origin))throw Error('Instância hostil inválida/duplicada.');ids.add(h.instanceId);};
 for(const t of Object.values(s.territories))if(t.hostile){register(t.hostile);if(t.owner!==null||t.hostile.origin!=='territory'||t.hostile.territoryId!==t.id||t.resistance!==t.hostile.currentHealth||t.threat!==hostileDefinition(t.hostile.definitionId)!.name||t.difficulty&&t.difficulty!==hostileDefinition(t.hostile.definitionId)!.tier)throw Error('Estado territorial do hostil inconsistente.');}
 if(s.encounter?.eventHostile){const h=s.encounter.eventHostile;register(h);if(h.origin!=='event'||!h.eventId||s.encounter.eventIntegrity!==h.currentHealth||s.encounter.territoryId||s.encounter.defenderId!==undefined)throw Error('Hostil de evento inconsistente.');}
 for(const h of s.hostileDiscarded??[])register(h);
 const context=s.encounter?.hostileContext;if(context){if(context.hostileInstanceId!==combatHostile(s)?.instanceId||typeof context.firstAttackUsed!=='boolean'||typeof context.firstHitReductionUsed!=='boolean'||!Number.isSafeInteger(context.round)||context.round<1||!['player_attack','hostile_attack','between_rounds'].includes(context.stage))throw Error('Contexto de combate hostil inválido.');}
}
