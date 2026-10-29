# Terras Devastadas — Catálogo completo de cartas v0.2

Edição de teste revisada em 29/10/2026, com seleção de alterações autorizada por Bruno. Compatível com rules.md v0.5 deste pacote. Mantém 74 modelos e 148 instâncias nos quatro grupos, com melhorias territoriais no baralho de equipamentos. Doze frentes foram atualizadas; as demais permanecem válidas. Hostis estão em dados/hostis.json. Nenhuma partida real foi medida nesta revisão.

Precedência: rules.md + este catálogo + rule-config.json + patches tipados; imagens antigas e contextos v0.1 não prevalecem sobre os textos desta edição.

### Regras transversais novas
- Todos os equipamentos de arma compartilham 1 ataque adicional por carro e rodada. A arma fixa não entra nesse limite. Erro também gasta o limite e a munição.
- E04, E06 e E09 agora são ÚNICOS. E06 pode ativar uma vez por combate, não por rodada.
- G17 exige turno próprio, 1 sucata e ação principal disponível; não acumula bloqueios em rota fechada. G18 permanece a resposta por carta.
- G09/G11/G12 entregam somente 1 unidade. G21/G22 alteram avanço em 1.
- Tags tática, sobrevivência, pressão, mobilidade e território organizam a UI; não são novos baralhos ou cotas.

## 1 Composição

| Baralho | Modelos diferentes | Cópias por modelo | Total |
|---|---:|---:|---:|
| Geral | 24 | 2 | 48 |
| Melhorias — equipamentos | 12 | 2 | 24 |
| Melhorias — territoriais | 6 | 2 | 12 |
| Surpresas de corrida | 16 | 2 | 32 |
| Eventos de deslocamento | 16 | Conforme tabela | 32 |
| **Total** | **74** | — | **148** |

Equipamentos e territoriais compartilham o mesmo baralho de melhorias, com 36 cartas. Não criar compra separada por tipo. Pistas são fichas de prova, não cartas de surpresa. Há 48 gerais para sustentar compras iniciais e por turno; reciclar descarte quando necessário.

## 2 Convenções universais

- Geral vai à mão. Limite de uso: 1 por jogador em cada turno do mapa, inclusive adversário. Combate e corrida não renovam esse limite.
- Cartas que modificam dados entram antes da rolagem. Ordem de oportunidade: jogador da vez, depois ordem dos turnos. Não existe reação retroativa ao resultado.
- Melhoria vai à reserva correspondente; instalada permanece no espaço ativo. Cada equipamento ocupa 1 dos 2 espaços adicionais; cada territorial ocupa 1 dos 2 espaços do território. Nenhuma carta ocupa carga na mão.
- Todo equipamento abaixo é compatível com os quatro veículos. Carga extra aparece explicitamente. Se exceder a capacidade, escolher descartar recursos ou cancelar instalação; não permitir carga ilegal.
- Duplicatas somam, exceto carta marcada ÚNICA: uma por carro ou território. Benefícios idênticos com frequência própria são controlados por instância, salvo o limite compartilhado de arma adicional por carro e rodada.
- Surpresa de corrida e evento são revelados e resolvidos imediatamente, depois descartados. Não contam como geral jogada. Efeitos pendentes são registrados separadamente do descarte.
- Toda quantidade de combustível é inteira. Consumo normal continua hatch 1, sedã 2, SUV 2, caminhonete 3; nenhuma carta abaixo aplica adicional passivo por carga ou terreno.
- Cura respeita Integridade máxima; ganho respeita tanque/carga/depósito. Excedente é escolhido e descartado. Recurso ganho de carta surge no destino descrito, não é doação entre jogadores.
- Dano pode inutilizar carro. Corrida: Integridade zero causada por carta retira participante para recuperação, sem eliminação automática, conforme rules.md desta edição.
- Efeito sem alvo legal não pode ser jogado voluntariamente. Evento/surpresa obrigatória sem alvo é descartado sem efeito. Se uma condição de texto não se cumprir, usar sua alternativa expressa.
- Modificador de acerto não afeta regra provisória de 1 natural falhar e 6 natural acertar. Modificadores opostos somam; dano mínimo zero e avanço mínimo zero. Nenhuma carta altera o sorteio de desempate da corrida.
- Cartas gerais que curam são usadas antes de uma ação, fora de combate/corrida. Podem escolher jogador em qualquer cidade quando indicado. Isso não concede movimento ou ação principal extras.
- Só veículos operacionais viajam/correm. Fuga PvP continua exigindo rota, combustível e 1 carta entregue às cegas; nenhuma carta abaixo remove esse pagamento.

