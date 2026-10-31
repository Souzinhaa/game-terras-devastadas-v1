# Integração das imagens — Terras Devastadas

## Runtime Godot — atualizado em 30/10/2026

Consultar `godot/CONTEXT.md` a partir da raiz. A cópia usada pela engine está em `godot/assets/cards/versos`; `godot/scripts/card_reveal.gd` centraliza o resolvedor e pré-carrega os quatro versos.

Aquisições usam `WastelandGame.gain_card` e a fila persistida por jogador: verso, toque, virada e confirmação. O mesmo fluxo atende carta inicial, compra, transferência e carta pendente de quem reage fora do turno. Não ativar equipamentos/efeitos apenas porque seus versos estão disponíveis.

Implemente os assets deste pacote no projeto existente. Inspecione primeiro a estrutura, os tipos de carta e o componente de renderização; adapte os caminhos ao projeto, sem reescrever mecânicas.

## Mapeamento obrigatório

| Prefixo de exemplo | Tipo | Cor | Arquivo em assets/cartas/versos/ |
|---|---|---|---|
| G | Geral | Laranja | geral.png |
| V | Evento de Estrada | Amarelo | evento-estrada.png |
| E | Equipamento | Azul | equipamentos-melhorias.png |
| T | Melhoria Territorial | Azul | equipamentos-melhorias.png |
| R | Surpresa de Corrida | Vermelho | surpresa-corrida.png |

**Equipamentos e Melhorias Territoriais devem referenciar o MESMO arquivo, sem qualquer alteração, legenda, ícone ou tonalidade adicional que permita distingui-los quando ocultos.** O JSON acompanha esta tabela; os prefixos são exemplos fornecidos, confirme a representação real no código. Não crie um verso verde.

## Implementação

1. Copie assets/cartas/versos para a pasta pública ou de assets utilizada pelo projeto. Ajuste URLs conforme o bundler.
2. Centralize a resolução do verso por tipo em uma função ou configuração. Use o mesmo resolvedor em baralhos, mãos ocultas, cartas em animação e demais estados virados para baixo.
3. Preserve a proporção nativa das imagens (2:3), sem esticar nem cortar títulos ou bordas. Use tamanho responsivo, aspect-ratio: 2 / 3 e object-fit: contain. Todas as cartas devem ter as mesmas dimensões de exibição.
4. Quando a carta estiver revelada, continue exibindo sua frente atual. Os cinco exemplos em referencias/frentes são referências originais, não representam o baralho completo e não devem substituir outras cartas.
5. Não revele nome, ID, efeito ou imagem de frente em tooltips, aria-labels ou elementos acessíveis de cartas ocultas. Use descrição genérica; o nome do baralho pode ser exibido se permitido pelas regras atuais. Em multiplayer, respeite a visibilidade já implementada e não envie dados secretos a clientes não autorizados.
6. Pré-carregue os quatro versos para evitar flashes durante a virada. Se houver animação, respeite preferência por movimento reduzido.
7. Preserve o estilo industrial original: metal escurecido, rebites, ferrugem e tipografia desgastada. Não aplique filtros que alterem as cores dos versos.
8. Não altere regras, custos, atributos, efeitos ou composição dos baralhos com base nestas imagens.

## Referência de tela

referencias/tela-conceitual.png é somente uma referência visual: mapa ocupa todo o fundo, HUD flutua sobre ele. Não a use como fundo funcional com textos embutidos, nem extraia dela valores e regras. Este pacote não contém os arquivos de veículos nem o repositório completo.

## Validação de entrega

- Conferir G, V, E, T e R virados para baixo e depois revelados.
- E e T devem resultar na mesma URL de imagem e ter apresentação idêntica.
- Conferir os quatro arquivos sem erros 404, mantendo bordas completas em diferentes resoluções.
- Conferir que nome e efeito de cartas ocultas não aparecem por hover ou leitor de tela.
- Executar build e verificações relevantes disponíveis no projeto.
- Informar arquivos alterados e resultado das verificações; atualizar documentação de assets se existente.

## Escopo e origem

Quatro versos gerados para este jogo, cinco frentes originais fornecidas e uma tela conceitual. Imagens PNG preservadas sem reprocessamento. As artes não incluem sangria ou perfil de cor de gráfica: para impressão física, preparar especificações próprias antes de produzir.
