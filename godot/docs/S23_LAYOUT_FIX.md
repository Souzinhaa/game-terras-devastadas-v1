# Layout após os prints do Galaxy S23

30/10/2026. Os prints físicos enviados pelo usuário mostraram fontes excessivas, painel fora da tela, ações de carta cortadas e um mapa menor sobre outro fundo.

DPI agora ajusta somente alvos de toque; fontes seguem a preferência e a escala do canvas. HUD e folhas respeitam a área segura. As ferramentas usam duas colunas nas telas baixas com toque, sem sobrepor ações. A consulta de carta dispõe arte à esquerda, texto rolável à direita e ações fixas no rodapé.

O mapa cobre os cantos e limita o arrasto para não revelar fundo. A imagem original continua central, sem distorção, com as mesmas coordenadas percentuais. A extensão decorativa não altera cidades, rotas, regras, saves ou RNG. O shader suaviza a junção nas bordas.

Após feedback no PC, o núcleo do mapa passou a caber entre o cabeçalho e a mão, mantendo o terreno panorâmico nos cantos. O modo mapa livre remove essa reserva. O botão principal “Viajar / explorar” lista destinos conectados e acesso aos setores locais. A consulta da cidade mantém a viagem visível, desabilitada com justificativa quando necessário. A posição dos nomes também considera marcadores de cidades e setores.

## Arte

Novo asset: `assets/mapa-panoramico-s23-v1.png`, 1896 × 830, gerado pela ferramenta integrada de imagem usando `assets/mapa-expandido-v2.png` como referência. Original preservado. Como a geração não preservou exatamente todos os pixels centrais, o runtime sobrepõe o original à expansão.

Prompt utilizado:

> Edit target: the attached existing top-down game map. Use case: precise-object-edit / horizontal outpainting. Expand its canvas to a wide landscape 13:6 aspect ratio (approximately 2340 by 1080), by adding contiguous terrain to the left and right ONLY. Keep the complete original 4:3 map, uncropped and undistorted, in the central 61.54% of the canvas, occupying the full height; original left edge at 19.23% and right edge at 80.77% of new canvas. Preserve the original center's road network, towns, rivers, lakes, colors and scale EXACTLY; do not rearrange or repaint it. Extend rural terrain, winding small roads, farms, forest and rivers seamlessly across the new outer left/right areas using the same muted warm brown/olive aerial map illustration style. No new major urban centers in added margins. Uniform top-down orthographic perspective and uniform visual scale; no vignette, borders, duplicate map, framing, paper, blur, interface, labels, text, icons, symbols or vehicle pieces. Every edge of the image must be map terrain. Purpose: seamless full-screen landscape board game map with decorative overscan margins; the exact original center remains the gameplay coordinate region.

## Verificação

Prévia de viagem: destinos agrupados em cartões, com estrada, piso e custo inteiro na mesma opção. Clicar em “Ver rota”, na consulta da cidade ou diretamente em uma rota disponível abre uma prévia no mapa. Um Tween de 0,55 s enquadra a polilinha e destaca apenas o trajeto selecionado. O rodapé oferece Cancelar e Confirmar viagem. Cancelar/Voltar restaura câmera e modo de mapa; somente confirmar envia o comando ao motor, que revalida as condições. Movimento reduzido aplica o enquadramento sem animação. A prévia não faz parte do save e não consome RNG, combustível ou ação. Passagem privada cancela a prévia. As variantes móveis verificam animação, identidade da rota, limites das ações, cancelamento, confirmação única e estado preservado antes da confirmação.

Correção posterior: o recorte de texto não é aplicado globalmente aos botões. Os botões nativos de `ConfirmationDialog` precisam da largura mínima calculada pelo texto; o recorte global fazia “Começar” e “Cancelar” encolherem na execução pelo editor. `onboarding_ui_smoke.gd` agora abre a configuração e verifica a largura desses dois controles antes de criar a partida.

`tests/mobile_layout_smoke.gd` renderiza em 2340 × 1080, com toque, DPI 425 e recorte simulado de 64 pixels. Repete com texto em 125%. Confere limites do HUD, ferramentas sem sobreposição nas ações, folha lateral, rodapé da carta, proporção original, cobertura dos cantos durante zoom/arrasto e preservação do estado/RNG. O runner inclui as duas variantes com perfis isolados.

Capturas locais em `.tools/s23-{board,sectors,card}-{normal,large}.png`. São simulações no Windows. Os prints do usuário são evidência física dos problemas anteriores; a correção ainda requer confirmação no S23 com nova compilação.
