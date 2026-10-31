# Terras Devastadas — Godot / Android

Para manutenção por IA, começar por [AGENTS.md](AGENTS.md) e [CONTEXT.md](CONTEXT.md). O contexto da raiz descreve a referência React e não significa paridade com o nativo.

## Multiplayer LAN e Android TV

Disponível pelo botão **Multiplayer LAN** na tela inicial: 2–4 jogadores em aparelhos próprios, um celular anfitrião e um aplicativo **Tabuleiro** opcional para Android TV. O anfitrião aprova jogadores/tela pública; cada jogador recebe sua mão e decisões privadas. A TV acompanha mapa, turno, placar e confrontos públicos, inclusive entrando depois do início.

Revisão **0.2.1-lan-ui**: a LAN usa o HUD original do modo local, preparação centralizada, ações em páginas curtas e salas encontradas automaticamente. Detalhes e limites de validação: [correção de layout/toque](docs/LAN_UI_TOUCH_FIX.md).

Revisão posterior de layout: conexão/lobby respeitam área segura e teclado, a consulta de cartas mantém ações visíveis, painéis paginados permitem rolagem quando necessário e Voltar fecha primeiro a janela ativa. A compra do início do turno se recupera de pausa durante a virada sem repetir a compra. [Relatório e capturas](docs/LAN_LAYOUT_REVIEW.md). Teste: `godot --path godot --script res://tests/lan_mobile_layout.gd -- --compact`, usando perfil isolado conforme a seção de validação; omitir `--compact` para 1280×720 ou trocar por `--s23` para 2340×1080. Android físico ainda pendente.

APKs de debug: `builds/terras-devastadas-lan.apk` e `builds/terras-devastadas-tabuleiro.apk`. O segundo usa pacote próprio e launcher TV. Os dois precisam ser da mesma geração de regras/protocolo. Foram gerados e inspecionados; instalação e homologação em Android físico permanecem pendentes.

Consulte [implementação, uso e testes](docs/MULTIPLAYER_LAN_IMPLEMENTATION.md), [contratos de rede/privacidade](docs/MULTIPLAYER_LAN_PROTOCOL.md) e [plano de migração](docs/MULTIPLAYER_LAN_MIGRATION_PLAN.md). Em Windows/editor, `-- --tv-board` abre a apresentação pública. O modo local e o save hot-seat continuam separados da sessão LAN.

Migração nativa em andamento. A versão React permanece na raiz como referência funcional das regras v0.6. Este projeto ainda não substitui todas as regras do jogo.

A [auditoria e plano](docs/GAMEPLAY_AUDIT_AND_PLAN.md) registram o diagnóstico anterior. A [implementação da campanha](docs/CAMPAIGN_IMPLEMENTATION.md) descreve o que foi entregue, como validar e o que ainda depende de regras/aparelho.

## Interface modernizada

Reações de combate e fuga abrem uma seleção central de tela inteira, sobre o combate, sem rolagem vertical. Cartas excedentes usam **Anterior/Próxima**. **Minimizar** permite consultar o confronto sem responder; **Ver cartas** reabre a seleção. Tocar em uma arte amplia a carta; apenas **Usar carta** confirma e consome. **Voltar** cancela sem gastar a carta. Só aparecem cartas elegíveis, após a confirmação do dono e as revelações pendentes.

O plano de `../update_ui.md` foi aplicado ao código. Consulte [o relatório e as capturas](docs/UI_IMPLEMENTATION.md) para a matriz de implementação e as verificações pendentes de Android físico.

O topo agora concentra jogador/turno/ação e Menu. Histórico, ajuda, configurações e nova partida ficam no menu. O veículo lateral abre uma gaveta de carga; o mapa mantém controles compactos e rotas com geometria própria. A ação disponível recebe o destaque laranja, e o rodapé permanente de log foi substituído por notificações e feedback local.

Explorar um setor abre um resultado central com ícones e quantidades dos recursos novos, sem somar itens que já estavam no depósito. **Ver depósito** leva ao estoque do setor; **Continuar** ou Voltar fecham o resultado. Os recursos permanecem no depósito até a retirada para a carga.

