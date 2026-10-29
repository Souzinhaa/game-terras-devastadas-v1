import { CardArt } from './Cards';
import { EffectBadge } from './EffectBadge';
import { equipmentBadge, pendingBadge } from './activeEffects';
import { cardDefinition } from '../engine/catalog';
import type { Game } from '../engine/game';
export function ActiveRack({game}:{game:Game}){
 const p=game.players[game.active],c=game.cardState,queued=c?.race?.entrants.flatMap(v=>(v.queued?.length?v.queued:v.next?[{amount:v.next,sourceCardId:'',sourceInstanceId:`legacy-race-${v.playerId}`}]:[]).map(e=>({...e,playerId:v.playerId})))??[];
 const pending=c?.pending??[],blocks=game.blocks.filter(b=>b.sourceCardId),count=pending.length+blocks.length+queued.length;
 return <section className={`active-rack ${!count&&!p.vehicle.installed.length?'is-empty':''}`} aria-label={`Efeitos e equipamentos de ${p.name}`}>
  <div className="rack-group" role="group" aria-label="Efeitos ativos"><strong>Ativos <small>{count}</small></strong><div className="rack-items">
   {!count&&<span className="rack-empty">Nenhum efeito pendente</span>}
   {pending.map((e,i)=>{const d=cardDefinition(e.sourceCardId??''),spec=pendingBadge(game,e);return <div className="rack-item" key={`${e.sourceInstanceId??i}-${e.effect}`}><div className="rack-visual">{d&&<CardArt id={d.id}/>}<EffectBadge {...spec}/></div><small>{spec.value} {['attack','threat'].includes(e.effect)?'acerto':e.effect==='escape'?'fuga':e.effect==='race'?'avanço':e.effect.includes('Damage')?'redução':'dano'}</small></div>;})}
   {queued.map(e=><div className="rack-item" key={e.sourceInstanceId}><div className="rack-visual">{e.sourceCardId&&<CardArt id={e.sourceCardId}/>}<EffectBadge iconId={e.amount<0?'corrida_minus2':'corrida_plus2'} value={`${e.amount<0?'−':'+'}${Math.abs(e.amount)}`} description={`${cardDefinition(e.sourceCardId)?.name??'Modificador de save anterior'} — ${game.players.find(p=>p.id===e.playerId)?.name} — próxima rolagem de avanço; expira ao fim da corrida. Instância ${e.sourceInstanceId}.`}/></div><small>Próximo avanço</small></div>)}
   {blocks.map((b,i)=><div className="rack-item" key={`${b.sourceInstanceId}-${i}`}><div className="rack-visual"><CardArt id={b.sourceCardId!}/><EffectBadge iconId="bloqueio_x" description={`Barricada na estrada — ${b.routeId} — fonte ${game.players.find(p=>p.id===b.by)?.name}. Uma fonte de bloqueio; expira no início do próximo turno da fonte. Instância ${b.sourceInstanceId}.`}/></div><small>Estrada bloqueada</small></div>)}
  </div></div>
  <div className="rack-group" role="group" aria-label="Equipamentos do carro"><strong>Carro <small>{p.vehicle.installed.length}/2</small></strong><div className="rack-items">
   {!p.vehicle.installed.length&&<span className="rack-empty">Sem equipamentos adicionais</span>}
   {p.vehicle.installed.map(key=>{const item=equipmentBadge(game,p,key);return item?<div className={`rack-item ${item.spec.used?'is-used':''}`} key={key}><div className="rack-visual"><CardArt id={item.d.id}/><EffectBadge {...item.spec}/></div><small>{item.status}</small></div>:<span key={key} className="rack-empty">Equipamento sem definição neste save</span>;})}
  </div></div>
 </section>;
}
