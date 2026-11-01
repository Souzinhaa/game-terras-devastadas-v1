# Auditoria do jogo e plano de implementação

> Registro histórico de uma etapa anterior. Números, ausências e pendências abaixo descrevem aquela revisão, anterior às regras 0.7 e/ou à LAN atual. Para desenvolvimento Android, usar [CONTEXT.md](../CONTEXT.md), [regras atuais](../../rules.md), [Como jogar](../../docs/COMO_JOGAR.md) e [rebalanceamento 0.7](REBALANCEAMENTO_V07.md). A CI Android e a implementação LAN posteriores estão documentadas nesses pontos de entrada.

Data: 30/10/2026. Escopo principal: Godot 4.7 Standard / Android em paisagem, offline, hot-seat para 2–4 jogadores. Esta é a auditoria original, anterior à implementação. O estado posterior, testes e pendências estão em [CAMPAIGN_IMPLEMENTATION.md](CAMPAIGN_IMPLEMENTATION.md); as lacunas abaixo descrevem o momento do diagnóstico.

## Diagnóstico

O ciclo básico existe: iniciar turno, comprar/revelar carta, viajar, explorar ou combater, administrar recursos e passar o aparelho. A maior lacuna é conectar esse ciclo às decisões estratégicas prometidas pelas regras: desenvolver o veículo, comprar e usar melhorias, disputar depósitos e sustentar cidades para vencer.

Há problemas de correção anteriores à expansão. Foi reproduzido um travamento de partida por excesso de cartas recebido fora do turno, além de quatro divergências em prioridade, capacidade e elegibilidade de carta. Os testes existentes passam, mas não cobrem esses cenários.

Recomendação: corrigir esses caminhos, consolidar validação/persistência e então entregar equipamentos, progressão e objetivo territorial em etapas completas de motor → interface → save → testes. A integração Android deve começar cedo com o recorte atual e acompanhar as demais etapas.

### Fontes e confiança

- Contratos: [rules.md](../../rules.md), [rules-cards.md](../../rules-cards.md), [REGRAS_V06.md](../../docs/REGRAS_V06.md) e JSON correspondentes.
- Estado nativo: [CONTEXT.md](../CONTEXT.md), [README.md](../README.md), [UI_IMPLEMENTATION.md](UI_IMPLEMENTATION.md), código e testes em `scripts/` e `tests/`.
- Referência de implementação: `src/engine/game.ts`, `cardRules.ts`, `catalog.ts`, `hostiles.ts`, configurações e testes TypeScript. As regras prevalecem quando houver divergência; passar nos testes React não prova cobertura integral do contrato.
- Evidência alta: caminho confirmado no código ou cenário reproduzido. Hipóteses de ritmo, diversão e balanceamento permanecem hipóteses até sessões com pessoas.

Os 11 JSON com equivalentes em `src/data/` e `godot/data/` têm conteúdo semanticamente igual nesta auditoria. Isso comprova sincronização dos dados, não implementação dos efeitos. `rebalance.json` ainda identifica versões `0.5`/`0.2`; não deve ser usado sozinho para inferir a edição da partida.

## Objetivos, meios e ferramentas de jogo

| Tipo | Objetivo | Evidência/confiança |
| --- | --- | --- |
| Jogador | Ser o último sobrevivente ou sustentar 4 pontos de cidades completas até o próximo turno após anúncio | Explícito nas regras; alta |
| Experiência | Tensão entre expansão, sobrevivência, preparação e interferência dos adversários | Inferido das regras e da apresentação; precisa de playtest |
| Produto | Jogo local legível e privado em um Android compartilhado, com retomada segura | Explícito nas instruções e no projeto; alta quanto à intenção, validação física pendente |

| Objetivo | Meio | Ferramentas previstas | Sustentação atual |
| --- | --- | --- | --- |
| Sobreviver e eliminar rivais | Tática e gestão de risco | Arma fixa, gerais, fuga, reparos, duas vidas | Funciona parcialmente; faltam equipamentos, progressão e reparo complexo |
| Vencer por cidades | Estratégia territorial e logística | Controle integral, pontos, anúncio, defesa local, melhorias e depósitos | Conquista/depósitos existem; pontuação, anúncio e bônus local ausentes |
| Construir um veículo competitivo | Otimização de recursos | Compra de melhorias, dois slots, munição, escolha de modelo e limites por instância | Catálogo e artes existem; cadeia de aquisição/instalação/efeito ausente |
| Interferir nas escolhas adversárias | Pressão e controle de caminhos | Gerais, bloqueios, saque, eventos e corridas | Reações G01–G07 existem, com problemas de prioridade/elegibilidade; demais caminhos ausentes |
| Entender e executar decisões no celular | Informação e interação | Custos visíveis, motivos de bloqueio, cartas legíveis, toque e privacidade | Boa estrutura de UI; faltam feedback das novas mecânicas e validação física |

