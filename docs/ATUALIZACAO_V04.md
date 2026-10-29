# Atualização para GDD v0.4

Fonte: leitura integral das seções 1–19 de `GDD_Terras_Devastadas_Codex_v04.md`. O DOCX v0.1 e o registro anterior foram preservados como histórico, mas não definem mais os valores ativos. Nenhum asset ou GDD do usuário foi substituído.

## Inspeção inicial e evolução

O checkout tinha React/TypeScript/Vite, motor puro, JSON, testes e um tabuleiro hot-seat da primeira entrega. Não havia persistência, troca, fuga ou bloqueios; o domínio antigo usava um território por cidade, três classes, combustível fracionário e carga incluindo tanque. Esses pontos foram atualizados nas mesmas camadas existentes, sem criar uma segunda fonte de regras.

- `src/data/vehicles.json`: conteúdo confirmado, IDs estáveis `hatch`, `sedan`, `suv`, `pickup`, carga/tanque/consumo 1/8/1, 7/12/2, 6/12/2, 10/15/3, dois slots e permissões `allowedSurfaces`.
- `src/data/cities.json`: quantidades confirmadas; 35 setores gerados com IDs cidade-número, rótulos provisórios “Setor N”.
- `src/data/routes.json`: 16 ligações asfaltadas do GDD e duas de terra ilustrativas. IDs distintos para asfalto/terra Araras–Rio Claro. Sem conexões descartadas. Acesso de Santa Cruz sem nome inventado.
- `src/engine/config.ts`: apenas parâmetros provisórios, incluindo fichas de combate, reparo, usos de exploração, dificuldade de fuga, sucata da troca e seleção de cartas territoriais no roubo.
- `src/engine/game.ts`: mesmo motor puro/determinístico, agora com entidades de veículo, tanque separado, cartas únicas, territórios, bloqueios, carros encontrados e comandos tipados. O RNG pertence ao estado; comandos inválidos trabalham numa cópia descartada sem consumir recursos/seed no original.
- `src/application/saves.ts`: codec e migração puros, persistência IndexedDB fora do motor. UI não decide custos/acertos.
- `src/ui/`: mapa e imagens reutilizáveis; interface existente atualizada.

## Matriz de execução

| Tema | Estado atual |
|---|---|
| Quatro classes e kit | Valores confirmados exatos, sorteio inclui caminhonete; tanque cheio apenas em novas partidas. Equipamento fixo tem ID e permanece com o modelo, mas habilidade não definida. Dois slots adicionais vazios. |
| Preparação | Sorteio determinístico da ordem e das cidades/setores iniciais; cidades diferentes, território controlado com defesa íntegra e sem ameaça; depósitos vazios. Duas gerais iniciais; compra da vez ao clicar Iniciar turno. |
| Turno e viagem | Uma viagem vizinha opcional antes da ação principal. Custo inteiro fixo, sem distância/carga/terreno. Toda viagem gera evento provisório. Administração/transferência local não cobra combustível. |
| Estoques | Tanque e reserva separados; depósitos de 10, todos os próprios da cidade acessíveis gratuitamente. Retirada, exploração ou troca podem abrir escolha de excesso; nenhum corte silencioso. |
| Terreno | Dados governam viagem, fuga e bloqueio. Hatch/sedã não usam terra; SUV/caminhonete usam. Suspensão impede terra; motor impede viagem. Efeitos antigos de pneu/superaquecimento não são ativados. |
| Bloqueios | Cartas de teste explícitas, bidirecionais, acumuladas; rejeição se qualquer carro presente perde todas as saídas compatíveis, sem considerar saldo de combustível. Expiração no início da próxima vez do autor; remoção antecipada só por carta. Não há remoção por sucata. |
| Descoberta/troca | Evento provisório encontra carro de qualquer das quatro classes com tanque vazio. Troca local usa ação; carro zero exige reparo em turno separado. Combustível anterior e do encontrado somados sem completar tanque; carga e mão preservadas, adicionais antigos descartados, fixo do novo modelo; 3 sucatas ficam no chão local. Excesso exige guardar em depósito próprio ou descartar. |
| Combate | Ataque básico D6 e resposta contra ameaça ou carro; dano persiste. Ameaça vencida perde ameaça e recebe defesa padrão íntegra, estoque não é gerado. Em PvP, uma carta aleatória às cegas é transferida antes de descartar equipamentos da mão do inutilizado; instalados ficam. Escolha interativa de cartas de verso e janelas de reação ainda não implementadas. |
| Fuga | Somente entre rodadas, D6+agilidade, alvo provisório; valida combustível e rota compatível/bloqueio antes de rolar. PvP exige carta elegível. Sucesso sai da cidade e paga consumo fixo, sem novo evento/ação; vencedor recebe uma carta da mão. Contra ameaça não exige carta. Falha continua sem ataque extra, sem cobrar combustível/cartas. |
| Exploração | Até três usos compartilhados por setor, perfil genérico provisório; descoberta vai para depósito, separado da conquista. Emergência/alheio e baralhos regionais ainda ausentes. |
| Controle/vitória | Pontos por todos os setores simultaneamente: 0,5 ou 1. Vitória por quatro pontos após resolver encontro/excedentes. Reconquista PvP, bônus locais e última sobrevivência dependem de etapas incompletas. |
| Corrida | A rolagem única v0.1 contrariava a pista/marcos/participação obrigatória. Ficou desativada com aviso, em vez de ser apresentada como corrida v0.4. Conteúdo/pista completa e retorno ainda precisam implementação. |

