# Terras Devastadas — contexto atual para IA / Godot

**Atualização:** 31/10/2026. Este arquivo descreve o runtime nativo, não a totalidade da referência React.

**LAN/TV:** serviço autoritativo, lobby, capacidades por jogador, projeções privadas/públicas, recibos persistidos, reconexão e interface Tabuleiro implementados para testes. Cinco processos Windows validaram quatro jogadores e TV opcional; APKs de debug foram gerados. Android físico/TV real continuam pendentes. Ver [MULTIPLAYER_LAN_IMPLEMENTATION.md](docs/MULTIPLAYER_LAN_IMPLEMENTATION.md) e [protocolo](docs/MULTIPLAYER_LAN_PROTOCOL.md).

**Correção após relato Android:** a revisão `0.2.1-lan-ui` reutiliza `game_hud.tscn` na LAN por `network/player_hud.gd`; prepara salas em `connection_menu.gd`, usa ações paginadas e descoberta por consulta UDP com resposta unicast. Não restaurar a barra lateral de ações do protótipo. Relato de instalação na Philips 50 polegadas ainda sem modelo/sistema/erro; usuário preferiu priorizar layout. Ver [LAN_UI_TOUCH_FIX.md](docs/LAN_UI_TOUCH_FIX.md).

## 1. Entrada e fontes de verdade

- Abrir `project.godot` no **Godot 4.7 Standard**. Validação efetuada no 4.7.2.
- Cena de entrada: `scenes/bootstrap.tscn`; celular abre `scenes/main.tscn`, feature `tv_board` abre `scenes/lan.tscn` como tela pública.
- Alvo: Android ARM64, paisagem, 2–4 jogadores; hot-seat offline preservado e modo LAN em aparelhos próprios. Tabuleiro Android TV opcional em pacote separado ARM64/ARMv7.
- Renderer: Compatibility. Canvas-base 1440 × 810, `canvas_items` e `expand`.
- Regras de referência: `../rules.md`, `../rules-cards.md`, `../docs/REGRAS_V06.md`.
- Implementação de referência: `../src/engine/game.ts`, `cardRules.ts`, `hostiles.ts`, `catalog.ts`, `config.ts`.
- Dados nativos: `data/*.json`; conferir consistência com `../src/data` ao migrar conteúdo.
- UI: `../update_ui.md` e `docs/UI_IMPLEMENTATION.md`. O relatório separa implementação de validação física.

Não inferir comportamento a partir de `rulesText`, nome, OCR, arte ou presença do asset. Confirmar o caminho real entre comando, estado e cálculo.

## 2. Estado funcional

| Sistema | Estado no Godot |
| --- | --- |
| Nova partida, nomes, seed, posição e ordem sorteadas | Implementado |
| 12 cidades, 35 setores, rotas e restrição de piso | Implementado |
| Início/passagem, compra de geral, uma ação principal, viagem | Implementado |
| Exploração, depósito, retirada, carga, abastecimento e reparo simples | Implementado |
| Mão, consulta, descarte, compra e fila de revelação | Implementado |
| Arma fixa, G01–G07, hostis, combate, conquista, fuga e duas vidas | Implementado |
| Vitória por sobrevivência | Implementado |
| Equipamentos E01–E12 | Aquisição, instalação, remoção, passivos e ativações implementados; E11 requer sucata solta existente, cuja geração permanece indefinida |
| Melhorias territoriais T01–T06 | Implementadas, incluindo reserva, espaços e instalação remota |
| Gerais G08–G24, eventos e corridas | Implementados em novas partidas; V16 está temporariamente sem efeito por decisão do usuário |
| Upgrade/troca de veículo | Implementados; ofertas dependem da composição aprovada do baralho de veículos |
| Carga ↔ depósito local próprio e depósito → tanque | Implementados; depósito padrão de 10 recursos |
| Anúncio/vitória territorial, bônus local e placar | Implementados; anúncio no fim, confirmação antes da compra e cancelamento por perda de pontos/morte |
| Saque e bloqueios | Implementados, incluindo defesa pessoal na mesma ação; alerta registrado, restrições adicionais aguardam definição |
| Importação de saves React e paridade de seed com TypeScript | Não implementadas |
| Validação em Android físico | Prints do S23 revelaram falhas de layout; correção testada no Windows com métricas simuladas, aguardando confirmação no aparelho |

