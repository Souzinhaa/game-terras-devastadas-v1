# Terras Devastadas — plano de reimplementação da interface

Data: 03/11/2026. Estado: especificação para implementação futura; nenhuma alteração de runtime é declarada por este documento.

## 1. Pedido, prioridade e resultado esperado

O usuário quer abandonar a aparência retrô e obter uma experiência moderna, mais fácil de entender e mais interativa. A referência é Wingspan digital. A prioridade explicitamente escolhida é **arte ilustrada e acabamento de jogo de tabuleiro premium**.

A direção proposta é um **tabuleiro pós-apocalíptico ilustrado, com peças bem acabadas, interface limpa e interação contextual**. Ruínas, estradas, veículos e sobrevivência continuam definindo o mundo. A apresentação passa a privilegiar composição, ilustração, legibilidade e resposta ao toque.

Este trabalho abrange direção de arte e experiência de uso; trocar cores e arredondar botões não satisfaz o pedido. Mapa, veículos, cartas, marcadores e controles devem pertencer à mesma linguagem visual.

Alvo: Godot 4.7 Standard, GDScript, renderer Compatibility, Android em paisagem. Cobertura obrigatória: normal/local hot-seat e Multiplayer LAN; TV/Tabuleiro para toda mudança de apresentação pública. React em `src/` é referência histórica e fica fora desta reimplementação.

### Como usar este documento

1. Ler as instruções e os contratos atuais indicados na seção 3.
2. Conferir os caminhos e o estado real do checkout; este documento não substitui investigação do código.
3. Trabalhar por etapas da seção 12, com revisão visual e regressões a cada etapa funcional.
4. Registrar o resultado e as pendências com evidências. Não tratar uma proposta, mockup ou asset importado como feature entregue.

Este plano reduz risco por isolamento, migração gradual e verificações. Não promete ausência absoluta de regressões. A LLM deve interromper a expansão de uma etapa quando houver regressão de regra, save, privacidade ou comando e corrigir a causa antes de continuar.

## 2. Diagnóstico e relação com o planejamento anterior

Foram consultados `update_ui.md`, `godot/docs/UI_IMPLEMENTATION.md`, `godot/CONTEXT.md`, componentes e inventário de testes. Foram inspecionadas estas capturas existentes:

- `godot/docs/ui-after-1280x720.png`.
- `.tools/city-functions-local.png`.

Observações limitadas a essas evidências: textura muito granulada no mapa e veículos; predomínio de tons terrosos escuros; molduras industriais; títulos condensados; cidades representadas principalmente por círculos e etiquetas; menu de ações em grandes linhas semelhantes entre si. Esses elementos ajudam a explicar a percepção retrô, mas não substituem uma auditoria da versão executada no início da implementação.

As evidências também mostram funcionalidades já existentes. Não presumir que viagens, cartas, combate, transferências ou LAN precisam ser reinventados. O relatório atual descreve correções de interação, animações e fluxos que devem ser preservados.

O plano anterior prioriza metal, ferrugem, rebites e papel gasto. Para esta nova proposta, a preferência recente do usuário muda a prioridade visual: desgaste fica na ilustração do mundo; a superfície de leitura recebe acabamento limpo. As restrições funcionais e de privacidade continuam valendo. Se uma instrução local exigir uma composição específica, preservar o contrato e renovar seu tratamento visual.

## 3. Leitura obrigatória antes de modificar o jogo

Ler, nesta ordem, verificando instruções adicionais nos diretórios tocados:

1. `AGENTS.md`, `godot/AGENTS.md` e `godot/CONTEXT.md`.
2. `godot/README.md` e instruções das skills aplicáveis, começando por `using-godot-prompter` antes da implementação.
3. `rules.md`, `rules-cards.md`, `docs/COMO_JOGAR.md` e os JSON usados pelo fluxo alterado.
4. `update_ui.md` e `godot/docs/UI_IMPLEMENTATION.md`, distinguindo histórico e estado atual.
5. Scripts, cenas e testes do fluxo efetivamente alterado.

Não transformar relatos históricos de sistemas incompletos em tarefas atuais. Em divergência entre relatório e código, investigar e registrar a conclusão antes de alterar comportamento.

## 4. Direção de arte

### 4.1 Referência e identidade própria

Usar Wingspan como referência de integração entre ilustração, componentes e apresentação digital. A página oficial fornece screenshots e trailer; o press kit descreve elementos animados e sons associados ao conteúdo. A proposta abaixo é uma interpretação para Terras Devastadas, não uma afirmação de que copiar sua composição garante usabilidade.

- Referência visual oficial: https://www.monstercouch.com/wingspan/
- Press kit: https://www.monstercouch.com/press/sheet.php?p=wingspan

Não reutilizar artes, ícones, música, marcas ou layouts proprietários da referência. Produzir identidade própria e registrar origem/licença de todos os assets incorporados.

