# Implementação da campanha v0.6

Data: 30/10/2026. Implementação posterior à [auditoria e plano](GAMEPLAY_AUDIT_AND_PLAN.md). Runtime: Godot 4.7.2 Standard, Compatibility. Alvo permanece Android em paisagem e hot-seat local.

## Entrega e limites

O jogo agora possui comandos e interface para progressão de Hatch, reparos complexos, compra/instalação/remoção de melhorias, armas adicionais com munição, territoriais, gerais de suporte, bloqueios, saque com defesa pessoal, eventos, corridas e vitória territorial. Não foi acrescentado backend ou multiplayer de rede.

O plano inteiro **não deve ser marcado como validado em produção**: faltam decisões de conteúdo, configuração de exportação e avaliação física/humana. E11 opera sobre sucata solta existente, mas não foi inventada uma fonte automática. Por decisão posterior do usuário, V16 está temporariamente sem efeito: não gera veículos, mesmo com `vehicle_pool` configurado. O catálogo, as cópias e ofertas preexistentes em saves são preservados; não reativar sem nova instrução.

| Etapa do plano | Estado entregue | Limite restante |
| --- | --- | --- |
| 0 — A01–A05 | Corrigidos; regressões do motor e jornada real de tributo/excesso | Android físico pendente |
| 1 — Base e ferramentas | Consultas de capacidade/elegibilidade, 148 instâncias preservadas nos quatro baralhos, validação de save, rollback de recusa, escrita repetível, runner, matriz e replay | Comparador cobre três contratos, não toda a regra; CI hospedada não configurada |
| 2 — Progressão e reparos | Upgrade por cinco sucatas locais/ação, Moto com dez combustíveis, reparos por modelo, gerais de suporte, peças superiores por modelo | Usos novos para água/pneu/bateria continuam sem regra |
| 3 — Equipamentos | Reserva, slots, únicos, instalação/remoção, passivos e ativações E01–E12 | E11 precisa de fonte de sucata solta aprovada para aparecer em partidas normais |
| 4 — Territórios | T01–T06, instalação remota, pontos, anúncio/cancelamento/confirmação, placar e proteção local | Casos adicionais de design devem continuar documentados/testados |
| 5 — Saque/bloqueios | Custos, escolha de defesa pessoal na mesma ação, teste simples, G19/G20, retirada escolhida, T05, G17/G18 e proteção da última saída | Alerta tem fonte/expiração; nenhuma proibição extra foi inventada |
| 6 — Eventos | Escolhas e revelações persistem, V15 temporário, V12–V14 chamam corrida | V16 desativado por decisão do usuário; resolve sem efeito |
| 7 — Corridas | Três pistas, inscrição/refundo, ordem, gerais/E10, R01–R16, marcos, rodada final, desempate, morte/retirada e prêmio | Balanceamento e ergonomia ainda não medidos com pessoas |
| 8 — Playtest | Protocolo e campos de coleta abaixo | Não houve sessão humana ou balanceamento empírico |
| Android | Preset preservado, pausa protege privacidade, tentativa de exportação executada | Sem APK: perfil isolado sem templates/JDK/SDK; sem aparelho físico |

## Como usar no jogo

