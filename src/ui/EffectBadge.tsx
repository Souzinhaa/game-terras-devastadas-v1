import { createElement, useRef } from 'react';
import manifest from '../data/effect-markers.json';
import shapes from '../data/marker-shapes.json';
export const markers=manifest.icons;
export const markerCards=manifest.cards;
export interface BadgeSpec {iconId:string;description:string;value?:string;used?:boolean}
export function EffectBadge({iconId,description,value,used=false}:BadgeSpec){
 const ref=useRef<HTMLDialogElement>(null),icon=markers.find(m=>m.id===iconId);if(!icon)return null;
 const geometry=shapes[icon.family as keyof typeof shapes];
 const picture=(detail=false)=>value&&value!==icon.label?<svg viewBox="0 0 256 256" className="effect-badge-image" aria-hidden="true">{geometry.map((part,i)=>createElement(part.tag,{...part.attrs,key:i}))}<text x="128" y="128" textAnchor="middle" dominantBaseline="central" fontFamily="DejaVu Sans,Arial,sans-serif" fontWeight="700" fontSize={value.length>3?60:82} fill="#12171D">{value}</text></svg>:<img className="effect-badge-image" src={`${import.meta.env.BASE_URL}assets/markers/${icon.png[detail?'256':'64']}`} alt="" width={detail?64:32} height={detail?64:32} loading="lazy"/>;
 return <><button className={`effect-badge ${used?'is-used':''}`} data-icon-id={iconId} data-state={used?'used':'available'} aria-label={description} title={description} onClick={()=>ref.current?.showModal()}>{picture()}</button><dialog ref={ref} className="effect-badge-detail" aria-label="Detalhe do marcador"><h2>{icon.description.replaceAll('Integridade','Vida')}</h2>{picture(true)}<p>{description}</p><button autoFocus onClick={()=>ref.current?.close()}>Fechar marcador</button></dialog></>;
}
export function CardMarkers({cardId,context='Referência visual da carta; condições conforme o texto.'}:{cardId:string;context?:string}){
 const d=markerCards.find(c=>c.cardId===cardId);if(!d?.icons.length)return null;
 return <div className="card-marker-guide" aria-label="Marcadores da carta"><small>Referência visual · veja condições e custos na carta</small><div>{d.icons.map(id=><EffectBadge key={id} iconId={id} description={`${markers.find(m=>m.id===id)?.description} — ${d.name}. ${context} ${d.rulesText}`}/>)}</div></div>;
}
