import { cardDefinition } from '../engine/catalog';
import { combatHostile, hostileDefinition } from '../engine/hostiles';
import type { CatalogState } from '../engine/cardRules';
import type { Game, Player } from '../engine/game';
import type { BadgeSpec } from './EffectBadge';
export type Pending=CatalogState['pending'][number];
export function pendingBadge(s:Game,e:Pending):BadgeSpec {
 const labels:Record<Pending['effect'],[string,string,string]>={attack:[e.amount<0?'acerto_minus1':'acerto_plus1','Acerto','próximo ataque declarado'],threat:[e.amount<0?'acerto_minus1':'acerto_plus1','Acerto do hostil','próximo ataque do hostil'],damage:['dano_plus1','Dano','próximo ataque, se acertar'],threatDamage:['dano_plus1','Dano do hostil','próximo ataque do hostil, se acertar'],reduceDamage:['reducao_dano_minus1','Redução de dano','próximo ataque recebido, mesmo se falhar'],fortificationReduction:['reducao_dano_minus1','Redução de dano da ameaça','próximo ataque recebido pela ameaça'],escape:[e.amount<0?'fuga_minus1':'fuga_plus1','Fuga','próximo teste de fuga'],race:[e.amount<0?(e.amount===-1?'corrida_minus1':'corrida_minus2'):(e.amount===1?'corrida_plus1':'corrida_plus2'),'Avanço','próxima rolagem de avanço'],lootAttack:['saque_ataque_plus1','Saque do atacante','próxima disputa simples de saque'],lootDefense:['saque_defesa_plus1','Saque da defesa','próxima disputa simples de saque']};
 const [iconId,label,duration]=labels[e.effect],reduction=['reduceDamage','fortificationReduction'].includes(e.effect),value=`${reduction?'−':e.amount>=0?'+':'−'}${Math.abs(e.amount)}`;
 const h=combatHostile(s),target=['threat','threatDamage','fortificationReduction'].includes(e.effect)?hostileDefinition(h?.definitionId??'')?.name??(s.encounter?.territoryId?s.territories[s.encounter.territoryId].threat??'Defesa territorial':'Ameaça'):s.players.find(p=>p.id===e.playerId)?.name??'Jogador';
 const source=cardDefinition(e.sourceCardId??'')?.name??'Origem não registrada neste save';
 return {iconId:reduction&&e.amount===2?'reducao_dano_minus2':iconId,value,description:`${label} ${value} — ${source} — alvo: ${target} — duração: ${duration}. ${e.sourceInstanceId?'Instância '+e.sourceInstanceId+'.':''}`};
}
const equipmentIcons:Record<string,string>={E01:'ataque_extra_plus1',E02:'ataque_extra_plus1',E03:'ataque_extra_plus1',E04:'defesa_plus1',E05:'reducao_dano_minus1',E06:'acerto_plus1',E07:'tanque_max_plus3',E08:'carga_max_plus2',E09:'fuga_plus1',E10:'corrida_plus2',E11:'transferir_1',E12:'reducao_dano_minus2'};
export function equipmentBadge(s:Game,p:Player,key:string){
 const c=s.cardState,card=c?.installed[key],d=cardDefinition(card?.definitionId??'');if(!d)return null;
 const scope=['E01','E02','E03'].includes(d.id)?`round:weapon:${p.vehicle.id}`:['E05','E06'].includes(d.id)?`combat:${key}`:d.id==='E10'?`race:${key}`:d.id==='E11'?`turn:${s.turn}:${key}`:'';
 const declared=!!c?.pending.some(e=>e.sourceInstanceId===key),spent=!!scope&&!!c?.used.includes(scope),weapon=['E01','E02','E03'].includes(d.id),passive=['E04','E07','E08','E09'].includes(d.id);
 const status=declared?'Declarado':spent?'Usado':weapon&&!p.stock.ammo?'Sem munição':passive?'Instalado':'Disponível';
 const frequency=scope.startsWith('round:')?'uma vez por rodada de combate':scope.startsWith('combat:')?'uma vez por combate':scope.startsWith('race:')?'uma vez por corrida':scope.startsWith('turn:')?'uma vez por turno próprio':d.id==='E12'?'descartado ao declarar':'enquanto instalado';
 return {card,d,status,spec:{iconId:equipmentIcons[d.id],used:spent&&!declared,description:`${d.name} — ${p.name} — ${status}. ${frequency}. ${d.rulesText}${weapon?' Custo por ataque: 1 munição, pago antes do dado.':''} Instância ${key}.`} satisfies BadgeSpec};
}
export const territoryMarkerIds:Record<string,string[]>={T01:['vida_max_plus2'],T02:['dano_plus1'],T03:['defesa_plus1'],T04:['deposito_max_plus5'],T05:['cofre_1'],T06:['reparo_bonus_plus1']};