### 4.2 Mundo e mapa

- Ilustração 2D pintada, com formas e volumes legíveis, contornos suaves e detalhe seletivo.
- Estradas, rios, vegetação e ruínas devem formar grandes massas visuais reconhecíveis no celular.
- Reduzir ruído fino, pontilhado e contraste repetitivo no chão. Reservar detalhes para pontos de interesse.
- Diferenciar cidades por pequenas ilustrações de silhueta e identidade local: torres, oficina, indústria, ponte ou agrupamento urbano, conforme o conteúdo existente.
- Usar luz quente e cores naturais com variação; evitar que toda a tela tenha o mesmo marrom/laranja.
- Preservar nomes, topologia, cidades, setores, rotas e seus custos. Uma nova ponte desenhada não cria conexão jogável.
- Manter coordenadas lógicas estáveis sempre que possível. Se a arte exigir transformação, aplicar a mesma transformação visual a cidades, rotas, seleção, veículos e câmera; testar ida e volta entre coordenadas.
- Textos, quantidades, propriedade, seleção e botões são elementos vivos da UI, nunca pintados no fundo.

### 4.3 Peças e veículos

- Veículos com silhueta clara, pintura ilustrada e sombra curta de contato, coerentes com o mapa.
- Preservar identificação por jogador usando cor acompanhada de nome, símbolo ou contorno identificável.
- Setores como fichas bem definidas, com número e estado legíveis; evitar excesso de círculos minúsculos em zoom distante.
- Em visão ampla, mostrar resumo da cidade; ao aproximar ou selecionar, revelar setores. Todo setor continua acessível por uma lista legível, sem depender de precisão no mapa.
- Propriedade e seleção precisam de códigos diferentes. Selecionar não deve parecer conquistar.
- Substituir sprites e animações de veículos de forma coerente; não misturar carro pintado no painel com sprite retrô como resultado final.

### 4.4 Interface e tipografia

- Painéis claros em marfim mineral, cinza quente ou areia suave; grafite para texto e controles de contraste.
- Bordas discretas, sombras curtas e espaçamento generoso. Eliminar rebites e molduras desgastadas dos controles comuns.
- Títulos com personalidade editorial e boa legibilidade; corpo com família limpa e acentuação portuguesa completa.
- Evitar fonte condensada como padrão de todos os botões. Testar primeiro a família de leitura já licenciada no projeto; uma nova fonte só entra após validação visual e de licença.
- Tamanho deve ser validado no aparelho. O canvas 1440×810 não garante legibilidade física por si só.
- Ícones consistentes, desenhados para tamanho pequeno. Ações centrais mantêm rótulos; tooltip/hover não é requisito para compreensão.

Paleta inicial de estudo, sujeita a contraste e prova renderizada:

| Papel | Cor inicial | Uso |
| --- | --- | --- |
| Superfície principal | `#F2EBDD` | Folhas, leitores e cartões |
| Superfície secundária | `#DFD7C8` | Agrupamentos e fundos auxiliares |
| Texto principal | `#253238` | Leitura |
| Texto secundário | `#566167` | Contexto, mantendo contraste |
| Destaque principal | `#276D73` | Ação contextual prioritária |
| Seleção | `#D49B41` | Contorno e marcação, com forma adicional |
| Perigo | `#AB443D` | Dano, descarte e ações destrutivas |

Não atribuir essas cores aos jogadores automaticamente. Manter a associação estável entre IDs e cores dos jogadores. Rever todas as combinações e estados de foco/indisponibilidade.

### 4.5 Cartas

- Preservar proporções e identidade de cada carta, com título, tipo, momento de uso e efeito legíveis em texto de interface.
- A arte ocupa área de destaque; a moldura recebe hierarquia consistente com o restante do jogo.
- Auditar o catálogo antes de decidir substituição de ilustrações. Classificar assets em manter, adaptar apresentação ou refazer.
- Não esconder informação necessária dentro de uma nova ilustração. Texto renderizado deve acompanhar edição e regras da partida.
- Novas artes só são aceitas após verificar associação por ID, frente/verso, categoria, direitos e leitura em escala reduzida.
- A migração não altera efeitos ou disponibilidade de cartas. E11/V16 e saves legados continuam seguindo os contratos atuais.

## 5. Composição e navegação

### 5.1 Tabuleiro principal

Preservar o mapa como centro da partida. Organização proposta:

```text
┌──────────────────────── área segura ─────────────────────────┐
│ Jogador / contexto       Preparação · Ação · Fim   Turno Menu │
│                                                            │
│ Veículo resumido        MAPA ILUSTRADO            Localizar  │
│ estrutura / tanque     cidades como lugares                 │
│ abrir carga            rotas contextuais                    │
│                                                            │
│                        detalhe da seleção, se houver        │
│             mão recolhida central            ação do estado │
└────────────────────────────────────────────────────────────┘
```