A tensão e a satisfação com progressão são objetivos inferidos, não resultados demonstrados. Arte, animação e presença de cartas não comprovam essas experiências.

## Inventário funcional

| Sistema | Cadastrado | Funcional no Godot | O que falta |
| --- | --- | --- | --- |
| Preparação, mapa, turnos e viagem | Sim | Sim | Eventos após viagem, efeitos temporários e exceção de viagem após G17 |
| Exploração | Sim | Sim | Resolver excedente de depósito; perfis regionais continuam abertos |
| Transferências carga ↔ depósito e abastecimento | Sim | Sim | Generalizar capacidades com E07/E08/T04; descarga do tanque prevista na referência |
| Gerais G01–G07 | Sim | Sim, com falhas identificadas | Prioridade circular e distinção entre hostil e fortificação |
| Gerais G08–G24 | Sim, inclusive no baralho | Não | Efeitos, alvos e janelas conforme dependências |
| E01–E12 | Sim | Não | Compra, instâncias, reserva, instalação, remoção, ativações e passivos |
| T01–T06 | Sim | Não | Reserva, espaços, instalação local/remota, efeitos e descarte na conquista |
| Hostis H01–H12 | Sim | Regras de atributos/poderes disponíveis | Distribuição nova ainda usa apenas H01–H04; não inventar distribuição regional/média/difícil |
| Conquista, duelo, fuga, duas vidas e sobrevivência | Sim | Sim | Correções auditadas; reutilização segura para saque/evento e dano fora do combate |
| Saque | Regras/React | Não | Teste simples, defesa pessoal, alerta e escolhas de recursos |
| Administrar e progressão | Regras/React | Apenas reparo simples | Reparo complexo/territorial, upgrade e veículos encontrados |
| Eventos V01–V16 | Sim | Não | Baralho, resolução imediata, escolhas, encontros temporários e convites |
| Pistas P01–P03 e surpresas R01–R16 | Sim | Não | Inscrição, rodadas, marcos, desempate, prêmio e retomada do turno |
| Vitória territorial e bônus de cidade completa | Regras | Não | Pontuação, anúncio, cancelamento, confirmação e redução local de dano |
| Save nativo e revelações | Sim | Sim, com validação limitada | Validação profunda, versões de conteúdo/regras e preservação dos novos estados |
| UI compartilhada, tema, privacidade e acessibilidade | Sim | Parcialmente validado em Windows | Motivos acessíveis por toque, novos fluxos, pausa/retomada e aparelho real |
| Android | Preset ARM64 | Não validado em aparelho | Toolchain, APK, instalação, desempenho, entrada e ciclo de vida |

### Conteúdo hoje sem função suficiente

O catálogo contém 74 definições e 148 cópias. Das 48 gerais colocadas no baralho nativo, 14 cópias correspondem a G01–G07 e 34 a efeitos indisponíveis: **70,8% da composição inicial do baralho geral não tem efeito executável**. Isso não é a probabilidade fixa de cada compra após alterações do baralho, nem uma medida de equilíbrio.

Combustível e sucata têm consumo funcional. Munição, pneus, bateria e água podem ser encontrados, armazenados ou descartados, mas não têm consumo funcional atual no Godot. A munição passa a ter destino com E01–E03; não há regra aprovada suficiente para inventar consumo periódico de água ou manutenção por pneus/baterias. A exploração sorteia os seis recursos, portanto muitos resultados atualmente pressionam espaço sem abrir uma decisão de uso.

Todos continuam de Hatch porque o upgrade não foi migrado. Artes e estatísticas de outros modelos não criam escolha de veículo nem acesso normal às rotas de terra. No mapa, `board.gd:6` e `board.gd:242` ainda usam a mesma textura superior de Hatch para todos; isso deve acompanhar a entrega da progressão.

## Falhas reproduzidas e prioridades

P0 = pode impedir a continuidade da partida. P1 = regra central ou integração incorreta. P2 = manutenção, clareza ou risco ainda sem reprodução de impacto no aparelho.

### A01 — P0: sexta carta recebida fora do turno trava a partida

**Evidência:** `scripts/game_state.gd:165`, `:166`, `:233` e aquisição por fuga em `scripts/combat_rules.gd:304`.

