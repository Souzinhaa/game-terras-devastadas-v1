# Terras Devastadas — regras de referência v0.5

## 1. Edição e precedência
Este texto consolida a camada operacional do GDD v0.4 com o rebalanceamento de 29/10/2026. Para novas partidas use rules.md, rules-cards.md, dados/cards.json e dados/rule-config.json deste pacote. Eles substituem os valores contraditórios dos documentos anteriores, das imagens antigas e dos contextos v0.1 de ícones. Não alterar partidas em andamento silenciosamente.

O conjunto é uma edição de teste para o protótipo digital. Números de combate, exploração, reparos e prêmios continuam parâmetros de teste. Os consumos, capacidades, terra e regras centrais preservadas são os já combinados. A resolução de vitória territorial e o setup mudam explicitamente nesta edição.

## 2. Objetivo e controle
Partida competitiva para 2–4 jogadores. Vença ao ser o último jogador não eliminado, ou sustentando cidades completas que somem 4 pontos até o início de seu próximo turno após anúncio.

Uma cidade completa exige controle simultâneo de todas suas sub-regiões. Cidades com 4 sub-regiões valem 1 ponto; as demais, 0,5. Sub-regiões isoladas não pontuam. Perder uma sub-região remove imediatamente os pontos e o bônus daquela cidade. Não há renda passiva territorial.

### Confirmação de vitória territorial — NOVO
Ao terminar seu próprio turno, após efeitos e descartes, se possui pelo menos 4 pontos e nenhum anúncio válido, registre anúncio de vitória. Os adversários jogam normalmente. Se em qualquer transação de regras concluída sua pontuação cair abaixo de 4 ou você for eliminado, cancele o anúncio; recuperar pontos posteriormente não restaura o anúncio antigo.

No início de seu próximo turno, expire primeiro os efeitos com essa janela, recalcule controle/pontos e, antes de comprar carta, confirme a vitória se o anúncio permaneceu válido e ainda possui pelo menos 4 pontos. Caso contrário, siga o turno. Novo anúncio somente ao fim de seu próprio turno. Não é necessário manter as mesmas cidades, desde que nunca caia abaixo de 4 após resolução integral de uma transação. A vitória por último sobrevivente continua imediata, sem anúncio. Se todos forem eliminados simultaneamente, não há vencedor.

## 3. Mapa e veículos
12 cidades, 35 sub-regiões, 8 pontos possíveis. Carros ocupam a cidade compartilhada, com espaço para até 4 jogadores; sub-regiões são alvos locais, sem custo de combustível entre elas. Estar na mesma cidade permite combate, sem iniciá-lo automaticamente.

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

| Veículo | Carga | Consumo por viagem | Tanque máximo | Combustível inicial NOVO | Terra |
|---|---:|---:|---:|---:|---|
| Hatch | 1 | 1 | 8 | 3 | Não |
| Sedã | 7 | 2 | 12 | 6 | Não |
| SUV | 6 | 2 | 12 | 6 | Sim |
| Caminhonete | 10 | 3 | 15 | 9 | Sim |

Consumo fixo e inteiro por ligação. Sem adicional por terreno ou carga. Combustível inicial corresponde a 3 viagens, não metade arredondada de cada tanque. Corridas, saque e cartas possuem custos próprios e podem reduzir essa autonomia. Nenhuma classe recebe acesso à terra por instalar equipamento deste catálogo.

Preservar o grafo atual: SP-330 Americana–Limeira–Cordeirópolis–Araras–Leme–Pirassununga; SP-310 Cordeirópolis–Santa Gertrudes–Rio Claro; SP-191 Conchal–Araras–Rio Claro; SP-147 Limeira–Piracicaba; SP-127 Rio Claro–Piracicaba; SP-304 Americana–Piracicaba; SP-332 Conchal–Artur Nogueira; ligação composta SP-147/SP-332 Limeira–Artur Nogueira; acessos de Santa Cruz da Conceição a Leme e Pirassununga. Rotas rurais alternativas Araras–Rio Claro e Araras–Artur Nogueira continuam ilustrativas, sem denominação oficial inventada. Esta edição não refez pesquisa rodoviária nem altera mapa/nomes.

