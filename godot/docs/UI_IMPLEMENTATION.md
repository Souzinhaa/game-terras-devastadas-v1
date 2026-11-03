# Modernização da UI — implementação e validação

Veículos por dono (03/11/2026): mapa, retrato, tela de detalhes, arena e corrida em local/LAN/TV usam as quatro pinturas. Ordem por ID estável: laranja, azul, preto (antes roxo), branco (antes verde). Paleta compartilhada e contorno claro para o jogador preto. Cópias de moto/caminhonete corrigidas visualmente; originais preservados. [Procedência, verificação e limites](vehicle-colors/README.md). Nenhuma mudança em regras, RNG, saves ou protocolo. Sem APK novo ou teste físico.

Ajustes de 03/11/2026: **Viajar** passa a integrar os atalhos compartilhados local/LAN. Usa o seletor de rotas legais já existente; cancelar restaura o HUD LAN. A faixa cresce para dentro da tela ao ampliar texto. Toque de mouse/touch recebido pelo mapa recolhe a CARGA; interação dentro da gaveta permanece disponível.

`card_activation.gd` apresenta cartas usadas/instaladas e equipamentos ativados no centro, durante quatro segundos por carta, com som de virada e fila para ativações seguidas. Cobre gerais, combate, saque e corrida. Local observa comandos aceitos; autoridade LAN publica apenas `card_id` e `player_name` após aceitação, inclusive para a TV. Não publica mãos, índices ou recursos; passar uma reação não gera apresentação. Evento LAN continua deduplicado pelo endpoint. Apresentação estática também com movimento reduzido; pausa suspende o tempo. Nenhuma animação determina resultado ou consome RNG.

Verificação Windows/Godot 4.7.2: `premium_ui_smoke` cobre atalhos e cancelamento por input real, fechamento da CARGA em quatro resoluções, arte local/LAN/TV, quatro segundos, fila, som, uso recusado e projeção pública. Regressões de fluxo de turno, compartilhamento local, sessão LAN, layout compacto LAN, TV, leitura e som também executadas. Jornada ENet de quatro jogadores + TV passou em menu, combate e corrida. Os cenários não tiveram falhas de asserção; o runner geral acusa `ERROR: Failed to read the root certificate store.` no ambiente Windows restrito, portanto não há PASS integral desse runner. Capturas transitórias em `.tools/premium-ui/`, incluindo `card-activation-tv.png`. Sem novos APKs, teste auditivo ou validação Android/TV físicos.

Tela inicial de 03/11: [START_SCREEN_BACKGROUND.md](START_SCREEN_BACKGROUND.md) registra a integração de `assets/tela_inicial/context.md`, ações preservadas, grade superior à direita, áudio único e fallback. A revisão V2 corrige o cenário/reenquadramento do carro e usa oito poses de caminhada do hostil. Originais preservados; validação desktop, sem APK novo ou teste físico.

Direção vigente de 03/11/2026: **layout contextual, menos texto e identidade pós-apocalíptica**, mantendo veículos existentes por preferência do usuário. [UI_PREMIUM_IMPLEMENTATION.md](UI_PREMIUM_IMPLEMENTATION.md) registra atalhos locais/LAN, operações/setores compartilhados, inventário em cartões, folhas pela altura do conteúdo e tema grafite/areia também na TV. 40 suítes e jornadas de rede passaram em Windows. Relatos abaixo descrevem a evolução anterior. Sem homologação física ou novo APK.

Viagem/combate/veículo (02/11/2026): Viajar usa o mapa livre com as estradas legais destacadas como na fuga; selecionar abre a prévia, cancelar restaura a câmera. Atacante e defensor têm nomes, rótulos e molduras nas cores dos participantes; o dado repete a cor/nome de quem ataca e mostra **?** antes da próxima rolagem. Cartas podem ser usadas diretamente na arena, com leitura ampliada opcional e privacidade hot-seat. O ciclo visual foi reduzido para 0,55 s de dado + 0,12 s de pausa + 0,3 s de dano; a mesma arena pública atende celulares LAN e TV.

