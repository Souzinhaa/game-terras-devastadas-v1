> Atualização v0.5: rules.md/rules-cards.md prevalecem; armas compartilham um ataque por rodada, E04/E06/E09 são únicos e E06 é por combate.

# Integração do catálogo de cartas — conteúdo 0.4.1

Implementação baseada em `rules-cards.md`, `src/data/catalog.json` e `rules.md` v0.5. Os valores do catálogo continuam propostas de balanceamento. A instrução do usuário inclui implementar os efeitos; o rival neutro permanece desativado conforme a restrição expressa do catálogo.

## Conteúdo e módulos

- `src/data/catalog.json`: manifesto original com 74 definições e hashes das artes.
- `public/assets/cards/`: 74 PNGs completos, sem recorte, compartilhados entre cópias. Os arquivos foram conferidos contra os hashes SHA-256 e dimensões 1024 × 1536 do manifesto.
- `src/engine/catalog.ts`: definições, efeitos discriminados, categorias, imagens e três pistas.
- `src/engine/cardRules.ts`: baralhos finitos, embaralhamento determinístico, descarte/reciclagem, efeitos por ID, instalação, capacidades, frequência por instância, escolhas e corrida.
- `src/engine/game.ts`: integra os efeitos às viagens, combate, fuga, conquista, sucata, limites e transições existentes.
- `src/ui/Cards.tsx`: mão com privacidade entre jogadores, catálogo consultável, PNG inteiro, ampliação, descrição acessível, alvos, instalação e resolução de escolhas/corrida.
- `src/application/saves.ts`: grava o estado dos baralhos e efeitos pendentes; migra conteúdo 0.4.0 sem alterar recursos, posição ou RNG existente. Originais continuam preservados pelo fluxo de backup.

São 148 instâncias: 48 gerais, 36 melhorias (24 equipamentos + 12 territoriais), 32 surpresas e 32 eventos. Cada nova cópia tem `id` e `instanceId` iguais e únicos; `definitionId` liga à arte. Instalações ficam fora dos baralhos e do descarte até serem removidas. Saves anteriores com cartas fora da composição são preservados; a migração não destrói cartas para forçar retroativamente uma contagem.

## Como usar

Abra **Cartas**, escolha o jogador cuja mão será consultada e pressione **Revelar**. Trocar o jogador oculta a mão novamente. Selecione jogador, território e estrada conforme o texto e use a carta. Clique na arte para ampliar. O catálogo completo está disponível para consulta sem revelar mãos.

Comprar melhoria custa 3 sucatas, uma vez por turno próprio, conforme o preço provisório do GDD. G15 não gasta essa compra. Equipamentos e territoriais saem do mesmo baralho e usam reservas separadas. Instalar localmente é livre mesmo depois da ação; instalar territorial remotamente consome a ação. T06 permite selecionar uma instalação para substituir.

O combate oferece uma janela antes de cada ataque, inclusive a resposta da ameaça. **Declarar cartas e equipamentos** abre a mão; **Voltar ao combate** retoma os comandos. Ataques adicionais usam munição e têm frequência por instância. O dado natural 1/6 mantém falha/acerto automático.

Viagens revelam um evento após a chegada. Escolhas obrigatórias interrompem o fluxo sem gastar outra viagem. A última carta pública pode ser consultada pelo controle **Última carta revelada**.

Corridas usam inscrições individuais, combustível da pista, marcos resolvidos em ordem, escolhas de alvo, modificadores de próxima rolagem, retirada por integridade zero, rodada final completa, desempate por dado sem cartas e prêmio. O carro permanece na cidade de retorno; a ação principal da viagem é preservada. Menos de dois inscritos cancela a prova e devolve as taxas. O painel pode ser recolhido para declarar gerais e equipamentos antes do avanço.

Excedentes não desaparecem: a interface existente permite escolher descarte ou depósito local. E02 exige capacidade para sua carga extra; remover E08 exige retirar antes qualquer equipamento cuja carga extra já não caberia. Recursos soltos excedentes continuam sujeitos à escolha de descarte.

## Limites e decisões ainda abertas

- Rival neutro de um inscrito não foi ativado.
- Destruição em corrida segue a proposta recuperável do catálogo, sem eliminar automaticamente o jogador.
- V16 usa os modelos ainda não ativos nem encontrados como oferta disponível; a composição final do baralho de veículos continua indefinida.
- V15 usa um encontro temporário leve com integridade 2 e os parâmetros de ataque/defesa provisórios existentes. Não concede território, não persiste após fuga e consome a ação uma vez.
- Saque simples inclui combustível, disputa, modificadores G19/G20, penalidade de falha e limite do cofre T05. A seleção atual recebe até duas unidades de um recurso escolhido. A defesa pessoal integrada ao saque continua pendente: o motor exige enfrentar o carro por duelo antes de saquear/atacar a fortificação. Não aplica bônus de fortificação ao duelo.
- Habilidades fixas exclusivas, exploração regional, catálogo definitivo de ameaças e recuperação/eliminações por emergência completa permanecem fora desta integração. V05 reduz o tanque, mantendo as limitações atuais de deslocamento; não inventa uma regra nova de eliminação por combustível.
- A ordem de declaração de reações é conduzida pelos jogadores no hot-seat; cada alvo e janela é validado pelo motor.

## Validação

`npm.cmd test -- --configLoader runner` executa testes de composição, IDs, efeitos gerais, todos os eventos/surpresas, custo, alvo, timing, limites, instalação, unicidade, T06, conservação de dano, munição, corrida e migração. O carregador `runner` evita o erro de acesso do esbuild à pasta ancestral neste ambiente Windows restrito.

`npm.cmd run test:ui` cobre a interface desktop/móvel, carregamento de PNG, ampliação, privacidade, saves e janela de resposta em combate. `npm.cmd run build` valida TypeScript e gera o build Vite.