## 4. Preparação — REVISADA
1. Sortear ordem, modelo de veículo e sub-regiões iniciais distintas; cidades diferentes enquanto houver possibilidade. Sorteio deve usar RNG serializado e não favorecer sistematicamente os primeiros.
2. Cada jogador controla uma sub-região inicial com defesa padrão íntegra; não recebe cidade completa de graça. Retire a ameaça dessa sub-região. Depósitos começam vazios.
3. Carro com Integridade máxima, combustível inicial da tabela, 1 sucata na carga, equipamento fixo do modelo e nenhum adicional instalado ou na reserva.
4. Entregar 1 carta geral aleatória por jogador, em vez de 2. Não criar carta de sobrevivência garantida ou baralho inicial separado.
5. A compra normal de 1 geral acontece também no primeiro turno próprio. Logo, antes da primeira ação o jogador normalmente tem 2 gerais, e não 3.
6. Restante do mapa segue distribuição de ameaças existente. Não inventar perfil completo de exploração ou novas penalidades por cidade.

## 5. Turno
1. Expirar efeitos e renovar contadores do turno próprio.
2. Verificar anúncio territorial e vitória antes da compra.
3. Comprar 1 geral; respeitar limites da mão.
4. Ações livres legais e cartas em suas janelas.
5. Opcionalmente viajar para uma cidade vizinha, pagando consumo e resolvendo evento.
6. Executar uma ação principal, se ainda disponível: explorar, conquistar, atacar carro, saquear ou administrar. Viajar não substitui essa ação; evento pode consumi-la.
7. Resolver encerramento, excedentes, recuperação e vitória por sobrevivência; registrar anúncio territorial se cabível; passar a vez.

Ações livres no turno próprio, fora de combate/corrida: depósitos próprios locais, abastecimento, instalação legal, recolher sucata local com carro operacional, uma compra de melhoria com sucata e um reparo simples. Administrar permite uma operação: reparo complexo/territorial, assumir carro ou instalação territorial remota. Instalar melhoria territorial local é livre; dois espaços por território. Não criar ação de suporte nova.

G17 é uma geral que também consome a ação principal. Só pode ser jogada se a cota de geral e a ação ainda estão disponíveis; custa 1 sucata. Pode viajar depois, mas não recebe outra ação na chegada. Se já agiu ou o evento consumiu a ação, não pode jogar G17.

## 6. Recursos e exploração
Recursos: combustível, sucata, munição, pneu, bateria e água. Sem consumo periódico de água/alimento, trocas ou doações diretas. Ajuda por carta continua permitida.

1 unidade transportada ocupa 1 carga, salvo combustível no tanque. Reserva de combustível na carga ocupa espaço. Depósito padrão 10 por sub-região. Acesso a todos os próprios depósitos da cidade atual é livre; não há acesso remoto comum. Ganhos respeitam limites e escolhas de excedente. Conquista transfere estoque existente, sem criar recurso. Descarte elimina recurso do jogo.

Explorar usa ação principal. Para o protótipo, 3 usos por sub-região, compartilhados, sem renovação automática; perfis regionais e composição detalhada continuam pendentes. Não usar esta edição para inventar taxas de achado. Recursos materiais sem ação implementada não ganham uso automático apenas por existir ícone.

## 7. Cartas, equipamentos e acúmulo
Uma geral por jogador por turno do mapa, inclusive turno de outro. Combate/corrida não resetam a cota. Dados só podem ser modificados antes de rolar. Prioridade começa no jogador da vez e segue a ordem. Cartas sem alvo legal não podem ser gastas voluntariamente; evento obrigatório sem alvo segue alternativa ou descarta sem efeito. Uma proibição só cede a exceção explícita.

Mão até 5 gerais, 3 equipamentos e reserva separada provisória de 3 territoriais. Instalados ficam no carro/território, fora da mão. Dois espaços adicionais por carro. Equipamento ocupa carga apenas se indicado. Retirar instalado descarta; fixo continua do modelo. Duas cópias de não únicas podem existir instaladas, respeitando limites compartilhados; ÚNICA impede instalar a segunda de mesmo ID no carro/território.

### Armas adicionais — NOVO
O carro pode executar no máximo 1 ataque concedido por equipamentos por rodada de combate, somando todas as armas adicionais instaladas. Escolha a arma no momento de atacar e pague o custo dela antes do dado. Erro consome munição e o limite daquela rodada. A arma fixa básica permanece separada. Ter duas armas oferece escolha de dano/alvo/custo, não dois disparos adicionais. O contador é por carro e rodada, não por carta nem por mudança de alvo. Não se renova na fase de resposta do mesmo carro na mesma rodada.

