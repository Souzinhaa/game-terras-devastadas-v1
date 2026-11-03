# Veículos nas cores dos jogadores

03/11/2026. A identidade segue o ID do assento, nunca a posição embaralhada na lista de jogadores.

| ID | Jogador | Pintura | Cor anterior |
| --- | --- | --- | --- |
| 0 | 1 | Laranja | Laranja |
| 1 | 2 | Azul | Azul |
| 2 | 3 | Preto | Roxo |
| 3 | 4 | Branco | Verde |

`scripts/player_palette.gd` centraliza nomes e cores. `scripts/vehicle_art.gd` resolve a arte pelo modelo e pelo dono, atualizando também quando apenas o dono muda. Local/LAN/TV usam essa seleção no mapa, resumo, detalhes, arena e corrida. Os nomes e marcadores pretos têm contorno claro quando necessário. Nenhum dado privado novo foi adicionado à projeção pública.

## Artes

Os 40 PNGs originais em `assets/veiculos/{Laranja,Azul,Preto,Branco}` na raiz foram preservados. As cópias de runtime ficam em `godot/assets/vehicles/players/{laranja,azul,preto,branco}`. Importação lossless, transparência preservada, limite de 512 px na vista de cima e 1024 px na lateral.

A inspeção conjunta das 40 imagens mostrou moto azul verde, caminhonete azul verde escura e caminhonete laranja marrom. As pinturas de moto/caminhonete foram corrigidas nas quatro cores usando a ferramenta integrada `image_gen` e conferidas visualmente. `repaint-atlas.png` guarda a folha resultante; `tools/extract_vehicle_repaint.ps1` recorta suas 16 células por transparência para o runtime. Hatch, Sedan e SUV conservam as imagens fornecidas.

Prompt de correção: manter grade 4×4, silhuetas, vistas, detalhes, ferrugem e transparência; pintar carroceria/tanque/carenagem em laranja `#ed8e42`, azul ciano `#51c9ef`, preto `#20252b` e branco `#f1eee6`, preservando pneus e metal. Colunas nessa ordem; linhas caminhonete de cima, caminhonete lateral, moto de cima, moto lateral. Remover halos de cor e manter bordas neutras com transparência.

As novas pinturas não incluem spritesheets. A corrida mantém seu deslocamento animado com a arte colorida estática, sem alternar para a pintura genérica. As animações antigas permanecem disponíveis para apresentações sem dono.

## Validação e limites

`vehicle_colors_smoke` verifica os cinco modelos e quatro assentos, troca de dono com mesmo modelo, cor durante movimento, mapa/resumo/detalhes locais, retratos de cada celular LAN, mapa e combate públicos na TV, combate local, corrida e ausência de mutações de estado/RNG na consulta. A TV continua sem mãos, estoques ou comandos privados.

Capturas Windows transitórias em `.tools/vehicle-colors-{local,lan,tv}.png`; conferência das fontes em `.tools/vehicle-colors-source-check.png`. O runner pode acusar `ERROR: Failed to read the root certificate store.` no ambiente restrito, mesmo quando as asserções das suítes passam. Não declarar PASS integral do runner nesse caso.

Resultado em Windows/Godot 4.7.2: **161 verificações da suíte de cores, nenhuma falha de asserção**. Regressões de combate, LAN UI (39), layout LAN compacto (56), TV (49), encontros públicos (26), fluxo de turno (63) e viagem/encontro também terminaram sem falhas de asserção. Todos esses processos encerraram com código 0; o runner os marca como FAIL pelo erro do repositório de certificados do Windows, não por uma asserção do jogo.

APKs exportados em 03/11/2026: **0.0.4-vehicle-colors / código 14**, celular ARM64 e Tabuleiro ARM64/ARMv7, disponíveis na raiz. Assinaturas anteriores preservadas. As 40 texturas importadas de cada APK foram comparadas por SHA-256 às fontes importadas atuais. ZIP, assinatura, alinhamento 16 KiB, versões interna/Android, permissões, launcher Leanback e fingerprint LAN comum passaram na verificação. [Manifesto e hashes](../../builds/vehicle-colors-build-manifest.json). Instalação/execução em Android/TV físicos ainda pendente.
