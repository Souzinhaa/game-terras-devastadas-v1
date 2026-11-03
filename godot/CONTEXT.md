# Terras Devastadas — contexto atual Godot / Android

Atualizado em 31/10/2026. Desenvolvimento ativo: **feature/release-0.0.4**, Godot **4.7 Standard**, verificado com **4.7.2**, GDScript e Compatibility. Alvo Android em paisagem; hot-seat e LAN de 2–4 jogadores, Tabuleiro/TV público opcional.

## 1. Fontes de verdade e versões

Preferência explícita do usuário (02/11/2026): features e correções sem indicação de modo devem ser aplicadas e verificadas no normal/local (hot-seat) e no Multiplayer LAN. A entrega precisa contemplar os dois fluxos, incluindo TV/Tabuleiro quando afetar apresentação pública, sem expor dados privados ou permitir comandos de outro jogador. Somente pedidos específicos de um modo podem ficar restritos a ele. A referência React histórica não entra nessa obrigação.

- [Regras atuais](../rules.md), [catálogo](../rules-cards.md), [Como jogar](../docs/COMO_JOGAR.md).
- [REBALANCEAMENTO_V07.md](docs/REBALANCEAMENTO_V07.md): diferenças e hipóteses de design.
- [README.md](README.md): execução, testes, APK e limites.
- Código em `scripts/`, dados em `data/` e cenários em `tests/` confirmam a implementação.

Novas partidas: `campaign-v07`, regras `0.7`, conteúdo `0.7.0`. Build Android: `0.0.4-local-tv`, código 11. Não confundir build com edição de regras. Saves `campaign-v06` mantêm valores/baralhos anteriores; `stage1` mantém conjunto legado limitado. Consultas, carregamento e apresentação não convertem perfil nem consomem RNG.

React/TypeScript é referência histórica separada. Não tem paridade integral de seed, recompensas ou persistência, e não recebeu as mudanças nativas 0.7. Não aplicar automaticamente contratos React à LAN. [Contexto React preservado](../docs/historico/CONTEXTO_REACT_V06.md).

## 2. Regras vigentes no nativo

Todos começam de Hatch: integridade 6, Defesa 4+, agilidade +1, consumo 1, carga 5, tanque 8 com três combustíveis, uma sucata, duas gerais já distribuídas sem animação, um setor próprio e duas vidas. Compra também no primeiro turno. Mapa: 12 cidades, 35 setores e 19 rotas.

- Uma viagem legal antes da ação e uma ação principal. Eventos podem consumir a ação. G17 permite sua exceção explícita de viagem após bloquear.
- Exploração: até três usos por setor; 2–3 itens no depósito, com uma unidade escolhida de sucata/combustível incluída no total. O popup mostra somente o delta real.
- Água/pneu/bateria da carga → uma sucata, livre uma vez por turno próprio iniciado, fora de encontros.
- Melhorar Hatch: cinco sucatas próprias locais e uma ação; preserva integridade/combustível/vidas, inclusive Moto. Compra de melhoria: três sucatas da carga, uma por turno, sem ação.
- Moto: dano fixo 2, equipamentos sem peso; SUV/Caminhonete: Defesa 4+. Capacidades/consumos vêm do JSON, defesa efetiva de `campaign.vehicle_defense`.
- Primeira destruição: Hatch íntegro, três combustíveis, perdas normais e proteção até iniciar a próxima vez própria; não perde essa vez. Segunda elimina.
- Vitória: último sobrevivente imediato ou três pontos anunciados ao fim e sustentados até próximo início antes da compra. Indisponibilidade/perda de pontos cancela anúncio.
- Saque simples: uma ação/um combustível, D6 × D6, empate da defesa; até dois recursos ou um com T05, falha causa dois danos. Dono local apto pode escolher combate pessoal na mesma ação.
- Corrida: inscrição voluntária inclusive para revelador, um combustível, mínimo dois; devolve inscrição se não iniciar. Pistas, marcos, prêmios e rodada final permanecem.
- Ameaças novas: faixas fácil/média/difícil por cidade/setor, identidade derivada da seed sem rerrolagem. Faixa pública; nome/atributos ocultos até revelar.
- E11/V16 ficam fora dos novos baralhos. 74 definições e 148 identidades no registro; 72 definições/144 cópias disponíveis no setup, quatro identidades `unavailable`. Saves antigos preservam suas cartas.

