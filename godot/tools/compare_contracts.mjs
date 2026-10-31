import { readFileSync } from 'node:fs';
import { isDeepStrictEqual } from 'node:util';
const root = new URL('../../', import.meta.url);
const native = JSON.parse(readFileSync(new URL('.tools/native-contracts.json', root), 'utf8'));
const reference = JSON.parse(readFileSync(new URL('.tools/ts-contracts.json', root), 'utf8'));
for (const name of new Set([...Object.keys(native), ...Object.keys(reference)])) {
  const equal = isDeepStrictEqual(native[name], reference[name]);
  console.log(`${name}: ${equal ? 'MATCH' : 'DIFFERENT'}`);
  if (!equal) process.exitCode = 1;
}
