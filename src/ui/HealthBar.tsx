import { useEffect, useRef, useState } from 'react';

export function HealthBar({value,max,label}:{value:number;max:number;label:string}) {
 const previous=useRef(value),[trail,setTrail]=useState(value),[loss,setLoss]=useState<{amount:number;key:number}|null>(null);
 useEffect(()=>{
  const before=previous.current;previous.current=value;
  if(value>=before){setTrail(value);setLoss(null);return;}
  setTrail(before);setLoss(old=>({amount:before-value,key:(old?.key??0)+1}));
  const trailTimer=window.setTimeout(()=>setTrail(value),250),lossTimer=window.setTimeout(()=>setLoss(null),1800);
  return ()=>{clearTimeout(trailTimer);clearTimeout(lossTimer);};
 },[value]);
 const maximum=Math.max(1,max),percent=Math.min(100,Math.max(0,value/maximum*100));
 return <div className={`health-bar ${loss?'is-damaged':''} ${percent<=25?'is-low':percent<=50?'is-wounded':''}`}>
  <div className="health-label"><span>Vida</span><strong>{value}<small> / {max}</small></strong></div>
  <div className="health-track" role="meter" aria-label={label} aria-valuemin={0} aria-valuemax={maximum} aria-valuenow={Math.max(0,Math.min(value,maximum))} aria-valuetext={`${value} de ${max} de vida`}>
   <span className="health-trail" style={{width:`${Math.min(100,trail/maximum*100)}%`}}/><span className="health-fill" style={{width:`${percent}%`}}/>
  </div>
  {loss&&<span key={loss.key} className="health-loss" role="status" aria-label={`${label}: perdeu ${loss.amount} de vida`}>−{loss.amount} de vida</span>}
 </div>;
}
