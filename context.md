# Terras Devastadas — contexto atual para desenvolvimento

## Fontes de verdade
- Regras de teste **v0.5**: `rules.md`.
- Cartas **v0.2**, 74 modelos/148 cópias: `rules-cards.md`, `src/data/catalog.json` e `src/engine/catalog.ts`.
- Parâmetros novos: `src/data/rebalance.json`; parâmetros de combate/reparo: `src/engine/config.ts`.
- Conteúdo serializado: `CONTENT_VERSION = 0.5.0`, schema de envelope 4, combustível inteiro.
- Diagnóstico: `docs/DIAGNOSTICO_REBALANCEAMENTO.md`; integração: `docs/REBALANCEAMENTO_V05.md`.

Não restaurar tanque cheio, duas gerais iniciais, duplicatas E04/E06/E09, E06 por rodada, G09/G11/G12 +2 ou G21/G22 ±2. Não reimportar os contextos antigos dos pacotes de assets.

## Projeto e arquitetura
Protótipo hot-seat para 2–4 jogadores em React, TypeScript e Vite; motor puro em `src/engine`, conteúdo em `src/data`, IndexedDB em `src/application/saves.ts`. `transition` clona estado, valida/executa e só retorna resultado válido; erros não alteram estado ou RNG do chamador. Não resolver regras na UI nem interpretar texto/arte com LLM.

A seed define a sequência; preserve IDs de instâncias, versões, contadores, escolhas pendentes e fontes no save. Novos campos de apresentação derivam do motor, não constituem segunda fonte de estado.

## Regras desta edição
- Hatch carga 1/tanque 8/consumo 1; sedã 7/12/2; SUV 6/12/2; caminhonete 10/15/3. Apenas SUV/caminhonete usam terra; sem sobretaxa por carga/terreno.
- Inicial: um território defendido, Integridade máxima, uma sucata, fixo e uma geral, zero adicional. Combustível 3/6/6/9. A compra normal ocorre inclusive no primeiro turno.
- Uma geral por jogador por turno do mapa; combate/corrida não renovam. Antes do dado, nunca reação retroativa.
- Uma arma adicional por carro/rodada, compartilhada entre E01/E02/E03. Erro gasta munição/limite. Arma fixa separada.
- E04/E06/E09 únicos, além de E07/E08/E10. E06 uma vez por combate.
- G17 só no turno próprio, antes de viajar/agir: uma sucata própria local + ação principal + carta/cota. Prioriza sucata na carga, depois depósito próprio local. Protege última saída compatível, não acumula em rota fechada e permite viagem posterior sem outra ação. G18 remove antecipadamente por carta.
- G09/G11/G12 +1 unidade; G21/G22 ±1 de avanço. Outros efeitos preservados.
- Anúncio territorial ao encerrar próprio turno com 4 pontos; sustentar até próximo início. Queda abaixo de 4 cancela, retomar não restaura. Confirmar após expirações, antes da compra. Não cobrar imposto/manutenção de cidade.

## Implementação e pendências reais
Implementados: viagem, inventários/depósitos, reparos e troca, 74 cartas, equipamentos/territoriais, reações antes do dado, 12 hostis com poderes e dano persistente, corrida multirrodadas/marcos/inscrição/prêmio, saque simples, anúncios de vitória e persistência.

Parciais: combate de conquista com carro + fortificação simultâneos; defesa pessoal integrada ao saque; alerta compartilhado de saque; exploração regional (sorteio genérico); protocolo completo de emergência/eliminação; vitória por último sobrevivente depende dessa eliminação. Não declarar esses sistemas concluídos por existirem na regra de referência. Não inventar habilidades fixas, condições mecânicas sem contrato ou uso obrigatório de água/pneu/bateria. Corrida NÃO está desativada: exige pelo menos dois inscritos e devolve taxa se cancelar.

## Assets e limpeza
Runtime canônico em `public/assets/cards`, `hostiles`, `markers` e `resources`; veículos/mapas em `assets` importados por Vite. Metadados em `src/data`. Doze frentes alteradas substituem pelo ID as anteriores, sem modificar cópias. Não manter novamente pacotes duplicados de importação. `docs/LIMPEZA_V05.md` registra exclusões; Git preserva histórico.

Marcadores mostram tipo/valor; custos ficam separados de bônus ativos. `round:weapon:<vehicleId>` é o contador compartilhado. E06 usa `combat:<instanceId>`; não renova por alvo, rodada ou save/load. `victoryAnnouncements` e `travelAfterBlock` são serializados.

## Saves
Não há motor legado paralelo: saves de conteúdo anterior a 0.5.0 são recusados com original intacto. Não converter, reabastecer ou descartar duplicatas automaticamente. Ao iniciar outra partida, IndexedDB preserva backup interno do registro anterior. Para continuar uma sessão antiga, usar o código da versão correspondente no histórico Git; exportar backup antes de atualizar. Schema igual não significa conteúdo compatível.

## Trabalho local e validação
Node 24, `npm ci`, `npm test`, `npm run build`, `npm run dev`. No PowerShell `npm.cmd` pode ser necessário. `npm run test:ui` usa Playwright; instalar Chromium ou configurar Chrome. Não confundir simulações de combate com partidas completas; não houve playtest humano.

Atualizar motor, JSON, UI, regras e testes juntos. Testar custos atômicos, limites por instância/grupo, cancelamento de anúncio, recusa de legado e round-trip. Não apagar mapas/arte ativa para limpar arquivos de importação. Não adicionar backend, autenticação, bots ou multiplayer sem pedido.
