# Terras Devastadas — entrada para agentes

O repositório mantém somente os apps Android de celular e Tabuleiro/TV em `godot/`, com Godot 4.7 Standard, GDScript e Compatibility.

- Começar por `godot/AGENTS.md` e pelo contexto único `godot/CONTEXT.md`. Execução, testes e exportação ficam em `godot/README.md`.
- Features/correções sem modo explícito devem funcionar e ser verificadas no normal/local (hot-seat) e Multiplayer LAN. Atualizar TV quando afetar apresentação pública; preservar privacidade e permissões.
- Novas partidas: `campaign-v07`, regras 0.7/conteúdo 0.7.0. Saves `campaign-v06` preservam sua edição.
- Contratos: `rules.md`, `rules-cards.md` e `docs/COMO_JOGAR.md`. Ajuda local/LAN em `godot/scripts/how_to_play.gd` acompanha o perfil real.
- UI e pendências: `godot/docs/UI_IMPLEMENTATION.md` e `godot/docs/UI_PREMIUM_IMPLEMENTATION.md`.
- Preservar artes originais, licenças, testes nativos, ferramentas de build e ambos os presets. Não reintroduzir website.
- Código/testes confirmam funcionalidade. Catálogo ou imagem não comprova efeito implementado; testes desktop não comprovam Android físico.
