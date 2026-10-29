# Cartas de Terras Devastadas

Este documento explica a categoria de cartas do jogo, sua função dentro da partida e os tipos de efeito que elas aplicam. Ele foi escrito com base no GDD v0.4 e no catálogo implementado em `src/data/catalog.json`.

## 1. Visão geral

As cartas do jogo se dividem em categorias com funções diferentes:

- Gerais (`Gxx`): efeitos instantâneos, bônus, debuffs, recursos e apoio em combate, fuga e viagem.
- Equipamentos (`Exx`): melhorias permanentes do veículo, com slots e impacto em defesa, ataque, fuga e capacidade.
- Territoriais (`Txx`): melhorias instaladas em uma sub-região, reforçando defesa e depósitos.
- Corrida (`Rxx`): cartas de prova, avanço ou penalidade em eventos de corrida.
- Eventos (`eventos`): cartas de cenário e consequências aleatórias em viagem ou em presença de ameaça.

Cada carta tem:

- ID estável (`G01`, `E07`, `T04`, `R02`, etc.)
- nome
- categoria
- timing (quando pode ser usada)
- texto de regra (`rulesText`)
- cópias no baralho

Algumas cartas são únicas, como `E07` (Tanque suplementar), `E08` (Bagageiro reforçado) e `T05` (Cofre enterrado).

## 2. Como as cartas entram em jogo

As cartas podem ser:

- compradas no início do turno;
- recebidas como recompensa;
- ganhos por exploração ou eventos;
- instaladas em veículo ou território;
- descartadas quando o efeito é usado ou quando o jogador excede limites.

O sistema do jogo também distingue entre:

- carta na mão
- carta instalada
- carta descartada
- carta em baralho

A lógica de cada tipo está centralizada em `src/engine/cardRules.ts` e o catálogo em `src/engine/catalog.ts`.

## 3. Cartas gerais

As cartas gerais são o núcleo de suporte do jogo. Elas afetam ataques, fuga, ameaça, exploração, viagem e recursos.

### 3.1 Função principal

As gerais são usadas para:

- melhorar ataque ou defesa em combate
- reduzir dano recebido
- alterar a chance de fuga
- ganhar recursos imediatos
- bloquear ou remover bloqueios
- criar vantagem em corrida
- reforçar a defesa territorial

### 3.2 Exemplos de efeitos gerais

#### Ataque e dano

- `G01`: Mira de ferro — +1 à rolagem do ataque.
- `G02`: Nuvem de poeira — −1 à rolagem do ataque.
- `G03`: Impacto brutal — se o ataque acertar, causa +1 dano.
- `G04`: Chapa improvisada — reduz em 1 o dano recebido.

Essas cartas alteram diretamente a resolução do combate e funcionam como multiplicadores temporários de ação.

#### Fuga

- `G05`: Cortina de fumaça — +1 à tentativa de fuga.
- `G06`: Cerco fechado — −1 à tentativa de fuga.

Essas cartas afetam o resultado do teste de fuga, sem alterar o custo base da ação.

#### Recursos

- `G09`: Combustível de emergência — recebe 2 combustíveis no tanque.
- `G11`: Suprimento de sucata — recebe 2 sucatas na carga.
- `G12`: Caixa de munição — recebe 2 munições.
- `G13`: Pneu de reserva — recebe 1 pneu.
- `G14`: Bateria recuperada — recebe 1 bateria.
- `G24`: Água para o radiador — recebe 1 água.

Essas cartas resolvem escassez imediata e são muito úteis em situações de sobrevivência.

#### Bloqueios e estrada

- `G17`: Barricada na estrada — bloqueia uma estrada até o início do próximo turno do jogador que a jogou.
- `G18`: Equipe de desobstrução — remove 1 efeito de bloqueio de uma estrada.

Essas cartas alteram a mobilidade do mapa e devem ser usadas com cuidado, porque bloqueios podem impedir deslocamento ou fechar rotas.

#### Saque e corrida

- `G19`: Golpe de oportunidade — atacante recebe +1 no dado de saque.
- `G20`: Vigias atentos — defesa recebe +1 adicional no dado de saque.
- `G21`: Pé embaixo — +2 de avanço na corrida.
- `G22`: Pressão no rival — −2 de avanço na corrida, mínimo zero.

Essas cartas fazem o jogo ter um componente de risco e pressão em disputas diretas.

### 3.3 Regra de uso

