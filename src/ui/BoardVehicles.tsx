import { type CSSProperties } from 'react';
import { cities, model, type Game } from '../engine/game';
import { VehicleArt } from './VehicleArt';
import { VehicleBlockMarker } from './VehicleBlockMarker';
import type { Journey } from './Board';

// Separate parking positions in the shared city. Never a rules position.
export const parkingOffsets = [[100, -35], [-100, -35], [100, 100], [-100, 100]];
export function BoardVehicles({ game, journey, width, height, onInspect }: {
  game: Game; journey: Journey | null; width: number; height: number; onInspect: (playerId: number) => void;
}) {
  return <div className="board-vehicles" aria-label="Veículos no tabuleiro">
    {game.players.map((player, index) => {
      if(player.eliminated)return null;
      const city = cities.find(c => c.id === player.city)!;
      const moving = journey?.playerId === player.id;
      const origin = moving ? cities.find(c => c.id === journey.from) : null;
      const heading = origin ? Math.atan2((city.y - origin.y) * height, (city.x - origin.x) * width) * 180 / Math.PI + 90 : index % 2 ? 12 : -12;
      const [dx, dy] = parkingOffsets[index];
      const style = { left: `${city.x}%`, top: `${city.y}%`, '--park-x': `${dx}px`, '--park-y': `${dy}px`, '--heading': `${heading}deg` } as CSSProperties;
      return <button key={player.id} className={`vehicle-piece owner-${index} ${index === game.active ? 'active-piece' : ''} ${moving ? 'is-moving' : ''} ${player.vehicle.integrity === 0 ? 'disabled-piece' : ''}`}
        style={style} data-player-id={player.id} data-city={player.city}
        aria-label={`Selecionar carro de ${player.name}: ${model(player).name}, ${city.name}${player.vehicle.integrity === 0 ? ', inutilizado' : ''}`}
        title={`${player.name} · ${model(player).name} · ${city.name}`} onClick={() => onInspect(player.id)}>
        <span className="vehicle-base" aria-hidden="true"/>
        <span className="piece-art"><VehicleArt vehicle={player.vehicle}/></span>
        <span className="piece-number">{index + 1}</span>
        <span className="piece-name">{player.name}</span>
        <VehicleBlockMarker game={game} player={player}/>
        {index === game.active && <span className="piece-state">{moving ? 'Em viagem' : 'Na vez'}</span>}
        {player.vehicle.integrity === 0 && <span className="piece-state">Inutilizado</span>}
      </button>;
    })}
  </div>;
}
