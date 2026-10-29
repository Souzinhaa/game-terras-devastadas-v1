# Terras Devastadas
## Game Design Document para desenvolvimento local

Versão 0.4 • Consolidação em 28/10/2026 • Responsável pelo conceito: Bruno Souza

Este documento orienta o primeiro protótipo digital local. Consolida o manual inicial e as decisões posteriores da conversa. As decisões mais recentes prevalecem sobre o manual e as imagens. O documento descreve o jogo pretendido, não afirma que o código, o mapa definitivo ou todos os baralhos já existam.

**Status:** CONFIRMADO = decidido pelo idealizador; PROVISÓRIO = solução ou número sugerido, substituível em configuração; ABERTO = sem decisão operacional suficiente. Arte não define regras ou conexões. Implementar as opções provisórias com indicação no modo de desenvolvimento.

## 1 Visão e escopo

Jogo competitivo de tabuleiro digital de estratégia territorial e sobrevivência, ambientado em uma versão pós-apocalíptica do interior paulista. Cada jogador controla um carro, administra recursos, explora, conquista e saqueia territórios. Corridas interrompem a disputa territorial com uma prova compartilhada.

Pilares: escolhas estratégicas antes da sorte; diferenças entre veículos; interação frequente; recursos localizados; combate arriscado e recuperável; identidade regional.

PROVISÓRIO: 2–4 jogadores, primeira versão em hot-seat local. Duração-alvo de 90–150 minutos, ainda não medida. Sem login, servidor remoto, bots, campanha, crafting ou consumo passivo de alimento no MVP.

## 2 Vitória

CONFIRMADO: vitória imediata por controlar cidades completas que somem 4 pontos, ou ser o último sobrevivente. Uma cidade pertence integralmente a quem controla todas suas sub-regiões simultaneamente. Menos de 4 sub-regiões vale 0,5; 4 ou mais vale 1. Perder uma sub-região remove o ponto e o bônus correspondente. Retomar domínio completo os restaura. Corridas e exploração não geram pontos por padrão.

Verificar vitória após resolução integral de efeitos, mudança de controle e eliminação. PROVISÓRIO: eliminação simultânea de todos termina sem vencedor.

## 3 Mapa atualizado

CONFIRMADO: carros ocupam uma posição compartilhada da cidade, e não uma posição por sub-região. Cada cidade deve admitir todos os carros presentes. As sub-regiões são alvos locais de exploração, conquista, saque e administração. Estar na mesma cidade permite combate entre carros, sem obrigá-lo. Entrar em cidade alheia não inicia combate automaticamente.

Agir em qualquer sub-região da cidade atual não custa combustível. Todos os próprios territórios naquela cidade contam como presença local: acesso a depósitos e instalação local são livres. O mapa inteiro deve permanecer conectado por vias compatíveis com carros comuns.

| Cidade | Sub-regiões | Pontos |
|---|---:|---:|
| Piracicaba | 4 | 1 |
| Americana | 4 | 1 |
| Limeira | 4 | 1 |
| Rio Claro | 4 | 1 |
| Araras | 3 | 0,5 |
| Leme | 3 | 0,5 |
| Pirassununga | 3 | 0,5 |
| Conchal | 2 | 0,5 |
| Artur Nogueira | 2 | 0,5 |
| Cordeirópolis | 2 | 0,5 |
| Santa Gertrudes | 2 | 0,5 |
| Santa Cruz da Conceição | 2 | 0,5 |

Total confirmado após redução: **35 sub-regiões, 12 cidades, 8 pontos possíveis**. Nomes finais das sub-regiões estão ABERTOS; usar IDs estáveis e rótulos provisórios, sem inventar bairros reais.

### 3.1 Conexões de jogo

Corredores rodoviários conferidos na conversa anterior. Estas ligações simplificam os acessos urbanos e percursos; não equivalem a um levantamento cartográfico de cada entroncamento.

