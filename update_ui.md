# Plano de modernização da UI — Terras Devastadas / Android

**Data:** 30/10/2026  
**Engine alvo:** Godot 4.7 Standard; base atual validada no 4.7.2.  
**Plataforma prioritária:** Android em paisagem, celulares e tablets.  
**Estado deste documento:** modernização implementada no código em 30/10/2026. Testes e capturas desktop cobrem 16:9, tela larga e 4:3; validação em Android físico e testes com jogadores novos permanecem pendentes.

**Entrega e evidências:** [relatório de implementação](godot/docs/UI_IMPLEMENTATION.md), [captura 16:9](godot/docs/ui-after-1280x720.png), [cidade e setores](godot/docs/ui-city-1280x720.png), [carga com texto ampliado](godot/docs/ui-cargo-1280x720.png).

O planejamento abaixo continua como especificação e checklist. Os diagnósticos descrevem a situação anterior à modernização; a matriz do relatório distingue o que foi implementado do que ainda exige aparelho, medição ou avaliação humana.

## 1. Objetivo e definição de resultado

Transformar a interface atual em uma experiência de tabuleiro digital com acabamento de jogo, mantendo o universo de metal, ferrugem, estradas e sobrevivência da referência visual fornecida pelo usuário.

O jogador deve conseguir responder rapidamente:

1. De quem é o turno e onde está seu veículo?
2. O que pode fazer agora e quanto isso custa?
3. Quais cidades e setores pode consultar ou alcançar?
4. Quais recursos possui e onde estão guardados?
5. O que acabou de acontecer e qual é o próximo passo?

O resultado deve combinar arte temática com leitura rápida, controles confortáveis por toque, transições consistentes e poucos elementos permanentes sobre o mapa. A estética moderna será obtida por hierarquia, resposta e consistência; não exige abandonar o estilo industrial.

### Metas propostas para validação

São metas de projeto, ainda sem medição em aparelho:

- Na visão inicial, pelo menos aproximadamente 65% da área útil deve permanecer sem painéis opacos. Medir também se a cidade ativa e seus caminhos ficam descobertos; a porcentagem isolada não garante boa composição.
- Um novo jogador deve localizar a ação principal e os recursos da carga sem explicação externa.
- Consultar um setor da cidade atual deve exigir no máximo dois toques a partir do tabuleiro.
- Todo controle deve ter estado visual de toque, indisponibilidade e confirmação quando aplicável.
- Nenhuma informação indispensável deve existir apenas em texto embutido nas artes, cor, hover ou áudio.
- Preservar turnos, custos, composição dos baralhos, RNG e saves durante a modernização.

## 2. Diagnóstico inicial, antes da modernização

| Área | Problema observado | Efeito na experiência | Direção de melhoria |
| --- | --- | --- | --- |
| Topo | Título, turno, orientação e legenda formam várias faixas | O mapa perde espaço e o olhar não encontra uma prioridade clara | Uma barra compacta; instrução contextual próxima da ação |
| Painéis | Grandes retângulos planos com bordas repetidas | Aparência de ferramenta de desenvolvimento | Materiais sutis, recortes e componentes com proporções próprias |
| Veículo | Painel alto, com rolagem e controles misturados às estatísticas | Carga e ações ficam escondidas em telas menores | Resumo compacto e detalhe dedicado |
| Mapa | Linhas retas e marcadores genéricos sobre arte detalhada | Conexões parecem um diagrama técnico | Traçados editoriais de rotas e destaque contextual |
| Setores | Marcadores pequenos e legenda separada do foco | Identificar propriedade exige esforço | Número, estado e dono em camadas de detalhe |
| Cartas | Artes expressivas em miniaturas pequenas | O jogador não reconhece a mão com facilidade | Mão recolhida com maior presença visual e expansão clara |
| Ações | Muitas opções têm aparência semelhante | Iniciar, explorar e encerrar competem entre si | Uma ação de maior destaque por contexto |
| Texto | Tipografia padrão e pouca diferenciação de pesos | Interface funcional, mas sem identidade própria | Família legível para leitura e fonte de título temática |
| Feedback | Mensagens no rodapé; erros podem ficar atrás dos diálogos | O jogador não relaciona ação e resultado | Feedback no componente que originou a ação |
| Estados pendentes | Conquista e efeitos de cartas ainda não migrados | Uma promessa visual pode ser confundida com função disponível | Separar ações disponíveis de sistemas ainda indisponíveis |

## 3. Relação com o protótipo de referência

### Preservar