**Reprodução:** um defensor com cinco gerais recebe o tributo de um atacante que foge; o combate fecha e a vez passa ao defensor. Após revelar a carta recebida, ele tem seis cartas e `started=false`. `start` responde “Descarte cartas até ficar com cinco gerais”; `discard` responde “Inicie o turno”; `end` também é recusado pelo excesso. Todas as ações anteriores da reprodução foram aceitas pelo motor.

**Correção planejada:** tratar resolução de excesso como janela própria, acessível antes do início e fora do turno para o dono afetado, com identificação privada. Não comprar outra carta, resetar cotas ou exigir início do turno para resolver esse excesso. Preservar `gain_card`, tickets e remoção por `take_hand_card`.

**Aceite:** receber uma sexta carta, revelar, escolher descarte e continuar; repetir com save/reload antes da revelação e durante a escolha, sem duplicar carta ou alterar RNG.

### A02 — P1: reações começam no primeiro jogador do array

**Evidência:** `scripts/combat_rules.gd:111` percorre `players` desde o índice zero, sem deslocar pela vez atual.

**Reprodução:** ordem `[1, 2, 0]`, ativo `2`, todos com uma geral elegível; a primeira reação é oferecida a `1`. O contrato determina ativo e depois ordem circular.

**Correção/aceite:** enumerar os participantes a partir de `active`, ignorar indisponíveis e respondidos; verificar todas as posições de vez em partidas de 2, 3 e 4 pessoas, inclusive fuga. A cota geral continua uma por turno do mapa.

### A03 — P1: exploração ultrapassa capacidade do depósito sem resolução

**Evidência:** `scripts/game_state.gd:215` adiciona recursos sem consulta à capacidade e não há resolução de excedente de depósito no encerramento.

**Reprodução:** setor próprio com dez recursos; explorar foi aceito, depósito terminou com doze e `end` foi aceito. A UI também oferece exploração nesse estado.

**Correção/aceite:** manter o ganho real de exploração e abrir resolução do excedente, permitindo os ajustes legais e descarte escolhido no depósito; impedir progresso normal até resolvê-lo. Não cortar ganhos silenciosamente nem conceder recursos ao reabrir o popup. Testar tanque/carga cheios e futura capacidade T04.

### A04 — P1: conquistar/duelar ignora excesso de carga

**Evidência:** `scripts/game_state.gd:167` encaminha comandos de combate antes da validação de carga em `:171`.

**Reprodução:** Hatch com cinco recursos e capacidade quatro consegue iniciar conquista e gastar a ação. O estado foi preparado diretamente como teste do validador; não se afirma que seja uma jornada normal da UI atual.

**Correção/aceite:** uma consulta central deve identificar excedentes e liberar apenas comandos de resolução adequados à janela. Conquistar/duelar nessas condições deve recusar sem gastar ação, RNG, carta ou recurso.

### A05 — P1: G07 pode fortalecer fortificação sem ameaça

**Evidência:** `scripts/combat_rules.gd:108` considera `right.player_id < 0` suficiente para G07; fortificação e hostil usam o mesmo valor.

**Reprodução:** em setor rival sem hostil, o ataque da fortificação oferece G07 e aceita seu uso, aplicando `attack=1`. O texto exige ataque de ameaça.

**Correção/aceite:** distinguir combatente carro, hostil territorial, fortificação e futuro hostil de evento; oferecer G07 somente quando houver ameaça válida atacando. Manter G01–G04 conforme seus alvos.

### A06 — P1: cartas sem efeito entram na economia da mão

**Evidência:** `scripts/game_state.gd:50` inclui todas as gerais; `scripts/main.gd:915` informa indisponibilidade fora de G01–G07.

**Impacto:** compra e limite de mão funcionam, mas a maior parte do baralho não abre uma ação. Isso distorce qualquer playtest de cartas, combustível e progressão.

**Encaminhamento:** migrar por grupos e usar uma matriz de suporte no desenvolvimento. Preservar a composição contratual; reduzir o baralho para apenas cartas prontas seria um modo de teste com regras diferentes e exigiria identificação explícita e autorização. Não alterar saves em andamento para “corrigir” a distribuição.

## Riscos técnicos e ferramentas mal aproveitadas