Todos começam de Hatch: vida 6, defesa 4+, consumo 1, carga 4, tanque máximo 8, combustível inicial 3, uma sucata e uma geral. Há compra no primeiro turno. A carta inicial de cada jogador permanece pendente de revelação até ele ser apresentado à sua mão/reação.

## 3. Arquitetura

Regras novas no nativo: PvP entrega carga/tanque e uma carta aleatória ao vencedor real; veículo de categoria diferente oferece recuperação por 2 sucatas, estrutura 4. Moto tem dano base 2 e equipamentos sem peso de carga. Hostis entregam a recompensa à carga; 12 perfis conferidos, relato de perda não reproduzido no motor atual. Exibição e histórico reforçados. React ainda segue as regras anteriores nesses pontos. Ver `docs/PVP_REWARDS_AND_MOTO.md`.

Mapa v3: terreno e margens sem rodovias pintadas; superfícies das estradas desenhadas pelas mesmas polilinhas da seleção/viagem. Adicionada a ligação rural Santa Cruz ↔ Rio Claro solicitada pelo usuário, totalizando 19 rotas, sem alterar conexões anteriores. Contratos JSON nativo/React atualizados. Ver `docs/MAP_ALIGNMENT_V3.md`.

Viagem na UI: seleção de estrada abre prévia com zoom via Tween, rota exata destacada e rodapé Cancelar/Confirmar. Destinos agrupam rotas alternativas. A prévia é transitória, restaura câmera no cancelamento e só envia `move` ao confirmar; não toca estado/RNG. Movimento reduzido aplica enquadramento imediato. Ver `docs/S23_LAYOUT_FIX.md` e testes móveis.

- `scripts/game_state.gd` / `WastelandGame`: criação, RNG LCG, comandos, cartas, inventário e persistência.
- `scripts/campaign_rules.gd`: capacidades, instâncias, equipamentos, gerais, progressão, territórios, elegibilidade e validação de save.
- `scripts/world_rules.gd`: eventos, escolhas persistidas, saque, veículos encontrados e corridas.
- `scripts/campaign_panel.gd`: administração, placar, instalação, eventos/corridas/saque e resolução privada de excedentes na folha compartilhada.
- `scripts/combat_rules.gd`: regras de combate, consulta de reações, resultados e migração aditiva de campos.
- `scripts/combat_view.gd` / `dice.gd`: adversários, estatísticas, dados, impacto/esquiva e recompensa. Não sorteiam resultados do jogo.
- `scripts/board.gd`: mapa, rotas, gestos, cidades/setores, seleção e deslocamento visual.
- `data/route-presentation.json`: polilinhas editoriais em porcentagem. Nunca alterar conectividade/custos com esse arquivo.
- `scripts/main.gd`: coordenação, navegação, vínculo com motor, adaptação ao dispositivo e dados dos painéis.
- `scenes/ui/`: HUD, topo, veículo, carga, mão, cidade, setor, consulta/revelação, entrega, notificações e resultado de exploração.
- `themes/wasteland_theme.tres` / `scripts/ui_style.gd`: tema e tokens. `tools/build_ui_theme.gd` regenera o recurso.
- `scripts/ui_preferences.gd`: preferências persistidas; `ui_audio.gd`: clique procedural em bus UI e vibração opcional Android.

O motor nativo modifica seu Dictionary. `act` restaura snapshot em recusa; `action_reason` simula isoladamente a mesma validação, sem escrita/RNG real. Uma ação aceita com falha de gravação permanece aceita e registra `persistence_error`: `retrySave` repete somente a escrita. Não repetir o comando original para tentar salvar.

