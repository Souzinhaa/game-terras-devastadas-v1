# Terras Devastadas — regras Godot 0.7

Contrato das **novas partidas Godot/Android**, atualizado em 31/10/2026. Perfil `campaign-v07`, regras `0.7`, conteúdo `0.7.0`; build de teste `0.0.4-ui-tv`.

Guia prático: [Como jogar](docs/COMO_JOGAR.md). Cartas: [rules-cards.md](rules-cards.md). Diferenças e compatibilidade: [REBALANCEAMENTO_V07.md](godot/docs/REBALANCEAMENTO_V07.md). O motor React continua em sua edição 0.6. Saves nativos antigos não são convertidos ao carregar; ver seção 14.

## 1. Objetivo

Jogo competitivo para 2–4 jogadores. Há duas formas de vencer:

- Ser o último jogador não eliminado: vitória imediata.
- Controlar cidades completas somando **pelo menos 3 pontos**, anunciar ao encerrar seu turno e manter uma pontuação válida até o próximo início próprio.

Uma cidade completa exige todos os seus setores. Cidades com quatro setores valem um ponto; as demais, meio ponto. Setores isolados não pontuam. Perder um setor remove imediatamente os pontos e o bônus da cidade. Não há renda territorial passiva.

O anúncio nasce ao encerrar o próprio turno, após resolver pendências. Pontuação abaixo de três, destruição ou indisponibilidade operacional cancelam o anúncio. Recuperar pontos não restaura um anúncio cancelado: é preciso anunciar de novo ao fim do próprio turno. Não precisa manter as mesmas cidades, desde que o anúncio permaneça válido.

No próximo início próprio, expire efeitos, recalcule controle e confirme o anúncio **antes da compra**. Se não houver vitória, siga o turno. Eliminação simultânea de todos encerra sem vencedor.

## 2. Mapa e preparação

Há 12 cidades, 35 setores, 19 rotas e oito pontos territoriais possíveis.

| Cidade | Setores | Pontos da cidade completa |
| --- | ---: | ---: |
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

A ordem e os setores iniciais são sorteados com a seed da partida, priorizando cidades iniciais distintas. Cada jogador recebe um setor próprio íntegro, depósito vazio e um **Hatch** com integridade 6, três combustíveis no tanque, uma sucata na carga, uma geral e duas vidas. Não recebe cidade completa, equipamentos adicionais ou kit de modelo superior.

A geral inicial precisa ser revelada pelo dono. A compra normal de uma geral ocorre também no primeiro turno próprio. Seed e decisões tornam a partida reproduzível no mesmo motor/edição, sem prometer sequência igual ao React.

Nos setores neutros da edição 0.7, o primeiro setor neutro ordenado de cada cidade tem faixa fácil; os demais, média; o último de uma cidade de quatro setores tem faixa difícil. Um dos quatro hostis da faixa é atribuído deterministicamente pela seed/setor. A faixa de risco é pública; identidade e atributos permanecem ocultos até a descoberta. Retomar não rerrola ameaças.

## 3. Veículos

Valores básicos, antes de cartas:

| Modelo | Integridade máxima | Defesa | Dano fixo | Agilidade de fuga | Carga | Tanque | Consumo por rota | Terra |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Hatch | 6 | 4+ | 1 | +1 | 4 | 8 | 1 | Não |
| Moto | 6 | 4+ | 2 | +1 | 2 | 10 | 1 | Sim |
| Sedã | 8 | 4+ | 1 | 0 | 7 | 12 | 2 | Não |
| SUV | 10 | 4+ | 1 | 0 | 6 | 12 | 2 | Sim |
| Caminhonete | 10 | 4+ | 1 | 0 | 10 | 15 | 3 | Sim |

Defesa é o limiar de acerto do atacante: número maior dificulta acertar. Dano fixo não consome munição. Equipamentos da Moto não ocupam carga, mas continuam sujeitos aos dois espaços adicionais, custos e limites de uso. Sair da Moto restaura o peso aplicável.