| Pares ligados, sem direção | Rótulo |
|---|---|
| Americana–Limeira; Limeira–Cordeirópolis; Cordeirópolis–Araras; Araras–Leme; Leme–Pirassununga | Anhanguera — SP-330 |
| Cordeirópolis–Santa Gertrudes; Santa Gertrudes–Rio Claro | Washington Luís — SP-310 |
| Conchal–Araras; Araras–Rio Claro | Wilson Finardi — SP-191 |
| Limeira–Piracicaba | Deputado Laércio Corte — SP-147 |
| Rio Claro–Piracicaba | Fausto Santomauro — SP-127 |
| Americana–Piracicaba | Luiz de Queiroz — SP-304, via região de Santa Bárbara d’Oeste |
| Conchal–Artur Nogueira | Professor Zeferino Vaz — SP-332, via Engenheiro Coelho |
| Limeira–Artur Nogueira | Engenheiro João Tosello — SP-147 + Professor Zeferino Vaz — SP-332 |
| Santa Cruz da Conceição–Leme; Santa Cruz da Conceição–Pirassununga | Acesso local + SP-330; nome do acesso pendente |

Não criar ligação direta Pirassununga–Rio Claro ou outras ligações da proposta descartada. Cidades intermediárias citadas na estrada não são novas casas conquistáveis.

PROVISÓRIO: duas arestas rurais alternativas, Araras–Rio Claro e Araras–Artur Nogueira, permitidas para SUV e caminhonete. O usuário pediu sua presença na arte; os traçados e nomes reais não foram verificados. Identificar como rotas ilustrativas, sem nome de rodovia oficial. A SP-191 asfaltada Araras–Rio Claro permanece disponível.

Fontes públicas já consultadas: DER/SP (mapas e denominações), ARTESP (SP-330, SP-191 e SP-310), legislação paulista e prefeituras. Não extrair topologia dos pixels da arte gerada: algumas placas ficaram erradas.

### 3.2 Bloqueios

CONFIRMADO: bloqueiam nos dois sentidos; duram até o início do próximo turno de quem jogou a carta, salvo texto diferente. Remoção antecipada somente por carta. Não existe ação de pagar sucata para remover.

Uma aplicação de bloqueio não pode deixar um carro presente sem saída compatível com seu modelo. Terra permitida para SUV e caminhonete não conta para hatch/sedã. Verificação considera terreno, não o combustível disponível. Avaliar o conjunto de bloqueios já ativos antes de aceitar um novo.

## 4 Preparação e turno

CONFIRMADO: sortear ordem, carro e sub-regiões iniciais diferentes; território inicial recebe controle e defesa padrão íntegra. Carro determina kit inicial e equipamento fixo. Cada jogador recebe 2 gerais e nenhum equipamento adicional. Restante do mapa começa com ameaça aleatória.

PROVISÓRIO: sortear posições válidas sem dois jogadores na mesma cidade quando possível; remover ameaça da casa inicial; depósitos vazios. Integridade inicial máxima.

Turno atualizado:
1. Expirar efeitos e renovar contadores por turno.
2. Jogador da vez compra 1 carta geral, ajustando a mão ao limite.
3. Ações livres legais.
4. Opcionalmente viajar para **uma cidade vizinha**, pagar combustível e resolver evento da estrada.
5. Se o evento permitir, executar **uma ação principal na chegada**, ou na cidade atual se não viajou.
6. Resolver encerramento, limites, recuperação e vitória; passar a vez.

CONFIRMADO: viajar não substitui a ação principal. O antigo deslocamento de até quatro sub-regiões não vale mais. Evento que interrompe a vez pode impedir a ação na chegada.

Ações principais: explorar; conquistar; atacar carro; saquear; administrar. Administrar inclui reparo complexo, reparo territorial, troca de carro ou instalação territorial remota. PROVISÓRIO: uma operação por ação Administrar.

Ações livres no próprio turno, fora de combate/corrida: instalar equipamentos; acessar depósitos próprios da cidade; abastecer; instalar melhoria territorial local; comprar melhoria com sucata uma vez por turno; recolher sucata abandonada na cidade com carro operacional. Reparos simples são livres, mas seu limite é provisório.

## 5 Recursos e exploração

CONFIRMADO: combustível único para gasolina/etanol; sucata; pneus; bateria; água; munição. Sem trocas ou doações entre jogadores; ajuda por cartas é permitida. Sem consumo obrigatório de água/comida por passar rodada.

Depósito de cada sub-região: 10 unidades, incluindo combustível, ampliável por melhoria. Retirada/depósito livres na cidade atual em território próprio. Sem acesso remoto comum. Excedente: jogador escolhe o que manter e descarta o resto. Combustível encontrado pode abastecer o tanque respeitando capacidade.

