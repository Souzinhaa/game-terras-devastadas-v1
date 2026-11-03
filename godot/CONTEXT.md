# Terras Devastadas — contexto técnico

Atualizado em 03/11/2026. Este é o contexto único de desenvolvimento dos apps de celular e Tabuleiro/TV. O website React/Vite foi removido por decisão do usuário. Godot 4.7 Standard, verificado com 4.7.2, GDScript e renderer Compatibility; Android em paisagem, 2–4 jogadores.

## Fontes de verdade

- [Regras](../rules.md), [cartas](../rules-cards.md) e [Como jogar](../docs/COMO_JOGAR.md): contratos e guia atuais.
- [README](README.md): execução, testes e exportação. [Rebalanceamento](docs/REBALANCEAMENTO_V07.md): compatibilidade entre edições.
- Código em `scripts/`, dados em `data/` e testes em `tests/` confirmam comportamento. Arte, catálogo e relatório não comprovam efeito funcional.
- [UI](docs/UI_IMPLEMENTATION.md), [interface contextual](docs/UI_PREMIUM_IMPLEMENTATION.md) e [TV](docs/UI_INTERACTION_TV.md): implementação e evidências desktop. Direção vigente: layout contextual, menos texto, grafite/areia, pós-apocalipse e veículos originais.

## Apps, modos e privacidade

O projeto único usa `scenes/bootstrap.tscn`. O preset Android abre o celular; Android TV usa a feature `tv_board` e abre o Tabuleiro. Manter ambos.

Features/correções sem modo explícito precisam funcionar e ser verificadas no normal/local (hot-seat) e Multiplayer LAN. Atualizar a TV quando a apresentação pública for afetada. A TV só recebe dados públicos, não ocupa assento, não hospeda e não executa comandos.

Hot-seat passa o celular com identificação antes da mão privada. Na LAN, cada jogador usa seu aparelho; o anfitrião executa os comandos serialmente. Não há migração de anfitrião nem garantia de hospedagem em segundo plano. O anfitrião precisa permanecer aberto.

No local, a preparação permite conectar Tabuleiro/TV antes de iniciar. Um lobby vazio usa o nome do jogador de ID 0 e não projeta o save carregado; ao começar, a autoridade recebe a partida real sem derrubar a conexão da TV. Menu → Conectar Tabuleiro/TV continua disponível durante a partida. Uma única TV é aprovada; clientes jogadores são recusados. Voltar ao início, sair, cancelar a preparação ou desconectar encerra a transmissão; preparar nova partida encerra a transmissão da anterior. O save LAN fica preservado.

Nomes locais (quatro campos/quantidade) e nome próprio/sala LAN são lembrados em `user://player-setup.cfg`, separados dos saves. Nome e senha LAN são opcionais; o anfitrião valida o hash da senha no handshake antes da aprovação, inclusive para TV. Nome/hash são preservados no envelope LAN; senha e hash não entram em descoberta ou snapshots. O transporte continua sem cifra, conforme o contrato LAN.

## Edições e regras

Novas partidas: `campaign-v07`, regras `0.7`, conteúdo `0.7.0`. Saves `campaign-v06` mantêm seus valores/baralhos; `stage1` mantém o conjunto legado. Carregar, consultar e apresentar não converte perfil nem consome RNG. Fixtures em `shared_contracts` preservam regressões nativas 0.6 sem depender de outro runtime.

Estado funcional: turnos, viagem/eventos, exploração, depósitos/transferências, cartas/equipamentos/territoriais, progressão/reparos, combate/hostis/conquista/fuga, saque, corridas, duas vidas, vitória, save/replay, LAN autoritativa, recibos e reconexão.

