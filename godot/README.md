# Terras Devastadas — Godot / Android

Correção de cartas (03/11/2026): a ampliação recebe prioridade de toque sobre o leitor nos modos local e LAN. `card_reading_ui_smoke` e `lan_ui_smoke` verificam ciclos de abertura/fechamento pelo viewport real, incluindo acesso às ações LAN. Validação em Windows; falta confirmar em Android físico.

Viagem/combate/carga (02/11/2026): **Viajar** abre o mapa com estradas legais destacadas, usando o seletor da fuga; escolher uma rota abre a conferência de trajeto/custo, e cancelar não gasta recursos. O combate identifica **ATACA**, **DEFENDE** e o dono do dado por nome/cor. Um **?** indica a próxima rolagem; o resultado anterior não é atribuído ao próximo atacante. Reações têm botões diretos de uso, com leitura ampliada opcional e identificação preservada no hot-seat. A apresentação usa 0,55 s de dado, 0,12 s de pausa e 0,3 s de dano, também na arena pública LAN/TV.

Hatch 0.7: **carga 5**, ou 7 com E08; saves 0.6 mantêm 4/6. Cinco sucatas podem pagar a melhoria diretamente da carga. Carga exatamente no limite permite encerrar; excesso muda o botão para **Liberar carga**, com orientação para guardar, abastecer ou descartar. Tocar no carro do mapa ou no retrato lateral abre seus detalhes em tela cheia. Outros jogadores e TV consultam apenas atributos/equipamentos públicos, sem estoque ou combustível atual.

Encontros: após virar a carta, **Continuar** ou o Voltar do Android aplica os efeitos automáticos sem abrir outra tela de resolução. Escolhas de recurso/alvo permanecem explícitas. Ganhos, perdas de estrutura/combustível e avanços de cartas têm destaque animado a partir dos resultados aceitos; recursos privados aparecem somente ao dono. O início de corrida exibe a arte **CORRIDA SURPRESA** no centro do Local, celulares LAN e Tabuleiro, com alternativa estática para movimento reduzido. **Agir aqui** separa Explorar, Conquistar/saquear e Depósitos; depósitos têm Retirar, Guardar e Abastecer, sem misturar transferências com exploração.

Ajustes de interface de 02/11/2026: nome, etapas e turno compartilham o centro vertical da barra, inclusive com texto ampliado; ícones de mapa/localização/menu ficam centralizados. Administração local abre quatro categorias curtas, com modelos de veículo em uma tela própria. LAN agrupa cuidados do veículo em recursos, reparos e melhorias, mantendo somente capacidades do próprio jogador. Submenus têm **‹ Voltar** no cabeçalho; o Voltar do Android percorre o mesmo caminho e **Fechar** encerra a folha. Ações locais aceitas mantêm o submenu aberto. A TV conserva a apresentação pública, sem menu de administração privada.

Combate: dado/ação principal no topo, opções secundárias em **Mais opções**, e um único **Fugir** abre o mapa com as rotas legais pulsando. Cancelar não envia comando; escolher estrada inicia a tentativa, mantendo reações, dado e custo das regras. Efeitos sonoros locais para conserto, dano, ataque, esquiva e virada de carta usam **Volume dos efeitos**, separado da música. LAN recebe somente os sons de fatos aceitos, sem repetir em snapshots/reenvios. `combat_escape_sfx_smoke` cobre seleção local/LAN e sinais de áudio.

Leitura: as duas cartas iniciais de novas partidas têm contorno preto pulsante até serem abertas; a leitura é registrada neste aparelho por instância, sem usar/descartar cartas. O leitor abre centralizado e tocar na arte amplia a carta no centro; Voltar fecha a ampliação. Música fica no início das configurações, com barra e porcentagem. Menu é o último item à direita do topo, após o turno. Em movimento reduzido, o contorno fica estático.

