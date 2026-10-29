# Regras do jogo: Terras Devastadas

Versão de referência: v0.4

Este documento resume as regras em vigor do protótipo local de Terras Devastadas, com base no GDD consolidado e no motor implementado. Ele serve como guia rápido para jogadores e para qualquer IA que precise entender o jogo sem ler o código inteiro.

## 1. Visão geral

Terras Devastadas é um jogo competitivo de tabuleiro digital para 2 a 4 jogadores em hot-seat local.

Cada jogador controla um carro, administra recursos, explora territórios, conquista sub-regiões, tenta controlar cidades e sobrevive às ameaças do ambiente e dos inimigos.

O jogo é jogado em turnos, em uma mesa compartilhada em um navegador, sem backend ou multiplayer online. O estado da partida é persistido localmente no navegador e a lógica é reproduzível por seed.

## 2. Objetivo

O objetivo principal é:

- controlar cidades inteiras que somem 4 pontos, ou
- sobreviver como último jogador restante.

Uma cidade pertence integralmente ao jogador que controla todas as suas sub-regiões ao mesmo tempo.

## 3. Mapa e cidades

O mapa possui:

- 12 cidades
- 35 sub-regiões
- 8 pontos possíveis no total

Cada cidade tem um número de setores e um valor de pontuação:

- 4 sub-regiões = 1 ponto
- 3 sub-regiões = 0,5 ponto
- 2 sub-regiões = 0,5 ponto

Uma cidade completa para um jogador significa que todas as suas sub-regiões estão sob o mesmo controle.

Se o jogador perder uma sub-região, perde o correspondente valor de ponto e bônus. Se recuperar o domínio completo, os pontos voltam.

## 4. Preparação da partida

Antes do primeiro turno:

- sorteia-se a ordem dos jogadores;
- sorteia-se o veículo de cada jogador;
- sorteia-se a cidade/território inicial de cada jogador;
- cada jogador recebe 2 cartas gerais;
- cada jogador começa com tanque cheio e 1 sucata;
- o restante do mapa começa com ameaça aleatória;
- os depósitos iniciais ficam vazios ou sem estoque relevante.

Todos os jogadores devem ter cidades iniciais diferentes quando possível.

## 5. Turno

A sequência do turno é:

1. Expirar efeitos ativos e renovar contadores por turno.
2. O jogador da vez compra 1 carta geral.
3. Executa ações livres legais.
4. Pode viajar para uma cidade vizinha, pagando combustível e resolvendo o evento da estrada.
5. Se o evento permitir, executa uma ação principal na cidade de chegada ou na cidade atual, se não viajou.
6. Resolve o fim do turno, limites, recuperação e vitória.
7. Passa a vez para o próximo jogador.

Importante:

- viajar não substitui a ação principal;
- a ação principal é obrigatória, salvo exceção por evento ou efeito de carta;
- um evento que interrompe a vez pode impedir a ação na chegada.

## 6. Ações principais

As ações principais incluem:

- explorar
- conquistar
- atacar carro
- saquear
- administrar

A ação de administrar pode incluir:

- reparo complexo
- reparo territorial
- troca de carro
- instalação territorial remota

A versão atual limita a ação administrativa a uma operação por vez.

## 7. Ações livres

Entre as ações livres, estão:

- instalar equipamentos
- acessar depósitos próprios da cidade atual
- abastecer
- instalar melhoria territorial local
- comprar melhoria com sucata uma vez por turno
- recolher sucata abandonada na cidade com carro operacional
- reparos simples

Reparos simples são livres, mas seu limite pode ser provisório e depender do equilíbrio atual do jogo.

## 8. Veículos

Os veículos disponíveis são:

- Hatch
- Sedan
- SUV
- Pickup

Cada modelo tem:

- capacidade de carga
- capacidade de tanque
- custo fixo por viagem
- permissão ou não de terreno
- equipamento fixo

A regra principal é que tanque e carga são separados:

- combustível no tanque não ocupa espaço de carga;
- combustível em reserva transportada ocupa carga;
- cada recurso geralmente ocupa 1 ponto de carga.

### Veículos confirmados

| Classe | Carga | Tanque | Custo fixo por viagem | Terra |
|---|---:|---:|---:|---|
| Hatch | 4 | 8 | 1 | Não |
| Sedã | 7 | 12 | 2 | Não |
| SUV | 6 | 12 | 2 | Sim |
| Caminhonete (`pickup`) | 10 | 15 | 3 | Sim |

## 9. Recursos

Os recursos implementados são:

- combustível
- sucata
- pneus
- bateria
- água
- munição

### Regras de recursos

- não há troca ou doação direta entre jogadores;
- auxílio por cartas pode acontecer;
- não há consumo obrigatório de água ou comida por turno;
- depósitos de sub-região possuem capacidade de 10 unidades;
- depósitos podem ser ampliados por melhoria;
- o jogador pode escolher o que guardar e descartar o excesso;
- recursos descartados saem do jogo;
- combustível pode abastecer o tanque respeitando a capacidade.

## 10. Exploração e conquista

Cada sub-região pode ser alvo de:

