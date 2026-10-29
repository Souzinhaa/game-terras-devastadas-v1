# Contexto do jogo: Terras Devastadas

## 1) Visão geral

Terras Devastadas é um protótipo de jogo competitivo local em hot-seat, desenvolvido em React + TypeScript + Vite. O núcleo do jogo é um motor de regras puro, determinístico e reproduzível por seed, com estado persistido no IndexedDB do navegador.

Tema: sobrevivência pós-apocalíptica no interior paulista, com disputa territorial, veículos, recursos, exploração, combate e gerenciamento de rotas/cidades.

- Jogadores: 2 a 4
- Modo: local, hot-seat, no navegador
- Persistência: IndexedDB + export/import de JSON
- Motor: TypeScript puro em `src/engine`
- Interface: React em `src/ui` e montagem em `src/main.tsx`

## 2) Objetivo do projeto

O jogo foi pensado como protótipo digital de tabuleiro estratégico territorial. O objetivo final do MVP é:

- controlar cidades inteiras para somar pontos,
- sobreviver ao longo dos turnos,
- gerenciar recursos e veículos,
- explorar e conquistar sub-regiões,
- enfrentar inimigos e eventos aleatórios,
- manter a lógica do jogo reproduzível via seed.

O GDD principal está em `docs/GDD_Terras_Devastadas_Codex_v04.md` e foi usado como base para a implementação atual.

## 3) Estado atual do projeto

### Implementado

- mapa com 12 cidades e 35 setores/sub-regiões,
- sorteio inicial de ordem, veículos e posições,
- turno por jogador,
- viagem entre cidades,
- ações de exploração, conquista, combate, saque e administração,
- recursos (combustível, sucata, pneus, baterias, água, munição),
- cartão geral/equipamento/territorial/evento,
- inimigos/hostis com sistema de combate,
- controle de território e pontuação,
- save/load local no navegador,
- UI com assets visuais definidos em `src/ui`.

### Ainda parcial ou não implementado

- combate territorial completo contra jogadores,
- reações fora do turno,
- catálogo completo de equipamentos e explorações regionais,
- saque completo e emergência/eliminação final,
- corridas de múltiplas fases em nível completo,
- backend, multiplayer, autenticação, nuvem, bots.

A regra antiga de corrida de uma rolagem foi desativada para manter compatibilidade com v0.4.

## 4) Arquitetura do código

### Estrutura principal

- `src/main.tsx` — ponto de entrada da UI, estado de aplicação, modal de setup, salvamento, execução de ações do jogador.
- `src/engine/game.ts` — motor principal do jogo, estado global, criação da partida, rotas, veículos, recursos, pontos, validação e random determinístico.
- `src/engine/cardRules.ts` — regras de cartas, equipamentos, melhorias, combate, eventos, ações de compra e uso de cartas.
- `src/engine/catalog.ts` — catálogo de cartas, efeitos e pistas de corrida.
- `src/engine/hostiles.ts` — lógica de inimigos/hostis, combate, dano, fuga e escalas de ameaça.
- `src/engine/config.ts` — regras laboratoriais/variações de configuração do jogo.
- `src/application/saves.ts` — serialização, validação e persistência dos saves.
- `src/ui/` — componentes visuais da interface (tabuleiro, ações, hand, mapas, cartões, saúde, etc.).
- `src/data/` — JSON de cidades, rotas, veículos, cartas, hostis, mapa.

### Estado central do jogo

O estado do jogo é representado pela interface `Game` em `src/engine/game.ts`. Ele inclui:

- `players`: jogadores ativos
- `territories`: mapa e controle territorial
- `encounter`: combate ativo
- `blocks`: bloqueios de rota
- `found`: veículos encontrados
- `localScrap`: sucata de cidade
- `log`: histórico de eventos
- `seed`: valor que torna o RNG reproduzível
- `rules`: regras ativas da partida
- `winner`: vencedor final, se houver

A lógica principal é feita através de `transition(game, action)`, que aplica ações no estado e produz um novo `Game`.

## 5) Regras-chave do jogo

### 5.1 Veículos

Os veículos confirmados são:

- Hatch
- Sedan
- SUV
- Pickup

Características principais:

- carga máxima,
- tanque de combustível,
- custo fixo de viagem por modelo,
- terra permitida ou não,
- equipamento fixo e extras.

O jogo trabalha com duas capacidades separadas:

- `tank` = combustível do tanque
- `cargo` = itens carregados em estoque

A reserva de combustível ocupa espaço de carga; o tanque é separado.

### 5.2 Recursos

Recursos implementados:

- combustível
- sucata
- pneus
- baterias
- água
- munição

Sem troca ou doação geral entre jogadores; cartas podem conceder auxílio.

### 5.3 Mapa e cidades

Mapa confirmado:

- 12 cidades
- 35 sub-regiões
- 8 pontos possíveis

Cidades e sub-regiões são definidas em `src/data/cities.json`, com pontos base e regiões. O cálculo de vitória usa `points(s, id)` para verificar cidade completa.

### 5.4 Vitória

A lógica conforme GDD v0.4:

