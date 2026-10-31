# Modernização da UI — implementação e validação

Data: 30/10/2026. Godot 4.7.2 Standard, renderer Compatibility.

Revisão após os prints físicos do Galaxy S23: [S23_LAYOUT_FIX.md](S23_LAYOUT_FIX.md). Corrigidos DPI aplicado à tipografia, limites da folha lateral, consulta de carta e mapa duplicado. A nova apresentação foi renderizada no Windows com métricas simuladas do S23 e texto ampliado; falta confirmar essa correção no aparelho.

## Resultado

Mapa atualizado para o [alinhamento v3](MAP_ALIGNMENT_V3.md): novo terreno sem rodovias pintadas; camada física de estrada coincide com a seleção e a viagem. A arte panorâmica anterior foi substituída por margens rurais sem conexões decorativas. Acesso de terra Santa Cruz ↔ Rio Claro incluído por solicitação explícita.

Aplicada a reformulação técnica do `update_ui.md`: HUD compacto em cenas, tema próprio, fontes licenciadas, gaveta de carga, cartas com leitura textual, menu e configurações, passagem privada de dispositivo, rotas editoriais e notificações contextuais.

Atualização posterior: removido o seletor **Reduzir movimento** da aquisição de cartas; a preferência permanece apenas em Configurações. Nova partida abre uma caixa central de introdução breve antes da primeira identificação privada. `intro_guide.tscn` usa o tema compartilhado; o teste `onboarding_ui_smoke.gd` validou o fluxo em janelas 1280×720 e 960×720, sem alteração de cartas/RNG e sem substituir Android físico.

A apresentação inicial foi acrescentada em `start_screen.tscn` / `start_screen.gd`, reutilizando mapa, arte lateral do Hatch e tema. Sempre abre antes de preparar ou retomar partida e oferece Continuar, Nova partida, Configurações, Como jogar e Sair. Retomada passa pela identificação; cancelamento de nova partida preserva o save e retorna ao menu. `start_screen_ui_smoke.gd` validou esses fluxos e os limites do painel em Windows 1280×720 e 960×720. Captura transitória: `.tools/start-screen.png`; Android físico continua pendente.

Na modernização visual original não foram acrescentadas regras para preencher a interface. A implementação posterior da campanha está em [CAMPAIGN_IMPLEMENTATION.md](CAMPAIGN_IMPLEMENTATION.md): novos painéis usam a mesma folha/tema, e equipamentos/eventos/corridas são resolvidos pelo motor.

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
