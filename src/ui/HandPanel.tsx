import { InventoryTabs } from './TurnActions';
import { useEffect, useRef, useState } from 'react';
import { catalog, cardDefinition } from '../engine/catalog';
import { cargoCapacity, tankCapacity, extraCargo } from '../engine/cardRules';
import { routes, type Action, type Game, type Resource } from '../engine/game';
import { CardArt } from './Cards';
import { Icon } from './Icon';

const resourceNames={fuel:'Combustível',scrap:'Sucata',ammo:'Munição',tire:'Pneu',battery:'Bateria',water:'Água'};
export function Cards({game,act,visible,onToggle,handoff,onNavigate}:{game:Game;act:(a:Action)=>void;visible:boolean;onToggle:()=>void;handoff:boolean;onNavigate:(id:string)=>void}) {
 const p=game.players[game.active],state=game.cardState;
 const [ownerId,setOwnerId]=useState(p.id),[filter,setFilter]=useState('all'),[selectedId,setSelectedId]=useState<string|null>(null);
 const [route,setRoute]=useState(routes[0].id),[target,setTarget]=useState(p.id),[territory,setTerritory]=useState(Object.values(game.territories).find(t=>t.owner===p.id)?.id??Object.keys(game.territories)[0]);
 const [replace,setReplace]=useState(''),[library,setLibrary]=useState(false),[lootResource,setLootResource]=useState<Resource>('scrap');
 const [lootTerritory,setLootTerritory]=useState('');
 const composer=useRef<HTMLElement>(null);
 const handOwner=game.players.find(v=>v.id===ownerId)??p;
 const selected=handOwner.hand.find(v=>v.id===selectedId),definition=cardDefinition(selected?.definitionId??'');
 useEffect(()=>{setOwnerId(p.id);setTarget(p.id);setSelectedId(null);setFilter('all');},[p.id]);
 useEffect(()=>{if(selected)composer.current?.scrollIntoView({block:'nearest',behavior:window.matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});},[selected?.id]);
 const targetTerritory=selected?.type==='territorial'||['G08','G19','G20','G23'].includes(definition?.id??'')||(definition?.id==='G04'&&!!game.encounter&&game.encounter.defenderId===undefined&&!game.encounter.threatTurn)||(['G01','G02','G03'].includes(definition?.id??'')&&game.encounter?.threatTurn);
 const targetPlayer=['G05','G06','G09','G10','G16','G21','G22'].includes(definition?.id??'')||(['G01','G02','G03'].includes(definition?.id??'')&&!game.encounter?.threatTurn)||(definition?.id==='G04'&&(!game.encounter||game.encounter.defenderId!==undefined||game.encounter.threatTurn));
 return <section className="panel hand-panel" id="cartas"><InventoryTabs current="cartas" onNavigate={onNavigate}/>
  <div className="panel-heading"><div><span className="eyebrow">CARTAS E MELHORIAS</span><h2>Sua mão</h2></div><button disabled={handoff} onClick={onToggle}>{visible?'Ocultar':'Revelar'}</button></div>
  <label>Mão do jogador<select aria-label="Mão do jogador" value={ownerId} onChange={e=>{setOwnerId(Number(e.target.value));setSelectedId(null);if(visible)onToggle();}}>{game.players.map(v=><option key={v.id} value={v.id}>{v.name}</option>)}</select></label>
  <div className="card-counts">{(['general','equipment','territorial'] as const).map(type=><span key={type}>{handOwner.hand.filter(c=>c.type===type).length}/{type==='general'?5:3} {{general:'gerais',equipment:'equipamentos',territorial:'territoriais'}[type]}</span>)}</div>
  {!visible&&<div className="concealed-hand"><div className="card-back-strip" aria-hidden="true">{handOwner.hand.map(card=><span key={card.id}/>)}</div><p>Cartas ocultas. Revele a mão quando estiver pronto.</p></div>}
  {visible&&!handoff&&<>
   {ownerId===p.id&&<button className="buy-improvement" disabled={!game.started||!!game.encounter||!!state?.race} onClick={()=>act({type:'buyImprovement'})}><Icon name="cards"/> Comprar melhoria · 3 sucatas · uma por turno</button>}
   <div className="card-filters" role="group" aria-label="Filtrar cartas">{[{id:'all',name:'Todas'},{id:'general',name:'Gerais'},{id:'equipment',name:'Equipamentos'},{id:'territorial',name:'Territoriais'}].map(item=><button key={item.id} aria-pressed={filter===item.id} onClick={()=>setFilter(item.id)}>{item.name}</button>)}</div>
   <div className="cards-grid">{handOwner.hand.filter(c=>filter==='all'||c.type===filter).map(card=>{const d=cardDefinition(card.definitionId);return <article className={`catalog-card hand-card ${selectedId===card.id?'is-selected':''}`} key={card.id}>
    <CardArt id={card.definitionId}/><strong>{d?.name??card.definitionId}</strong><p>{d?.rulesText}</p><small>{d?.timing}</small>
    <div className="button-row"><button disabled={!game.started||!!state?.choice||(card.type==='general'?handOwner.usedGeneral:ownerId!==p.id)} onClick={()=>setSelectedId(selectedId===card.id?null:card.id)}>{selectedId===card.id?'Selecionada':'Preparar'}</button><button aria-label={`Descartar ${d?.name??card.definitionId}`} disabled={!!game.encounter||ownerId!==p.id} onClick={()=>act({type:'discardCard',playerId:ownerId,cardId:card.id})}>Descartar</button></div>
   </article>;})}</div>
   {!handOwner.hand.some(c=>filter==='all'||c.type===filter)&&<p className="hint">Nenhuma carta nesta categoria.</p>}
   {selected&&definition&&<section className="card-composer" ref={composer} aria-label={`Preparar ${definition.name}`}>
    <span className="eyebrow">{selected.type==='general'?'JOGAR CARTA':'INSTALAR MELHORIA'}</span><h3>{definition.name}</h3><p>{definition.rulesText}</p><small>{definition.timing}</small>
    {targetPlayer&&<label>Jogador alvo<select value={target} onChange={e=>setTarget(Number(e.target.value))}>{game.players.map(v=><option key={v.id} value={v.id}>{v.name}</option>)}</select></label>}
    {targetTerritory&&<label>Território alvo<select value={territory} onChange={e=>{setTerritory(e.target.value);setReplace('');}}>{Object.values(game.territories).filter(t=>selected.type!=='territorial'||t.owner===p.id).map(t=><option key={t.id} value={t.id}>{t.city} · {t.label} · {game.players.find(v=>v.id===t.owner)?.name??'Ameaça'}</option>)}</select></label>}
    {['G17','G18'].includes(definition.id)&&<label>Ligação alvo<select value={route} onChange={e=>setRoute(e.target.value)}>{routes.map(r=><option key={r.id} value={r.id}>{r.from} ↔ {r.to}</option>)}</select></label>}
    {definition.id==='T06'&&<label>Substituir melhoria<select value={replace} onChange={e=>setReplace(e.target.value)}><option value="">Não substituir</option>{(game.territories[territory]?.installed??[]).map(key=><option key={key} value={key}>{cardDefinition(state?.installed[key]?.definitionId??'')?.name}</option>)}</select></label>}
    <button className="primary" onClick={()=>act(selected.type==='general'?{type:'playCatalog',cardId:selected.id,playerId:ownerId,targetId:target,territoryId:territory,route}:{type:'install',cardId:selected.id,territoryId:territory,replaceId:replace||undefined})}>{selected.type==='general'?'Usar carta':'Instalar melhoria'}</button>
   </section>}
  </>}
  <details><summary>Equipamentos instalados e melhorias territoriais</summary><p>Carga total: {Object.values(p.stock).reduce((a,b)=>a+b,0)+extraCargo(game,p)}/{cargoCapacity(game,p)} · tanque: {p.vehicle.fuelUnits}/{tankCapacity(game,p)}</p>
   {game.players.map(owner=><div key={owner.id}><h3>{owner.name} · equipamentos</h3>{!owner.vehicle.installed.length&&<p className="hint">Nenhum equipamento adicional instalado.</p>}{owner.vehicle.installed.map(key=>{const card=state?.installed[key];return card&&<article key={key}><CardArt id={card.definitionId}/><p>{cardDefinition(card.definitionId)?.rulesText}</p>
    {['E01','E02','E03'].includes(card.definitionId)?<button onClick={()=>act({type:'equipmentAttack',instanceId:key})}>Ataque adicional · 1 munição</button>:['E05','E06','E10','E12'].includes(card.definitionId)&&<button onClick={()=>act({type:'useEquipment',instanceId:key})}>Declarar benefício antes do dado</button>}
    {owner.id===p.id&&card.definitionId==='E11'&&<><label>Depósito do guincho<select value={territory} onChange={e=>setTerritory(e.target.value)}>{Object.values(game.territories).filter(t=>t.owner===p.id&&t.city===p.city).map(t=><option key={t.id} value={t.id}>{t.label}</option>)}</select></label><button onClick={()=>act({type:'winch',instanceId:key,territoryId:territory})}>Guincho: 1 sucata para depósito</button></>}
    {owner.id===p.id&&<button onClick={()=>act({type:'removeUpgrade',instanceId:key})}>Retirar e descartar</button>}
   </article>;})}</div>)}
   {Object.values(game.territories).filter(t=>t.owner===p.id).map(t=><div key={t.id}><h3>{t.city} · {t.label}</h3>{(t.installed??[]).map(key=><article key={key}><CardArt id={state?.installed[key]?.definitionId??''}/><button onClick={()=>act({type:'removeUpgrade',instanceId:key,territoryId:t.id})}>Retirar e descartar</button></article>)}<button onClick={()=>act({type:'repairTerritory',territoryId:t.id})}>Administrar defesa · 1 sucata</button></div>)}
  </details>
  <details><summary>Saquear depósito</summary><label>Território alvo<select value={lootTerritory} onChange={e=>setLootTerritory(e.target.value)}><option value="">Escolha um depósito rival</option>{Object.values(game.territories).filter(t=>t.city===p.city&&t.owner!==null&&t.owner!==p.id).map(t=><option key={t.id} value={t.id}>{t.label} · {game.players.find(v=>v.id===t.owner)?.name}</option>)}</select></label><label>Recurso para saque<select value={lootResource} onChange={e=>setLootResource(e.target.value as Resource)}>{(Object.keys(resourceNames) as Resource[]).map(r=><option key={r} value={r}>{resourceNames[r]}</option>)}</select></label><button disabled={!lootTerritory} onClick={()=>act({type:'loot',territoryId:lootTerritory,resource:lootResource})}>Saquear · ação + 1 combustível</button></details>
  <button onClick={()=>setLibrary(!library)}>{library?'Fechar catálogo':'Consultar as 74 cartas'}</button>
  {library&&<div className="cards-grid">{catalog.map(d=><article className="catalog-card" key={d.id}><CardArt id={d.id}/><strong>{d.id} · {d.name}</strong><p>{d.rulesText}</p><small>{d.copies} cópias · proposta para teste</small></article>)}</div>}
 </section>;
}