- Mapa como superfície dominante, com sensação de território explorável.
- Veículo e recursos à esquerda; ação de encerramento à direita.
- Cartas na parte inferior, sem uma faixa preta opaca atrás da mão.
- Metal escurecido, ferrugem, papel gasto e luz quente como identidade.
- Ciano para rota/seleção; laranja para a ação de maior importância.
- Veículos ilustrados e cartas com arte de destaque.

### Adaptar para Android

- O painel completo de veículo da referência não deve ficar permanentemente aberto no celular.
- A mão precisa de alvos de toque maiores que os detalhes visuais aparentes.
- Informações densas devem abrir em gavetas ou painéis contextuais.
- Evitar copiar todos os elementos da referência ao mesmo tempo: ela tem densidade de tela maior que a confortável para um telefone.
- Não extrair regras da imagem: a referência mostra valores e fases ilustrativos. A interface deve refletir o motor real, que hoje tem uma ação principal e uma viagem nas condições já implementadas.

**Não usar a imagem da referência como fundo funcional com textos e botões pintados.** A composição deve ser construída com elementos separados e interativos.

## 4. Direção de arte e sistema visual

### 4.1 Materiais

- Base dos painéis: metal grafite, com textura de baixa intensidade e centro uniforme atrás do texto.
- Ferrugem e desgaste concentrados nas bordas, cantos e divisórias.
- Rebites usados em painéis maiores e molduras, sem repetir em todos os botões.
- Sombras curtas para separar HUD e mapa; evitar brilho e relevo em todos os componentes.
- Papel gasto reservado a cartas, etiquetas de cidade e documentos narrativos.
- Evitar transparência excessiva em textos longos: o mapa detalhado não pode competir com a leitura.

### 4.2 Paleta inicial proposta

Valores de partida para construir o tema, sujeitos à revisão de contraste em tela:

| Função | Cor proposta | Aplicação |
| --- | --- | --- |
| Metal principal | `#151D1B` | Painéis e gavetas |
| Metal elevado | `#26312B` | Controles secundários e cartões |
| Borda envelhecida | `#8C6C43` | Molduras e divisórias |
| Texto principal | `#EADBC0` | Informação principal |
| Texto secundário | `#B7B3A4` | Explicações e contexto |
| Laranja | `#ED8E42` | Ação principal e resposta positiva de interação |
| Ciano | `#71D4D8` | Seleção e deslocamento possível |
| Vermelho | `#D86454` | Dano, erro e ação destrutiva |
| Neutro | `#92958A` | Setor sem dono e informação inativa |

As cores dos jogadores devem continuar associadas aos IDs estáveis, mesmo quando a ordem de turno muda. Sempre acompanhar propriedade com nome, número ou padrão visual. O ciano de uma facção não pode ser a única forma de diferenciar uma rota selecionada; usar também espessura e animação pontual.

### 4.3 Tipografia

- Selecionar uma fonte de título temática e uma família de leitura com boa acentuação em português.
- Conferir licença de distribuição antes de incorporar arquivos de fonte.
- Usar números claros e, quando disponível, alinhamento tabular para quantidades.
- Não aplicar textura desgastada a textos pequenos, descrições ou recursos.
- Escala inicial no canvas de referência: título 28–32, seção 22–24, corpo 20–22 e metadados 17–18 unidades lógicas.
- Esses números não equivalem automaticamente a tamanho físico confortável no Android. Ajustar após medir a escala efetiva no aparelho.
- Texto grande deve aumentar layout e rolagem sem cortar ações essenciais.

### 4.4 Ícones e espaçamento

- Usar os ícones de recursos existentes quando forem legíveis em tamanho pequeno.
- Criar ou obter um conjunto consistente para voltar, fechar, localizar, menu e histórico.
- Não usar caracteres Unicode como substitutos improvisados de ícones.
- Espaçamento baseado em passos de 4, 8, 12, 16, 24 e 32 unidades lógicas.
- Separar visualmente ações que consomem turno de operações livres.
- Ícones sem rótulo precisam de nome acessível; ações centrais devem manter texto visível.

## 5. Composição responsiva

### 5.1 Celular em paisagem — estado padrão

```text
┌──────────────────── área segura ────────────────────────────┐
│ Marca compacta    Jogador · turno · ação disponível    Menu  │
│                                                            │
│ Veículo compacto          MAPA                     Localizar│
│ tanque / estrutura      cidade ativa                        │
│ abrir carga         rotas e setores relevantes              │
│                                                            │
│                    indicação contextual                    │
│            cartas parcialmente recolhidas       ação atual │
└────────────────────────────────────────────────────────────┘
```

