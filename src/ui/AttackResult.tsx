import { RollingDie } from './RollingDie';
import { useEffect, useState } from 'react';
import { HealthBar } from './HealthBar';
import { VehicleArt } from './VehicleArt';
import type { Player } from '../engine/game';

export interface AttackOutcome {
 attacker: string;
 target: string;
 natural: number;
 total: number;
 defense: number;
 hit: boolean;
 damage: number;
 prevented: number;
 disabled: boolean;
 attackerVehicle: Player['vehicle'];
 targetVehicle: Player['vehicle'];
 attackerMax: number;
 targetMax: number;
 targetHealthBefore: number;
}

export function AttackResult({result,onContinue}:{result:AttackOutcome;onContinue:()=>void}) {
 const [rolling,setRolling]=useState(true);
 const [reveal]=useState(()=>()=>setRolling(false));
 const [settled,setSettled]=useState(false);
 useEffect(()=>{
  if(rolling)return;
  const timer=window.setTimeout(()=>setSettled(true),800);
  return ()=>window.clearTimeout(timer);
 },[rolling]);
 return <div className="attack-result" aria-busy={rolling}>
  <p>{result.attacker} ataca {result.target}</p>
  <div className="attack-participants">
   <article><VehicleArt vehicle={result.attackerVehicle} small/><strong>{result.attacker}</strong><HealthBar value={result.attackerVehicle.integrity} max={result.attackerMax} label={`Vida de ${result.attacker}`}/></article>
   <article className={rolling?'':result.hit?'attack-target-hit':'attack-target-miss'}><VehicleArt vehicle={result.targetVehicle} small/><strong>{result.target}</strong><HealthBar value={rolling?result.targetHealthBefore:result.targetVehicle.integrity} max={result.targetMax} label={`Vida de ${result.target}`}/>{!rolling&&<span className="attack-impact" aria-hidden="true">{result.hit?'ACERTO':'ERROU'}</span>}</article>
  </div>
  <RollingDie natural={result.natural} label="" onReveal={reveal}/>
  <div aria-live="polite">{rolling?<p>Rolando o dado…</p>:<><h3 className={`attack-verdict ${result.hit?'is-hit':'is-miss'}`}>{result.hit?(result.damage?'Acertou!':'Acerto absorvido'):'Não acertou'}</h3><p>Dado {result.natural} · Total {result.total} · Defesa {result.defense}+</p><p className="attack-health-change">Vida de {result.target}: <strong>{result.targetHealthBefore} → {result.targetVehicle.integrity}</strong></p><p>{result.damage>0?`${result.target} perdeu ${result.damage} de vida.`:'Nenhum dano causado.'}</p>{result.prevented>0&&<p>Escudo ou redução absorveu {result.prevented} de dano.</p>}{result.disabled&&<p>Carro de {result.target} destruído.</p>}</>}</div>
  <button className="primary" disabled={rolling||!settled} onClick={onContinue}>Continuar</button>
 </div>;
}