## 3 Baralho geral — 24 modelos, 48 cartas

Todos têm 2 cópias. Não há custo adicional além de gastar a carta e a cota geral, salvo texto.

| ID | Nome | Momento e alvo | Texto da carta |
|---|---|---|---|
| G01 | Mira de ferro | Antes de um ataque, qualquer atacante | Some +1 à rolagem deste ataque. |
| G02 | Nuvem de poeira | Antes de um ataque, qualquer atacante | Aplique −1 à rolagem deste ataque. |
| G03 | Impacto brutal | Antes de um ataque, qualquer atacante | Se este ataque acertar, cause +1 dano. |
| G04 | Chapa improvisada | Antes de um ataque, qualquer alvo | Reduza em 1 o dano deste ataque se acertar. |
| G05 | Cortina de fumaça | Antes de uma tentativa de fuga | Some +1 ao teste de fuga. Os custos normais permanecem. |
| G06 | Cerco fechado | Antes de uma tentativa de fuga | Aplique −1 ao teste de fuga. |
| G07 | Reforço hostil | Antes do ataque de uma ameaça | Some +1 à rolagem desse ataque da ameaça. |
| G08 | Socorro aos hostis | Antes de uma ação fora de combate/corrida, ameaça revelada | Recupere 2 de Integridade dessa ameaça. |
| G09 | Combustível de emergência | Antes de uma ação, qualquer jogador | Antes de uma ação, qualquer jogador. Adicione 1 combustível ao tanque escolhido. Respeite a capacidade. Pode ajudar um carro em emergência. |
| G10 | Remendo de campo | Antes de uma ação, qualquer carro | Recupere 2 de Integridade se o carro já tiver pelo menos 1. Não reativa carro inutilizado. |
| G11 | Suprimento de sucata | Antes de sua ação | Antes de sua ação, receba 1 sucata na carga. Pode armazená-la em depósito próprio da cidade antes de descartar excedente. |
| G12 | Caixa de munição | Antes de sua ação | Antes de sua ação, receba 1 munição na carga, respeitando a capacidade. |
| G13 | Pneu de reserva | Antes de sua ação | Receba 1 pneu na carga. |
| G14 | Bateria recuperada | Antes de sua ação | Receba 1 bateria na carga. |
| G15 | Contato do ferro velho | Antes de sua ação | Compre 1 carta do baralho de melhorias. Não consome a compra com sucata do turno. |
| G16 | Desvio sinalizado | Antes de viajar, qualquer viajante | Olhe a próxima carta de deslocamento. Devolva ao topo ou coloque no fundo. A viagem ainda resolve um evento normalmente. |
| G17 | Barricada na estrada | Turno próprio, antes de viajar ou agir; fora de combate/corrida | No seu turno, antes de viajar ou agir: gaste 1 sucata e sua ação principal. Bloqueie 1 estrada aberta até seu próximo turno. Não pode retirar a última saída compatível de nenhum carro presente. |
| G18 | Equipe de desobstrução | Antes de uma viagem ou ação | Remova 1 efeito de bloqueio de uma estrada. Se houver outros bloqueios ativos, ela continua fechada. |
| G19 | Golpe de oportunidade | Antes da disputa simples de saque | Atacante soma +1 ao seu dado. Não altera combate com defesa pessoal. |
| G20 | Vigias atentos | Antes da disputa simples de saque | Defesa soma +1 adicional ao seu dado. |
| G21 | Pé embaixo | Antes do avanço de um participante na corrida | Antes do avanço de um participante na corrida, some +1 ao avanço desta rolagem. Não altera o dado natural. |
| G22 | Pressão no rival | Antes do avanço de um participante na corrida | Antes do avanço de um participante na corrida, subtraia 1 do avanço desta rolagem, mínimo zero. |
| G23 | Reforço da muralha | Antes de ação fora de combate/corrida, defesa territorial própria | Recupere 2 de Integridade dessa defesa, mesmo se estiver a zero e a casa ainda for sua. |
| G24 | Água para o radiador | Antes de sua ação | Receba 1 água na carga. Não remove condição ainda sem regra definida. |

