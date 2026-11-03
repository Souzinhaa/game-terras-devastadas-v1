# Assets da revisão de interface — 03/11/2026

`terrain.png` (1448×1086) e `margins.png` (1536×1024) foram produzidos com a ferramenta integrada **image_gen**, nesta tarefa, para Terras Devastadas. O terreno é uma revisão da imagem original do projeto `assets/mapa-terreno-alinhado-v3.png`, preservada. Não foram incorporados assets de Wingspan ou de outros jogos. Os direitos preexistentes da imagem de referência continuam aplicáveis; não se atribui uma licença de terceiros à geração.

A primeira proposta campestre e a proposta de novos veículos foram rejeitadas pelo usuário e **não** são consumidas pelo jogo. Os veículos, animações e cartas do acervo original foram mantidos. A prioridade final passou a ser layout, interação e redução de texto; as imagens integradas conservam solo seco, ruínas e vegetação castigada.

`icons/explore.svg`, `attack.svg` e `depot.svg` foram escritos como vetores nesta alteração. Os outros SVG são cópias do conjunto vetorial do projeto, para permitir contraste adequado sem alterar os originais. Não foi obtida uma biblioteca externa.

Fontes existentes: Barlow Regular e Semibold, SIL OFL 1.1, com licença em `../ui/fonts/Barlow-OFL.txt`. A fonte condensada foi retirada do papel de título padrão, preservando o arquivo original.

O [inventário](inventory.json) associa IDs de cartas, peças e controles a arquivos, origem, dimensões, tamanho e decisão de manutenção. A presença nesse inventário não valida efeitos de cartas nem Android físico.

## Prompts finais usados no modo integrado

Terreno — referência: `godot/assets/mapa-terreno-alinhado-v3.png`:

> Edit this production top-down game board terrain. PRESERVE EXACTLY its aspect ratio and the centers of all existing 12 city clusters. This remains a harsh POST APOCALYPTIC Brazilian wasteland, compatible with gritty battered Mad Max survival vehicles. Upgrade to premium painted board game illustration: reduce micro grain and noisy foliage, simplify into deliberate readable masses while retaining dry cracked ochre soil, desaturated dead olive vegetation, scattered burned patches, ruined gray concrete city districts, crumbled factories, abandoned industrial structures, collapsed rusting roofs. Mood: dramatic dusty late afternoon, warm weathered ochres, charcoal ruins, sparse muted sage, slight cool shadows. Cities clearly ruined and distinctive, no intact cheerful villages, no bright flowers, no lush idyllic greenery. Painterly but mature and dangerous. Keep city shapes and locations as in source so live game markers still align. NO roads (all roads drawn dynamically), no text, no markers, no numbers, no border, no UI, no cars, no humans. Do not change composition or move cities. Full bleed terrain asset, not a mockup.

Margens — referência: `godot/assets/premium/terrain.png`:

> Create a companion background terrain texture for this game map. Use reference ONLY for matching painted style, palette, scale and overhead perspective. Wide landscape panorama 3:2. Harsh post-apocalyptic wasteland, cracked dry rusty ochre earth, scorched patches, muted dead olive scrub in wide masses, few leafless trees, tiny concrete rubble. Muted orange brown and cool gray shadows, dusty late afternoon. NO city clusters or settlements anywhere, no roads, no lakes or rivers, no cars, no people, no text, no markers, no frame. Low detail low contrast painted terrain used as expanded margins around the reference board. Match reference colors so seamless stylistic transition. Not cheerful, not lush, not pixel art.
