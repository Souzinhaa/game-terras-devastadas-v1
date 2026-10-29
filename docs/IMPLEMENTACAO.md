> HISTÓRICO v0.1 — valores substituídos pelo GDD v0.4. Consulte [ATUALIZACAO_V04.md](ATUALIZACAO_V04.md) para o estado atual.

# Protótipo local — registro de decisões

## Fonte e escopo

Leitura integral de `GDD_Jogo_Pos_Apocaliptico_Regiao_Araras_v01.docx`, seções 1–17. O arquivo `GDD_Terras_Devastadas_Codex.md` solicitado não existe neste checkout; o usuário autorizou usar o DOCX v0.1. O original e os assets foram preservados. Não havia código anterior, apenas README, DOCX e duas imagens.

O DOCX não enumera etapas de implementação. Neste protótipo, **etapa 1** significa fundação de dados/motor e **etapa 2**, tabuleiro/turnos hot-seat. Essa divisão é operacional, não uma atribuição ao documento ausente.

## Matriz de fidelidade

| Tema | Confirmado no DOCX | Implementação / pendência |
|---|---|---|
| Mapa | 12 cidades; grafo pavimentado; acesso rural para SUV | 12 cidades em JSON, conexões demonstrativas sem nomes de rodovias; um nó por cidade substitui temporariamente sub-regiões. Não representa geografia validada. |
| Ameaças | Ocupação inicial aleatória; conquistar exige presença e vitória | Ameaças sorteadas por seed; conquista inicia combate, posse só após resistência zero. Tipos e dificuldades são amostras. |
| Exploração | Conquista não concede recursos automaticamente | Exploração separada; loot nasce no depósito e recolhimento é outra ação. Baralhos regionais e probabilidades temáticas ainda abertos. |
| Veículos | Sorteio inicial, equipamento permanente específico, carga e consumo próprios | Sorteio entre três categorias; capacidade/consumo provisórios em `RuleConfig.vehicles`, importados de JSON. Equipamento inicial explicitamente a definir, sem bônus inventados. Descoberta/troca/sucateamento não implementados. |
| Recursos | Combustível genérico, sucata, pneu, bateria, água, munição; estoques físicos | Todos representados; depósito e carro distintos; água sem consumo passivo. Munição sem mecânica de armamento. |
| Viagem | Paga combustível e sempre gera evento | Custo auditável com fração, carga e categoria; eventos sorteados. Fórmula inteira **provisória**, não fecha distância, saltos ou arredondamento. |
| Integridade | Zero inutiliza, mas veículo recuperável; reparos livres e complexos | Integridade geral e reparos implementados. Sistemas individuais, falhas, peças específicas e custos finais ausentes. |
| Combate | Dados e equipamento; carro superior pode perder | Duelo experimental contra ameaça, sem PvP, equipamentos ou críticos. Dado, alvo, resistência e dano configuráveis. |
| Corrida | Somente por evento ou ponto específico | Minijogo por convite de viagem, com inscrição e resultado de dado. Sem participação remota, pista ou várias rodadas. |
| Turno | Uma ação principal no esqueleto; reparos simples livres | Uma ação configurável, encontros resolvidos antes de passar; administração local; reparo simples limitado provisoriamente. |
| Posse alheia | Perda de depósito; saque exato pendente | Invasão de jogador bloqueada: sem decidir destino dos itens ou perda de posse. “Saque” disponível é recolhimento local de descoberta, não roubo de outro jogador. |
| Vitória / morte | Pontos; fim com cidades conquistadas; sem eliminação definitiva | Sem placar/fim/respawn. Zero integridade não é modelado como morte do jogador. Sem regra inventada de reaparecimento. |

## Estado incremental

1. **Fundação implementada:** React, TypeScript, Vite; motor puro sem React, DOM, relógio ou aleatoriedade externa; RNG explícito; transições imutáveis; config e JSON.
2. **Hot-seat implementado:** 2–4 jogadores (limite de laboratório), nomes e cidades iniciais selecionáveis, passagem de turno, mapa com rotas, recursos, carga, custo, diário e erros. Sem sigilo de inventários.
3. **Combate parcial:** loop de dados, resistência, conquista, inutilização e reparo; nenhum combate entre jogadores.
4. **Exploração/saque parcial:** descoberta genérica única por nó, depósito e transferências locais; nenhum baralho regional ou saque de invasor.
5. **Corrida parcial:** convite, recusa, inscrição, rolagem, prêmio limitado à capacidade (excesso descartado, hipótese de laboratório) ou dano. Não é um motor de corrida completo.

