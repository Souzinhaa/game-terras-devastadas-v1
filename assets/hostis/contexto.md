# Terras Devastadas — integração dos 12 hostis

## Escopo e precedência
Este pacote substitui o inimigo genérico por 12 definições de hostis. O usuário aceitou iniciar com estes nomes, atributos e efeitos. O balanceamento continua inicial e deve ser testado, sem alterar automaticamente os veículos ou outras regras do GDD v0.4. Não substitui defesa territorial de jogador por hostil aleatório.

Arquivos: 12 cartas PNG em `cartas/H01.png` a `H12.png`, `hostis.json`, este contexto e `catalogo.md`. Arte completa vertical 1024 × 1536, vinho/bordô em vez do laranja do baralho geral. Cada PNG já contém nome, nível, vida, defesa, dano e efeito. Não recortar nem cobrir o texto. Exibir com object-fit contain, zoom ao clicar e descrição acessível em texto.

## Atributos
maxHealth é vida máxima; health atual pertence à instância. defense é o mínimo do D6 necessário para o jogador acertar o hostil, não armadura ou bônus em disputa de dados. attackDamage é dano por acerto, não número de dados. Cada hostil faz um único ataque por rodada, rolando 1D6 contra a Defesa do carro. Usar a ordem de combate existente: jogador ataca, hostil sobrevivente responde, depois fuga. Não atacar após vida chegar a zero.

Ataques hostis não consomem munição da carga do jogador. Não implementar fraquezas, prêmios, roubo de recursos ou ataques adicionais não descritos. Cartas gerais que modificam ataques entram antes do dado, na ordem vigente; não permitir resposta retroativa ao resultado.

## Gatilhos
- H04 Vigia armado: +1 somente no primeiro ataque que tentar em cada combate, mesmo se errar. Marcar firstAttackUsed ao rolar. Não acumular a cada rodada.
- H07 Atirador: +1 em cada rolagem de ataque própria. Não alterar sua Defesa 5+.
- H08 Emboscadores: −1 no teste de fuga do oponente contra este hostil. Não proíbe fuga, não consome combustível extra, não aplica a outros combates.
- H11 Gangue incendiária: somente 6 NATURAL e acerto concedem +1 dano. Um 5 modificado para 6 não ativa. É dano imediato, sem condição de queimadura posterior.
- H12 Sentinela: primeiro ataque que a acertar no combate sofre redução de 1, mínimo zero; consumir proteção nesse acerto mesmo se dano final zero. Erros não consomem. Não reduzir todos os ataques da rodada.
- Outros sete modelos não possuem efeito especial. Arrays effects vazios não recebem comportamento genérico oculto.

Flags de primeiro ataque e proteção pertencem ao CombatContext e são renovadas ao iniciar novo confronto. Vida do hostil pertence à instância territorial e NÃO renova. Uma fuga encerra combate; ao retornar, mesmo inimigo e mesma vida, novos flags por combate. Essa precisão operacional fecha a redação “primeiro ataque” e não cria cura.

## Persistência e cartas gerais
Hostil territorial sobrevivente mantém dano após fuga, turno e save/load. Só cura por efeitos de carta geral, respeitando maxHealth. Derrotado é removido/descartado. Conquista aplica defesa padrão e controle conforme GDD; não somar simultaneamente ameaça neutra e defesa padrão na mesma resistência sem evento explícito.

Para ameaça temporária de evento V15, sortear da faixa fácil e seguir o ciclo próprio do evento: descartar ao encerrar encontro, mesmo se houver fuga, conforme catálogo anterior. Isso é diferente de apagar inimigo territorial após fuga.

## Sorteio e cópias
Quatro modelos por nível; duas cópias de cada totalizam 24 cartas conceituais. Atenção: existem 35 sub-regiões e 24 cópias não bastam se todas receberem inimigo simultaneamente.

