# Terras Devastadas — executar, testar e exportar

Godot 4.7 Standard, verificado com 4.7.2; GDScript, Compatibility, Android em paisagem. Projeto único para celular e Tabuleiro/TV. Estado funcional, arquitetura, versões e pendências estão no [contexto técnico](CONTEXT.md).

## Executar

Importar [project.godot](project.godot) no Godot e executar. `scenes/bootstrap.tscn` escolhe celular ou Tabuleiro pela feature `tv_board`.

No celular, Nova partida abre hot-seat; Multiplayer LAN abre conexão/lobby. Continuar identifica o jogador antes de mostrar dados privados. Na LAN, usar builds compatíveis e manter o anfitrião aberto. A TV só acompanha dados públicos. No hot-seat, Menu → Conectar Tabuleiro/TV permite disponibilizar a partida e aprovar a TV na mesma rede.

- [Como jogar](../docs/COMO_JOGAR.md), [regras](../rules.md) e [cartas](../rules-cards.md).
- [Compatibilidade de saves 0.6/0.7](docs/REBALANCEAMENTO_V07.md).
- [Protocolo LAN](docs/MULTIPLAYER_LAN_PROTOCOL.md).
- [Interface](docs/UI_IMPLEMENTATION.md), [layout contextual](docs/UI_PREMIUM_IMPLEMENTATION.md) e [interação/TV](docs/UI_INTERACTION_TV.md).

## Testar

Na raiz do repositório:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1 -Godot "C:/caminho/Godot_v4.7.2-stable_win64_console.exe"
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1 -HeadlessOnly
```

O runner encontra também `.tools/godot/Godot_v4.7.2-stable_win64_console.exe`. `-OnlySuites` seleciona suítes. Cada suíte usa perfil temporário isolado e restaura APPDATA/LOCALAPPDATA; logs em `.tools/campaign-checks/`. Suítes visuais precisam de renderer real. Testes/replays manuais também devem usar perfil isolado para não sobrescrever saves do jogador.

`balance_smoke` cobre regras 0.7 e compatibilidade. `shared_contracts` mantém fixtures nativas 0.6; não exige Node, npm ou website. Sessão/campanha LAN verificam permissões, recibos e projeções. Layouts incluem local, LAN compacto/ampliado e TV.

`barricade_cargo_ui_smoke` verifica G17/G18 pelo mapa, cancelamento sem mutação, bloqueios públicos na TV e atalhos de melhorias/equipamentos/reparo maior da carga, no local e na LAN. As capturas ficam em `.tools/barricade-*.png`.

Jornadas reais ENet com processos separados, na mesma máquina:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/test_lan_network.ps1 -PeerScript res://tests/lan_actions_peer.gd
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/test_lan_network.ps1 -PeerScript res://tests/local_board_peer.gd
```

A primeira cobre quatro jogadores LAN e TV; a segunda, anfitrião hot-seat e TV, descoberta/reconexão e recusa de clientes/comandos indevidos. Não equivalem a rede Android física.

Replay usa a edição do save:

```powershell
godot --headless --path godot --script res://tools/replay_campaign.gd -- "C:/backup/partida.json"
```

## Exportar os dois apps

Presets em [export_presets.cfg](export_presets.cfg):

| Preset | Pacote | Arquitetura | Entrada |
| --- | --- | --- | --- |
| Android | `com.bhsp.terrasdevastadas` | ARM64 | Celular |
| Android TV | `com.bhsp.terrasdevastadas.tabuleiro` | ARM64/ARMv7 | Feature `tv_board`, Gradle, Leanback |

Instalar templates da mesma versão do editor e configurar JDK 17/Android SDK. Para TV, preparar o template Gradle com `tools/prepare_android_tv.ps1`. Preservar pacote e chave de apps distribuídos. Não incluir credenciais no Git.

```powershell
godot --headless --path godot --export-debug "Android" ../terras-devastadas.apk
godot --headless --path godot --export-debug "Android TV" ../terras-devastadas-tabuleiro.apk
```

Dados JSON e licenças entram nos APKs; testes, docs e ferramentas são excluídos. `tools/verify_lan_apks.ps1 -Aapt "C:/Android/sdk/build-tools/36.0.0/aapt.exe"` verifica as cópias `builds/terras-devastadas-lan.apk` e `builds/terras-devastadas-tabuleiro.apk`; atualizar essas cópias antes de executar. Release/Play Store exige chave própria; assinatura debug não é assinatura de distribuição.

A [CI Android](../.github/workflows/android-debug.yml) prepara Godot/templates 4.7.2, JDK/SDK, testa e exporta os dois apps. Verifica assinatura, pacote, ABIs, INTERNET e launcher TV; publica APKs, logs e checksums. Usa pacotes preview separados e chave debug temporária por execução, que pode exigir reinstalar a variante preview. Não usar esse processo para substituir a edição distribuída.

## Organização e validação

`scripts/`, `scenes/`, `themes/`, `data/` e `assets/` formam o runtime. `tests/` e `tools/` verificam e mantêm os apps. `docs/` guarda contratos técnicos, procedência e evidências úteis. Artes originais ficam em `../assets/`; preservar licenças e metadados `.import`, sem editar `.godot/`.

Novas alterações precisam verificar local e LAN, além da TV quando afetada. Faltam validação física Android/TV, desempenho em hardware de entrada e playtests humanos. Nenhum teste Windows deve ser apresentado como homologação física.

Interface do veículo (local/LAN): Carga → Abastecer, Reparar, Melhorar veículo, Depósitos e Descartar. Reparos ficam em aba própria; compra/equipamentos/troca ficam em Melhorar veículo. Símbolo 1 em círculo tracejado e cor âmbar identificam uso da ação principal; detalhes acessíveis por tooltip/leitor de tela. Cobertura em `barricade_cargo_ui_smoke`, `campaign_ui_smoke` e `lan_action_menu_ui_smoke`.

Preparação: nomes e quantidade locais são lembrados. A TV pode conectar antes de Começar; a sala local usa o nome do jogador 1. Na LAN, informe opcionalmente nome e senha da sala. O aplicativo mostra **v0.0.5 · Em desenvolvimento**; a edição interna das regras tem numeração independente.

O menu da partida agrupa funções e Como jogar abre um manual por assuntos, com destaques em negrito. Compra de equipamento pede confirmação; troca de veículo mostra miniaturas e atributos antes de executar. Corrida destaca o dono dos efeitos e do dado no celular e TV.

Cobertura adicional: `vehicle_setup_ui_smoke` (nomes, preparação/TV, layout, compra/troca e defesas) e `race_manual_ui_smoke` (atores local/LAN/TV, manual, menu e versão). Handshake com senha em cinco processos: `tools/test_lan_network.ps1 -PeerScript res://tests/room_password_peer.gd`. `local_board_peer.gd` agora conecta a TV no lobby antes de criar a partida.