Trilha de fundo: **Aftermath**, Kevin MacLeod, CC BY 4.0. Toca em loop no modo local e na TV; celulares LAN ficam sem música para evitar duplicação. Volume independente em **Configurações → Volume da música** e no botão **Música** da TV; zero desliga. Créditos ficam nessas telas e em `assets/audio/music/CREDITS.txt`; licença completa incluída no APK. Build de teste atual: `0.0.4-local-tv`, código 11.

Após confirmar uma viagem aceita, o próprio veículo no mapa principal sai da cidade de origem, acompanha a estrada até o destino e toca som curto de motor, respeitando volume e movimento reduzido. O encontro usa a virada da compra geral e **Resolver encontro**, sem entrar na mão; sua decisão permanece no motor. Na LAN, a frente só chega após autorização do anfitrião. Pausar interrompe o som/apresentação e conserva a carta sorteada. `travel_encounter_ui_smoke` cobre os dois fluxos em Windows; Android físico pendente.

HUD atual: jogador em negrito e na sua cor à esquerda, etapas centralizadas na mesma linha e turno à direita. Na preparação, **Comprar Carta** ocupa a área das ações em vermelho. A carga usa comandos curtos e quantidades alinhadas, com abastecimento excedente apenas quando disponível. Novas partidas 0.7 distribuem duas gerais sem animação; a compra explícita adiciona uma carta e mantém a revelação. Saves existentes não recebem cartas extras.

Menus roláveis permitem iniciar o arrasto sobre botões e painéis, sem selecionar a opção ao rolar. No combate local, a interface distingue turno, reação e carta recebida; abrir uma reação não compra cartas nem troca o jogador ativo. O resultado mostra recursos com ícone, quantidade e nome; o relato completo fica em **Ver detalhes**. Verificações automatizadas em Windows; toque em Android físico ainda precisa de validação.

Projeto nativo Godot 4.7 Standard, validado no **4.7.2**, GDScript e renderer Compatibility. Alvo principal: Android ARM64 em paisagem, 2–4 jogadores em LAN ou hot-seat. Branch atual: **feature/release-0.0.4**.

## Documentação atual

- [Como jogar no Android](../docs/COMO_JOGAR.md): preparação, LAN, turno, combate e objetivos.
- [Regras 0.7](../rules.md) e [cartas](../rules-cards.md): contrato de novas partidas.
- [CONTEXT.md](CONTEXT.md): arquitetura e limites para desenvolvimento.
- [Rebalanceamento 0.7](docs/REBALANCEAMENTO_V07.md): diferenças e preservação de saves.

Novas partidas usam `campaign-v07`, regras `0.7`, conteúdo `0.7.0`. Saves `campaign-v06` mantêm sua edição; não converter ao carregar. React/TypeScript é referência separada, com regras 0.6, sem importação de saves ou paridade integral de seed.

## Abrir e executar

Importe [project.godot](project.godot) no Godot e execute o projeto. A cena inicial é `scenes/bootstrap.tscn`: abre o modo celular ou Tabuleiro segundo a feature exportada. Na tela inicial do celular, **Nova partida** prepara hot-seat; **Multiplayer LAN** abre conexão/lobby. **Continuar** pede identificação antes de mostrar informações privadas. Como jogar e Configurações funcionam também sem partida.

Hot-seat usa um só dispositivo; LAN usa um por jogador. Tabuleiro/TV mostra projeção pública e não ocupa uma vaga nem executa comandos. Todos os participantes LAN precisam de builds compatíveis; o fingerprint de regras/protocolo/dados é produzido na exportação.

## Regras implementadas

Todos começam de Hatch com duas vidas, integridade 6, tanque 3/8, carga com uma sucata e duas gerais já distribuídas sem animação, um setor próprio e compra normal também no primeiro turno.

