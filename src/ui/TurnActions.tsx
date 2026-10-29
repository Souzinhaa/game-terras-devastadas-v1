import { cities, type Game, type Action } from '../engine/game';
import { Icon } from './Icon';
export function InventoryTabs({current,onNavigate}:{current:string;onNavigate:(id:string)=>void}){
 return <div className="inventory-tabs" role="group" aria-label="Inventário"><button aria-pressed={current==='carro'} onClick={()=>onNavigate('carro')}><Icon name="car"/>Veículo e recursos</button><button aria-pressed={current==='cartas'} onClick={()=>onNavigate('cartas')}><Icon name="cards"/>Cartas</button></div>;
}
export function TurnActions({game,act,onNavigate}:{game:Game;act:(action:Action)=>void;onNavigate:(id:string)=>void}){
 const p=game.players[game.active],blocked=!!game.encounter||!!game.cardState?.race||!!game.cardState?.choice;
 return <section className="panel turn-actions-panel" id="acoes"><span className="eyebrow">JOGAR</span><h2>O que você quer fazer?</h2><p>{cities.find(c=>c.id===p.city)?.name} · {game.actions?'Ação principal disponível':'Ação principal já usada'}</p>
 <div className="turn-action-list">
 <button disabled={blocked||!game.actions||game.moved} onClick={()=>onNavigate('rotas')}><Icon name="route"/><span><strong>Viajar</strong><small>Opcional. Você ainda pode agir ao chegar.</small></span><Icon name="arrow"/></button>
 <button disabled={blocked||!game.actions} onClick={()=>onNavigate('territorios')}><Icon name="flag"/><span><strong>Explorar ou conquistar</strong><small>Escolher um território na cidade atual.</small></span><Icon name="arrow"/></button>
 <button disabled={blocked} onClick={()=>onNavigate('administrar')}><Icon name="tools"/><span><strong>Cuidar do veículo</strong><small>Reparar, recolher sucata ou trocar de carro.</small></span><Icon name="arrow"/></button>
 <button disabled={blocked} onClick={()=>onNavigate('cartas')}><Icon name="cards"/><span><strong>Comprar ou usar cartas</strong><small>Comprar melhoria ou preparar uma carta da mão.</small></span><Icon name="arrow"/></button>
 </div><p className="hint">Abrir o mapa ou o inventário não gasta sua ação.</p><button className="primary" disabled={blocked} onClick={()=>act({type:'end'})}>Encerrar turno</button></section>;
}