PROVISÓRIO: 1 recurso ocupa 1 carga; combustível no tanque não ocupa carga, reserva transportada ocupa. Recursos descartados saem do jogo. Estoque territorial transfere ao conquistador; recursos encontrados não surgem automaticamente na conquista.

Explorar usa a ação principal e revela carta regional, com raridade temática híbrida. Recursos são mais prováveis em locais compatíveis, mas não exclusivos. O conceito de três explorações foi confirmado; **escopo exato ainda é provisório**: adotar 3 usos por sub-região, compartilhados entre donos e sem renovação automática. Baralho por cidade com perfil por sub-região simplifica o MVP. Exploração de emergência e permissão em casa alheia dependem da seção 10.

## 6 Veículos e equipamentos

CONFIRMADO: existem quatro classes: hatch, sedã, SUV e caminhonete. Hatch e sedã usam asfalto; SUV e caminhonete usam asfalto e terra. Cada carro tem equipamento inicial fixo do modelo e **2 espaços adicionais**. Equipamento instalado só ocupa carga extra se a carta indicar. Não instalado fica na mão, sem ocupar carga.

Mãos: até 5 gerais e 3 equipamentos; escolher excedente a descartar. PROVISÓRIO: reserva separada de 3 melhorias territoriais. Tipo da carta determina limite, não baralho de origem.

Retirar/substituir equipamento instalado o descarta. Ao inutilizar carro, descartar equipamentos na mão, mas manter instalados. Instalados são descartados por efeitos, troca do carro ou eliminação. Fixos continuam vinculados ao modelo.

CONFIRMADO: duas melhorias iguais podem ocupar os dois espaços e somar efeitos, salvo carta única/restrição. Territorial também tem dois espaços; substituir somente se nova carta permitir. Instalar localmente é livre; remotamente consome turno. PROVISÓRIO: melhorias de depósito compartilham os dois espaços territoriais.

Baralho de melhorias: equipamentos e melhorias territoriais. Acesso por gerais, exploração ou sucata. Compra com sucata é livre uma vez por turno; efeitos de cartas não consomem esse limite. Preço 3 sucatas é PROVISÓRIO.

## 7 Cartas e janelas

CONFIRMADO: comprar 1 geral por turno próprio; usar até 1 geral por jogador em **cada turno do mapa**, inclusive adversário. Combate e corrida não renovam limite. Cartas para afetar dados devem entrar antes da rolagem; nunca alterar dado já lançado.

Prioridade segue ordem dos turnos, começando pelo jogador da vez. PROVISÓRIO: uma passagem por jogador em cada janela; passar não gasta a cota. Cartas sem dado entram antes da ação afetada.

Proibição prevalece sobre permissão comum; exceção exige texto explícito. Cartas da mão têm verso igual para roubo às cegas. Baralhos separados: gerais, melhorias, exploração por cidade/perfil, deslocamento, ameaças, veículos e surpresas de corrida. PROVISÓRIO: embaralhar descarte ao esgotar; não reciclar permanentes ativas.

## 8 Combate e conquista

CONFIRMADO: Defesa = mínimo no D6 para acertar; Integridade = reserva de dano. Atacante age primeiro, sobreviventes respondem, depois há fuga entre rodadas. Cada arma/ataque disponível resolve separadamente. Carro e defesa territorial possuem estados separados. Antes de cada ataque escolher alvo.

Defesa territorial faz um ataque por rodada mesmo sem dono. Se dono tiver carro operacional na cidade, pode escolher defender pessoalmente antes da primeira rolagem. Sem bônus automático por participação conjunta; danos individuais persistem. Conquistar exige destruir fortificação e inutilizar/expulsar carro defensor, se participar. Nova posse recebe defesa padrão íntegra imediatamente, descartando melhorias anteriores.

Ameaça derrotada é descartada. Se sobreviver à retirada mantém danos; cura somente por carta geral. Recuperar carro derrotado não conquista território: uma nova tentativa exige nova carta de inimigo. **ABERTO:** aplicação dessa recompra em território já controlado por adversário; não gerar ameaça além da defesa dele sem regra explícita.

Carro recuperado permanece no local. A posição operacional do carro é a cidade; manter referência opcional à sub-região onde foi derrotado para contexto de recuperação.

