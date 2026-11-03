# Fundo da tela inicial — integração de 03/11/2026

Origem: pacote fornecido pelo usuário em `assets/tela_inicial/`. Artes, carro e mix sonoro existentes foram preservados. O OGV já inclui a faixa sincronizada; o jogo não toca o mix externo nem os impactos separados.

Runtime: `video/fundo_godot_v2.ogv`, Theora/Vorbis, 1280×720, 24 fps, 18 segundos. Poster: `assets/fallback.jpg`. Cena/script adaptados do exemplo do pacote para visibilidade, volume de efeitos, pausa e movimento reduzido. `INTEGRATION_SOURCE.md` preserva o contexto original anterior à integração; o estado atual está em `godot/docs/START_SCREEN_BACKGROUND.md`.

A revisão V2 corrige o cenário para a direita enquanto o carro aponta para a esquerda; o reenquadramento do carro permanece mais lento que a estrada. O hostil usa oito poses, a 12 fps, em vez de uma imagem deslizando. Impactos e áudio continuam em 6 e 13 segundos.

Os oito quadros do hostil foram criados com a ferramenta integrada `image_gen`, usando o `assets/tela_inicial/assets/hostil.png` do pacote como referência, sem substituir esse original. Atlas e script de composição reproduzível estão em `assets/tela_inicial/revisao/`. O script usa Pillow/NumPy/FFmpeg apenas na produção; não são dependências do jogo. A licença/direitos do acervo fornecido permanecem aplicáveis; não foi atribuída uma licença externa inexistente.

Prompt final do atlas: edição do hostil original, preservando capuz, óculos, lenço, armadura, botas e pé de cabra; exatamente oito poses de caminhada para a direita em grade 4×2, 1536×1024, fundo transparente, corpo inteiro com escala e linha do chão constantes, pernas alternando contato/passagem e braços acompanhando o passo; mesmo estilo ilustrado e paleta, sem textos, molduras ou cenário. Geração pelo modo integrado, não CLI.
