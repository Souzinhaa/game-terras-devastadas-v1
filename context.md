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

Preferência do usuário registrada em 02/11/2026: features e correções sem indicação explícita de modo devem ser implementadas e verificadas nos dois modos nativos, normal/local (hot-seat) e Multiplayer LAN. Não concluir a entrega com apenas um modo atualizado. Conferir também a TV/Tabuleiro quando a apresentação pública for afetada, preservando privacidade e permissões. Restringir a um modo somente quando o pedido for específico dele. Isso não exige paridade com a referência React histórica.

Estão implementados turnos de 2–4 jogadores, 12 cidades/35 setores/19 rotas, viagem e eventos, exploração e depósitos, carga/tanque, reparos, cartas e revelações privadas, equipamentos/territoriais, progressão de veículo, combate/hostis/conquista/fuga, saque com defesa pessoal, corridas, duas vidas e vitória por sobrevivência ou anúncio territorial.

Há hot-seat no mesmo aparelho e LAN com anfitrião autoritativo, credenciais de assento, comandos individuais, recibos, reconexão e Tabuleiro/TV público opcional. Não existe migração automática de anfitrião; manter o app do anfitrião ativo. Não adicionar backend, autenticação ou bots por inferência.

UI usa tema e cenas compartilhados, área segura, folhas com rolagem/paginação, mão privada, leitura de cartas, Voltar contextual, movimento reduzido e proteção da revelação interrompida. [Relatório de layout LAN](godot/docs/LAN_LAYOUT_REVIEW.md).

Revisão de interação: `ui_feedback.gd` realça toque/foco sem mover botões nem alterar compra de cartas. `board_feedback.gd` destaca fatos públicos de dano, reparo, exploração, conquista e turno. A TV usa `network/tv_dashboard.gd`, com etapas do turno e placar compacto permanente, encontros públicos, foco/rolagem por controle remoto e movimento reduzido. A atualização passou em 13 suítes de UI, com 47 verificações do dashboard e 54 por resolução LAN; [capturas e limites](godot/docs/UI_INTERACTION_TV.md).

## Regras atuais e partidas antigas

Novas partidas registram `rules_profile=campaign-v07`, `rules_version=0.7` e `content_version=0.7.0`. Todos começam de Hatch: integridade 6, Defesa 4+, tanque máximo 8 com três combustíveis, carga máxima 5 com uma sucata, duas gerais já distribuídas sem animação, um setor próprio e duas vidas. Há compra no primeiro turno.

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


Atualização de 01/11/2026 — combate e acompanhamento: a LAN vincula `combatRoll` e a continuação ao combatente daquele ataque; hostil/fortificação é rolado pelo atacante do setor. `combatFast` não é oferecido na LAN. Em 0.7, uma geral por pessoa por rodada de combate, independente da cota do mapa; saves 0.6 preservam a regra antiga. `round_generals` é validado/persistido e renova depois dos dois ataques principais. Saves de combate antigos sem o campo conservam a cota já gasta.

TV e celulares, inclusive de não combatentes, usam a arena pública de `combat_view.gd` com dado, dano interpolado e efeitos iguais ao local. A projeção inclui somente vida anterior/posterior e fatos públicos; nunca mãos/capacidades alheias. Resultados recebidos durante animação são enfileirados, sem bloquear a autoridade. `race_board.gd` compartilha pista, veículos, marcos e chegada entre TV/celular/local. Novos avisos identificam quem reage/rola e relatam ações aceitas. O menu abre em “O que fazer agora?”, prioriza as ações e recolhe cartas/opções secundárias.