- Marca pequena durante a partida; a identidade completa fica na tela inicial.
- Barra superior única com jogador ativo, turno e ações restantes.
- Menu contém histórico, configurações e nova partida; não manter tudo exposto.
- Resumo do veículo mostra modelo, estrutura e tanque. Carga abre por toque.
- Mão centralizada na área útil inteira, independentemente da largura dos painéis laterais.
- Instrução contextual curta junto da ação, sem outra faixa permanente de largura total.
- Ao mover a câmera para uma cidade, considerar as áreas ocupadas pelo HUD e pelas gavetas.

### 5.2 Tablet e telas próximas de 4:3

- Aproveitar espaço para um painel lateral maior, sem ampliar proporcionalmente todos os botões.
- Permitir exibir veículo e carga juntos quando houver espaço real.
- Aumentar a separação das cartas antes de aumentar exageradamente seu tamanho.
- Manter os mesmos nomes, caminhos de navegação e regras dos celulares.

### 5.3 Formatos largos, recortes e mudança de área útil

- Base atual: canvas 1440 × 810, `canvas_items` e `expand`; preservar como ponto de partida.
- Calcular área segura para controles, inclusive após retomada, mudança de janela e alterações das barras do sistema.
- Não transformar margens vazias de telas largas em painéis adicionais obrigatórios.
- Escolher layout pela largura e altura úteis e pela escala de texto, sem depender apenas de um modelo de aparelho.
- Adotar como meta alvos de toque equivalentes a cerca de 48 dp; comprovar a equivalência no aparelho. Um botão de 64 unidades Godot não garante esse tamanho físico.
- Paisagem é o modo de jogo planejado. Se houver janela estreita ou retrato durante transição, preservar navegação e saves; não prometer uma versão completa em retrato nesta etapa.

## 6. Mapa, cidades, rotas e setores

### 6.1 Navegação e seleção

- Um toque seleciona; arrasto move; pinça amplia. Pequeno tremor do dedo não deve disparar viagem.
- A viagem exige confirmação com destino e custo; selecionar uma cidade não altera o estado do jogo.
- Após pinça, não tratar a retirada do último dedo como seleção acidental.
- A ação Localizar enquadra o veículo ativo na região visível, fora de painéis abertos.
- Exibir resposta imediata de seleção no toque; animações longas não devem impedir consulta do mapa.
- O usuário deve conseguir desfazer a seleção e fechar detalhes sem alterar recursos.

### 6.2 Rotas integradas à paisagem

- Substituir progressivamente segmentos retos por polilinhas com pontos de passagem desenhados sobre as estradas da arte.
- Armazenar geometria de apresentação separada da conectividade e dos custos das rotas.
- Não gerar trajetos arbitrários que atravessem lagos ou ignorem estradas visíveis.
- Rotas comuns: discretas; rotas disponíveis: destaque moderado; rota selecionada: ciano, contorno e custo visível.
- Desenhar indicação de sentido ou pulsação apenas na seleção, evitando movimentação contínua em todo o mapa.
- Diferenciar piso pavimentado e terra também por padrão/traçado, sem depender apenas da cor.
- Ao bloquear uma rota, mostrar o motivo no detalhe: combustível, piso incompatível, viagem usada ou condição do turno.

### 6.3 Cidades e veículos

- Etiquetas de cidade com fundo legível e borda temática; reduzir sobreposição entre cidades próximas.
- Em zoom distante, priorizar nomes importantes e a cidade ativa. Em zoom próximo, revelar detalhes adicionais.
- Aumentar a presença do veículo ativo com sombra de contato e anel de seleção bem definido.
- Se houver vários veículos na mesma cidade, distribuí-los em posições estáveis sem ocultar dono ou acesso aos setores.
- Mudanças de posição devem refletir o estado confirmado; a animação não pode cobrar combustível novamente.

### 6.4 Setores e propriedade

- Manter um marcador numerado por setor; cinza para sem dono.
- Selecionar cidade abre resumo: quantidade de setores, distribuição de donos e ações locais.
- Cada setor deve apresentar número, nome do dono, exploração usada/disponível e depósito quando permitido pelas regras.
- Setor próprio, adversário, sem dono e selecionado precisam de aparências diferentes.
- Informações não devem aparecer somente em uma legenda distante.
- Não oferecer retirada ou mostrar informação privada de depósitos adversários se as regras não permitirem.
- Conquista deve ter localização clara na interface; sua ativação depende da implementação do combate. Até lá, mostrar motivo visível de indisponibilidade no detalhe.