- Mapa: 12 cidades, 35 setores, 19 rotas. Setup: Hatch, integridade 6, Defesa 3+, agilidade +1, consumo 1, carga 5, tanque 3/8, uma sucata, duas gerais sem animação, um setor e duas vidas. Compra também no primeiro turno.
- Uma viagem antes da ação principal; G17 tem exceção explícita. Explorar até três vezes por setor: 2–3 itens no depósito, incluindo uma unidade escolhida de sucata/combustível. Popup exibe o delta real sem novo sorteio.
- Água/pneu/bateria da carga vira uma sucata, uma vez por turno próprio e fora de encontros. Sem consumo automático desses suprimentos, doação direta ou renda de cidade.
- Melhorar Hatch: cinco sucatas próprias locais e uma ação, preservando integridade/combustível. Comprar melhoria: três sucatas da carga, uma por turno, sem ação. Moto: dano 2, equipamentos sem peso. Defesa 0.7: Hatch 3+; Sedã/SUV/Caminhonete 4+; Moto 5+. Saves 0.6 preservam seus limiares anteriores.
- Primeira destruição: Hatch íntegro, três combustíveis e proteção até o próximo início próprio, sem perder a vez. Segunda elimina. Último sobrevivente vence; vitória territorial exige anunciar três pontos ao encerrar e manter até o próximo início, antes da compra.
- Saque simples: uma ação/um combustível, D6 contra D6, empate da defesa, até dois recursos (um com T05), falha causa dois danos. Dono local apto pode defender pessoalmente. Corrida: inscrição voluntária de um combustível, mínimo dois; devolve se não iniciar.
- Ameaças por faixa fácil/média/difícil; identidade derivada da seed, oculta até revelar. Recompensas de hostil vão à carga, sem abastecer: 2–3/3–4/4–5 sucata/combustível. Conquista restaura resistência quatro, preserva depósito e descarta melhorias antigas.
- Registro: 74 definições/148 identidades; setup usa 72/144. E11 depende de fonte indefinida de sucata solta; V16 foi desativado pelo usuário. Não reativar por inferência nem apagar cartas de saves antigos. Ofertas existentes seguem seu contrato.

## Motor e integridade

| Camada | Responsabilidade |
| --- | --- |
| `game_state.gd` / WastelandGame | Setup, RNG LCG, comandos, inventário, cartas e persistência |
| `campaign_rules.gd` | Perfis, atributos, equipamentos, territórios, vitória |
| `world_rules.gd` | Eventos, escolhas, corrida, saque e ofertas |
| `combat_rules.gd` | Reações, dados, dano, fuga, recompensas e vidas |
| `main.gd`, `campaign_panel.gd`, `combat_view.gd` | Apresentação hot-seat |
| `board.gd`, `data/route-presentation.json` | Mapa/gestos e polilinhas visuais |
| `network/session_authority.gd` | Execução serial, permissões, save e recibos |
| `network/command_catalog.gd`, `view_projector.gd` | Capacidades do ator e projeções privadas/públicas |
| `network/player_hud.gd`, `lan_screen.gd`, `tv_dashboard.gd` | Clientes e tela pública |
| `network/local_session.gd`, `network/network_endpoint.gd` | Comandos locais e transmissão local/TV |

UI consulta elegibilidade e envia comandos; regras, custos, recompensas e RNG ficam no motor. `act` restaura snapshot em recusa; `action_reason` simula em isolamento. Na LAN, `game.player()` é o ativo, não o dono do aparelho. Nunca fornecer save, baralho, RNG, mãos ou depósitos alheios ao cliente.

Toda aquisição passa por `gain_card`; remoção por `take_hand_card`, preservando instâncias, zonas, tickets e índices de revelação. Compra fora da vez pertence ao destinatário identificado antes de revelar. Recibos impedem repetir RNG no reenvio.

Em 0.7, uma geral por pessoa por rodada de combate, compartilhada entre ataques/adicionais/fuga. `round_generals` persiste e renova após ambos os ataques principais; cota do mapa é independente. Saves 0.6 mantêm a regra antiga; combate antigo sem campo conserva as cotas de `used_general`. `responses` e preferências normalizam IDs ao restaurar JSON.

D6 natural 1 erra, 6 acerta. G07 exige hostil real. Arma fixa não gasta munição; E01/E02/E03 compartilham um adicional por carro/rodada, pago antes do dado. E03 só atinge carro. E04 passivo; E05/E06 por instância/combate; E12 descarta; E09 soma fuga; E10 uma vez por corrida; T01–T06 seguem seus contratos.

Defesa pessoal de conquista enfrenta carro e depois fortificação, se necessário; saque pessoal só carros. PvP entrega carga/tanque e uma carta aleatória ao vencedor. Captura de categoria diferente por duas sucatas/estrutura quatro é opcional e distinta do upgrade por cinco.

`combatFast` avança até 24 transições e para antes de decisão; não é oferecido na LAN. `combatAutoPass` é individual e reversível antes do dado, sem gastar carta/cota. Animação não confirma decisões nem bloqueia autoridade.

## Apresentação e assets

Canvas 1440×810, `canvas_items`/`expand`; cenas/tema compartilhados, área segura, mão central recolhida, resumo lateral do veículo, carga em cartões e folhas roláveis. Não restaurar a barra lateral antiga. Arrasto/pinça e cancelar prévia não enviam viagem; excesso de carga exige decisão legal, sem descarte automático.