- a vitória é por controle completo de cidades que somem 4 pontos, ou pela permanência como último sobrevivente,
- uma cidade pertence inteira a quem controla todas as suas sub-regiões ao mesmo tempo,
- menos de 4 sub-regiões vale 0,5 pontos
- 4 ou mais vale 1 ponto,
- perder uma sub-região remove o ponto correspondente,
- retomar domínio completo restaura.

### 5.5 Sistema de turno

A sequência do turno no protótipo atual:

1. expirar efeitos e renovar contadores,
2. compra de carta geral,
3. ações livres,
4. viagem para cidade vizinha (opcional),
5. ação principal,
6. encerramento e verificação de vitória.

Viajar para cidade vizinha não substitui a ação principal.

### 5.6 Cartas

Tipos principais:

- gerais
- equipamentos
- territoriais
- eventos
- corrida

Cartas têm efeitos de:

- dano,
- redução de dano,
- rolagem/bonus,
- recursos,
- bloqueios,
- fuga,
- exploração,
- ameaças / hostis,
- corrida, loot e interação territorial.

O catálogo de cartas está em `src/data/catalog.json` e é consolidado em `src/engine/catalog.ts`.

## 6) Rng, determinismo e reprodução

O jogo usa um RNG reproduzível e anexado ao estado:

- `game.seed`
- `random(s, max)` em `src/engine/game.ts`
- `Math.imul` e LCG/incremental determinístico

Isso significa que, com a mesma seed e as mesmas ações, a partida pode ser reproduzida. Isso é essencial para debug, testes automatizados e balanceamento.

## 7) Estrutura dos dados e JSON

Arquivos em `src/data`:

- `cities.json` — cidades, regiões e pontuação
- `routes.json` — rotas e conectividade entre cidades
- `vehicles.json` — modelos de veículos
- `cards.json` — cartas e descrição básica
- `hostiles.json` — dados de inimigos e dificuldades
- `map-view.json` — visão do mapa
- `catalog.json` — catálogo estrutural de cartas
- `effect-markers.json` — marcadores de efeitos
- `marker-shapes.json` — formas visuais

## 8) Salvamento e carregamento

A persistência atual usa IndexedDB por navegador. O código relevante está em:

- `src/application/saves.ts`

Regras importantes:

- cada ação aceita salva automaticamente,
- exporta JSON para cópia independente,
- importação preserva backup interno,
- saves sem versão ou schema inválido são recusados,
- mudanças de navegador/perfil/porta podem alterar origem do save,
- estados acima dos limites são pausados para escolha explícita, sem truncamento automático.

## 9) Comandos de execução

No projeto, os comandos principais são:

```powershell
npm.cmd ci
npm.cmd run dev
npm.cmd run build
npm.cmd run preview
npm.cmd test
npm.cmd run test:ui
```

Observações:

- `npm.cmd` é recomendado no PowerShell do Windows.
- `npm.cmd run dev` inicia o Vite em localhost.
- `npm.cmd test` roda a suíte de testes do motor.
- `npm.cmd run test:ui` usa Playwright/Chrome headless.

## 10) Testes e validação

Há testes focados em:

- engine de jogo,
- catálogo de cartas,
- hostis,
- saves.

Arquivos de teste relevantes:

- `src/engine/game.test.ts`
- `src/engine/catalog.test.ts`
- `src/engine/hostiles.test.ts`
- `src/application/saves.test.ts`

Quando alterar regras, é importante manter compatibilidade com os testes e com o GDD atual.

## 11) Diretrizes para IA e manutenção

### O que qualquer IA deve saber ao mexer neste repositório

- O jogo é um protótipo local, não um backend/service real.
- Não assuma que tudo está terminado: o GDD e o código podem divergir em partes.
- Sempre confira o GDD principal antes de alterar regras de balanceamento ou estrutura de turno.
- O estado do jogo é centralizado em um único objeto `Game`; evite duplicar estado em componentes.
- Preservar deterministic behavior é crucial.
- Alterações de regra devem ser refletidas em documentação relevante e, se possível, em testes.
- A UI deve ser tratada como camada de apresentação; a lógica de regras fica no motor em `src/engine`.

### Arquivos que geralmente importam mudanças de regra

- `src/engine/game.ts`
- `src/engine/cardRules.ts`
- `src/engine/catalog.ts`
- `src/engine/hostiles.ts`
- `src/application/saves.ts`
- `docs/GDD_Terras_Devastadas_Codex_v04.md`
- `docs/ATUALIZACAO_V04.md`

## 12) Resumo executivo para agentes de IA

Terras Devastadas é um protótipo de jogo de estratégia/territorial pós-apocalíptico em navegador. Ele usa React + TypeScript + Vite, motor fortemente tipado em `src/engine`, dados em JSON e persistência local. A lógica do jogo é determinística por seed, o foco é o tabuleiro de cidades/territórios, os recursos, os veículos e a interação por turno. A interface é hot-seat local, sem backend ou multiplayer. Qualquer alteração deve respeitar o motor puro, a documentação do GDD e a compatibilidade com saves/testes.

## 13) Referências úteis

- `README.md`
- `docs/GDD_Terras_Devastadas_Codex_v04.md`
- `docs/ATUALIZACAO_V04.md`
- `docs/IMPLEMENTACAO.md`
- `docs/INTERFACE.md`
- `src/engine/game.ts`
- `src/engine/cardRules.ts`
- `src/engine/hostiles.ts`
- `src/application/saves.ts`