## 7. Turno e ação principal

### 7.1 Estado e hierarquia

| Contexto | Mensagem/ação prioritária | Comportamento |
| --- | --- | --- |
| Turno ainda não iniciado | Iniciar turno | Aciona compra e fila de revelação |
| Carta recebida | Toque para revelar | Bloqueia outras ações até concluir a aquisição |
| Ação disponível, ainda pode viajar | Escolher destino ou explorar | Rotas e setor próprio acessíveis |
| Já viajou, ação disponível | Explorar setor | Abre seleção local e explica custo |
| Ação usada | Gerenciar recursos / encerrar | Não oferecer nova exploração como habilitada |
| Mão acima do limite | Descartar excesso | Mostrar quantidade necessária e abrir mão |
| Operação inválida | Motivo específico | Explicação no painel que originou a operação |
| Passagem de jogador | Entregar dispositivo | Ocultar mão antes da confirmação do próximo jogador |

As mensagens acima são propostas de apresentação. Não mudam a ordem ou as permissões das regras existentes.

### 7.2 Descoberta e orientação

- Na primeira partida, apresentar uma orientação curta por etapa: iniciar, revelar, consultar cidade, explorar e retirar recursos.
- Incluir opção de dispensar e reabrir a ajuda.
- Evitar longos tutoriais obrigatórios ou instruções repetidas após o jogador conhecer o fluxo.
- Distinguir rótulos como `Explorar · 1 ação` e `Retirar recurso · livre` quando isso corresponder ao motor.
- Não deixar um botão prometer uma ação indisponível sem indicar o motivo.
- Manter o encerramento alcançável pelo polegar, mas afastado de descartar ou confirmar compra.

## 8. Veículo, carga e depósitos

### 8.1 Resumo do veículo

- Modelo e miniatura com dimensão suficiente para reconhecimento.
- Estrutura e tanque com número e barra simples, sem depender apenas do preenchimento.
- Indicador compacto de carga usada/capacidade.
- Toque no resumo abre uma gaveta; recolher devolve área ao mapa.

### 8.2 Gaveta de carga

- Lista ou grade de recursos com ícone, nome e quantidade.
- Exibir também recursos zerados, com menor ênfase e leitura preservada.
- Explicar visualmente que combustível da carga e combustível do tanque são estoques diferentes.
- Mostrar capacidade utilizada e o impedimento antes de retirar um recurso que não cabe.
- Abastecer usa reserva da carga; o botão informa quantidade e o resultado atualiza ambos os números.
- Reparo mostra custo, recuperação prevista e limite por turno conforme a regra implementada.
- Não desenhar slots vazios como se houvesse uma regra de inventário por encaixe: a carga atual é baseada em quantidades e capacidade.
- Equipamentos instalados terão seção própria quando o sistema estiver migrado, separada dos recursos consumíveis.

### 8.3 Depósitos

- Nome da cidade e número do setor sempre visíveis no detalhe.
- Separar claramente o estoque do setor e a carga do veículo.
- Confirmar retirada com resposta local e atualização imediata da carga.
- Se a carga estiver cheia, explicar a restrição no mesmo painel.
- Quantidade e direção de transferências futuras devem ser explícitas; não implementar depósito/devolução sem suporte no motor.

## 9. Cartas e compra

### 9.1 Mão recolhida

- Preservar o pedido do usuário: sem faixa preta atrás, centralizada e parcialmente escondida.
- Mostrar uma área superior suficiente de cada carta para reconhecer sua arte/título sem exigir leitura do texto completo.
- Ajustar sobreposição conforme a quantidade; nenhuma carta pode ficar impossível de tocar.
- Se a mão ultrapassar a largura útil, oferecer expansão de mão ou navegação horizontal clara.
- A navegação da mão não deve arrastar o mapa.
- Na passagem de jogador, ocultar todas as frentes antes de mostrar a confirmação do próximo turno.

### 9.2 Consulta ampliada

- Toque abre carta central, preservando proporção 2:3 e bordas completas.
- Permitir ler nome, momento de uso e efeito em texto da interface, além da imagem.
- Botões: Recolher, Descartar e, futuramente, Usar quando o motor oferecer o efeito.
- Descartar deve ser diferenciado de simplesmente fechar; considerar confirmação quando não for resolução de excesso.
- Fechar por Voltar do Android, controle visível ou toque fora, sem descartar automaticamente.
- Reduzir distração atrás da carta, mantendo a mão padrão sem painel opaco.

