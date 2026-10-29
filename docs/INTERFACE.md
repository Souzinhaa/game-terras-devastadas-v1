# Redesenho da interface — frontend-design

Direção escolhida: **Organic**, conforme a skill solicitada. O jogo apresenta decisões densas de território e inventário; o redesenho usa um atlas de areia e musgo para organizar essas informações sem inventar recursos ou regras.

## Sistema visual

- Areia `#E8DCC7`, aveia `#D4B895`, sálvia `#8B9D83`, musgo `#606C38`, terracota `#C66B3D`, argila `#B08B6E` e ocre `#C08E3A`, com variações terrosas para contraste.
- Títulos serifados com fontes locais Palatino/Iowan/Book Antiqua e corpo Avenir/Trebuchet. Não depende de Google Fonts, CDN ou rede.
- Superfícies arredondadas, grão SVG de baixa opacidade e mapa com moldura de atlas. Assets originais preservados, sem geração ou edição de imagens.
- Valores, nomes, posições, cartas, participantes de combate e resultados vêm do estado real. Ícones são SVG; os antigos glifos usados como ícones foram removidos.

## Navegação e estados

Navegação fixa para mapa, veículo, cartas e histórico, com nomes acessíveis e foco visível. É navegação pela página, não troca de regras ou fases. Faixa de jogadores mostra pontuação, modelo e cidade reais. Painel duplicado de pontuação inferior foi ocultado.

Cidades selecionadas e posição atual têm tratamentos separados. Ligações legais recebem destaque; bloqueios e terra mantêm padrões distintos. Zoom, arrasto e inspeção continuam disponíveis. No celular, painéis usam uma coluna e os atalhos evitam percorrer toda a página.

Combate mostra participantes e integridade individual; o último registro reproduz o resultado do motor sem simular dados extras. Mãos permanecem ocultas após passagem; a visualização dos versos usa somente a quantidade real de cartas.

## Movimento

- 300–500 ms nos controles, painéis, revelação de cartas e alterações numéricas.
- Marcador de viagem percorre a ligação real em 600 ms; destaque termina em 900 ms. É somente visual: não adia o comando nem altera custo/RNG.
- Resultado da ação usa mensagem do log ou confirmação específica da operação, fechável e temporária. Erros continuam persistentes.
- Nenhuma animação contínua, parallax ou rolagem de dado fictícia. `prefers-reduced-motion: reduce` remove transições, animações CSS, rolagem suave e marcador de viagem.

## Validação

49 testes de motor/persistência e build TypeScript/Vite aprovados. Seis cenários Chrome cobrem fluxo de quatro jogadores e reload, móvel/importação inválida, mapa/zoom, migração com excesso, navegação/movimento reduzido e combate. Capturas de setup, desktop, móvel e combate ficam em `test-results/` (ignorado pelo Git). Capturas de setup/desktop/móvel inspecionadas.

O motor, o schema de save, os números dos veículos e as regras não foram alterados. Permanecem as limitações funcionais em `REBALANCEAMENTO_V05.md`; não houve playtest humano ou auditoria completa de acessibilidade.

## Mapa em tela cheia e controles sobrepostos

Atualização solicitada: a partida agora ocupa `100vw × 100dvh`, com `mapa-principal.png` no plano de fundo interativo. A proporção original 1205/1306 é preservada no canvas; zoom e arrasto permitem navegar pela arte de formato vertical em telas largas. A página não rola durante a partida. O setup continua como formulário separado.

Mantida a direção Organic: superfícies flutuantes de areia/musgo, cantos arredondados e iconografia SVG própria de assentamento, bandeira, rota, carro, ferramentas, cartas, combustível, carga e escudo. Não há emojis ou regras extraídas dos pixels da imagem.

A barra inferior abre um painel de cada vez: territórios, rotas, veículo, cartas, administração ou histórico. Selecionar uma cidade abre os setores dela. O botão fechar ou Escape recolhe o painel; combate pendente permanece visível até ser resolvido. Viagem recolhe as rotas para mostrar o deslocamento. O resumo compacto do veículo mantém tanque, carga e integridade disponíveis sobre o mapa.

Os seis cenários Chrome passaram novamente, incluindo verificação de que a área do mapa ocupa exatamente 1440×1000 em viewport desse tamanho, abertura do painel por marcador de cidade, fechamento por botão/Escape, responsividade móvel, fluxo hot-seat e preservação de saves. Build aprovado. Capturas desktop, móvel e painel territorial foram inspecionadas. Nenhuma regra, schema ou asset original foi alterado.

## Veículos como peças do tabuleiro

Os veículos agora ficam em `BoardVehicles`, uma camada própria sobre o mapa: imagens reais das quatro classes em tamanho de peça, nome e número do jogador, destaque da vez e indicação de inutilização. As miniaturas pequenas dentro das etiquetas de cidade foram substituídas por essas peças clicáveis. Selecionar o próprio carro abre o veículo; selecionar o adversário inspeciona a cidade, sem revelar sua mão.

Quatro vagas visuais estáveis por cidade acomodam todos os jogadores, sem alterar a posição de cidade do domínio. As vagas são apenas offsets de renderização. Viagem e fuga bem-sucedida animam a peça identificada do jogador entre as posições, com orientação de deslocamento, em vez de um ponto luminoso. A animação não adia o motor, cobra combustível extra ou altera o save. Movimento reduzido posiciona imediatamente no destino. Zoom e pan continuam movendo mapa, marcadores e carros juntos.

Build aprovado. Os seis cenários existentes de interface continuam validados; cenário adicional verifica as imagens das quatro classes, ausência de interseção das peças na mesma cidade, seleção do carro e atualização de cidade/movimento sem duplicar peças. Captura `test-results/board-cars.png` inspecionada. Nenhuma alteração de regra ou schema.

## Contraste e navegação — fundo expandido v2

Substituído somente o fundo ativo por `assets/mapa-expandido-v2.png`; o mapa original foi preservado. A imagem nova não tem textos, legendas, marcadores ou carros embutidos. Dimensão real 1448×1086; geração integrada e prompt completo em `MAPA_V2_PROMPT.md`. A área navegável tem no mínimo 2800×2100 a 100% e cresce conforme a viewport. Não confundir dimensão do canvas de jogo com resolução da imagem gerada.

Controles flutuantes agora usam fundos opacos; nomes dos jogadores e dos carros têm contraste forte. O contorno dos carros acompanha o alpha da imagem, com borda clara e acabamento escuro; a base de estacionamento também ficou escura. As linhas do grafo têm espessura estável em pixels, evitando faixas largas ao ampliar o mundo.

Zoom expandido para 50–250%, barras de rolagem visíveis, rolagem horizontal/vertical e arrasto por mouse/toque. O zoom preserva o centro da câmera em vez de voltar para a cidade selecionada. Botão “Centralizar no veículo” retorna à peça atual, incluindo o deslocamento da vaga. A proporção da arte é mantida.

Os sete cenários anteriores de interface passaram com a nova arte e contraste. Um oitavo cenário passou verificando área de rolagem maior que a viewport, wheel nos dois eixos, arrasto, preservação da câmera no zoom, recenter, superfícies opacas, contorno do carro e limites 50/250%. Build aprovado. Regras, seed, cidades, rotas e schema de saves preservados.
