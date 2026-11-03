# Interface contextual pós-apocalíptica — implementação

Correção posterior do leitor (03/11): rodapé reservado, botões com área mínima de 64 unidades, Recolher/Usar/Descartar distintos e painel local responsivo mesmo já aberto. Retirada a frase genérica acima dos botões. Local/LAN avançam o leitor na árvore ao abrir: `z_index` isoladamente não impede o HUD abaixo de receber o toque. Nova regressão `card_reader_layout_smoke`: 146 verificações em três resoluções, texto local 1,0/1,25, input real, abrir opções/cancelar sem comandos, mutação ou RNG. Passaram também leitura/zoom, LAN, layout local normal/ampliado, LAN compacto e UI moderna. [Captura corrigida](premium-ui/card-buttons.png). Windows; Android físico e novo APK não incluídos.

03/11/2026 · Godot 4.7.2 Standard · Compatibility · Windows.

A direção foi corrigida pelo usuário durante a implementação: **priorizar layout e interação, reduzir texto redundante e manter o pós-apocalipse e os veículos existentes**. O primeiro estudo campestre foi rejeitado. O resultado implementado privilegia grafite, areia e cobre sobre o terreno devastado, sem substituir os carros e suas animações.

## Implementado

03/11/2026: G17/G18 usam seleção direta no mapa, compartilhada com fuga/viagem, no local e na LAN. Somente estradas legais são destacadas; cancelar preserva carta, recursos e RNG. Estradas bloqueadas recebem tracejado vermelho e uma barricada no ponto médio da polilinha, também na TV. Rótulos de cidade/resumos evitam esse marcador. A carga ganhou atalhos Melhorar veículo, Equipamentos e Reparo maior +4, preservando custos e permissões do motor. `barricade_cargo_ui_smoke` verifica esses fluxos em Godot/Windows; Android físico e novos APKs não incluídos.

| Fluxo | Mudança concreta | Cobertura |
| --- | --- | --- |
| Tabuleiro | Atalhos Explorar, Disputar e Depósitos abrem diretamente a operação na cidade atual; Encerrar separado. Preparação conserva Comprar Carta. | Local e LAN |
| Cidade | Operações diretamente na consulta; removido o passo intermediário “Agir aqui”. Folha menor, centralizada à direita, com altura pelo conteúdo. | Local; mesmas operações compartilhadas na LAN |
| Setores | Grade de fichas com número/proprietário; exploração exibe contador. Corrigida a numeração em cidades cujos IDs têm hífen. | Local e LAN |
| Carga | Duas colunas com ícone/quantidade/nome; capacidade separada. Depósitos abre diretamente essa operação. | Local e LAN |
| Folhas | Altura conforme conteúdo, largura limitada à área segura, rolagem quando necessária; Voltar e Fechar separados. | Local e LAN |
| Texto | Removidas orientação genérica permanente e frases repetidas nos cartões e combate. Custos, impedimentos, ganho, ator e decisões preservados. Ajuda completa no menu. | Local, LAN e arena pública |
| Arena | Superfícies do HUD; removidas duplicação de status público, repetição do atacante antes de Rolar e instrução “Use uma carta ou passe”. Permanecem ATACA/DEFENDE, dono do dado, munição, reações, opções e fuga. | Local, LAN e TV |
| Mapa | Ruínas/solo seco com margens coerentes, placas legíveis, seleção com quatro marcas distinta de propriedade, resumo de setores no zoom amplo, mais posições para etiquetas. Coordenadas/polilinhas preservadas. | Local, LAN e TV |
| Acabamento | Barlow sem condensação por padrão; tema único, foco, estados dos botões, leitura/zoom e passagem privada. Retirados rebites/riscos dos painéis comuns. Início, lobby, ajuda e configurações herdam o tema. | Local, LAN e TV |