Cartas gerais normalmente são usadas imediatamente ou antes de uma ação relevante, conforme o texto da carta. O timing é parte essencial da leitura: o efeito pode valer antes do ataque, antes da fuga, antes da viagem, antes da ação do jogador, ou antes da resolução de evento.

## 4. Equipamentos

As cartas de equipamento são instaladas no veículo. Elas ficam vinculadas ao carro e geralmente melhoram atributos permanentes ou fornecem efeitos especiais por rodada.

### 4.1 Função principal

Os equipamentos alteram:

- ataque
- defesa
- fuga
- capacidade de carga
- capacidade do tanque
- uso de munição
- combate e sobrevivência em viagem

### 4.2 Exemplos de equipamentos

- `E01`: Metralhadora lateral — +1 ataque por rodada, dano 1, custo 1 munição.
- `E02`: Canhão de sucata — +1 ataque por rodada, dano 3, custo 1 munição, mas penalidade no acerto.
- `E03`: Espingarda de bordo — ataque extra, dano 2, só atinge carros.
- `E04`: Blindagem rebitada — aumenta a defesa em 1, até 6.
- `E05`: Placa de absorção — uma vez por combate, reduz em 1 o dano recebido.
- `E06`: Mira estabilizada — uma vez por rodada, +1 ao acerto de um ataque do jogador.
- `E07`: Tanque suplementar — aumenta a capacidade do tanque em +3.
- `E08`: Bagageiro reforçado — aumenta a carga em +2.
- `E09`: Kit de extração — +1 ao teste de fuga.
- `E10`: Suspensão de corrida — +2 em uma rolagem de corrida, uma vez por prova.
- `E11`: Guincho manual — em alguns casos, transfere sucata local mais rapidamente.
- `E12`: Escudo descartável — pode descartar o equipamento para reduzir em 2 o dano de um ataque.

### 4.3 Regras importantes

- o equipamento ocupa slot do veículo;
- alguns são únicos (`E07`, `E08`, `E10`);
- o efeito pode depender de munição, carga ou condições de combate;
- remover um equipamento pode exigir ajustes imediatos de excesso ou de capacidade.

## 5. Cartas territoriais

As cartas territoriais são instaladas em uma sub-região e reforçam a defesa ou os estoques locais de um território.

### 5.1 Função principal

Essas cartas melhoram:

- defesa territorial
- resistência do setor
- capacidade de depósito
- segurança contra saque ou pressão de invasão
- custo de manutenção e recuperação

### 5.2 Exemplos de melhorias territoriais

- `T01`: Muralha de sucata — +2 de integridade da defesa e aumenta a integridade atual em 2.
- `T02`: Torre de tiro — o ataque da defesa territorial recebe +1 de dano.
- `T03`: Posição elevada — +1 de defesa da fortificação, até 6.
- `T04`: Depósito ampliado — aumenta a capacidade do depósito em +5.
- `T05`: Cofre enterrado — único; em saque bem-sucedido, o invasor leva no máximo 1 recurso do depósito.
- `T06`: Reforma planejada — permite descartar uma melhoria para liberar espaço e recupera +1 de integridade por ação administrativa.

### 5.3 Regra de uso

Uma melhoria territorial normalmente só pode ser instalada em um território sob controle do jogador ou em região de sua presença funcional. O jogo trata a instalação como parte da gestão do território e da manutenção da base.

## 6. Cartas de corrida

As cartas de corrida pertencem ao baralho de eventos/provas. Elas afetam diretamente o progresso do jogador em uma corrida.

### 6.1 Função principal

Essas cartas alteram a distância percorrida na pista e podem:

- avançar posições
- reduzir avanço
- penalizar o jogador
- afetar outro corredor
- causar dano e recuo

### 6.2 Exemplos

- `R01`: Reta livre — avança 2 posições.
- `R02`: Atalho da pista — avança 3 posições.
- `R03`: Vácuo perfeito — se estiver à frente, avança 2; caso contrário, avança 1.
- `R04`: Motor afinado — na próxima rolagem de avanço, +2.
- `R05`: Curva aberta — escolhe outro participante: ele avança 2.
- `R06`: Bandeira amarela — você recua 2 posições.
- `R07`: Areia solta — sua próxima rolagem tem −2, mínimo zero.
- `R08`: Barreira improvisada — outro participante recua 2.
- `R09`: Toque lateral — você e outro participante sofrem 1 dano.
- `R10`: Detritos no asfalto — sofre 1 dano e recua 1 posição.

