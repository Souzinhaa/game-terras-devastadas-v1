# Integração dos hostis — conteúdo 0.4.2

Base: `assets/hostis/contexto.md`, `catalogo.md`, `hostis.json` e GDD v0.4. O pacote é conteúdo inicial de playtest aceito pelo usuário; não altera ficha, consumo, carga ou tanque dos quatro veículos.

## Módulos

- `src/data/hostiles.json`: manifesto original com 12 definições, quatro por faixa, duas cópias conceituais por modelo e descritores de efeitos.
- `public/assets/hostiles/cartas/`: os 12 PNGs completos, verificados contra SHA-256 e dimensões 1024×1536 do manifesto.
- `src/engine/hostiles.ts`: definições tipadas, instâncias, sorteio, vida persistente, contexto por combate, handlers e validação/migração.
- `src/engine/game.ts` e `cardRules.ts`: integração com conquista, ataque, resposta, fuga, G08, munição, eventos V15 e descarte.
- `src/ui/HostileArt.tsx`: arte sem cortes, ampliação e descrição acessível. Catálogo dos 12 modelos disponível na inspeção de territórios.
- `src/ui/CombatSummary.tsx`: nome específico, arte vinho, nível, defesa, dano, efeito e barra de vida atual/máxima. O histórico registra dados, total, bônus próprio, proteção e incêndio; fuga identifica a penalidade quando houver.

## Instâncias e combate

`Territory.hostile` guarda `instanceId`, `definitionId`, `currentHealth`, `territoryId`, `revealed` e `origin`. `resistance` e `threat` continuam como espelhos compatíveis com o motor anterior; as funções de dano/cura atualizam ambos e os invariantes rejeitam divergências.

Defesa é limiar do dado para acertar. Dano é aplicado por acerto. Um hostil sobrevivente responde uma única vez por rodada; não gasta munição do jogador. Não há fraquezas, prêmios extras ou roubo pelo hostil. A defesa territorial de um jogador continua sendo fortificação, sem hostil sorteado.

O `hostileContext` do combate contém referência à instância, rodada, estágio e flags. H04 consome o bônus no primeiro dado, inclusive falha. H07 aplica +1 em todo ataque próprio. H08 subtrai 1 na fuga somente contra ele. H11 causa +1 dano apenas no acerto de 6 natural. H12 absorve 1 no primeiro acerto recebido, mesmo quando o dano restante é zero; erros não consomem proteção. Modelos sem efeito não recebem habilidade oculta.

Fugir conserva a instância e sua vida no território. O próximo confronto renova flags, não a vida. Save/load conserva tanto ferimentos quanto flags do combate em andamento. G08 cura até o máximo da definição; turno novo não cura. Derrota remove a instância para `hostileDiscarded` e concede a defesa padrão da conquista, sem acumular a vida do inimigo com a fortificação.

V15 sorteia da faixa fácil. A ameaça fica em `eventHostile`, espelhada por `eventIntegrity`, e é descartada ao terminar o encontro, inclusive por fuga ou derrota do jogador. Não concede território e já consome a ação na revelação do evento.

## Sorteio e classificação pendente

O jogo anterior sorteava ameaças com reposição; esse comportamento é mantido explicitamente em `hostileConfig.samplingMode = 'with_replacement'`. As 24 cópias do catálogo não impõem um baralho físico finito às 35 regiões. Cada ocupação possui ID e vida próprios.

O conteúdo atual de cidades não define dificuldade por sub-região. O perfil é `development`, `unclassifiedTier = 'easy'` e territórios ficam com `difficultyPending = true`. O motor aceita as três faixas e sorteia somente dentro da faixa atribuída; nenhuma área recebe nível médio/difícil inventado. A apresentação dos 12 modelos pode ser consultada independentemente do sorteio. O conteúdo atual já expõe nomes das ameaças na inspeção, por isso essas instâncias têm `revealed = true`.

**Pendência real:** classificar as sub-regiões para usar as faixas média/difícil na distribuição regional. Aumentar o número físico de cópias, se desejado para tabuleiro físico, também é decisão separada.

## Migração dos saves

O carregador aceita conteúdo 0.4.0/0.4.1 e versões anteriormente suportadas. Para regiões neutras com ameaça genérica, escolhe deterministicamente uma definição fácil capaz de manter a vida atual, usando o ID da região como chave, sem consumir RNG. Registra em `hostileConfig.migration` o nome anterior, novo ID, ID da instância e vida anterior/posterior. Regiões próprias e fortificações abandonadas sem ameaça não ganham inimigo novo.

Em um V15 legado, vida até 2 é mapeada para H02; acima disso, para H03. O confronto preserva a etapa vigente e recebe flags da nova ficha. Carregar novamente o save convertido não sorteia nem migra novamente.

Se um save personalizado trouxer vida acima de todos os máximos da faixa fácil, a conversão limita ao máximo de H03, registra o valor original e apresenta aviso explícito. Isso não afeta os atributos padrão antigos, cujo máximo era 4. O fluxo de carregamento preserva o arquivo original em backup. Não completa tanques, muda recursos nem cura automaticamente.

Uma partida anterior ainda aberta durante atualização também é convertida antes da próxima ação. Exportar um estado antigo mantém a versão do próprio estado no envelope, para que possa ser migrado sem divergência de versões.

## Verificação

Os testes cobrem composição, faixas, IDs, independência de cópias, atributos, sete modelos sem efeitos, cinco habilidades, um ataque por rodada, descarte, fortificações, fuga, cura, flags e vida em saves, migração determinística e atualização de partidas abertas. As regressões anteriores que fabricam inimigos genéricos continuam isoladas como testes de compatibilidade; a suíte própria usa instâncias reais do catálogo.

Os testes de interface conferem arte completa, zoom no celular, ficha da sentinela, proteção e contra-ataque real, além do catálogo dos 12 modelos e dos fluxos anteriores. Comandos: `npm.cmd test -- --configLoader runner`, `npm.cmd run test:ui`, `npm.cmd run build`.