`ui_operations.gd` e `ui_resource_tile.gd` concentram os componentes novos; as fontes de dados continuam distintas por modo. Atalhos **navegam** e não enviam comandos de exploração/conquista/transferência. Elegibilidade, aceitação, recursos e RNG continuam no motor e nas capacidades LAN. Não foram alterados protocolo, balanceamento ou motor para sustentar o layout. A autorização para descartar saves antigos não precisou ser utilizada.

## Verificação desktop

- **40/40 suítes** do runner passaram. [Resultado completo](premium-ui/results.json).
- Após os últimos ajustes de rótulos/contraste, passaram novamente `modern_ui_smoke`, `tv_dashboard_smoke`, `public_encounters_ui_smoke`, `travel_encounter_ui_smoke`, `encounter_flow_ui_smoke` e `premium_ui_smoke`.
- `premium_ui_smoke`: **118 verificações**, input pelo viewport em 1280×720, 2340×1080, 1024×768 e 892×445; texto 1,25 no local 4:3. Confere atalhos, cancelamentos, quantidades, estado/RNG e ausência de comandos/revisões LAN por navegação.
- ENet com quatro jogadores e TV: menus, combate e corrida completos; TV sem menus privados. Evidência `.tools/lan-network-f653186971bb478bb3e5d63da42414f2/`.
- Hot-seat com Tabuleiro: oito ações do anfitrião, comandos recusados aos três clientes e TV com reconexão/eventos públicos. Evidência `.tools/lan-network-bd7a537907c14939b36a5f2c790f84cb/`.
- Revisão orientada por `godot-code-review`: sem RNG/comandos nos componentes, sem polling de inventário, decoração ignora input, sinais de aquisição mantidos. Zoom continua exercitado por input real e regressões de privacidade.
- `modern_ui_smoke`: aproximadamente **74,3%** de área livre de HUD, 73,4 MiB de memória estática e intervalo mediano de 13,3 ms em 90 frames Windows. É uma amostra após interações, sem garantia de VSYNC, orçamento GPU ou equivalência Android.

Baseline em `.tools/premium-baseline/`, com branch/status/diff e logs então disponíveis. O teste de tremor tocava um veículo e esperava cidade; a fixture agora usa cidade desocupada para isolar o gesto. `ui_smoke` e `encounter_flow_ui_smoke` consultavam hierarquias antigas; agora percorrem cartões e continuam conferindo **35 setores, donos, exploração e retirada**. O teste de arma passou a buscar o rótulo com atacante, mantendo dano 3. `data_validation` comparava veículos Godot 0.7 com React 0.6; retirada essa comparação somente para veículos, mantendo regressões modernas/legadas em `balance_smoke` e `shared_contracts`. Nenhum dado foi alterado para fazer testes passarem. Na limpeza posterior do repositório, a comparação externa foi removida por completo junto com o website; `balance_smoke` e as fixtures nativas `shared_contracts` permanecem.

No sandbox, a engine registrou erro ao ler certificados Windows; a execução isolada com acesso ao sistema eliminou esse erro. Warnings antigos de nomes de variáveis e ObjectDB permanecem nos logs; não foram apresentados como erros de regra.

## Capturas reais

| Tela | Captura |
| --- | --- |
| Tabuleiro local, 1280×720 | [local.png](premium-ui/local.png) |
| Cidade contextual | [city.png](premium-ui/city.png) |
| Carga | [cargo.png](premium-ui/cargo.png) |
| LAN, 892×445 | [lan-compact.png](premium-ui/lan-compact.png) |
| Arena | [combat.png](premium-ui/combat.png) |
| TV, 1280×720 | [tv.png](premium-ui/tv.png) |

Outros tamanhos e texto ampliado em `.tools/premium-ui/`. São execuções reais inspecionadas no Windows, não mockups. A inspeção pelo agente não substitui avaliação com jogadores.

## Assets e limites

