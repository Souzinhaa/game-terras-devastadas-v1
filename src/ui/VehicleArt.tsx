import { model, type Vehicle } from '../engine/game';
const images = import.meta.glob('../../assets/*-cima.png', { eager: true, query: '?url', import: 'default' }) as Record<string, string>;
export function VehicleArt({ vehicle, small = false }: { vehicle: Vehicle; small?: boolean }) {
  const def = model(vehicle);
  return <img className={small ? 'vehicle-marker' : 'vehicle-art'} src={images[`../../assets/${def.art}`]} alt={small ? def.name : `${def.name}, vista de cima`} draggable={false} />;
}
