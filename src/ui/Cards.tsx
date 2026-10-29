import { useEffect, useRef, useState } from 'react';
import { cardDefinition, tracks } from '../engine/catalog';
import { type Action, type Game } from '../engine/game';
import './cards.css';
import { Icon } from './Icon';
export function DrawnCards({ids,onClose}:{ids:string[];onClose:()=>void}) {
 const ref=useRef<HTMLDialogElement>(null);
 const [index,setIndex]=useState(0),[revealed,setRevealed]=useState(false);
 const definition=cardDefinition(ids[index]);
 useEffect(()=>{ref.current?.showModal();return ()=>ref.current?.close();},[]);
 return <dialog ref={ref} className="drawn-cards" aria-label="Cartas recebidas" onCancel={e=>{e.preventDefault();if(revealed&&index===ids.length-1)onClose();}}>
 <h2>{revealed?'Sua nova carta':'Você comprou uma carta'}</h2>
 {ids.length>1&&<p>Carta {index+1} de {ids.length}</p>}
 <button key={index} className={`draw-flip ${revealed?'is-revealed':''}`} aria-label={revealed?'Carta revelada':'Virar carta'} aria-pressed={revealed} onClick={()=>setRevealed(true)} autoFocus>
  <span className="draw-flip-rotor"><span className="draw-flip-back" aria-hidden={revealed}><span>TERRAS<br/>DEVASTADAS</span><Icon name="map"/><small>CLIQUE PARA REVELAR</small></span><span className="draw-flip-front" aria-hidden={!revealed}>{revealed&&definition&&<img src={definition.imageUrl} alt={`${definition.name}. ${definition.rulesText}`}/>}</span></span>
 </button>
 {revealed?<><h3>{definition?.name}</h3><p>Adicionada à sua mão no inventário.</p><button className="primary" onClick={()=>{if(index<ids.length-1){setIndex(index+1);setRevealed(false);}else onClose();}}>{index<ids.length-1?'Próxima carta':'Guardar carta'}</button></>:<p>Toque no verso para virar a carta.</p>}
 </dialog>;
}
export function CardArt({id}:{id:string}) {
 const d=cardDefinition(id),ref=useRef<HTMLDialogElement>(null);if(!d)return <span>{id}</span>;
 return <><button className="card-art" onClick={()=>ref.current?.showModal()} aria-label={`Ampliar ${d.name}`}><img src={d.imageUrl} alt={`${d.name}. ${d.rulesText}`} loading="lazy" decoding="async"/></button><dialog className="card-zoom" ref={ref} onClick={e=>{if(e.target===ref.current)ref.current.close();}}><button onClick={()=>ref.current?.close()} autoFocus>Fechar ampliação</button><img src={d.imageUrl} alt={`${d.name}. ${d.rulesText}`} loading="lazy" decoding="async"/><p>{d.rulesText}</p></dialog></>;
}
export function CardResolution({game,act,onCards}:{game:Game;act:(a:Action)=>void;onCards:()=>void}) {
 const [collapsed,setCollapsed]=useState(false);
 const c=game.cardState,choice=c?.choice,race=c?.race;
 useEffect(()=>{if(choice)setCollapsed(false);},[choice?.card.id]);
 if(!choice&&!race)return null;
 const track=tracks.find(t=>t.id===race?.trackId),next=race?.entrants[race.cursor];
 return <section className={`card-resolution ${collapsed?'is-collapsed':''}`} aria-label="Resolver carta ou corrida" aria-live="polite">
 <button className="resolution-toggle" onClick={()=>setCollapsed(!collapsed)}>{collapsed?'Abrir resolução da carta/corrida':'Recolher painel'}</button><button onClick={()=>{setCollapsed(true);onCards();}}>Abrir cartas e equipamentos</button>
 {choice?<><h2>{choice.kind==='inspect'?'Próximo evento':'Escolha da carta'}</h2><CardArt id={choice.card.definitionId}/>{choice.kind==='inspect'?<div><button onClick={()=>act({type:'cardChoice',bottom:false})}>Manter no topo</button><button onClick={()=>act({type:'cardChoice',bottom:true})}>Colocar no fundo</button></div>:choice.kind==='raceTarget'?choice.targets?.map(id=><button key={id} onClick={()=>act({type:'cardChoice',targetId:id})}>{game.players.find(p=>p.id===id)?.name}</button>):(['scrap','ammo','fuel','tire','battery','water'] as const).filter(resource=>choice.card.definitionId==='V10'?['scrap','ammo'].includes(resource):game.players.find(p=>p.id===choice.playerId)!.stock[resource]>0).map(resource=><button key={resource} onClick={()=>act({type:'cardChoice',resource})}>{{scrap:'Sucata',ammo:'Munição',fuel:'Combustível da carga',tire:'Pneu',battery:'Bateria',water:'Água'}[resource]}</button>)}</>:
 race&&<><h2>Corrida {track?.name}</h2><p>Distância {track?.distance} · marcos {track?.markers.join(' / ')} · inscrição {track?.fee} combustíveis</p>{race.phase==='entry'?game.players.filter(p=>!race.responses.includes(p.id)).map(p=><div key={p.id}><strong>{p.name}</strong><button onClick={()=>act({type:'raceEntry',playerId:p.id,join:true})}>Participar</button><button onClick={()=>act({type:'raceEntry',playerId:p.id,join:false})}>Não participar</button></div>):<><ol>{race.entrants.map(v=><li key={v.playerId}>{game.players.find(p=>p.id===v.playerId)?.name}: {v.progress}/{track?.distance}{!game.players.find(p=>p.id===v.playerId)?.vehicle.integrity?' · retirado':''}<progress aria-label={'Progresso de '+game.players.find(p=>p.id===v.playerId)?.name} max={track?.distance} value={Math.min(v.progress,track?.distance??v.progress)}/></li>)}</ol><p>Próximo: {game.players.find(p=>p.id===next?.playerId)?.name}. Declare cartas e equipamentos antes de rolar.</p><button onClick={()=>act({type:'raceRoll'})}>Rolar avanço</button></>}</>}
 </section>;
}