Esse desenho indica hierarquia, não coordenadas absolutas. Implementar com containers, âncoras e área segura.

- Topo compacto com jogador, contexto do turno e menu; manter turno e navegação sempre legíveis.
- Resumo lateral do veículo preservado, com imagem, estrutura, tanque e acesso explícito à carga.
- Mão central recolhida sem faixa preta, conforme instrução vigente. Toque expande a consulta; não exigir leitura de miniatura.
- Encerrar turno permanece alcançável e separado de descarte/confirmar ações. Sua ênfase depende do estado, sem esconder opções legais.
- A instrução contextual explica o próximo passo obrigatório, quando existir. Em uma decisão estratégica, apresentar as opções sem escolher a estratégia do jogador.
- Tablet pode ampliar detalhes laterais; celular compacto usa folha contextual. A navegação e os nomes continuam consistentes.

### 5.2 Interação direta com cidade e setor

Um toque em cidade seleciona e abre resumo contextual. Arrastar continua movendo o mapa; pinça amplia. Seleção nunca executa viagem ou conquista.

O resumo mostra nome, presença pública de jogadores, setores e operações relevantes. Ações de alto nível como Explorar, Conquistar/saquear e Depósitos continuam acessíveis, com detalhes vinculados à seleção. Reduzir navegação redundante só após verificar todos os alvos e permissões dos dois modos.

Ao selecionar um setor, mostrar nome/número, dono e informações autorizadas, com a ação correspondente e seu custo. Ações bloqueadas relevantes explicam o motivo. Usar validação e capacidades existentes; não derivar elegibilidade da aparência ou do dono exibido.

Fluxo de viagem: selecionar destino → ver rota, custo e impedimentos → confirmar → aguardar aceitação → apresentar deslocamento → continuar encontro. Cancelar antes da confirmação não altera estado. A prévia não cobra combustível nem consome RNG.

### 5.3 Veículo, carga e depósito

- Abrir veículo a partir do resumo ou da peça mantém o fluxo existente de detalhes.
- Carga: ícone, nome, quantidade e capacidade; distinguir tanque, carga e depósito com títulos e agrupamento espacial.
- Transferência: origem, quantidade, destino e impacto na capacidade. Exibir o resultado após aceitação.
- Exploração: exibir o delta real recebido no depósito, sem simular ganho na carga.
- Carga cheia e carga excedente são estados diferentes; respeitar os impedimentos reais do motor.
- Melhorias e reparos mostram custo e consequência segundo o perfil atual; não fixar valores 0.7 em partidas 0.6.
- Arrastar recursos é opcional e fica para depois da primeira entrega. Toda operação tem alternativa por toque. Soltar nunca executa um segundo comando além do clique equivalente.

### 5.4 Mão, leitura, aquisição e reação

- Toque na carta abre leitura; usar, descartar e fechar são controles distintos.
- A ampliação da arte fica acima do leitor tanto em desenho quanto em captura de input. Voltar fecha o nível superior sem atingir o controle de trás.
- Preservar compra/revelação: frente só aparece após autorização; confirmar recolhe e avança a fila correta.
- Não aplicar animação genérica de clique ao fluxo de aquisição/revelação de forma que altere sua sequência.
- Preservar identificação das cartas iniciais não lidas e a persistência local de leitura, modernizando o indicador se necessário.
- Reação fora do turno informa claramente quem deve decidir; não chama início de turno nem compra cartas.
- Hot-seat oculta dados privados antes de solicitar entrega do aparelho. LAN só mostra a mão do assento autorizado.

### 5.5 Combate, corrida e encontros

- Renovar o enquadramento como uma arena ilustrada com participantes identificados e dado central.
- Resultado, ator e alvo devem ser inequívocos, inclusive sem som e em movimento reduzido.
- Preservar comandos próximos dos combatentes, leitura de cartas, fuga pelo mapa e opções extras recolhidas.
- Custos opcionais, munição, equipamento, reações e escolhas finais continuam explícitos; não automatizar por conveniência visual.
- Corrida conserva inscrições, marcos e ordem das decisões. Não converter apresentação em nova regra de minijogo.
- Eventos automáticos não ganham confirmação redundante; escolhas reais continuam pedidas.
- A TV apresenta apenas o fato público autorizado, sem botões privados ou dados ocultos do encontro.

## 6. Interatividade e feedback

Mais interativo significa que objetos respondem e as consequências ficam compreensíveis. Priorizar:

