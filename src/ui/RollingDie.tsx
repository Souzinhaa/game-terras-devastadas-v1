import { RaceMotion, type RaceMotionData } from './RaceMotion';
import { useEffect, useState } from 'react';
import type { DiceRoll } from '../engine/game';

export function RollingDie({natural,label,onReveal}:{natural:number;label:string;onReveal:()=>void}) {
 const [rolling,setRolling]=useState(true),[face,setFace]=useState(1);
 useEffect(()=>{
  if(window.matchMedia('(prefers-reduced-motion: reduce)').matches){setRolling(false);onReveal();return;}
  const interval=window.setInterval(()=>setFace(value=>value%6+1),80);
  const timer=window.setTimeout(()=>{window.clearInterval(interval);setRolling(false);onReveal();},1000);
  return ()=>{window.clearInterval(interval);window.clearTimeout(timer);};
 },[natural,onReveal]);
 return <div><p>{label}</p><div className={`die-face attack-die ${rolling?'is-rolling':''}`} aria-label={rolling?'Dado rolando':`Dado natural ${natural}`}>{rolling?face:natural}</div></div>;
}

export function DiceResolution({rolls,messages,race,onContinue}:{rolls:DiceRoll[];messages:string[];race?:RaceMotionData;onContinue:()=>void}) {
 const [index,setIndex]=useState(0),[revealed,setRevealed]=useState(false);
 const [reveal]=useState(()=>()=>setRevealed(true));
 const last=index===rolls.length-1;
 const [settled,setSettled]=useState(false);
 useEffect(()=>{if(!revealed||!race)return;const timer=window.setTimeout(()=>setSettled(true),1000);return ()=>window.clearTimeout(timer);},[revealed,race]);
 return <div className="attack-result" aria-busy={!revealed}>
  <RollingDie key={index} natural={rolls[index].natural} label={rolls[index].label} onReveal={reveal}/>
  {race&&<RaceMotion race={race} revealed={revealed}/> }
  <div aria-live="polite">{revealed?<><p>Resultado do dado: <strong>{rolls[index].natural}</strong></p>{last&&messages.map((message,i)=><p key={i}>{message}</p>)}</>:<p>Rolando o dado…</p>}</div>
  <button className="primary" disabled={!revealed||!!race&&!settled} onClick={()=>{if(last)onContinue();else{setRevealed(false);setIndex(value=>value+1);}}}>{last?'Continuar':'Próximo dado'}</button>
 </div>;
}