Não há consumo automático de água/pneu/bateria, doação direta de recursos, renda de cidade ou regra nova implícita do alerta de saque.

## 3. Estado funcional e limites

Implementados: campanha, gerais de suporte/reação, equipamentos/territoriais, upgrades/reparos, depósitos/transferências, eventos/escolhas, corridas, saque, combate/fortificação, fuga, duas vidas, anúncios, save/replay, LAN autoritativa, capacidades por jogador, projeções e recibos/reconexão.

E11 depende de fonte indefinida de sucata solta. V16 foi desativado por instrução do usuário; não reativar mesmo em save com `vehicle_pool`. Ofertas já existentes seguem suas próprias regras. Condições mecânicas sem contrato, impasse especial sem dano e restrições adicionais de alerta permanecem pendentes.

Equipamento/catalogação não prova efeito funcional. Relatórios de auditoria/migração anteriores estão identificados como históricos, não como lista atual de sistemas ausentes.

## 4. Arquitetura e comandos

| Arquivo/camada | Responsabilidade |
| --- | --- |
| `game_state.gd` / WastelandGame | Nova partida, RNG LCG, comandos, inventário, cartas e persistência |
| `campaign_rules.gd` | Perfis, atributos/capacidades, instâncias, gerais, equipamentos, territórios e vitória |
| `world_rules.gd` | Eventos, escolhas, corridas, saque e ofertas |
| `combat_rules.gd` | Estados, reações, dados, dano, fuga, recompensas e vidas |
| `main.gd`, `campaign_panel.gd`, `combat_view.gd` | Coordenação/apresentação hot-seat; não sorteiam ou concedem recursos |
| `board.gd`, `route-presentation.json` | Mapa, gestos e polilinhas visuais; não redefinem conectividade/custos |
| `network/session_authority.gd` | Execução serial, permissões, save e recibos LAN |
| `network/command_catalog.gd`, `view_projector.gd` | Opções vinculadas ao ator e dados públicos/privados |
| `network/player_hud.gd`, `lan_screen.gd` | UI cliente a partir da projeção |
| `how_to_play.gd` | Texto de ajuda compartilhado, derivado de edição/modo, sem mutações |
| `ui_feedback.gd`, `board_feedback.gd` | Retorno de toque/foco e destaques de fatos públicos, sem modificar layout ou RNG |
| `network/tv_dashboard.gd` | Etapas do turno, placar minimizado permanente, encontros públicos e preferência de movimento reduzido na TV |

`act` restaura snapshot em recusa. `action_reason` simula a mesma validação isoladamente, sem escrita/RNG real. UI consulta elegibilidade e emite comandos; animação não determina resultado.

Na LAN, `game.player()` é o jogador ativo, não o assento do aparelho. `CommandCatalog` vincula args/capacidade ao ator; `ViewProjector` não fornece save completo ao cliente. Baralhos, RNG, mãos e depósitos alheios não podem vazar. Tabuleiro não hospeda nem confirma animações.

## 5. Combate e integridade da aquisição

Reações seguem a ordem circular a partir do ativo. Na 0.7, uma geral por jogador por rodada de combate, compartilhada entre ataques/adicionais/fuga; `round_generals` persiste a cota e renova após ambos os ataques principais. Fora de combate permanece uma por turno do mapa, em cota independente; corrida não renova a cota do mapa. Saves 0.6 preservam a regra anterior. Combate antigo sem o campo conserva como gastas as cotas indicadas por `used_general`, sem RNG ou cartas extras. G07 exige hostil real. Arma fixa sem munição; E01/E02/E03 compartilham um adicional por carro/rodada, pago antes do dado inclusive em erro. E03 só atinge carro. E04 passivo; E05/E06 por instância/combate; E12 descarta; E09 soma fuga; E10 uma vez por corrida. T01–T06 afetam fortificação/depósito/administração.

