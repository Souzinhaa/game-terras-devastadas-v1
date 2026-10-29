import { useRef } from 'react';
import { hostileDefinition, hostileImage, hostiles, tierNames } from '../engine/hostiles';
export function HostileArt({id}:{id:string}){
 const ref=useRef<HTMLDialogElement>(null),d=hostileDefinition(id);if(!d)return null;
 const description=`${d.name}. ${tierNames[d.tier]}. Vida ${d.maxHealth}. Defesa ${d.defense}+. Dano ${d.attackDamage}. ${d.effectText} Um ataque por rodada.`;
 return <><button className="hostile-art" aria-label={`Ampliar hostil ${d.name}`} onClick={()=>ref.current?.showModal()}><img src={hostileImage(d)} alt={description} loading="lazy" decoding="async"/></button><dialog ref={ref} className="card-zoom hostile-zoom" aria-label={d.name} onClick={e=>{if(e.target===ref.current)ref.current.close();}}><button autoFocus onClick={()=>ref.current?.close()}>Fechar ampliação</button><img src={hostileImage(d)} alt={description} loading="lazy"/><p>{description}</p></dialog></>;
}
export function HostileCatalog(){return <details className="hostile-catalog"><summary>Consultar os 12 hostis</summary><div className="cards-grid">{hostiles.map(d=><article className="catalog-card" key={d.id}><HostileArt id={d.id}/><strong>{d.name}</strong><small>{tierNames[d.tier]} · Vida {d.maxHealth} · Defesa {d.defense}+ · Dano {d.attackDamage}</small><p>{d.effectText}</p></article>)}</div></details>;}
