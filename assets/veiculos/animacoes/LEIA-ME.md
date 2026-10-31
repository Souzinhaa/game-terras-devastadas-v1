# Veículos andando — loop simples

## Integração Godot vigente — 30/10/2026

Runtime em `godot/assets/vehicles/animacoes`, controlado por `godot/scripts/vehicle_art.gd`. Consultar `godot/CONTEXT.md` a partir da raiz do repositório.

O Godot usa spritesheet com AtlasTexture e AnimatedTexture, não APNG/WebP animado. As regiões são calculadas pelo tamanho efetivo importado dividido em 6 colunas e 4 linhas, pois a importação pode reduzir a folha. Pickup mapeia para a pasta `caminhonete`; sua arte parada é `picape-lateral.png`.

A animação lateral aparece no resumo ao viajar; a peça no mapa percorre a polilinha de apresentação em paralelo. Movimento reduzido elimina o deslocamento animado. Não mover o estado lógico, gastar combustível ou sortear evento dentro da animação.

Cinco animações de 24 quadros, 20 fps e 1,2 segundo. Veículo parado no centro, voltado para a esquerda, com balanço, discos das rodas girando e fumaça periódica nos pneus. Mova o objeto pelo mapa no código do jogo.

## Arquivos
- `*-loop.webp`: WebP animado com transparência, para interface web.
- `*-loop.png`: APNG animado com transparência.
- `*-spritesheet.png`: 6 colunas × 4 linhas; cada célula mede 960 × 640.
- `frames/`: PNGs RGBA individuais, de 00 a 23.
- `*-preview.gif`: prévia com fundo escuro; não usar como asset transparente.
- `manifest.json`: dimensões e tempos.

## Integração
Percorra os quadros de 0 a 23 e retorne ao 0 a cada 50 ms. Use ordem por linhas, da esquerda para a direita. Preserve proporção e transparência; não recorte cada quadro automaticamente, pois isso altera o ponto de apoio. Para andar à direita, espelhe o objeto inteiro horizontalmente, incluindo a fumaça. Em repouso, pare a animação e o efeito de fumaça. No React, a versão WebP pode ser usada em um elemento img; para controlar pausa e velocidade, use a folha de sprites em canvas ou no motor do jogo.

Animação procedural construída sobre as ilustrações aprovadas, sem regenerar a carroceria. O giro está concentrado nos discos internos das rodas para preservar os para-lamas e a sobreposição do piloto. É um loop estilizado simples, não uma simulação física.
