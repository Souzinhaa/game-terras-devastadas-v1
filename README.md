# Terras Devastadas — Android e TV

Jogo de tabuleiro digital pós-apocalíptico para 2–4 jogadores. Este repositório mantém os apps de celular e Tabuleiro/TV no projeto [Godot](godot/project.godot), sem website.

- Celular: Android em paisagem; normal/local (hot-seat) ou Multiplayer LAN.
- Tabuleiro/TV: tela pública opcional, tanto para LAN quanto para partida no mesmo celular. Sem mãos privadas ou comandos de jogador.
- [Como jogar](docs/COMO_JOGAR.md), [regras 0.7](rules.md) e [cartas](rules-cards.md).
- [Executar, testar e exportar](godot/README.md).
- [Contexto técnico único](godot/CONTEXT.md) e [instruções para agentes](godot/AGENTS.md).

Novas partidas usam `campaign-v07`, regras 0.7/conteúdo 0.7.0. Saves `campaign-v06` mantêm sua edição. Os presets atuais são `0.0.4-vehicle-colors`, código 14; os APKs locais ficam na raiz: `terras-devastadas.apk` e `terras-devastadas-tabuleiro.apk`.

`godot/` contém runtime, dados, testes e ferramentas dos dois apps. `assets/` guarda artes originais e fontes de produção usadas na manutenção dos assets nativos. Licenças, presets de exportação e CI Android/TV fazem parte do projeto.

Validação automatizada desktop não substitui testes em celular/TV físicos. Consulte os limites no contexto técnico.