### 9.3 Aquisição e revelação — preservar o fluxo já implementado

- Toda aquisição passa por `WastelandGame.gain_card`.
- Apresentar verso correto, aguardar toque, virar e só então mostrar a frente.
- Depois da revelação, confirmação recolhe a carta para a mão e avança a fila.
- Manter confirmação e aquisição independentes do tempo da animação.
- Preservar fila por jogador e retomada após pausa/fechamento, sem compra duplicada.
- Não mostrar nome, efeito ou frente em tooltip/acessibilidade antes da virada.
- Geral: `geral.png`; evento: `evento-estrada.png`; corrida: `surpresa-corrida.png`.
- Equipamento e melhoria territorial usam exatamente `equipamentos-melhorias.png`, sem diferenciação adicional quando ocultos.
- Manter pré-carregamento dos quatro versos e a preferência Reduzir movimento.
- Melhorar o deslocamento até a mão e a leitura da carta, sem substituir as artes atuais por exemplos ou referências.

## 10. Histórico, mensagens e telas auxiliares

- Trocar o rodapé permanente de log por notificações curtas para ações recentes e histórico no menu.
- Mensagens de erro devem persistir o suficiente para leitura e ter explicação próxima da ação.
- Não esconder erros atrás de modais ou substituir feedback essencial antes de ser lido.
- Histórico com jogador, turno e ação; agrupar eventos relacionados e permitir rolagem.
- Nova partida deve explicar que substitui a partida local e preservar o comportamento de salvamento definido para o projeto.
- Preparação deve continuar aceitando 2–4 nomes; seed pode ficar em seção avançada.
- Tratar teclado virtual, nomes longos, campos vazios e foco de entrada no Android.
- Configurações propostas: texto, movimento reduzido, volume e vibração quando esses sistemas existirem. Não criar controles sem efeito.

## 11. Movimento, som e resposta tátil

### Tempos iniciais propostos

| Interação | Faixa inicial | Cuidados |
| --- | --- | --- |
| Resposta visual ao toque | Imediata | Não aguardar gravação ou animação longa |
| Abrir/recolher painel | 160–240 ms | Cancelar tween anterior ao inverter direção |
| Expandir carta | 180–240 ms | Não animar posição controlada por Container |
| Virar carta | 350–450 ms no total | Bloquear cliques duplicados; frente só após metade |
| Recolher aquisição | 200–300 ms | Estado já confirmado não pode duplicar aquisição |
| Destacar recurso alterado | 200–350 ms | Mostrar também valor numérico |

- Usar `Tween` para transições procedurais de UI; `AnimationPlayer` para sequências artísticas fixas com múltiplas trilhas.
- Não adicionar `AnimationTree` a transições simples de interface.
- Evitar tremor de tela em toda ação. Reservar para eventos relevantes quando combate estiver disponível.
- Movimento reduzido mantém as mesmas escolhas e resultados, com troca imediata ou transição discreta.
- Áudio de carta, botão e recurso é complementar; eventos devem continuar compreensíveis no silêncio.
- Vibração é opcional, desligável e depende de configuração Android apropriada; não adicionar permissão sem necessidade real.
- Não usar efeitos contínuos de poeira, brilho e partículas em todos os componentes do HUD.

## 12. Acessibilidade e ergonomia

- Validar contraste sobre metal e sobre o mapa, incluindo controles desabilitados.
- Nome, número ou padrão devem acompanhar as cores de jogador e setor.
- Disponibilizar leitura textual dos efeitos de cartas; texto rasterizado não é suficiente.
- Testar aumento de texto e nomes de 24 caracteres, sem cortar botões.
- Garantir foco visível e sequência coerente para teclado/controle, além de toque.
- Fornecer nomes acessíveis aos controles; cartas ocultas recebem descrição genérica.
- Não depender de hover, pressionamento longo ou gesto secreto para funções essenciais.
- Manter alvos de toque separados em ações de descarte, encerramento e confirmação.
- Garantir comportamento consistente do Voltar: fecha detalhe, recolhe gaveta e retorna ao mapa. Durante revelação obrigatória, não descarta nem ignora aquisição.
- Testar acessibilidade com recursos reais do Android; a existência de propriedades no Godot não comprova suporte completo em aparelho.

## 13. Arquitetura proposta no Godot 4.7

Esta estrutura é proposta, não um inventário de arquivos já existentes:

