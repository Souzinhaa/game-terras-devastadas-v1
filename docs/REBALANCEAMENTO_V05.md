# Implementação do rebalanceamento v0.5

Aplicado sobre a branch feature/implementacao-inicial a partir do commit b0197fa. Fontes atuais: rules.md, rules-cards.md, context.md, src/data/rebalance.json e o catálogo tipado do motor. A decisão sobre cada sugestão está em DIAGNOSTICO_REBALANCEAMENTO.md.

## Alterações realizadas
- Preparação com combustível 3/6/6/9, uma geral, uma sucata e a compra normal do primeiro turno. Hatch restaurado à carga 1 conforme regra combinada e testes; o checkout possuía valor 4 divergente do GDD/testes.
- G09/G11/G12 +1 unidade e G21/G22 ±1 de avanço no catálogo, resolvedor, texto, arte e marcadores.
- G17 valida turno/janela/sucata local/ação/cota/rota antes de retornar estado aceito. Consome sucata, ação e carta; permite uma viagem posterior sem devolver ação. Não empilha bloqueio próprio/rota fechada e conserva proteção de última saída.
- E01/E02/E03 compartilham contador por veículo/rodada, consumido inclusive no erro; fixo separado. UI marca ambas as armas usadas após escolher uma.
- E04/E06/E09 únicos; E06 usa escopo de combate e não renova por rodada ou save.
- Anúncio territorial serializado, cancelamento quando pontuação cai e confirmação no próximo início, após expiração de efeitos e antes da compra. Não há imposto periódico.
- Doze PNGs atualizados pelo ID, registros com novos hashes, 56 marcadores e seis recursos com caminhos públicos canônicos.
- Recusa explícita de saves de edições antigas: não há conversão automática para regras novas. Originais e backups preservados; dados atuais fazem round-trip.
- Contexto/README/rules revisados e limpeza documentada em LIMPEZA_V05.md. Não houve remoção de assets ativos.

## Validação
- `npm test`: suíte de motor, cartas, hostis, IndexedDB e regressões do rebalanceamento. Inclui 30 sementes de setup (4 modelos) e testes de falha atômica, próxima rodada, novo combate, persistência, confirmação/cancelamento de vitória e recusa de conteúdo antigo.
- `npm run build`: TypeScript e Vite.
- Assets: dimensões, SHA-256 das 74 frentes e caminhos de todos os ícones conferidos.
- Playwright: runner ajustado para npm multiplataforma e Chromium padrão. A instalação do navegador neste ambiente retornou download inválido; testes de navegador não foram executados. Não confundir esse bloqueio de ambiente com resultado de UI aprovado.

Não houve partida humana ou simulação completa de 30 jogos. Sistemas parciais (defesa pessoal integrada, alerta de saque, exploração regional e eliminação) estão explicitados em context.md. Vitória por sobrevivência depende da implementação futura de eliminação; zero de Integridade continua recuperável.