Hatch 0.7 agora carrega cinco (sete com E08), preservando quatro/seis nos perfis anteriores. Carga exatamente cheia não bloqueia fim de turno. Excesso apresenta **Liberar carga**, quantidade a liberar e comandos legais de guardar, abastecer e descartar. Tocar no carro do mapa ou no retrato abre `vehicle_details.gd` em tela cheia, com atributos e recursos organizados em colunas. Estoques e tanque atuais ficam restritos ao próprio jogador; consultas alheias e TV usam apenas dados públicos. Telas compactas mantêm rolagem e Voltar acessível.

Verificação Windows/Godot 4.7.2: `turn_flow_ui_smoke` passou em 63 verificações de viagens/cancelamento/prévia sem RNG, detalhes públicos/privados, fim de turno com carga no limite, liberação única de excedente, reação direta Local/LAN, alternância do dono/cor do dado e duração visual. `balance_smoke` cobre Hatch moderno/legado, E08 e melhoria paga somente com a carga. A matriz final passou nas 19 suítes de regras/campanha/combate, permissões LAN, transferências, viagem, HUD, TV e layout normal/compacto/ampliado; `combat_ui_smoke` também passou na validação específica do seletor opcional e dos novos tempos. Cinco processos ENet (quatro jogadores + TV) completaram menu, exploração, combate e corrida com projeção pública sem comandos privados. Capturas transitórias: `.tools/travel-map-picker.png`, `.tools/vehicle-fullscreen.png`, `.tools/cargo-overload-guidance.png`, `.tools/combat-roles-fast.png`. Testes de layout incluem recortes e texto ampliado. Sem validação Android/TV física ou geração de novos APKs nesta alteração.

Encontros/Agir aqui (02/11/2026): removida a confirmação intermediária de eventos automáticos após fechar a carta revelada. Escolhas reais de recurso/alvo continuam sendo pedidas. Deltas aceitos recebem destaque animado; a arte original de **CORRIDA SURPRESA** foi importada sem edição e aparece centralizada no início da prova em Local/LAN/TV. A apresentação não envia comandos, não consome RNG e não revela recursos de terceiros; movimento reduzido usa o mesmo aviso sem escala/fade. Agir aqui tem três funções: Explorar, Conquistar/saquear e Depósitos. Cada função abre seus setores; exploração isola a escolha de recurso garantido, depósitos isolam retirar/guardar/abastecer. Transferências permanecem livres e conservam a tela de recursos.

Validação desta alteração em Windows/Godot 4.7.2: `encounter_flow_ui_smoke` cobre resolução única, escolhas explícitas Local/LAN, transferências pelos submenus, deltas reais, arte local/TV, snapshots duplicados e pausa. Passaram também viagem/encontros, exploração, campanha/sessão/menu LAN, campanha UI, transferências, layout normal/ampliado, UI moderna, TV e encontros públicos. Jornada ENet com cinco processos passou (quatro jogadores navegam no novo menu, exploram, combatem e entram na corrida; TV permanece sem capacidades privadas). Capturas transitórias: `.tools/surprise-race-local.png`, `.tools/surprise-race-tv.png`, `.tools/city-functions-local.png`. Não houve geração de novos APKs nem teste físico Android/TV nesta alteração.

Correções de 02/11/2026: etapas centralizadas verticalmente pela altura real do topo, ícones de mapa/localização/menu centralizados e administração organizada em submenus curtos. Cabeçalhos oferecem **‹ Voltar** e **Fechar**; o botão Voltar do Android retorna um nível. Local preserva a seção após executar um comando; LAN apresenta recursos, reparos e melhorias conforme capacidades próprias. Verificações em Windows/Godot 4.7.2: `hud_preparation_smoke`, `campaign_ui_smoke`, `lan_action_menu_ui_smoke` (71 verificações em três resoluções), `lan_ui_smoke`, `mobile_layout_smoke`, `scroll_touch_smoke`, `tv_dashboard_smoke`, `public_encounters_ui_smoke` e `card_reading_ui_smoke` passaram. Incluem alinhamento com texto ampliado, retorno sem mutação/RNG/comandos LAN, transferência única de combustível e preservação da apresentação pública. Evidências transitórias em `.tools/hud-preparation-1.0.png` e `.tools/campaign-administration.png`. Android/TV físicos e novos APKs não foram validados/gerados nesta alteração.

