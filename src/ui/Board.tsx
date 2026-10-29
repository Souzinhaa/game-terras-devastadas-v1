import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { cities, routes, cityTerritories, routeReason, type Game } from '../engine/game';
import { BoardVehicles, parkingOffsets } from './BoardVehicles';
import { Icon } from './Icon';
import mapView from '../data/map-view.json';
export interface Journey { from: string; to: string; routeId: string; key: number; playerId: number }
export function Board({ game, selected, onSelect, onInspectVehicle, journey }: { game: Game; selected: string; onSelect: (id: string) => void; onInspectVehicle: (playerId: number) => void; journey: Journey | null }) {
  const [zoom, setZoom] = useState(1), [width, setWidth] = useState(mapView.worldWidth), viewport = useRef<HTMLDivElement>(null);
  const pendingCamera = useRef<{x: number; y: number} | null>(null);
  const drag = useRef<{ x: number; y: number; left: number; top: number } | null>(null);
  const player = game.players[game.active];
  const height = width * mapView.imageHeight / mapView.imageWidth;
  function centerVehicle() {
    const city = cities.find(c => c.id === player.city)!, view = viewport.current;
    const [dx, dy] = parkingOffsets[game.active];
    if (view) view.scrollTo({left: city.x / 100 * width * zoom + dx - view.clientWidth / 2, top: city.y / 100 * height * zoom + dy - view.clientHeight / 2, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'});
  }
  function changeZoom(next: number) {
    const view = viewport.current;
    if (view) pendingCamera.current = {x: (view.scrollLeft + view.clientWidth / 2) / zoom * next - view.clientWidth / 2, y: (view.scrollTop + view.clientHeight / 2) / zoom * next - view.clientHeight / 2};
    setZoom(next);
  }
  useLayoutEffect(() => {
    if (pendingCamera.current && viewport.current) { viewport.current.scrollTo({left:pendingCamera.current.x,top:pendingCamera.current.y,behavior:'instant'}); pendingCamera.current = null; }
  }, [zoom]);
  useEffect(() => {
    const view = viewport.current;
    if (!view) return;
    const observer = new ResizeObserver(() => setWidth(Math.max(mapView.worldWidth, view.clientWidth * 2, view.clientHeight * mapView.imageWidth / mapView.imageHeight * 2)));
    observer.observe(view);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    const city = cities.find(c => c.id === selected), view = viewport.current;
    if (city && view) view.scrollTo({left: city.x / 100 * width * zoom - view.clientWidth / 2, top: city.y / 100 * height * zoom - view.clientHeight / 2, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'});
  }, [selected, width, height]);
  return <section className="panel board-panel" id="mapa" aria-label="Mapa de cidades"><div className="panel-heading"><div><span className="eyebrow">12 CIDADES · 35 SETORES</span><h2>Mapa da disputa</h2></div><div className="zoom-controls"><button aria-label="Reduzir mapa" disabled={zoom <= mapView.minZoom} onClick={() => changeZoom(Math.max(mapView.minZoom, zoom - mapView.zoomStep))}>−</button><output>{Math.round(zoom * 100)}%</output><button aria-label="Ampliar mapa" disabled={zoom >= mapView.maxZoom} onClick={() => changeZoom(Math.min(mapView.maxZoom, zoom + mapView.zoomStep))}>+</button><button className="recenter-map" aria-label="Centralizar no veículo" title="Centralizar no veículo" onClick={centerVehicle}><Icon name="car"/></button></div></div>
    <div className="map-viewport" ref={viewport} tabIndex={0} aria-label="Mapa ampliável. Use barras de rolagem, arraste o fundo ou use as setas do teclado."
      onPointerDown={e => { if ((e.target as HTMLElement).closest('button')) return; const v = viewport.current!; drag.current = { x: e.clientX, y: e.clientY, left: v.scrollLeft, top: v.scrollTop }; v.setPointerCapture(e.pointerId); }}
      onPointerMove={e => { if (!drag.current) return; const v = viewport.current!; v.scrollLeft = drag.current.left + drag.current.x - e.clientX; v.scrollTop = drag.current.top + drag.current.y - e.clientY; }} onPointerUp={() => { drag.current = null; }} onPointerCancel={() => { drag.current = null; }}>
      <div className="map" style={{ width: width * zoom, height: height * zoom }}>
        <svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">{routes.map(r => { const a = cities.find(c => c.id === r.from)!, b = cities.find(c => c.id === r.to)!; return <line key={r.id} x1={a.x} y1={a.y + (r.terrain === 'rural' ? 1 : 0)} x2={b.x} y2={b.y + (r.terrain === 'rural' ? 1 : 0)} className={`${r.terrain} ${routeReason(game, player, r.id) === null ? 'available' : ''} ${game.blocks.some(b => b.routeId === r.id) ? 'blocked' : ''} ${journey?.routeId === r.id ? 'traveled' : ''}`} />; })}</svg>
        {cities.map(c => { const regions = cityTerritories(game, c.id); return <button key={c.id} className={`city ${selected === c.id ? 'selected' : ''} ${player.city === c.id ? 'current' : ''}`} style={{ left: `${c.x}%`, top: `${c.y}%` }} aria-pressed={selected === c.id} onClick={() => onSelect(c.id)}><span className="city-emblem"><Icon name={player.city === c.id ? 'flag' : 'city'}/></span><strong>{c.name}</strong><span className="city-summary">{regions.filter(t => t.owner === player.id).length}/{c.regions} seus · {c.regions >= 4 ? '1 ponto' : '½ ponto'}</span><span className="region-dots">{regions.map(t => <i key={t.id} className={t.owner === null ? 'neutral' : `owner-${game.players.findIndex(p => p.id === t.owner)}`} title={`${t.label}: ${game.players.find(p => p.id === t.owner)?.name ?? 'ameaça'}`} aria-label={`${t.label}: ${game.players.find(p => p.id === t.owner)?.name ?? 'ameaça'}`}/>)}</span>{player.city === c.id && <span className="here">VOCÊ ESTÁ AQUI</span>}</button>; })}
        <BoardVehicles game={game} journey={journey} width={width * zoom} height={height * zoom} onInspect={onInspectVehicle}/>
      </div>
    </div><div className="map-legend"><span><i className="legend-road"/>Asfalto · todos</span><span><i className="legend-road dirt"/>Terra · SUV / Caminhonete</span><span><i className="legend-road closed"/>Bloqueada</span></div><p className="hint">Selecione uma cidade para inspecionar. Arraste o mapa para navegar.</p>
  </section>;
}
