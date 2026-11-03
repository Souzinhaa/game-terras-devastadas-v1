# Revisão V2 — direção de marcha e caminhada

03/11/2026. Os arquivos originais em `assets/tela_inicial/assets`, `audio` e `video` não foram sobrescritos. O Godot usa a revisão `godot/assets/menu_background/video/fundo_godot_v2.ogv`.

- Cenário para a direita, Hatch apontando para a esquerda: marcha à frente. O reenquadramento do carro nunca ultrapassa o movimento da estrada; `build_v2.py` verifica essa condição para todos os frames.
- Oito poses de caminhada do hostil, 12 fps, em vez da figura única deslizando. Barricada em 6 s e hostil em 13 s; áudio WAV original preservado.
- Carro: 24 PNG do pacote, sem geração/substituição. Só o atlas de caminhada é novo.
- [Prévia corrigida](output/previa_v2.mp4), [vídeo Theora](output/fundo_godot_v2.ogv) e [medidas de movimento](output/motion-check.json).
- Produção: `build_v2.py --ffmpeg CAMINHO_DO_FFMPEG`. Pillow/NumPy e encoder são ferramentas de produção, sem dependência no jogo. Não executar o script original `source/build.py` para substituir esta revisão.

Validação Windows/Godot 4.7.2: 59 verificações de menu/reprodução, três ciclos completos do vídeo V2, configurações/retomada/LAN preservadas, exportação PCK do preset Android com os recursos carregados diretamente do pacote. Isso não é um APK nem validação em Android físico. Áudio testado com driver Dummy, sem avaliação auditiva em aparelho.

## Atlas gerado

`hostil_walk.png`, 1536×1024, produzido com `image_gen` integrado, referência `assets/tela_inicial/assets/hostil.png`, original preservado. Sem biblioteca ou personagem de terceiros incorporado. Aplicam-se os direitos do acervo de referência. As células são recortadas como frames de animação na composição do vídeo.

Prompt usado:

> Edit this supplied game character into a production WALK CYCLE sprite sheet. Preserve EXACTLY this post-apocalyptic raider identity, wrapped hood, goggles, scarf, brown patched clothes, shoulder armor, boots and crowbar. Keep gritty illustrated ink-and-painted style and same palette. This is animation frame artwork, not new character design. Make exactly EIGHT frames in regular 4 columns by 2 rows on a 1536x1024 transparent canvas. Each cell is 384x512. Full body entirely within each cell, equal character height about460px, same head height and ground baseline, generous padding, no overlap. Perfect SIDE VIEW facing RIGHT in every frame, walking to RIGHT, weapon in hand. Read in row-major order: right leg forward contact, down/passing, left leg forward rising, left leg forward contact, down/passing opposite, right leg rising, passing, return before initial contact. Visibly alternate the legs and swing arms through a clear believable continuous walk cycle, distinct contact and passing poses, preserve feet and hands, no changes in equipment between frames. Keep head and torso nearly stationary vertically and consistent size. Transparent background only, no ground, no shadows, no labels, no text, no grids, no borders. Do NOT draw eight copies of one standing pose.