- **Cidade / setores** abre os setores e oferece acesso à administração e ao placar. Depósito rival local permite iniciar saque.
- **Menu → Administrar / equipamentos / veículo** compra melhoria por três sucatas, instala/retira cartas, mostra slots e custos, executa reparo complexo e melhora Hatch por cinco sucatas próprias locais e uma ação.
- **Carta ampliada → Usar / instalar** mostra alvos e opções. Gerais de combate, saque e corrida aparecem nas respectivas janelas de reação.
- **Menu → Gerais de outros jogadores antes da ação** permite ajuda/interferência compatível com a janela, usando a cota do dono da carta e identificação privada. Cartas que exigem turno próprio continuam restritas.
- No combate, E01–E03 aparecem depois do ataque fixo, antes de continuar. O disparo adicional paga munição antes de rolar; a cota é compartilhada entre armas do carro por rodada. E05/E06/E12 aparecem antes do dado.
- Viagem de nova partida abre evento pelo verso. Identificação do dono precede a revelação/efeito; escolhas de recurso e surpresas ficam no save.
- **Resolver encontro / excedentes** reabre escolhas e descarte. Ganhos fora do turno podem exigir entrega privada ao destinatário; ao terminar, a identificação do jogador ativo é solicitada novamente.
- **Placar** mostra pontos de cidades completas, vidas restantes e anúncio. O anúncio nasce no fim do próprio turno com pelo menos quatro pontos e só confirma no próximo início, antes da compra, se não tiver sido cancelado.

Botões da campanha consultam `action_reason`: simulação síncrona em snapshot, usando o mesmo validador do comando sem mudar RNG nem salvar. Motivos de bloqueio aparecem em texto, além do tooltip. A consulta não é executada por frame.

## Arquitetura e persistência

- `game_state.gd` permanece a entrada de comandos. Recusa restaura snapshot se houve alteração parcial. A UI não rola dados ou concede recompensa.
- `campaign_rules.gd` calcula capacidades, atributos, limites por tipo, efeitos de instalação, progressão e vitória. `world_rules.gd` controla encontros e escolhas. `campaign_panel.gd` usa a folha e o tema compartilhados.
- Nova partida conserva o envelope nativo e registra `rules_profile=campaign-v06`, versões 0.6/0.6.0, seed inicial, nomes e comandos aceitos. Não existe conversão de save React.
- Save anterior sem perfil novo mantém sua sequência e seu RNG. Campos estruturais recebem defaults sem embaralhar novos baralhos nem gerar ganhos. Para jogar o conjunto novo, iniciar nova partida.
- As 148 cópias têm identidade no registro de cartas desde o setup. Compra, descarte e reciclagem preservam essas identidades; a seleção de cópia não depende da ordem das chaves do JSON. A mão mantém IDs de definição para compatibilidade com a UI e uma lista paralela de instâncias. Instalação e transferência de tributo preservam identidade. As remoções continuam usando `take_hand_card`; aquisições de mão usam `gain_card`.
- Na leitura, jogadores, recursos, IDs, instâncias, revelações, fases e estruturas de encontros são validados antes de substituir a partida. Um arquivo incompatível permanece preservado.
- Falha de gravação após um comando aceito registra `persistence_error`. A ação não deve ser repetida: **Tentar salvar sem repetir ação** executa só a escrita. O teste força falha de destino e verifica recursos/RNG intactos na repetição.
- Redução local de cidade completa é automática no primeiro dano positivo elegível da cidade por turno do mapa; o uso é compartilhado entre carro/fortificação dessa cidade e não renova por rodada. Não gera renda.
- Alerta de saque registra fonte e expira no início da próxima vez do saqueador. Não foi criada restrição adicional sem regra definida.

## Ferramentas e reprodução

Na raiz do repositório:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File godot/tools/run_checks.ps1
npm.cmd test -- --configLoader native --reporter=dot
node.exe node_modules/typescript/bin/tsc --noEmit
node godot/tools/compare_contracts.mjs
```

O runner encontra o executável local ou aceita `-Godot <caminho>`. `-HeadlessOnly` executa dados/regras. Cada suíte tem APPDATA/LOCALAPPDATA próprios; o runner restaura as variáveis, registra exit code e erros de script e encerra uma execução que ultrapasse 45 segundos. Logs/resultados ficam em `.tools/campaign-checks/`.

`data_validation.gd` verifica contagens 74/148, baralhos, IDs, rotas, artes e divergência dos 11 pares de JSON. Gera `.tools/card-support.json`, distinguindo efeitos implementados de E11/V16 dependentes de conteúdo e marcando Android como não validado.

`shared_contracts.gd` e `native_contract.test.ts` executam os mesmos contratos de upgrade da Moto, reparo do sedã e controle de todas as cidades. O comparador compara os relatórios dos dois runtimes. Isso não exige nem comprova que a seed de inicialização seja igual entre motores.

Replay de um save novo, com APPDATA/LOCALAPPDATA já isolados:

```powershell
$replayFile = (Resolve-Path .tools/replay-fixture.json).Path
& .tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path godot --script res://tools/replay_campaign.gd -- $replayFile
```

O replay usa seed/nomes/comandos, confere RNG antes/depois e compara estado normalizado. Não sobrescreve o arquivo de entrada; grava seu resultado em `user://replay-validation.json`. Saves sem histórico reproduzível são recusados, sem inventar seed inicial.

