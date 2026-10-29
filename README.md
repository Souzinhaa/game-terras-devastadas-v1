# Terras Devastadas

Protótipo hot-seat local em **React + TypeScript + Vite**, com motor puro, RNG reproduzível e persistência IndexedDB. Fonte atual: [GDD v0.4](docs/GDD_Terras_Devastadas_Codex_v04.md), lido integralmente. Esta versão substitui os valores do protótipo v0.1.

## Rodar localmente

Requer Node.js 24 e npm. No PowerShell use `npm.cmd` se a política bloquear `npm.ps1`.

```powershell
npm.cmd ci
npm.cmd run dev
```

Abra o endereço exibido pelo Vite, normalmente **http://127.0.0.1:5173**. Sorteie 2–4 jogadores; inicie o turno para comprar a geral. Viajar uma cidade vizinha não gasta a ação principal. Depósitos próprios da cidade e abastecimento são livres. O painel explica rotas indisponíveis.

```powershell
npm.cmd test
npm.cmd run build
npm.cmd run preview
npm.cmd run test:ui
```

`test:ui` usa o Google Chrome instalado, em modo headless, na porta 5174. Se não houver Chrome, configure o canal em `playwright.config.ts` para um navegador Playwright instalado. Testes de motor/IndexedDB não precisam de navegador.

## Regras de veículos confirmadas

| Classe | Carga | Tanque | Custo fixo por viagem | Terra |
|---|---:|---:|---:|---|
| Hatch | 4 | 8 | 1 | Não |
| Sedã | 7 | 12 | 2 | Não |
| SUV | 6 | 12 | 2 | Sim |
| Caminhonete (`pickup`) | 10 | 15 | 3 | Sim |

Tanque separado da carga; reserva de combustível na carga ocupa espaço. Novas partidas: tanque cheio, **1 sucata**, fixo vinculado ao modelo, **2 gerais** e nenhum adicional. A compra da primeira geral ocorre ao iniciar o primeiro turno. Habilidades dos fixos continuam abertas; não foram inventadas.

## Salvar e carregar

Cada comando aceito salva automaticamente no IndexedDB deste navegador e origem. A interface informa salvamento/falha; exporte JSON para ter uma cópia independente. Mudar a porta, navegador ou perfil muda a origem do save. Use uma única aba por partida.

Importar e iniciar outra partida preservam o save anterior em backup interno; importações também guardam o JSON original. Nenhuma atualização completa tanque ou reaplica kit. Estados com carga/tanque/mão/depósito acima da capacidade ficam pausados para **escolha explícita**, sem truncamento automático.

Saves sem versão, com unidade ambígua, fração não conversível ou schema desconhecido são recusados; o arquivo original e a sessão atual permanecem intactos. O protótipo anterior deste repositório não tinha save. O migrador suporta somente o contrato legado explícito descrito em [ATUALIZACAO_V04.md](docs/ATUALIZACAO_V04.md), não qualquer arquivo chamado “v0.3”.

## Estado e limites

Implementados: 12 cidades/35 setores, sorteio, turno, viagem e ação na chegada, quatro veículos, descoberta e troca, estoques locais, excedentes, bloqueios por carta, fuga por rota, combate básico, exploração, controle/pontos, save/load e UI com os assets fornecidos.

Ainda parciais: combate territorial contra jogadores, reações fora do turno, catálogo de equipamentos e explorações regionais, saque, emergência/eliminação e corridas completas. A antiga corrida de uma rolagem foi desativada por incompatibilidade com as regras v0.4. Sem autenticação, backend, nuvem, bots ou multiplayer. Não houve playtest humano nem balanceamento.

Veja a [matriz atual, migração, heurísticas de interface e limitações](docs/ATUALIZACAO_V04.md). O registro v0.1 em `docs/IMPLEMENTACAO.md` foi mantido apenas como histórico.

Interface redesenhada com a skill frontend-design: [direção visual, navegação e movimento acessível](docs/INTERFACE.md).
