import { model, type Game } from '../engine/game';
import { VehicleArt } from './VehicleArt';
import { HealthBar } from './HealthBar';
import { defenseMax } from '../engine/cardRules';
import { combatHostile, hostileDefinition, tierNames } from '../engine/hostiles';
import { HostileArt } from './HostileArt';
export function CombatSummary({ game }: { game: Game }) {
  const encounter = game.encounter;
  if (!encounter) return null;
  const attacker = game.players[game.active];
  const defender = game.players.find(p => p.id === encounter.defenderId);
  const territory = encounter.territoryId ? game.territories[encounter.territoryId] : null;
  const hostile=combatHostile(game),hostileDef=hostile?hostileDefinition(hostile.definitionId):undefined;
  const defenderName=defender?.name ?? hostileDef?.name ?? territory?.threat ?? (encounter.eventIntegrity!==undefined?'Saqueadores de evento':'Defesa territorial');
  return <div className="combat-summary">
    <div className="combatants">
      <article><VehicleArt vehicle={attacker.vehicle} small/><strong>{attacker.name}</strong><small>{model(attacker).name}</small><HealthBar key={attacker.vehicle.id} value={attacker.vehicle.integrity} max={game.rules.combat[attacker.vehicle.modelId].integrity} label={`Vida de ${attacker.name}`}/></article>
      <article>{hostileDef?<><div className="hostile-profile"><HostileArt id={hostileDef.id}/><div><strong>{defenderName}</strong><small>{tierNames[hostileDef.tier]}</small><div className="hostile-stats"><span>Defesa <b>{hostileDef.defense}+</b></span><span>Dano <b>{hostileDef.attackDamage}</b></span></div></div></div><small className="hostile-effect">{hostileDef.effectText}</small></>:<>{defender&&<VehicleArt vehicle={defender.vehicle} small/>}<strong>{defenderName}</strong><small>{defender?model(defender).name:territory?.label}</small></>}<HealthBar key={defender?.vehicle.id??hostile?.instanceId??territory?.id??'event-enemy'} value={defender?.vehicle.integrity??hostile?.currentHealth??territory?.resistance??encounter.eventIntegrity??0} max={defender?game.rules.combat[defender.vehicle.modelId].integrity:hostileDef?hostileDef.maxHealth:territory?defenseMax(game,territory):2} label={`Vida de ${defenderName}`}/></article>
    </div>
    {encounter.lastRoll&&<div className={`combat-roll ${encounter.lastRoll.hit?'is-hit':'is-miss'}`} key={`roll-${game.log.length}`} aria-label={`Dado natural ${encounter.lastRoll.natural}. ${encounter.lastRoll.hit?'Acerto':'Falha'}.`}>
      <span className="die-face" aria-hidden="true">{encounter.lastRoll.natural}</span><div><small>DADO NATURAL</small><strong>{encounter.lastRoll.hit?'Acertou':'Não acertou'}</strong><span>Total {encounter.lastRoll.total} · defesa {encounter.lastRoll.defense}+</span></div>
    </div>}
    <p className="combat-result" key={game.log.length}>{game.log.at(-1)}</p>
  </div>;
}
