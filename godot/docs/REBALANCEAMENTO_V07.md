# Regras nativas 0.7 — ritmo e decisões

Implementação autorizada após a revisão de design, em 31/10/2026. Escopo: Godot local/LAN e apresentação pública na TV.

## Edição e saves

- Novas partidas: `rules_profile=campaign-v07`, regras `0.7`, conteúdo `0.7.0`.
- Saves `campaign-v06` continuam com quatro pontos, Moto recebendo dez combustíveis na melhoria, Defesa 3+ nos veículos pesados, penalidade de um turno após destruição, saque contra D6+1, exploração totalmente sorteada, corrida obrigatória para o revelador apto e baralhos originais.
- Carregar saves não sorteia novamente nem substitui o perfil. Campos estruturais novos têm defaults sem efeitos. Saves com edições desconhecidas são recusados.
- O replay usa o perfil registrado no save. Consultas de disponibilidade não consomem RNG nem escrevem arquivos.

## Novas partidas

| Sistema | Regras 0.7 |
| --- | --- |
| Hatch (ajuste autorizado em 02/11/2026) | Capacidade 5; E08 aumenta para 7. Cabe o custo de cinco sucatas da melhoria sem outros itens. Saves 0.6 preservam capacidade 4, ou 6 com E08. |
| Exploração | Uma ação; 2–3 recursos no depósito. O jogador garante uma unidade de sucata ou combustível; as outras 1–2 são sorteadas entre os seis tipos. Sem seleção explícita no comando, o padrão é sucata. Mantido o limite de três explorações por setor. |
| Suprimentos | Uma vez por turno próprio, fora de encontros, trocar uma água, pneu ou bateria da carga por uma sucata, sem ação principal. A troca conserva o tamanho da carga; não há venda infinita nem doações entre jogadores. |
| Moto | Mantém dano 2, consumo 1, carga 2, terra e equipamentos sem peso. Melhorar continua custando cinco sucatas e uma ação; preserva combustível em vez de gerar dez unidades. |
| SUV e Caminhonete | Defesa passa de 3+ para 4+. Integridade, carga e consumo permanecem. Defesa é limiar de acerto do atacante: número maior torna o alvo mais difícil de acertar. |
| Primeira destruição | Hatch íntegro, três combustíveis e perdas de itens anteriores mantidas. Não perde a próxima vez. Protegido contra combate/participação até iniciar seu próximo turno próprio. A ação da destruição termina. |
| Segunda destruição | Eliminação mantida; vitória por último sobrevivente continua imediata. |
| Vitória territorial | Três pontos, anunciados no fim do turno e sustentados até o próximo início próprio, antes da compra. Perder pontos/proteção operacional cancela o anúncio. |
| Saque simples | D6 contra D6; empate da defesa. Mantidos custo de uma ação e um combustível, até dois recursos no sucesso e dois danos na falha. Sem modificadores, sucesso 15/36, aproximadamente 41,7%. |
| Corrida | Revelador apto também pode recusar. Exige dois participantes; se não houver, devolve a inscrição e não dá prêmio. Distâncias e prêmios mantidos. |
| Conteúdo indisponível | E11 e V16 ficam fora dos baralhos novos. As quatro cópias continuam no registro como `unavailable`; nenhuma carta é apagada de partidas antigas. |

## Ameaças e escolhas de risco

O setup novo usa os doze hostis. Em cada cidade, ordenam-se os setores neutros: o primeiro é fácil, os demais médios; o último de uma cidade com quatro setores é difícil. A identidade dentro da faixa varia deterministicamente com a seed e o setor, sem rerrolar ao carregar.

A interface informa apenas a faixa fácil/média/difícil antes da descoberta. Nome e atributos do hostil continuam ocultos até a revelação. Os prêmios por faixa já existentes são preservados. Conquista não cria uma nova ameaça; defesas de setores conquistados continuam usando as regras territoriais.

## Combate rápido, sem decisões automáticas do jogador

- `Avançar até a próxima decisão` é um comando explícito, limitado a 24 transições por chamada.
- Pode rolar o ataque pronto, continuar um resultado sem arma opcional e começar a próxima rodada se nenhum participante tem fuga legal.
- Para antes de cartas pendentes, equipamentos ativáveis, munição opcional, fuga ou resultado final. Não escolhe veículo capturado, descarta excesso, confirma cartas nem fecha recompensas.
- Jogador pode optar por passar nas próximas rolagens daquele combate. Não usa carta nem consome a cota de geral; é possível voltar a reagir antes do dado.
- A preferência é persistida por jogador/combate. Na LAN, a opção autoriza somente o próprio jogador; espectador não a recebe. Recibos impedem repetir rolagens ao reenviar o comando.
- O motor registra todas as rolagens. A apresentação pode mostrar somente o resultado mais recente do lote; nunca decide RNG ou dano.

## Interface e verificação

As ações novas usam as folhas, tema, área segura, paginação e rolagem existentes. Não foram adicionadas barras permanentes. Texto de objetivo usa o perfil real da partida, inclusive no placar LAN e na ajuda local.

- `tests/balance_smoke.gd`: economia nova/antiga, ameaças, vitória, recuperação, saque, corrida, RNG manual versus rápido, interrupções para decisões, comandos inválidos atômicos, save/reconexão, privacidade e recibos.
- `tests/lan_mobile_layout.gd`: conexão, HUD, compras e botões novos de exploração/troca em 892×445, 1280×720 e 2340×1080 com recorte simulado.
- Regressões de campanha/combate v0.6 e fixtures nativas usam perfil antigo explícito; não foram reescritos como regras novas.
- Regressões de LAN, combate visual, campanha visual, exploração e revelação também são executadas.
- `tools/run_checks.ps1` inclui as suítes novas e permite `-OnlySuites`. Perfis de teste temporários curtos evitam a falha de cache OpenGL em caminhos longos do Windows.

Testes e capturas de Windows não substituem testes de toque, rede, desempenho ou balanceamento com pessoas em Android físico. A edição é um conjunto de hipóteses implementadas para playtest, não uma afirmação de equilíbrio competitivo ou de duração já medida.

## APK de teste

O workflow Android exporta a variante `com.bhsp.terrasdevastadas.preview.v07`, chamada **Terras Devastadas Teste 0.7**, versão `0.0.4-ui-tv`. Ela instala ao lado do APK anterior, preservando seus dados. Todas as pessoas da sala LAN devem usar esta edição. Começar uma partida nova para jogar com as regras 0.7; carregar uma partida 0.6 preserva as regras anteriores.

A chave de debug do CI é temporária por execução. Builds futuros com o mesmo pacote podem exigir reinstalar essa variante de teste; não usar este workflow para substituir a assinatura de distribuição.

Ajuste solicitado em 03/11/2026: limiares atuais da edição 0.7 — Hatch 3+, Sedã/SUV/Caminhonete 4+, Moto 5+. A regra de 1 natural errar e 6 natural acertar permanece. Edição 0.6 e snapshots de combates já iniciados permanecem preservados. Atributos públicos, prévia de troca e combate consultam o mesmo motor.
