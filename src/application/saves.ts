import { migrateHostiles } from '../engine/hostiles';
import { migrateCatalog } from '../engine/cardRules';
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
    if (!envelope || envelope.format !== 'terras-devastadas' || ![3, 4].includes(envelope.schemaVersion)) throw Error('Formato sem versão reconhecida. O protótipo v0.1 não tinha save; não é seguro inferir sua unidade ou topologia.');
    if (!['whole', 'half'].includes(envelope.fuelUnit) || (envelope.schemaVersion === 4 && envelope.fuelUnit !== 'whole')) throw Error('Unidade de combustível incompatível.');
    if (!envelope.state || envelope.state.schemaVersion !== envelope.schemaVersion || envelope.state.contentVersion !== envelope.contentVersion) throw Error('Versões do envelope e estado divergem.');
    if (envelope.schemaVersion === 4 && ![CONTENT_VERSION, '0.4.0', '0.4.1'].includes(envelope.contentVersion)) throw Error('Versão de conteúdo não suportada.');
    if (envelope.schemaVersion === 3 && envelope.contentVersion !== '0.3.0') throw Error('Schema legado sem contrato de conteúdo conhecido.');
    const game = structuredClone(envelope.state) as Game;
    const warnings: string[] = [];
    if (envelope.schemaVersion === 3) {
      // Contrato v3: mesmas entidades/IDs, combustível em whole ou ticks half explícitos.
      // Valores ímpares de ticks não têm conversão inteira sem perda: rejeitar.
      if (envelope.fuelUnit === 'half') {
        const convert = (n: number) => { if (!Number.isSafeInteger(n) || n < 0 || n % 2) throw Error('Meia unidade remanescente não admite conversão inteira sem perda.'); return n / 2; };
        for (const p of game.players) { p.vehicle.fuelUnits = convert(p.vehicle.fuelUnits); p.stock.fuel = convert(p.stock.fuel); }
        for (const t of Object.values(game.territories)) t.stock.fuel = convert(t.stock.fuel);
        for (const f of game.found) f.vehicle.fuelUnits = convert(f.vehicle.fuelUnits);
      }
      game.schemaVersion = 4; game.contentVersion = CONTENT_VERSION;
      game.rules = structuredClone(laboratoryRules);
      warnings.push('Contrato v3 migrado para v4. Seed, IDs, posição, cartas e recursos preservados; nenhum tanque foi completado. Capacidades agora seguem o GDD v0.4.');
    }
    if(!game.cardState){migrateCatalog(game);warnings.push('Catálogo de 74 cartas integrado; cartas antigas de bloqueio mantêm seus IDs e recebem os efeitos G17/G18. Seed, tanques e recursos preservados.');}
    if(game.contentVersion!==CONTENT_VERSION){game.contentVersion=CONTENT_VERSION;warnings.push('Conteúdo atualizado para 0.4.2 com catálogo de hostis.');}
    warnings.push(...migrateHostiles(game));
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