| Interação | Resposta imediata | Após aceitação do comando |
| --- | --- | --- |
| Tocar cidade/setor | Seleção e detalhe | Só muda jogo se uma ação for confirmada |
| Selecionar rota | Traçado, destino e custo | Veículo percorre a rota aceita |
| Tocar carta | Elevação/abertura do leitor | Uso/descarte só após comando próprio |
| Abastecer/transferir | Prévia de origem/destino | Quantidades atualizam e delta recebe destaque |
| Atacar | Controle indica processamento | Dado e dano apresentam o resultado recebido |
| Encerrar | Resposta de toque | Nova vez somente após aceitação |

Diretrizes de tempo: microfeedback curto; transição de painel suficiente para comunicar origem; animações de jogo sem espera decorativa obrigatória. Usar as durações já verificadas como baseline antes de alterá-las. Não alongar combate ou viagem para exibir arte.

- Centralizar feedback em `ui_feedback.gd` e efeitos públicos em `board_feedback.gd` quando suas responsabilidades se aplicarem.
- Respeitar pausa, volume e movimento reduzido. Redução de movimento mantém informação com estados estáticos e texto.
- Impedir duplo envio durante processamento com o mecanismo existente de comandos/recibos; não inventar confirmação paralela no cliente.
- Reconexão e snapshots duplicados não repetem ganho, som, revelação ou deslocamento como se fossem uma nova ação.
- Não introduzir flashes intensos ou movimentação contínua em todos os objetos do mapa.

## 7. Contratos que não podem regredir

### Regras e persistência

- Novas partidas: `campaign-v07`, regras 0.7, conteúdo 0.7.0. Saves `campaign-v06` mantêm sua edição; `stage1` continua legado.
- Não alterar balanceamento, baralhos, custos, vitória, RNG, formato de save ou migração para acomodar o novo layout.
- Regras e resultados permanecem no motor; UI consulta elegibilidade, apresenta estado e emite comandos.
- `action_reason` é consulta isolada; navegar, abrir painéis e renderizar não alteram estado nem RNG.
- Aquisição usa `WastelandGame.gain_card`; remoção de mão usa `take_hand_card`. Preservar instâncias, índices, tickets e filas pendentes.
- Exploração concede recursos uma vez ao depósito. Fechar, reabrir, reconectar ou pular animação nunca concede novamente.
- Preservar combate pendente, rodada, cotas de cartas, escolhas, recibos e sequência de revelação ao salvar/restaurar.

### LAN e TV

- Na LAN, `game.player()` representa o ativo, não necessariamente o dono do aparelho. A UI deve usar a identidade/capacidades do assento correto.
- `CommandCatalog` vincula opções e argumentos ao ator. Preservar a validação autoritativa e os recibos.
- `ViewProjector` fornece somente o que o destinatário pode ver. Não passar save completo ao cliente para facilitar um componente.
- Não revelar mãos, depósitos, recursos privados, RNG, baralhos ou identidade de ameaça ainda oculta em miniaturas, tooltips, animações, logs ou capturas.
- TV/Tabuleiro não vira jogador, não ganha capacidades privadas e não confirma animações necessárias à progressão.
- Cobrir hot-seat com TV opcional e LAN com TV opcional. Não pressupor que toda sessão usa uma TV.

### Input e apresentação

- Um gesto corresponde a uma intenção. Rolagem e pinça não disparam clique residual.
- Painéis bloqueiam o mapa abaixo; só o controle/camada superior recebe input onde houver sobreposição.
- Voltar fecha ampliação, leitor ou folha de acordo com a pilha. Não deve descartar carta, confirmar custo ou sair da partida por acidente.
- Movimento reduzido e interrupção de animação preservam a mesma informação e resultado.
- Sons/animações não criam comandos, não consomem RNG e não decidem quando um resultado passa a existir.

## 8. Mapa de implementação

Os caminhos abaixo foram identificados no checkout usado para planejar. Ler suas APIs e dependências antes de editar; não assumir assinaturas pelo nome.

| Área | Arquivos principais | Orientação |
| --- | --- | --- |
| Tema/componentes | `godot/scripts/ui_style.gd`, `godot/themes/wasteland_theme.tres`, `godot/scenes/ui/` | Tokens compartilhados e componentes reutilizáveis |
| Composição local | `godot/scripts/main.gd`, `campaign_panel.gd`, `hud_presentation.gd`, `turn_steps.gd` | Trocar apresentação preservando transições |
| Composição LAN | `godot/scripts/network/player_hud.gd`, `lan_screen.gd`, `lan_layout.gd` | Mesma linguagem visual, capacidades do assento |
| Mapa | `godot/scripts/board.gd`, `network/board_view.gd`, `city_actions.gd` | Separar arte, geometria e seleção das regras |
| Veículo | `godot/scripts/vehicle_details.gd`, `vehicle_art.gd` | Preservar filtros públicos/privados e animação |
| Cartas | `godot/scripts/hand_dock.gd`, `card_zoom.gd`, `card_reveal.gd`, `network/card_reader.gd`, `new_card_outline.gd` | Preservar IDs, input e aquisição |
| Folhas e toque | `godot/scripts/ui_sheet.gd`, `ui_scroll_input.gd`, `turn_handoff.gd` | Preservar Voltar, rolagem e privacidade |
| Animações públicas | `godot/scripts/travel_presentation.gd`, `encounter_reveal.gd`, `encounter_effects.gd`, `board_feedback.gd` | Apresentar fatos aceitos, deduplicados |
| Combate/corrida | `godot/scripts/combat_view.gd`, `race_board.gd`, `escape_map_picker.gd` | Trocar composição sem alterar decisões |
| TV | `godot/scripts/network/tv_dashboard.gd` | Leitura a distância, somente conteúdo público |
| Preferências/ajuda | `godot/scripts/ui_preferences.gd`, `how_to_play.gd`, `intro_guide.gd` | Preservar preferências e ajuda por edição |