Melhorar um Hatch para outro modelo custa **cinco sucatas próprias locais e uma ação principal**. Pode somar carga e depósitos próprios da cidade, pagando primeiro a carga. Preserva combustível, integridade atual, mão, recursos, equipamentos e vidas. **Moto não recebe dez combustíveis na edição 0.7.** Tanque maior não cria combustível, integridade máxima maior não cura e melhorar não renova vidas.

Não há melhoria direta entre modelos superiores. Veículo encontrado de save/oferta existente segue os custos e escolhas próprios de assumir/reparar; V16 não cria novas ofertas nesta edição. Captura PvP possui regra distinta na seção 9.

## 4. Turno e viagem

1. Iniciar: expirar efeitos, renovar contadores próprios e verificar anúncio territorial.
2. Comprar uma geral, revelar cartas recebidas e resolver excesso.
3. Executar ações livres e cartas em suas janelas.
4. Opcionalmente viajar **uma vez**, antes da ação principal, para cidade adjacente.
5. Resolver o evento de viagem; ele pode consumir a ação ou abrir encontro.
6. Executar a ação principal disponível: explorar, conquistar, duelar, saquear ou administrar uma operação com custo de ação.
7. Resolver escolhas/excedentes, encerrar, registrar anúncio elegível e passar a vez.

Viajar paga o consumo inteiro do modelo pelo trecho, sem adicional automático por terreno/carga. Exige rota aberta, piso compatível e combustível no tanque. O carro chega antes de resolver o evento. Rotas alternativas são escolhas distintas; use as conexões de `godot/data/routes.json`. Carros compartilham a cidade; estar junto não inicia duelo automaticamente.

G17 é exceção explícita: consome sucata, carta/cota e ação principal antes de viajar, mas permite a viagem posterior sem ganhar outra ação. Não bloqueia estrada já fechada nem a última saída compatível de carro presente; G18 remove bloqueio. O bloqueio expira no próximo início de quem o criou.

Ações livres não substituem os próprios custos/limites. Não concedem ação principal extra. Resolver um encontro ou excedente tem prioridade sobre prosseguir normalmente.

## 5. Recursos, exploração e depósitos

Recursos: combustível, sucata, munição, pneu, bateria e água. Cada unidade na carga ocupa um espaço; combustível no tanque não ocupa carga. Não há consumo periódico de água/alimento ou doação direta de recursos.

Explorar exige setor próprio na cidade atual e uma ação. Há **três usos por setor**, compartilhados entre donos ao longo da partida, sem renovação automática. Gera **2–3 recursos no depósito**: uma unidade garantida de **sucata ou combustível**, escolhida antes, e as demais 1–2 sorteadas entre os seis tipos. Não é um bônus além do total.

O resultado mostra somente o ganho da exploração; recursos anteriores continuam no depósito. Abrir/fechar resultado ou depósito não concede novamente os itens.

Depósito básico comporta dez recursos por setor, ampliável por T04. No turno próprio, transferir carga ↔ depósito próprio da cidade atual e depósito → tanque é livre quando legal. Sem acesso remoto comum. O combustível achado/ganho na carga precisa ser abastecido para virar autonomia de viagem.

**Troca de suprimentos:** fora de encontros, uma vez por turno próprio iniciado, transformar **uma água, pneu ou bateria da carga em uma sucata**, sem ação principal. A troca conserva o tamanho da carga; não vale diretamente para recurso no depósito. Não repõe a cota de geral ou de reparo.

Limites nunca apagam ganhos automaticamente. Resolver excesso por opções legais de abastecer, armazenar ou descartar; os botões disponíveis dependem da janela. Excesso de cartas por tipo, tanque, carga ou depósito bloqueia a continuação normal até ser resolvido.

## 6. Reparos, compra e instalação