```text
godot/
  scenes/ui/
    game_hud.tscn
    top_bar.tscn
    vehicle_summary.tscn
    cargo_drawer.tscn
    city_panel.tscn
    sector_row.tscn
    hand_dock.tscn
    card_viewer.tscn
    card_reveal.tscn
    turn_handoff.tscn
    notification_stack.tscn
  themes/
    wasteland_theme.tres
  assets/ui/
    fonts/
    panels/
    icons/
  data/
    route-presentation.json
```

### Responsabilidades

- `main.gd`: coordenar telas, ação e navegação; reduzir a criação de toda a interface em um arquivo único.
- `game_state.gd`: continuar responsável pelas regras, recursos e revelações pendentes. Sem dependência de Control, texturas ou animações.
- `board.gd`: desenho, geometria de apresentação, enquadramento e entrada do mapa.
- Componentes de UI: exibir dados, emitir intenção por sinais e receber resultado do coordenador.
- Tema compartilhado: cores, fontes e estilos; evitar repetir ajustes em cada botão.
- HUD em `CanvasLayer` próprio se houver câmera/world transform na reorganização. O mapa atual usa transformação local de desenho; não aplicar um segundo deslocamento ao HUD.
- Sobreposições devem ter uma prioridade explícita: tabuleiro, HUD, detalhes, confirmação e revelação. Evitar dois modais concorrentes.
- A apresentação deve derivar permissões do motor ou de uma camada de consulta compartilhada. Evitar duplicar regras em vários botões.
- Usar containers para conteúdo e anchors para bordas/gavetas; animações devem agir em wrappers visuais para não disputar posição com o layout.
- Construir cenas reutilizáveis e editáveis no Inspector, sem impor uma reescrita integral do motor.

## 14. Assets necessários e reaproveitamento

| Material | Origem/estado | Trabalho planejado |
| --- | --- | --- |
| Mapa | Arte já no projeto | Preservar; ajustar contraste somente se necessário e com comparação visual |
| Frentes de cartas | Catálogo existente | Preservar; conferir legibilidade e importação |
| Versos | `assets/cartas/versos` e cópia Godot | Preservar PNGs e mapeamento; manter os quatro versos |
| Veículos | Assets existentes; há material adicional na pasta de origem | Inventariar dimensões, variantes e adequação ao tabuleiro antes de escolher |
| Recursos | Ícones do projeto React | Conferir presença no pacote Godot e legibilidade; copiar somente o necessário |
| Painéis e molduras | Acabamento ainda pendente | Produzir molduras modulares com centro limpo e borda temática |
| Fontes | Seleção pendente | Conferir licença e acentos; importar com tamanhos adequados |
| Ícones de navegação | Padronização pendente | Um conjunto coerente, com alvos de toque independentes da arte |
| Áudio UI | Pendente | Selecionar/produzir com licença e organizar em bus próprio |

Molduras rasterizadas devem usar `StyleBoxTexture` com recorte de nove regiões quando adequado, evitando esticar cantos e rebites. Formas simples podem continuar em `StyleBoxFlat`. Gerar somente as texturas realmente necessárias depois de aprovar uma tela representativa.

## 15. Desempenho e ciclo de vida Android

- Manter Compatibility como alvo inicial e validar efeitos nesse renderer; não depender de recursos exclusivos de Forward+ para a identidade da UI.
- Preservar importação das cartas limitada inicialmente a 1024 px e veículos a 512 px; revisar por caso com imagens reais na tela.
- Não pré-carregar todas as frentes do catálogo. Pré-carregar versos e carregar/cachear frentes conforme uso, com política de descarte mensurável.
- Conferir texturas com transparência, compressão e memória em aparelhos reais antes de definir formato final.
- Atualizar HUD por mudança de estado; evitar reconstrução de toda a árvore visual em cada pequena operação.
- Não usar `_process()` para consultar inventário ou estado de botões a cada frame.
- Evitar shaders de desfoque de tela cheia, muitas camadas translúcidas e efeitos permanentes.
- Reduzir redraws de rotas quando mapa/seleção não mudaram.
- Testar primeira abertura de cada carta e painel; medir travamentos de carregamento, além da média de FPS.
- Meta inicial a validar: 60 FPS no aparelho de referência e comportamento consistente em aparelho de entrada; definir eventual perfil de 30 FPS após medição, não como justificativa para travamentos.
- Não fixar orçamento de RAM ou tamanho de APK sem medir os assets e o build. Registrar baseline e regressões por etapa.
- Pausa, tela bloqueada e retorno devem preservar seleção importante, turno e compra pendente sem duplicação.
- Nenhuma compra ou ação deve ser confirmada exclusivamente por callback de animação sujeito a interrupção do sistema.