| Achado | Evidência e limite | Tratamento no plano |
| --- | --- | --- |
| Validação de save superficial | `game_state.gd:335` verifica envelope, chaves e índices básicos; não valida completamente jogadores, recursos, IDs, cartas, revelações ou fases antes de instalar `state=loaded` | Carregar em candidato, validar e migrar, depois substituir estado; preservar original incompatível/corrompido |
| Estado é alterado antes de confirmar escrita | `act` modifica o Dictionary e depois retorna erro de `save_game` se persistência falhar | Distinguir comando aceito de falha de persistência e permitir repetir a escrita sem repetir o efeito; testar falha de gravação |
| Versão de conteúdo e seed inicial ausentes | Save novo guarda schema/versão estrutural e `seed` corrente, mas não uma versão separada de regras/conteúdo ou `initial_seed` | Registrar novos metadados para novos jogos; não inventar seed inicial de saves antigos |
| Constantes de regras espalhadas | Reparo usa vida máxima fixa 6 em `game_state.gd:218` e `:250`; UI e motor repetem limites/condições | Consultas de atributos/capacidades e elegibilidade no motor; remover valor de Hatch antes de liberar upgrades |
| UI repete parte das regras | `main.gd:783` calcula disponibilidade da exploração; outras ações já usam `transfer_reason`/`inventory_reason` | Expandir o padrão existente para exploração, viagem, cartas, instalação e administração |
| Crescimento do coordenador visual | `main.gd` tem aproximadamente 1.060 linhas e concentra muitos painéis | Extrair painéis quando cada sistema entrar, mantendo cenas/tema compartilhados; tamanho sozinho não prova problema de desempenho |
| Motivos escondidos em tooltip | `main.gd:852` desativa botões e guarda motivo em `tooltip_text` | Acrescentar motivo curto visível/consultável por toque e acessibilidade; ergonomia deve ser verificada no aparelho |
| Avisos de teclado por frame em Windows | Teste de transferências produziu avisos repetidos em `main.gd:97` enquanto setup estava aberto | Restringir consulta ao suporte/contexto adequado, sem remover o tratamento de teclado Android |
| Testes dão cobertura parcial | Suítes atuais passam, mas os cinco cenários auditados não são detectados | Testes de transições inválidas, sequência de turnos, ganho fora da vez, persistência e conservação |
| Pipeline de dados depende de revisão manual | Cópias estão iguais hoje; não há comando único de sincronização/validação Godot | Validador de catálogo/rotas/assets e relatório de suporte; geração/cópia controlada com diff |
| Testes/build nativos sem execução única no repositório | Há scripts separados, sem workflow `.github/` nesta árvore | Runner PowerShell com perfis isolados, exit code por falha e logs; CI quando houver ambiente adequado |

### A referência React também tem lacunas

Não portar `cardRules.ts` automaticamente como se cada comportamento estivesse completo:

- O saque com dono operacional local é recusado por `src/engine/cardRules.ts:125`, pedindo duelo separado. Isso não representa a ação única de saque com defesa pessoal e resolução de prêmio descrita nas regras; o duelo separado já gasta a ação principal.
- O alerta compartilhado de saque descrito em `rules.md` não aparece como estado próprio no caminho de saque examinado. Sua restrição exata precisa ser explicitada antes de virar novo bloqueio de ação.
- A redução local por cidade completa está no contrato, mas não aparece nos cálculos de dano examinados de `resolveAttack`/`counterAttack` nem no motor nativo.
- A fonte de sucata solta local para E11 não está fechada: a referência inicializa `localScrap` em zero e tem comandos de recolha, mas não foi identificado abastecimento desse estoque nos caminhos examinados. Não criar renda automática para dar utilidade ao guincho.

Esses pontos são divergências de código/contrato ou definições incompletas, não reprovações dos 243 testes que passaram. Ao migrar, registrar a diferença e criar cenário baseado na regra aplicável. Custos de reparo territorial e composição de veículos devem ser conferidos no contrato específico antes da implementação.

## Plano de implementação

Ordem por dependência e risco, sem promessa de prazo. Esforço relativo: P = alteração localizada; M = módulo e alguns fluxos; G = várias janelas/estados e integrações. Cada etapa termina com motor, UI utilizável, persistência e evidência de teste daquilo que foi entregue.

| Etapa | Entrega | Prioridade/esforço | Depende de | Critério de saída |
| --- | --- | --- | --- | --- |
| 0 | Corrigir A01–A05 e registrar lacunas A06 | P0/P1 · M | Nenhuma | Reproduções passam como regressões e nenhuma recusa altera estado/RNG |
| 1 | Contratos de comandos, capacidades, instâncias e saves | P1 · G | 0 | Estado novo validado, migração nativa testada e efeitos preservados na retomada |
| 2 | Economia de sucata, reparos, upgrade e gerais de suporte | P1 · M/G | 1 | Hatch pode progredir legalmente e recursos têm escolhas rastreáveis |
| 3 | Melhorias, equipamentos e combate equipado | P1 · G | 1; integrar com 2 | Comprar, revelar, instalar, usar, remover e salvar equipamentos funciona |
| 4 | Controle de cidades, territoriais e vitória anunciada | P1 · G | 1 e 3 para infraestrutura de melhorias | Jornada conquista → anúncio → resposta → confirmação/cancelamento completa |
| 5 | Saque e bloqueios | P1 · G | 2–4 | Disputa de depósito e controle de estrada seguem contrato sem consumir duas ações |
| 6 | Eventos e veículos encontrados | P1 · G | 1–5; corrida depende de 7 | Viagem → evento → escolhas → turno preservado ou consumido corretamente |
| 7 | Corridas e surpresas | P1 · G | 1–3 e infraestrutura de 6 | Convite → prova → prêmio → retorno ao turno, com marcos e mortes corretos |
| 8 | Validação humana, balanceamento e estabilização | P1 · contínuo | Recortes jogáveis anteriores | Resultados medidos e pendências de regras documentadas |
| Android | Toolchain, APK e testes físicos | P1 · M + contínuo | Começar após 0; repetir por etapa | Execução física registrada, sem confundir Windows/PCK com Android |