G09 é ajuda por efeito, não transferência de inventário. Não consumir combustível de outro jogador. G17 não pode ser aplicada depois que a viagem já começou.

## 4 Equipamentos — 12 modelos, 24 cartas

Dois exemplares por modelo. Instalar é livre no próprio turno fora de combate/corrida. Retirar descarta. Ataques são opcionais e pagam munição antes da rolagem. Estes equipamentos não substituem a arma fixa do modelo.

| ID | Nome | Carga extra | Efeito instalado |
|---|---|---:|---|
| E01 | Metralhadora lateral | 0 | 1 espaço. Concede 1 ataque adicional por rodada: dano 1, custo 1 munição. Use no máximo 1 arma adicional por rodada, somando todos os equipamentos. |
| E02 | Canhão de sucata | 2 | 1 espaço e 2 cargas. Ataque adicional por rodada: dano 3, custo 1 munição, acerto −1. Use no máximo 1 arma adicional por rodada entre todos os equipamentos. |
| E03 | Espingarda de bordo | 0 | 1 espaço. Ataque adicional por rodada: dano 2, custo 1 munição. Só atinge carros. Use no máximo 1 arma adicional por rodada entre todos os equipamentos. |
| E04 | Blindagem rebitada | 0 | ÚNICA. 1 espaço. Enquanto instalada, sua Defesa aumenta em 1, até 6+. Não reduz dano recebido. |
| E05 | Placa de absorção | 1 | Uma vez por combate, reduza em 1 o dano de um ataque recebido. Declare antes da rolagem. |
| E06 | Mira estabilizada | 0 | ÚNICA. 1 espaço. Uma vez por combate, some +1 ao acerto de um ataque seu. Declare antes do dado. |
| E07 | Tanque suplementar | 0 | ÚNICA. Capacidade do tanque +3. Instalar não gera combustível; remover exige descartar combustível acima da nova capacidade. |
| E08 | Bagageiro reforçado | 0 | ÚNICA. Capacidade de carga +2. Remover exige ajustar excedente imediatamente. |
| E09 | Kit de extração | 0 | ÚNICA. 1 espaço. +1 ao teste de fuga. Não remove o custo de combustível nem o pagamento de carta na fuga entre jogadores. |
| E10 | Suspensão de corrida | 0 | ÚNICA. Uma vez por corrida, some +2 ao seu avanço. Declare antes de sua rolagem. Não concede acesso à terra. |
| E11 | Guincho manual | 0 | Uma vez por turno próprio, ao recolher sucata local, transfira até 1 dela diretamente para depósito próprio da cidade. Restante segue regra de carga. |
| E12 | Escudo descartável | 0 | Antes de um ataque contra seu carro, pode descartar este equipamento para reduzir em 2 o dano desse ataque. Decisão antes do dado. |

Toda redução indicada antes do dado pode resultar em benefício gasto mesmo se o ataque falhar. Frequência por combate não renova entre rodadas; não renova por simples mudança de alvo. Munição exige carga: o hatch precisa abrir espaço para carregá-la. Não criar munição infinita por instalação.

## 5 Melhorias territoriais — 6 modelos, 12 cartas

Dois exemplares por modelo; mesmo baralho dos equipamentos. Usam os dois espaços territoriais. Presencialmente instalar é livre; remotamente consome a ação Administrar. A reserva de três territoriais continua proposta do GDD.

