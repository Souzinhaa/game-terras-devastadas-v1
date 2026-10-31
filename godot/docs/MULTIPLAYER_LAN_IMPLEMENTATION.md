# Multiplayer LAN e Tabuleiro — implementação e validação

Data: 31/10/2026. Godot 4.7.2 Standard, GDScript, Compatibility.

**Revisão atual: 0.2.1-lan-ui / código 3.** O HUD original foi restaurado no modo LAN, a preparação ganhou tela própria e a descoberta passou a consultar/responder automaticamente. Ver [correção de interface e toque](LAN_UI_TOUCH_FIX.md). As descrições da primeira entrega abaixo são históricas quando mencionam a lista lateral de ações.

## Resultado e limite da entrega

Implementados o serviço autoritativo LAN, lobby com aprovação e prontidão, comandos por capacidades individuais, projeções públicas/privadas, saves com recibos, reconexão, descoberta e uma interface LAN com mapa, cartas, inventário e decisões de campanha. O modo hot-seat permanece disponível com sua interface e save anteriores.

O aplicativo Tabuleiro tem entrada própria, somente consulta pública, navegação por teclado/controle, câmera independente, banner e configuração Android TV. Foram gerados dois APKs de debug com pacotes distintos. Testes locais de transporte, regras e UI não equivalem a homologação em Android físico: nenhum celular ou TV estava conectado no ADB durante este trabalho.

| Área | Implementação | Evidência disponível |
| --- | --- | --- |
| Servidor em celular, 2–4 jogadores, uma TV opcional | Código pronto | Cinco processos Windows, ENet real por loopback. |
| Entrada manual e descoberta UDP | Código pronto | Conexão direta testada; broadcast entre dispositivos físicos pendente. |
| Aprovação de jogador/TV, prontidão e início sem TV | Código pronto | Harness de processos; TV entra após início. |
| Separação de informações e autorização de ações | Código pronto | Testes de projeção, identidade e recusa de comando da TV. |
| Reenvio, recibos e recuperação da sessão | Código pronto | Duplicação/save em testes de sessão; desconexão/reconexão no ENet. |
| Campanha e decisões fora do turno | Catálogo integrado ao motor nativo | Testes de apoio, PvP, eventos, corrida, saque e vitórias. |
| Interface LAN e Tabuleiro | Código pronto | Renderização Windows e verificações de layout/foco. |
| APK celular | Gerado em `godot/builds/terras-devastadas-lan.apk` | Exportação e inspeção de pacote; instalação física pendente. |
| APK Tabuleiro/TV | Gerado em `godot/builds/terras-devastadas-tabuleiro.apk` | Gradle, inspeção de manifest/ABIs/banner; instalação física pendente. |
| Consumo, estabilidade prolongada, suspensão Android e controle físico | Pendente | Exigem aparelhos reais. |
| Publicação em loja | Fora da entrega | Sem publicação nem chave de release nova. |

## Como jogar pela LAN

1. Instalar o APK **LAN** nos celulares, todos da mesma build. Abrir **Multiplayer LAN** no menu inicial.
2. Um jogador informa seu nome e cria a sala. O menu mostra os endereços locais e a porta padrão 24876.
3. Nos demais celulares, informar nome e tocar na sala encontrada automaticamente. **Entrar por IP** é uma alternativa se a rede bloquear descoberta.
4. O anfitrião aceita os jogadores; cada cliente confirma **Estou pronto**. O anfitrião inicia com 2–4 jogadores conectados.
5. O topo mostra o jogador ativo e a identidade local. **Viajar / explorar** abre opções por grupo; a mão fica no rodapé e a gaveta **Carga** abre pelo resumo lateral do veículo, como no modo local.
6. Viajar abre a prévia da estrada; somente confirmar solicita a ação. Revelações usam verso, virada e confirmação de recebimento. Reações e escolhas aparecem somente ao responsável.

Na TV, instalar o APK **Tabuleiro**, que abre diretamente como tela pública. Conectar ao mesmo IP/porta; o anfitrião aprova a tela. Ela pode entrar durante uma partida e sair sem bloquear os jogadores. O app aparece no launcher Android TV e não exige toque. Para simular sua interface no editor/Windows, executar o projeto com argumento de usuário `--tv-board`.

O Wi-Fi deve permitir tráfego entre aparelhos. Redes de convidados ou com isolamento podem bloquear tanto conexão quanto descoberta. Ethernet na TV e Wi-Fi nos celulares são possíveis se o roteador permitir comunicação. Hotspot não foi homologado.

## Desconexão e saves