- Reparo simples: uma sucata da carga por uma integridade, livre, uma vez por turno próprio.
- Reparo complexo: duas sucatas da carga e uma ação para recuperar até quatro integridades, limitado pelo máximo.
- Ambos exigem veículo de jogador com integridade positiva; zero consome uma vida.
- Comprar melhoria com sucata: três sucatas **na carga**, uma compra por turno; não consome ação principal. G15 não usa essa cota de compra.
- Instalar equipamento em espaço disponível é livre, sujeito à carga e às restrições.
- Territorial próprio local: instalação livre; territorial remoto: consome ação principal.
- Dois espaços adicionais no veículo e dois por setor. ÚNICA impede duas cópias do mesmo ID no mesmo carro/setor.
- Retirar instalado descarta a carta. T06 permite substituição conforme seu efeito. Retirar capacidade pode exigir resolver excesso.

Melhorias territoriais alteram a fortificação/depósito. Reparo de território próprio danificado custa uma sucata da carga e uma ação, recuperando até duas resistências, mais uma com T06, até seu máximo. Veículo encontrado segue custos e janelas próprios mostrados na administração. Não há oficina ou requisito novo implícito.

## 7. Cartas e revelação

Limites na mão/reserva: cinco gerais, três equipamentos e três territoriais. Instalados ficam fora desses limites. Gerais usam a cota de **uma por jogador por turno do mapa**, inclusive durante a vez de outra pessoa. Combate e corrida não renovam essa cota.

Reações entram antes do dado; não há reação retroativa. A ordem começa no jogador ativo e segue a ordem circular. Carta sem alvo legal não pode ser gasta voluntariamente. Evento/surpresa obrigatório segue sua alternativa ou resolve sem efeito quando não houver alvo.

Aquisição gera revelação pendente do dono, inclusive tributo/recompensa fora do turno. Tocar para ampliar não usa a carta; somente confirmar o uso consome. Identificação privada precede a mão no hot-seat; na LAN cada pessoa usa seu aparelho.

O registro contém **74 definições/148 identidades**. No setup 0.7, **E11 Guincho manual e V16 Veículo abandonado** não entram nos baralhos: quatro cópias ficam indisponíveis, restando 72 definições/144 cópias disponíveis. Saves antigos conservam suas cartas. Conteúdo detalhado e composição ativa: [catálogo](rules-cards.md).

## 8. Combate, conquista e fuga

Ataques alternam entre os lados. Antes do dado, resolver reações e equipamentos opcionais. D6: **1 natural sempre erra e 6 natural sempre acerta**; nos demais, somar modificadores e comparar com a defesa. Acerto aplica dano e reduções legais, mínimo zero.

Cada veículo tem a arma fixa e pode escolher **um ataque adicional de equipamento por rodada**, compartilhado entre E01/E02/E03. Munição e limite são gastos antes do dado, mesmo em erro. Ter duas armas oferece escolha, não dois adicionais. E03 atinge carro, não hostil/fortificação. E05/E06/E12 são declarados antes do dado; seus usos/descartes são por instância e janela.

Conquistar exige resolver o defensor. Dono operacional presente pode escolher carro; se esse carro for derrotado ou fugir, a mesma ação prossegue contra a fortificação. Não são três ataques simultâneos: o motor resolve os confrontos em sequência. Saque com defesa pessoal é uma exceção, somente carros, seção 10.

A fortificação básica tem integridade quatro, Defesa 4+ e dano um, com efeitos T01/T02/T03 quando instalados. Conquista descarta melhorias do dono anterior, restaura resistência padrão e conserva depósito e usos de exploração. A cidade completa concede uma redução de dano um elegível por turno do mapa dentro dela, compartilhada entre seu carro/fortificação; não é renda nem benefício por rodada.

Hostis H01–H12 usam os atributos/poderes do JSON. H04 beneficia o primeiro ataque tentado; H07 tem bônus contínuo; H08 modifica fuga; H11 acrescenta dano no seis que acerta; H12 reduz o primeiro acerto recebido. Fácil recompensa 2–3 itens, médio 3–4, difícil 4–5: cada item sorteia sucata/combustível para a carga. Não abastece automaticamente. Fuga preserva o dano da ameaça; só efeito explícito cura.

