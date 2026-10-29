type Name = 'map' | 'car' | 'cards' | 'history' | 'arrow' | 'check' | 'close' | 'city' | 'flag' | 'route' | 'tools' | 'fuel' | 'cargo' | 'shield';
const paths: Record<Name, string> = {
  map: 'm3 5 6-2 6 2 6-2v16l-6 2-6-2-6 2V5Zm6-2v16m6-14v16',
  car: 'm5 9 2-5h10l2 5M4 9h16v10H4V9Zm0 6h16M7 19v2m10-2v2M7 12h1m8 0h1',
  cards: 'M7 3h13v16H7V3ZM4 6H2v16h13v-1m-5-10h7m-7 4h4',
  history: 'M3 11a9 9 0 1 1 2 7M3 4v7h7m2-5v6l4 2',
  arrow: 'M4 12h16m-6-6 6 6-6 6',
  check: 'm5 12 4 4L19 6',
  close: 'm6 6 12 12M6 18 18 6',
  city: 'M3 21h18M5 21V10l4-3v14M9 12h6v9m0-16 4-2v18M4 10h6m5-5h5M7 13v2m10-6v2m0 4v2m-5 1v3',
  flag: 'M5 22V3m0 1c5-5 9 5 15 0v11c-6 5-10-5-15 0',
  route: 'M5 5h10a4 4 0 0 1 0 8H9a4 4 0 0 0 0 8h10M5 2v6m-3-3h6m8 13 3 3-3 3',
  tools: 'm14 6 4 4m-8 3-7 7 2 2 7-7m-1-5a6 6 0 0 1 8-7l-4 4 3 3 4-4a6 6 0 0 1-8 8Z',
  fuel: 'M4 21V5h10v16M2 21h14M6 8h6v5H6V8Zm9-3 5 5v8a2 2 0 0 1-4 0v-3h-2m4-8v4h3',
  cargo: 'm3 7 9-4 9 4v13l-9 3-9-3V7Zm0 0 9 4 9-4M12 11v12M8 5l9 4v5',
  shield: 'm12 3 9 4v6c0 5-9 9-9 9s-9-4-9-9V7l9-4Zm-4 9 3 3 5-6',
};
export function Icon({ name }: { name: Name }) {
  return <svg className="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={paths[name]}/></svg>;
}