### Etapa 0 — Continuidade e correção

- Resolver excesso de mão de qualquer destinatário com privacidade, mesmo antes de `start`; dar caminho de descarte ao excesso de depósito.
- Centralizar bloqueios por pendências e evitar que o encaminhamento para combate burle capacidade.
- Corrigir prioridade circular e tipo de combatente para G07.
- Converter as cinco reproduções em testes permanentes na suíte nativa; não manter testes que apenas afirmem o comportamento defeituoso.
- Ajustar documentação desatualizada: o README ainda contém afirmações amplas de que efeitos de cartas não executam e transferências estão pendentes, embora G01–G07 e transferências locais funcionem.

**Cenário de aceite principal:** atacar adversário com cinco cartas → fugir → ele recebe a sexta → fechar combate → entregar aparelho → revelar/descartar → iniciar turno normalmente. Recarregar em cada ponto de espera.

### Etapa 1 — Base dos sistemas restantes

- Manter `WastelandGame` como porta de comandos. Separar regras por responsabilidade conforme forem entrando: inventário, cartas/equipamentos, territórios, veículos, eventos/corridas e persistência.
- Introduzir consultas de carga, tanque, depósito, vida/defesa efetiva, excesso e elegibilidade. Motor e interface consultam o mesmo contrato.
- Representar cópias por `instance_id` e definição por `definition_id`; dois E05 não são a mesma instância. Relacionar revelações a instâncias, preservando compatibilidade com tickets/índices antigos.
- Preparar quatro baralhos e descartes: geral 48; melhorias E/T juntas 36; eventos 32; surpresas 32. Eventos/surpresas são revelados e resolvidos imediatamente; não viram mão de gerais.
- Preservar limites por tipo: cinco gerais, três equipamentos e três territoriais na reserva provisória. Instalados ficam fora da mão.
- Persistir fontes de efeitos, uso por turno/rodada/combate/corrida, escolhas obrigatórias, IDs e RNG. A UI apresenta o resultado decidido pelo motor.
- Validar candidatos de save antes de substituir a partida; preservar backups e migrar campos estruturais nativos sem comprar cartas, gerar recompensas ou consumir RNG. Mudança de edição/distribuição exige política explícita; não converter saves React silenciosamente.
- Criar runner de testes com perfil dedicado e fixtures legíveis. Para comparar TS/Godot, usar estados equivalentes e RNG conhecido; não exigir paridade de seed de inicialização que ainda não existe.

**Aceite:** roundtrip de estado com carta oculta, escolha pendente, modificador usado e combate; comando recusado preserva estado/RNG; falha de escrita não permite duplicar efeito ao repetir salvamento; IDs não se duplicam nem desaparecem entre zonas.

### Etapa 2 — Sucata, reparos e escolha de veículo

- Upgrade de Hatch operacional para sedã, SUV, caminhonete ou Moto: cinco sucatas da carga e depósitos próprios locais, consumindo primeiro a carga, mais uma ação.
- Preservar vida atual e vidas restantes, mão, carga e adicionais. Moto recebe tanque 10 na melhoria; demais modelos preservam combustível, sem kit. Resolver excedentes quando necessário.
- Implementar reparo complexo de carro e administração/reparo territorial conforme os contratos aplicáveis. Consultar vida máxima do modelo; não manter o teto fixo seis.
- Portar G08–G14, G23 e G24 com alvos, janelas, limites e proteção de jogadores em recuperação. Ganhos não são transferência de recursos entre jogadores.
- Exibir comparação de modelo, piso, consumo, carga, tanque e custo local antes de confirmar. Atualizar peça superior no mapa conforme modelo.
- Preservar primeira destruição/turno perdido e segunda eliminação após melhorar. Extrair resolução de vidas para ser usada também por dano de evento, corrida e saque.

