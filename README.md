# Terras Devastadas

Jogo de tabuleiro digital pós-apocalíptico, hot-seat local para 2–4 jogadores. React + TypeScript + Vite, motor determinístico por seed, persistência IndexedDB.

## Rodar

Node.js 24 e npm:

```sh
npm ci
npm run dev
npm test
npm run build
```

No PowerShell, use `npm.cmd` se `npm.ps1` estiver bloqueado. UI: `npx playwright install chromium` e `npm run test:ui` (ou configure Chrome no Playwright).

## Edição atual

Regras v0.5 / cartas v0.2 / conteúdo do save 0.5.0. Consulte [context.md](context.md), [rules.md](rules.md) e [rules-cards.md](rules-cards.md).

| Modelo | Carga | Tanque máximo | Consumo | Combustível inicial | Terra |
|---|---:|---:|---:|---:|---|
| Hatch | 1 | 8 | 1 | 3 | Não |
| Sedã | 7 | 12 | 2 | 6 | Não |
| SUV | 6 | 12 | 2 | 6 | Sim |
| Caminhonete | 10 | 15 | 3 | 9 | Sim |

Inicial: uma sucata, uma geral e equipamento fixo. Comprar uma geral ao iniciar também o primeiro turno. Viajar normalmente preserva a ação principal. G17 consome sucata/ação mas ainda permite viajar. Vitória territorial: anunciar ao encerrar com 4 pontos e sustentar até o próximo início.

Armas adicionais compartilham um ataque por carro/rodada. E04/E06/E09 são únicos; E06 uma vez por combate. Doze cartas e os marcadores foram atualizados. Veja [a implementação do rebalanceamento](docs/REBALANCEAMENTO_V05.md) e [a limpeza de duplicatas](docs/LIMPEZA_V05.md).

## Saves e limitações

Exportar JSON mantém cópia independente. IndexedDB é local ao navegador/origem. Saves de edições anteriores são recusados sem alteração, para não misturar regras e arte; não há migração automática para este rebalanceamento. Nova partida preserva backup interno do save anterior. Para continuar jogo antigo, use a versão correspondente no Git.

Implementados: 12 cidades/35 setores, viagens, cartas, hostis, equipamentos, corrida por marcos, saque simples, controle e anúncios, inventários e persistência. Parciais: defesa pessoal integrada à conquista/saque, alerta de saque, perfis regionais e emergência/eliminação completa. Sem servidor, multiplayer ou bots. Balanceamento continua em teste; não houve partidas humanas medidas.