E04 Blindagem rebitada, E06 Mira estabilizada e E09 Kit de extração passam a ÚNICOS, além dos E07/E08/E10 já únicos. E06 ativa uma vez por combate, antes do dado, e não uma vez por rodada. Instalar outra cópia não pode renovar frequência dentro do mesmo combate; instalação em combate continua proibida. Não criar teto geral de bônus além das restrições expressas: G01 ainda pode combinar com E06, e G05 com E09 e agilidade.

Tanque/bagageiro não cobram manutenção e não geram recursos. Compra de melhoria por sucata: 3, uma vez por turno próprio; efeitos de carta não consomem essa compra. Preço permanece parâmetro de teste.

## 8. Bloqueios — REVISADOS
Bloqueio fecha ambos os sentidos até início do próximo turno da fonte. Só se aplica a estrada aberta, sem empilhar outra fonte enquanto fechada. Cada jogador mantém no máximo um bloqueio próprio ativo. G17 exige turno próprio, janela fora de combate/corrida, carta geral disponível, ação principal e 1 sucata na carga ou depósito próprio local. Validar tudo antes de gastar qualquer custo.

Não pode retirar a última saída compatível de nenhum carro presente. Contar bloqueios já ativos e permissões de terreno, sem exigir que o carro tenha combustível. Arestas paralelas são independentes: bloquear terra não bloqueia asfalto. Validar cada estrada por ID.

Remoção antecipada continua somente por carta: G18 remove uma fonte, sem ação ou sucata extra além da cota geral. Não implementar desobstrução por manutenção nesta edição. Expiração é automática; se fonte for eliminada, usar sua posição na ordem para expirar, sem bloqueio eterno. A regra de uma fonte por estrada vale para novos bloqueios; save antigo com múltiplas fontes mantém semântica antiga até seu próprio término.

## 9. Combate, conquista e fuga
Defesa é limiar no D6; Integridade é vida. Atacante age primeiro, sobreviventes respondem, fuga entre rodadas. Declarar alvo por ataque. 1 natural falha e 6 acerta, Defesa efetiva 2–6; sem crítico universal. Custo de arma é pago antes da rolagem. Não há acerto em área implícito.

Fortificação ataca uma vez por rodada mesmo sem proprietário. Dono operacional na cidade pode optar por defender antes do primeiro dado. Carro e fortificação possuem alvos e danos separados. Conquista exige eliminar fortificação e derrotar/expulsar carro participante. Novo dono recebe defesa padrão íntegra; melhorias antigas descartam, estoque existente transfere. Neutral derrotado descarta; se o jogador fugir, ameaça territorial mantém dano. Ameaça só cura por geral.

Fuga usa D6 + agilidade + modificadores, sucesso 5+. Exige rota e combustível para cidade vizinha compatível, sem novo evento nem nova ação. Contra jogador também exige uma carta na mão; vencedor escolhe 1 às cegas após mistura. Sem carta, sem fuga PvP. Erro continua combate sem ataque gratuito adicional. Contra ameaça não há tributo. E09 único elimina a fuga garantida por duplicação; o teste continua obrigatório.

Vencedor PvP rouba só 1 carta por combate, por inutilização OU fuga, antes de eventual descarte de equipamentos da mão. Instalados não podem ser roubados. Gerais/equipamentos não instalados elegíveis; reserva territorial elegível é parâmetro provisório sim. Respeitar limite da carta recebida.

Hostis H01–H12 preservam estatísticas e poderes do hostis.json. H04 bônus no primeiro ataque tentado, H07 em todos, H08 reduz fuga adversária, H11 dano +1 no 6 natural que acerta e H12 reduz primeiro acerto recebido. Sem novos poderes ou loot. Recuperar carro não conquista território; a ambiguidade de recompra de ameaça em território já pertencente a jogador permanece pendente, sem gerar defesa neutra extra automaticamente.

## 10. Saque
Ação principal + 1 combustível; escolher depósito alheio local. Atacante D6 contra defesa D6+1; empate defesa. Sucesso leva até 2 recursos, capacidades respeitadas; falha causa 2 danos. Qualquer tentativa ativa alerta compartilhado até início do próximo turno do saqueador. Não colocar cartas no depósito.

Se dono operacional local escolher defesa pessoal, combater somente carros: fortificação não participa. Saqueador vencedor leva até 2 recursos e resolve roubo PvP de 1 carta normalmente; derrota/fuga não leva recursos. Não aplicar dano de falha do teste simples além do combate. T05 reduz saque a no máximo 1 recurso, inclusive defesa pessoal. Saque não muda controle nem descarta melhorias.

