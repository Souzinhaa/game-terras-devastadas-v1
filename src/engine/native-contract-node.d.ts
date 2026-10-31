/** Node functions used only by the contract test reporter; no runtime dependency. */
declare module 'node:fs' {
  export function mkdirSync(path: string, options: { recursive: true }): string | undefined;
  export function writeFileSync(path: string, data: string): void;
}
