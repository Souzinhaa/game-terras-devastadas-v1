# Regras v0.6 — Hatch, progressão e duas vidas

Estas regras substituem o início com modelo sorteado e a recuperação de carro destruído das versões anteriores. A mudança de regras exige uma nova partida: conteúdo 0.6.0, envelope schema 4. Não converter saves anteriores nem inventar vidas restantes para eles.

## Conflitos resolvidos

| Regra anterior / conflito | Correção adotada |
|---|---|
| Hatch tem carga 4 e melhoria custa 5 sucatas | Somar sucata da carga e dos depósitos próprios na cidade atual. Consumir primeiro a carga, depois depósitos. Sem pagamento remoto. |
| Zero de integridade permitia reparo e exploração para recuperação | Zero agora destrói o carro e consome uma vida. Reparos só recuperam carros de jogador com integridade positiva. Reparar carro encontrado continua permitido antes de assumi-lo. |
| Carros encontrados permitiriam evitar o custo de progressão | Assumir sedã, SUV, caminhonete ou Moto encontrados também custa 5 sucatas locais e uma ação. Não gera sucata pelo carro substituído. |
| Roubo ao destruir carro contradiz a perda de todas as cartas | Morte descarta todas as cartas e itens transportados; não há roubo por destruição. O tributo de uma carta pela fuga PvP permanece. |
| Melhorar o carro poderia curar ou renovar vidas | Melhoria do Hatch preserva integridade atual, combustível, equipamentos, condições, recursos, mão e contador de vidas. Não renova vidas nem cura. Moto é a exceção confirmada de combustível: recebe tanque cheio (10) na melhoria. |
| Renascer sem combustível poderia deixar o jogador sem opção | Hatch renasce íntegro, com 3 combustíveis no tanque e carga vazia. Regra confirmada pelo usuário. |
| Penalidade poderia permitir compras ou ataques imediatos ao renascido | Próximo turno próprio inteiro sem compra, viagem, ações ou cartas. Proteção contra ataques/efeitos enquanto a penalidade estiver pendente ou em curso. Depósitos não ficam protegidos contra conquista/saque. |

## Preparação e progressão

Todos começam de Hatch: carga 4, tanque máximo 8, consumo 1, integridade máxima 6, defesa 4+, agilidade +1, apenas asfalto. Kit inicial: 3 combustíveis no tanque, 1 sucata, equipamento fixo e 1 geral. A compra normal ocorre no primeiro turno próprio.

Em Administrar, um Hatch operacional pode melhorar para sedã, SUV, caminhonete ou Moto por 5 sucatas próprias locais e uma ação principal. Não exige oficina, viagem ou carta. A melhoria não é ação livre. O jogador pode ter viajado antes de melhorar, como nas demais ações principais. Não se troca diretamente entre modelos superiores pela ação de melhoria.

Sedã: carga 7/tanque 12/consumo 2/vida máxima 8; SUV: 6/12/2/10; caminhonete: 10/15/3/10. Moto, SUV e caminhonete usam terra. Tanque maior não acrescenta combustível, exceto a melhoria para Moto (10 combustíveis confirmados). A integridade atual é preservada, sem cura gratuita. A melhoria não entrega o antigo combustível inicial 6/6/9.

Carro encontrado deve ser operacional e local. Consertar um encontrado e assumi-lo continuam exigindo ações em turnos distintos. Assumi-lo cobra 5 sucatas e uma ação, transfere combustível disponível, preserva carga e mão e descarta adicionais do carro substituído, respeitando os excedentes. Não gera sucata pelo carro substituído. Um Hatch encontrado não é melhoria.

## Primeira destruição

Qualquer dano que leve o carro a zero — PvP, hostil, evento, surpresa de corrida ou falha de saque — consome a primeira vida. O combate acaba se envolvia esse carro. Em corrida, o participante sai da prova atual e não volta com o carro renascido; os demais continuam.

Descartar todas as cartas da mão, equipamentos adicionais instalados, carga e combustível do carro perdido. Não transferir esses itens ao atacante. O jogador recebe outro Hatch íntegro, com equipamento fixo padrão, 3 combustíveis no tanque, sem cartas, carga ou adicionais. Permanece na mesma cidade. Territórios, suas melhorias e depósitos são preservados. O anúncio de vitória territorial é cancelado.

Se era seu turno, a ação e a viagem restantes ficam indisponíveis; isso não quita a penalidade. Seu próximo turno próprio inteiro é perdido, sem comprar carta nem executar ações. O turno precisa ser iniciado e encerrado para consumir a penalidade; depois disso a proteção termina. Ele não participa de novas corridas durante a recuperação. Cartas de outros jogadores não podem escolher um jogador em recuperação.

## Segunda destruição

A próxima destruição, mesmo após nova melhoria ou troca de carro, elimina definitivamente. Não existe um terceiro renascimento. Descartar novamente todas as cartas, equipamentos e recursos transportados. Abandonar territórios preservando integridade, melhorias territoriais e depósitos; conquistar continua necessário. Remover bloqueios do eliminado para evitar bloqueios eternos. Ignorar sua posição na ordem dos turnos.

Vitória imediata por último sobrevivente; se todos morrerem na mesma resolução, partida encerrada sem vencedor. A vitória territorial por anúncio e sustentação de 4 pontos permanece, mas um anúncio é cancelado pela morte.

## Regras recentes preservadas

- Explorar: uma ação, 3 usos por setor, 2–3 recursos sorteados individualmente, no depósito.
- Hostil fácil: 2–3 recursos; médio: 3–4; difícil: 4–5. Cada item sorteia sucata ou combustível com igual chance. Ganho fica na carga/reserva; não abastece automaticamente.
- Corridas: inscrição de 1 combustível em todas as pistas. Prêmios existentes preservados.
- Dado animado antes do resultado e passagem de vez; combate PvP mostra carros, vida, impacto ou esquiva. Animação respeita movimento reduzido.
- Seed inicial aleatória por padrão, entrada manual opcional e valor inicial visível/salvo.

## Validação de balanceamento

O sistema é coerente com o objetivo de dar uma segunda chance e tornar sucata uma decisão entre reparar, comprar cartas e melhorar o veículo. Isso ainda não prova equilíbrio. Observar em partidas reais: tempo até a primeira melhoria, dificuldade de reunir cinco sucatas locais, mortes antes da primeira melhoria, capacidade de reconstrução após renascer e pressão sofrida após a proteção acabar. Se a eliminação ocorrer sem oportunidade de reconstrução, revisar a janela de proteção antes de aumentar kits ou criar novas vidas.

## Complemento da Moto
Moto usa `assets/moto-cima.png`, carga 2, consumo 1, tanque 10, terra permitida, integridade máxima 6, defesa 4+, agilidade +1. Melhorar o Hatch para Moto custa 5 sucatas locais e uma ação e entrega tanque cheio com 10. Vida atual e contador de vidas são preservados. Moto encontrada continua sem kit; ao assumi-la, transfere combustível disponível sem completar tanque. Todos continuam começando e renascendo de Hatch.
