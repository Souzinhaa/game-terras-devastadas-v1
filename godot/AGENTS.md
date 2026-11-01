# Instruções para agentes — Terras Devastadas / Godot

Escopo: projeto nativo em `godot/`. Atualizado em 30/10/2026.

Novas partidas usam `campaign-v07`; consultar `docs/REBALANCEAMENTO_V07.md`. Saves `campaign-v06` preservam seus números e baralhos. Testes de regressão v0.6 usam perfil explícito; `tests/balance_smoke.gd` verifica as regras novas e a compatibilidade.

## Ordem de leitura

1. `CONTEXT.md`: estado real e limites da migração.
2. `README.md`: execução, regras disponíveis e testes.
3. `../rules.md`, `../rules-cards.md` e JSON relevantes: contratos de regras.
4. `../update_ui.md` e `docs/UI_IMPLEMENTATION.md`: direção e implementação da interface.
5. Código e testes do sistema a alterar.

O contexto da raiz contém histórico React. Não tratar seus sistemas implementados como funcionalidades existentes no Godot. Em conflito entre documentação e código, verificar e registrar a divergência antes de declarar uma função pronta.

## GodotPrompter

Consultar `using-godot-prompter` e as skills de domínio relevantes antes da implementação. Exemplos: `godot-ui`, `hud-system`, `responsive-ui`, `input-handling`, `animation-system`, `tween-animation`, `save-load`, `godot-testing` e `godot-code-review`.

As skills orientam a implementação; não mudam as regras, o escopo pedido ou a prioridade das instruções do usuário. Não introduzir dependência/addon apenas para reproduzir um exemplo da skill.

## Restrições de manutenção

- Godot 4.7 Standard, GDScript, Compatibility; alvo Android em paisagem e hot-seat de 2–4 jogadores.
- Regras e RNG ficam no motor, nunca em animações, ícones, texto das cartas ou callbacks visuais.
- Importar catálogo/artes não implementa equipamentos ou efeitos. Distinguir cadastrado, implementado e testado.
- Preservar saves, recursos, filas de revelação, combate pendente e RNG; não converter saves React silenciosamente.
- Toda aquisição de carta usa `WastelandGame.gain_card`; toda remoção deve preservar os índices das revelações pendentes.
- Exploração concede recursos ao depósito. O popup exibe o delta real; fechar ou abrir depósito não sorteia nem concede itens novamente.
- Manter mão recolhida central sem faixa preta, resumo lateral do veículo e privacidade na passagem de dispositivo.
- UI em cenas/tema compartilhado. Preferir atualização por mudança de estado, sem reconstruir inventário/mão sem necessidade.
- Preservar originais dos assets. Copiar para o runtime em `godot/assets` e manter configurações `.import`; não editar cache `.godot/`.
- Não apresentar testes Windows como validação Android física nem PCK como APK.
- Não implementar backend, autenticação, multiplayer de rede ou novas regras sem pedido.

## Verificação e contexto

Usar perfil de teste isolado, conforme README, para não sobrescrever a partida do usuário. Executar os testes pertinentes à mudança e revisar a tela renderizada quando houver alteração visual.

Atualizar `CONTEXT.md` e README quando um sistema mudar de estado ou contrato. Manter relatórios e documentação coerentes, sem apagar os limites reais da migração.