### Fuga entre jogadores

CONFIRMADO: teste D6 + agilidade; exige combustível de viagem e rota legal para **sair da cidade**, até cidade vizinha. Exige também carta na mão. Se não houver carta não pode fugir de outro jogador. Sem rota/combustível não há tentativa.

Vencedor escolhe uma carta adversária às cegas, após misturar elegíveis viradas para baixo; equipamentos não instalados são elegíveis. Instalados não são. Transferir somente uma carta por combate, tanto por inutilização quanto fuga; no primeiro caso roubar antes do descarte obrigatório dos equipamentos. Respeitar limite do tipo recebido.

PROVISÓRIO: sucesso 5+, retirada sem novo evento da estrada e sem ação adicional. Falha continua combate sem ataque gratuito extra. Contra ameaça, pagamento de carta não se aplica. **ABERTO:** melhorias territoriais na mão também elegíveis ao roubo; usar configuração explícita, padrão provisório sim.

## 9 Saque

CONFIRMADO: ação principal + 1 combustível; escolher depósito alheio na cidade. Sem conquistar nem destruir melhorias. Atacante 1D6, defesa 1D6+1; empate defesa. Sucesso: escolher até 2 unidades de recursos do depósito, incluindo combustível, respeitando capacidades. Falha: 2 danos e nenhum recurso.

Qualquer tentativa ativa alerta até início do próximo turno do saqueador; ninguém saqueia aquela sub-região no intervalo. Marcar jogador e turno de expiração, inclusive se ele for eliminado — PROVISÓRIO: expirar quando sua posição na ordem fosse alcançada.

Se dono operacional na cidade optar pela defesa pessoal: combate normal **apenas entre carros**, fortificação não participa. Vencedor saqueador leva até 2 recursos; se fugir/perder não leva recursos. Custos e alerta permanecem. Regra geral de roubo de uma carta por vitória PvP também se aplica. Não aplicar os 2 danos da disputa simples adicionalmente à derrota em combate.

Não existem cartas soltas no depósito. Saque não rouba cartas nem equipamentos instalados; roubo de mão é consequência distinta de combate PvP.

## 10 Recuperação, eliminação e troca

CONFIRMADO: Integridade zero inutiliza, não elimina automaticamente. Reparos simples são livres; complexos consomem ação e dispensam oficina. Falta de combustível sem possibilidade de recuperação pode eliminar após esgotar as três explorações e alternativas. Ao recuperar carro, permanece no local.

PROVISÓRIO operacional: emergência permite uma exploração por ação usando usos restantes do local, inclusive território alheio sem acessar depósito. Após esgotar, um último turno com compra geral; se continuar sem solução executável, eliminar. Plano de conserto em etapas pode continuar somente se executar progresso real. Essa janela e exploração alheia não foram validadas individualmente pelo usuário.

CONFIRMADO: eliminado descarta recursos da carga e tanque. Territórios ficam abandonados preservando defesas e estoques; exigem conquista. Equipamentos adicionais instalados e mãos são descartados, respeitando roubo prévio. Se carro utilizável e eliminação por combustível, deixar carro vazio recuperável. Se perdido por inimigo gera sucata local; por outro jogador entrega sucata ao vencedor respeitando carga. Qualquer carro operacional na cidade pode recolher sucata local como ação livre no próprio turno; primeiro a recolher fica com ela.

Troca: carro encontrado na cidade; reparar antes, em turno separado se necessário; assumir usa Administrar. Carro antigo vira sucata, adicionais instalados descartados. Transferir recursos e combustível respeitando capacidades; excedente em depósito próprio local ou descarte. Novo carro mantém equipamento fixo próprio. PROVISÓRIO: mão não instalada permanece na troca voluntária; sucata gerada = 3.

## 11 Corridas

CONFIRMADO: evento de deslocamento convoca corrida; revelador deve entrar se puder pagar e tiver carro utilizável; demais podem entrar de qualquer cidade. Custo até 5 combustível, indicado na pista. Sem combustível não entra e não sofre penalidade. Pista separada neutra; ao final retornar à posição anterior. Só primeiro ganha prêmio grande.