LAN usa `scripts/network/`: `SessionAuthority` executa as capacidades geradas por `CommandCatalog`, serializa ações e salva estado/recibos no mesmo envelope. O motor usa `persistence_managed` somente nesse modo. `ViewProjector` publica campos permitidos; UI e mapa clientes não recebem o save completo. `NetworkEndpoint` é Autoload comum com RPCs compatíveis nos dois pacotes. Mão/recursos/decisões são individuais; RNG/baralhos/log interno ficam na autoridade. O fingerprint de regras/protocolo é inserido automaticamente por `addons/lan_export` na exportação. Recursos privados, ator por comando e demais contratos estão no relatório de protocolo. Não substituir jogador local por `game.player()`, que continua significando jogador ativo.

## 4. Combate e efeitos

- Arma fixa: dano 1, sem munição. Defesa e vida base vêm de `CombatRules.STATS`.
- Antes de cada ataque, jogadores operacionais com gerais compatíveis podem usar ou passar. A cota é uma geral por jogador por turno do mapa; não se renova por ataque/rodada.
- G01: +1 acerto; G02: −1 acerto; G03: +1 dano; G04: redução de dano 1; G07: +1 no ataque da ameaça.
- G05/G06: +1/−1 na fuga, na janela própria entre rodadas.
- E01–E03 oferecem ataque adicional opcional após o fixo, antes de continuar. Munição e limite compartilhado por carro/rodada são gastos antes do dado, inclusive em erro. E03 só atinge carro.
- E04 altera defesa; E05/E06 são ativações por instância/combate antes do dado; E12 descarta ao ativar; E09 soma fuga sem retirar custos. E07/E08 alteram capacidades sem gerar recursos. E10 é usado antes do avanço, uma vez por corrida.
- Fortificação aplica T01/T02/T03; T04 amplia depósito, T05 limita saque, T06 permite substituição e melhora reparo. Conquista descarta melhorias e preserva estoque, resolvendo excedentes.
- D6: 1 natural sempre erra, 6 natural sempre acerta; demais valores somam modificadores contra a defesa.
- H01–H12 leem atributos e poderes do JSON. H04 consome bônus no primeiro ataque tentado; H07 tem bônus contínuo; H08 modifica fuga; H11 soma dano no 6; H12 absorve no primeiro acerto recebido.
- Estados incluem defesa pessoal, cartas, pronto para dado, resultado, intervalo, fuga e término. O dado real e o dano são salvos antes da apresentação animada.
- Dono operacional presente pode defender com o carro. Após derrota/fuga desse carro, a mesma ação prossegue contra a fortificação.
- Conquista restaura resistência a 4 e preserva o depósito. Hostil fácil concede 2–3 itens, médio 3–4, difícil 4–5, sorteando sucata/combustível para a carga. Resolver excedentes.
- Destruição PvP concede carga/tanque e uma carta aleatória ao vencedor; oferece recuperar outra categoria por 2 sucatas. Após a entrega, aplica descarte restante e vidas: renasce Hatch com 3 combustíveis e perde o próximo turno; segunda destruição elimina. Último sobrevivente vence.
- Fuga paga combustível e usa piso compatível; PvP exige carta de tributo aleatória. Carta transferida usa a fila de revelação do novo dono.
- Aquisição ainda oculta de quem reage fora do turno deve ser revelada antes de permitir seu uso.

Reações seguem a ordem circular a partir do jogador ativo; G07 exige hostil real. Excedentes de mão por tipo, carga/tanque e depósito bloqueiam progresso normal e têm comandos de resolução, inclusive ganho fora do turno. O relatório [CAMPAIGN_IMPLEMENTATION.md](docs/CAMPAIGN_IMPLEMENTATION.md) registra testes e limites; código funcional não equivale a validação Android ou de balanceamento.

## 5. Exploração — correção recente

