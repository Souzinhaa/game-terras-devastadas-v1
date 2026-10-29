# Diagnóstico e decisões — rebalanceamento v0.2

Data: 29/10/2026. Revisão editorial e de regras; números ajustados para teste, sem alegação de equilíbrio comprovado. A autorização para selecionar alterações foi dada por Bruno nesta solicitação.

## Fontes e limites
Comparados GDD v0.4, catálogo de 74 cartas v0.1, hostis v0.1 e os dois pacotes de ícones. Não foi disponibilizado o repositório do jogo: nenhum rules.md ou rules-cards.md da implementação foi inspecionado. Os documentos homônimos deste pacote são novas referências para integração, não provas de alterações já aplicadas ao código local.

## O que a revisão acertou
- Tanque cheio + duas cartas antes da compra inicial reduz a pressão de adaptação.
- Ganhos de duas sucatas/munições favorecem veículos com carga e permitem saltar etapas.
- Duas armas instaladas podem gerar dois ataques adicionais por rodada. Este é um acúmulo concreto, não apenas uma hipótese.
- Duas Blindagens levam hatch/sedã de Defesa 4+ a 6+, reduzindo pela metade a chance de acerto frente a uma única blindagem, sem custo por ataque.
- Dois Kits de extração + agilidade do hatch + G05 atingem modificador +4: fuga 5+ torna-se garantida no D6 quando custos/rota são legais.
- Bloqueio remoto por uma geral, sem custo material nem ação, acumula pressão com uma conquista no mesmo turno.
- Vitória territorial imediata impede uma última oportunidade de resposta.

## O que não corresponde ao conjunto atual
- Já existe limite de uma geral por jogador em cada turno do mapa; combate/corrida não o reiniciam. Não acrescentar outro limite equivalente.
- G01 modifica uma rolagem de um dado; não concede dado extra.
- Não há cartas atuais que entreguem simultaneamente dois recursos, Defesa e ataque, nem ataque que atinja todos os jogadores. Não remover um efeito inexistente.
- Bloqueios já expiram e não podem retirar a última saída compatível. Terra não é saída para hatch/sedã.
- Tanque e bagageiro já são ÚNICOS. Não geram combustível ou sucata; têm custo de oportunidade de espaço instalado. Cobrar manutenção aumentaria contabilidade sem evidência de ganho.
- Cidade completa já concede apenas bônus local, sem renda passiva. São necessárias várias cidades para os 4 pontos. A crítica de que uma cidade encerra a partida é exagerada.
- Mais regras de escassez não garantem diversão: água, pneus e bateria ainda não têm todos os usos fechados. Não os tornar obrigatórios sem sistema correspondente.

## Seleção de mudanças
| Tema | Decisão aplicada | Motivo |
|---|---|---|
| Preparação | 1 geral; combustível para 3 viagens por modelo; manter 1 sucata | Menos valor inicial, mesma autonomia de deslocamento |
| Apoio inicial separado | Não adicionar | Evitar novo minibaralho e uma vantagem de recurso garantida |
| G09/G11/G12 | Ganho 2 → 1 | Reposição menor sem matar a carta |
| Recursos unitários G13/G14/G24 | Manter | Já são leves; usos incompletos não justificam redução |
| Armas E01–E03 | 1 ataque de arma adicional por carro por rodada, compartilhado | Escolher a ferramenta em vez de disparar todas |
| E04 | ÚNICA | Impedir Defesa 6+ por duplicação de blindagem |
| E06 | ÚNICA e 1 vez por combate, antes do dado | Diferenciar preparação permanente e geral tática |
| E09 | ÚNICA | Evitar fuga garantida pela combinação de duplicatas |
| G17 | 1 sucata + ação principal; somente turno próprio; sem empilhar em rota já fechada | Custo claro de pressão e resposta por tempo |
| Remoção por manutenção | Não adicionar | G18, expiração e saída compatível já fornecem respostas; bloquear ficou caro |
| G21/G22 | +2/−2 → +1/−1 | Gerais menos dominantes; surpresas e E10 conservam identidade |
| Território | Anunciar 4 pontos ao fim do turno e sustentar até próximo início | Janela de resposta sem imposto periódico |
| Pontos por cidade | Manter | Sem evidência suficiente para redesenhar toda progressão |
| Manutenção de domínio/influência | Não adicionar | Contabilidade extra e necessidade de redesenhar mapa/IA/UI |
| Desvantagem por cidade | Não adicionar | Não há dados de exploração/localidades completos para balanceá-la |
| Hostis/terra/veículos | Manter | Preserve identidades, números inteiros e arte sem alterações desnecessárias |

Não há prova de que toda abertura dominante foi eliminada. Este pacote corrige mecanismos concretos; sessões reais ainda precisam medir o resultado.

## Deltas visuais
Somente G09, G11, G12, G17, G21, G22, E01, E02, E03, E04, E06 e E09 recebem novas frentes. Seus IDs e duas cópias por modelo não mudam. Os demais 62 modelos do catálogo e 12 hostis preservam as frentes antigas. Os novos ícones numéricos necessários e o manifest atualizado também acompanham o pacote. Consumíveis não mudam.