Avançar 1D6 por rodada acumulando posições. Cada pista tem distância abstrata e marcos próprios: alcançar/ultrapassar compra surpresa do **baralho de corrida**. Exemplo aceito: 15 posições com marcos 6 e 12. Surpresas podem ajudar/prejudicar outros. Não confundir posições com quilômetros reais.

CONFIRMADO: não há desistência voluntária; o participante sai se o carro for destruído por efeito de carta. Interpretação adotada na conversa: prova termina na chegada de um vencedor; destruição encerra participação do carro. **ABERTO:** distinção entre destruído/inutilizado em corrida e impacto de falhas mecânicas; não converter automaticamente em eliminação do jogador.

PROVISÓRIO: cada marco uma vez por participante; cruzar vários resolve em ordem, inclusive por avanço de efeito. Retrocesso não reativa. Completar rodada final, maior progresso vence; empate por D6 sem cartas. Sem bônus passivo de velocidade. Rival neutro para um inscrito é **proposta não validada**, desativado por padrão até decisão. Sem inscritos ou todos retirados: sem prêmio, provisoriamente.

Pistas sugeridas: Araras–Limeira 15, marcos 6/12; Araras–Piracicaba 21, 7/14; Rio Claro–Americana 18, 6/12. Apenas primeira distância/marcos têm exemplo aprovado; demais são conteúdo de teste. Prêmio, catálogo de surpresas e rolagens de rival precisam de conteúdo final.

## 12 Parâmetros provisórios para o primeiro build

Nunca espalhar números nas regras; manter RuleConfig e conteúdo versionados.

### Capacidades e consumo confirmados

| Parâmetro | Hatch | Sedã | SUV | Caminhonete |
|---|---:|---:|---:|---:|
| Tanque | 8 | 12 | 12 | 15 |
| Carga máxima | 1 | 7 | 6 | 10 |
| Consumo por viagem | 1 | 2 | 2 | 3 |
| Asfalto | Sim | Sim | Sim | Sim |
| Terra | Não | Não | Sim | Sim |
| Autonomia sem outros gastos | 8 viagens | 6 viagens | 6 viagens | 5 viagens |

CONFIRMADO: consumo fixo e inteiro por ligação entre cidades. Não aplicar adicionais por carga ou por terra. Os antigos adicionais de 0,5, a representação de combustível em meios pontos e o consumo base 1,5 da caminhonete foram substituídos. Usar unidades inteiras de combustível no modelo de dados e nos saves novos. Ações/cartas com custo próprio não são multiplicadas pelo consumo do veículo.

CONFIRMADO: todos começam com tanque cheio, 1 sucata na carga, equipamento fixo, 2 cartas gerais e nenhum equipamento adicional. Assim, o hatch começa com sua carga ocupada; combustível no tanque não ocupa carga. Não entregar o kit antigo de pneus, munição e 3 sucatas.

### Atributos de combate ainda provisórios

| Parâmetro | Hatch | Sedã | SUV | Caminhonete |
|---|---:|---:|---:|---:|
| Defesa | 4+ | 4+ | 3+ | 3+ |
| Integridade | 6 | 8 | 10 | 10 |
| Agilidade | +1 | 0 | 0 | 0 |
| Espaços adicionais | 2 | 2 | 2 | 2 |

Os dois espaços adicionais são confirmados para todos. Defesa, integridade, agilidade e ataque fixo básico de dano 1 sem munição são parâmetros de teste. Equipamento específico de cada modelo ainda precisa de definição; não inventar habilidade exclusiva da caminhonete.

Defesa padrão provisória: 4+, Integridade 4, dano 1. Ameaças leve/média/forte: Defesa 3/4/4+, Integridade 3/5/7, dano 1/1/2.

Acerto provisório: 1 natural falha, 6 natural acerta, Defesa efetiva 2–6; sem crítico extra. Ataque consome custo antes de rolar. Só arma instável sofre 1 dano próprio em 1 natural. Defensores respondem fortificação antes do carro.

Reparo simples 1 sucata → 1 Integridade, uma vez por turno, não reativa carro zero; complexo 2 sucatas → 4 Integridade ou remove uma condição. Defesa 1 sucata → 2 Integridade, até 2 sucatas por ação.