## Persistência e migração

O save atual usa envelope `format: terras-devastadas`, `schemaVersion: 4`, `contentVersion: 0.4.0`, `fuelUnit: whole`, `state` contendo o estado versionado. Não há heurística para deduzir unidade por magnitude. Confirmados dos veículos vêm do catálogo atual, não de estatísticas antigas do arquivo.

Não havia implementação anterior de save nem amostras legadas neste checkout. Por isso, **não há promessa de compatibilidade universal com saves v0.3 externos**. O contrato legado suportado pelo codec é estrito: envelope schema 3/content 0.3.0, mesmas entidades e IDs do domínio atual, unidade `whole` ou `half` declarada. `half` significa ticks de meia unidade: todos os saldos de combustível no tanque, reserva, depósitos e carros encontrados são divididos por 2. Tick ímpar é recusado, pois não há conversão inteira sem perda nem regra aprovada de arredondamento. O contrato é coberto por fixtures construídas nos testes, não validado contra arquivos reais de outra implementação.

Saves crus v0.1, schemas desconhecidos, topologia diferente, IDs inválidos, versões divergentes e valores negativos/fracionários são recusados. A interface não troca a sessão ao falhar a decodificação. Arquivos importados nunca são escritos no disco original.

Migração **não chama `createGame`**, não muda seed, ordem, IDs, posição, mãos, estoque, equipamento instalado, integridade ou saldo do tanque. Não entrega novas cartas nem kit. Um save que ultrapasse a capacidade nova fica pausado; a UI permite escolher recursos para descartar ou guardar localmente. Integridade histórica acima da ficha provisória não é cortada; reparo fica indisponível enquanto não houver dano abaixo da ficha.

IndexedDB guarda `current`; importação e nova partida guardam o anterior em `backup-*` e o texto importado em `import-original-*` na mesma transação. Backups internos não são apagados; ainda não há navegador de backups na UI (acessíveis nas ferramentas do navegador). Exportar JSON é o caminho de recuperação independente. Falha de gravação é visível, sem fingir sucesso. Cada origem/porta/perfil mantém banco próprio; não há sincronização entre abas. Recomenda-se uma aba por partida e exportação periódica.

## Interface e heurísticas de Nielsen