## Backlog de decisões — ABERTO

Nada nesta lista foi aprovado por implementar um experimento. Alternativas para avaliação futura:

| Ordem | Decisão | Alternativas e impacto | Recomendação para validar |
|---|---|---|---|
| 1 | Sub-regiões e rotas | Poucas casas facilitam leitura; muitas aumentam disputa e duração | Começar com poucas casas por cidade, em proporções diferentes, depois validar rodovias. Não codificado como regra. |
| 2 | Combustível | Meio marcador por deslocamento facilita previsão; crédito de duas viagens evita frações; custo não linear aumenta risco de saltos | Crédito de duas viagens, a validar com distância/carga. Laboratório usa frações para permitir inspeção. |
| 3 | Combate | Ataque contra alvo fixo é rápido; dados opostos ampliam variação; cartas táticas aumentam escolhas | Testar alvo fixo primeiro, depois equipamentos; valores atuais não balanceados. |
| 4 | Exploração | Baralhos regionais separados reforçam identidade; baralho comum ponderado reduz manutenção | Baralho comum ponderado por região, após definir recursos locais. |
| 5 | Reparo | Limite por turno reduz abuso; limite por peça detalha sistemas | Um reparo simples por turno para experimentar; custo e reparabilidade precisam decisão. |
| 6 | Corrida | Resultado único encurta interrupção; pista de várias rodadas aumenta tática | Resolver evento curto antes de projetar corrida global. |
| 7 | Fim e morte | Conquistadas alguma vez acelera fim; controle simultâneo estende disputa. Respawn fixo é previsível; escolha livre amplia recuperação | Validar fim por histórico e respawn escolhido antes de qualquer implementação. |

Ainda dependem de decisão: equipamentos e slots, habilidades após troca, raridade/dificuldade, PvP, perda de território/estoque, pontuação e desempate. Não há autenticação, nuvem, multiplayer, bots, persistência ou vitória automática.

## Validação e arquitetura

`src/engine/game.ts`: `createGame`, `transition`, `travelCost`, `assertInvariants`. Uma ação inválida lança erro sem alterar o estado anterior. O RNG avança somente na cópia da transição; mesma seed/config/ações produz os mesmos resultados. Seed no diário é estado atual do gerador; seed inicial é a informada no setup.

`src/engine/config.ts`: números e perfis experimentais. `experimental: false` bloqueia criação: não existe um conjunto final de regras. Dados JSON são amostras do laboratório, não fontes geográficas.

Os testes cobrem determinismo, imutabilidade, configuração, terreno, combustível, ação/turno, encontro pendente, conquista sem loot, exploração, capacidade, conservação de estoque, reparos, corrida condicionada e sequências de combate em 50 seeds. Eles verificam consistência técnica, não equilíbrio nem diversão.

Arte existente utilizada somente como background CSS. Nenhuma regra ou geometria é extraída da imagem; botões e conexões derivam dos JSON. O asset `hatch-cima.png` foi preservado sem uso, pois usar a miniatura contrariaria o pedido de arte apenas como fundo.

Limitações de interface: não houve inspeção visual automatizada em navegador; build e testes do motor não comprovam usabilidade. Mudanças de configuração são feitas no código antes de iniciar; recarregar perde a partida. O mapa não oferece editor de sub-regiões.

Validação executada: `npm.cmd test` — 11 testes aprovados no Vitest 5.0.5; `npm.cmd run build` — TypeScript e bundle Vite aprovados. A instalação após atualização do Vitest reportou zero vulnerabilidades. Nenhum teste de balanceamento foi realizado.

Smoke do servidor: Vite iniciado em `127.0.0.1:5173`; HTML e módulo `src/main.tsx` responderam HTTP 200. Neste ambiente, a otimização de dependências precisou executar fora do sandbox devido à leitura negada em diretórios ancestrais; isso não exigiu mudança de permissões no projeto. Não equivale a teste de interação em navegador.
