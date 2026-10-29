# Terras Devastadas — Marcadores de efeitos v1

## Objetivo aprovado
Aplicar marcadores planos e simples: uma forma de cor sólida com número ou sinal central. Exemplo: círculo vermelho +1 para acerto. Defesa usa escudo azul. Não adicionar ilustração, textura, engrenagens ou moldura de baralho ao marcador. A identidade da categoria permanece na carta e no tooltip; cor do marcador significa efeito, não baralho.

Este pacote é uma camada de apresentação. Não altera regras, valores, chances, baralhos ou balanceamento. Não aprova pendências anteriores do GDD. Abrange as 74 cartas do catálogo v0.1 e os 12 hostis v0.1. Não inclui armas fixas de veículos sem definição no catálogo.

## Arquivos
- manifest.json: 54 marcadores, famílias de cores/formas e mapeamento das 86 definições de carta. Os IDs de carta existentes são preservados.
- svg/: vetores 256 × 256, fundo externo transparente.
- png/32, png/64, png/256: as mesmas imagens rasterizadas, RGBA transparente.
- catalogo.md: consulta rápida por carta.
- galeria.html: abra localmente no navegador para consultar todos os marcadores.
- previa.png: folha visual com os 54 marcadores.

## Integração
1. Inspecione o projeto local e encontre o catálogo, o resolvedor de efeitos e os componentes de carro/combate/corrida/território. Preserve os padrões do projeto e os IDs.
2. Copie os assets para uma pasta pública adequada. Importe o manifest como dados de UI. Prefixe os caminhos relativos pelo diretório público escolhido.
3. Crie um componente EffectBadge com iconId, tamanho, tooltip e estado disponível/usado. Prefira PNG 64 em telas comuns; SVG permite escala livre. SVG usa fonte DejaVu Sans/Arial, podendo variar conforme o sistema; PNG garante aparência fixa.
4. Use a família semântica do efeito para selecionar cor e forma. Para valor dinâmico fora das variantes exportadas, componha a mesma forma e o número em código, usando famílias do manifest. Não estique PNG nem substitua por emoji.
5. Mantenha referência à origem por instanceId, sourceCardId, alvo, duração, frequência e estado de consumo. Esses campos pertencem ao motor existente; não são inferidos pelo nome do PNG.
6. Mostre o efeito ativo junto ao alvo correto e os custos na área de custos. Ganhos/perdas instantâneos aparecem como feedback breve e no histórico; não entram na lista de bônus ativos.
7. Para efeitos condicionais ou escolhas, exiba apenas a alternativa aplicável no estado resolvido. A lista icons no manifest é uma paleta visual da carta, não uma sequência executável. R03, R08, R16 e V10 têm alternativas; R09/R14 podem afetar mais de um alvo.
8. Não interpretar rulesText com LLM durante a partida. O texto foi copiado para consulta e tooltip. A resolução continua tipada no motor do jogo.

