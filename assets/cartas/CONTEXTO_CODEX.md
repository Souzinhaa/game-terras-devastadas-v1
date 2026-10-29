# Terras Devastadas — integração das cartas completas

## Conteúdo
74 PNGs individuais de 1024 × 1536 pixels, proporção 2:3, com nome, categoria, ilustração e efeito na própria carta. Pastas: gerais (24), equipamentos (12), territoriais (6), corrida (16), eventos (16). `cartas.json` liga os IDs aos arquivos e inclui textos e quantidade de cópias. São 148 instâncias de jogo reutilizando 74 artes.

## Uso no projeto
Copie estas pastas para `public/assets/cards/` e carregue o manifesto. Resolva o campo image relativo à raiz copiada. Exiba a carta com object-fit: contain e razão 2/3, sem cortar título ou efeito. Clique/toque deve abrir a imagem ampliada. Em miniatura, mostre também nome e descrição acessíveis na interface. Não renderize outra caixa de texto sobre a imagem: ela já contém nome e regras.

Estas são cartas completas, não ilustrações isoladas. PNGs são opacos e têm moldura. Não remover fundo nem recortar a área do efeito. O log e o motor devem usar dados estruturados; nunca OCR nem LLM para interpretar a imagem em tempo de execução.

## Regras e status
Use GDD v0.4 para regras confirmadas. Este catálogo continua proposta de balanceamento: produzir imagens não aprova automaticamente seus efeitos. Código deve validar alvos e janelas e aplicar efeitos tipados, não executar rulesText. Um campo copies significa quantas instâncias criar, e não imagens distintas.

Equipamentos e territoriais pertencem ao mesmo baralho de melhorias. Gerais respeitam uma utilização por jogador por turno do mapa; eventos e surpresas são imediatos. Custos e capacidades dos veículos continuam os definidos no GDD. Não modificar consumo base por causa da arte.

## Edição de texto e limites
As cartas foram geradas individualmente com image_gen e revisadas visualmente. Há pequenas variações de diagramação. Equipamentos/territoriais nem sempre imprimem o lembrete de um espaço: o custo de espaço continua 1 no manifesto e na regra geral. Este pacote não contém versos comuns nem fichas P01–P03; as pistas estão descritas no catálogo. Não criar versos diferentes para cartas que entram na mão, pois o roubo é às cegas.

Uma alteração futura no efeito exige atualizar o catálogo, o manifesto, a implementação e a imagem. Mantenha uma descrição acessível em texto mesmo enquanto usa PNG completo. Os dados incluem campos de leitura, não um motor de efeitos já implementado.

V13/V14 receberam o texto de retomada do turno expandido para não depender de ler V12. G24 removeu a observação editorial sobre condição ainda indefinida; concede apenas uma água. E04 usa teto 6+ sem palavra provisório impressa, mas o balanceamento continua proposto.

## Verificações feitas
74 arquivos encontrados e decodificados; resolução uniforme 1024 × 1536; IDs únicos; SHA-256 no manifesto; soma de cópias 148. Revisão visual de títulos, categorias e áreas de efeito, sem afirmar certificação de impressão. Não é um pacote de sangria gráfica para gráfica comercial.

## Prompt para o Codex
Leia este contexto, o catálogo e o GDD v0.4. Integre as 74 cartas completas ao projeto existente com base nos IDs de cartas.json. Preserve dados e lógica existentes; exiba PNG sem cortes, zoom e descrições acessíveis. Reutilize artes entre cópias e crie instanceId único por cópia. Implemente efeitos explicitamente tipados e testes de custo, timing e alvo. Não trate os textos como código nem as artes como aprovação de balanceamento. Apresente os módulos integrados e as pendências reais.

## Direção de arte e geração
Ferrugem, aço escuro rebitado, laranja queimado, areia e marfim. Arte central pós-apocalíptica com veículos de sucata e ruínas. Prompt-base: criar carta vertical 2:3 com nome e categoria, ilustração temática original no centro, painel marfim inferior e efeito literal em português, ID e marca no rodapé, sem mockup. A Mira de Ferro G01 serviu como referência visual para os outros modelos. Geração pelo image_gen; nenhuma chave de API é necessária para consumir os arquivos locais.