- Setor próprio na cidade atual; uma ação; até três explorações por setor.
- Sorteia 2–3 recursos e os coloca no **depósito**, não na carga.
- `dispatch("explore")` captura o estoque anterior e calcula somente o delta após sucesso.
- `scripts/exploration_result.gd` / `scenes/ui/exploration_result.tscn` mostram janela central com ícones e quantidades.
- A apresentação é deferida para ficar à frente da folha de setores que o callback reconstrói.
- Continuar/Voltar fecham sem alterar recursos. Ver depósito abre os setores para retirada.
- Não incluir estoque antigo no resultado, sortear novamente, conceder itens ao abrir/fechar popup ou repetir resultado em tentativa inválida.
- O resultado visual da exploração é transitório. O estoque real é persistido; não há fila persistida de popups de exploração.

## 6. Cartas e assets

- `gain_card` centraliza aquisições e cria tickets em `pending_reveals`.
- `take_hand_card` mantém os índices da fila ao remover/transferir carta.
- `card_reveal.gd` resolve versos, aguarda toque, vira e confirma recolhimento. Movimento reduzido preserva escolhas sem a animação.
- Versos: G geral, V evento, R corrida, E e T exatamente o mesmo arquivo de equipamento/melhoria. Não expor nome/efeito/frente por tooltip ou acessibilidade antes da virada.
- Runtime: `assets/cards`, `assets/hostiles`, `assets/vehicles`, `assets/ui`; fontes de origem também existem na raiz do repositório.
- Veículos laterais: `vehicle_art.gd`. Pickup usa `picape-lateral.png`; animação usa pasta `caminhonete`.
- Movimento: folha 6 × 4, 24 quadros, 20 fps, 1,2 segundo. Usar tamanho efetivo da textura importada para as regiões; não assumir células originais após redução. Espelhar o objeto inteiro ao andar à direita.
- Mapa e peças top-down permanecem separados da arte lateral do resumo/combate.
- Fontes Barlow/Barlow Condensed têm SIL OFL incluída no runtime/exportação. Ícones de navegação são SVG; ícones de recursos vêm do projeto.

## 7. Contratos da UI Android

- HUD em CanvasLayer próprio; overlays em camada superior, com prioridade de modal e foco.
- Topo compacto, Menu, resumo do veículo, gaveta de carga, mão central parcialmente escondida sem faixa preta.
- Dica contextual e ação relevante em laranja; não manter faixas permanentes de log.
- Mapa livre e Localizar disponíveis. Toque seleciona, confirmação viaja, arrasto/pinça não podem disparar ações.
- Setores identificados por número, nome do dono e cor; não depender só de cor.
- Passagem/retomada usam tela opaca e ocultam HUD/mão até confirmar o jogador.
- Cartas ampliadas têm leitura textual e descarte confirmado quando não for resolução de excesso.
- Preferências: texto, movimento reduzido, volume, orientação e vibração opcional Android, desligada por padrão.
- A compra/revelação não contém seletor de movimento reduzido. `card_reveal.reduced_motion` é um bool aplicado pelas Configurações, preservando a preferência salva.
- Nova partida pela preparação abre `scenes/ui/intro_guide.tscn`: caixa central breve com turno/objetivos e botão **Vamos jogar**, seguida da identificação do primeiro jogador. Não aparece em refresh/retomada nem revela cartas antes da identificação. `tests/onboarding_ui_smoke.gd` cobre fluxo, foco visual, limites e preservação do estado; capturas em `.tools/intro-guide.png` e `.tools/card-without-motion-option.png`.
- A abertura sempre passa por `scenes/ui/start_screen.tscn`, com nome/arte e menu Continuar, Nova partida, Configurações, Como jogar e Sair. Save não é retomado automaticamente; Continuar abre identificação privada. Nova partida preserva confirmação/backup, preparação e guia. Cancelar preparação retorna à tela inicial; o menu de pausa oferece retorno à apresentação. `tests/start_screen_ui_smoke.gd` cobre início, configurações/ajuda sem partida, cancelamento, save e privacidade; validado em Windows 1280×720 e 960×720, captura em `.tools/start-screen.png`.
- DPI/área segura e teclado virtual possuem tratamento no código; precisam de calibração em aparelho.
- Mão/inventário não devem reconstruir a árvore em refresh sem mudança relevante.