### 6.3 Regra importante

Na corrida, a carta não cria uma rota de mapa; ela altera a prova e o progresso naquele momento. O efeito geralmente é imediato e concreto, com impacto sobre a posição no circuito.

## 7. Cartas de evento

As cartas de evento são efeitos de cenário, ameaça, deslocamento e contexto. Elas podem acontecer ao navegar, ao entrar em território hostil ou ao resolver uma rolagem específica.

### 7.1 Função principal

Cartas de evento podem:

- alterar o clima ou ambiente
- gerar ameaça
- ampliar ou reduzir pressão de combate
- causar dano em veículos ou defesas
- mudar a dinâmica do mapa
- influenciar a viagem ou o entorno do jogador

### 7.2 Características

- normalmente são lidas como cenário e punição/benefício temporário
- o timing depende do gatilho da carta
- podem ser lidas antes da ação, durante o deslocamento ou em resposta à ameaça

## 8. Tipos de efeito de carta

A implementação atual do jogo distingue alguns tipos de efeito, principalmente em `src/engine/catalog.ts` e `src/engine/cardRules.ts`:

- rolagem modificada (`roll`)
- dano direto (`damage`)
- redução de dano (`reduceDamage`)
- ganho de recurso (`resource`)
- reforço de fuga (`escape`)
- efeito especial (`special`)
- penalidade ou bônus de corrida (`race`)
- efeitos de ameaça (`threat`, `threatDamage`)
- ações de saque (`lootAttack`, `lootDefense`)

Esses efeitos são aplicados em momentos específicos do turno ou do combate conforme a carta e o contexto.

## 9. Regras gerais de uso das cartas

### 9.1 Timing

Cada carta tem um “timing”, ou seja, o momento em que pode ser usada. Isso é muito importante. Pode ser:

- antes do ataque
- antes da fuga
- antes da ação do jogador
- antes da viagem
- antes do deslocamento de um participante da corrida
- antes de um saque
- quando instalada em veículo ou território

Se o jogador ignorar o timing correto, a carta pode ser inválida ou não ter efeito.

### 9.2 Prioridade

Quando vários efeitos se acumulam, o jogo normalmente resolve na ordem de:

1. carta ativa do jogador
2. carta de reação ou defesa
3. dano e integridade
4. consequência de mapa ou território
5. fim do turno

### 9.3 Limites

O sistema atual também considera:

- número máximo de cartas na mão
- capacidade de carga
- capacidade de tanque
- limite de melhoria por território
- exceções de cartas únicas
- descarte de cartas excedentes

## 10. Estratégia prática

As cartas não são apenas “power-ups”; elas definem a lógica de planejamento do jogo.

### Em combate

- cartas de ataque e defesa devem ser usadas em momentos de decisão crítica
- uma boa ordem de efeitos pode mudar o resultado de um duelo
- equipamentos melhoram o desempenho de longo prazo, mas consomem slot do veículo

### Em sobrevivência

- cartas de recurso são fundamentais para manter o carro e a tripulação em operação
- combustível, munição e água têm impacto direto na capacidade de exploração e fuga

### Em território

- melhorias territoriais reduzem riscos de ataque e protegem estoques
- um setor bem defendido vale mais no longo prazo

### Em corrida

- cartas de avanço e recuo podem virar a prova em poucos segundos
- o timing e a escolha do alvo são decisivos

## 11. Resumo rápido

Em uma frase:

cartas em Terras Devastadas são ferramentas de decisão, pressão e sobrevivência, e cada categoria tem um papel diferente no fluxo da partida — desde melhorar a força de ataque até fortalecer a base, a fuga, a viagem e a corrida.

## 12. Arquivos relevantes

- `src/data/catalog.json` — catálogo completo das cartas
- `src/engine/catalog.ts` — definição das categorias e efeitos
- `src/engine/cardRules.ts` — regras de uso, descarte e aplicação das cartas
- `src/engine/game.ts` — integração das cartas com o estado global do jogo

## 13. Observação importante

O jogo encontra-se em fase de protótipo e de consolidação do GDD v0.4. Algumas cartas e efeitos podem aparecer como “propostos” ou dependentes de regras ainda em revisão. Mesmo assim, a estrutura operacional da categoria de cartas já está clara no código e na documentação.
