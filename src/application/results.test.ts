import { describe, expect, it } from 'vitest';
import { createGame } from '../engine/game';
import { finalStandings } from './results';

describe('placar final',()=>{
 it('mantém o vencedor em primeiro mesmo com menos pontos e ordena sobreviventes por setores',()=>{
  const s=createGame(['A','B','C'],42);for(const t of Object.values(s.territories))t.owner=null;
  const [winner,second,third]=s.players;s.winner=winner.id;
  s.territories['araras-1'].owner=second.id;s.territories['araras-2'].owner=second.id;s.territories['leme-1'].owner=third.id;
  expect(finalStandings(s).map(row=>[row.player.id,row.position])).toEqual([[winner.id,1],[second.id,2],[third.id,3]]);
 });
 it('eliminado mais recente fica à frente de quem saiu antes e conserva empates simultâneos',()=>{
  const s=createGame(['A','B','C','D'],42);const [winner,latest,tied,earliest]=s.players;s.winner=winner.id;
  for(const p of [latest,tied,earliest]){p.eliminated=true;p.deaths=2;p.vehicle.integrity=0;}
  latest.eliminatedAtTurn=8;tied.eliminatedAtTurn=8;earliest.eliminatedAtTurn=4;
  expect(finalStandings(s).map(row=>[row.player.id,row.position])).toEqual([[winner.id,1],[latest.id,2],[tied.id,2],[earliest.id,4]]);
 });
 it('não inventa desempate em partida sem vencedor',()=>{
  const s=createGame(['A','B'],42);for(const p of s.players){p.eliminated=true;p.deaths=2;p.eliminatedAtTurn=3;}s.finished=true;
  expect(finalStandings(s).map(row=>row.position)).toEqual([1,1]);
 });
});