Na tabela, caminhos abreviados após a primeira entrada de uma célula são relativos ao mesmo diretório, exceto onde `network/` estiver explícito.

Tratar `game_state.gd`, `campaign_rules.gd`, `world_rules.gd`, `combat_rules.gd`, `session_authority.gd`, `command_catalog.gd` e `view_projector.gd` como contratos protegidos: a renovação visual não autoriza reescrevê-los. Mudança estritamente necessária deve ser mínima, justificada, testada e sem ampliar divulgação de dados. Não criar um segundo motor ou uma segunda fonte de elegibilidade dentro da UI.

## 9. Estrutura técnica recomendada

1. Centralizar cores, espaçamentos, tipografia, raios, sombras e estados no tema/estilo compartilhado. Evitar estilos duplicados em local, LAN e TV.
2. Reutilizar as cenas existentes quando possível, preservando sinais e APIs. Se substituir um componente, mapear todos os consumidores e verificar o contrato de entrada/saída.
3. Separar adaptação de dados e composição visual: local e LAN podem ter fontes distintas, mas não precisam de dois conjuntos independentes de botões e leitores.
4. A UI reage a alterações de estado; não reconstruir mão/inventário em todo frame nem por animação. Preservar seleção e rolagem em atualizações não relacionadas.
5. Manter ordem de desenho e de input coerentes. Não confiar apenas em `z_index` para modais sobrepostos.
6. Tratar mudança de resolução, área segura, retomada e escala de texto como eventos de layout.
7. Evitar novas dependências, addons, shaders caros ou exigência de renderer diferente para obter o estilo.
8. Não alterar versão do protocolo ou compatibilidade LAN sem necessidade real demonstrada e validada.

Não planejar uma reescrita total simultânea. Migrar por componentes/fluxos completos e remover a implementação antiga apenas quando os consumidores e testes estiverem atualizados. Um modo temporário de comparação pode existir em desenvolvimento, sem duplicar regras ou se tornar configuração obrigatória do produto.

## 10. Assets e orçamento de produção

Criar inventário com: ID, arquivo de origem, uso, dimensão, licença, decisão de manutenção e substituto. Prioridade de produção:

1. Amostra de terreno/cidade, um veículo, uma ficha, três cartas representativas e um painel para fixar a linguagem.
2. Mapa completo e seus elementos mais frequentes, após validar a amostra em escala de celular.
3. Famílias de veículos e animações necessárias.
4. Molduras, versos, ícones e cartas classificadas como destoantes.
5. Telas iniciais, lobby, ajuda, configurações e acabamentos secundários.

Preservar os originais. Novos arquivos de runtime ficam em `godot/assets`, com configurações `.import` apropriadas; não editar cache `.godot/`. Não gerar ou substituir todo o catálogo antes de validar a direção em uma tela funcional.

Para geração de imagens, usar a skill/ferramenta apropriada disponível. Solicitar arte em camadas separadas, sem texto funcional embutido. Validar perspectiva, paleta, identidade, recorte e escala entre gerações. Se a ferramenta não estiver disponível, registrar a lacuna e produzir uma prova provisória identificada; não declarar acabamento final com placeholders retrô.

Antes de ampliar texturas/animações, medir uso atual e novo de memória, tempo de entrada, fluidez de pan/zoom e resposta ao toque em dispositivo representativo. Escolher dimensões a partir do maior tamanho útil de exibição; não importar tudo em resolução máxima sem necessidade. Não há orçamento de desempenho medido neste plano.

## 11. Critérios de experiência e acessibilidade

