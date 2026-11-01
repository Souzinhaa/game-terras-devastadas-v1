# Terras Devastadas — contexto atual Godot / Android

Atualizado em 31/10/2026. Desenvolvimento ativo: **feature/release-0.0.4**, Godot **4.7 Standard**, verificado com **4.7.2**, GDScript e Compatibility. Alvo Android em paisagem; hot-seat e LAN de 2–4 jogadores, Tabuleiro/TV público opcional.

## 1. Fontes de verdade e versões

- [Regras atuais](../rules.md), [catálogo](../rules-cards.md), [Como jogar](../docs/COMO_JOGAR.md).
- [REBALANCEAMENTO_V07.md](docs/REBALANCEAMENTO_V07.md): diferenças e hipóteses de design.
- [README.md](README.md): execução, testes, APK e limites.
- Código em `scripts/`, dados em `data/` e cenários em `tests/` confirmam a implementação.

Novas partidas: `campaign-v07`, regras `0.7`, conteúdo `0.7.0`. Build Android: `0.0.4-ui-tv`, código 6. Não confundir build com edição de regras. Saves `campaign-v06` mantêm valores/baralhos anteriores; `stage1` mantém conjunto legado limitado. Consultas, carregamento e apresentação não convertem perfil nem consomem RNG.

React/TypeScript é referência histórica separada. Não tem paridade integral de seed, recompensas ou persistência, e não recebeu as mudanças nativas 0.7. Não aplicar automaticamente contratos React à LAN. [Contexto React preservado](../docs/historico/CONTEXTO_REACT_V06.md).

## 2. Regras vigentes no nativo

Todos começam de Hatch: integridade 6, Defesa 4+, agilidade +1, consumo 1, carga 4, tanque 8 com três combustíveis, uma sucata, uma geral, um setor próprio e duas vidas. Compra também no primeiro turno. Mapa: 12 cidades, 35 setores e 19 rotas.

- Uma viagem legal antes da ação e uma ação principal. Eventos podem consumir a ação. G17 permite sua exceção explícita de viagem após bloquear.
- Exploração: até três usos por setor; 2–3 itens no depósito, com uma unidade escolhida de sucata/combustível incluída no total. O popup mostra somente o delta real.
- Água/pneu/bateria da carga → uma sucata, livre uma vez por turno próprio iniciado, fora de encontros.
- Melhorar Hatch: cinco sucatas próprias locais e uma ação; preserva integridade/combustível/vidas, inclusive Moto. Compra de melhoria: três sucatas da carga, uma por turno, sem ação.
- Moto: dano fixo 2, equipamentos sem peso; SUV/Caminhonete: Defesa 4+. Capacidades/consumos vêm do JSON, defesa efetiva de `campaign.vehicle_defense`.
- Primeira destruição: Hatch íntegro, três combustíveis, perdas normais e proteção até iniciar a próxima vez própria; não perde essa vez. Segunda elimina.
- Vitória: último sobrevivente imediato ou três pontos anunciados ao fim e sustentados até próximo início antes da compra. Indisponibilidade/perda de pontos cancela anúncio.
- Saque simples: uma ação/um combustível, D6 × D6, empate da defesa; até dois recursos ou um com T05, falha causa dois danos. Dono local apto pode escolher combate pessoal na mesma ação.
- Corrida: inscrição voluntária inclusive para revelador, um combustível, mínimo dois; devolve inscrição se não iniciar. Pistas, marcos, prêmios e rodada final permanecem.
- Ameaças novas: faixas fácil/média/difícil por cidade/setor, identidade derivada da seed sem rerrolagem. Faixa pública; nome/atributos ocultos até revelar.
- E11/V16 ficam fora dos novos baralhos. 74 definições e 148 identidades no registro; 72 definições/144 cópias disponíveis no setup, quatro identidades `unavailable`. Saves antigos preservam suas cartas.

Não há consumo automático de água/pneu/bateria, doação direta de recursos, renda de cidade ou regra nova implícita do alerta de saque.

## 3. Estado funcional e limites

Implementados: campanha, gerais de suporte/reação, equipamentos/territoriais, upgrades/reparos, depósitos/transferências, eventos/escolhas, corridas, saque, combate/fortificação, fuga, duas vidas, anúncios, save/replay, LAN autoritativa, capacidades por jogador, projeções e recibos/reconexão.

E11 depende de fonte indefinida de sucata solta. V16 foi desativado por instrução do usuário; não reativar mesmo em save com `vehicle_pool`. Ofertas já existentes seguem suas próprias regras. Condições mecânicas sem contrato, impasse especial sem dano e restrições adicionais de alerta permanecem pendentes.