O cliente reconecta à mesma vaga usando sua credencial local. Se o endereço do anfitrião mudar, manter o mesmo nome no mesmo aparelho permite procurar a credencial recente; a identidade efetiva continua sendo validada pelo anfitrião. Não há recuperação de credencial após limpar os dados/reinstalar o cliente.

Se o anfitrião sair, os demais aguardam. Para continuar, reabrir **Multiplayer LAN → Retomar sessão LAN salva**, na mesma porta/endereço acessível, e aguardar as reconexões. **Retomar backup LAN** permite recuperar a cópia anterior quando existente. Isso não garante recuperar ações que ficaram com salvamento pendente antes de um encerramento.

Dados de sessão ficam em `campaign-lan-v1.json`, separados de `campaign-native-v1.json`. Criar outra sessão preserva a anterior no backup; não é conversão do save local. Repetir save nunca repete a ação. Não há migração automática do anfitrião, entrada de novo jogador no meio da partida, execução em segundo plano garantida ou regra de ausência automática.

## Organização do código

| Arquivo/área | Responsabilidade |
| --- | --- |
| `scripts/network/command_catalog.gd` | Gera opções exatas por ator e valida candidatas no motor. |
| `session_authority.gd` | Estado canônico, revisão, recibos, execução e envelope persistido. |
| `view_projector.gd` | Projeções por campos permitidos; nenhum save completo enviado. |
| `network_endpoint.gd` | Autoload comum: RPCs, lobby, credenciais, conexão e descoberta. |
| `compatibility_stamp.gd`, `addons/lan_export/` | Identificação automática das regras/protocolo nas duas builds. |
| `board_view.gd` | Dados públicos do mapa e rotas legais da visão individual, sem motor cliente. |
| `lan_screen.gd`, `scenes/lan.tscn` | Interface LAN e papel público de TV. |
| `local_session.gd` | Adaptador do comando hot-seat para o mesmo motor de regras existente. |
| `scripts/bootstrap.gd`, `scenes/bootstrap.tscn` | Entrada celular/TV por feature do pacote. |
| `game_state.gd` | Adição de persistência gerenciada e restauração validada de Dictionary. |
| `board.gd` | Aceita fachada de apresentação e enquadramento por largura no modo LAN. |

Os contratos efetivos, incluindo atores e visibilidade de recursos, estão em [MULTIPLAYER_LAN_PROTOCOL.md](MULTIPLAYER_LAN_PROTOCOL.md). A interface LAN usa menus contextuais próprios com o tema nativo; não é uma cópia integral de todos os painéis/animações hot-seat. Os resultados continuam sendo determinados pelo mesmo motor, e os limites funcionais já registrados para V16, E11 e regras abertas permanecem.

## Verificação executada

Todos os testes usaram perfil isolado no workspace, sem gravar a partida real do usuário.

| Teste | Resultado |
| --- | --- |
| `lan_session_smoke.gd` | 63 verificações, zero falhas. |
| `lan_campaign_smoke.gd` | 197 verificações, zero falhas. |
| `lan_ui_smoke.gd` | 22 verificações, zero falhas; renderização real Windows. |
| `tools/test_lan_network.ps1` | Cinco processos; quatro jogadores, TV pública admitida após início, um cliente reconectado na mesma vaga e tentativa de ação da TV recusada. |
| Regressão de regras | `smoke`, `data_validation`, `shared_contracts`, `combat_smoke`, `campaign_smoke`, `campaign_edges`, `transfers_smoke`, `pvp_rewards`: zero falhas. |
| Regressão de UI | `start_screen_ui_smoke`, `reveal_smoke`, `combat_ui_smoke`, `campaign_ui_smoke`, `onboarding_ui_smoke`: zero falhas. |
| Pacotes | Inspeção de identificadores, INTERNET, SDK, ABIs, launcher TV, banner e touchscreen opcional. |
| `lan_export_smoke.gd` com PCK exportado | Zero falhas: GDScript compilado lê fingerprint embutido e bootstrap escolhe a tela pública da TV. O PCK é somente evidência de runtime, não substitui APK. |

Registro histórico da primeira entrega (substituída pelos APKs descritos em LAN_UI_TOUCH_FIX.md): versão `0.2.0-lan`, código Android 2. Celular aproximadamente 150,4 MiB; TV aproximadamente 279,4 MiB, incluindo as duas ABIs. SHA-256 desta geração:

- Celular: `2C17127466C7889028B7F5B9F40337A65BBADFB2D337102306F82FC53DAEDFCB`.
- Tabuleiro: `BDAD90E04B6D65479218AE5E1C58A044B9189A3D89343437B40C7AA79F15141B`.