- Ao abrir o tabuleiro, o jogador reconhece sua identidade, seu veículo, o estado do turno e o próximo passo obrigatório.
- O jogador distingue explorar, viajar, retirar recursos e encerrar sem precisar compreender a estrutura interna dos menus.
- Ao tentar uma ação, consegue prever custo e destino dos recursos; depois identifica o que mudou.
- Seleção, indisponibilidade, propriedade e perigo não dependem só de cor.
- Texto ampliado reconfigura o layout sem esconder ações essenciais. Painéis longos rolam com fechamento e navegação acessíveis.
- Controles têm área confortável de toque; usar aproximadamente 48 dp como alvo inicial e medir no aparelho. Unidades Godot não equivalem automaticamente a dp.
- Navegação funciona sem hover, com toque, Voltar do Android e controles de TV quando aplicáveis. Preservar foco visível onde já houver navegação por teclado/controle.
- Como alvos de revisão de contraste, usar 4,5:1 para corpo e 3:1 para texto grande/elementos visuais relevantes, medidos sobre o fundo final. Isso não representa certificação de acessibilidade.
- Mapa continua legível com folhas abertas: reposicionar enquadramento para a área visível, sem esconder cidade/rota ativa sob o painel.

Fazer avaliação com pessoas que ainda não conhecem o jogo. Pedir que comprem/revelem carta, consultem um setor, explorem, retirem recurso, abasteçam e encerrem a vez sem instrução passo a passo. Observar buscas, retornos, toques errados e confusão entre estoques antes de pedir opinião estética. Comparar com o fluxo atual quando possível. A hipótese de que a nova UI facilita compreensão permanece não validada até esse teste.

## 12. Etapas de execução e condições de avanço

### Etapa 0 — Baseline e proteção do trabalho existente

- Registrar branch, `git status` e diff inicial. O checkout consultado no planejamento já continha numerosas alterações e arquivos novos; não presumir árvore limpa nem atribuir essas mudanças à implementação futura.
- Não usar reset, clean, checkout destrutivo ou sobrescrita de arquivos alheios. Preferir patches pequenos.
- Capturar telas atuais e executar baseline em perfil isolado. Classificar falhas preexistentes antes de editar.
- Mapear os fluxos local/LAN/TV e registrar os estados críticos da seção 13.

Avançar quando houver baseline rastreável, inventário de consumidores e clareza sobre falhas existentes.

### Etapa 1 — Prova de direção de arte e composição

- Produzir uma composição em escala real de celular: mapa ilustrado, veículo, mão, topo e um detalhe de cidade.
- Produzir exemplos de carta aberta, carga e arena para verificar coerência.
- Identificar mockups como mockups; não alterar regras ou saves para demonstrá-los.
- Conferir legibilidade, hierarquia, área segura e consistência da arte. Registrar decisões e ajustes.

Avançar com uma direção coerente que atenda ao pedido de acabamento ilustrado premium. Havendo decisões materiais sem base no pedido, apresentar alternativas concretas; não pedir aprovação de cada detalhe rotineiro.

### Etapa 2 — Sistema visual compartilhado

- Implementar tokens, tema, botões, cabeçalhos, indicadores, folhas e estados de toque/foco/bloqueio.
- Aplicar componentes em telas representativas de local, LAN e TV desde o início.
- Preservar APIs, sinais, privacidade e comportamento de Voltar/rolagem.

Avançar com prova renderizada em tamanhos normal/compacto e texto ampliado, sem regressões nos componentes alterados.

### Etapa 3 — Tabuleiro, veículo e navegação contextual

- Integrar mapa e peças novos, coordenadas, rotas, câmera, seleção e detalhes de cidade/setor.
- Atualizar resumo e detalhes do veículo, carga e depósitos.
- Migrar o acesso contextual às operações nos dois modos; sincronizar apresentação pública na TV.
- Validar viagem, exploração e transferências completas, inclusive cancelamento e comandos recusados.

Avançar com jornada jogável nos dois modos, recursos corretos e mapa consistente em todos os zooms.

### Etapa 4 — Cartas e passagem de aparelho

- Integrar linguagem visual das cartas, mão, leitor, zoom e aquisição.
- Preservar filas, leitura inicial, reações e proteção hot-seat.
- Verificar input pelo viewport real, incluindo ciclos repetidos de abrir/fechar/voltar e acesso às ações após fechar o zoom.

Avançar com frentes e versos corretos, comandos únicos e nenhuma divulgação indevida em local/LAN/TV.

### Etapa 5 — Combate, corrida, encontros e feedback

- Renovar arena, resultado, escolhas e apresentação pública.
- Preservar reações, munição/opções, fuga, recompensas e interrupções.
- Deduplicar apresentação recebida pela rede e respeitar pausa/movimento reduzido.

Avançar após regressões de combate e jornadas reais de LAN com múltiplos processos e TV.

### Etapa 6 — Telas complementares e consolidação

- Aplicar sistema visual ao início, setup, lobby, reconexão, placar, ajuda, pausa e configurações.
- Preservar música, efeitos, preferências e créditos/licenças.
- Eliminar estilos antigos remanescentes apenas quando não houver consumidores.
- Executar regressão final, revisão visual, teste de compreensão e validação física quando disponível.
- Atualizar documentação de estado e relatório, separando implementação, testes desktop e Android físico.