Fuga ocorre entre rodadas: D6 + agilidade + modificadores, sucesso a partir de cinco. Exige rota adjacente aberta, piso e combustível; paga consumo ao conseguir escapar, sem evento de viagem nem outra ação. Contra jogador exige uma carta na mão, transferida aleatoriamente ao adversário no sucesso. Falha continua o combate sem ataque adicional gratuito.

### Avançar até a próxima decisão

O botão é voluntário. Executa até 24 transições de ataques/continuações sem decisão opcional disponível, mantendo os mesmos dados/regras do modo manual. Para diante de reação, equipamento ativável, munição opcional, fuga legal ou resultado final. Não confirma carta, veículo, descarte ou recompensa.

Cada pessoa pode optar por **Passar nas próximas rolagens deste combate** e **Voltar a reagir** antes do dado. Passar não usa carta nem a cota de geral. A preferência dura aquele combate, é salva e, na LAN, só pode ser alterada pelo próprio dono.

## 9. Vitória PvP e duas vidas

Destruir carro de outro jogador entrega ao vencedor real os recursos da carga, combustível do tanque e uma carta aleatória da mão, antes de descartar o restante. Instalados não são transferidos. A carta usa revelação privada do vencedor.

Se o derrotado tinha modelo superior diferente do vencedor, pode oferecer captura por **duas sucatas**, estrutura quatro. Aceitar descarta os instalados do veículo substituído; combustível do tanque anterior vai à carga, tanque capturado é conservado até o limite, e o excedente vai à carga. Recusar mantém o modelo e os recursos recebidos. Não confundir essa escolha com melhoria de Hatch por cinco sucatas.

Primeira destruição por combate/evento/saque/surpresa consome uma vida. Depois de resolver a entrega PvP aplicável, descartar o restante de mão, instalados, carga e tanque. Renascer na mesma cidade de Hatch íntegro, três combustíveis e sem itens/cartas; preservar territórios e depósitos e cancelar anúncio territorial.

**Não perde o próximo turno próprio na edição 0.7.** O carro fica protegido/indisponível para combate e participação até iniciar essa próxima vez; o turno de renascimento, se era o ativo, fica sem ação/viagem restante. A proteção do carro não protege seus depósitos/setores contra conquista ou saque. Corrida já iniciada não readmite o renascido.

Segunda destruição elimina. Abandonar setores preservando integridade/melhorias/estoque; remover bloqueios do eliminado e ignorar seus turnos. Melhorar/trocar não renova vidas. Não há eliminação automática por tanque vazio.

## 10. Saque

Uma ação principal e um combustível do tanque; depósito alheio local com recursos. Se o dono operacional está presente, pode defender com o carro. Essa defesa substitui o teste simples, sem enfrentar fortificação nem causar também o dano de falha do teste.

Teste simples: atacante **D6 contra D6 da defesa**, com modificadores G19/G20 quando usados antes. Empate favorece a defesa. Sucesso permite escolher até dois recursos, ou um com T05; falha causa dois danos. Não transfere controle, cartas do depósito ou melhorias.

Na defesa pessoal, vitória do saqueador permite até dois recursos do depósito (T05 limita a um), além das consequências PvP aplicáveis. Derrota/fuga não leva itens do depósito. Ganhos continuam sujeitos à capacidade.

A tentativa registra alerta até o próximo início do saqueador. Não há proibição extra implementada para esse alerta; não inventar bloqueio, taxa ou dano adicional.

## 11. Eventos e corridas

Viajar abre evento de deslocamento, resolvido antes de continuar a ação. V12/V13/V14 convocam P01/P02/P03. **Todos podem recusar a inscrição, inclusive o revelador**. Jogadores aptos podem participar de outras cidades. Inscrição custa um combustível, sem multiplicar pelo consumo do veículo.