Na passagem e na retomada, uma tela opaca oculta as cartas até o jogador confirmar. Texto, movimento reduzido, áudio e dicas são configuráveis. No Android, a vibração é opcional e os controles usam uma escala baseada no DPI reportado, ainda sujeita à validação física.

## Abrir e jogar

1. No Godot **4.7, edição Standard**, importe `godot/project.godot`. O projeto declara a versão mínima **4.7** e foi validado com **4.7.2 stable**. Use os export templates correspondentes à versão exata do seu editor.
2. Pressione **F6** na cena `scenes/main.tscn` ou **F5** para iniciar o projeto. A tela de apresentação oferece **Continuar partida**, **Nova partida**, **Configurações**, **Como jogar** e **Sair**. Continuar só fica disponível com partida carregada e não encerrada; ele exige identificação antes de mostrar cartas. O menu de pausa também permite voltar à **Tela inicial**.
3. Informe de dois a quatro nomes. A nova partida abre um guia rápido com o ciclo de turno e os objetivos. **Vamos jogar** segue para a identificação do primeiro jogador. Todos jogam no mesmo dispositivo, alternando turnos.
4. Inicie o turno, toque em uma cidade conectada e confirme a viagem. Arraste o mapa para navegar; use pinça ou os botões para ampliar.
5. Abra **Explorar / conquistar** (ou **Cidade / setores** quando a ação já foi utilizada) para consultar setores, explorar e retirar recursos. O seletor de cidade permite consultar as demais. Tocar em uma cidade abre seu detalhe e permite enfrentar um adversário local. Conquistar/enfrentar custa uma ação principal.
6. As cartas ficam centralizadas, sem faixa de fundo e com a metade inferior recolhida. Toque para ampliar; **Usar / instalar** abre alvos/opções das gerais e melhorias. G01–G07 são usadas na reação de combate; G19/G20 no saque e G21/G22 na corrida. **Recolher** ou Voltar fecha a consulta.
7. O veículo aparece de lado no canto superior esquerdo. O botão **Carga X/Y · abrir** abre a gaveta com os seis recursos, separados do tanque. Ao viajar, o resumo usa a animação aprovada de 24 quadros a 20 fps por 1,2 segundo, enquanto a peça percorre a rota. Movimento reduzido elimina o deslocamento animado.
8. Ao receber uma carta, inclusive a inicial e a compra do turno, ela aparece pelo verso. Toque nela para virar e revelar; depois toque em **Adicionar à mão**. Compras múltiplas são apresentadas uma a uma, apenas ao respectivo jogador. **Reduzir movimento** fica somente em **Menu → Configurações**; a preferência salva continua controlando as animações, sem seletor na compra.
9. O **ícone de mapa** no canto superior direito recolhe o HUD e enquadra o tabuleiro inteiro, permitindo selecionar as 12 cidades. **Voltar aos controles** restaura os painéis. Zoom e arrasto continuam disponíveis.

## Combate nativo

- Conquista de setor neutro enfrenta seu hostil; contra setor ocupado, o dono operacional presente escolhe se defende com o carro. Após derrotar/expulsar o carro, a mesma ação continua contra a fortificação, sem consumir uma segunda ação.
- Dois adversários são exibidos com arte, dano da arma fixa, defesa, vida atual e barra. O dado é animado e mostra o valor real, modificadores e resultado. Acerto produz impacto e redução da barra; erro produz esquiva; dano absorvido recebe sinal próprio.
- Antes de cada ataque, todos os jogadores aptos com uma geral compatível podem usar ou passar. G01/G02 alteram o acerto; G03 o dano; G04 a redução; G07 o acerto da ameaça. G05/G06 são consultadas na tentativa de fuga. Uma geral por jogador por turno do mapa, como no motor original. Cartas fora dessa janela não são oferecidas como reação.
- A identidade das cartas fica atrás de **Sou [jogador] · ver minhas cartas de reação**. Uma carta inicial ainda pendente do jogador que reage é revelada antes de poder ser usada, inclusive fora do turno dele. Trata-se de hot-seat local, não autenticação ou sigilo de rede.
- D6: 1 natural erra; 6 natural acerta; demais resultados somam modificadores contra a defesa. H01–H12 preservam atributos e poderes do JSON; setores novos/antigos sem perfil continuam na faixa fácil de desenvolvimento.
- A vitória sobre hostil concede 2–3, 3–4 ou 4–5 recursos conforme a faixa, sorteando sucata/combustível para a carga. A janela de resultado lista os itens efetivamente adquiridos; excedente precisa ser descartado. Conquista restaura a defesa a 4 e preserva o depósito.
- Destruição PvP entrega carga/tanque e uma carta aleatória ao vencedor, com escolha de recuperar outra categoria por 2 sucatas. A primeira destruição aplica descarte restante, renasce de Hatch e perde o próximo turno; a segunda elimina. Último sobrevivente encerra a partida. Fuga entre rodadas paga rota/combustível e concede uma carta aleatória ao adversário.
- Rolagem, dano, respostas e resultado ficam no save antes da animação. Retomar pode reapresentar o dado, mas não rola nem concede saque novamente. Saves nativos anteriores recebem atributos de combate e hostis de forma determinística, sem consumir seu RNG na migração.
- **Menu → Administrar** compra melhorias, instala/retira equipamento e melhora o Hatch por cinco sucatas próprias locais e uma ação. E01–E03 oferecem um ataque adicional compartilhado por carro/rodada, gastando munição mesmo em erro; E05/E06/E12 são declarados antes do dado. Territoriais alteram a fortificação/depósito. **Placar** mostra pontos e anúncio territorial; quatro pontos precisam ser sustentados até o próximo início próprio.