Não estimar prazo fechado antes de concluir inventário de assets, prova visual e custo da primeira migração. Produção de arte pode ser o maior custo desta mudança.

## 13. Matriz mínima de validação

| Cenário | Local/hot-seat | LAN jogador/host | TV/Tabuleiro |
| --- | --- | --- | --- |
| Nova partida e retomada | Identidade, proteção e perfil correto | Identidade, sala e projeção correta | Sem dados privados |
| Turno e compra | Compra única e fila de revelação | Só dono vê/confirma frente | Sem frente privada |
| Mapa/cidade/setor | Seleção, gestos e custos | Capacidades do assento | Estados públicos coerentes |
| Viagem/encontro | Prévia, cancelar, confirmar, resolver | Comando aceito/recusado/reenvio | Viagem pública sem confirmar |
| Exploração/transferência | Depósito/carga/tanque corretos | Projeção e permissão próprias | Somente deltas públicos autorizados |
| Cartas/zoom/reação | Voltar, input e troca privada | Própria mão e reação fora do turno | Nenhum vazamento |
| Combate/fuga/corrida | Escolhas e resultados preservados | Ordem, capacidades e recibos | Arena pública e atores corretos |
| Excesso/encerramento | Motivo e liberação legal | Sem executar pelo outro jogador | Próximo estado público |
| Pausa/movimento reduzido | Sem duplicar efeitos/comandos | Retomada/reconexão consistente | Informação estática equivalente |
| Save v0.6 e v0.7 | Perfil e pendências preservados | Host restaura corretamente | Exibição pela edição efetiva |

Testar também jogador eliminado, mão vazia/cheia, vários carros na mesma cidade, recurso zero, carga cheia/excedente, comando recusado, toque duplo, arrasto sobre botão e perda de conexão durante uma decisão.

Layouts: 1280×720, 2340×1080, 1024×768 e compacto 892×445, além de escala de texto ampliada e recortes simulados. Esses tamanhos são uma matriz desktop inicial, não prova de leitura/toque em Android físico. TV exige também avaliação a distância.

### 13.1 Execução dos testes existentes

O runner consultado é `godot/tools/run_checks.ps1`. Ele isola `APPDATA`/`LOCALAPPDATA` por suíte e detecta erros de script além do código de saída. Conferir a implementação atual antes de usá-lo.

Exemplos em PowerShell, a partir da raiz do repositório:

```powershell
# Regressão de regras e sessão; conferir as suítes incluídas no runner atual.
& ./godot/tools/run_checks.ps1 -HeadlessOnly

# Seleção de suítes por array de argumentos PowerShell.
& ./godot/tools/run_checks.ps1 -OnlySuites @('modern_ui_smoke', 'mobile_layout_smoke', 'mobile_layout_large', 'lan_mobile_layout', 'lan_mobile_compact', 'lan_mobile_s23', 'lan_ui_smoke', 'tv_dashboard_smoke')

# Jornada real de quatro jogadores LAN e TV.
& ./godot/tools/test_lan_network.ps1 -PeerScript 'res://tests/lan_actions_peer.gd'

# Jornada local com Tabuleiro/TV.
& ./godot/tools/test_lan_network.ps1 -PeerScript 'res://tests/local_board_peer.gd'

# Regressão completa ao consolidar o conjunto.
& ./godot/tools/run_checks.ps1
```

O runner tenta localizar `.tools/godot/Godot_v4.7.2-stable_win64_console.exe` ou `godot` no PATH; quando necessário, passar `-Godot` com o executável disponível. Não baixar ou migrar a engine silenciosamente. Inspecionar isolamento e pré-requisitos dos outros harnesses antes de executar.

Além das suítes acima, selecionar conforme a mudança: `scroll_touch_smoke`, `hud_preparation_smoke`, `campaign_ui_smoke`, `lan_action_menu_ui_smoke`, `transfers_smoke`, `exploration_ui_smoke`, `card_reading_ui_smoke`, `reveal_smoke`, `travel_encounter_ui_smoke`, `encounter_flow_ui_smoke`, `turn_flow_ui_smoke`, `combat_ui_smoke`, `combat_escape_sfx_smoke`, `public_encounters_ui_smoke`, `local_board_ui_smoke`, `music_smoke`, `onboarding_ui_smoke` e `start_screen_ui_smoke`. Conferir nomes no runner atual.

Novos testes devem cobrir riscos reais: envio duplicado, input sobreposto, privacidade, estado/RNG alterados por consulta, restauração e fluxo completo. Não criar testes que apenas reproduzem cores ou detalhes internos sem verificar comportamento útil.

### 13.2 Atualização de testes visuais

