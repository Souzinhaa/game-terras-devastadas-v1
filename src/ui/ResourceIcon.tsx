import manifest from '../data/resources.json';
import type { Resource } from '../engine/game';
const ids:Record<Resource,string>={fuel:'combustivel',scrap:'sucata',ammo:'municao',tire:'pneu',battery:'bateria',water:'agua'};
/** Decorative when followed by the resource's visible name/quantity. */
export function ResourceIcon({resource}:{resource:Resource}){
 const icon=manifest.resources.find(v=>v.id===ids[resource])!;
 return <img src={`${import.meta.env.BASE_URL}assets/resources/${icon.png['64']}`} alt="" width="24" height="24" style={{verticalAlign:'middle',objectFit:'contain',marginRight:6}}/>;
}