A fila de revelações também fica no save: retomar uma partida interrompida durante a compra apresenta novamente o verso pendente, sem comprar uma segunda carta. Cartas já reveladas em saves antigos não são reveladas de novo. Toda nova aquisição deve passar por `WastelandGame.gain_card`; o baralho atual continua com a mesma composição e as mesmas regras. Os versos ficam em `assets/cards/versos`, com resolução centralizada em `card_reveal.gd`: G geral, V evento, E/T o mesmo verso de equipamento/melhoria, R corrida. Frente, nome e efeito ficam ocultos até a virada.

Cada cidade tem um marcador numerado por setor. Cinza indica setor sem dono; as demais cores correspondem aos nomes na legenda. O detalhe do setor sempre mostra o nome do dono, de modo que o controle não depende apenas da cor. Explorar consome uma ação principal; retirar recursos de um depósito próprio na cidade atual é livre, respeitando a capacidade da carga.

O visual segue a composição da referência: mapa em tela cheia, painel escuro com contornos de metal, rotas disponíveis em ciano, mão na base e ação principal em laranja. A arte reutilizada é a do repositório; a imagem anexada serve como direção visual, não como fundo com controles pintados.

## Implementado e limites

| Sistema | Estado |
| --- | --- |
| Godot nativo, GDScript, renderer Compatibility | Implementado |
| 12 cidades, 35 setores e rotas originais | Importados |
| Artes existentes de mapa, veículos e catálogo | Importadas |
| 2–4 jogadores locais, nomes, seed e ordem sorteada | Implementado |
| Hatch inicial, compra, início e passagem de turno | Implementado |
| Uma viagem antes da ação, adjacência, piso e combustível | Implementado |
| Exploração de setor próprio, retirada, capacidade da carga | Implementado |
| Abastecimento da reserva e reparo simples | Implementado |
| Consulta e descarte de cartas | Implementado |
| Save próprio automático, retomada, pausa Android | Implementado; sem teste em aparelho |
| Pan, pinça, botões de zoom, painel recolhível e área segura | Implementado; sem teste em aparelho |
| Android ARM64 / paisagem e Tabuleiro Android TV | APKs de debug gerados; validação física pendente |
| Combate com arma fixa, G01–G07, hostis, mortes, fuga e conquista | Implementado; sem teste em Android físico |
| Gerais, equipamentos, territoriais, eventos e corridas | Implementados em novas partidas; E11 depende de fonte de sucata; V16 temporariamente sem efeito por decisão do usuário |
| Melhoria de Hatch, reparos complexos, troca de encontrado | Implementados; V16 não gera novas ofertas enquanto desativado |
| Saque, bloqueios e vitória territorial | Implementados; restrições adicionais do alerta de saque ainda sem definição |
| UI modernizada, áudio e animações de viagem/combate/exploração | Implementados; revisão em Android físico pendente |
| Paridade com o motor TypeScript e saves do navegador | Pendente |

