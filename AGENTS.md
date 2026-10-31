# Terras Devastadas — entrada para agentes

O desenvolvimento atual tem como alvo **Godot 4.7 Standard / Android em paisagem**, em `godot/`.

- Para trabalho no jogo nativo, começar por `godot/AGENTS.md` e `godot/CONTEXT.md`.
- A aplicação React/TypeScript em `src/` permanece como referência das regras implementadas. Não presumir paridade entre os motores.
- `context.md` contém principalmente histórico e estado da referência React, com um aviso de escopo no início.
- `rules.md`, `rules-cards.md` e os JSON definem os contratos; código/testes confirmam o que está funcional em cada runtime.
- O planejamento visual está em `update_ui.md`; a implementação e suas pendências estão em `godot/docs/UI_IMPLEMENTATION.md`.
- Não tratar presença de cartas, imagens ou catálogo como efeito funcional. Preservar a distinção entre cadastrado, implementado e validado em Android físico.