| ID | Nome | Efeito instalado |
|---|---|---|
| T01 | Muralha de sucata | Integridade máxima da defesa +2. A instalação também aumenta sua Integridade atual em 2, preservando o dano já sofrido. |
| T02 | Torre de tiro | O ataque da defesa territorial recebe +1 de dano. Não concede segundo ataque. |
| T03 | Posição elevada | Defesa da fortificação +1, até 6+. Não altera Defesa do carro do dono. |
| T04 | Depósito ampliado | Capacidade do depósito +5. Ao remover, ajuste o excedente. |
| T05 | Cofre enterrado | ÚNICA. Em saque bem-sucedido, o invasor leva no máximo 1 recurso deste depósito, inclusive após defesa pessoal. |
| T06 | Reforma planejada | Ao instalar, pode descartar uma melhoria deste território para liberar espaço, mesmo se já houver duas. Depois, reparos Administrar nesta defesa recuperam +1 Integridade por ação, sem material extra. |

Somente T06 permite substituir uma melhoria já instalada quando os espaços estão ocupados. T01 não repara dano antigo: se máxima/atual eram 4/1, passam a 6/3. T02/T03 não participam da defesa pessoal de saque, que envolve apenas carros. T05 continua protegendo o depósito. Melhorias são descartadas na conquista por outro dono.

## 6 Surpresas de corrida — 16 modelos, 32 cartas

Duas cópias por modelo. Compradas nos marcos da pista, resolvidas imediatamente. Não vão à mão. “Você” = participante que cruzou o marco. Sem custo adicional de combustível. Todas as perdas de avanço têm mínimo zero.

| ID | Nome | Efeito |
|---|---|---|
| R01 | Reta livre | Avance 2 posições. |
| R02 | Atalho da pista | Avance 3 posições. Trecho temporário da prova, não concede rota rural no mapa. |
| R03 | Vácuo perfeito | Se alguém estiver à sua frente, avance 2. Caso contrário, avance 1. |
| R04 | Motor afinado | Na sua próxima rolagem de avanço, receba +2. Expira ao fim da corrida se não usado. |
| R05 | Curva aberta | Escolha você ou outro participante ativo: ele avança 2. |
| R06 | Bandeira amarela | Você recua 2 posições. |
| R07 | Areia solta | Sua próxima rolagem de avanço tem −2, mínimo zero. |
| R08 | Barreira improvisada | Escolha outro participante ativo: ele recua 2. Se não houver outro, você recua 1. |
| R09 | Toque lateral | Escolha outro participante ativo: você e ele sofrem 1 dano. Sem outro alvo, você sofre 1. |
| R10 | Detritos no asfalto | Sofra 1 dano e recue 1 posição. |
| R11 | Colisão no guard rail | Sofra 2 danos. Se ainda operacional, permaneça na posição atual. |
| R12 | Rota segura | Nada acontece. A passagem foi limpa. |
| R13 | Ajuste rápido | Recupere 1 Integridade do seu carro. Não reativa participante já retirado. |
| R14 | Embalo | Avance 1 e escolha outro participante ativo para avançar 1. Sem outro alvo, só você avança 1. |
| R15 | Poeira na frente | O participante ativo mais à frente, exceto você, recua 1. Em empate, você escolhe entre empatados. Sem outro alvo, nada acontece. |
| R16 | Passagem estreita | Se houver outro participante na mesma posição que você, escolha um: ele recua 1. Caso contrário, avance 1. |

Nunca pular rolagens inteiras: evita deixar alguém esperando sem jogar. Marcos acionam no máximo uma vez por participante. Avanço por carta cruza novos marcos e resolve em ordem. Recuar não reativa marcos. Bônus de próxima rolagem são consumidos juntos nessa rolagem; não migram para outra corrida.

Uma carta geral pode afetar uma próxima rolagem antes dela, mas não cancelar retroativamente estas surpresas. R09/R11 podem inutilizar um carro já danificado; nenhuma carta destrói automaticamente um carro íntegro. Se ninguém permanecer apto a terminar, encerrar sem prêmio.

## 7 Eventos de deslocamento — 16 modelos, 32 cartas

Revelar após pagar uma viagem legal e antes da ação na chegada. Para este catálogo, o carro chega ao destino antes de resolver o evento, salvo texto expresso. Evento não cobra outra viagem. Não transformar todo evento em combate obrigatório.