**Aceite:** pagar cinco sucatas somando carga e dois depósitos locais sem acesso remoto; recusa sem saldo não gasta ação/RNG; upgrade não cura; Moto recebe somente a exceção autorizada; reparos em sedã/SUV não param em seis.

### Etapa 3 — Equipamentos e economia de melhorias

- Compra livre de melhoria por três sucatas, uma por turno próprio; E/T usam o mesmo baralho. G15 entrega melhoria sem consumir essa compra.
- Instalação/remoção fora de combate/corrida: dois espaços adicionais; únicos E04/E06/E07/E08/E09/E10; carga extra E02=2, E05=1. Recursos mais carga extra precisam caber; não descartar automaticamente para instalar.
- E07/E08 alteram capacidade, sem criar combustível/recursos. Remoção exige resolução de excedentes.
- E01–E03: escolha de arma/alvo, pagamento de munição antes do dado e um ataque adicional compartilhado por carro/rodada. Erro também gasta munição e cota. E03 só atinge carro; arma fixa permanece separada.
- E04 altera limiar de defesa, sem redução de dano. E05/E06 usam frequência por combate; E12 descarta antes do ataque e reduz dano mesmo quando poderia ter sido gasto em um erro.
- E09 modifica fuga sem retirar teste, combustível ou tributo. Preparar E10 para a etapa de corrida. E11 depende de fonte de sucata local aprovada e recolha funcional; não anunciá-lo pronto sem essa condição.
- UI de reserva/slots mostra custo, carga, ÚNICA, uso restante e motivo de indisponibilidade. Reações continuam antes do dado e privadas para o dono.

**Aceite:** duas armas não concedem dois extras; mudar alvo/atacante da mesma rodada não renova cota; duas instâncias de E05 têm uso independente; E06 não renova entre rodadas; retirar E07/E08 resolve excedente; retomar não renova ativação gasta.

### Etapa 4 — Expansão com objetivo e melhorias territoriais

- Calcular controle completo e pontos: cidades de quatro setores valem um; demais meio. Exibir placar, composição dos pontos e setores faltantes.
- Anunciar ao fim do próprio turno resolvido com pelo menos quatro pontos. Cancelar se cair abaixo de quatro em qualquer transação concluída ou ocorrer morte/eliminação.
- No próximo início próprio, expirar efeitos primeiro, recalcular e confirmar antes da compra. Recuperar pontos não restaura anúncio cancelado.
- Implementar bônus local de cidade completa: uma redução de um dano por turno do mapa dentro da cidade, sem renda passiva e sem renovar por rodada. Registrar o beneficiário/consumo e explicitar o tratamento de casos não definidos antes de codificá-los.
- T01–T06: dois espaços; instalação local livre e remota por Administrar; T01 preserva dano existente, T02 só dano da fortificação, T03 só defesa da fortificação, T04 capacidade, T05 limite de saque e T06 substituição/reparo.
- Conquista descarta melhorias antigas, transfere estoque e restaura defesa padrão; eliminação abandona setores preservando defesa, melhorias e depósito.

**Aceite:** perder um setor cancela pontos/anúncio imediatamente; recuperar depois exige novo anúncio ao fim do próprio turno; vitória por sobrevivência continua imediata; T01 transforma máxima/atual 4/1 em 6/3; T06 substitui com dois espaços ocupados e as demais não.

### Etapa 5 — Pressão territorial: saque e bloqueios

- Saque simples: uma ação e um combustível; atacante D6 versus defesa D6+1, empate da defesa, até dois recursos ou um com T05; falha causa dois danos e passa pelo sistema de vidas.
- Dono operacional local decide defesa pessoal na mesma ação. Só carros participam; vencer autoriza resolver o saque, sem ataque de fortificação e sem segunda ação.
- Preservar a regra de destruição sem roubo de cartas. Tributo por fuga permanece; esclarecer a elegibilidade do roubo citado no saque se a vitória ocorrer por destruição, pois as regras de vidas têm precedência explícita.
- Registrar tentativa/expiração do alerta; fechar sua semântica de restrição antes de criar uma proibição nova. Não dar imunidade a depósitos de jogador em recuperação.
- Portar G19/G20 só para o teste simples. Não aplicar esses bônus ao duelo.
- Portar G17/G18 com fonte e rota por ID; custo e alvo validados antes de consumo, máximo de um bloqueio próprio, estrada aberta, ambos os sentidos e expiração no início da vez da fonte.
- Proteger última saída compatível considerando piso e outros bloqueios, sem exigir combustível; rotas paralelas são independentes. Fonte eliminada não deixa bloqueio eterno.
- G17 consome ação, mas permite a viagem posterior prevista. `route_reason` precisa representar essa exceção sem liberar ações extras.

