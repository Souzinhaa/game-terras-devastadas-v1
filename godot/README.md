# Terras Devastadas — Godot / Android

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

Todos começam de Hatch com duas vidas, integridade 6, tanque 3/8, carga com uma sucata e uma geral, um setor próprio e compra normal também no primeiro turno.

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

O preset **Android** usa ARM64, pacote `com.bhsp.terrasdevastadas`, versão `0.0.4-ui-tv`. O preset **Android TV** é separado, com feature `tv_board` e Gradle. Não mudar o identificador de distribuição ou a chave de um app publicado por inferência.

Instale templates **da mesma versão do editor**, configure JDK 17/Android SDK no editor e exporte Android em modo debug. JSON e licenças das fontes entram no pacote; testes, ferramentas e docs ficam fora. Release/Play Store exige assinatura própria e configuração de distribuição; nenhuma chave de release está incluída.

O [workflow CI](../.github/workflows/android-debug.yml) usa Godot/templates 4.7.2, template Android mínimo 24/alvo 36 e SDK correspondente. Executa testes, exporta e verifica APK, assinatura, ARM64 e INTERNET. O artefato ZIP contém APK, logs e SHA256SUMS.

No CI, o pacote vira `com.bhsp.terrasdevastadas.preview.v07`, app **Terras Devastadas Teste 0.7**, instalado ao lado da variante anterior. A assinatura debug é temporária por execução: outra build do mesmo pacote pode exigir reinstalar essa variante. Preservar os dados da edição anterior; não reutilizar esse processo como assinatura de release.

O CI também prepara o source template Gradle da mesma versão e exporta **Android TV** como `com.bhsp.terrasdevastadas.tabuleiro.preview.v07`, **Terras Devastadas Tabuleiro Teste 0.7**. O ZIP reúne os dois APKs, logs e checksums; use o arquivo `tabuleiro` na TV. A verificação TV inclui launcher leanback. A instalação/experiência em TV física permanece pendente.

## Evidências e trabalho restante

A execução CI [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924) passou em **444 verificações** (180 regras, 63 sessão LAN e 201 campanha LAN), importou/exportou e verificou assinatura v2/v3. Regressões antigas e layouts renderizados passaram no Windows. Novas alterações devem registrar sua própria validação.

Faltam Android físico/TV, rede entre aparelhos, teclado/pausa/recortes/toque, desempenho em hardware de entrada e partidas humanas medidas. Balanceamento é hipótese de playtest. Permanecem sem definição a fonte de sucata solta de E11, a reativação/conteúdo de V16 e restrições extras do alerta de saque. Não inventar efeitos para preencher essas lacunas.
