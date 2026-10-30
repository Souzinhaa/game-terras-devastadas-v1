# Moto e mapa de Santa Cruz

## Moto

Asset existente `assets/moto-cima.png`. Carga 2, consumo 1, tanque 10, asfalto e terra. Vida máxima 6, defesa 4+, agilidade +1 e dois espaços adicionais, sem habilidade fixa inventada. A melhoria custa 5 sucatas locais e uma ação, como as demais, com a exceção confirmada de entregar a Moto com 10 combustíveis no tanque. Integridade atual e vidas restantes não renovam. Todos continuam começando e renascendo de Hatch. Veículo encontrado não recebe kit.

Saves v0.6 anteriores ganham apenas o perfil de combate da Moto quando ausente, mantendo RNG, veículos, mãos, tanques e vidas. O original fica preservado pelo fluxo normal de backup.

## Mapa atual — restauração solicitada

O usuário rejeitou a nova imagem. O fundo ativo voltou a `assets/mapa-expandido-v2.png` (1448×1086), mundo-base 2800 e coordenadas antigas de Santa Cruz (83%,13%). `mapa-principal-4k.webp` foi preservado como tentativa anterior e não é carregado pelo jogo. As regras e o asset da Moto continuam ativos.

A edição anterior tentou mover Santa Cruz para oeste de Leme, posição relativa conferida no [plano municipal](https://www.santacruzdaconceicao.sp.gov.br/wp-content/uploads/2023/06/pmsb_15.pdf). O mapa restaurado é esquemático e não pretende cartografia georreferenciada.

### Histórico da imagem rejeitada

Skill `imagegen`, ferramenta integrada, usando `mapa-expandido-v2.png` como referência. Primeira edição moveu o núcleo urbano do nordeste para (34%,22%), removeu o anterior e refez os acessos. Segunda edição refinou vegetação, construções e vias. A ferramenta entregou 1448×1086 nas duas tentativas mesmo com pedido de 4K; o arquivo final foi ampliado com interpolação bicúbica para 4096×3072 e comprimido em WebP com qualidade 0,95 (cerca de 3,1 MB). Isso não equivale a detalhe nativo 4K nem preserva detalhe ilimitado em ampliações extremas.

Prompt final usado com a ferramenta integrada:

> Edit this 4096x3072 image at its FULL ORIGINAL 4096x3072 pixel resolution; do not reduce the output dimensions. This image was enlarged; refine/reconstruct the fine painterly detail of rooftops, individual trees, field textures, road verges and river edges so the result is genuinely sharp and detailed for zooming in. Preserve exact layout and exact 4:3 framing, same colors and style, and all city/road/river positions. NO TEXT, labels, markers, new towns, borders or UI. Santa Cruz town at x34%,y22% stays west of Leme at x52%,y29%, original northeast x83%,y13% remains countryside. Preserve the North-South main road along x50% connecting towns y12%,29%,46%,65%,85% and western towns x18% y31%,50%,65%,85%, eastern towns x86% y48%,68%. Only improve high-resolution detail and clarity; do not alter road topology or geography. Output MUST retain original input size 4096x3072. Detailed post-apocalyptic Brazilian countryside aerial painted game board.