D6 natural um erra, seis acerta. Atributos H01–H12 e poderes vêm do JSON. Recompensa de hostil vai à carga, 2–3/3–4/4–5 sucata/combustível por faixa; não abastece. Conquista restaura resistência quatro, descarta melhorias antigas e conserva depósito.

Defesa pessoal de conquista enfrenta primeiro carro, depois fortificação se necessário, na mesma ação. Saque pessoal enfrenta somente carros. PvP entrega carga/tanque e uma carta aleatória ao vencedor real; captura de categoria diferente por duas sucatas/estrutura quatro é opcional, distinta do upgrade por cinco.

`combatFast` executa até 24 transições e para antes de escolhas, equipamento, munição opcional, fuga ou término. Não confirma/desfaz carta, recompensa, veículo ou descarte. `combatAutoPass` é preferência individual por combate, reversível antes do dado; não consome carta/cota. Preferência e `responses` normalizam IDs ao restaurar JSON. Recibos impedem repetir RNG no reenvio.

Toda aquisição de mão usa `gain_card`; toda remoção usa `take_hand_card`. Instâncias, zonas, tickets e índices de revelação permanecem coerentes na compra, tributo, descarte e instalação. Compra fora do turno pertence ao destinatário, identificado antes de revelar.

## 6. UI Android e assets

Correção de interação (03/11/2026): `card_zoom.present` coloca a ampliação no fim da árvore de controles, além do `z_index`, para que receba os toques antes do leitor subjacente. Regressões local/LAN usam eventos pelo viewport real para abrir, voltar, recolher e acessar ações após ciclos de leitura. Validação Windows; Android físico ainda pendente.

Combate simplificado: comandos abaixo dos combatentes, dado central entre os painéis, extras recolhidos e fuga agrupada em um botão. `escape_map_picker.gd` usa o tabuleiro existente e `board.escape_routes` com pulso só nas rotas legais; seleção apenas solicita `combatEscape`, sem antecipar dado/custo. Local permite escolher o combatente se ambos puderem fugir; LAN só usa capacidades próprias. Cancelamento/pausa restauram câmera e mapa sem comandos. `GameSFX` sintetiza conserto/batida/ataque/esquiva/virada sem RNG de partida, com volume dos efeitos e suspensão na pausa. `SessionAuthority.event_for` deriva sons de resultados aceitos, `NetworkEndpoint` filtra apenas a lista pública e deduplica eventos; compra/encontro toca virada só no próprio clique válido. `combat_escape_sfx_smoke` verifica regras e efeitos com driver Dummy, sem validação auditiva em Android físico.

Leitura e atenção: novas partidas registram os IDs das cartas distribuídas em `initial_card_instances`; somente a projeção privada informa `initial_deal` de cada carta própria. `hand_dock.gd` pulsa o contorno preto até abrir cada instância e persiste leitura em `ui-card-reading.cfg` neste aparelho, sem alterar RNG/comandos. `card_zoom.gd` amplia artes conhecidas do leitor, compra, encontro e reação; nunca revela versos ocultos. Leitor local tem painel limitado e centralizado na área segura. Menu é o último item à direita, depois do turno; volume musical aparece primeiro nas configurações com porcentagem. `card_reading_ui_smoke` cobre persistência, alinhamento e leitura sem mutações.

`Music` é um único autoload com **Aftermath** (Kevin MacLeod, CC BY 4.0), MP3 original em `assets/audio/music/aftermath.mp3`, loop e volume padrão 0,18. `audio/music_volume` é independente dos efeitos e preservado entre telas; zero desliga e pausa suspende reprodução. Local/TV reproduzem; celular LAN não duplica a TV. `music_settings.gd` oferece volume/créditos nas configurações locais e na folha pública de música da TV/LAN. CREDITS/LICENSE são incluídos nos dois APKs. `music_smoke` valida reprodução, modos, volume, pausa e créditos em perfil isolado com driver Dummy; isso não é teste auditivo em aparelho.