Decisão técnica provisória para protótipo digital: amostrar um modelo uniforme dentro do nível permitido COM REPOSIÇÃO e criar instanceId único por ocupação. copies=2 é composição do catálogo, não limite de quantos inimigos vivos podem existir nesse modo. Não esgotar um baralho físico e deixar casas sem ameaça por acidente. Guardar samplingMode='with_replacement' como configuração explícita. Se o projeto já usa baralho finito, manter modo e apontar necessidade de aumentar cópias antes de mudar silenciosamente a regra.

O nível é dado pela sub-região; não sortear difícil em qualquer casa. Se difficulty não existir no conteúdo, adotar easy apenas no perfil de desenvolvimento e marcar território como pendente de classificação. Não inventar níveis reais para todos os bairros.

## Modelo de estado
HostileDefinition: id, name, tier, maxHealth, defense, attackDamage, attacksPerRound, effects, image.
HostileInstance: instanceId, definitionId, territoryId ou eventId, currentHealth, revealed, origin.
CombatContext: hostileInstanceId, firstAttackUsed, firstHitReductionUsed, round, stage.

Fonte da regra é JSON/motor, nunca OCR da imagem. Efeitos são descritores tipados: implementar handlers explícitos. Vida no painel deve usar currentHealth/maxHealth e não resetar com rerender. Mostrar nome específico, card art, três atributos, efeito e histórico de modificadores. Não deixar apenas “Sobreviventes hostis”.

## Integração no Codex
Copiar PNGs para `public/assets/hostiles/` ou pasta equivalente; resolver image relativo à raiz importada. Ajustar manifesto se mover arquivos. Preservar arquitetura existente. Incluir definições no motor, sorteio por faixa, combate, cartas de cura e salvamento. Saves antigos com inimigo genérico precisam de migração explícita que preserve dano/vida quando possível; não sortear de novo ao carregar nem curar automaticamente. Registrar mapeamento para manter reprodutibilidade.

## Testes necessários
1. IDs únicos, 12 definições, 4 por nível, 24 cópias conceituais, 12 imagens existentes.
2. Todos fazem um ataque por rodada e somente se vivos.
3. Defesa é limiar de acerto; dano é independente da vida.
4. Vigia perde bônus após primeiro ataque, mesmo errando.
5. Atirador tem +1 de acerto, sem alterar defesa.
6. Emboscadores reduzem fuga somente durante confronto correspondente.
7. Incêndio ativa em 6 natural; não em 5+1.
8. Sentinela absorve 1 no primeiro acerto; não no segundo; erro não gasta proteção.
9. Fuga e save/load conservam currentHealth; novo combate só renova flags.
10. Cura por geral respeita máximo; início de turno não cura.
11. Sorteio com reposição cria instâncias diferentes e não compartilha vida entre duas cópias do mesmo modelo.
12. Cartas não alteram consumo/carga/tanque dos quatro carros.

## Prompt para aplicar
Leia contexto.md, catalogo.md e hostis.json junto do GDD v0.4. Integre estes 12 hostis ao projeto local existente, substituindo apresentação e ficha genéricas. Implemente sorteio por nível, atributos individuais, efeitos tipados e persistência da vida. Use as cartas vinho completas com zoom e texto acessível. Não interprete imagem ou rulesText como código. Preserve regras do jogo e progresso do repositório. Registre a configuração provisória de amostragem e migração de saves. Execute testes e build; informe mudanças e pendências reais.

## Arte e limites
Imagens criadas com image_gen: moldura de ferro rebitado, vinho #651e38, marfim, ilustração pós-apocalíptica original. Prompt mestre: carta completa 2:3 com nome, HOSTIL e nível, ilustração central, três placas VIDA/DEFESA/DANO, efeito literal e um ataque por rodada. H01 foi referência das demais. Revisão visual de todas as cartas; não são arquivos de impressão com sangria certificada. Pacote não inclui verso.
