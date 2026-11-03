# Tela inicial com fundo animado

03/11/2026 · integração do contrato `assets/tela_inicial/context.md`, com correção posterior de movimento solicitada pelo usuário.

O menu usa `assets/menu_background/godot/MenuBackground.tscn` atrás dos controles. Título à esquerda e seis ações em duas colunas no alto à direita deixam a estrada inferior visível. Removido o Hatch decorativo estático e o texto promocional redundante; o carro já faz parte da animação. Continuar, nova partida, LAN, configurações, ajuda e sair preservam os sinais/fluxos existentes.

O vídeo nativo é Theora/Vorbis com áudio embutido, 18 s/720p/24 fps. O único som dessa animação vem do vídeo, no bus SFX, com -17 dB no volume padrão e ajuste pelo Volume dos efeitos. A música mantém seu controle independente. Zero silencia o vídeo sem parar a imagem. Movimento reduzido ou falha usa o poster sem áudio. Ocultar o menu para a partida para a reprodução; sair para a LAN destrói o player; pausa suspende imagem/áudio e retomar não cria outra instância. Não se usam MP4 ou efeitos avulsos no runtime.

## Correção da animação

O arquivo original deslocava o cenário para a esquerda, no mesmo sentido da frente do carro, dando impressão de marcha à ré. O script de produção também apenas movia a figura estática do hostil, com uma oscilação pequena, sem passos.

A composição V2 move os marcos do cenário para a direita. O Hatch mantém os 24 quadros existentes; após a barricada, volta lentamente ao enquadramento sem ultrapassar o movimento da estrada. A produção verifica matematicamente que `delta_carro - delta_cenário <= 0` em todos os frames; o valor máximo é zero durante a parada. O hostil usa oito poses de caminhada a 12 fps, em escala legível. Mantidos os impactos em 6/13 segundos e o WAV sincronizado original, sem sangue ou nova sequência sonora.

Arquivos de produção: `assets/tela_inicial/revisao/build_v2.py`, `hostil_walk.png` e `output/motion-check.json`. A [prévia V2](../../assets/tela_inicial/revisao/output/previa_v2.mp4) e os originais permanecem separados. Ferramentas Python/FFmpeg ficam fora do runtime. [Origem](../assets/menu_background/CREDITS.md).

## Verificação

- `start_screen_ui_smoke`: nova partida, cancelamento, ajuda, configurações e retomada privada, sem alteração da partida por navegar.
- `onboarding_ui_smoke`, `music_smoke` e `lan_ui_smoke` passaram na integração.
- `menu_background_smoke`: **59 verificações passaram com o vídeo V2**, três repetições completas, cobertura sem deformar em 16:9/16:10/892×445 e revisão do recorte 600×900; controles alcançáveis, faixa inferior livre, silêncio/movimento reduzido, pausa, fallback, input real e transição real para LAN liberando o vídeo. Audio driver Dummy; não é avaliação auditiva.
- Exportação com o preset Android para `.tools/menu-background-check.pck`, sem tocar nos APKs. `menu_export_smoke` carrega Theora, poster e cena diretamente do PCK; filtros incluem explicitamente o OGV. PCK não é APK.
- Sem mudanças de regras, motor, RNG, rede ou formato de save. TV/Tabuleiro continua abrindo sua conexão própria; não recebeu outra fonte de áudio.

Capturas: [menu](premium-ui/start-background.png), [caminhada](premium-ui/start-walking.png), [compacto](premium-ui/start-compact.png). São frames reais do renderer Windows.

Android/TV físico, avaliação auditiva, desempenho em celular, loop em aparelho e avaliação com pessoas permanecem pendentes. Após a integração, o APK do celular foi exportado a pedido do usuário: `0.0.4-ui-premium`, código 12, ARM64, em `terras-devastadas.apk` na raiz; assinatura, integridade, manifesto e presença do vídeo V2 verificados. [Manifesto](../builds/ui-premium-build-manifest.json).
