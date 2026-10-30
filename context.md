# Terras Devastadas — contexto atual para desenvolvimento

## Fontes de verdade
- Regras de teste **v0.6**: `rules.md` e `docs/REGRAS_V06.md` (conflitos, decisões e duas vidas).
- Cartas **v0.2**, 74 modelos/148 cópias: `rules-cards.md`, `src/data/catalog.json` e `src/engine/catalog.ts`.
- Parâmetros novos: `src/data/rebalance.json`; parâmetros de combate/reparo: `src/engine/config.ts`.
- Conteúdo serializado: `CONTENT_VERSION = 0.6.0`, schema de envelope 4, combustível inteiro. Não migrar partidas v0.5 silenciosamente.
- Diagnóstico: `docs/DIAGNOSTICO_REBALANCEAMENTO.md`; integração: `docs/REBALANCEAMENTO_V05.md`.

Não restaurar tanque cheio, duas gerais iniciais, duplicatas E04/E06/E09, E06 por rodada, G09/G11/G12 +2 ou G21/G22 ±2. Não reimportar os contextos antigos dos pacotes de assets.

## Projeto e arquitetura
Protótipo hot-seat para 2–4 jogadores em React, TypeScript e Vite; motor puro em `src/engine`, conteúdo em `src/data`, IndexedDB em `src/application/saves.ts`. `transition` clona estado, valida/executa e só retorna resultado válido; erros não alteram estado ou RNG do chamador. Não resolver regras na UI nem interpretar texto/arte com LLM.

A seed define a sequência; preserve IDs de instâncias, versões, contadores, escolhas pendentes e fontes no save. Novos campos de apresentação derivam do motor, não constituem segunda fonte de estado.

## Regras desta edição
- Todos começam de Hatch: carga 4/tanque 8/consumo 1/vida 6, 3 combustíveis, duas vidas, um território defendido, uma sucata, fixo e uma geral. A compra normal ocorre inclusive no primeiro turno.
- Melhorar Hatch para sedã (7/12/2), SUV (6/12/2) ou caminhonete (10/15/3) ou Moto (2/10/1) custa 5 sucatas da carga e depósitos próprios locais e uma ação. Preserva vida atual, combustível, equipamentos, mão e vidas restantes; não cura nem renova vidas. Exceção confirmada: melhorar para Moto entrega tanque cheio (10); vida 6, defesa 4+, agilidade +1. Os demais modelos preservam combustível. Moto, SUV e caminhonete usam terra.
- Assumir um carro superior encontrado também custa 5 sucatas locais e uma ação; reparo prévio continua em turno separado. Não gerar sucata pelo carro substituído. Melhoria direta só parte do Hatch.
- Primeira destruição por qualquer dano: perde mão, equipamentos adicionais, tanque e carga; renasce Hatch íntegro com 3 combustíveis na mesma cidade. Territórios/depósitos preservados. Ação atual termina, próximo turno inteiro perdido sem compra ou ações. Imune a ataques/efeitos até encerrar esse turno; não participa de novas corridas. Em corrida já iniciada, fica retirado, mesmo após renascer.
- Segunda destruição elimina permanentemente, sem renovar vidas por melhoria/troca. Abandona territórios preservando defesa, instalações territoriais e estoque; remove bloqueios e ignora turnos. Último sobrevivente vence; todos eliminados simultaneamente encerram sem vencedor. Destruição cancela anúncio territorial. Sem roubo PvP na morte; tributo por fuga permanece.
- Reparos de carro de jogador exigem integridade positiva; não reativam carro destruído. Sem eliminação automática por falta de combustível nesta edição.
- Exploração: 3 usos por setor, uma ação, 2–3 itens sorteados individualmente no depósito. Hostis: fácil 2–3, médio 3–4, difícil 4–5 recursos, cada item sorteando sucata ou combustível para carga/reserva. Preservar excedentes até escolha.
- Corridas custam 1 combustível por inscrição nas três pistas. Dado animado em toda rolagem; PvP mostra vida/impacto/esquiva; corrida mostra avanço/chegada. Seed inicial aleatória por padrão, campo manual opcional, seed original salva e visível separada do RNG corrente.
- Durante a penalidade após renascer, mostrar “Bloqueado · sem ataque” no mapa, HUD e efeitos ativos. O marcador termina ao encerrar o turno de penalidade. O motor impede ataques normais/adicionais antes do dado. V11 apenas consome a ação; barricada bloqueia somente estrada, sem marcador de recuperação no carro.
- Fim da partida abre placar final com posição, pontos, setores, carro, vida, tanque, carga, depósitos e cartas/equipamentos restantes. Vencedor primeiro; sobreviventes por pontos/setores; eliminados por `eliminatedAtTurn` (última eliminação primeiro), com posições compartilhadas em empate. A classificação é apresentação e não altera a condição de vitória. “Ver placar final” reabre o resultado; exportação e nova partida continuam disponíveis.
- Uma geral por jogador por turno do mapa; combate/corrida não renovam. Antes do dado, nunca reação retroativa.
- Uma arma adicional por carro/rodada, compartilhada entre E01/E02/E03. Erro gasta munição/limite. Arma fixa separada.
- E04/E06/E09 únicos, além de E07/E08/E10. E06 uma vez por combate.
- G17 só no turno próprio, antes de viajar/agir: uma sucata própria local + ação principal + carta/cota. Prioriza sucata na carga, depois depósito próprio local. Protege última saída compatível, não acumula em rota fechada e permite viagem posterior sem outra ação. G18 remove antecipadamente por carta.
- G09/G11/G12 +1 unidade; G21/G22 ±1 de avanço. Outros efeitos preservados.
- Anúncio territorial ao encerrar próprio turno com 4 pontos; sustentar até próximo início. Queda abaixo de 4 cancela, retomar não restaura. Confirmar após expirações, antes da compra. Não cobrar imposto/manutenção de cidade.