## 16. Backlog e sequência de execução

### Fase 0 — Baseline e especificação visual

**Prioridade: P0.**

- [ ] Capturar tela atual em celular 16:9, celular largo e tablet 4:3.
- [ ] Inventariar assets de UI, recursos, veículos e fontes/licenças.
- [ ] Medir área coberta, alvos de toque e textos ilegíveis no aparelho.
- [ ] Registrar os fluxos de turno, exploração, carga e revelação em vídeo curto.
- [ ] Produzir composição estática de uma tela de jogo e uma tela de cidade.
- [ ] Revisar a direção visual dessas telas antes de replicar o estilo no restante.

**Saída verificável:** referências comparáveis, lista de assets e layout alvo com hierarquia definida.

### Fase 1 — Estrutura e espaço para o mapa

**Prioridade: P0. Dependência: fase 0.**

- [x] Extrair componentes principais de `main.gd` para cenas de UI.
- [x] Criar tema compartilhado e tokens visuais.
- [x] Compactar topo; mover histórico/nova partida para menu.
- [x] Criar resumo do veículo e gaveta de carga.
- [x] Manter mão centralizada independentemente dos painéis.
- [x] Aplicar área segura e prioridades de sobreposição.
- [x] Criar passagem de dispositivo que oculte a mão.

**Saída verificável:** mapa mais livre, navegação completa e nenhuma mudança nas regras ou saves.

### Fase 2 — Clareza de ação, cidade e inventário

**Prioridade: P0. Dependência: fase 1.**

- [x] Criar estado visual da ação principal e orientação curta por contexto.
- [x] Reorganizar painel de cidade e linhas de setor.
- [x] Mostrar propriedade por nome, número e cor.
- [x] Separar tanque, carga e depósitos.
- [x] Exibir custos e motivos de bloqueio antes da tentativa.
- [x] Manter conquista desabilitada até o combate estar disponível.
- [x] Colocar erros e resultados dentro do painel pertinente.

**Saída verificável:** completar iniciar → revelar → explorar → retirar → abastecer → encerrar sem orientação externa.

### Fase 3 — Arte do mapa e acabamento

**Prioridade: P1. Dependência: fases 1–2.**

- [x] Aplicar fontes finais e molduras modulares.
- [x] Definir etiquetas e estados visuais de cidades/veículos.
- [x] Criar geometria de apresentação para cada rota.
- [x] Refinar destaque de rota selecionada e motivos de bloqueio.
- [ ] Validar densidade de marcadores por nível de zoom.
- [ ] Conferir que os assets continuam legíveis no menor aparelho alvo.

**Saída verificável:** comparação lado a lado com a referência com identidade temática consistente.

### Fase 4 — Cartas, transições e resposta

**Prioridade: P1. Dependência: fases 1–3.**

- [x] Refinar apresentação da mão e alvos de seleção.
- [x] Adicionar leitura textual acessível ao visualizador de cartas.
- [x] Melhorar chegada/recolhimento da aquisição sem alterar a fila persistida.
- [x] Padronizar tempos de painel, seleção e notificação.
- [x] Adicionar sons e vibração opcionais, se os assets e suporte estiverem disponíveis.
- [x] Aplicar movimento reduzido a todas as transições.

**Saída verificável:** interações consistentes, nenhuma informação oculta revelada antecipadamente e nenhuma duplicação de ação.

### Fase 5 — Validação em Android e ajustes

**Prioridade: P0 para considerar a modernização pronta. Dependência: fases anteriores.**

- [ ] Gerar APK de debug e instalar em aparelhos reais.
- [ ] Testar pelo menos um celular de entrada e um aparelho de referência; incluir tablet quando disponível.
- [ ] Medir frame time, memória, carregamentos e comportamento após suspensão.
- [ ] Corrigir texto, áreas seguras, toque e escala.
- [ ] Repetir a jornada sem ajuda com jogadores novos.
- [ ] Documentar comparação antes/depois e pendências reais.

**Saída verificável:** build testado em Android, evidências e checklist de aceite concluído. Testes desktop não substituem esta fase.

## 17. Plano de testes e critérios de aceite

### Matriz visual

| Cenário | O que conferir |
| --- | --- |
| 1280 × 720 / 16:9 | Composição base e textos sem cortes |
| Aproximadamente 20:9 | Alinhamento central da mão e painéis nas bordas |
| 960 × 720 / 4:3 | Tablet, inventário e diálogos sem extrapolar área útil |
| Aparelho com recorte | Botões fora do recorte e das áreas do sistema |
| Fonte ampliada | Rolagem, quebra de linha e acesso às ações |
| 2, 3 e 4 jogadores | Nome, cor, ordem e propriedade consistentes |
| Nomes longos e acentos | Sem cortes que impeçam identificar o dono |