Validação: regressões Godot 4.7.2 em Windows e renderização real, incluindo `combat_turns_smoke` (permissões, cota/rodada, JSON/save), `public_encounters_ui_smoke` (TV/celular, animação, reconexão, movimento reduzido, limites compactos), suítes de combate, campanha LAN, balanceamento e layout. Capturas transitórias em `.tools/public-combat-tv.png`, `.tools/public-race-phone.png` e `.tools/public-race-tv.png`. APKs debug gerados em 01/11/2026: `0.0.4-combat-race`, código 9, celular ARM64 e TV ARM64/ARMv7. Assinaturas, pacotes, conteúdo e fingerprint das fontes atuais verificados; a assinatura do celular coincide com o APK anterior. Entregas: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk` na raiz; cópias, SHA256 e manifesto em `godot/builds/`. Android e TV físicos continuam pendentes.
Correção LAN de 02/11/2026 — versão `0.0.4-lan-flow`, código 10: o menu de ações LAN deixou de abrir a grade antiga de categorias. Agora oferece Agir aqui (com setores e opções legais na própria cidade), Viajar antes de agir, Cuidar do veículo/depósitos, Cartas/equipamentos e Encerrar meu turno. A entrada muda conforme a própria capacidade; não oferece ações do jogador ativo aos demais. Abrir/consultar menus não envia comandos.

Combate/corrida LAN têm arena/pista e decisões próprias lado a lado, com rolagem de reserva em telas compactas. As reações deixam de prender a interface numa folha antiga ou cobrir a animação. Cada snapshot aceito passa pela apresentação, preservando resultados quando RPCs chegam no mesmo frame. Acontecimentos públicos recentes são sanitizados, limitados a 12, persistidos e apresentados em celulares/TV; recursos privados continuam fora da projeção. A versão aparece na conexão LAN e no menu.

Validação Windows: `lan_action_menu_ui_smoke` (38 verificações em 892×445, 1280×720 e 2340×1080), suítes LAN/combate/layout e teste com cinco processos conectados por ENet: quatro jogadores usaram os botões do novo menu, exploraram, passaram por duas rodadas de combate e se inscreveram/rolaram a corrida; a TV recebeu apenas dados públicos. Harness: `godot/tools/test_lan_network.ps1 -PeerScript res://tests/lan_actions_peer.gd`. Evidência transitória em `.tools/lan-network-dc7b8dfdde3f4610ba8511e50536b64f/` e `.tools/lan-action-menu-updated.png`. Isso não comprova toque/rede em Android ou TV físicos.
APKs da correção LAN exportados em 02/11/2026: versão `0.0.4-lan-flow`, código 10, mesma assinatura debug anterior. Ambos verificados por assinatura, manifesto, conteúdo e fingerprint atual `a809d5ab8484c435238a287fc3d2b84ab8e351c9455adc0db4b48de7080d9765`. Entregas na raiz: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk`; manifesto e SHA256 em `godot/builds/`. As 13 suítes pertinentes passaram, assim como as jornadas ENet de menu/encontros e descoberta/reconexão/TV sem comandos. O harness de reconexão agora aguarda o intervalo real de 4 s antes de encerrar o servidor. Android/TV físicos seguem pendentes.

Tabuleiro/TV no jogo local — 02/11/2026, build `0.0.4-local-tv` (código 11): durante uma partida hot-seat, abrir **Menu → Conectar Tabuleiro/TV → Disponibilizar tabuleiro para a TV**. Na mesma rede Wi-Fi, abrir o aplicativo Tabuleiro na TV, selecionar a sala **Local · nome** (ou informar o IP/porta mostrados no celular) e aprovar **Aceitar TV** no celular. Todos continuam usando o mesmo celular; a TV acompanha mapa, turnos, combate e corrida sem mãos, carga, depósitos ou capacidades privadas. Só uma tela pública pode ser aprovada; clientes jogadores são recusados. Desconectar pelo mesmo menu, voltar à tela inicial, iniciar nova partida ou sair encerra a transmissão sem converter saves locais em sessões LAN. Após retomar o save local, disponibilizar novamente. A TV pode reconectar enquanto a transmissão estiver ativa; o celular precisa permanecer aberto.

Implementação: `NetworkEndpoint.host_local` observa os comandos aceitos de `local_session.gd` usando o motor hot-seat existente e a projeção pública compartilhada. Aprovação, fingerprint, descoberta, eventos, arena e pista reutilizam o fluxo TV/LAN. O save LAN fica preservado. Reações públicas identificam o jogador que realmente reagiu, inclusive fora da vez do mapa. Históricos públicos desta transmissão ficam em memória; reiniciar a transmissão cria novo contexto.

Validação Windows/Godot 4.7.2: `local_board_ui_smoke` verifica menu, estado/RNG/saves, comandos aceitos/recusados, reações fora do turno, dado animado na TV, corrida e ciclo de conexão. Regressões LAN/sessão/TV/arena passaram. `tools/test_lan_network.ps1 -PeerScript res://tests/local_board_peer.gd` passou com host local, TV, descoberta/reconexão, comando de TV recusado e três clientes jogadores recusados. O cenário `lan_actions_peer.gd` continuou passando com quatro jogadores LAN e TV (menus, combate e corrida). Captura de UI em `.tools/local-board-sharing.png`. Não equivale à validação em Android/TV físicos.