## Evidências executadas

- Suítes nativas de dados, regras, combate, campanha, bordas e contratos compartilhados.
- Suítes com renderer real: UI, revelações, combate, transferências, modernização, exploração e campanha.
- Vitest: **246 testes em nove arquivos**, incluindo três contratos novos. TypeScript sem erros.
- Comparador: três contratos equivalentes.
- Replay: fixture com onze comandos reproduziu estado e RNG.
- Registro: sessenta turnos com reciclagem conservaram as mesmas 148 identidades; retomada conserva RNG, identidade/posse das cartas e anúncio territorial.
- Painéis de administração, evento e corrida inspecionados em capturas; teste da campanha executado em 1280×720 e 960×720. O painel administrativo não ultrapassa a largura útil.

As capturas transitórias ficam em `.tools/campaign-administration.png`, `campaign-event.png` e `campaign-race.png`. Testes Windows não provam tamanho físico de toque, desempenho Android nem acessibilidade de aparelho. O aviso de certificados do Windows continuou aparecendo sem impedir os testes locais.

A tentativa de `--export-debug Android` no perfil isolado recusou a exportação por templates 4.7.2 ausentes e caminhos JDK/SDK inválidos, incluindo `platform-tools`, `adb`, `build-tools` e `apksigner`. Não foi gerado APK nem realizada instalação em aparelho. A configuração não foi preenchida com caminhos inventados.

## Trabalho que exige definição ou validação externa

1. V16 foi deixado sem uso por decisão do usuário; sua composição deixa de ser uma decisão necessária enquanto estiver desativado. A fonte de sucata solta de E11 continua pendente. Não gerar veículos/sucata automaticamente para preencher esses efeitos.
2. Restrições adicionais do alerta, exploração regional, distribuição de dificuldade, impasse sem dano e reconquista com nova ameaça: conservar os limites das regras, sem criar novos efeitos.
3. Toolchain Android e aparelhos: configurar templates correspondentes, JDK/SDK, gerar APK e validar toque, teclado, Voltar, recortes, pausa/retomada, privacidade, acessibilidade e consumo em sessão prolongada.
4. Playtests com duas e depois três/quatro pessoas. Registrar seed/build, modelos, tempo até upgrade, combustível/munição, duração/rodadas de combate, espera, anúncio e cancelamentos, mortes e reconstrução após o turno perdido. Não alterar números com base apenas em testes automáticos.

Modelo de registro para cada sessão:

| Campo | Valor a coletar |
| --- | --- |
| Identificação | Build, aparelho, seed inicial, quantidade de jogadores |
| Compreensão | Objetivo explicado sem ajuda, custo da próxima ação identificado |
| Economia | Turno do primeiro upgrade, usos de sucata, compras sem ação útil, combustível/munição restantes |
| Ritmo | Duração da partida, tempo entre decisões, rodadas por combate/corrida |
| Recuperação | Primeira morte, turno perdido, decisões úteis até a segunda destruição |
| Vitória | Pontuação, anúncios, respostas adversárias e motivo do encerramento |
| Problemas | Comando, estado/seed, comportamento esperado/observado e captura quando aplicável |