Novas partidas resolvem eventos após viajar. Corridas usam pistas/marcos, inscrição de um combustível, dois participantes e prêmio com escolhas de excesso. Saque permite defesa pessoal dentro da mesma ação. Saves antigos preservam o perfil anterior; iniciar nova partida para o conjunto da campanha. A mesma seed não gera a mesma inicialização TypeScript; importação de saves React não está implementada.

## Arquitetura

- `scripts/game_state.gd`: regras da etapa atual e persistência, sem dependência da árvore visual.
- `scripts/campaign_rules.gd`, `world_rules.gd`: campanha, equipamentos, progressão, territórios, eventos, saque e corridas.
- `scripts/campaign_panel.gd`: painéis de administração, placar, escolhas e excedentes; usa a folha/tema compartilhados.
- `scripts/board.gd`: desenho do mapa, rotas, veículos e gestos.
- `scripts/main.gd`: interface, preparação e diálogos.
- `scripts/combat_rules.gd`: estados, reações, dados, dano, hostis, fuga, conquista e vidas.
- `scripts/combat_view.gd` e `dice.gd`: apresentação e animação de combate; não determinam resultados.
- `scripts/vehicle_art.gd`: artes laterais e animação via AtlasTexture/AnimatedTexture, sem APNG/WebP animado.
- `data/`: cópia dos JSON originais; não editar nos dois lugares sem revisar a sincronização.
- `assets/`: cópia das artes necessárias, sem dependência de caminhos fora do projeto Godot. Importação limitada a 1024 px para cartas e 512 px para veículos; os originais permanecem intactos.
- `tests/`: testes de regras e abertura dos fluxos da interface.

O save `user://campaign-native-v1.json` usa schema `native-stage1`. Não importa IndexedDB ou JSON do React. Em novas etapas, mudar o schema ou implementar migração explícita para não misturar regras incompletas com regras finais.

## Android

O projeto abre na horizontal e usa Compatibility. O modo local é hot-seat offline; o modo LAN usa aparelhos próprios e rede local sem serviço externo. O bootstrap seleciona a UI celular ou Tabuleiro conforme a feature de exportação. A TV tem navegação por controle e não executa ações do jogo. O anfitrião precisa permanecer disponível; não há migração automática nem garantia de hospedagem em segundo plano.