G17/G18 abrem o seletor visual de estradas no local e na LAN, com destaque apenas para alvos legais. Na LAN, a projeção individual inclui `card_id`/`route` das capacidades de gerais; a escolha continua usando o ID da opção autoritativa. Barricadas públicas aparecem com linha tracejada vermelha e bloqueio no meio da polilinha no celular e na TV. A carga oferece cinco operações: Abastecer, Reparar, Melhorar veículo, Depósitos e Descartar. Reparar abre uma aba exclusiva (simples livre; maior com duas sucatas/uma ação/até quatro de estrutura). Melhorar veículo reúne compra confirmada por três sucatas, equipamentos e troca em grade com miniaturas na cor do dono e prévia dos atributos. `turn_action_style.gd` padroniza símbolo 1 em círculo tracejado e âmbar nos comandos que gastam a ação principal; a LAN recebe somente o metadado de apresentação `consumes_action`, calculado na autoridade. Inclui instalação territorial remota e G17; operações livres não recebem a marca. Cobertura específica em `barricade_cargo_ui_smoke`, com capturas desktop em `.tools/barricade-*.png`; sem exportação ou teste físico Android nesta alteração.

Leitores local/LAN reservam rodapé e avançam na árvore ao abrir para receber input. `card_zoom` fica acima do leitor também na árvore. `initial_card_instances`/`initial_deal` identificam somente cartas próprias ainda não lidas; `ui-card-reading.cfg` persiste leitura sem alterar partida. Pausa oculta dados privados e conserva revelações pendentes.

`travel_presentation.gd` percorre estradas com o veículo real; `encounter_reveal.gd` apresenta a carta sem adicioná-la à mão. `encounter_effects.gd` usa deltas aceitos; `card_activation.gd` mostra a arte pública usada por quatro segundos, com fila. Cancelamentos, recusas e reconexões não revelam mão nem repetem efeitos.

`ui_feedback.gd` cuida de toque/foco; `board_feedback.gd` destaca fatos públicos. `combat_view.gd` e `race_board.gd` compartilham arenas/pistas entre local/LAN/TV. Resultados recebidos durante animação são enfileirados. Movimento reduzido mantém informação estática; pausa suspende apresentações. Efeitos não enviam comandos, consomem RNG ou exigem ACK da TV.

`player_palette.gd` e `vehicle_art.gd` usam ID estável: 0 laranja, 1 azul, 2 preto, 3 branco. Preto tem contorno claro. Artes em mapa/retrato/detalhes/arena/corrida; sem spritesheets por cor. [Procedência e limites](docs/vehicle-colors/README.md). Folhas laterais antigas: 24 quadros, 6×4, 20 fps, recortes AtlasTexture; top-down separado.

`Music` toca Aftermath, Kevin MacLeod, CC BY 4.0; MP3 e licença/créditos preservados. Local/TV reproduzem; celular LAN não duplica a TV. Volume musical padrão 0,18, independente dos efeitos; zero desliga, pausa suspende. `GameSFX` e motor respeitam efeitos/mudo. [Tela inicial](docs/START_SCREEN_BACKGROUND.md): Theora com áudio único, título à esquerda, seis ações à direita e fallback estático.

`godot/assets/` contém runtime; `assets/` na raiz guarda fontes de produção e artes originais. Manter procedência, licenças e `.import`; não editar cache `.godot/`. Fontes Barlow/Barlow Condensed usam SIL OFL.

## Persistência e builds

Hot-seat: `user://campaign-native-v1.json`, schema `native-stage1` versão 1; backup `campaign-before-new-game.json`. Preferências em `ui-preferences.cfg`. LAN: `campaign-lan-v1.json`/`.bak`, credenciais `lan-connections.cfg`; estado/recibos no mesmo envelope. Falha de escrita local pede repetir só a gravação; LAN bloqueia novas mutações até salvar.

Configuração atual no código: aplicativo **0.0.5**, código Android **17**, com aviso Em desenvolvimento; celular ARM64 e TV ARM64/ARMv7. A versão interna das regras é independente. APKs na raiz ainda são os anteriores `0.0.6-vehicle-actions`, código 16, exportados em 03/11/2026 antes das mudanças de preparação/corrida/manual/defesas desta etapa. Manifesto desses APKs: `builds/vehicle-actions-build-manifest.json`; fingerprint `01cece2fc1b9a92a5a9ca2a3ba7a1ea5a1c05be48ac05f3d059dc1363a13a1b9`. Assinatura, pacotes e alinhamento 16 KiB foram verificados naquela exportação. Nesta etapa não foram reexportados APKs nem testados aparelhos físicos. `godot/builds` mantém somente os dois APKs versionados e manifesto/SHA256SUMS da última exportação, conforme a limpeza solicitada.