| Sistema | Nova partida 0.7 |
| --- | --- |
| Turno | Iniciar/comprar, livres legais, até uma viagem antes da ação, uma ação principal, encerrar |
| Exploração | Até três usos por setor; 2–3 recursos no depósito, incluindo uma sucata ou combustível escolhido |
| Suprimentos | Água/pneu/bateria da carga → uma sucata, livre uma vez por turno próprio |
| Progressão | Melhorar Hatch por cinco sucatas próprias locais e uma ação; preserva integridade e combustível |
| Moto | Dano 2, consumo 1, carga 2; equipamentos sem peso, dois espaços adicionais |
| SUV/Caminhonete | Defesa 4+, integridade/capacidades/consumos mantidos |
| Combate | Reações, equipamentos, dano, fuga, fortificação e recompensa; avanço até próxima escolha |
| Primeira destruição | Hatch íntegro com três combustíveis; proteção até próximo início próprio, sem perder essa vez |
| Segunda destruição | Eliminação; último sobrevivente vence |
| Territórios | T01–T06, depósitos, controle, anúncio de três pontos e confirmação no próximo início |
| Saque | Uma ação e um combustível; teste D6 × D6 com empate da defesa ou combate pessoal |
| Corridas | Três pistas, inscrição voluntária de um combustível, mínimo dois, marcos/surpresas/prêmio |
| Cartas | Gerais, melhorias, eventos e surpresas; E11/V16 excluídos de novos baralhos |

Água, pneu e bateria não são consumidos automaticamente. Não há doação direta de recursos. Moto não ganha combustível ao melhorar. Conquistar preserva o depósito e descarta melhorias antigas; o ganho de hostil entra na carga e não abastece automaticamente.

O catálogo mantém 74 definições e 148 identidades; 72 definições/144 cópias estão disponíveis nos baralhos do setup 0.7. E11 depende de sucata solta sem fonte definida; V16 permanece desativado. Cópias antigas não são apagadas.

## Interface Android

HUD e tema compartilhados, área segura, mapa com arrasto/pinça, prévia de viagem, mão recolhida, gaveta de carga, folhas com rolagem e ações LAN paginadas. Leitores de carta mantêm ações acessíveis e texto rolável. Pausa interrompe a animação sem perder a compra; a revelação pendente reaparece após desbloquear a mão.

Ajuda: tela inicial ou Menu → Como jogar no hot-seat; Menu → Como jogar na LAN. O texto usa o perfil da partida. A ajuda LAN explica que cada pessoa mantém seu aparelho; a local explica a passagem privada.

Botões respondem visualmente ao toque/foco e mostram custos/contexto nas opções. Fatos públicos de dano, reparo, conquista e turno destacam o mapa. A compra/revelação mantém sua animação. Na TV, o mapa preenche a tela, as etapas do turno ficam no topo e o placar minimizado permanece na base, com detalhes públicos ao selecionar. Combate/corrida atualizam barras e resultados sem decidir por jogadores. Há controle de movimento reduzido na TV. [Detalhes e validação](docs/UI_INTERACTION_TV.md).

Referências visuais: [UI_IMPLEMENTATION.md](docs/UI_IMPLEMENTATION.md), [S23_LAYOUT_FIX.md](docs/S23_LAYOUT_FIX.md), [LAN_LAYOUT_REVIEW.md](docs/LAN_LAYOUT_REVIEW.md). Relatórios são evidência desktop, não homologação física.

## Persistência e LAN

- Hot-seat: `user://campaign-native-v1.json`; backup antes de nova partida: `campaign-before-new-game.json`.
- LAN: `user://campaign-lan-v1.json`, backup `.bak`, credenciais locais em `lan-connections.cfg`.
- Schema do estado nativo: `native-stage1`, versão 1, com perfil e versão de conteúdo próprios.
- `gain_card` mantém instâncias e tickets; `take_hand_card` atualiza índices das revelações.
- Recusa de comando não gasta recursos/RNG. Falha de gravação local após aceitação pede repetir somente a escrita; LAN bloqueia novas mutações até salvar.
- Não há migração de anfitrião, garantia de hospedagem em segundo plano, conversão React ou troca automática de edição.