## 8. Saves e exportação

- Save: `user://campaign-native-v1.json`, schema `native-stage1`, versão 1.
- Novas partidas têm `rules_profile=campaign-v06`, regras 0.6/conteúdo 0.6.0, seed inicial, nomes e registro de comandos. Saves antigos recebem campos estruturais sem consumir RNG e mantêm perfil anterior, sem criar baralhos/recompensas ou ligar eventos silenciosamente. Iniciar nova partida para o conjunto completo.
- As 148 cópias recebem identidade no registro desde o setup; compra, descarte, reciclagem, instalação e tributo preservam identidade. A mão tem uma lista paralela de instâncias e as revelações mantêm tickets/índices. Eventos e surpresas não vão à mão. IDs numéricos usados como chaves são normalizados após JSON.
- Há campos aditivos para revelações, combate, mortes, recuperação e resultado. Saves nativos antigos recebem defaults compatíveis.
- Atribuição de hostis na migração é determinística sem consumir RNG. Não reinstanciar hostis/rolar novamente ao retomar.
- Preferências: `user://ui-preferences.cfg`.
- Nova partida preserva cópia em `user://campaign-before-new-game.json`.
- IndexedDB/JSON React não são importados. Não confundir versão nativa com conteúdo/envelope React.
- Preset Android ARM64 com INTERNET para LAN e vibração opcional; modo hot-seat continua sem depender de rede. Preset Android TV usa Gradle, feature `tv_board`, ARM64/ARMv7 e pacote separado.
- Dados JSON e licenças de fontes precisam entrar no pacote. `docs/`, `tools/` e `tests/` são excluídos.
- APKs de debug LAN/Tabuleiro gerados com min SDK 24/alvo 36. Manifest TV inspecionado com launcher leanback, banner e touchscreen opcional. PCK continua não sendo APK. Não há homologação física ou publicação.
- Save LAN: `user://campaign-lan-v1.json` com backup `.bak`, credenciais locais separadas em `lan-connections.cfg`. Não converte o save hot-seat nem o React. Falha de escrita bloqueia novas mutações LAN até repetir a gravação; retomada usa último estado realmente salvo. TV não é anfitrião nem participante de confirmação de animações.

## 9. Verificação

No PowerShell, usar Godot no PATH ou o executável local de `../.tools/godot/`. Isolar APPDATA/LOCALAPPDATA no workspace antes dos testes, conforme README, para não sobrescrever saves reais.

```powershell
godot --headless --path godot --editor --import --quit
godot --headless --path godot --script res://tests/smoke.gd
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --path godot --script res://tests/ui_smoke.gd
godot --path godot --script res://tests/reveal_smoke.gd
godot --path godot --script res://tests/combat_ui_smoke.gd
godot --path godot --script res://tests/modern_ui_smoke.gd
godot --path godot --script res://tests/exploration_ui_smoke.gd
```

Executar na raiz do repositório; se estiver dentro de `godot/`, usar `--path .`. Testes visuais usam renderer real; headless não substitui inspeção de imagem.

Evidências recentes: testes de regras/combate/UI/revelação passaram; modernização validada em janelas 1280×720, 1560×720 e 960×720; exploração validada com ícones, delta, foco, depósito e repetição inválida. Os testes não provam equipamentos ainda ausentes.

## 10. Próximas pendências e limites de evidência

1. V16 foi deixado sem uso por decisão do usuário: permanece no catálogo/baralho, mas resolve sem efeito, inclusive com `vehicle_pool` configurado ou carta pendente em save. Não reativar sem nova instrução. A fonte de sucata solta para E11 continua indefinida.
2. Fechar semântica adicional do alerta de saque, perfis regionais/dificuldade e impasses ainda abertos nas regras.
3. Ampliar cenários de regressão/playtests do conjunto integrado; três contratos TS/Godot comparados não representam paridade integral de seed/implementação.
4. Homologar os APKs LAN e Tabuleiro já gerados; preparar distribuição de release apenas depois. SDK/JDK/templates foram configurados em perfil de build isolado; a TV exige Gradle e JDK compatível. Não reutilizar a falha antiga de exportação como estado atual.
5. Testar Android físico e medir desempenho/balanceamento com pessoas. Medidas Windows não comprovam FPS/RAM no Android.

