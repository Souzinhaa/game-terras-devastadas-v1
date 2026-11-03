# Terras Devastadas — entrada para agentes

O desenvolvimento atual tem como alvo **Godot 4.7 Standard / Android em paisagem**, em `godot/`.

- Para trabalho no jogo nativo, começar por `godot/AGENTS.md` e `godot/CONTEXT.md`.
- Features e correções sem indicação explícita de modo devem ser implementadas e verificadas nos dois modos nativos: normal/local (hot-seat) e Multiplayer LAN. Não considerar a entrega concluída ao funcionar em apenas um. Atualizar também a TV/Tabuleiro quando afetar apresentação pública; preservar privacidade e permissões de cada jogador. Restringir a um modo somente quando o pedido for específico dele.
- `context.md` e `godot/CONTEXT.md` descrevem o estado atual Android; novas partidas usam `campaign-v07`, regras 0.7/conteúdo 0.7.0. Saves `campaign-v06` mantêm sua edição.
- `rules.md`, `rules-cards.md` e `docs/COMO_JOGAR.md` são os contratos e o guia atuais. A ajuda local/LAN usa `godot/scripts/how_to_play.gd` e deve acompanhar o perfil da partida.
- A referência React/TypeScript em `src/` continua em 0.6, sem paridade integral com o nativo. Seu contexto anterior está em `docs/historico/CONTEXTO_REACT_V06.md`.
- Não aplicar como pendência atual os planos/relatórios identificados como históricos. Código/testes confirmam o que está funcional em cada runtime.
- O planejamento visual está em `update_ui.md`; a implementação e suas pendências estão em `godot/docs/UI_IMPLEMENTATION.md`.
- Não tratar presença de cartas, imagens ou catálogo como efeito funcional. Preservar a distinção entre cadastrado, implementado e validado em Android físico.