O anfitrião deve manter o app aberto. Falha de descoberta permite entrar por IP; reconectar não concede outro turno nem repete recompensas. [Protocolo LAN](docs/MULTIPLAYER_LAN_PROTOCOL.md).

## Testar

Na raiz do repositório, com Godot no PATH ou passando o executável:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1 -Godot "C:/caminho/Godot_v4.7.2-stable_win64_console.exe"
# Somente regras, dados e rede:
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1 -HeadlessOnly
```

O runner usa um perfil temporário curto por suíte e restaura APPDATA/LOCALAPPDATA. Não usa o save do jogador. Isso também evita falha do cache OpenGL em caminhos longos no Windows. `-OnlySuites` seleciona suítes ao chamar pelo PowerShell; logs ficam em `.tools/campaign-checks/`. Suítes visuais precisam de renderer real.

`balance_smoke` cobre 0.7 e compatibilidade; `campaign_smoke`, `combat_smoke`, `pvp_rewards` e contratos compartilhados preservam regressões 0.6. LAN cobre permissões, recibos, projeções, reconexão e campanha. Layout LAN usa 892×445, 1280×720 e 2340×1080 com área segura simulada.

Replay usa a edição registrada no save:
```powershell
godot --headless --path godot --script res://tools/replay_campaign.gd -- "C:/backup/partida.json"
```
Execute testes/replays manuais em perfil isolado. Contratos TypeScript: `npm.cmd test -- --configLoader native --reporter=dot` e `node godot/tools/compare_contracts.mjs`; não representam paridade integral.

## Exportar APK

O preset **Android** usa ARM64, pacote `com.bhsp.terrasdevastadas`, versão `0.0.4-lan-flow` (código 10). O preset **Android TV** é separado, com feature `tv_board` e Gradle. Não mudar o identificador de distribuição ou a chave de um app publicado por inferência.

Instale templates **da mesma versão do editor**, configure JDK 17/Android SDK no editor e exporte Android em modo debug. JSON e licenças das fontes entram no pacote; testes, ferramentas e docs ficam fora. Release/Play Store exige assinatura própria e configuração de distribuição; nenhuma chave de release está incluída.

O [workflow CI](../.github/workflows/android-debug.yml) usa Godot/templates 4.7.2, template Android mínimo 24/alvo 36 e SDK correspondente. Executa testes, exporta e verifica APK, assinatura, ARM64 e INTERNET. O artefato ZIP contém APK, logs e SHA256SUMS.

No CI, o pacote vira `com.bhsp.terrasdevastadas.preview.v07`, app **Terras Devastadas Teste 0.7**, instalado ao lado da variante anterior. A assinatura debug é temporária por execução: outra build do mesmo pacote pode exigir reinstalar essa variante. Preservar os dados da edição anterior; não reutilizar esse processo como assinatura de release.

O CI também prepara o source template Gradle da mesma versão e exporta **Android TV** como `com.bhsp.terrasdevastadas.tabuleiro.preview.v07`, **Terras Devastadas Tabuleiro Teste 0.7**. O ZIP reúne os dois APKs, logs e checksums; use o arquivo `tabuleiro` na TV. A verificação TV inclui launcher leanback. A instalação/experiência em TV física permanece pendente.

## Evidências e trabalho restante

A execução CI [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924) passou em **444 verificações** (180 regras, 63 sessão LAN e 201 campanha LAN), importou/exportou e verificou assinatura v2/v3. Regressões antigas e layouts renderizados passaram no Windows. Novas alterações devem registrar sua própria validação.

Faltam Android físico/TV, rede entre aparelhos, teclado/pausa/recortes/toque, desempenho em hardware de entrada e partidas humanas medidas. Balanceamento é hipótese de playtest. Permanecem sem definição a fonte de sucata solta de E11, a reativação/conteúdo de V16 e restrições extras do alerta de saque. Não inventar efeitos para preencher essas lacunas.

Correções de 01/11/2026: fechamento do leitor de cartas libera a mão imediatamente e restaura opacidade; combate local mantém dado central e comandos abaixo dos combatentes. Rolagem com som de dados dura 1,6 s, seguida de pausa de 0,45 s e perda de vida interpolada em 1 s; movimento reduzido mantém resultado imediato. Regressões: combat_smoke, combat_ui_smoke, card_reading_ui_smoke, combat_escape_sfx_smoke, lan_ui_smoke e tv_dashboard_smoke passaram no Windows. Captura: .tools/combat-rolling-fixed.png. Android/TV físicos ainda não validados.

Atualização de 01/11/2026 — combate e acompanhamento: a LAN vincula `combatRoll` e a continuação ao combatente daquele ataque; hostil/fortificação é rolado pelo atacante do setor. `combatFast` não é oferecido na LAN. Em 0.7, uma geral por pessoa por rodada de combate, independente da cota do mapa; saves 0.6 preservam a regra antiga. `round_generals` é validado/persistido e renova depois dos dois ataques principais. Saves de combate antigos sem o campo conservam a cota já gasta.

TV e celulares, inclusive de não combatentes, usam a arena pública de `combat_view.gd` com dado, dano interpolado e efeitos iguais ao local. A projeção inclui somente vida anterior/posterior e fatos públicos; nunca mãos/capacidades alheias. Resultados recebidos durante animação são enfileirados, sem bloquear a autoridade. `race_board.gd` compartilha pista, veículos, marcos e chegada entre TV/celular/local. Novos avisos identificam quem reage/rola e relatam ações aceitas. O menu abre em “O que fazer agora?”, prioriza as ações e recolhe cartas/opções secundárias.

Validação: regressões Godot 4.7.2 em Windows e renderização real, incluindo `combat_turns_smoke` (permissões, cota/rodada, JSON/save), `public_encounters_ui_smoke` (TV/celular, animação, reconexão, movimento reduzido, limites compactos), suítes de combate, campanha LAN, balanceamento e layout. Capturas transitórias em `.tools/public-combat-tv.png`, `.tools/public-race-phone.png` e `.tools/public-race-tv.png`. APKs debug gerados em 01/11/2026: `0.0.4-combat-race`, código 9, celular ARM64 e TV ARM64/ARMv7. Assinaturas, pacotes, conteúdo e fingerprint das fontes atuais verificados; a assinatura do celular coincide com o APK anterior. Entregas: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk` na raiz; cópias, SHA256 e manifesto em `godot/builds/`. Android e TV físicos continuam pendentes.
Correção LAN de 02/11/2026 — versão `0.0.4-lan-flow`, código 10: o menu de ações LAN deixou de abrir a grade antiga de categorias. Agora oferece Agir aqui (com setores e opções legais na própria cidade), Viajar antes de agir, Cuidar do veículo/depósitos, Cartas/equipamentos e Encerrar meu turno. A entrada muda conforme a própria capacidade; não oferece ações do jogador ativo aos demais. Abrir/consultar menus não envia comandos.

