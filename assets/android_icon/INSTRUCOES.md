# Ícones de launcher — Terras Devastadas

## Arquivos e campos

| Campo da referência | Arquivo | Dimensões |
|---|---|---|
| Main | `main-192.png` | 192 × 192 px |
| Adaptive Foreground | `adaptive-foreground-432.png` | 432 × 432 px |
| Adaptive Background | `adaptive-background-432.png` | 432 × 432 px |
| Adaptive Monochrome | `adaptive-monochrome-432.png` | 432 × 432 px |

## Como usar

1. Selecione cada PNG no campo correspondente da ferramenta que mostra esses quatro campos.
2. Use o Main como imagem completa do ícone. Ele já inclui fundo opaco.
3. No ícone adaptativo, combine o Foreground transparente com o Background opaco. Não recorte nem amplie o Foreground: suas margens fazem parte do arquivo para acomodar as máscaras do launcher.
4. Use Monochrome como camada de uma só cor com transparência; a plataforma pode aplicar a cor do tema. Não use a versão colorida nesse campo.
5. Confira a prévia circular e a quadrada arredondada da ferramenta antes de exportar.
6. Gere os recursos finais pela ferramenta do seu projeto, mantendo os quatro arquivos de entrada separados. Os PNGs deste pacote não substituem por si só o manifesto e os recursos gerados da aplicação.

## Para a IA que integra no jogo

Configure os ícones do aplicativo usando exatamente o mapeamento acima. Preserve as dimensões, o canal alfa das camadas Foreground e Monochrome e o fundo opaco das outras duas imagens. Não aplique máscara circular ou cantos arredondados diretamente nos arquivos adaptativos. A imagem `preview.png` serve apenas para conferência e não deve ser usada como ícone final.

## Arte

Emblema original com veículo blindado, engrenagem enferrujada e estrada rachada; cores de aço escuro e laranja queimado, seguindo a estética pós-apocalíptica do jogo. Sem texto para manter a leitura em tamanho reduzido.