Data: 30/10/2026. Godot 4.7.2 Standard, renderer Compatibility.

Combate/fuga/sons: dado central entre os combatentes, comandos abaixo dos painéis e extras recolhidos; **Fugir** abre o mapa com estradas legais pulsantes e cancelar sem custo. Captura `.tools/combat-escape-map.png`; `combat_escape_sfx_smoke` cobre local/LAN, cancelamento, tentativa, som de reparo, batida, ataque, esquiva e virada única. Efeitos respeitam volume próprio e pausa; testes usam Dummy, sem evidência auditiva em aparelho físico.

Leitura (31/10): menu no extremo direito após turno; barra musical com porcentagem no início das configurações; contorno preto das cartas iniciais até leitura individual (estático em movimento reduzido). Leitor centralizado e toque na arte abre ampliação central, com Voltar sem usar carta. Leitura persiste por instância neste aparelho. Capturas `.tools/card-reading-centered.png` e `.tools/card-reading-expanded.png`; `card_reading_ui_smoke` verifica identidade, centralização e ausência de mutações de jogo.

Música (31/10): **Aftermath**, Kevin MacLeod, em loop no local/TV, com volume independente e créditos CC BY 4.0 nas configurações. Celulares LAN permanecem sem trilha para evitar duplicação; efeitos seguem disponíveis. `music_smoke` valida controles e ciclo de vida com áudio Dummy; captura em `.tools/music-settings.png`. Licença e créditos embarcados nos APKs.

Viagem/encontro (31/10): confirmação aceita anima o veículo top-down no mapa principal, da cidade A à B pela estrada, com orientação do trajeto e som de motor; não há cena separada da viagem; o encontro usa verso e flip da compra geral, seguido de **Resolver encontro**, mantendo as escolhas originais. O recorte individual dos 24 quadros substitui a composição de atlas em `AnimatedTexture` que exibia a folha inteira. Testes renderizados local/LAN verificam duplicação, pausa, volume zero, movimento reduzido e autorização da frente; capturas em `.tools/travel-vehicle-engine.png` e `.tools/encounter-card-reveal.png`. Android físico permanece pendente.

HUD revisado em 31/10: topo com nome colorido em negrito, etapas centrais e turno à direita; botão vermelho **Comprar Carta** na preparação; carga com comandos curtos e quantidades dentro do painel. `hud_preparation_smoke` renderiza preparação/carga com texto 1.0/1.25 em `.tools/hud-*.png`, verifica alinhamento e confirma compra de uma carta após as duas iniciais já distribuídas sem animação. Evidências Windows; validação em Android físico pendente.

Atualização de interação (31/10): arrasto vertical sobre botões/painéis dos menus compartilhados, com seleção simples preservada; combate local distingue turno, reação e revelação de carta recebida, validando o dono antes de abrir cartas; resultado compacto com ícones, nomes e quantidades, relato em **Ver detalhes**. `scroll_touch_smoke`, `combat_ui_smoke`, `lan_ui_smoke`, `mobile_layout_smoke` e `pvp_rewards` passaram em Windows. Tela de recompensa renderizada e revisada; validação em Android físico pendente.

Revisão após os prints físicos do Galaxy S23: [S23_LAYOUT_FIX.md](S23_LAYOUT_FIX.md). Corrigidos DPI aplicado à tipografia, limites da folha lateral, consulta de carta e mapa duplicado. A nova apresentação foi renderizada no Windows com métricas simuladas do S23 e texto ampliado; falta confirmar essa correção no aparelho.

## Resultado