Exige pelo menos dois inscritos aptos. Se não houver, devolver inscrição, cancelar e não dar prêmio. A prova é separada do mapa; termina com retorno à cidade anterior. Depois de entrar não há desistência voluntária.

| Pista | Distância | Marcos | Inscrição | Prêmio do primeiro |
| --- | ---: | --- | ---: | --- |
| P01 Araras–Limeira | 15 | 6/12 | 1 | 3 sucatas + 1 melhoria |
| P02 Araras–Piracicaba | 21 | 7/14 | 1 | 4 sucatas + 2 melhorias |
| P03 Rio Claro–Americana | 18 | 6/12 | 1 | 3 sucatas + 2 melhorias |

Avanço D6 por rodada. Cada marco revela uma surpresa por participante, inclusive se cruzado por carta; recuar não renova marco. G21/G22 alteram avanço em um; E10 em dois uma vez por corrida. Completar a rodada de chegada e comparar progresso; empate usa D6 sem cartas. Só o primeiro recebe prêmio, com escolhas de excedente. Se todos saírem por destruição, encerrar sem prêmio. Rival neutro desativado.

## 12. Android e LAN

No hot-seat, entregar o aparelho e identificar o dono antes de abrir cartas. Na LAN, um celular hospeda e cada pessoa mantém seu aparelho. Mesma rede e build compatível; Tabuleiro/TV público é opcional. Não compartilhar mão privada na TV.

Somente o anfitrião executa regras e RNG. Ações de outros jogadores aparecem em suas janelas; ficar fora do turno não significa que nunca há reação. Recibos/reconexão não devem repetir ação, compra ou recompensa. Não há migração automática de anfitrião: mantê-lo ativo.

Painéis e leitores respeitam área segura, rolagem e Voltar contextual. Ajuda está em **Como jogar** no menu local e no menu da LAN. Pausar não confirma carta ou perde uma compra pendente.

## 13. Limites da edição

E11 aguarda fonte definida de sucata solta; V16 permanece desativado. Não reativar automaticamente em save antigo. Perfis regionais detalhados além da escolha atual, condições mecânicas sem contrato, resolução especial de impasse sem dano, exploração renovável e regras extras de alerta continuam sem definição. Não acrescentar efeitos só por haver arte/ícone.

Testes automáticos e APK exportado comprovam os cenários testados. Não demonstram diversão, duração, equilíbrio competitivo ou funcionamento físico em todos os aparelhos; esses pontos exigem playtests.

## 14. Edição, saves e histórico

| Aspecto | Nova partida Godot 0.7 | Save nativo campaign-v06 |
| --- | --- | --- |
| Pontos territoriais | 3 | 4 |
| Exploração | Uma unidade escolhida dentro de 2–3 | Todas as 2–3 sorteadas |
| Troca de suprimentos | Uma vez por turno próprio | Indisponível |
| Moto na melhoria | Preserva combustível | Recebe dez |
| SUV/Caminhonete | Defesa 4+ | Defesa 3+ |
| Primeira destruição | Proteção até próximo início, sem perder a vez | Penalidade de próximo turno perdido |
| Saque simples | D6 × D6 | D6 × (D6+1) |
| Revelador da corrida | Inscrição opcional | Entra quando apto e com combustível |
| E11/V16 | Fora dos novos baralhos | Cópias antigas preservadas |

Carregar preserva perfil, conteúdo, RNG, identidades e escolhas. O controle de combate rápido não troca a edição. Replays usam o perfil registrado. Perfil `stage1` conserva seu conjunto legado limitado, sem ligar campanha por inferência. React usa outro formato e suas regras 0.6; não importar/converter silenciosamente.

[Snapshot anterior de regras](docs/historico/REGRAS_REFERENCIA_V06.md), [contexto React anterior](docs/historico/CONTEXTO_REACT_V06.md) e [decisões v0.6](docs/REGRAS_V06.md) são registros históricos. Este documento e os contratos 0.7 prevalecem para novas partidas Godot.