Viagem aceita é coordenada por `travel_presentation.gd`, sem desenhar cena separada: o veículo top-down do mapa segue a polilinha da estrada da cidade de origem ao destino, orientado pelo trajeto e vinculado ao ID do viajante. Motor em `vehicle_engine_audio.gd`; prévia/cancelamento não disparam apresentação, e pular/concluir só encerra o efeito. Os endpoints das cidades e a posição intermediária são verificados por teste. `vehicle_art.gd` alterna recortes `AtlasTexture` diretamente a 20 fps, evitando o uso incompatível de atlas dentro de `AnimatedTexture`. `encounter_reveal.gd` deriva da apresentação de compra: o flip usa o comando existente de revelar, depois abre a decisão sem adicionar evento à mão. Local preserva identificação e LAN espera a frente autorizada, sem alterar projeções privadas/públicas. Pausa, som zero e movimento reduzido cobertos por `travel_encounter_ui_smoke`; capturas em `.tools/travel-vehicle-engine.png` e `.tools/encounter-card-reveal.png`, evidência Windows.

Topo em linha única com nome/cor, etapas centrais e turno à direita; `hud_presentation.gd` compartilha apresentação entre local/LAN. Preparação usa **Comprar Carta** vermelho na área das ações. Carga mantém ícone/nome/quantidade e quatro comandos curtos; excedente só aparece quando legal. `hud_preparation_smoke` cobre alinhamento e carga com texto padrão/ampliado. Setup novo `campaign-v07` registra `initial_hand_size=2` e não gera tickets para a distribuição; compra e ganhos posteriores continuam passando por `gain_card` com revelação. Carregamento e setup `campaign-v06` preservados.

Correções de interação: `ui_scroll_input.gd` permite propagar o arrasto dos controles de conteúdo até o `ScrollContainer`, que mantém o bloqueio do mapa. Campos de edição e widgets com gesto próprio são preservados. `scroll_touch_smoke` verifica seleção simples, arrasto sobre botão dentro de painel e ausência de clique durante rolagem. Combate local separa `combatReaction` de `combatReveal`, valida a identidade da janela e explicita o jogador ativo; a regressão verifica que a reação fora do turno não compra cartas, não altera RNG e não muda a vez. Recompensas têm ícones/quantidades/nomes, com relato em **Ver detalhes** e decisões pendentes preservadas. Validado por testes e renderização Windows, sem evidência em aparelho físico.

Canvas-base 1440×810, `canvas_items`/`expand`. HUD em camada própria; modal acima; área segura aplicada às folhas, leitura e botões. Cenas e tema compartilhados em `scenes/ui/`, `themes/wasteland_theme.tres`, `ui_style.gd`. Não restaurar a barra lateral do protótipo LAN.

Topo compacto, menu, veículo lateral com gaveta de carga, mão central recolhida sem faixa preta, destaque contextual âmbar. Arrasto/pinça não disparam viagem; prévia confirma o comando e cancelar restaura câmera sem custo/RNG. Mapa/rodovias usam polilinhas coerentes com seleção. Perfis de DPI não devem inflar texto.

Reações locais usam seleção privada paginada fora da rolagem do combate. Minimizar/Voltar não passa nem usa carta; Ver cartas reabre. Toque amplia, Usar carta confirma. Leitor LAN usa área de arte e texto rolável, com ações acessíveis. Ações LAN mantêm paginação e rolagem de reserva.

Botões têm retorno de toque/foco sem mudar tamanho/posição. O instalador de feedback exclui a árvore `card_reveal.gd`: a animação de compra permanece. Mudanças públicas de estrutura, veículo, conquista e turno destacam cidades; não há efeitos históricos ao entrar/reconectar nem repetição de snapshot. TV usa mapa integral, as mesmas etapas Preparação/Ação/Encerramento e quatro cartões compactos de pontos/vidas; selecionar cartão abre só dados públicos. Encontros têm barras interpoladas até o valor real. Nada disso bloqueia o motor ou pede ACK. Ver [UI_INTERACTION_TV.md](docs/UI_INTERACTION_TV.md).

Pausa restaura animação interrompida e oculta informação privada; revelação ainda pendente reaparece ao desbloquear. Tela inicial não retoma save sem identificação. Guia breve de nova partida precede a primeira entrega. Ajuda local e LAN usa o perfil real; na LAN explica aparelhos individuais.