## Implementação e pendências reais
Implementados: viagem, inventários/depósitos, reparos e troca paga, progressão de veículo, duas vidas, renascimento/penalidade/eliminação, vitória por sobrevivência, 74 cartas, equipamentos/territoriais, reações antes do dado, 12 hostis, corrida multirrodadas/marcos/inscrição/prêmio, saque simples, anúncios de vitória e persistência.

Parciais: combate de conquista com carro + fortificação simultâneos; defesa pessoal integrada ao saque; alerta compartilhado de saque; exploração regional (sorteio genérico). Recuperação do carro destruído por reparo/exploração e emergência por tanque vazio foram substituídas pelo ciclo de vidas v0.6; não restaurar. Não inventar habilidades fixas, condições mecânicas sem contrato ou uso obrigatório de água/pneu/bateria. Corrida exige pelo menos dois inscritos e devolve taxa se cancelar.

## Assets e limpeza
Runtime canônico em `public/assets/cards`, `hostiles`, `markers` e `resources`; veículos/mapas em `assets` importados por Vite. Metadados em `src/data`. Doze frentes alteradas substituem pelo ID as anteriores, sem modificar cópias. Não manter novamente pacotes duplicados de importação. `docs/LIMPEZA_V05.md` registra exclusões; Git preserva histórico.

Marcadores mostram tipo/valor; custos ficam separados de bônus ativos. `round:weapon:<vehicleId>` é o contador compartilhado. E06 usa `combat:<instanceId>`; não renova por alvo, rodada ou save/load. `victoryAnnouncements` e `travelAfterBlock` são serializados.

## Saves
Não há motor legado paralelo: saves de conteúdo anterior a 0.6.0 são recusados com original intacto. Não converter, reabastecer ou inventar vidas passadas. Serializar `deaths`, `skipTurns`, `penaltyActive`, `eliminated`, `finished`, `winnerReason` e retiradas da corrida. Ao iniciar outra partida, IndexedDB preserva backup interno do registro anterior. Para continuar uma sessão antiga, usar a versão correspondente no histórico Git; exportar backup antes de atualizar. Schema igual não significa conteúdo compatível.

## Trabalho local e validação
Node 24, `npm ci`, `npm test`, `npm run build`, `npm run dev`. No PowerShell `npm.cmd` pode ser necessário. `npm run test:ui` usa Playwright; instalar Chromium ou configurar Chrome. Não confundir simulações de combate com partidas completas; não houve playtest humano.

Atualizar motor, JSON, UI, regras e testes juntos. Testar custos atômicos, limites por instância/grupo, cancelamento de anúncio, recusa de legado e round-trip. Não apagar mapas/arte ativa para limpar arquivos de importação. Não adicionar backend, autenticação, bots ou multiplayer sem pedido.


## Interface vigente
A revisão com navegação lateral e mão em barra inferior foi desfeita a pedido do usuário. Usar o layout anterior definido por style.css/fullscreen.css/theme.css. Mapa antigo assets/mapa-expandido-v2.png, 1448×1086, mundo-base2800; Santa Cruz(83%,13%). Moto, regras v0.6, combate e placar final permanecem.