Equipamento/catalogação não prova efeito funcional. Relatórios de auditoria/migração anteriores estão identificados como históricos, não como lista atual de sistemas ausentes.

## 4. Arquitetura e comandos

| Arquivo/camada | Responsabilidade |
| --- | --- |
| `game_state.gd` / WastelandGame | Nova partida, RNG LCG, comandos, inventário, cartas e persistência |
| `campaign_rules.gd` | Perfis, atributos/capacidades, instâncias, gerais, equipamentos, territórios e vitória |
| `world_rules.gd` | Eventos, escolhas, corridas, saque e ofertas |
| `combat_rules.gd` | Estados, reações, dados, dano, fuga, recompensas e vidas |
| `main.gd`, `campaign_panel.gd`, `combat_view.gd` | Coordenação/apresentação hot-seat; não sorteiam ou concedem recursos |
| `board.gd`, `route-presentation.json` | Mapa, gestos e polilinhas visuais; não redefinem conectividade/custos |
| `network/session_authority.gd` | Execução serial, permissões, save e recibos LAN |
| `network/command_catalog.gd`, `view_projector.gd` | Opções vinculadas ao ator e dados públicos/privados |
| `network/player_hud.gd`, `lan_screen.gd` | UI cliente a partir da projeção |
| `how_to_play.gd` | Texto de ajuda compartilhado, derivado de edição/modo, sem mutações |
| `ui_feedback.gd`, `board_feedback.gd` | Retorno de toque/foco e destaques de fatos públicos, sem modificar layout ou RNG |
| `network/tv_dashboard.gd` | Etapas do turno, placar minimizado permanente, encontros públicos e preferência de movimento reduzido na TV |

`act` restaura snapshot em recusa. `action_reason` simula a mesma validação isoladamente, sem escrita/RNG real. UI consulta elegibilidade e emite comandos; animação não determina resultado.

Na LAN, `game.player()` é o jogador ativo, não o assento do aparelho. `CommandCatalog` vincula args/capacidade ao ator; `ViewProjector` não fornece save completo ao cliente. Baralhos, RNG, mãos e depósitos alheios não podem vazar. Tabuleiro não hospeda nem confirma animações.

## 5. Combate e integridade da aquisição

Reações seguem a ordem circular a partir do ativo; uma geral por jogador por turno do mapa. G07 exige hostil real. Arma fixa sem munição; E01/E02/E03 compartilham um adicional por carro/rodada, pago antes do dado inclusive em erro. E03 só atinge carro. E04 passivo; E05/E06 por instância/combate; E12 descarta; E09 soma fuga; E10 uma vez por corrida. T01–T06 afetam fortificação/depósito/administração.

D6 natural um erra, seis acerta. Atributos H01–H12 e poderes vêm do JSON. Recompensa de hostil vai à carga, 2–3/3–4/4–5 sucata/combustível por faixa; não abastece. Conquista restaura resistência quatro, descarta melhorias antigas e conserva depósito.

Defesa pessoal de conquista enfrenta primeiro carro, depois fortificação se necessário, na mesma ação. Saque pessoal enfrenta somente carros. PvP entrega carga/tanque e uma carta aleatória ao vencedor real; captura de categoria diferente por duas sucatas/estrutura quatro é opcional, distinta do upgrade por cinco.

`combatFast` executa até 24 transições e para antes de escolhas, equipamento, munição opcional, fuga ou término. Não confirma/desfaz carta, recompensa, veículo ou descarte. `combatAutoPass` é preferência individual por combate, reversível antes do dado; não consome carta/cota. Preferência e `responses` normalizam IDs ao restaurar JSON. Recibos impedem repetir RNG no reenvio.

Toda aquisição de mão usa `gain_card`; toda remoção usa `take_hand_card`. Instâncias, zonas, tickets e índices de revelação permanecem coerentes na compra, tributo, descarte e instalação. Compra fora do turno pertence ao destinatário, identificado antes de revelar.

## 6. UI Android e assets

Canvas-base 1440×810, `canvas_items`/`expand`. HUD em camada própria; modal acima; área segura aplicada às folhas, leitura e botões. Cenas e tema compartilhados em `scenes/ui/`, `themes/wasteland_theme.tres`, `ui_style.gd`. Não restaurar a barra lateral do protótipo LAN.

Topo compacto, menu, veículo lateral com gaveta de carga, mão central recolhida sem faixa preta, destaque contextual âmbar. Arrasto/pinça não disparam viagem; prévia confirma o comando e cancelar restaura câmera sem custo/RNG. Mapa/rodovias usam polilinhas coerentes com seleção. Perfis de DPI não devem inflar texto.

