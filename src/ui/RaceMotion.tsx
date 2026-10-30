import { VehicleArt } from './VehicleArt';
import type { Vehicle } from '../engine/game';

export interface RaceMotionData {
 distance:number;
 entrants:{id:number;name:string;vehicle:Vehicle;before:number;after:number}[];
}
export function RaceMotion({race,revealed}:{race:RaceMotionData;revealed:boolean}) {
 return <div className={`race-motion ${revealed?'is-revealed':''}`} aria-label="Avanço dos carros na corrida">
  {race.entrants.map(entrant=>{
   const progress=revealed?entrant.after:entrant.before,finished=progress>=race.distance;
   return <div className={`race-lane ${finished?'has-finished':''}`} key={entrant.id}>
    <div className="race-lane-label"><strong>{entrant.name}</strong><span>{progress}/{race.distance}{finished?' · Chegada!':''}{entrant.vehicle.integrity===0?' · Retirado':''}</span></div>
    <div className="race-road"><span className="race-finish" aria-hidden="true"/><span className="race-car" style={{left:`${Math.min(100,Math.max(0,progress/race.distance*100))}%`}}><VehicleArt vehicle={entrant.vehicle} small/></span></div>
   </div>;
  })}
 </div>;
}
