# Terras Devastadas — Ícones de consumíveis e recursos v1

## Escopo
Aplicar seis ícones: combustível, sucata, munição, pneu, bateria e água. São os recursos identificados no catálogo de cartas existente. “Consumíveis” é a organização visual deste pacote: não significa que todos tenham ação de consumo disponível. Não criar novas ações, receitas, preços ou usos para água, bateria ou pneu.

O pacote complementa Marcadores_Terras_Devastadas_v01. Os ícones deste pacote identificam o objeto; os marcadores anteriores indicam o modificador. Exemplo: galão ao lado da quantidade de combustível; marcador âmbar +2 somente quando uma carta adiciona combustível. Quantidade atual e ganho são informações diferentes.

## Entregáveis
- svg/: seis desenhos vetoriais, sem fontes, fundo externo transparente, viewBox 256 × 256.
- png/32, png/64, png/128, png/256: seis imagens RGBA por tamanho, 24 PNGs no total.
- manifest.json: identificadores semânticos, nomes, cores e caminhos.
- previa.png e galeria.html: consulta visual; a galeria abre offline.

## Identidade
| ID do pacote | Recurso | Imagem | Cor |
|---|---|---|---|
| combustivel | Combustível | Galão com gota | #DA9A18 |
| sucata | Sucata | Peças metálicas | #A6AAB3 |
| municao | Munição | Cartuchos | #BEA260 |
| pneu | Pneu | Pneu com sulcos | #596473 |
| bateria | Bateria | Bateria automotiva | #B4DF43 |
| agua | Água | Garrafa | #388FD7 |

As cores acompanham as famílias de recursos do pacote de marcadores. As silhuetas distinguem recursos sem depender apenas da cor. Três cartuchos no desenho representam o tipo munição; NÃO representam três unidades.

## Orientações para o Codex
1. Leia o projeto e localize inventário, tanque, depósito, custos de ação, detalhes de carta e histórico. Preserve o motor e o modelo de dados.
2. Copie as pastas de imagem para o diretório público de assets do projeto. Carregue manifest.json e adapte seus IDs aos enums já existentes (por exemplo fuel/scrap/ammo/tire/battery/water). Não renomeie IDs existentes, banco de dados ou saves para acompanhar os nomes em português.
3. Crie ou reutilize um componente ResourceIcon(resourceType, size, label). Use SVG para escala livre ou PNG 64 para exibição de 24–32 px em tela de alta densidade. Não recrie por emoji, nem distorça proporções.
4. Mostre quantidade como texto externo ao desenho. Exemplos: [galão] 8/12; [sucata] 2; custo [munição] 1. Em ganho/perda use sinal textual ou marcador de efeito associado. Não interprete figuras internas como quantidades.
5. Incluir alt/aria-label com nome e quantidade. Se o texto adjacente já descreve integralmente o recurso, imagem decorativa pode usar alt vazio. Tooltip/toque deve mostrar o nome. Quantidade zero precisa de texto legível; não depender somente de opacidade.
6. Exibir recursos na carga e depósitos conforme estado real. Combustível de viagem reside no tanque: não criar item de combustível na carga por causa da arte do galão. Preservar qualquer representação adicional que o projeto já tenha, sem inventar transferência.
7. Em custos, verificar recursos e capacidades antes de habilitar ação conforme regras existentes. Apresentação não efetua desconto. O motor aplica mudanças uma única vez.
8. Em ganhos, respeitar capacidade do tanque/carga/depósito e escolha de excedente. Não descartar nem transferir automaticamente só para ajustar a interface.
9. Não acrescentar consumo por terreno ou carga. Consumo base confirmado por viagem: hatch 1, sedã 2, SUV 2, caminhonete 3. Capacidades base de tanque 8/12/12/15 e carga 1/7/6/10 respectivamente; equipamentos modificam capacidades somente conforme regras existentes.
10. Integrar com os marcadores anteriores sem trocar significados: combustível atual difere de capacidade máxima; munição −1 é custo de ataque adicional, não penalidade permanente. Recurso instantâneo não vira bônus ativo.

## Referências de cartas para validação visual
- Combustível: G09 e V04 adicionam 2; V05 perde até 1. E07 aumenta capacidade, não fornece combustível.
- Sucata: G11 adiciona 2; V03 adiciona 1. E11 transfere até 1 na condição definida, não cria recurso.
- Munição: G12 adiciona 2; E01–E03 gastam 1 por ataque opcional. V10 escolhe 1 sucata OU 1 munição.
- Pneu: G13 e V09 adicionam 1.
- Bateria: G14 e V08 adicionam 1.
- Água: G24 adiciona 1. Não remove condição sem regra implementada.
- V07 perde 1 recurso da carga à escolha, não tanque ou equipamento.
Essas referências orientam apresentação; não recriar resolvedor a partir do texto.

## Aceitação
- Os seis tipos usam a imagem correta no inventário, tooltip, custos e histórico onde disponíveis.
- Salvar/carregar conserva quantidades e tipos; nenhuma alteração de save é necessária apenas pelos ícones.
- Ícones ficam nítidos sobre painel escuro e não têm retângulo de fundo; todos os PNGs têm transparência externa.
- Quantidade é texto separado; três cartuchos nunca geram três munições.
- Combustível aparece no tanque, capacidades e custos permanecem os mesmos.
- V10 não concede ambos os recursos; E07 não abastece automaticamente.
- Água/pneu/bateria não ganham ações de uso novas.

## Prompt pronto
“Leia contexto.md e manifest.json deste pacote de consumíveis. Integre as seis imagens nos componentes de recursos existentes, com adaptador para os IDs atuais e quantidade fora do ícone. Preserve o motor, regras, custos, capacidades e saves. Use assets transparentes e tooltips acessíveis. Mantenha compatibilidade com os marcadores de efeito e verifique os critérios de aceitação. Informe arquivos alterados e validações realizadas.”
