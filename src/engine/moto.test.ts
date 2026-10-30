import { describe, expect, it } from 'vitest';
import { createGame, transition, makeVehicle, model, cities, routes, type Game } from './game';
import { decodeSave, encodeSave } from '../application/saves';

const player=(s:Game)=>s.players[s.active];
function setup(){const s=transition(createGame(['Ana','Bia'],42),{type:'start'}),p=player(s);p.city='araras';p.stock.scrap=1;const t=s.territories['araras-1'];delete t.hostile;t.owner=p.id;t.threat=null;t.stock.scrap=4;return s;}
describe('Moto',()=>{
 it('melhoria custa cinco sucatas e uma ação, entrega tanque cheio e preserva vida e vidas restantes',()=>{
  const s=setup();player(s).vehicle.integrity=4;player(s).vehicle.fuelUnits=1;player(s).deaths=1;
  const n=transition(s,{type:'upgradeVehicle',modelId:'moto'}),p=player(n);
  expect(p.vehicle.modelId).toBe('moto');expect(model(p).capacity).toBe(2);expect(model(p).consumption).toBe(1);expect(model(p).tank).toBe(10);expect(p.vehicle.fuelUnits).toBe(10);expect(p.vehicle.integrity).toBe(4);expect(p.deaths).toBe(1);expect(p.vehicle.fixedEquipmentId).toBe('fixed-moto');expect(p.stock.scrap).toBe(0);expect(n.territories['araras-1'].stock.scrap).toBe(0);expect(n.actions).toBe(0);expect(n.rules.combat.moto).toEqual({defense:4,integrity:6,agility:1});
 });
 it('viaja por terra por um combustível e é preservada pelo save',()=>{
  const s=setup();player(s).vehicle=makeVehicle(s,'moto');player(s).vehicle.fuelUnits=10;
  const n=transition(s,{type:'move',route:'araras-artur-nogueira-terra'});expect(player(n).city).toBe('artur-nogueira');expect(player(n).vehicle.fuelUnits).toBe(9);expect(decodeSave(encodeSave(n)).game).toEqual(n);
 });
 it('conserva partida v0.6 anterior à Moto ao adicionar apenas seu perfil',()=>{
  const s=setup();player(s).vehicle.fuelUnits=0;const raw=JSON.parse(encodeSave(s));delete raw.state.rules.combat.moto;
  const loaded=decodeSave(JSON.stringify(raw));expect(loaded.warnings).toHaveLength(1);expect(loaded.game).toEqual(s);expect(player(loaded.game).vehicle.modelId).toBe('hatch');expect(player(loaded.game).vehicle.fuelUnits).toBe(0);
 });
 it('descoberta não recebe combustível grátis fora da melhoria confirmada',()=>{
  const s=setup();const found=makeVehicle(s,'moto');s.found.push({city:'araras',vehicle:found,repairedOnTurn:null});player(s).vehicle.fuelUnits=2;
  const n=transition(s,{type:'swap',vehicleId:found.id});expect(player(n).vehicle.modelId).toBe('moto');expect(player(n).vehicle.fuelUnits).toBe(2);
 });
});
describe('posição e ligações de Santa Cruz',()=>{
 it('restaura as coordenadas da imagem antiga preservando acessos e setores',()=>{
  const santa=cities.find(c=>c.id==='santa-cruz')!,leme=cities.find(c=>c.id==='leme')!;
  expect(santa.x).toBe(83);expect(santa.y).toBe(13);expect(santa.x).toBeGreaterThan(leme.x);expect(santa.y).toBeLessThan(leme.y);expect(cities.reduce((sum,c)=>sum+c.regions,0)).toBe(35);
  expect(routes.filter(r=>r.from===santa.id||r.to===santa.id).map(r=>r.from===santa.id?r.to:r.from).sort()).toEqual(['leme','pirassununga']);
 });
});
