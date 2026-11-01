# Terras Devastadas — Godot / Android

Jogo de tabuleiro digital pós-apocalíptico para 2–4 pessoas, com exploração, conquista, combate e duas vidas. O desenvolvimento ativo está em [godot/project.godot](godot/project.godot), usando Godot 4.7 Standard, validado no 4.7.2, com foco em Android na horizontal.

## Começar a jogar

- [Como jogar no Android, em LAN ou no mesmo aparelho](docs/COMO_JOGAR.md).
- [Regras completas da edição 0.7](rules.md).
- [Cartas, baralhos ativos e exceções](rules-cards.md).
- [Guia técnico Godot, testes e exportação](godot/README.md).

No modo LAN, todos usam a mesma edição do APK e a mesma rede local. Um celular cria a sala e os demais entram; cada pessoa consulta suas próprias cartas. O anfitrião deve manter o aplicativo aberto. No modo local, o aparelho passa entre os jogadores com identificação antes das informações privadas. O Tabuleiro/TV é opcional e mostra somente informações públicas.

A interface tem retorno visual nos botões e destaques de ações no mapa. Na TV, as etapas do turno e o placar compacto ficam visíveis; controle remoto abre detalhes públicos. A animação de compra foi preservada. Veja [capturas e validação da interface/TV](godot/docs/UI_INTERACTION_TV.md).

## Edição atual

Branch: **feature/release-0.0.4**. APK de teste: **0.0.4-ui-tv**. Novas partidas: regras **0.7**, conteúdo **0.7.0**, perfil **campaign-v07**. O número da build e a versão das regras identificam coisas diferentes.

- Vitória territorial: anunciar **3 pontos** ao encerrar e manter até o próximo início próprio; último sobrevivente vence imediatamente.
- Exploração: **2–3 recursos no depósito**, incluindo uma unidade escolhida de sucata ou combustível.
- Água, pneu ou bateria da carga podem virar uma sucata, uma vez por turno próprio, sem ação principal.
- Melhorar o Hatch custa cinco sucatas próprias locais e uma ação; todos os modelos preservam combustível e integridade atual. Moto mantém dano 2, consumo 1 e equipamentos sem peso; SUV/Caminhonete têm Defesa 4+.
- Primeira destruição: Hatch íntegro, três combustíveis, proteção até iniciar o próximo turno próprio, sem perder essa vez. Segunda destruição elimina.
- Saque simples: D6 contra D6, empate da defesa. Inscrição em corrida é opcional inclusive para quem revelou o evento.
- Combate oferece avanço até a próxima decisão e preferência individual de passar nas próximas reações.
- E11 e V16 ficam fora dos baralhos de partidas novas; o catálogo e o registro mantêm suas identidades.

Saves nativos **campaign-v06** continuam com as regras anteriores. Carregar uma partida não a converte para 0.7; comece outra para usar as mudanças. Formatos React e Godot são distintos.

## APK e validação

O [workflow Android](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/workflows/android-debug.yml) gera APK ARM64 de teste e verifica assinatura, pacote e permissão de rede. Nos artefatos de uma execução concluída, baixe o ZIP e extraia o APK. O app **Terras Devastadas Teste 0.7**, pacote `com.bhsp.terrasdevastadas.preview.v07`, instala separado do APK anterior.

O mesmo workflow prepara o APK **Tabuleiro Teste 0.7**, pacote `com.bhsp.terrasdevastadas.tabuleiro.preview.v07`, para TV. Use o arquivo com `tabuleiro` no nome nesse aparelho; a variante de celular é outro APK. A chave debug muda por execução: se já instalou uma variante de teste com assinatura anterior, preservar seus dados antes de reinstalar. A distribuição assinada definitiva é um processo separado.

A execução [41257585924](https://github.com/Souzinhaa/game-terras-devastadas-v1/actions/runs/41257585924) validou 180 verificações de regras, 63 de sessão LAN e 201 de campanha LAN, e exportou o APK assinado. Layouts foram verificados no Windows em 892×445, 1280×720 e 2340×1080, com recorte simulado. Isso não comprova toque, rede, desempenho ou balanceamento em Android físico; playtests com pessoas permanecem pendentes.

## Desenvolvimento e contexto

Comece por [AGENTS.md](AGENTS.md), [context.md](context.md) e [godot/CONTEXT.md](godot/CONTEXT.md). Os textos atuais descrevem o runtime nativo. Relatórios antigos estão identificados como registros históricos; não devem reintroduzir regras substituídas.

A referência React/TypeScript permanece em `src/`, com regras 0.6 e persistência IndexedDB. Ela não recebeu as mudanças nativas 0.7, não tem paridade integral de seed e não importa saves Godot. Contexto preservado: [referência React v0.6](docs/historico/CONTEXTO_REACT_V06.md). Para executar essa referência: Node.js 24, `npm ci`, `npm run dev`, `npm test` e `npm run build`; no PowerShell, use `npm.cmd` quando necessário.