Essas resoluções são cenários de teste, não uma lista fechada de aparelhos suportados.

### Jornadas obrigatórias

- [ ] Nova partida → carta inicial → iniciar turno → revelar compra.
- [ ] Selecionar cidade → conferir custo → cancelar sem gastar → confirmar viagem uma vez.
- [ ] Explorar setor próprio → ver depósito → retirar recurso → ver carga atualizada.
- [ ] Carga cheia → entender o impedimento sem perder recurso.
- [ ] Abastecer → reserva diminui e tanque aumenta corretamente.
- [ ] Consultar todas as 12 cidades e seus 35 setores, identificando os donos.
- [ ] Abrir carta → ler → recolher; distinguir isso de descartar.
- [ ] Receber várias cartas → revelar cada uma → concluir fila.
- [ ] Pausar/fechar no verso, durante virada e após revelar → retomar sem duplicação.
- [ ] Passar dispositivo → nenhuma frente da mão anterior ou seguinte aparece na tela de entrega.
- [ ] Arrastar/pinçar próximo de controles → nenhuma viagem, carta ou ação acionada por acidente.
- [ ] Alternar movimento reduzido → mesmos resultados e navegação.
- [ ] Voltar do Android em gaveta, detalhe, carta e revelação.

### Regressão e evidências

- Manter `godot/tests/smoke.gd`, `ui_smoke.gd` e `reveal_smoke.gd` passando; adaptar seletores à composição nova sem remover as verificações de comportamento.
- Comparar estado e recursos antes/depois de sequências equivalentes; não testar apenas a existência de botões.
- Capturar screenshots nos mesmos estados, resolução e seed para comparação visual.
- Registrar teste físico de toque, pausa e áreas seguras; injeção de eventos no desktop não comprova ergonomia.
- Testar saves atuais e compatibilidade de preferências. Se houver mudança de schema, escrever migração e teste antes de utilizá-la.

## 18. Limites e dependências

- Este plano moderniza apresentação e interação; não implementa novas regras por conta própria.
- Combate, hostis, conquista, corridas, efeitos de cartas e vitória ainda dependem da migração dos sistemas correspondentes.
- Os painéis desses sistemas podem ter estrutura visual planejada, mas não devem apresentar resultados ou valores fictícios como dados de uma partida real.
- A geometria das rotas será apresentação; conectividade, piso e custo continuam vindo das regras.
- Não introduzir multiplayer por rede, monetização, loja ou autenticação neste trabalho.
- Não substituir os saves ou remover a referência React durante a modernização.
- Se a produção de arte atrasar, manter a UI funcional com tema provisório e registrar quais assets faltam; não declarar acabamento final.

## 19. Skills para orientar a implementação posterior

| Skill GodotPrompter | Aplicação |
| --- | --- |
| `godot-ui` | Controls, containers, tema e foco |
| `hud-system` | Hierarquia da partida e feedback contextual |
| `responsive-ui` | Área útil, escala e adaptação de layout |
| `mobile-development` | Ciclo de vida e validação Android |
| `scene-organization` | Extração em cenas com responsabilidades claras |
| `input-handling` | Toque, arrasto, pinça e Voltar |
| `inventory-system` | Apresentação da carga e atualização após operações |
| `assets-pipeline` | Importação, molduras, fontes e memória de texturas |
| `2d-essentials` | Desenho de rotas, marcadores e camadas |
| `tween-animation` / `animation-system` | Transições e apresentação de cartas |
| `save-load` | Preservar aquisições e preferências na retomada |
| `godot-optimization` | Medir frame time, redraws e memória |
| `godot-testing` / `godot-code-review` | Verificação de comportamento e revisão final |

Consultar cada skill relevante antes de implementar a respectiva área. Adaptar seus padrões ao motor existente, sem trocar o inventário por slots ou reestruturar regras apenas para reproduzir exemplos da documentação.

## 20. Definição de pronto

A modernização estará concluída quando a composição estiver consistente com a referência, as jornadas disponíveis puderem ser concluídas por toque sem ajuda externa, os testes de regressão passarem e houver validação em Android físico. Sistemas ainda não migrados devem continuar claramente identificados. A entrega deve incluir screenshots comparáveis, lista de assets/fontes e licenças, resultados de desempenho medidos e pendências explícitas.