| ID | Nome | Cópias | Efeito |
|---|---|---:|---|
| V01 | Estrada vazia | 6 | Chegue sem incidentes. Pode agir normalmente. |
| V02 | Trecho sinalizado | 4 | Chegue sem incidentes. Pode agir normalmente. |
| V03 | Pequeno achado | 2 | Receba 1 sucata na carga; pode usar depósito próprio do destino antes de descartar excedente. |
| V04 | Posto abandonado | 2 | Adicione 2 combustíveis ao tanque. |
| V05 | Vazamento na chegada | 2 | Perca até 1 combustível do tanque, sem saldo negativo. Se ficar imobilizado, aplique emergência normalmente. |
| V06 | Choque nos destroços | 2 | Sofra 1 dano de Integridade. Se continuar operacional, pode agir. |
| V07 | Carga mal presa | 2 | Descarte 1 recurso da carga, à sua escolha. Se não carregar recursos, nada acontece. Não afeta tanque nem equipamento. |
| V08 | Bateria esquecida | 1 | Receba 1 bateria na carga. |
| V09 | Pneu aproveitável | 1 | Receba 1 pneu na carga. |
| V10 | Caixa de suprimentos | 2 | Escolha e receba 1 sucata ou 1 munição na carga. |
| V11 | Caminho obstruído | 1 | Você chega, mas perde a ação principal deste turno. Ações livres legais continuam disponíveis. Não cria bloqueio de estrada. |
| V12 | Corrida Araras–Limeira | 1 | Convoque a pista P01. Após a corrida, retome este turno, preservando a ação principal se operacional. |
| V13 | Corrida Araras–Piracicaba | 1 | Convoque a pista P02 e proceda como V12. |
| V14 | Corrida Rio Claro–Americana | 1 | Convoque a pista P03 e proceda como V12. |
| V15 | Emboscada de saqueadores | 2 | Enfrente uma ameaça leve de evento. Esta batalha substitui sua ação principal. Não concede território; descarte a ameaça ao encerrar, mesmo se fugiu. |
| V16 | Veículo abandonado | 2 | Revele 1 veículo disponível e deixe-o na cidade de destino, com tanque vazio e Integridade máxima, sem adicionais. Pode assumir usando sua ação Administrar na chegada. |

V15: a regra de dano persistente vale para ameaças territoriais; inimigo de evento é encontro temporário sem casa, descartado no encerramento. Se houver fuga, sair da cidade e pagar custo normal, sem carta de tributo porque é ameaça. Se faltar saída, continuar combate; impasse sem dano segue pendência do GDD.

V16: veículo revelado não recebe kit inicial. Não devolver cartas de veículos ativos ao sorteio. Se não houver modelo disponível, descartar evento sem efeito. Definição de quantas cópias de veículos existem pertence ao baralho de veículos, não a este catálogo. A oferta fica pública e pode ser assumida por outro jogador primeiro.

Distribuição: 10 passagens tranquilas; 10 achados (V03/V04/V08/V09/V10/V16); 9 riscos/atrasos (V05/V06/V07/V11/V15); 3 corridas. Assim, 3 de 32 eventos convocam corrida antes de reciclar. A probabilidade efetiva muda conforme cartas saem do baralho.

## 8 Fichas de pista propostas

| ID | Pista | Distância | Marcos | Inscrição | Prêmio do vencedor |
|---|---|---:|---|---:|---|
| P01 | Araras–Limeira | 15 | 6 e 12 | 3 | 3 sucatas + 1 melhoria |
| P02 | Araras–Piracicaba | 21 | 7 e 14 | 5 | 4 sucatas + 2 melhorias |
| P03 | Rio Claro–Americana | 18 | 6 e 12 | 4 | 3 sucatas + 2 melhorias |

Custos respeitam teto confirmado 5; os valores individuais e recompensas são novos. Prêmio entra na carga/mão. Na cidade de retorno, pode usar depósitos próprios antes do descarte. Sem depósito e com hatch, parte da sucata pode ser perdida; melhorias continuam valiosas e não ocupam carga na mão.