1. Instale os **export templates da mesma versão do editor** em Editor → Manage Export Templates.
2. Configure OpenJDK 17 e o Android SDK em Editor Settings → Export → Android, seguindo a [documentação oficial](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
3. Crie a pasta `godot/builds` e abra Project → Export → Android. O identificador inicial é `com.terrasdevastadas.game`; revise antes de publicar.
4. Exporte um APK de debug para instalar e testar no aparelho. Para publicação na Play Store, configure o build Gradle, exporte AAB e use sua chave de assinatura de release.
5. Verifique leitura de cartas, pinça, toque versus arrasto, recortes de câmera, pausa/retomada e desempenho em um aparelho de entrada. O teste desktop não cobre esses comportamentos físicos.

Nenhuma chave de assinatura é incluída. Credenciais, builds e cache da engine estão no `.gitignore`.

## Validação

Na raiz do repositório, com o Godot no PATH:

```powershell
# Isolar saves e configurações dos testes dentro do workspace.
New-Item -ItemType Directory -Force .tools/test-profile | Out-Null
$env:APPDATA = (Resolve-Path .tools/test-profile).Path
$env:LOCALAPPDATA = $env:APPDATA
godot --headless --path godot --editor --import --quit
godot --headless --path godot --script res://tests/smoke.gd
godot --path godot --script res://tests/ui_smoke.gd
godot --path godot --script res://tests/reveal_smoke.gd
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --path godot --script res://tests/combat_ui_smoke.gd
godot --path godot --script res://tests/modern_ui_smoke.gd
godot --path godot --script res://tests/exploration_ui_smoke.gd
```

O teste visual usa uma janela real, abre os diálogos e captura `.tools/godot-preview.png`. Os testes de regras gravam saves no perfil isolado. Execute em um terminal dedicado para não reaproveitar esse perfil ao jogar normalmente.

## Próximas etapas da migração

### Transferências e descarte

Os controles de abastecimento, excedentes, depósitos, reparo e descarte ficam desativados quando a ação é inválida. A interface consulta a mesma validação do motor e mostra o motivo no tooltip.

Em **Setores**, cada depósito próprio mostra seu estoque e a carga do carro. **Carga → Depósito** guarda uma unidade; **Depósito → Carga** retira uma unidade. Exigem turno iniciado, proprietário presente na cidade e espaço no destino (depósito padrão: 10). São operações livres.

**Depósito → Tanque** abastece diretamente até o limite do tanque, sem passar pela carga. **Enviar excedente de combustível ao tanque** aproveita apenas o excedente que couber, inclusive no resultado do combate. Nenhum recurso restante é eliminado automaticamente. A carga oferece escolha de descarte com ícones e quantidades; cartas aparecem com sua arte na seleção e na confirmação do descarte. Contadores da carga são inteiros, inclusive após carregar saves JSON.

Teste dedicado: `Godot_v4.7.2-stable_win64_console.exe --path godot --script res://tests/transfers_smoke.gd`, usando o perfil isolado descrito acima. Executar com renderização para a captura visual.

1. Fechar composição de veículos, fonte de sucata solta e semântica adicional do alerta de saque, sem inventar regras para preencher efeitos.
2. Ampliar playtests e comparações entre motores. Dados iguais e três contratos compartilhados não provam paridade integral.
3. Configurar templates/JDK/SDK, gerar APK e validar em Android físico; depois preparar distribuição assinada.
4. Medir desempenho real, leitura/toque e balanceamento antes de alterar recursos, cópias ou kits.

## Verificação da campanha

Vitória PvP recolhe carga, tanque e uma carta aleatória, com escolha de recuperar outra categoria por 2 sucatas. Moto tem dano base 2 e equipamentos sem peso. Recompensas dos hostis entram na carga; combustível precisa ser abastecido para ir ao tanque. Decisões e diferenças em relação ao React: [PVP_REWARDS_AND_MOTO.md](docs/PVP_REWARDS_AND_MOTO.md).

O mapa v3 adapta a arte ao grafo: estradas visuais usam exatamente as polilinhas da viagem. Inclui o novo acesso de terra Santa Cruz ↔ Rio Claro, totalizando 19 rotas. Detalhes e procedência das artes: [MAP_ALIGNMENT_V3.md](docs/MAP_ALIGNMENT_V3.md).

Viagens usam prévia no mapa antes da confirmação: selecione uma estrada na lista agrupada por destino, na consulta da cidade ou clique no traçado disponível. O zoom animado enquadra a rota; Cancelar devolve a câmera e Confirmar viagem executa o comando. A preferência de movimento reduzido remove a animação.

Após os prints do S23, a interface separa escala de toque e fontes, limita folhas à área segura e usa mapa panorâmico contínuo. A consulta de carta mantém ações visíveis e texto rolável. Detalhes: [S23_LAYOUT_FIX.md](docs/S23_LAYOUT_FIX.md). O runner inclui resolução 2340 × 1080 com toque/DPI simulados e fonte normal/ampliada. A correção ainda requer confirmação no S23.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1
npm.cmd test -- --configLoader native --reporter=dot
node godot/tools/compare_contracts.mjs
```

O runner restaura as variáveis do terminal e usa um perfil isolado por suíte. `-HeadlessOnly` omite os testes visuais. Logs/resultados ficam em `.tools/campaign-checks/`; a matriz de cartas é gerada em `.tools/card-support.json`. O carregador nativo do Vitest evita uma restrição do bundler no ambiente atual. Os testes visuais usam renderer real no Windows.

Saves novos guardam comandos e seed inicial para reprodução com `res://tools/replay_campaign.gd -- <caminho-absoluto-do-save>`. O replay escreve somente `user://replay-validation.json`; usar o mesmo perfil isolado de testes. Falha de escrita após ação aceita exige **Tentar salvar sem repetir ação**, disponível em Resolver encontro no menu.

Indicador de turno: HUD compartilhado local/LAN com Preparação → Ação → Encerramento, centralizado no topo; destaque atual âmbar e concluídas verdes. Apenas apresentação do estado existente; validado em layout Windows, Android físico pendente.