## 11. Reparos, recuperação e eliminação
Zero Integridade inutiliza; não elimina automaticamente. Parâmetros de protótipo: reparo simples uma vez por turno próprio, 1 sucata por 1 Integridade, livre, sem reativar carro zero. Reparo complexo usa Administrar, 2 sucatas por 4 Integridade, podendo reativar; não exige oficina. Territorial usa Administrar, 1 sucata por 2 Integridade, até 2 sucatas por ação; T06 adiciona +1 uma vez à ação de reparo, não por sucata.

Emergência: pode explorar uma vez por ação enquanto houver usos locais, inclusive território alheio sem acessar depósito. Esgotados usos e alternativas, conceder um último turno com compra geral; se nenhuma solução executável, eliminar. Plano em etapas só continua com progresso real. São regras operacionais provisórias, sem garantir que G09 unitária salve sozinha SUV/caminhonete.

Inutilização descarta equipamentos na mão, mantendo instalados. Eliminado descarta tanque/carga/mãos/adicionais; territórios ficam abandonados com defesa/estoque, exigindo conquista. Eliminação por combustível pode deixar carro operacional vazio recuperável; perda por ameaça gera sucata local, por PvP entrega sucata ao vencedor respeitando carga. Quantidade gerada provisória 3.

Carro recuperado fica na cidade. Assumir carro disponível local usa Administrar; reparar antes se necessário. Antigo vira sucata e adicionais descartam. Transferir recursos/combustível dentro de capacidades; excedente para depósito próprio local ou descarte escolhido. Mão não instalada permanece na troca voluntária. Não gerar kit inicial em veículo encontrado.

## 12. Corridas
Eventos V12–V14 convocam pistas P01/P02/P03. Revelador deve entrar se apto e puder pagar; demais podem entrar de qualquer cidade. Custo da pista não é multiplicado pelo consumo do modelo. Sem combustível não entra e não sofre multa. Pista é tabuleiro neutro separado; ao final retorna à cidade anterior.

Avanço D6 por rodada; marcos geram surpresa uma vez por participante, inclusive avanço por carta. Recuo não renova marco. Modificadores expiram/consomem conforme texto. G21/G22 agora alteram avanço em 1, não em 2; E10 continua +2 uma vez por corrida e as surpresas conservam valores.

Sem desistência voluntária. Zero Integridade por carta retira participante para recuperação, sem eliminar automaticamente jogador. Completar a rodada de chegada; maior progresso vence, empate D6 sem cartas. Só primeiro ganha prêmio. Se todos ficarem inutilizados, encerrar sem prêmio. Com um único apto, não iniciar corrida: devolver inscrição e seguir evento sem prêmio. Rival neutro continua desativado.

| Pista | Distância | Marcos | Inscrição | Prêmio |
|---|---:|---|---:|---|
| P01 Araras–Limeira | 15 | 6/12 | 3 | 3 sucatas + 1 melhoria |
| P02 Araras–Piracicaba | 21 | 7/14 | 5 | 4 sucatas + 2 melhorias |
| P03 Rio Claro–Americana | 18 | 6/12 | 4 | 3 sucatas + 2 melhorias |

Ganhos respeitam capacidades e acesso a depósito próprio da cidade de retorno. Custos/prêmios permanecem valores de teste.

## 13. Atributos e pendências preservadas
Hatch: Integridade 6, Defesa 4+, agilidade +1; sedã 8/4+/0; SUV 10/3+/0; caminhonete 10/3+/0. Arma fixa genérica: dano 1 sem munição até conteúdo específico aprovado. Defesa territorial padrão 4/4+/dano 1. Bônus local de cidade completa: uma redução de dano 1 por turno do mapa dentro da cidade, mínimo zero, ainda parâmetro de teste; não é por rodada de combate nem renda.

Permanecem abertos: perfis e nomes de sub-regiões; baralho regional completo; quantidades de veículos; condições mecânicas sem especificação; impasse de combate sem dano; regra definitiva de recompra de ameaça em território de adversário. Não restaurar valores antigos incompatíveis. Sistema de condições sem regras deve permanecer desativado.

## 14. Persistência e interface
Guardar versões de regras/conteúdo, RNG, limites, fontes, anúncios e janelas. Regra de novos jogos é v0.5; não reabastecer, esvaziar tanque ou remover cartas/equipamentos de save antigo automaticamente. Ver contexto.md para migração.

Interface deve mostrar combustível inicial diferente do máximo, ataque adicional compartilhado usado/disponível, ÚNICA, E06 gasto no combate e anúncio territorial com prazo. Marcadores são apresentação; não calcular regra por OCR ou texto da imagem.
