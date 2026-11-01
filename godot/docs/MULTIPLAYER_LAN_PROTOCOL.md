# Contratos da sessão LAN — versão 1

## Atualização de apresentação e regras 0.7

Novas partidas usam `campaign-v07`; saves 0.6 preservam a edição. A projeção pública informa `rules_version`, `victory_target`, recuperação do carro e `threat_band` de setores neutros. Faixa não revela identidade/atributos do hostil antes da descoberta. Somente a projeção privada do dono informa `combat_auto_pass`.

`combatFast` é uma capacidade do jogador ativo, sem escolhas automáticas; `combatAutoPass` fica vinculado ao próprio ator. Reenvio usa os recibos existentes. A TV não recebe essas capacidades, cartas, recursos privados, RNG, baralhos ou save integral.

O dashboard TV usa as mesmas etapas de turno e um placar compacto com pontos, vidas e anúncio. Efeitos de dano/conquista/turno comparam somente campos públicos já resolvidos, por `match_id`/`epoch`/`revision`. Primeiro snapshot e nova epoch estabelecem baseline; snapshots repetidos não repetem efeitos. Animações não enviam confirmação, não bloqueiam comandos e não recalculam resultados. Movimento reduzido conserva os valores sem os efeitos. A ajuda local/LAN vem de `scripts/how_to_play.gd` e acompanha a edição.

Data: 31/10/2026. Implementação em `scripts/network/`. Este contrato descreve o código, complementando o [plano](MULTIPLAYER_LAN_MIGRATION_PLAN.md) e o [relatório de entrega](MULTIPLAYER_LAN_IMPLEMENTATION.md).

## Autoridade e identidades

Um celular hospeda e também joga na vaga `player_id=0`. Até três outros celulares entram como jogadores; uma tela pública pode acompanhar. O anfitrião aprova entradas. `peer_id` é transitório e nunca substitui `player_id`; a ordem de `game.state.players` pode ser embaralhada. O hot-seat usa `LocalSession` e mantém a apresentação e os saves locais existentes.

`match_id` identifica a partida salva. `epoch` muda a cada reabertura do serviço autoritativo. `revision` aumenta a cada ação aceita. Seeds do motor e credenciais de conexão usam fontes diferentes: credenciais/identificadores usam `Crypto`, sem consumir o RNG da partida.

## Entrada de comandos por capacidades

`CommandCatalog` oferece somente intenções autorizadas ao dono na janela atual. Cada candidata passa por `game.action_reason()`, que simula o mesmo motor sem escrita/RNG real. A autoridade guarda ação, argumentos exatos e identidade de instância selecionada. O cliente recebe ID opaco, legenda, grupo, confirmação e nome da ação; viagens incluem o ID público da rota para a prévia. Índices da mão/slots e argumentos executáveis não são aceitos do cliente.

Envelope efetivo, com exatamente seis campos:

```json
{
  "protocol": 1,
  "match_id": "identificador-da-partida",
  "epoch": "identificador-da-execucao",
  "revision": 42,
  "option_id": "capacidade-do-jogador-nesta-revisao",
  "command_id": "identificador-unico-da-intencao"
}
```

O ID de opção incorpora epoch, revisão, jogador, ação e argumentos. Ele funciona como o ticket de decisão desta versão: qualquer mudança de revisão invalida opções anteriores. Isso é conservador e pode pedir nova confirmação mesmo após uma mudança independente de outro jogador. A autoridade valida novamente a posse da capacidade; a interface do anfitrião usa o mesmo caminho.

Reenvio mantém ID e conteúdo. O recibo é indexado por jogador e `command_id`, com fingerprint da intenção; reutilizar o ID para outra intenção é recusado. Consultar um recibo após reconexão não executa o comando. Mensagens antigas de outra epoch são recusadas. O cliente mantém no máximo uma intenção pendente; não existe fila offline de ações para execução futura.

## Atores por família

| Família | Responsável no código |
| --- | --- |
| Turno, viagem, exploração, duelo, conquista, administração e depósitos | Jogador ativo; demais condições verificadas pelo motor. |
| Geral de suporte | Dono da carta, nos tipos/janelas já permitidos pelo motor. |
| Descarte de carta/recurso/tanque | Dono, respeitando a exceção de excesso fora do turno. |
| Revelação | Dono do ticket e da mão. |
| Defesa pessoal | Dono do setor consultado pelo combate ou saque. |
| Reação de combate/saque/corrida | Jogador devolvido por `reaction_player`, `loot_reactor` ou `race_reactor`. |
| Ativação de equipamento no combate | Dono do equipamento; o motor confere se ataca/recebe o ataque. |
| Ataque adicional | Dono do carro atacante naquela fase. |
| Tentativa de fuga e respectiva rolagem | Dono do carro que tenta escapar. |
| Rolagem/avanço/fechamento do combate | Jogador ativo que conduz o encontro. |
| Recuperação de veículo e recompensas | Vencedor real indicado pelo motor, inclusive defensor fora do turno. |
| Inscrição na corrida | Cada jogador responde pela própria inscrição. |
| Rolagem/equipamento de corrida | Participante na posição atual do cursor. |
| Escolha de evento, inspeção e surpresa | `choice.player_id`. |
| Teste/retirada/finalização de saque | Jogador ativo que iniciou o saque. |
| Repetir gravação | Serviço autoritativo acionado pelo anfitrião; nunca reaplica a ação. |
| TV | Consultas e ressincronização; nenhuma ação de jogo. |