[Inventário por ID](../assets/premium/inventory.json) e [origem/prompts](../assets/premium/CREDITS.md). Terreno/margens usam `image_gen` integrado. Originais preservados; fontes já licenciadas; sem dependências ou assets externos novos. SVG novos pertencem ao código visual do projeto. Veículos, seus 24 frames e as 74 definições de cartas mantidos; isso não reclassifica efeitos de cartas como validados em aparelho.

**Android/TV físicos:** não testados. **Jogadores novos:** não avaliados. **APKs:** não gerados/substituídos. Não houve descarte de saves nem homologação de leitura, toque, área segura, áudio, suspensão ou desempenho físico. Essas verificações continuam necessárias antes de afirmar melhora de compreensão. Esta entrega implementa e verifica em desktop a direção corrigida; a homologação física/humana do plano continua pendente.

## Organização do veículo e custo de ação — 03/11/2026

Carga local/LAN usa cinco atalhos: Abastecer, Reparar, Melhorar veículo, Depósitos e Descartar. Reparos simples/maior ficam em folha exclusiva. Melhorar veículo reúne compra, consulta/instalação de equipamentos e troca. Comandos que usam a ação principal recebem símbolo 1 em círculo tracejado, superfície/borda âmbar e descrição acessível, pelo componente `turn_action_style.gd`. Textos repetidos “1 ação” foram retirados dos rótulos, preservando custos de recursos e impedimentos. A autoridade projeta `consumes_action` para a LAN sem enviar índices privados ou alterar regras/RNG. G17 também recebe indicador no seletor de estradas compartilhado.

Validação desta alteração: 12 suítes desktop passaram (`lan_session_smoke`, `lan_campaign_smoke`, `transfers_smoke`, `campaign_ui_smoke`, `lan_action_menu_ui_smoke`, `premium_ui_smoke`, `barricade_cargo_ui_smoke`, `mobile_layout_smoke`, `lan_mobile_compact`, `tv_dashboard_smoke`, `public_encounters_ui_smoke`, `lan_ui_smoke`). Últimos ajustes LAN repetidos nas três suítes pertinentes. Capturas revisadas: `.tools/vehicle-repair-local.png` e `.tools/vehicle-repair-lan.png`. Sem nova exportação de APK ou teste físico Android/TV nesta alteração.

## Preparação, veículos, corrida e manual — v0.0.5 em desenvolvimento

Carga local tem colunas iguais e Melhorar/veículo em duas linhas. Comprar equipamento tem rótulo curto, confirmação de custo e mensagem de sucata insuficiente. O baralho misto permanece. Troca local/LAN usa grade compartilhada com arte por ID/cor, inspeção de ataque/defesa/carga/tanque/consumo e comando separado da navegação.

Nomes locais/LAN são persistidos em preferências de formulário. Sala LAN aceita nome e senha opcionais; campo de senha é mascarado. Preparação local oferece transmissão para a TV antes de Começar; lobby não envia partida anterior. Sessão local é nomeada pelo jogador ID 0, independentemente da ordem sorteada.

Menu principal agrupado e manual com índice de sete assuntos e negrito nas regras/custos principais. Tela inicial identifica v0.0.5 e EM DESENVOLVIMENTO. Corrida usa faixa com nome/cor e distingue CARTAS DE EFEITO de DADO, inclusive na TV. A rolagem e o passe também nomeiam o jogador. O estado de evento interrompe a indicação de dado.

Verificação desta etapa: 46 suítes passaram em Godot 4.7.2/Windows; layouts LAN foram repetidos após a troca do manual longo por índice e tópicos. `vehicle_setup_ui_smoke`: 41 verificações; `race_manual_ui_smoke`: 25. Três jornadas ENet passaram (senha, TV pré-partida local, quatro jogadores/TV em ações/combate/corrida). Relatório `.tools/vehicle-session-validation.json`. Capturas revisadas de carga, grade, detalhe LAN, manual e atores de corrida. Código/configuração em v0.0.5, código Android 17; APKs anteriores ainda não reexportados. Sem teste físico Android/TV.
