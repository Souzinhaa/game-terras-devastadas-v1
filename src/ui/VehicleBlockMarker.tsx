import { vehicleAttackBlock, type Game, type Player } from '../engine/game';
import { Icon } from './Icon';

export function VehicleBlockMarker({game,player}:{game:Game;player:Player}) {
 const reason=vehicleAttackBlock(game,player);
 if(!reason||player.eliminated)return null;
 return <span className="vehicle-block-marker" role="status" aria-label={reason} title={reason}><Icon name="close"/><span>Bloqueado · sem ataque</span></span>;
}
