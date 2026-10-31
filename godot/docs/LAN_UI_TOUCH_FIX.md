# LAN — restauração do HUD, preparação e descoberta

Data: 31/10/2026. Correção solicitada após teste do usuário em Android.

## Alterações

- A partida LAN passou a instanciar **`scenes/ui/game_hud.tscn`**, a mesma cena do modo local: topo compacto, veículo lateral, gaveta de carga, ferramentas de mapa e mão parcialmente recolhida no rodapé.
- O tabuleiro volta a ocupar a tela inteira. Saiu a lista lateral permanente de ações e o menu de abas do primeiro protótipo LAN.
- Ações ficam nos painéis com o tema original, agrupadas por contexto e paginadas. Cada página apresenta até quatro opções, ou duas quando há confronto com arte dos adversários. Isso elimina as listas verticais longas que dificultavam o toque.
- Cartas da mão usam as artes originais. A consulta oferece **Usar / instalar** e encaminha às opções legais da carta. Cartas pendentes continuam protegidas pelo verso e pela identificação do jogador da conexão.
- O menu de conexão virou uma tela central própria, com criar partida e salas encontradas lado a lado. Porta e IP ficaram na entrada manual opcional. O teclado virtual recolhe as colunas auxiliares enquanto o nome é editado.
- Descoberta agora envia consultas periódicas; o anfitrião responde diretamente à porta do cliente. A lista se atualiza quando salas entram, mudam ou expiram. Tocar em uma sala conecta sem digitar IP. Os anúncios periódicos continuam como complemento.
- Cada listener cliente usa uma porta efêmera. O anfitrião escuta descoberta em 24877 e anuncia sua porta de jogo, que pode ser diferente da padrão. Respostas não carregam dados privados.
- Versão de pacote: **0.2.1-lan-ui**, código Android **3**. O pacote TV passou a comprimir as bibliotecas nativas para reduzir o tamanho do APK.

## Verificação

- `lan_ui_smoke.gd`: 30 verificações, zero falhas; verifica a cena HUD compartilhada, mapa em tela inteira, página de ações sem rolagem vertical, admissão de TV, cartas, prévia e confronto.
- `lan_session_smoke.gd`: 63 verificações, zero falhas.
- `lan_campaign_smoke.gd`: 197 verificações, zero falhas.
- Harness ENet com cinco processos: um dos clientes encontrou o endereço por consulta de descoberta (`LAN_DISCOVERY_QUERY_OK`); jogadores e TV continuaram conectando/reconectando com os dados filtrados.
- Regressão: tela inicial, layout móvel com métricas S23, combate e revelações passaram.
- Capturas renderizadas Windows: `.tools/lan-connection-1280x720.png`, `.tools/lan-player-1280x720.png` e `.tools/lan-player-960x720.png`.

Essas verificações não substituem o toque e a descoberta por Wi-Fi nos aparelhos. Não houve modificação das regras, saves ou autorização dos comandos para acomodar a apresentação.

## Instalação na TV Philips

O usuário informou Philips de 50 polegadas e preferiu adiar a consulta do modelo completo, sistema e mensagem de erro. O APK anterior teve assinatura v2 e manifest inspecionados; não foi identificada uma causa de instalação a partir dessa informação parcial. O novo pacote é menor e mantém as ABIs ARM64/ARMv7, launcher TV e touchscreen opcional. A compatibilidade específica da TV e a resolução do erro de instalação continuam pendentes; não foram declaradas corrigidas.

Instalar os dois pacotes novos da mesma geração. A descoberta e o handshake recusam builds de regras/protocolo incompatíveis.

## Indicador de etapas do turno

HUD local e LAN exibem Preparação → Ação → Encerramento no topo central. Etapa atual em âmbar, concluídas em verde e próximas em cinza; ícones também distinguem os estados. A indicação deriva de started/actions e das resoluções pendentes, sem impor ordem à viagem nem alterar regras. Reinicia na passagem de turno. Validação visual Windows; Android físico pendente.

## Controle Android TV

Setas e OK navegam pelos controles nativos, com contorno âmbar no foco. A tela de conexão começa em Buscar novamente; a navegação vertical é circular e mantém a seleção ao atualizar salas. Voltar fecha primeiro a janela aberta e só então oferece sair da sala. Teste tv_remote_smoke.gd simula setas, Enter, popup e atualização de salas; zero falhas no Windows. Controle físico Android TV ainda pendente.