- **Estado visível:** jogador/cidade/turno, compra inicial, viagem e ação principal separadas, barras com números e rótulos, motivos de bloqueio, log e status de salvamento.
- **Linguagem do jogo:** tanque, carga, sucata, setores e rodovias; termos de schema/config restritos ao detalhe de desenvolvimento.
- **Controle e prevenção:** confirmação de importação/nova partida/troca, cancelamento, nenhuma exclusão automática de excesso, nenhuma rota ilegal acionável, erros sem perda de recursos.
- **Consistência/reconhecimento:** mesmos rótulos e custos vindos do motor; legenda asfalto/terra; imagens das quatro classes; cores acompanhadas de nomes/números/ícones, cartas visíveis só por escolha.
- **Eficiência:** atalhos para cidade atual, zoom e arrasto/rolagem do mapa, acesso local a depósitos; informações detalhadas sob disclosures.
- **Minimalismo e recuperação:** animações funcionais com movimento reduzido, contraste sobre a arte, painéis de ação, mensagens persistentes com ação de fechar, export/import de save. Modais nativos com foco contido e nomes acessíveis; teclado/foco visível; barras nomeadas.

Todos os PNGs de veículo foram inspecionados: canal ARGB e alpha zero no canto; não se assumiu transparência por nome/extensão. Mapas não geram regras: hitboxes, setores, custos, rotas e pontos vêm dos JSON. Assets originais preservados, sem edição. Há cerca de 16 MB de PNGs originais; otimização de mídia ainda não foi feita.

## Etapas e limites reais

1. Motor/conteúdo/save: implementados para o escopo atual, com contrato de migração limitado e explícito.
2. Turno/viagem/inventários: implementados, incluindo bloqueio e excesso. Melhorias territoriais/instalação ainda ausentes.
3. Combate/domínio: parcial; sem fortificação + carro defensor em conquista alheia, participação pessoal antes do dado, escolha de alvo entre múltiplos ataques ou janelas reativas. Recompra de ameaça em território alheio permanece aberta, não foi inventada.
4. Saque/cartas: cartas gerais de bloqueio em turno próprio apenas; saques e reações adversárias ainda indisponíveis. Não confundir recolhimento de depósito próprio com saque PvP.
5. Recuperação/corridas: reparos e troca implementados; emergência/eliminações e corrida completa ainda ausentes. Nenhuma morte automática por integridade zero.
6. UI/arte: interface responsiva testada em Chrome, 2/4 jogadores, desktop/móvel, imagens reais, zoom/pan e passagem privada. Sem playtest humano, medição de duração ou validação de balanceamento.

Abertos preservados: nomes/perfis finais de setores, rotas rurais reais, habilidades fixas (incluindo caminhonete), catálogo final de cartas, duração sem dano, emergência definitiva, superaquecimento, corrida solo/destruição, bônus próprios e balanceamento. Sem autenticação, nuvem, backend ou multiplayer.

## Validação executada

- `npm.cmd test`: **49 testes aprovados**, incluindo conteúdo, 60 seeds de sorteio, custo fixo, tanque, ação na chegada, imutabilidade, bloqueios acumulados por classe, fuga, troca, carga excedente, conservação de recursos, 50 seeds de combate, codecs e transações IndexedDB com backups.
- `npm.cmd run test:ui`: **4 cenários aprovados no Chrome headless** — quatro jogadores, privacidade e compra da vez; viagem e reload sem reabastecimento; layout móvel/importação inválida; mapa/zoom desktop; importação legada com excesso, escolha de descarte e original preservado. Capturas desktop/móvel geradas em `test-results/` e inspecionadas.
- `npm.cmd run build`: TypeScript estrito e bundle Vite aprovados.
- Instalação das dependências de teste reportou **zero vulnerabilidades**.

No sandbox desta sessão, Vite/Vitest encontraram leitura negada em diretórios ancestrais. Testes foram executados com a permissão do ambiente para rodar fora dessa restrição, sem alterar políticas/permissões do projeto. Isso não deve exigir execução como administrador na máquina comum.