## Significado dos números
- Acerto vermelho +1/−1: altera a rolagem de ataque; NÃO adiciona dado nem dano.
- Dano laranja +1: bônus ao dano de ataque que acerta. Dano laranja 1/2/3 sem sinal: quantidade de dano causado, ou dano base de ataque adicional, conforme fonte.
- Defesa azul +1: aumento do limiar defensivo conforme regra existente (teto 6+ quando previsto). NÃO reduz dano recebido.
- Escudo azul claro −1/−2: subtração do dano recebido, mínimo zero. O sinal menos é visual; internamente use o valor positivo de redução esperado pelo motor. Não aplicar dupla negação.
- Verde +1/+2: recuperação de Integridade. Não reativar carro quando o texto proíbe, nem ultrapassar máxima.
- Verde escuro +2: aumento de Integridade máxima. T01 também aumenta atual em 2 preservando dano; seu marcador verde NÃO é cura livre nem recorrente.
- Triângulo roxo: modificador do teste de fuga. Não remove rota, combustível ou carta de tributo PvP.
- Seta amarela: avanço/recuo de corrida; consultar se é deslocamento imediato ou modificador de próxima rolagem. Não alterar dado natural.
- Gota âmbar: combustível atual. Gota turquesa: capacidade máxima; E07 não gera combustível.
- Quadrado marrom: capacidade de carga. Quadrado marrom escuro sem sinal: carga ocupada pelo equipamento (E02=2; E05=1), não bônus.
- Hexágonos rosa claro/escuro: dado do atacante/defesa no saque simples. Não aplicar ao combate com defesa pessoal.
- Quadrado verde oliva: capacidade do depósito, não carga do carro.
- Recursos e compra: ganhos/perdas imediatos ou custos, conforme contexto. Munição −1 de E01–E03 é custo por ataque opcional, pago antes do dado; não perda passiva.
- Cofre 1: limite máximo levado pelo invasor, não bônus nem ganho.
- Transferir 1: até 1 sucata encaminhada ao depósito na condição de E11, não criação de sucata.
- Ação −1: ação principal consumida; não pular turno completo.
- P01/P02/P03: convocar pista correspondente, não avanço de posições.
- Símbolo ∅: sem efeito. Pode aparecer na resolução da carta, mas não deve poluir os estados ativos.
- Incêndio vinho +1: H11 só no 6 natural que acerta; não criar queimadura ou dano por turno.

## Duração, frequência e alvo
### Gerais
G01/G02/G07: uma rolagem de ataque; G07 é da ameaça. G03/G04: um ataque, condicionado ao acerto. G05/G06: um teste de fuga. G19/G20: uma disputa simples de saque, lado correto. G21/G22: uma rolagem de avanço. Declare antes da rolagem e consuma conforme a regra da carta, mesmo se o resultado não trouxer benefício.
G08–G15, G18, G23/G24: resolução imediata, sem bônus persistente. G08 cura ameaça; G23 cura defesa territorial própria; G10 cura carro operacional. G16 inspeciona e devolve ao topo/fundo, sem cancelar evento. G17 cria bloqueio até início do próximo turno da fonte e respeita última saída compatível. G18 remove uma fonte de bloqueio; outras fontes podem continuar fechando estrada.

### Equipamentos
Exibir no carro somente enquanto instalado; reserva não concede benefício.
- E01/E02/E03: um ataque adicional opcional por rodada de combate por instância, com dano e custo próprios. E02 tem −1 apenas no próprio ataque. E03 mira somente carros. Não adicionar o dano da arma ao ataque fixo.
- E04: Defesa +1 enquanto instalado, teto previsto.
- E05: redução −1 uma vez por combate, declarada antes do dado; ocupa 1 carga. Marcar como gasto após uso.
- E06: +1 ao acerto uma vez por rodada de combate, escolhido antes do dado.
- E07/E08: tanque máximo +3/carga máxima +2, ÚNICOS, sem gerar recursos. Ajustar excedentes ao remover.
- E09: +1 nos testes de fuga enquanto instalado.
- E10: +2 em uma rolagem de avanço por corrida; declarado antes; ÚNICO. Não concede acesso à terra.
- E11: até 1 sucata transferida diretamente ao depósito ao recolher sucata local, uma vez por turno próprio; não fabricar recurso.
- E12: descartar equipamento antes da rolagem para redução −2 naquele ataque; remover bônus ao terminar ataque e equipamento ao descartar.

### Territoriais
Exibir no território/defesa/depósito, não no carro do proprietário.
T01 Integridade máxima +2 e atual +2 ao instalar preservando dano. T02 dano +1 do ataque da defesa; não dá segundo ataque. T03 Defesa +1 da fortificação. T04 depósito +5. T05 limite de saque 1, ÚNICA, inclusive após defesa pessoal. T06 permite substituir melhoria na instalação e melhora reparo Administrar +1, sem material adicional. Não é cura automática por turno. T01/T02/T03 não entram como benefícios do carro em defesa pessoal de saque. Conquista descarta melhorias antigas.