Condições sugeridas: pneu e superaquecimento precisam de efeitos redefinidos, pois consumo fracionário e viagem longa foram removidos. Não ativar os efeitos antigos; materiais sugeridos de reparo: 1 pneu e 1 água, respectivamente; suspensão impede terra (2 sucatas complexo); elétrica desativa elétricos (1 bateria simples); motor impede viagem/corrida (2 sucatas complexo).

Bônus confirmado é local e não produz recurso automático. Efeito específico ainda provisório: uma redução de 1 dano por turno dentro da cidade, mínimo zero. Não apresentar como bônus definitivo de todas as cidades.

## 13 Direção visual e interação

Arte original de corrida pós-apocalíptica: ferrugem, metal reaproveitado, preto, areia e laranja queimado. Referências de atmosfera: Mad Max e energia de corrida de Heat, sem copiar logos/personagens. Cidade como mancha urbana aérea ilustrada, com bairros delimitados; não usar quadros genéricos repetidos. Arte não é satélite geograficamente preciso.

Cada cidade: pátio para até 4 carros, sub-regiões com controle, Integridade, explorações e estoque. Usar cores + ícones + rótulos para acessibilidade. Rodovias asfaltadas sólidas; terra marrom tracejada e indicação SUV / Caminhonete. Marcadores claros sobre fundo detalhado. Zoom/pan e painel lateral evitam texto minúsculo. Recursos e cartas devem ser componentes de interface, não texto embutido na imagem.

Ativos existentes: esquema v03; artes ilustradas com cidades e acessos rurais; hatch vermelho/laranja, sedã azul-petróleo, SUV prata e caminhonete preta com caçamba aberta, todos vistos de cima. Não assumir transparência dos PNGs dos veículos sem verificar canal alfa. Imagens geradas possuem rótulos/quantidades inconsistentes; usar somente como fundo/conceito, com dados oficiais da partida sobrepostos.

## 14 Arquitetura recomendada para Codex

PROPOSTA técnica compatível com desenvolvimento local: React + TypeScript + Vite, motor puro TypeScript, conteúdo JSON, persistência IndexedDB. Não precisa de backend no hot-seat. FastAPI pode ser acrescentado depois para multiplayer/persistência compartilhada; não criar duas fontes de regras.

Diretórios sugeridos: src/domain (tipos, comandos, validação, reducers), src/content (cidades/rotas/veículos/cartas/config), src/application (sessão, salvar, projeções), src/ui (mapa/painéis/modais), public/assets (arte), tests (regras e cenários), docs (este GDD).

Motor: validate(state, command) retorna erros ou plano; execute aceita RNG injetado e devolve novo estado + eventos. Renderização nunca decide acerto, saque ou domínio. Comando inválido não gasta recurso. Uma única semente e estado RNG serializados permitem reproduzir partidas. Guardar versão do schema e do conteúdo no save.

### Entidades mínimas

- GameState: schemaVersion, contentVersion, seed/rngState, players, turnOrder, turnNumber, activePlayerId, phase, cities, territories, decks, pendingInteraction, eventLog, winner.
- Player: id, name, status, cityId, vehicle, inventories, hands, usedGeneralThisTurn, improvementPurchaseUsed, simpleRepairUsed, emergency.
- VehicleInstance: instanceId, modelId, integrity, fuelUnits, conditions, installedEquipmentIds, fixedEquipmentId.
- Territory: id, cityId, ownerId|null, abandoned, threatInstance|null, defense, improvements, storage, explorationUses, alertUntilTurn.
- Road: id, cityA, cityB, surface, allowedVehicleClasses, label, officialStatus, blockedEffects. Permitir arestas paralelas asfalto/terra entre mesmo par.
- CardDefinition: id, deck, type, timing, targets, costs, effects, duration, restrictions, artwork; CardInstance com ID único e proprietário/zona.
- CombatContext: attacker, defenderCar?, threat?, fortification?, intent (conquest/raid/duel), stage, round, selectedTarget, originCity, retreatOptions, lootResolved.
- RaceContext: trackId, mapTurnId, participants, returnCityByPlayer, progress, triggeredMilestones, round, stage, finishers.
- Effect: source, target, kind, stackingRule, startsAt, expiresAt, explicitExceptions.

Separar definições imutáveis de instâncias. IDs de cartas únicas não são nome da carta. Estoque em território não integra inventário global. Contadores por turno referem-se ao turno do mapa; nenhum reset ao iniciar combate/corrida.

### Comandos essenciais