As opções cobrem as famílias de `Game._act`, `CampaignRules.COMMANDS`, `CombatRules.act` e `WorldRules.act`. Não há encaminhamento genérico de nomes recebidos pela rede para o motor. Um comando futuro precisa ser incluído explicitamente no catálogo e nos testes antes de ficar acessível em LAN.

## Projeções e visibilidade

`ViewProjector` constrói mensagens por campos permitidos. Não copia o save completo para remover segredos depois. O mapa usa `BoardView`, uma fachada de apresentação que não instancia o motor no cliente.

| Público, inclusive TV | Somente dono | Somente autoridade |
| --- | --- | --- |
| Nomes, IDs, posições, modelo, integridade e vidas | Mão, instâncias próprias e revelações | Seeds inicial/atual e ordem dos baralhos |
| Pontos, anúncio territorial, turno e resultado | Tanque, carga e depósitos próprios | Registro completo de cartas e comandos |
| Dono dos setores, exploração e melhorias instaladas | Opções de ação e escolhas próprias | Credenciais verificáveis das vagas |
| Resistência territorial exposta e hostil já revelado | Evento/inspeção/surpresa quando revelados ao dono | Estado integral de combate/corrida/escolhas |
| Rotas bloqueadas, participantes/progresso da corrida | Delta de exploração do destinatário | Índices e argumentos reais das capacidades |
| Adversários, dados e dano públicos de combate | Credencial opaca de reconexão do aparelho | Recibos da partida completa |

Recursos são privados por padrão conservador de apresentação. Na retirada de saque, o saqueador recebe somente as opções legais necessárias, sem divulgar o inventário inteiro na TV. Melhorias instaladas, integridade e modelo são públicos; hostis não revelados não têm perfil ou resistência publicados. Se as regras de produto definirem outra publicidade para recursos, alterar o projetor e seus testes explicitamente, sem mudar os cálculos do motor.

Frentes de cartas pendentes não aparecem em rótulos, tooltips ou acessibilidade antes da virada no aparelho dono. A TV não recebe essas cartas. Mensagens de erro do motor e logs internos não são enviados integralmente; a autoridade devolve recusa genérica filtrada quando a opção deixou de ser válida.

O anfitrião é confiável e conhece a partida completa. O protocolo atual não cifra o transporte. Não oferece proteção contra anfitrião adulterado nem contra captura de tráfego na rede local.

## Persistência

- Local: `user://campaign-native-v1.json`, contrato anterior preservado.
- LAN autoritativa: `user://campaign-lan-v1.json`, schema `wasteland-lan`, versão 1.
- Backup LAN: `campaign-lan-v1.json.bak`; recuperação explícita no menu.
- Credencial do aparelho: `user://lan-connections.cfg`, separada do save e das preferências.

O envelope LAN contém estado completo, versões, match, revisão, vagas e recibos. `Game.persistence_managed` suprime as escritas internas somente nesse modo; a autoridade escreve estado e recibos juntos via temporário/rename. O save local não é convertido nem substituído.

Uma ação pode estar aplicada em memória e com gravação pendente. Nesse caso a sessão bloqueia novas mutações, mantém consulta e oferece repetir a escrita. `saved=false` não significa “ação recusada”. Se o processo terminar antes da recuperação, a retomada usa o último save válido; clientes consultam recibos e reconciliam a revisão sem repetir intenções automaticamente.

Não há migração automática de anfitrião ou importação de hot-seat/React para LAN. Retomar a mesma sessão exige as credenciais existentes dos clientes. O aparelho anfitrião continua responsável pela disponibilidade; a TV não assume o servidor.

## Transporte, descoberta e versões

- ENet/UDP: porta padrão **24876**; configurável na interface.
- Descoberta UDP: anfitrião escuta **24877**; clientes usam portas efêmeras e enviam consultas por broadcast a cada aproximadamente 2 segundos. O anfitrião responde por unicast com IP e porta real do jogo. Anúncios periódicos complementam a consulta; salas expiram após aproximadamente 7 segundos. A lista identifica cada sala por IP e porta.
- Conexões remotas máximas do transporte: 8, incluindo entradas ainda não admitidas; vagas de jogo máximas: 4 no total; TV admitida: 1.
- Limite de pedidos de aplicação: 20 por segundo por peer. Comandos: envelope até 2048 caracteres serializados; descoberta: até 1024 bytes e até 16 salas guardadas.
- Timeout inicial: aproximadamente 12 segundos; nova tentativa após aproximadamente 4 segundos, sem repetir comandos de jogo.
- `NetworkEndpoint` fica em `/root/NetworkEndpoint` nos dois aplicativos, com as mesmas declarações RPC.
- O plugin `addons/lan_export` injeta `data/network-build.json` durante a exportação. O fingerprint inclui código de regras/protocolo e dados de jogo/mapa, independentemente do GDScript estar compilado no APK. Em editor, calcula o mesmo valor diretamente das fontes.
- Builds incompatíveis são recusadas antes da atribuição de vaga. Perfil e permissões Android não alteram o fingerprint das regras.

Os APKs desta entrega usam min SDK 24 e alvo SDK 36. O caminho de permissão `ACCESS_LOCAL_NETWORK` existe atrás da feature `lan_target37`, mas não é ativado nesses presets. Uma migração futura para alvo 37+ deve habilitar essa feature e declarar a permissão junto com a configuração Gradle correspondente; ainda exige teste físico de concessão/revogação.