Verificação única: `powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1`, na raiz. Perfis e logs separados por suíte em `.tools/campaign-checks/`. Inclui validação de dados/assets, campanha, casos de borda, contratos compartilhados e testes renderizados. `-HeadlessOnly` executa só regras/dados. Replay: `tools/replay_campaign.gd`; comparação: `node godot/tools/compare_contracts.mjs` após suíte nativa e Vitest.

Manter este contexto coerente ao concluir novas etapas. Não apagar limites ou marcar validação externa como concluída apenas porque a implementação existe.

## Transferências e descarte — revisão de 30/10/2026

Reações de combate/fuga: `combat_view.build_reactions` exibe `ReactionCards` no `CombatCardPicker` (z=90), sobreposição central de tela inteira fora do ScrollContainer do combate. Cabe uma página de artes por vez, sem rolagem vertical; **Anterior/Próxima** navegam pelo excedente. **Minimizar**/Android Back oculta sem responder; **Ver cartas** reabre. Nova janela de reação restaura a seleção. Toque abre `CombatCardPreview` (z=100), com arte ampliada, **Usar carta** e **Voltar**. Só confirmar emite `combatCard`; valida novamente dono, índice, identidade e elegibilidade. Voltar não consome; foco fica no modal ativo e `sync` fecha previews antigos. Preserva privacidade e revelações. `combat_ui_smoke` cobre limites da tela, paginação, minimização, reabertura, textura, expansão sem consumo, cancelamento e confirmação pelo adversário; validado em janelas 1280×720 e 960×720, sem substituir Android físico.

- `transfer_resource` centraliza depósito local próprio ↔ carga, abastecimento da carga, depósito → tanque e combustível excedente → tanque. Depósito padrão tem limite 10; tanque e carga usam capacidade do modelo. Quantidades conservadas, sem RNG nem custo de ação.
- `refuelDepot` transfere o máximo que couber diretamente ao tanque, inclusive com carga cheia. `refuelExcess` usa o menor entre excedente, combustível na carga e espaço no tanque; funciona no resultado final de combate, nunca durante ataques. Não descarta automaticamente o restante.
- A UI identifica origem/destino, estoque/carga/tanque e ícones. Carga exibe números inteiros mesmo após JSON. Descarte de recurso permite escolher um recurso existente com ícone/quantidade; elimina uma unidade por toque. Resultado de combate também oferece ícones e aproveitamento do combustível excedente.
- Seleção de cartas e confirmação de descarte exibem as artes. Revelações pendentes continuam obrigatórias antes de abrir a seleção; remoções usam `take_hand_card`.
- `tests/transfers_smoke.gd` cobre conservação, acesso, capacidade, excedentes em combate, persistência e escolhas visuais. Validação Windows; Android físico ainda pendente.
- Disponibilidade: `transfer_reason` e `inventory_reason` são consultas sem efeitos, usadas pelo motor e pela UI. Abastecimento/excedente, depósitos, reparo e descarte ficam desativados quando inválidos, com motivo no tooltip. `refresh` atualiza os controles da carga após alterações. Teste cobre falta de excedente/combustível, tanque cheio, turno não iniciado, recuperação, revelação e combate ativo.

Indicador de turno: HUD compartilhado local/LAN com Preparação → Ação → Encerramento, centralizado no topo; destaque atual âmbar e concluídas verdes. Apenas apresentação do estado existente; validado em layout Windows, Android físico pendente.

Android TV: foco inicial em Buscar novamente, navegação vertical circular na conexão, seleção preservada na descoberta, contorno âmbar e Voltar contextual. tv_remote_smoke.gd validou eventos de setas/Enter no Windows; controle físico pendente.