CreateGame, StartTurn, PlayGeneralCard, PassReaction, Travel, Explore, Conquer, AttackCar, Raid, ChooseDefenseParticipation, AttackTarget, AttemptEscape, ChooseHiddenCard, StoreResources, WithdrawResources, InstallEquipment, InstallTerritorialImprovement, BuyImprovement, Repair, RecoverVehicle, CollectScrap, JoinRace, RollRace, ResolveRaceSurprise, DiscardExcess, EndTurn.

Choice e Roll são resolvidos pelo motor; interface não manda resultado de dado em modo normal. Uma interação pendente bloqueia comandos incompatíveis. Retorno de corrida reabre exatamente a ação interrompida, sem pagar viagem ou comprar geral outra vez.

## 15 Telas do MVP

1. Configurar partida e sortear jogadores/carros/inícios.
2. Mapa com seleção de cidade, rotas legais, custos e ação principal restante.
3. Painel do carro com tanque, carga, condições, cartas e slots.
4. Painel territorial com depósito, defesa, melhorias, alerta e exploração.
5. Modal de reação respeitando ordem e mão oculta.
6. Combate com alvos separados e saída explícita.
7. Pista de corrida, marcos usados e participantes.
8. Resgate/eliminação e resultado da partida.
9. Salvar/carregar e histórico auditável.

Hot-seat precisa de tela de passagem antes de revelar mão do próximo jogador. Escolha cega mistura apenas elegíveis; não vazar tipo, frente ou ordem anterior das cartas. No modo de desenvolvimento permitir seed fixa, estados de cenário e visualizar configuração provisória.

## 16 Plano de implementação e aceite

### Etapa 1 Motor e conteúdo mínimo

Criar tipos, grafo de 12 cidades/35 territórios, config, RNG e save. Aceite: IDs válidos, soma 35 e pontos 8; duas arestas Araras–Rio Claro sem colisão; round-trip de save conserva RNG.

### Etapa 2 Turno, viagem e inventários

Aceite: viajar uma cidade e agir; não gastar combustível local; acesso a todos depósitos próprios da cidade; bloqueio bidirecional e validação de saída por veículo; comando inválido não altera estado.

### Etapa 3 Ameaças, combate e domínio

Aceite: danos persistem; fortificação e carro independentes; escolha de defender antes do dado; fuga sai da cidade e exige carta em PvP; roubo antes do descarte; nova defesa íntegra; vitória por controle simultâneo.

### Etapa 4 Saque e cartas

Aceite: disputa simples +1 defesa/empate; limite 2; falha dano 2; alerta compartilhado; defesa pessoal somente carro; limite geral não renova no combate; equipamentos instalados nunca roubados.

### Etapa 5 Recuperação e corridas

Aceite: inutilização não elimina imediatamente; recursos eliminados descartados; carro sem combustível recuperável; corridas não criam turnos extras; marcos não repetem; retorno à cidade e prêmio único.

### Etapa 6 Interface e arte

Aplicar fundo ilustrado depois do motor funcionar. Hitboxes e etiquetas vêm do conteúdo estruturado. Medir legibilidade e espaço de carros, testar 2 e 4 jogadores e registrar consumo, duração, conquistas, saques e mortes. Não chamar uma simulação matemática de playtest humano.

## 17 Decisões abertas que não devem ser inventadas

- Nomes e perfis finais das 35 sub-regiões; nome do acesso a Santa Cruz; validação real das rotas rurais.
- Balanceamento por partidas de teste; consumo, carga, tanques e kit inicial já estão confirmados. Fichas de combate, preços, reparos, munição e recompensas ainda são provisórios.
- Limite e descarte da reserva territorial; inclusão dela no roubo.
- Escopo dos três usos de exploração e protocolo definitivo de emergência.
- Reconquista com inimigo novo quando território pertence a outro jogador.
- Duração de combate sem dano e saída forçada quando não existe fuga legal.
- Corrida com um participante; carros destruídos versus inutilizados; consequências definitivas da destruição na corrida.
- Condição de superaquecimento adaptada ao novo deslocamento.
- Bônus próprios por cidade e composição completa dos baralhos.

Não bloquear a criação do projeto por esses itens: isolar provisórios em config; deixar recursos sem regra desabilitados com indicação no modo dev. Não solicitar aprovação de cada detalhe técnico reversível.

