import 'fake-indexeddb/auto';
import { describe, expect, it } from 'vitest';
import { createGame, transition } from '../engine/game';
import { decodeSave, encodeSave, readLocal, writeLocal } from './saves';
describe('persistência IndexedDB', () => {
  it('salva e recupera partida sem alterar RNG ou tanque', async () => {
    const game = transition(createGame(['A','B'], 42), {type:'start'});
    game.players[0].vehicle.fuelUnits = 1;
    await writeLocal(game);
    expect(decodeSave((await readLocal())!).game).toEqual(game);
  });
  it('preserva partida anterior e original importado em transação; save inválido não substitui current', async () => {
    const previous = createGame(['Primeiro','Segundo'], 8);
    await writeLocal(previous);
    const next = createGame(['Novo','Outro'], 9), imported = encodeSave(next);
    await writeLocal(next, imported);
    expect(decodeSave((await readLocal())!).game).toEqual(next);
    const db = await new Promise<IDBDatabase>((resolve,reject) => {const r=indexedDB.open('terras-devastadas-local',1);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
    const values = await new Promise<unknown[]>((resolve,reject) => {const r=db.transaction('saves','readonly').objectStore('saves').getAll();r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
    db.close();
    expect(values).toContain(encodeSave(previous)); expect(values).toContain(imported);
    const invalid = structuredClone(next); invalid.players[0].vehicle.fuelUnits = -1;
    await expect(writeLocal(invalid)).rejects.toThrow();
    expect(await readLocal()).toBe(encodeSave(next));
  });
});