Sem desistência voluntária. Completar a rodada de chegada; maior progresso vence, empate por D6 sem cartas. Com um único inscrito apto, cancelar a convocação, devolver inscrição e seguir o turno sem prêmio. Rival neutro desativado nesta edição.


## 9 Guardas de balanceamento e implementação

- Não há roubo de turno completo por carta geral, eliminação instantânea, roubo de equipamentos instalados ou bloqueio permanente neste conjunto.
- Não há carta que torne hatch/sedã aptos à terra. Capacidade de carga pode aumentar; consumo base continua fixo.
- A mão geral tem formas de ajudar terceiros sem doação direta. Ameaças só curam por G08; não restaurar vida por fuga ou novo turno.
- G17/G18 são as únicas cartas deste conjunto que criam/removem bloqueio de estrada; V11 é atraso individual.
- Saque continua 2 recursos no máximo; T05 reduz esse limite. G19/G20 não alteram duelo de carros.
- E02 ocupa duas cargas; o hatch pode usá-lo somente se tiver capacidade adicional suficiente e liberar espaço. Equipamento não se instala violando capacidade.
- Mão geral limite 5; equipamento 3; reserva territorial provisória 3. Compras podem exigir descarte imediatamente. Compra G15 não aumenta cota de gerais.
- Nenhuma carta muda regra de vitória, concessão de defesa padrão na conquista ou descarte na eliminação.

### Estrutura de dados recomendada

Cada definição precisa de `id`, `name`, `deck`, `type`, `copies`, `timing`, `targetSelector`, `cost`, `effects`, `duration`, `restrictions`, `rulesText` e `status: proposed`. Equipamento inclui `slots`, `extraCargo`, `unique` e efeitos acionáveis/passivos. Não interpretar texto natural com LLM durante a partida.

Efeitos tipados mínimos: modifyRoll, modifyDamage, restoreIntegrity, gainResource, loseResource, drawCard, inspectDeckTop, blockRoad, removeBlock, modifyStat, grantAttack, moveRaceProgress, queueRaceModifier, startRace, spawnVehicle, startEventCombat e consumeMainAction.

Registrar triggers e fontes por instância. Definição contém duas cópias, mas cada cópia precisa de instanceId distinto. Validar alvo/custo antes de gastar geral; efeitos obrigatórios sem alvo seguem alternativas do texto.

### Testes de aceitação

1. Contagem 74 definições e 148 instâncias; geral 48, melhorias 36, corrida 32, eventos 32.
2. Nenhuma geral altera dado depois da rolagem; limite não renova no combate/corrida.
3. Cura não supera máximo; ganho não supera tanque/carga sem escolha de descarte.
4. E02 não cabe em hatch básico; E08 altera capacidade antes da validação de carga extra.
5. Duplicatas de não únicas somam; únicas impedem segunda instalação.
6. T06 permite substituição e descarta antiga; outras cartas não substituem espaços ocupados.
7. T01 preserva dano existente; conquest descarta todas melhorias antigas.
8. R01/R02/R14 cruzam marcos em ordem sem repeti-los; efeito não gera novo turno.
9. Carro inutilizado por surpresa sai da prova e retorna para recuperação.
10. G17 respeita última saída por classe; G18 remove uma fonte de bloqueio.
11. V16 não entrega kit ou combustível nem duplica veículo ativo.
12. V15 consome ação principal uma única vez; V12–V14 não a consomem por padrão.

## 10 Pendências para a próxima edição

Validar números em sessões reais; rival neutro permanece desativado e corrida com um participante não inicia. Zero de Integridade retira da corrida sem eliminar jogador. Fechar composição de veículos e exploração regional; hostis H01–H12 já estão definidos em hostis.json. Testar frequência de munição/combustível e impacto da carga 1 do hatch. Aumento de carga E08 pode ser especialmente forte para hatch: medir antes de aumentar suas cópias.

Este catálogo cobre integralmente os quatro grupos pedidos, incluindo territoriais porque compartilham o baralho de equipamento. Não afirma conter todas as ameaças, explorações ou veículos da edição final.