- O novo layout pode invalidar posições, hierarquias de nós e capturas antigas. Identificar quais expectativas são de apresentação e quais protegem contratos.
- Antes de atualizar uma asserção, explicar por que a nova composição a tornou obsoleta e manter uma verificação equivalente do comportamento importante.
- Não apagar testes, reduzir cobertura de privacidade ou atualizar todos os snapshots para fazer a suíte passar.
- Interações críticas devem continuar exercitando eventos reais de toque/input, além de chamadas diretas a métodos.
- Comparar estado, RNG e contadores de comandos antes/depois de consultas, cancelamentos e ciclos de leitura.
- Separar falhas da implementação de falhas preexistentes registradas no baseline.

### 13.3 Verificação física e desempenho

Quando houver aparelhos, testar celular Android em paisagem, outro formato relevante e TV/dispositivo de tabuleiro. Verificar leitura, toque, área segura, rolagem, pan/zoom, suspensão/retomada, áudio e reconexão LAN. Comparar desempenho com baseline sob o mesmo cenário.

Sem aparelho disponível, concluir somente o escopo verificável em desktop e registrar explicitamente a pendência física. Não escrever “validado no Android” com base em Windows, não chamar PCK de APK e não declarar avaliação humana que não ocorreu.

## 14. Limites e recuperação

- Não adicionar autenticação, backend, multiplayer pela internet, monetização, novas regras ou balanceamento como parte desta interface.
- Não reformatar grandes módulos nem refatorar o motor incidentalmente. Isolar qualquer correção funcional descoberta e explicitar sua causa/escopo.
- Não modificar saves do usuário para preparar demonstrações ou testes.
- Não sobrescrever os APKs entregues na raiz durante iteração visual. Eventuais builds de teste devem ter destino identificado; seguir o pipeline atual quando houver entrega de APK no escopo.
- Não remover arquivos antigos até verificar referências em cenas, scripts, testes, importações e exportação.
- Se uma etapa falhar, desfazer apenas os patches próprios necessários ou manter o componente anterior ligado; nunca reverter em bloco alterações preexistentes.
- Conservar notas por etapa com arquivos tocados, testes, screenshots, decisões e problemas. Isso permite que outra LLM retome sem supor conclusão.

## 15. Definição de conclusão e relatório de entrega

A implementação pode ser declarada funcionalmente concluída quando:

- Mapa, veículos, cartas e controles apresentam linguagem ilustrada coerente, com aparência retrô residual identificada e resolvida no escopo acordado.
- Todos os fluxos migrados funcionam em local e LAN; a apresentação pública afetada funciona na TV com privacidade preservada.
- Regras, RNG, saves/edições, custos, identidade de cartas e comandos permanecem equivalentes.
- Área segura, texto ampliado, Voltar, rolagem, foco e input sobreposto foram verificados nos layouts relevantes.
- Suítes pertinentes e regressão final passaram; exceções são explicitadas com evidência e não ocultam uma regressão introduzida.
- As telas foram efetivamente renderizadas e revistas. Teste headless não certifica acabamento visual.
- `godot/CONTEXT.md`, `godot/README.md` e `godot/docs/UI_IMPLEMENTATION.md` refletem o estado entregue. Atualizar a indicação de direção em `update_ui.md` se esta proposta passar a ser a implementação vigente, sem apagar histórico útil.
- Assets novos têm origem/licença e não substituem os originais de trabalho.

O relatório deve separar: **implementado**, **verificado em desktop**, **verificado em Android/TV físicos**, **avaliado com jogadores** e **pendente**. A facilidade de compreensão e o acabamento premium precisam de revisão visual/humana; o sucesso dos testes automatizados cobre os contratos que eles exercitam.

Formato recomendado de entrega:

```text
Resultado e etapas concluídas:
Principais mudanças visuais e de navegação:
Arquivos/fluxos alterados:
Contratos preservados e evidências:
Testes executados e resultados:
Capturas renderizadas por modo/resolução:
Dispositivos físicos efetivamente usados:
Assets novos e licenças:
Regressões preexistentes e pendências restantes:
Próxima etapa concreta, se houver:
```

## 16. Instrução curta para a LLM executora

> Implemente este plano no projeto Godot, começando pela leitura das instruções e pelo baseline. O objetivo é uma interface de tabuleiro pós-apocalíptico ilustrado com acabamento premium, tendo Wingspan como referência de qualidade visual. Preserve as regras, os saves, o RNG, as filas, a privacidade e a autoridade dos comandos. Execute por componentes e fluxos completos em local, LAN e TV quando aplicável. Não reescreva o motor, não duplique regras na UI e não descarte alterações preexistentes. Inspecione as telas renderizadas e execute os testes pertinentes por etapa. Corrija regressões introduzidas antes de avançar. Informe com precisão o que foi implementado, o que foi testado e o que ainda depende de aparelhos ou avaliação humana.