A CI Android mantém os dois presets e usa identificadores preview separados. Não trocar pacote/chave de distribuição por inferência. Instruções de build/teste no [README](README.md).

## Limites reais

Limpeza de 03/11/2026: website, dependências/caches web, contextos duplicados e planos históricos substituídos removidos. Validação após a limpeza: 43 suítes do runner passaram em Godot 4.7.2/Windows, incluindo local/LAN/TV e renderização. Jornadas ENet `lan_actions_peer.gd` e `local_board_peer.gd` passaram (quatro jogadores/TV e hot-seat/TV, reconexão e recusa de comandos indevidos). Links dos documentos ativos conferidos. Logs em `.tools/campaign-checks/` e `.tools/lan-network-*/`; cópia dos documentos anteriores em `.tools/cleanup/documentation-before-cleanup.zip`. Nenhum APK foi reexportado nesta limpeza.

Testes e capturas Windows não homologam Android/TV físicos. Pendentes: rede/toque/controle remoto/teclado/pausa/recortes em aparelhos, desempenho de entrada e partidas humanas medidas. Balanceamento segue hipótese de playtest. Sem contrato para fonte de sucata solta de E11, reativação de V16, condições mecânicas adicionais, impasse especial sem dano ou restrições extras de alerta de saque. Não inventar regras para preencher lacunas.

## Interface em desenvolvimento — 03/11/2026

Versão do aplicativo solicitada: **0.0.5**, com **EM DESENVOLVIMENTO** na tela inicial. A edição interna das regras (`campaign-v07` / regras 0.7) é independente da versão do app; não foi revertida para regras antigas. Mensagem de início e manual não confundem essas numerações.

Carga local mantém cinco botões com colunas iguais e Melhorar/veículo em duas linhas. Comprar equipamento abre confirmação do custo de três sucatas e informa falta de sucata; o baralho continua misturando equipamentos e territoriais. Trocar veículo usa `vehicle_shop.gd` compartilhado no local/LAN: grade de miniaturas por ID/cor, inspeção sem comando/RNG e confirmação apenas com capacidade legal.

Menu local usa sete categorias; LAN, cinco (mais recuperação de gravação quando necessária). Histórico, placar, cidades e saída ficam em Partida; suporte e administração de cartas mantêm acesso próprio. Manual compartilhado em `how_to_play.gd` tem sete tópicos, RichTextLabel com negrito e conteúdo conforme a edição real.

Corrida local/LAN/TV recebe `decision`, `roller_id` e `reactor_id` de apresentação, sem mãos. `race_board.gd` destaca o nome/cor de quem reage ou rola; botões de dado/passe também identificam o dono. Eventos de marco suspendem a indicação de rolar. Identidade, progressão e RNG continuam no motor.

Validação final desta etapa: **46 suítes desktop passaram**; três layouts LAN foram repetidos após adequar o teste ao manual por tópicos. Evidência consolidada em `.tools/vehicle-session-validation.json`; importação final em `.tools/vehicle-session-final-import.log`. Jornadas ENet com cinco processos passaram: sala/senha (`.tools/lan-network-1477338379f74d97ab5900a57b03c133`), TV no lobby local/reconexão (`.tools/lan-network-d2d8c3e91c6c44e0b6d0ea7ee068fcb1`) e ações/combate/corrida (`.tools/lan-network-39ca819b4f4d487f871631a35e1717c5`). Capturas revisadas em `.tools/vehicle-setup-*.png`, `.tools/manual-vehicle-topic.png` e `.tools/race-turn-*.png`. Sem exportação nova nem validação física Android/TV.


## Exportação Android — 03/11/2026

APKs de celular e Tabuleiro/TV reexportados com Godot 4.7.2, aplicativo 0.0.5 e código Android 17. Esta exportação substitui os APKs anteriores citados acima. Cópias atuais na raiz: terras-devastadas.apk e terras-devastadas-tabuleiro.apk. Artefatos versionados em godot/builds/terras-devastadas-v0.0.5-android-arm64.apk e godot/builds/terras-devastadas-v0.0.5-tabuleiro.apk. Manifesto e hashes: builds/current-build-manifest.json e builds/SHA256SUMS-current.txt. Assinatura debug original preservada; pacotes, versão, ABIs, launcher TV, permissão INTERNET, recursos, licenças e alinhamento de 16 KiB verificados. Fingerprint LAN comum: 690834fc9b7b02c5f2548512fbcd8fa2160d330fcab0371a0ccad3ec230bce7a. Sem teste físico Android/TV.
