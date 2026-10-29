# Reformulação da interface — Modern UI/UX

## Escopo e direção

Aplicação das skills `modern-ui-ux` e `frontend-design` ao frontend React existente. A identidade solicitada pelo usuário prevalece sobre os modelos genéricos: aço escuro, laranja queimado, ferrugem e texto marfim acompanham as cartas e o mapa original. Foram reutilizadas as artes existentes; não há serviço de imagem, fonte externa ou biblioteca de animação adicional.

O mapa continua ocupando a tela inteira. Os controles ficam em superfícies opacas, com contraste independente do fundo ilustrado. Os nomes, recursos, veículos, progresso e resultados vêm do estado real da partida.

## Simplificação após uso do layout

A barra de sete opções foi substituída por **Mapa** e **Inventário**, agrupados como consultas. **Ações do turno** é um botão separado que abre as decisões de jogo. Antes do início, o botão mostra **Iniciar turno · comprar geral**. Abrir um painel não executa a ação nem gasta recursos.

O inventário reúne as abas **Veículo e recursos** e **Cartas**. Territórios são inspecionados pelo mapa ou escolhidos pelo painel de ações. Histórico e placar ficam no menu da sessão. O guia de quatro etapas e o placar permanente foram retirados para desobstruir o mapa.

Cartas recebidas abrem com um **verso comum**, sem imagem ou nome da definição expostos. Clique, toque ou Enter vira a carta com uma transição 3D de 750 ms. Só depois da revelação aparece a opção de guardar. Se houver várias cartas, cada uma começa pelo mesmo verso e é revelada separadamente. Redução de movimento mantém o clique de revelação e remove a transição. A compra é registrada uma única vez pelo motor; virar ou guardar não compra outra cópia.

## Antes e depois da primeira reformulação

### Vida e indicação de dano

O combate, a defesa territorial e o inventário mostram **Vida** com valor atual/máximo e barra. O componente `src/ui/HealthBar.tsx` compara valores reais consecutivos: somente uma redução ativa a borda de dano, o breve tremor do participante atingido, o rastro na barra e o aviso `−N de vida`. Carregar um participante já ferido não reproduz dano. Curas não geram aviso negativo.

O recibo da ação identifica quem perdeu vida, inclusive quando o golpe encerra o combate e o painel deixa de existir. A perda usa a diferença efetiva, não o dano nominal do ataque; trocas de veículo e descarte de encontros por fuga não são contabilizados como dano ao inimigo. Redução de movimento remove tremor/transições, mantendo números e aviso. Os campos internos `integrity` e `resistance`, os saves e os textos impressos nas artes continuam compatíveis.

| Antes | Depois |
|---|---|
| Painéis verdes e bege com cantos muito arredondados | Superfícies de metal escuro, bordas discretas e acento laranja coerente com as cartas |
| Preparação centrada em formulário | Abertura com mapa, três cartas reais e informações sobre veículos e partida local |
| Ações e estados distribuídos pelo mapa | Guia Comprar / Viajar / Agir / Encerrar, HUD de recursos, navegação e menu de sessão compacto |
| Formulários de alvo antes da mão inteira | Artes primeiro, filtros por tipo e preparação com os campos relevantes à carta selecionada |
| Combate apresentado apenas por texto | Dado natural, total, defesa e acerto/falha alimentados por `Combat.lastRoll`, com animação breve |
| Corrida listada apenas por posições | Barras de progresso por participante e controles preservados para inscrição, escolhas e avanço |

A viagem permanece opcional. O guia não executa nem restringe ações por conta própria.

## Componentes

- `src/theme.css`: tokens da identidade visual e ajustes de layout, estados, diálogos e movimento. É carregado após os estilos estruturais existentes, sem alterar o funcionamento do mapa.
- `src/ui/SetupHero.tsx`: apresentação usando o mapa e cartas do próprio catálogo.
- `src/ui/TurnActions.tsx`: decisões do turno e abas do inventário. Substitui o antigo guia permanente.
- `src/ui/HandPanel.tsx`: mão, filtros, preparação de cartas, equipamentos e melhorias.
- `src/ui/Cards.tsx`: artes completas, ampliação, compra e resolução de corrida. Imagens de ampliação também usam carregamento preguiçoso para não antecipar todos os arquivos do catálogo.
- `src/ui/CombatSummary.tsx`: resultado visual baseado em dados estruturados do motor. A rolagem e suas regras não foram alteradas.
- `src/main.tsx`: menu da sessão, integração dos componentes e foco dos painéis.

## Checklist modern-ui-ux

| Item | Resultado e evidência |
|---|---|
| Tipografia | PASS: títulos condensados em Bahnschrift/Arial Narrow, corpo em Segoe UI/Arial e hierarquia de títulos, texto e legendas. Sem download de fontes. |
| Espaçamento | PASS: tokens de espaço, painéis com respiro e controles agrupados por tarefa. HUD conferido em 320×700, 390×844, 1024×768 e 1440×1000. |
| Cor | PASS para os pares principais: marfim sobre fundo escuro 14,02:1; texto secundário 8,14:1; laranja 7,01:1; texto escuro do botão primário 7,52:1. Não equivale a auditoria WCAG completa. |
| Componentes | PASS: estados padrão, hover, foco, pressionado, desativado e selecionado; formulários e botões compartilham tokens. |
| Movimento | PASS: entrada de painéis, revelação de cartas, dado, resultado de combate, traçado da viagem e poeira transitória. `prefers-reduced-motion` desativa animações e transições. |
| Layout | PASS nos viewports testados: sem rolagem horizontal da página; HUD sem sobreposição em 320×700 e 1024×768. Mapa mantém rolagem própria e zoom. |
| Feedback | PASS: compra mostra a carta, ações mantêm recibo, erros continuam específicos e os alvos aparecem conforme a carta preparada. |
| Teclado e semântica | PASS nos fluxos testados: foco no título ao abrir painel, retorno ao acionador ao fechar, Escape fecha menu/painel, filtros expõem seleção e diálogos mantêm semântica nativa. |
| Toque | PASS para navegação, botão de turno e menu no teste de 320 px: alvos de pelo menos 44×44 px. |

## Validação

- `npm.cmd test -- --configLoader runner`: regras e saves existentes.
- `npm.cmd run build`: TypeScript e build Vite.
- `npm.cmd run test:ui`: compra, imagens, privacidade, preparação de carta, uso de alvo, responsividade, foco/navegação, movimento reduzido, combate e zoom.
- Capturas geradas em `test-results/`: abertura, mapa desktop/móvel, cartas, combate e HUD de 320/1024 px.

As verificações usam Chromium em desktop com emulação de viewport. Ainda não constituem uma sessão de jogo prolongada em aparelhos físicos nem auditoria de todos os leitores de tela. Os saves e as regras anteriores são preservados; `lastRoll` é um campo opcional de apresentação.
