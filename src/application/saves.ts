import { assertInvariants, CONTENT_VERSION, type Game } from '../engine/game';
import { laboratoryRules } from '../engine/config';

export interface LoadResult { game: Game; warnings: string[] }
export function encodeSave(game: Game): string {
  assertInvariants(game);
  return JSON.stringify({ format: 'terras-devastadas', schemaVersion: 4, contentVersion: game.contentVersion, fuelUnit: 'whole', state: game }, null, 2);
}
/** Nunca usa createGame: carregar não pode refazer kit, seed ou tanque. */
export function decodeSave(raw: string): LoadResult {
  try {
    const envelope = JSON.parse(raw);
    if (!envelope || envelope.format !== 'terras-devastadas' || envelope.schemaVersion !== 4) throw Error('Formato sem versão compatível com v0.6.');
    if (envelope.fuelUnit !== 'whole') throw Error('Unidade de combustível incompatível.');
    if (!envelope.state || envelope.state.schemaVersion !== envelope.schemaVersion || envelope.state.contentVersion !== envelope.contentVersion) throw Error('Versões do envelope e estado divergem.');
    if (envelope.contentVersion !== CONTENT_VERSION) throw Error('Partida de edição anterior incompatível com v0.6. Inicie uma nova partida; o original não será convertido.');
    const game = structuredClone(envelope.state) as Game;
    const warnings: string[] = [];
    if(game.rules?.combat&&game.rules.combat.moto===undefined){
      game.rules.combat.moto=structuredClone(laboratoryRules.combat.moto);
      warnings.push('Perfil da Moto adicionado; veículos, combustível e vidas da partida foram preservados.');
    }
    validateRules(game);
    assertInvariants(game);
    return { game, warnings };
  } catch (e) {
    throw Error(`Save não carregado. Original preservado. ${(e as Error).message}`);
  }
}
function validateRules(game: Game) {
  const walk = (value: unknown, reference: unknown): void => {
    if (typeof reference === 'object' && reference !== null) {
      if (typeof value !== 'object' || value === null) throw Error('RuleConfig inválido.');
      for (const key of Object.keys(reference)) walk((value as Record<string, unknown>)[key], (reference as Record<string, unknown>)[key]);
    } else if (typeof reference === 'number') {
      if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 0 || value > 1000) throw Error('Parâmetro provisório inválido.');
    } else if (typeof value !== typeof reference) throw Error('Parâmetro provisório inválido.');
  };
  walk(game.rules, laboratoryRules);
  if (game.rules.explorationUses < 1 || game.rules.territoryIntegrity < 1 || game.rules.attackDamage < 1 || Object.values(game.rules.combat).some(v => v.defense < 2 || v.defense > 6 || v.integrity < 1)) throw Error('Configuração de combate inválida.');
}

const DB_NAME = 'terras-devastadas-local';
function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => request.result.createObjectStore('saves');
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    request.onblocked = () => reject(Error('Banco bloqueado por outra aba.'));
  });
}
export async function readLocal(): Promise<string | null> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction('saves', 'readonly'), request = tx.objectStore('saves').get('current');
    request.onsuccess = () => resolve(typeof request.result === 'string' ? request.result : null);
    request.onerror = () => reject(request.error);
    tx.oncomplete = () => db.close();
  });
}
/** Backup e troca de current na mesma transação. Nenhuma exclusão de saves. */
export async function writeLocal(game: Game, importedRaw?: string): Promise<void> {
  const raw = encodeSave(game), db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction('saves', 'readwrite'), store = tx.objectStore('saves');
    const current = store.get('current');
    current.onsuccess = () => {
      const key = `${Date.now()}-${crypto.randomUUID()}`;
      if (importedRaw !== undefined) {
        if (typeof current.result === 'string') store.put(current.result, `backup-${key}`);
        store.put(importedRaw, `import-original-${key}`);
      }
      store.put(raw, 'current');
    };
    tx.oncomplete = () => { db.close(); resolve(); };
    tx.onerror = () => { db.close(); reject(tx.error); };
    tx.onabort = () => { db.close(); reject(tx.error ?? Error('Salvamento cancelado.')); };
  });
}