Mapa atualizado para o [alinhamento v3](MAP_ALIGNMENT_V3.md): novo terreno sem rodovias pintadas; camada física de estrada coincide com a seleção e a viagem. A arte panorâmica anterior foi substituída por margens rurais sem conexões decorativas. Acesso de terra Santa Cruz ↔ Rio Claro incluído por solicitação explícita.

Aplicada a reformulação técnica da interface: HUD compacto em cenas, tema próprio, fontes licenciadas, gaveta de carga, cartas com leitura textual, menu e configurações, passagem privada de dispositivo, rotas editoriais e notificações contextuais.

Atualização posterior: removido o seletor **Reduzir movimento** da aquisição de cartas; a preferência permanece apenas em Configurações. Nova partida abre uma caixa central de introdução breve antes da primeira identificação privada. `intro_guide.tscn` usa o tema compartilhado; o teste `onboarding_ui_smoke.gd` validou o fluxo em janelas 1280×720 e 960×720, sem alteração de cartas/RNG e sem substituir Android físico.

A apresentação inicial foi acrescentada em `start_screen.tscn` / `start_screen.gd`, reutilizando mapa, arte lateral do Hatch e tema. Sempre abre antes de preparar ou retomar partida e oferece Continuar, Nova partida, Configurações, Como jogar e Sair. Retomada passa pela identificação; cancelamento de nova partida preserva o save e retorna ao menu. `start_screen_ui_smoke.gd` validou esses fluxos e os limites do painel em Windows 1280×720 e 960×720. Captura transitória: `.tools/start-screen.png`; Android físico continua pendente.

Na modernização visual original não foram acrescentadas regras para preencher a interface. A implementação posterior da campanha está em [contexto técnico](../CONTEXT.md): novos painéis usam a mesma folha/tema, e equipamentos/eventos/corridas são resolvidos pelo motor.

## Comparação visual

As imagens mostram execução real do projeto. O cenário de comparação usa seed 42 e jogadores Bruno, Lucas e Ana.

- [Depois — 1280 × 720](ui-after-1280x720.png)
- [Depois — 1560 × 720](ui-after-1560x720.png)
- [Depois — 960 × 720](ui-after-960x720.png)
- [Cidade, propriedade e ações de setor](ui-city-1280x720.png)
- [Carga com texto ampliado](ui-cargo-1280x720.png)
- [Configurações e movimento reduzido](ui-settings-large-1280x720.png)
- [Passagem do dispositivo com tela opaca](ui-handoff-1280x720.png)

A captura anterior disponível foi preservada em `.tools/ui-before.png`, fora do pacote exportado. Não há baseline anterior equivalente em aparelho físico ou nas três proporções.

## Matriz de implementação