**Aceite:** nenhum custo/RNG gasto em bloqueio inválido; saque com defesa pessoal cabe em uma ação; T05 limita ambos os caminhos; alerta expira na janela definida; G18 remove uma fonte; save antigo com fontes múltiplas mantém tratamento explícito até expiração.

### Etapa 6 — Eventos e veículos encontrados

- Conectar viagem legal → pagar consumo → chegar → revelar um evento → resolver → liberar ação se ainda disponível. Viagem inválida não compra evento.
- Primeiro entregar V01–V11 e escolhas de recurso; G16 só fica funcional junto da inspeção e ordem do baralho de eventos.
- V15 usa hostil temporário, consome a ação uma vez, não conquista setor e é descartado ao fim mesmo com fuga; não reaproveitar a conquista territorial como efeito de vitória.
- V16 depende de composição/disponibilidade do baralho de veículos aprovada. Veículo encontrado tem tanque vazio e vida máxima, não duplica modelo ativo indisponível e fica público na cidade.
- Assumir encontrado cobra cinco sucatas locais e uma ação; reparo necessário ocorre em turno anterior, adicionais do carro anterior são descartados e excedentes resolvidos. Conferir o contrato de combustível na troca antes de copiar o código React.
- V12–V14 dependem da corrida. Não removê-los silenciosamente do baralho para anunciar eventos completos; uma entrega parcial deve identificar sua limitação e preservar a convocação pendente até existir resolução correta.

**Aceite:** retomar após a revelação não compra outro evento; V11 elimina apenas a ação principal; morte por V06/V15 consome vida uma vez; V16 não gera kit; um evento nunca dispara uma segunda viagem/evento implícita.

### Etapa 7 — Corridas

- Pistas P01/P02/P03 com distância, marcos, inscrição de um combustível e prêmios contratados. Preservar cidade de retorno e turno do mapa.
- Revelador apto deve entrar; demais podem entrar de qualquer cidade. Menos de dois aptos cancela/devolve inscrição, sem prêmio nem rival neutro.
- Rodadas de D6, ordem circular, escolha de alvos e fila de marcos por participante. Avanço por carta cruza marcos em ordem; recuo não os renova.
- Implementar R01–R16, G21/G22 e E10; modificadores na janela anterior ao dado e uso persistido. A cota de geral não reinicia na prova.
- Zero de vida retira participante da corrida e resolve primeira/segunda destruição; renascer não o devolve à prova.
- Completar a rodada da chegada, decidir maior progresso e desempatar por D6 sem cartas. Prêmio somente ao primeiro, com depósito próprio da cidade de retorno acessível antes do descarte.

**Aceite:** cruzar dois marcos via carta resolve ambos uma vez; escolha pendente bloqueia próxima rolagem; E10 não renova ao retomar; todos retirados termina sem prêmio; retorno preserva ação quando permitido pelo evento/estado do carro.

### Android e experiência — trilha contínua

- Configurar templates correspondentes ao editor, JDK/SDK e gerar APK de debug cedo, usando o recorte atual corrigido. Registrar versão, dispositivo e build.
- Validar em telefone de entrada e aparelho de referência: paisagem, recorte, barras, alvos de toque, pinça versus clique, Voltar, teclado, cartas e texto ampliado.
- Testar privacidade na entrega, compra fora do turno, interrupção por outro app, pausa, retomada e encerramento do processo em escolhas/combate. O código de retomada quente hoje reajusta layout; confirmar se também deve exigir nova identificação privada.
- Medir carregamento, tempo de quadro, RAM/VRAM quando disponível e sessão prolongada. Otimizar texturas/cache somente onde houver medição; o PCK de aproximadamente 114 MiB relatado não demonstra consumo de memória em aparelho.
- Manter tema/cenas, atualização da mão/inventário por mudança e movimento reduzido. Revisar cada painel novo renderizado, sem exigir nova reformulação visual completa.
- Explicar no Como jogar o objetivo vigente, duas vidas e opções disponíveis; ao entrar vitória territorial, mostrar anúncio e prazo de resposta. Botão indisponível precisa ter motivo legível por toque.

## Ferramentas de desenvolvimento a acrescentar

