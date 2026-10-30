import { useEffect, useRef } from 'react';
import { finalStandings } from '../application/results';
import { emptyStock, model, type Game, type Resource, type Stock } from '../engine/game';
import { cardDefinition } from '../engine/catalog';
import { VehicleArt } from './VehicleArt';
import { HealthBar } from './HealthBar';
import { ResourceIcon } from './ResourceIcon';

const labels:Record<Resource,string>={fuel:'Combustível reserva',scrap:'Sucata',tire:'Pneus',battery:'Baterias',water:'Água',ammo:'Munição'};
function Resources({stock}:{stock:Stock}){
 const resources=(Object.keys(stock) as Resource[]).filter(key=>stock[key]>0);
 return resources.length?<ul className="final-resources">{resources.map(resource=><li key={resource}><ResourceIcon resource={resource}/><span>{labels[resource]}</span><strong>{stock[resource]}</strong></li>)}</ul>:<p className="hint">Nenhum recurso restante.</p>;
}
export function FinalStandings({game,onClose,onNewGame,onExport}:{game:Game;onClose:()=>void;onNewGame:()=>void;onExport:()=>void}){
 const ref=useRef<HTMLDialogElement>(null);
 useEffect(()=>{const dialog=ref.current;dialog?.showModal();return ()=>dialog?.close();},[]);
 const winner=game.players.find(player=>player.id===game.winner);
 return <dialog ref={ref} className="final-standings" aria-labelledby="final-results-title" onCancel={event=>{event.preventDefault();onClose();}}>
  <header className="final-heading"><div><span className="eyebrow">PARTIDA ENCERRADA</span><h2 id="final-results-title">Placar final</h2><p>{winner?`${winner.name} venceu ${game.winnerReason==='survival'?'por sobrevivência':'por domínio territorial'}.`:'Partida encerrada sem vencedor.'}</p></div><button onClick={onClose} aria-label="Fechar placar final">Fechar</button></header>
  <ol className="final-ranking">{finalStandings(game).map(({player,position,points,sectors})=>{
   const depot=emptyStock();for(const territory of Object.values(game.territories))if(territory.owner===player.id)for(const resource of Object.keys(depot) as Resource[])depot[resource]+=territory.stock[resource];
   const equipment=player.vehicle.installed.map(id=>game.cardState?.installed[id]).filter(Boolean);
   return <li key={player.id} className={`final-player ${player.id===game.winner?'is-winner':''}`}>
    <div className="final-player-header"><span className="final-position">{position}º</span><VehicleArt vehicle={player.vehicle}/><div><h3>{player.name}</h3><p>{model(player).name} · {player.eliminated?'Eliminado':`${2-player.deaths} vida(s) restante(s)`}</p><strong>{points} pontos · {sectors} setores</strong></div>{player.id===game.winner&&<span className="final-winner">Vencedor</span>}</div>
    <div className="final-player-items"><section><HealthBar value={player.vehicle.integrity} max={game.rules.combat[player.vehicle.modelId].integrity} label={`Vida final de ${player.name}`}/><p className="final-tank"><ResourceIcon resource="fuel"/>Combustível no tanque: <strong>{player.vehicle.fuelUnits}</strong></p><h4>Itens no carro</h4><Resources stock={player.stock}/></section><section><h4>Itens nos depósitos</h4><Resources stock={depot}/><p>Cartas na mão: <strong>{player.hand.length}</strong> · Equipamentos: <strong>{equipment.length}</strong></p>{(player.hand.length>0||equipment.length>0)&&<details><summary>Ver cartas e equipamentos</summary><ul>{player.hand.map(card=><li key={card.id}>{cardDefinition(card.definitionId)?.name??card.definitionId} · na mão</li>)}{equipment.map(card=><li key={card!.id}>{cardDefinition(card!.definitionId)?.name??card!.definitionId} · instalado</li>)}</ul></details>}</section></div>
   </li>;
  })}</ol>
  <p className="final-ranking-rule">Vencedor primeiro; sobreviventes por pontos e setores; eliminados pela ordem de saída. Empates compartilham posição.</p>
  <div className="final-actions" role="group" aria-label="Ações do placar final"><span>Seed inicial: {game.initialSeed??'não registrada'}</span><button onClick={onExport}>Exportar partida</button><button onClick={onClose}>Voltar ao mapa</button><button className="primary" onClick={onNewGame}>Nova partida</button></div>
 </dialog>;
}
