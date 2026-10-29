import type { Game, Action, Resource } from '../engine/game';
import { cardDefinition } from '../engine/catalog';
import { cargoCapacity, tankCapacity, depotCapacity } from '../engine/cardRules';
import { territoryHealthMax } from '../engine/hostiles';
import type { BadgeSpec } from './EffectBadge';
export function changeBadges(before:Game,after:Game,action:Action):BadgeSpec[]{
 const out:BadgeSpec[]=[],sourceId='cardId'in action?before.players.flatMap(p=>p.hand).find(c=>c.id===action.cardId)?.definitionId:action.type==='move'?after.cardState?.lastCard:action.type==='cardChoice'?before.cardState?.choice?.card.definitionId:undefined;
 const origin=cardDefinition(sourceId??'')?.name??'Resolução da ação';
 const add=(iconId:string,value:string,description:string)=>out.push({iconId,value,description:`${description} — ${origin}. Resultado já aplicado; não é um bônus pendente.`});
 const health=(name:string,delta:number)=>{if(delta>0)add(delta===2?'vida_plus2':'vida_plus1',`+${delta}`,`${name}: recuperou ${delta} de vida`);else if(delta<0)add(`dano_${Math.min(3,-delta)}`,String(-delta),`${name}: perdeu ${-delta} de vida`);};
 const resources:Partial<Record<Resource,[string,string]>>={scrap:['sucata_plus1','Sucata'],ammo:['municao_plus1','Munição'],tire:['pneu_plus1','Pneu'],battery:['bateria_plus1','Bateria'],water:['agua_plus1','Água']};
 for(const previous of before.players){const p=after.players.find(p=>p.id===previous.id)!;
  if(p.vehicle.id===previous.vehicle.id)health(p.name,p.vehicle.integrity-previous.vehicle.integrity);
  const fuel=p.vehicle.fuelUnits-previous.vehicle.fuelUnits;if(fuel&&p.vehicle.id===previous.vehicle.id)add(fuel>0?'combustivel_plus2':'combustivel_minus1',`${fuel>0?'+':'−'}${Math.abs(fuel)}`,`${p.name}: combustível no tanque ${fuel>0?'+':'−'}${Math.abs(fuel)}`);
  for(const resource of Object.keys(resources) as Resource[]){const delta=p.stock[resource]-previous.stock[resource],config=resources[resource]!;if(delta)add(delta>0?config[0]:resource==='ammo'?'municao_minus1':'recurso_minus1',`${delta>0?'+':'−'}${Math.abs(delta)}`,`${p.name}: ${delta<0&&action.type==='equipmentAttack'?'custo pago, ':''}${config[1]} ${delta>0?'+':'−'}${Math.abs(delta)}`);}
  const tank=tankCapacity(after,p)-tankCapacity(before,previous),cargo=cargoCapacity(after,p)-cargoCapacity(before,previous);if(tank)add('tanque_max_plus3',`${tank>0?'+':'−'}${Math.abs(tank)}`,`${p.name}: capacidade do tanque, não ganho de combustível`);if(cargo)add('carga_max_plus2',`${cargo>0?'+':'−'}${Math.abs(cargo)}`,`${p.name}: capacidade de carga`);
 }
 for(const t of Object.values(before.territories)){const next=after.territories[t.id];if(t.owner===next.owner&&!['install','removeUpgrade'].includes(action.type))health(t.threat??`${t.city} ${t.label}`,next.resistance-t.resistance);else if(t.owner!==next.owner&&t.resistance>0)health(t.threat??`${t.city} ${t.label}`,-t.resistance);
  const maximum=territoryHealthMax(after,next)-territoryHealthMax(before,t),depot=depotCapacity(after,next)-depotCapacity(before,t);if(maximum&&t.owner===next.owner)add('vida_max_plus2',`${maximum>0?'+':'−'}${Math.abs(maximum)}`,`${t.city} ${t.label}: vida máxima; preserva dano anterior`);if(depot)add('deposito_max_plus5',`${depot>0?'+':'−'}${Math.abs(depot)}`,`${t.city} ${t.label}: capacidade do depósito`);
 }
 if(before.cardState?.race&&after.cardState?.race)for(const entrant of after.cardState.race.entrants){const old=before.cardState.race.entrants.find(v=>v.playerId===entrant.playerId),delta=old?entrant.progress-old.progress:0;if(delta)add(delta>0?'corrida_plus1':'corrida_minus1',`${delta>0?'+':'−'}${Math.abs(delta)}`,`${after.players.find(p=>p.id===entrant.playerId)?.name}: posições efetivamente alteradas nesta resolução`);}
 return out;
}