- exploração
- conquista
- assalto
- ocupação
- instalação de melhorias

Quando um jogador conquista uma sub-região, ela passa a estar sob seu controle, desde que a operação seja válida e haja regra de resolução.

Exploração e conquista estão ligadas ao controle do território, ao risco de combate e às condições de rota.

## 11. Territórios e controle

As cidades são formadas por sub-regiões. O controle pode ser entendido como dominância do setor pela presença e capacidade do jogador.

Uma cidade inteira vale pontos conforme o número de setores sob controle de um mesmo jogador.

### Resultado de controle

- menos de 4 sub-regiões = 0,5 ponto
- 4 ou mais sub-regiões = 1 ponto

Uma cidade completa também pode gerar bônus de vitória conforme o GDD.

## 12. Rotas, viagem e bloqueios

O mapa é conectado por rotas entre cidades.

### Regras de viagem

- o jogador pode viajar para uma cidade vizinha;
- viagem exige combustível e rota compatível;
- não há deslocamento livre por múltiplas sub-regiões no protótipo atual;
- o custo do deslocamento depende do veículo e do modelo;
- a viagem pode gerar evento de estrada.

### Bloqueios

Bloqueios:

- funcionam nos dois sentidos;
- duram até o início do próximo turno do jogador que usou a carta, salvo texto diferente;
- só podem ser removidos por carta;
- não existe pagamento de sucata para remover bloqueio;
- um bloqueio não pode deixar um carro presente sem saída compatível com o modelo;
- o terreno de rota e a compatibilidade do veículo são avaliados antes da aceitação do bloqueio.

## 13. Combate e hostis

O jogo inclui combate contra ameaças e contra outros carros.

### Combate contra hostis

- envolve dano, defesa, rolagem e eventuais efeitos de carta;
- ameaça vencida pode perder a “ameaça” ativa e recuperar sua defesa padrão;
- não é obrigatório atacar outro carro apenas por estar na mesma cidade;
- uma cidade ocupada ou uma rota ativa pode mudar as escolhas do jogador.

### Dano e integridade

- cada veículo tem integridade máxima;
- dano reduz integridade;
- carro inutilizado não é automaticamente eliminado;
- recuperação pode ocorrer na cidade de origem ou por meios específicos.

## 14. Cartas

Há tipos de carta em circulação:

- gerais
- equipamentos
- territoriais
- eventos
- corrida

### Cartas gerais

São usadas para efeito direto, como:

- dano
- reduzir dano
- roubo de recursos
- bônus de fuga
- bônus de ataque
- alteração de ameaça ou evento
- recursos imediatos

### Cartas de equipamento

Aumentam ou modificam capacidades do veículo ou da região.

### Cartas territoriais

Podem melhorar o território, reforçar defesa, ou gerar efeitos ligados ao controle de cidade/sub-região.

### Cartas de evento

Resolvem eventos aleatórios, como ameaças, surpresas e complicações.

## 15. Fuga e sobrevivência

A fuga é contemplada em certos momentos de combate ou de ameaça.

- somente pode ocorrer em certos contextos;
- exige rota e combustível compatíveis;
- pode depender de carta elegível;
- sucesso permite sair da cidade ou do confronto;
- falha não concede ataque extra nem cobrança adicional, salvo regras específicas do cenário.

## 16. Vitória e fim da partida

Uma partida é vencida quando:

- um jogador alcança a condição de pontos de cidades completas, ou
- resta apenas um jogador vivo/sobrevivente.

### Regras de vitória

- verificar vitória após resolver efeitos, mudança de controle e eliminação;
- empate ou eliminação simultânea pode terminar sem vencedor, conforme provisão do GDD.

## 17. Persistência e salvamento

O jogo salva automaticamente no navegador.

- exportação em JSON para cópia independente;
- importação de save com backup interno;
- saves em schema inválido são recusados;
- o motor preserva o estado antigo quando o save falha;
- a lógica do jogo depende de seed e do estado interno do objeto `Game`.

## 18. Regras operacionais importantes

Para qualquer modificação ou análise do jogo, vale o seguinte:

- a lógica do jogo fica no motor em `src/engine`;
- a interface é apenas camada de apresentação;
- a seed torna o resultado reproduzível;
- o código do jogo e o GDD devem permanecer coerentes;
- regras novas devem ser testadas e documentadas;
- o protótipo não é multiplayer online, backend ou serviço de autenticação.

## 19. Resumo rápido

Em poucas palavras:

- o jogo é uma disputa territorial em um mapa de cidades e sub-regiões;
- cada jogador controla um carro e deve sobreviver, explorar e conquistar;
- cada turno combina compra, viagem, ação principal e resolução final;
- o mapa, os recursos, as cartas, a integridade e a pontuação determinam o vencedor;
- a vitória vem da combinação de estratégia, logística e risco calculado.

## 20. Referências

- [README.md](README.md)
- [context.md](context.md)
- [docs/GDD_Terras_Devastadas_Codex_v04.md](docs/GDD_Terras_Devastadas_Codex_v04.md)
- [docs/ATUALIZACAO_V04.md](docs/ATUALIZACAO_V04.md)