## 18 Prompt inicial para o Codex local

> Leia integralmente docs/GDD_Terras_Devastadas_Codex.md. Implemente um protótipo local em React, TypeScript e Vite com motor puro desacoplado da interface. Comece pelas etapas 1 e 2; avance incrementalmente para combate, saque e corrida. Preserve regras CONFIRMADAS, isole PROVISÓRIAS em RuleConfig e não invente respostas para itens ABERTOS. Use arte apenas como fundo e dados JSON para cidades, rotas e cartas. Primeiro inspecione o repositório e aproveite o que existir; não substitua arquivos do usuário indiscriminadamente. Faça testes significativos das transições e invariantes. Entregue comandos para rodar, estado das etapas e limitações reais. Não implemente autenticação, nuvem ou multiplayer antes do hot-seat funcionar.

Este arquivo é a referência consolidada para o build inicial. Mudanças futuras devem atualizar o GDD, o conteúdo versionado e os testes afetados juntos.


## 19 Atualização de veículos e migração para o Codex

Esta versão consolida e substitui os números do complemento `Contexto_Atualizacao_Codex_Caminhonete.md`. Não usar os antigos valores de carga 16, tanque 14 ou consumo 1,5 da caminhonete. As tabelas confirmadas da seção 12 prevalecem.

Adicionar identificador `pickup`, exibido como Caminhonete. Permissões devem estar nos dados, como `allowedSurfaces`, incluindo asfalto e terra para SUV e caminhonete. Eliminar verificações universais do tipo `vehicle.type === 'suv'`. Atualizar cadastro, sorteio, descoberta, troca, viagem, fuga, bloqueios e legendas. Arte preta não concede vantagem mecânica adicional.

Manter seed e IDs estáveis. Migrar saves antigos explicitamente se usavam meios pontos: converter conforme schema de origem, sem adivinhar unidade pelo valor. Se não houver conversão segura, informar incompatibilidade e manter arquivo original intacto. Ao reduzir capacidades em save migrado, encaminhar excedente para escolha de descarte antes de permitir continuar; não apagar recursos silenciosamente. Aplicar tanque cheio e kit novo somente a novas partidas, nunca reabastecer saves existentes por atualizar conteúdo.

### Testes obrigatórios desta atualização

- Cadastro contém quatro classes e valores exatos da seção 12.
- Nova partida: tanque cheio específico e somente 1 sucata na carga; 2 gerais e zero equipamento adicional.
- Hatch com 1 carga cabe; segunda unidade exige resolução de excedente.
- Mesma viagem custa 1/2/2/3 para hatch/sedã/SUV/caminhonete.
- Carga cheia e terra não acrescentam consumo; hatch/sedã continuam impedidos na terra.
- SUV e caminhonete com combustível suficiente podem viajar e fugir por terra; fuga PvP continua exigindo carta.
- Validação de bloqueio reconhece terra como saída para caminhonete.
- Combustível insuficiente rejeita comando sem alteração de estado.
- Tanque não aceita acima de 8/12/12/15, respectivamente.
- Save/load preserva unidades inteiras, equipamentos, carga e posição.
- UI mostra custo fixo e distingue carga do tanque.

### Prompt para atualizar projeto existente

> Leia integralmente docs/GDD_Terras_Devastadas_Codex_v04.md. Esta versão consolida o GDD 0.3 e o complemento da caminhonete e substitui seus valores antigos. Inspecione o repositório e atualize o projeto preservando o progresso existente. Implemente quatro classes: hatch carga 1/tanque 8/consumo 1; sedã carga 7/tanque 12/consumo 2; SUV carga 6/tanque 12/consumo 2; caminhonete carga 10/tanque 15/consumo 3. Somente SUV e caminhonete usam terra. Consumo fixo inteiro, sem adicionais por carga ou terreno. Novas partidas começam com tanque cheio, 1 sucata, equipamento fixo, 2 cartas gerais e nenhum adicional. Atualize conteúdo, tipos, UI, sorteio, troca, rotas, fuga, bloqueios e persistência; migre saves com segurança e não reabasteça saves existentes. Preserve regras confirmadas, isole provisórias e registre abertas. Execute testes relevantes e build. Entregue resumo das mudanças e instruções para rodar localmente.
