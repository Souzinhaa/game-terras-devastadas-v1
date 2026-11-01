# Terras Devastadas — contexto atual de desenvolvimento

Atualizado em 31/10/2026. Alvo principal: **Godot 4.7 Standard / Android em paisagem**, branch **feature/release-0.0.4**. A implementação foi validada com Godot 4.7.2.

## Entradas e precedência

1. [rules.md](rules.md): contrato atual das novas partidas Godot, edição 0.7.
2. [rules-cards.md](rules-cards.md): definições, composição ativa e exceções.
3. [docs/COMO_JOGAR.md](docs/COMO_JOGAR.md): guia de jogador Android, LAN e hot-seat.
4. [godot/CONTEXT.md](godot/CONTEXT.md) e [godot/README.md](godot/README.md): arquitetura, execução, persistência, testes e exportação.
5. [godot/docs/REBALANCEAMENTO_V07.md](godot/docs/REBALANCEAMENTO_V07.md): decisões de design e compatibilidade.

Verificar comportamento no motor e nos testes quando houver divergência. Arte, catálogo, plano e relato histórico não demonstram efeito implementado. Não resolver regras pelo texto ou OCR das cartas.

## Estado funcional nativo

Estão implementados turnos de 2–4 jogadores, 12 cidades/35 setores/19 rotas, viagem e eventos, exploração e depósitos, carga/tanque, reparos, cartas e revelações privadas, equipamentos/territoriais, progressão de veículo, combate/hostis/conquista/fuga, saque com defesa pessoal, corridas, duas vidas e vitória por sobrevivência ou anúncio territorial.

Há hot-seat no mesmo aparelho e LAN com anfitrião autoritativo, credenciais de assento, comandos individuais, recibos, reconexão e Tabuleiro/TV público opcional. Não existe migração automática de anfitrião; manter o app do anfitrião ativo. Não adicionar backend, autenticação ou bots por inferência.

UI usa tema e cenas compartilhados, área segura, folhas com rolagem/paginação, mão privada, leitura de cartas, Voltar contextual, movimento reduzido e proteção da revelação interrompida. [Relatório de layout LAN](godot/docs/LAN_LAYOUT_REVIEW.md).

Revisão de interação: `ui_feedback.gd` realça toque/foco sem mover botões nem alterar compra de cartas. `board_feedback.gd` destaca fatos públicos de dano, reparo, exploração, conquista e turno. A TV usa `network/tv_dashboard.gd`, com etapas do turno e placar compacto permanente, encontros públicos, foco/rolagem por controle remoto e movimento reduzido. A atualização passou em 13 suítes de UI, com 47 verificações do dashboard e 54 por resolução LAN; [capturas e limites](godot/docs/UI_INTERACTION_TV.md).

## Regras atuais e partidas antigas

Novas partidas registram `rules_profile=campaign-v07`, `rules_version=0.7` e `content_version=0.7.0`. Todos começam de Hatch: integridade 6, Defesa 4+, tanque máximo 8 com três combustíveis, carga máxima 4 com uma sucata, uma geral, um setor próprio e duas vidas. Há compra no primeiro turno.

Vitória territorial exige três pontos anunciados ao encerrar e sustentados até o próximo início próprio. Exploração escolhe uma unidade de sucata/combustível dentro de 2–3 itens no depósito. Água/pneu/bateria da carga podem virar sucata uma vez por turno. Upgrade custa cinco sucatas locais e uma ação, preservando integridade e combustível inclusive na Moto. SUV/Caminhonete usam Defesa 4+. Primeira destruição protege até o próximo início próprio, sem perder essa vez; segunda elimina. Saque simples é D6 contra D6, empate da defesa; a corrida é opcional na inscrição.

Setup atribui ameaças por faixas fácil/média/difícil, com risco público e identidade oculta até revelar. E11/V16 não entram nos baralhos novos: 74 definições e 148 identidades no registro, das quais 72 definições/144 cópias disponíveis no setup 0.7.

Combate rápido avança somente até uma escolha e não confirma cartas/recompensas. Passagem automática de reações é opção de cada jogador por combate, reversível antes do dado. Esses controles também podem ser usados em campanhas antigas sem trocar seus valores de regras.

Saves nativos `campaign-v06` preservam seus baralhos, quatro pontos, combustível da Moto, defesa dos veículos pesados e penalidades anteriores. Campos aditivos não devem rerrolar RNG nem converter a edição. O perfil legado `stage1` mantém suas limitações. Não importar IndexedDB/JSON React silenciosamente.

## Arquitetura e integridade

O motor nativo é `godot/scripts/game_state.gd`, apoiado por `campaign_rules.gd`, `world_rules.gd` e `combat_rules.gd`. UI envia comandos; RNG, custos, dano, capacidades e recompensas pertencem ao motor.

Consultas de disponibilidade simulam a validação em cópia do estado. Recusas restauram o estado. Aquisições usam `gain_card`; remoções usam `take_hand_card` para preservar instâncias e tickets de revelação. Exploração entrega no depósito e o popup mostra apenas o delta real.

Na LAN, `SessionAuthority` executa e salva comandos/recibos; `CommandCatalog` restringe opções ao ator; `ViewProjector` fornece projeções privadas/públicas. O cliente não recebe o save integral. `game.player()` significa jogador ativo, não o dono do aparelho.

Saves hot-seat: `user://campaign-native-v1.json`; LAN: `user://campaign-lan-v1.json`. Não intercambiar os dois arquivos. Falhas de escrita são tratadas sem repetir a ação/RNG; a LAN bloqueia mutações enquanto a gravação estiver pendente.

## Build, evidência e pendências

Build Android de teste: `0.0.4-ui-tv`, app **Terras Devastadas Teste 0.7**, pacote `com.bhsp.terrasdevastadas.preview.v07`. ARM64, mínimo API 24, alvo API 36 no template verificado. O workflow usa Godot/templates 4.7.2 e assinatura debug temporária; não é distribuição de release.

A execução CI [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924) passou em 444 verificações de regras/LAN e exportou APK com assinatura v2/v3 verificada. Regressões de campanha/combate 0.6 e testes renderizados passaram no Windows. Layout móvel validado em três resoluções com área segura simulada. Testar Android físico e medir partidas humanas continuam pendentes.

Pendências: geração de sucata solta de E11, conteúdo/reativação de V16, semântica adicional do alerta de saque, impasses sem dano, desempenho em aparelhos de entrada, toque/teclado/recortes/pausa e LAN real/TV. Não criar regras para preencher esses vazios sem nova instrução.

## Referência e histórico

React/TypeScript continua em `src/`, com edição 0.6 e envelope IndexedDB 4. Não recebeu o rebalanceamento nativo 0.7 nem tem paridade integral de seed/recompensas. Instruções e contexto anteriores foram preservados em [CONTEXTO_REACT_V06.md](docs/historico/CONTEXTO_REACT_V06.md) e [regras de referência anteriores](docs/historico/REGRAS_REFERENCIA_V06.md). O GDD e relatórios antigos documentam decisões de suas épocas; os documentos atuais acima orientam o desenvolvimento Android.