Artes nativas em `assets/`; originais preservados. Pickup usa `picape-lateral.png`, animação em pasta `caminhonete`. Movimento lateral: 24 quadros, folha 6×4, 20 fps; considerar dimensões importadas ao recortar. Mapa/top-down é separado do veículo lateral. Versos G/V/R e E/T compartilhado não revelam nome/efeito antes da virada. Fontes Barlow/Barlow Condensed incluem SIL OFL. Não editar cache `.godot/`.

## 7. Persistência

Hot-seat: `user://campaign-native-v1.json`, schema `native-stage1`, versão 1. Nova partida preserva backup `campaign-before-new-game.json`. Preferências: `ui-preferences.cfg`.

LAN: `user://campaign-lan-v1.json` com `.bak`, credenciais em `lan-connections.cfg`. Envelope salva estado/recibos juntos. `persistence_managed` delega escrita ao serviço somente nesse modo. Falha de escrita impede novas mutações LAN até repetir a gravação; retomada usa o último estado salvo. No hot-seat, erro após ação aceita não a desfaz: repetir somente escrita com `retrySave`, sem repetir comando.

Preservar perfil, seed inicial/corrente, registro de comandos, instâncias, escolhas, recursos, revelações e combate. Defaults estruturais não embaralham baralhos nem inventam recompensas. Replays usam o perfil salvo; conversão React não existe.

## 8. APK, testes e evidências

Preset Android: `com.bhsp.terrasdevastadas`; CI de teste substitui para `com.bhsp.terrasdevastadas.preview.v07`, nome **Terras Devastadas Teste 0.7**, versão `0.0.4-ui-tv`. Instala separado do anterior. O template verificado é mínimo API 24/alvo 36, ARM64 e INTERNET. Preset TV é separado, Gradle/feature `tv_board`, ARM64/ARMv7. Não declarar TV física homologada.

CI `.github/workflows/android-debug.yml` importa, testa, exporta e verifica assinatura/pacote/permissões. Usa templates da mesma versão, JDK 17 e assinatura debug temporária por execução. Não usar esse processo para substituir chave de distribuição.

Runner: `powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1`, na raiz; `-Godot`, `-HeadlessOnly` e `-OnlySuites` disponíveis. Perfis temporários curtos e isolados por suíte evitam sobrescrever save real e a falha de cache OpenGL em caminhos longos Windows. Logs em `.tools/campaign-checks/`.

`balance_smoke`: 180 verificações da edição 0.7/compatibilidade. Regressões 0.6 usam perfil explícito. CI [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924): 180 regras + 63 sessão LAN + 201 campanha LAN, APK exportado e assinatura v2/v3 verificada. Layout LAN renderizado em Windows: 892×445, 1280×720 e 2340×1080 com recorte simulado. Novas alterações precisam de validação própria.

Não apresentar simulação desktop como Android físico. Permanecem pendentes LAN/toque/teclado/pausa/recortes em aparelhos, TV, desempenho em hardware de entrada e playtests com duração, decisões e balanceamento medidos.

## 9. Continuidade

Viagem, combate e carga (02/11/2026): `escape_map_picker.gd.present` aceita finalidade `travel`/`escape`. Local e LAN destacam somente viagens legais/capacidades próprias; selecionar mantém a prévia de confirmação, e cancelar restaura câmera sem comando. Carros no mapa emitem `vehicle_selected`; retratos também abrem `vehicle_details.gd` em tela cheia. `vehicle_info` na projeção pública contém máximos/atributos/equipamentos públicos; carga e tanque atuais vêm exclusivamente da projeção própria. Pausa/desconexão ocultam os detalhes.

Hatch moderno lê `capacityV07=5` em `data/vehicles.json`; o campo base 4 preserva 0.6/stage1. E08 continua somando dois. Regras/guia/ajuda acompanham o ajuste. O botão de turno distingue carga cheia de excesso: somente `cargo > capacity` leva a **Liberar carga**, com guardar/abastecer/descartar legais e sem consumo da ação. `end_reason`/`hand_excess` são metadados privados do próprio assento LAN. Não há descarte ou encerramento automáticos.