| Ferramenta | Resultado esperado | Momento |
| --- | --- | --- |
| Matriz de suporte por carta/efeito | ID, comando, janela, consumidor de efeito, teste e estado Android; detectar carta “só no catálogo” | Etapas 0–1 |
| Validador de dados/assets | Contagens 74/148 e 48/36/32/32, IDs, cópias, caminhos, tipos de efeito e divergências entre JSON | Etapa 1 |
| Runner de verificação nativa | Perfis isolados por suíte, falha pelo exit code, logs e separação entre headless/renderizado | Etapa 1 |
| Fixtures e cenários de regras | Preparar mãos, cidade, vida, depósito e RNG sem editar save real; repetir casos de borda | Etapas 0–1 |
| Invariantes e diagnóstico de estado | Cartas em uma única zona, recursos inteiros não negativos, excesso resolvível, IDs válidos e fases consistentes | Etapa 1 |
| Registro reproduzível de comandos | Seed inicial quando conhecida, RNG corrente, versão e sequência de intenções; ausência de cartas privadas em telas públicas | Etapa 1 em diante |
| Comparador de cenários TS/Godot | Comparar contrato em estados normalizados; divergência justificada quando TS não segue regra | A cada migração |
| Checklist de APK e planilha de playtest | Evidência por aparelho, falhas de entrada, duração, decisões e recuperação após morte | Começar após etapa 0 |

Usar a estrutura atual de scripts de teste e ferramentas nativas como ponto de partida. Esta auditoria não identificou necessidade de instalar addons de inventário, diálogo, IA, rede ou física para resolver as lacunas encontradas.

## Validação humana e decisões ainda abertas

Depois de cada recorte jogável, registrar: tempo até primeira melhoria; ações gastas em exploração/reparo/combate; compras sem opção legal de uso; consumo de combustível/munição; duração e número de rodadas dos combates; tempo de espera entre decisões; momento e duração do anúncio territorial; mortes e possibilidade de reconstrução após o turno perdido.

Primeiro comparar partidas de duas pessoas; depois verificar pressão e espera com três/quatro. Perguntar se os jogadores conseguem explicar seu objetivo e custo da próxima ação e se identificam uma decisão útil sem ajuda. Metas numéricas de duração/equilíbrio precisam ser estabelecidas a partir da intenção do produto e dos dados, não inventadas nesta auditoria.

Permanecem como decisões, sem bloquear as correções e a maior parte das etapas iniciais:

- Duração desejada da sessão e tolerância à espera com quatro pessoas.
- Uso futuro de pneus, bateria e água; condições mecânicas ainda sem regra permanecem desativadas.
- Quantidade/disponibilidade de veículos encontrados, origem de sucata solta para E11 e perfis regionais/dificuldade dos hostis.
- Semântica detalhada do alerta de saque, casos de acionamento do bônus de cidade e conflitos de roubo após destruição.
- Impasse de combate sem dano e reconquista de território de jogador com nova ameaça: não criar saída ou hostil extra sem regra aprovada.

## Evidências desta auditoria

| Verificação executada | Resultado | Limite |
| --- | --- | --- |
| `tests/smoke.gd` | Zero falhas | Regras do recorte atual, Windows headless |
| `tests/combat_smoke.gd` | Zero falhas | Não cobre equipamentos ausentes nem os novos cenários auditados |
| `tests/transfers_smoke.gd` com renderer real | Zero falhas | Windows; avisos repetidos de teclado durante setup |
| `tests/combat_ui_smoke.gd` com renderer real | Zero falhas | Windows; captura de confirmação de carta inspecionada |
| Vitest da referência | 8 arquivos / 243 testes aprovados | Não executados os testes Playwright nem validação Android |
| Diagnóstico A01–A05 | Cinco comportamentos incorretos reproduzidos | Cenários direcionados, sem estimativa de frequência em partidas reais |
| Comparação de JSON | 11 pares equivalentes | Igualdade de dados não garante efeito funcional |

Todos os testes nativos usaram APPDATA/LOCALAPPDATA isolados em `.tools/audit-2026-10-30/`. As capturas de transferência e confirmação de carta foram inspecionadas; não houve alteração visual do jogo. O aviso de leitura do repositório de certificados do Windows apareceu, sem impedir conclusão das suítes.

O comando padrão do Vitest encontrou restrição de leitura do bundler no sandbox. A mesma suíte passou usando o carregador nativo, sem mudar a configuração do projeto:

```powershell
npm.cmd test -- --configLoader native --reporter=dot
```

Diagnóstico local: `.tools/audit-2026-10-30/probe.gd` e `probe-results.txt` são auxiliares ignorados pelo Git. As reproduções e os critérios de correção estão descritos acima para continuarem disponíveis sem esses arquivos.

**Primeiro pacote recomendado para executar:** etapa 0 completa e infraestrutura mínima de capacidades/validação da etapa 1. Depois, progressão de sucata/veículos e cadeia de equipamentos; ambos devem alimentar o recorte de vitória territorial antes de avaliar equilíbrio do jogo completo.