Combate/corrida LAN têm arena/pista e decisões próprias lado a lado, com rolagem de reserva em telas compactas. As reações deixam de prender a interface numa folha antiga ou cobrir a animação. Cada snapshot aceito passa pela apresentação, preservando resultados quando RPCs chegam no mesmo frame. Acontecimentos públicos recentes são sanitizados, limitados a 12, persistidos e apresentados em celulares/TV; recursos privados continuam fora da projeção. A versão aparece na conexão LAN e no menu.

Validação Windows: `lan_action_menu_ui_smoke` (38 verificações em 892×445, 1280×720 e 2340×1080), suítes LAN/combate/layout e teste com cinco processos conectados por ENet: quatro jogadores usaram os botões do novo menu, exploraram, passaram por duas rodadas de combate e se inscreveram/rolaram a corrida; a TV recebeu apenas dados públicos. Harness: `godot/tools/test_lan_network.ps1 -PeerScript res://tests/lan_actions_peer.gd`. Evidência transitória em `.tools/lan-network-dc7b8dfdde3f4610ba8511e50536b64f/` e `.tools/lan-action-menu-updated.png`. Isso não comprova toque/rede em Android ou TV físicos.
APKs da correção LAN exportados em 02/11/2026: versão `0.0.4-lan-flow`, código 10, mesma assinatura debug anterior. Ambos verificados por assinatura, manifesto, conteúdo e fingerprint atual `a809d5ab8484c435238a287fc3d2b84ab8e351c9455adc0db4b48de7080d9765`. Entregas na raiz: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk`; manifesto e SHA256 em `godot/builds/`. As 13 suítes pertinentes passaram, assim como as jornadas ENet de menu/encontros e descoberta/reconexão/TV sem comandos. O harness de reconexão agora aguarda o intervalo real de 4 s antes de encerrar o servidor. Android/TV físicos seguem pendentes.

Tabuleiro/TV no jogo local — 02/11/2026, build `0.0.4-local-tv` (código 11): durante uma partida hot-seat, abrir **Menu → Conectar Tabuleiro/TV → Disponibilizar tabuleiro para a TV**. Na mesma rede Wi-Fi, abrir o aplicativo Tabuleiro na TV, selecionar a sala **Local · nome** (ou informar o IP/porta mostrados no celular) e aprovar **Aceitar TV** no celular. Todos continuam usando o mesmo celular; a TV acompanha mapa, turnos, combate e corrida sem mãos, carga, depósitos ou capacidades privadas. Só uma tela pública pode ser aprovada; clientes jogadores são recusados. Desconectar pelo mesmo menu, voltar à tela inicial, iniciar nova partida ou sair encerra a transmissão sem converter saves locais em sessões LAN. Após retomar o save local, disponibilizar novamente. A TV pode reconectar enquanto a transmissão estiver ativa; o celular precisa permanecer aberto.

Implementação: `NetworkEndpoint.host_local` observa os comandos aceitos de `local_session.gd` usando o motor hot-seat existente e a projeção pública compartilhada. Aprovação, fingerprint, descoberta, eventos, arena e pista reutilizam o fluxo TV/LAN. O save LAN fica preservado. Reações públicas identificam o jogador que realmente reagiu, inclusive fora da vez do mapa. Históricos públicos desta transmissão ficam em memória; reiniciar a transmissão cria novo contexto.

Validação Windows/Godot 4.7.2: `local_board_ui_smoke` verifica menu, estado/RNG/saves, comandos aceitos/recusados, reações fora do turno, dado animado na TV, corrida e ciclo de conexão. Regressões LAN/sessão/TV/arena passaram. `tools/test_lan_network.ps1 -PeerScript res://tests/local_board_peer.gd` passou com host local, TV, descoberta/reconexão, comando de TV recusado e três clientes jogadores recusados. O cenário `lan_actions_peer.gd` continuou passando com quatro jogadores LAN e TV (menus, combate e corrida). Captura de UI em `.tools/local-board-sharing.png`. Não equivale à validação em Android/TV físicos.
APKs da feature local/TV gerados em 02/11/2026: `0.0.4-local-tv`, código 11, assinatura debug igual à dos APKs anteriores. Manifestos, conteúdo, ABIs e fingerprint atual `a73ff5640335373027e9ef872eb81ac3086231d9719b1f2d7ab1c7fc1d81cc59` verificados nos dois pacotes. Entregas atualizadas na raiz: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk`. Checksums em `godot/builds/SHA256SUMS.txt`; manifesto em `godot/builds/local-tv-build-manifest.json`. A suíte específica passou em 40 verificações; regressões LAN/sessão/combate/TV e ambos os cenários ENet também passaram. Teste em aparelhos Android/TV físicos ainda pendente.