Combate mantém as mesmas etapas, cotas e donos dos comandos. `combat_view.gd` compartilha nomes/cor de atacante/defensor/dado no Local/LAN/TV. Próximo dado mostra **?** em vez do resultado anterior. Cartas rápidas na arena local validam dono, janela e identidade antes de emitir `combatCard`; leitura/picker são opcionais após identificação. Na LAN, capacidades próprias de carta incluem `card_id` e uso direto, sem confirmação intermediária; outros assentos e TV não recebem essas cartas. Animações de resultado passaram a 0,55 s + 0,12 s + 0,3 s, com som de dado correspondente; movimento reduzido continua imediato. Isso substitui os tempos de 01/11 registrados abaixo.

Encontros e cidade (02/11/2026): sair da carta virada por **Continuar**/Voltar resolve automaticamente apenas quando `action_reason("cardChoice", {})` aceita a intenção; decisões obrigatórias continuam explícitas. LAN recebe `automatic` somente na capacidade própria legal de resolução, mais `resource`/`supply` para rótulos de apresentação, sem argumentos confiados ao cliente. `encounter_effects.gd` anima deltas aceitos de estrutura, tanque/carga própria, ação e avanço na pista. A transição pública para corrida mostra `assets/ui/corrida_surpresa.png`, cópia intacta de `../assets/corrida_surpresa.png`, também na TV. Contexto/revisão evitam repetir efeitos em snapshots duplicados/reconexão; pausa oculta os efeitos, movimento reduzido mantém o aviso estático. `city_actions.gd` organiza o Local em função → setor → escolha; a LAN segue a mesma separação usando apenas capacidades/projeção próprias. Exploração e transferências continuam no motor, sem novas regras ou RNG visual.

UI de 02/11/2026: `turn_steps.gd` alinha as etapas à altura efetiva de `TopBar` por sinal de redimensionamento; a cena compartilhada centraliza ícones dos botões de mapa/localização/menu. `ui_sheet.gd.reset` aceita um callback opcional de retorno, mostra **‹ Voltar**, reinicia a rolagem e mantém **Fechar** independente. Local/Android e LAN usam esse retorno. Administração local separa veículo, recursos, equipamentos e defesas/veículos encontrados; modelos ficam em submenu e comandos aceitos reabrem a seção atual. LAN separa recursos, reparos e melhorias usando exclusivamente opções da projeção privada autorizada. Não mudou regras, RNG, saves ou projeção da TV.

Não acrescentar backend, bots, regras ou fontes de recurso para preencher pendências sem pedido. Não reativar V16 automaticamente. Atualizar regras, guia, ajuda compartilhada, contextos e testes quando mudar contrato. Preservar contexto histórico em documentos identificados; orientações atuais estão aqui, no README e nos contratos 0.7.

Correções de 01/11/2026: fechamento do leitor de cartas libera a mão imediatamente e restaura opacidade; combate local mantém dado central e comandos abaixo dos combatentes. Rolagem com som de dados dura 1,6 s, seguida de pausa de 0,45 s e perda de vida interpolada em 1 s; movimento reduzido mantém resultado imediato. Regressões: combat_smoke, combat_ui_smoke, card_reading_ui_smoke, combat_escape_sfx_smoke, lan_ui_smoke e tv_dashboard_smoke passaram no Windows. Captura: .tools/combat-rolling-fixed.png. Android/TV físicos ainda não validados.

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
APKs da feature local/TV gerados em 02/11/2026: `0.0.4-local-tv`, código 11, assinatura debug igual à dos APKs anteriores. Manifestos, conteúdo, ABIs e fingerprint atual `a73ff5640335373027e9ef872eb81ac3086231d9719b1f2d7ab1c7fc1d81cc59` verificados nos dois pacotes. Entregas atualizadas na raiz: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk`. Checksums em `godot/builds/SHA256SUMS.txt`; manifesto em `godot/builds/local-tv-build-manifest.json`. A suíte específica passou em 40 verificações; regressões LAN/sessão/combate/TV e ambos os cenários ENet também passaram. Teste em aparelhos Android/TV físicos ainda pendente.