| Área do plano | Entrega | Estado |
| --- | --- | --- |
| Hierarquia e espaço para o mapa | Uma barra superior; histórico/configurações/nova partida no menu; dica curta ao lado da ação; carga recolhida | Implementado |
| Aparência industrial | Tema compartilhado, molduras com acabamento vetorial, desgaste de borda, rebites em painéis maiores, sombra curta e paleta temática | Implementado com recursos nativos; sem novos bitmaps de moldura |
| Tipografia | Barlow para leitura, Barlow SemiBold para controles, Barlow Condensed Bold para títulos | Implementado; licenças incluídas |
| Estrutura de cenas | HUD, topo, resumo de veículo, carga, mão, visualizador, revelação, cidade, setor, entrega e notificações | Implementado |
| Resumo do veículo | Arte lateral, estrutura/tanque numéricos e barras, capacidade de carga e botão de gaveta | Implementado |
| Inventário | Seis recursos com ícone/nome/quantidade, inclusive zeros; separação entre tanque e reserva; estados de manutenção | Implementado |
| Setores | Número, nome e cor do dono; custos, bloqueios e exploração; acesso ao combate existente | Implementado |
| Rotas | Geometria própria em 18 conexões, piso com traçado distinto, seleção ciano e pulsação limitada | Implementado; alinhamento editorial pode ser refinado sobre a arte |
| Deslocamento | A peça acompanha a polilinha, em ambos os sentidos; animação lateral aprovada preservada | Implementado |
| Toque | Limiar de arrasto, pinça sem clique final, controles de mapa e confirmação de viagem | Implementado; ergonomia física pendente |
| Cartas | Mão central recolhida; consulta com texto legível; confirmação de descarte fora de excesso | Implementado |
| Compra | Versos, virada, fila por jogador e retomada sem duplicação | Preservado e coberto por regressão |
| Turno privado | Tela opaca antes de encerrar/entregar; HUD e mão ocultos até confirmação do próximo jogador | Implementado |
| Foco e Voltar | Foco retido no modal ativo; Voltar recolhe detalhes/gavetas; não ignora aquisição obrigatória | Implementado; botão físico pendente |
| Orientação | Dica contextual e Como jogar; preferência para reduzir instruções | Implementado |
| Ação prioritária | Explorar/conquistar em destaque quando há ação; iniciar/encerrar em destaque nos respectivos estados | Implementado |
| Feedback | Toast temporário e mensagem no detalhe; sem rodapé permanente de log | Implementado |
| Preferências | Texto padrão/grande/maior, movimento reduzido, volume de UI e dicas | Implementado e persistido |
| Áudio e vibração | Clique procedural em bus UI; vibração opcional somente Android, desligada por padrão | Implementado; hardware não validado |
| Preparação | Nomes, opções avançadas recolhidas, backup antes de substituir partida, conteúdo rolável e ajuste ao teclado virtual | Implementado; teclado Android não validado |
| Área segura e DPI | Insets nas bordas; dimensionamento de toque/fontes condicionado ao DPI reportado no Android; layouts adaptativos | Implementado; depende de calibração física |
| Exportação | Recursos, dados e licenças no PCK; docs, ferramentas e testes fora do pacote | Verificado |
| Teste com pessoas e Android real | Aparelho de entrada, tablet físico, leitor de tela, recortes, bateria, pausa e retomada | Pendente |

## Componentes e manutenção

- `scenes/ui/game_hud.tscn`: composição do HUD e suas âncoras.
- `top_bar.tscn`, `vehicle_summary.tscn` e `cargo_drawer.tscn`: regiões principais.
- `hand_dock.tscn` / `scripts/hand_dock.gd`: montagem da mão somente quando seu conteúdo muda.
- `city_panel.tscn` / `scripts/ui_sheet.gd`: detalhes, menu, configurações e feedback local em folha lateral.
- `sector_row.tscn`: componente de apresentação de um setor.
- `card_viewer.tscn` e `card_reveal.tscn`: consulta e aquisição.
- `turn_handoff.tscn`: privacidade e confirmação de entrega.
- `notification_stack.tscn`: mensagens temporárias que não interceptam toques no mapa.
- `themes/wasteland_theme.tres`: fonte e estilos editáveis no Inspector.
- `scripts/ui_style.gd`: criação do tema e tokens; `tools/build_ui_theme.gd` regenera o recurso.
- `scripts/metal_panel.gd`: acabamento nativo, sem shader de desfoque ou textura grande extra.
- `scripts/ui_preferences.gd`: preferências, mantendo a chave de movimento reduzido já existente.
- `scripts/ui_audio.gd`: efeitos procedurais curtos, bus UI e vibração opcional.
- `data/route-presentation.json`: pontos percentuais de apresentação; não contém regras, custos ou conectividade alternativa.
- `main.gd`: coordenação, adaptação ao dispositivo, dados dos painéis e envio de intenções ao motor.

O inventário mantém a árvore de seus controles; as quantidades atualizam sem reconstruir a carga. A mão compara sua assinatura antes de substituir as cartas. Não há consulta de regras por frame. O polling de teclado virtual fica ativo somente durante a preparação.

## Assets e licenças

