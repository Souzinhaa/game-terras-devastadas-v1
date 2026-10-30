import { canTravelThisTurn, cities, type Game, type Action } from '../engine/game';
import { Icon } from './Icon';
export function InventoryTabs({current,onNavigate}:{current:string;onNavigate:(id:string)=>void}){
 return <div className="inventory-tabs" role="group" aria-label="Inventário"><button aria-pressed={current==='carro'} onClick={()=>onNavigate('carro')}><Icon name="car"/>Veículo e recursos</button><button aria-pressed={current==='cartas'} onClick={()=>onNavigate('cartas')}><Icon name="cards"/>Cartas</button></div>;
}
export function TurnActions({game,act,onNavigate}:{game:Game;act:(action:Action)=>void;onNavigate:(id:string)=>void}){
 const p=game.players[game.active],blocked=!!game.finished||!!game.encounter||!!game.cardState?.race||!!game.cardState?.choice,penalty=p.skipTurns>0||p.penaltyActive||p.eliminated;
 return <section className="panel turn-actions-panel" id="acoes"><span className="eyebrow">JOGAR</span><h2>O que você quer fazer?</h2><p>{cities.find(c=>c.id===p.city)?.name} · {game.actions?'Ação principal disponível':'Ação principal já usada'}</p>
 <p>{penalty?'Turno perdido pela destruição do carro. Encerre para passar a vez.':`Vidas restantes: ${2-p.deaths}`}</p><div className="turn-action-list">
 <button disabled={penalty||blocked||!canTravelThisTurn(game)} onClick={()=>onNavigate('rotas')}><Icon name="route"/><span><strong>Viajar</strong><small>Opcional. Você ainda pode agir ao chegar.</small></span><Icon name="arrow"/></button>
 <button disabled={penalty||blocked||!game.actions} onClick={()=>onNavigate('territorios')}><Icon name="flag"/><span><strong>Explorar ou conquistar</strong><small>Enfrentar outro carro ou escolher um setor na cidade atual.</small></span><Icon name="arrow"/></button>
 <button disabled={penalty||blocked} onClick={()=>onNavigate('administrar')}><Icon name="tools"/><span><strong>Cuidar do veículo</strong><small>Melhorar o Hatch, reparar ou recolher sucata.</small></span><Icon name="arrow"/></button>
 <button disabled={penalty||blocked} onClick={()=>onNavigate('cartas')}><Icon name="cards"/><span><strong>Comprar ou usar cartas</strong><small>Comprar melhoria ou preparar uma carta da mão.</small></span><Icon name="arrow"/></button>
 </div><p className="hint">Abrir o mapa ou o inventário não gasta sua ação.</p><button className="primary" disabled={blocked} onClick={()=>act({type:'end'})}>Encerrar turno</button></section>;
}