### Corrida
R01/R02/R03/R05/R06/R08/R10/R14/R15/R16 alteram posições imediatamente, observando alvos, condições e alternativas. R04/R07 ficam pendentes até próxima rolagem de avanço desse participante e expiram no fim da corrida. R09/R10/R11 causam dano imediato; R13 cura imediatamente. R12 não cria estado. R09 pode causar dano a dois participantes, R14 pode avançar dois; não duplicar efeito quando só há um alvo. R16 recua outro OU avança o próprio.

### Eventos
V01/V02 sem efeito. V03–V10 ganhos/perdas/dano imediatos; V07 afeta somente recurso da carga. V10 escolhe sucata OU munição, não ambos. V11 consome somente ação principal do turno. V12–V14 convocam corrida correspondente, preservando ação conforme regras existentes. V15 gera combate temporário e substitui ação principal uma única vez. V16 revela veículo disponível, sem kit inicial, tanque vazio; não entrega posse automaticamente.

### Hostis
H01/H02/H03/H05/H06/H09/H10: nenhum poder especial; lista de ícones vazia é intencional. Estatísticas continuam exibidas nos campos de vida/defesa/dano, sem inventar bônus.
H04 acerto +1 só no primeiro ataque tentado de cada combate; consome mesmo se errar. H07 acerto +1 em todas as próprias rolagens de ataque. H08 fuga −1 no jogador enquanto combate com ele. H11 dano +1 somente se 6 natural E acerto. H12 redução −1 só no primeiro ataque que o acertar em cada combate; erro não consome, acerto com dano final zero consome. Reiniciar flags em novo combate, mantendo dano territorial persistente conforme regras.

## Leitura e acessibilidade
- Usar 32 a 40 px nos estados ativos e 48 a 64 px no detalhe. Área clicável pode ser maior que a arte.
- Tooltip ou toque mostra nome, valor, origem, alvo, duração, custo/frequência e condições. Exemplo: “Acerto +1 — Mira de ferro — próximo ataque declarado”.
- Cor e forma nunca substituem o texto acessível: aria-label obrigatório. Algumas famílias têm formas semelhantes; texto e tooltip distinguem sem depender apenas da cor.
- Não aglutinar custos com bônus ativos. Só somar modificadores se tipo, alvo e duração forem compatíveis. Preserve origens e limites individuais na expansão.
- Mostrar benefícios condicionais como disponíveis até serem usados; não somar ao total de estatísticas antes de escolher ativar.
- Não usar vinho para recolorir um círculo de acerto de hostil: a origem hostil aparece no tooltip/carta; o acerto continua vermelho.

## Verificações de aceitação no projeto
1. G01 exibe círculo vermelho +1 no acerto, sem aumentar dano ou quantidade de dados.
2. G04/E05/E12 reduzem dano; E04 aumenta Defesa, sem confusão de sinal.
3. E02 mostra dano 3, custo munição 1, carga ocupada 2 e −1 em seu próprio acerto; reserva não ativa efeitos.
4. G09 resolve combustível +2 e remove feedback; E07 mantém capacidade +3 sem gerar combustível.
5. R04/R07 expiram após próxima rolagem ou fim da corrida; R03/V10 resolvem só alternativa legal.
6. T01 preserva dano antigo; T04 afeta depósito, E08 carga, T05 limite de saque.
7. H04/H12 respeitam consumo por tentativa/acerto; H11 não cria queimadura.
8. Os 86 IDs têm mapeamento, todos os caminhos existem e os PNGs têm transparência externa.
9. Sem alterações nos cálculos do motor para acomodar a arte; sem ler o número do arquivo para resolver efeito.

## Prompt para o Codex local
“Leia contexto.md e manifest.json deste pacote. Integre os marcadores simples no jogo existente, respeitando as regras e o motor atual. Use os IDs de carta para mapear assets e diferencie feedback instantâneo, custos, efeitos passivos e efeitos ativáveis com frequência. Exiba tooltips acessíveis com origem e duração. Não execute a lista visual como regras. Preserve efeitos condicionais e alternativas, limites por instância e salvamento da partida. Valide os cenários de aceitação acima e informe os arquivos alterados.”