Reexportar altera os hashes; conferir os arquivos reais com `verify_lan_apks.ps1`. Tamanho de pacote não é medição de memória/FPS no dispositivo.

As fixtures dos testes de campanha preparam estados específicos para exercitar decisões, não representam partidas físicas medidas. A verificação de vitórias usa esses cenários controlados. O harness de rede testa transporte entre processos Windows; não demonstra comportamento de roteadores, Wi-Fi ou ciclo de vida Android.

Capturas de desenvolvimento ficam em `.tools/lan-player-1280x720.png`, `.tools/lan-player-960x720.png` e `.tools/lan-tv-1920x1080.png`. Logs de regressão usam `.tools/lan-*.log`; o harness imprime a pasta exclusiva de evidências de cada execução. A matriz A01–A20 do plano permanece pendente de Android físico.

Para repetir os testes, usar o perfil isolado descrito no README:

```powershell
godot --headless --path godot --script res://tests/lan_session_smoke.gd
godot --headless --path godot --script res://tests/lan_campaign_smoke.gd
godot --path godot --script res://tests/lan_ui_smoke.gd
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/test_lan_network.ps1 -Godot "CAMINHO_DO_GODOT_CONSOLE"
```

Testes que aguardam `RenderingServer.frame_post_draw`, como transferências e UI, devem usar renderer real. Não executar esses scripts em headless esperando capturas.

## Gerar novamente os APKs

Usar templates **4.7.2** correspondentes ao editor, Android SDK/build-tools instalados e **JDK 17** para o Gradle 8.11.1 do template. O Java 25/27 disponível nesta máquina não foi compatível com esse Gradle; foi utilizado um JDK 17 portátil verificado, sem alterar o Java do sistema.

**Celular:** preset `Android`, pacote `com.bhsp.terrasdevastadas`, ARM64, INTERNET e vibração opcional, sem Gradle obrigatório.

**TV:** preset `Android TV`, pacote `com.bhsp.terrasdevastadas.tabuleiro`, ARM64 e ARMv7, feature `tv_board`, INTERNET, sem vibração. Esse preset usa Gradle: apenas marcar `show_in_android_tv` na exportação sem Gradle não produziu a categoria TV no manifest nesta base.

Preparar o template da TV pelo menu Godot ou com a ferramenta fornecida. O script acrescenta banner, touchscreen opcional e suporte leanback ao template local. A pasta extraída é ignorada pelo Git; a preparação precisa ser repetida após reinstalar templates.

```powershell
# Com renderer real, gera o banner a partir das artes/fontes existentes.
godot --path godot --script res://tools/build_tv_banner.gd

powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/prepare_android_tv.ps1 `
  -TemplateZip "CAMINHO_DOS_TEMPLATES/4.7.2.stable/android_source.zip" `
  -GodotVersion "4.7.2.stable" -BuildTools "36.0.0"

godot --headless --path godot --export-debug Android builds/terras-devastadas-lan.apk
godot --headless --path godot --export-debug "Android TV" builds/terras-devastadas-tabuleiro.apk

powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/verify_lan_apks.ps1 `
  -Aapt "CAMINHO_DO_SDK/build-tools/36.0.0/aapt.exe"
```

Configurar JDK/SDK/debug keystore no editor antes desses comandos. Para isolamento, usar APPDATA/LOCALAPPDATA e `GRADLE_USER_HOME` em diretórios de desenvolvimento dedicados. No ambiente Windows deste trabalho, desativar daemon/file watching do Gradle e limitar workers no cache isolado resolveu o bloqueio de transformação de arquivos; isso não muda o código do jogo.

Os APKs atuais têm min SDK 24 e alvo SDK 36. `lan_target37` permanece desativada; elevar o alvo exige manifest e teste da nova permissão LAN em conjunto. O plugin de compatibilidade precisa permanecer habilitado na exportação. A verificação dos APKs confere também se ambos têm o mesmo fingerprint.

## Próxima validação em aparelhos

Instalar os dois APKs da mesma geração, testar primeiro dois celulares sem TV, depois quatro celulares e TV. Conferir descoberta Wi-Fi, TV por Ethernet, controle remoto, leitura à distância, suspensão e encerramento do anfitrião, reconexão durante cartas/recompensas e uma partida prolongada. Registrar modelo, Android, ABI, SDK, roteador, build e resultado. Os APKs são de debug; não houve publicação ou homologação física neste trabalho.