| Asset | Origem | Licença/observação |
| --- | --- | --- |
| Barlow Regular e SemiBold | [Google Fonts / Barlow](https://github.com/google/fonts/tree/main/ofl/barlow) | SIL Open Font License 1.1 em `assets/ui/fonts/Barlow-OFL.txt` |
| Barlow Condensed Bold | [Google Fonts / Barlow Condensed](https://github.com/google/fonts/tree/main/ofl/barlowcondensed) | SIL OFL 1.1 em `assets/ui/fonts/BarlowCondensed-OFL.txt` |
| Ícones de recursos | Arquivos existentes do jogo | Cópia para `assets/ui/resources`; sem alteração dos originais |
| Ícones de navegação | SVGs criados no projeto | Traço uniforme, sem glifos improvisados |
| Veículos, cartas, versos e mapa | Assets existentes | Preservados |
| Efeito de clique | Síntese no código | Não depende de biblioteca de áudio externa |
| Molduras e desgaste | Desenho vetorial nativo | Sem custo de carregar novos fundos rasterizados |

Os dois arquivos OFL são incluídos explicitamente no preset de exportação.

## Evidências de validação

### Cobertura do HUD

O teste soma os retângulos de topo, resumo, mão e controles, tratando até áreas transparentes da mão como cobertas. É uma estimativa conservadora de layout, não segmentação de pixels.

| Janela desktop | Proporção aproximada | Área fora dos retângulos do HUD |
| --- | --- | --- |
| 1280 × 720 | 16:9 | 75,3% |
| 1560 × 720 | 21,7:10 | 78,1% |
| 960 × 720 | 4:3 | 81,5% |

O indicador supera a meta proposta de 65% nos três casos. Não mede tamanho físico do alvo de toque.

### Testes

- `tests/smoke.gd`: criação, RNG, turnos, viagens, exploração, carga e save.
- `tests/combat_smoke.gd`: cartas, ataques, hostis, vidas, fuga e conquista.
- `tests/ui_smoke.gd`: cidades/setores/donos, exploração, retirada, mão, consulta, toque e zoom.
- `tests/reveal_smoke.gd`: inicial, compra, fila, cinco tipos, retomada e movimento reduzido.
- `tests/combat_ui_smoke.gd`: dado, reações, resultado, mapa livre e veículo.
- `tests/modern_ui_smoke.gd`: cobertura, cenas, árvore estável, menu, texto maior, carga, detalhe de cidade, privacidade, Voltar, geometria e preservação do estado.

Os testes usam perfil isolado em `.tools/profile`. As três proporções foram executadas com renderer real no Windows; o teste de pacote também verificou dados, cenas, tema e licenças.

### Medições

Arquivos `ui-metrics-1280x720.json`, `ui-metrics-1560x720.json` e `ui-metrics-960x720.json` contêm cobertura, memória estática e intervalos entre frames após as interações.

O intervalo é amostrado por timestamp de 90 frames consecutivos, sem garantia de VSYNC. Memória estática não inclui toda a memória de vídeo. São medidas de desktop, não evidência de 60 FPS ou orçamento de RAM no Android.

### Empacotamento

Gerado e verificado PCK usando o preset Android, com aproximadamente 114 MiB. O PCK valida conteúdo e referências; não é APK e não comprova execução Android.

## Pendências para considerar a entrega validada em produção

1. Configurar SDK/JDK/templates no ambiente e gerar APK de debug.
2. Instalar em um telefone de entrada e em um aparelho de referência; incluir tablet quando disponível.
3. Conferir alvos próximos de 48 dp no aparelho, pois DPI informado e densidade efetiva podem divergir.
4. Testar teclado virtual, recorte, barras do sistema, Voltar físico, vibração e acessibilidade Android.
5. Medir frame time, memória de vídeo, carregamento de cartas e consumo em sessão prolongada.
6. Executar as jornadas com jogadores novos; ainda não houve avaliação humana medida.
7. Refinar manualmente o alinhamento dos traçados editoriais à arte conforme o feedback visual.

Não foi gerado APK nesta etapa: SDK/JDK e aparelho Android não estão configurados no ambiente. O código e o preset estão preparados para continuar essa validação. Não foram inventados resultados de aparelho ou de playtest.

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
