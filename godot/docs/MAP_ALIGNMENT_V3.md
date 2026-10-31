# Mapa alinhado aos trajetos do jogo

30/10/2026. A pedido do usuário, a arte foi adaptada às rotas existentes, sem mover cidades, custos ou polilinhas anteriores. A única conexão nova autorizada é Santa Cruz da Conceição ↔ Rio Claro por terra.

## Implementação

- `assets/mapa-terreno-alinhado-v3.png`: novo terreno, com povoações compactas e sem rodovias intermunicipais pintadas.
- `assets/mapa-margens-sem-rotas-v3.png`: campo decorativo sem cidades nem estradas, cobrindo os cantos. Evita sugerir conexões externas ao tabuleiro.
- `board.gd` desenha as superfícies de asfalto e terra usando `route_points`, a mesma geometria da seleção, do clique e da animação de viagem. A estrada permanece visível mesmo quando indisponível; somente o realce depende das condições de viagem.
- As duas artes foram geradas com a ferramenta integrada de imagem; os originais foram preservados. A precisão das conexões vem da camada desenhada pelo Godot, não da capacidade de geração de coordenadas exatas em uma imagem.
- `santa-cruz-rio-claro-terra` foi adicionada aos contratos JSON nativo e React, com polilinha editorial contornando o norte. Agora são 19 rotas. Usa consumo e restrições rurais existentes: Moto, SUV e Caminhonete; Hatch e Sedã não podem usar terra. Não há cruzamento funcional fora das cidades só porque linhas se cruzam no desenho.
- Saves preservados; não houve migração ou regravação da partida do usuário. A nova conexão entra no catálogo de rotas compartilhado também para partidas já existentes.

## Verificação

`data_validation.gd` verifica toda rota com geometria de superfície/seleção e extremos nas cidades corretas; testa a nova estrada nos dois sentidos para os cinco modelos. Testes renderizados cobrem enquadramento, zoom, prévia e confirmação com métricas de S23 simuladas no Windows. Ainda requer confirmação visual no Android físico.

## Prompts usados

Terreno:

+> Use case: precise-object-edit. Edit target/reference: attached existing top-down wasteland board-game map. Create a new clean terrain illustration in exactly 4:3 aspect ratio, preferably 1448x1086. Preserve the warm muted ochre/olive aerial painted satellite-map aesthetic, weathered small Brazilian towns, scattered woodland and farms. CRITICAL REMOVE ALL INTERCITY ROADS, highways, thin dirt tracks, bridges, straight linear field boundaries resembling roads and river crossings from the entire image. They will be drawn precisely by the game engine afterward. Keep local streets confined within very small settlements only, not extending outside. Reorganize the settlements so their centers are at these exact normalized percentage coordinates (x from left,y from top): Pirassununga(48,12), Santa Cruz(83,13), Rio Claro(18,31), Leme(52,29), Santa Gertrudes(17,50), Araras(51,46), Conchal(86,48), Cordeiropolis(18,65), Limeira(50,65), Artur Nogueira(87,68), Piracicaba(17,85), Americana(49,85). Names are location specifications ONLY: do not render any text or labels. Settlement footprints must be compact, maximum diameter 7% of canvas width, centered on those coordinates, no additional major cities. All areas between settlements should be low-detail continuous dry earth, patchy grass and scattered woodland suitable for drawing roads across; avoid large lakes and rivers that would obstruct future routes. Use a single small irregular pond in the far lower-right margin if desired. Perfect vertical top-down orthographic view, flat continuous terrain to every edge, no perspective, no UI, no icons, no pins, no text, no borders, no compass, no vignette. This is functional game terrain; visual roads must be entirely absent outside settlement footprints. Preserve geography coordinates, not the old incorrect road network.

Margens:

+> Use case: background-extraction / terrain companion generation. Reference image: attached top-down wasteland game terrain, use only its palette and brush texture. Create a new very wide landscape 21:9 panoramic background of continuous low-detail dry ochre earth, irregular muted olive scrub and scattered woodland, small subtle irregular fields. Same vertical top-down orthographic illustrated aerial style and visual scale as reference. CRITICAL NO cities, villages, houses, buildings, roads, trails, pathways, bridges, rivers, lakes, large field boundary lines, text, icons, labels, vignette or borders anywhere. Entire image must be uninterrupted countryside terrain and woodland clearings, all the way to every edge, evenly lit, no focal subject. This will fill decorative overscan margins behind a separately positioned gameplay map and must not imply extra settlements or connections.
