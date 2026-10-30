import { points, type Game, type Player } from '../engine/game';

export function finalStandings(game:Game){
 const score=(player:Player)=>({player,points:points(game,player.id),sectors:Object.values(game.territories).filter(t=>t.owner===player.id).length});
 const compare=(a:ReturnType<typeof score>,b:ReturnType<typeof score>)=>{
  const winner=Number(b.player.id===game.winner)-Number(a.player.id===game.winner);if(winner)return winner;
  if(a.player.eliminated!==b.player.eliminated)return Number(a.player.eliminated)-Number(b.player.eliminated);
  if(a.player.eliminated&&b.player.eliminated)return (b.player.eliminatedAtTurn??0)-(a.player.eliminatedAtTurn??0);
  return b.points-a.points||b.sectors-a.sectors;
 };
 const rows=game.players.map(score).sort(compare);
 let position=1;
 return rows.map((row,index)=>{if(index&&compare(rows[index-1],row)!==0)position=index+1;return {...row,position};});
}
