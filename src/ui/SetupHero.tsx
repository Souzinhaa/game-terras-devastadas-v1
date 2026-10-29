import { cardDefinition } from '../engine/catalog';
import { Icon } from './Icon';

export function SetupHero(){
 return <section className="setup-hero">
  <div className="setup-hero-copy"><span className="eyebrow">TERRAS DEVASTADAS</span><h2>Domine as rotas.<br/><em>Conquiste as terras.</em></h2><p>Combustível contado. Estradas disputadas. Prepare seu veículo, use suas cartas e conquiste as cidades da região de Araras.</p><div className="hero-facts"><span><Icon name="map"/>12 cidades</span><span><Icon name="cards"/>74 cartas</span><span><Icon name="car"/>2–4 jogadores locais</span></div></div>
  <div className="hero-card-fan" aria-label="Cartas do jogo">{['E02','G01','R11'].map(id=>{const d=cardDefinition(id)!;return <img key={id} src={d.imageUrl} alt={d.name}/>;})}</div>
 </section>;
}