Reações locais usam seleção privada paginada fora da rolagem do combate. Minimizar/Voltar não passa nem usa carta; Ver cartas reabre. Toque amplia, Usar carta confirma. Leitor LAN usa área de arte e texto rolável, com ações acessíveis. Ações LAN mantêm paginação e rolagem de reserva.

Botões têm retorno de toque/foco sem mudar tamanho/posição. O instalador de feedback exclui a árvore `card_reveal.gd`: a animação de compra permanece. Mudanças públicas de estrutura, veículo, conquista e turno destacam cidades; não há efeitos históricos ao entrar/reconectar nem repetição de snapshot. TV usa mapa integral, as mesmas etapas Preparação/Ação/Encerramento e quatro cartões compactos de pontos/vidas; selecionar cartão abre só dados públicos. Encontros têm barras interpoladas até o valor real. Nada disso bloqueia o motor ou pede ACK. Ver [UI_INTERACTION_TV.md](docs/UI_INTERACTION_TV.md).

Pausa restaura animação interrompida e oculta informação privada; revelação ainda pendente reaparece ao desbloquear. Tela inicial não retoma save sem identificação. Guia breve de nova partida precede a primeira entrega. Ajuda local e LAN usa o perfil real; na LAN explica aparelhos individuais.

Artes nativas em `assets/`; originais preservados. Pickup usa `picape-lateral.png`, animação em pasta `caminhonete`. Movimento lateral: 24 quadros, folha 6×4, 20 fps; considerar dimensões importadas ao recortar. Mapa/top-down é separado do veículo lateral. Versos G/V/R e E/T compartilhado não revelam nome/efeito antes da virada. Fontes Barlow/Barlow Condensed incluem SIL OFL. Não editar cache `.godot/`.

## 7. Persistência

Hot-seat: `user://campaign-native-v1.json`, schema `native-stage1`, versão 1. Nova partida preserva backup `campaign-before-new-game.json`. Preferências: `ui-preferences.cfg`.

LAN: `user://campaign-lan-v1.json` com `.bak`, credenciais em `lan-connections.cfg`. Envelope salva estado/recibos juntos. `persistence_managed` delega escrita ao serviço somente nesse modo. Falha de escrita impede novas mutações LAN até repetir a gravação; retomada usa o último estado salvo. No hot-seat, erro após ação aceita não a desfaz: repetir somente escrita com `retrySave`, sem repetir comando.

Preservar perfil, seed inicial/corrente, registro de comandos, instâncias, escolhas, recursos, revelações e combate. Defaults estruturais não embaralham baralhos nem inventam recompensas. Replays usam o perfil salvo; conversão React não existe.

## 8. APK, testes e evidências

Preset Android: `com.bhsp.terrasdevastadas`; CI de teste substitui para `com.bhsp.terrasdevastadas.preview.v07`, nome **Terras Devastadas Teste 0.7**, versão `0.0.4-ui-tv`. Instala separado do anterior. O template verificado é mínimo API 24/alvo 36, ARM64 e INTERNET. Preset TV é separado, Gradle/feature `tv_board`, ARM64/ARMv7. Não declarar TV física homologada.

CI `.github/workflows/android-debug.yml` importa, testa, exporta e verifica assinatura/pacote/permissões. Usa templates da mesma versão, JDK 17 e assinatura debug temporária por execução. Não usar esse processo para substituir chave de distribuição.

Runner: `powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1`, na raiz; `-Godot`, `-HeadlessOnly` e `-OnlySuites` disponíveis. Perfis temporários curtos e isolados por suíte evitam sobrescrever save real e a falha de cache OpenGL em caminhos longos Windows. Logs em `.tools/campaign-checks/`.

`balance_smoke`: 180 verificações da edição 0.7/compatibilidade. Regressões 0.6 usam perfil explícito. CI [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924): 180 regras + 63 sessão LAN + 201 campanha LAN, APK exportado e assinatura v2/v3 verificada. Layout LAN renderizado em Windows: 892×445, 1280×720 e 2340×1080 com recorte simulado. Novas alterações precisam de validação própria.

Não apresentar simulação desktop como Android físico. Permanecem pendentes LAN/toque/teclado/pausa/recortes em aparelhos, TV, desempenho em hardware de entrada e playtests com duração, decisões e balanceamento medidos.

## 9. Continuidade

Não acrescentar backend, bots, regras ou fontes de recurso para preencher pendências sem pedido. Não reativar V16 automaticamente. Atualizar regras, guia, ajuda compartilhada, contextos e testes quando mudar contrato. Preservar contexto histórico em documentos identificados; orientações atuais estão aqui, no README e nos contratos 0.7.
