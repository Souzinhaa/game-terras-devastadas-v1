# Contexto para o Codex — fundo animado da tela inicial

**Atualização de integração (03/11/2026):** o pacote foi integrado ao Godot; consultar `godot/docs/START_SCREEN_BACKGROUND.md`. A revisão em `revisao/` corrige o sentido do cenário e substitui o hostil deslizante por oito poses de caminhada. O runtime usa `fundo_godot_v2.ogv`; os arquivos originais abaixo permanecem preservados como fonte. As afirmações de ausência de integração no restante deste documento descrevem o estado original do pacote.

## Objetivo e escopo
Integrar este pacote na tela inicial existente de Terras Devastadas, atrás do título e dos botões. Referência: título à esquerda e painel de menu à direita. Preserve as ações Continuar partida, Nova partida, Multiplayer LAN, Configurações, Como jogar e Sair, bem como salvamentos, rede e regras. Remova apenas o carro decorativo estático anterior, pois o vídeo já contém o carro.

A entrega é uma animação 2D por composição de sprites, não um vídeo 3D. As artes são ilustradas; os efeitos sonoros são sintetizados, sem vozes ou música. Não existe integração executada no repositório do jogo neste pacote.

## Arquivos principais
- `video/fundo_godot.ogv`: Ogg Theora com áudio Vorbis sincronizado; escolha principal no Godot.
- `video/fundo_com_audio.mp4`: vídeo H.264 com áudio AAC para visualizar ou usar em plataformas compatíveis.
- `video/fundo_sem_audio.mp4`: imagem em movimento sem áudio.
- `previa.mp4`: prévia menor, 640 × 360.
- `audio/mix_sincronizado.wav`: sequência sonora completa, 18 segundos, PCM mono, 44.100 Hz, 16 bits.
- `audio/mix_sincronizado.ogg`: a mesma sequência comprimida em Vorbis.
- `audio/motor_loop.wav`, `audio/vento_loop.wav`: camadas isoladas de 3 segundos para reaproveitamento; fade nas bordas.
- `audio/freada.wav`, `audio/barricada_impacto.wav`, `audio/hostil_impacto.wav`: efeitos avulsos, não devem repetir em loop.
- `assets/fallback.jpg`: quadro estático para modo de movimento reduzido ou falha de vídeo.
- `assets/`: cenário, barricada, hostil e 24 quadros do carro para reutilização.
- `source/build.py`: script de produção como referência; depende das artes originais e dos quadros do pacote anterior no workspace de criação. Os arquivos finais deste ZIP são autossuficientes para reprodução. O script não é dependência do jogo.
- `godot/MenuBackground.tscn` e `.gd`: cena auxiliar de integração. Caminhos esperam que este pacote seja copiado para `res://assets/menu_background/`.

## Sequência — 18 segundos, 1280 × 720, 24 fps
| Tempo | Ação |
|---|---|
| 0–3 s | Carro em movimento na estrada. |
| 3–4 s | Freada e redução do deslocamento do cenário. |
| 4–5 s | Carro parado diante da barricada. |
| 5–6 s | Arrancada em direção à barricada. |
| 6 s | Impacto, fragmentos e poeira. |
| 6–10 s | Carro atravessa e retoma o trajeto. |
| 10–13 s | Hostil aparece à frente. |
| 13 s | Atropelamento estilizado: hostil lançado para fora da cena, coberto por poeira, sem sangue. |
| 14–18 s | Carro segue pela estrada e retorna ao estado inicial. |

O cenário percorre um panorama espelhado completo para voltar à posição inicial. O reinício real depende do player e da plataforma; verificar no dispositivo final. Não colocar tela preta, vinheta de abertura ou fade de imagem entre repetições.

## Integração no Godot 4
1. Inspecione a cena e os scripts atuais da tela inicial antes de editar. Não presuma caminhos de nós.
2. Copie as pastas do pacote para `res://assets/menu_background/`.
3. Instancie `godot/MenuBackground.tscn` como primeiro filho visual do Control raiz do menu, atrás do título e painel existentes. O Control pai deve ocupar a tela.
4. A cena usa VideoStreamPlayer com `expand`, `autoplay`, `loop` e `mouse_filter = IGNORE`. Seu script dimensiona o vídeo por cobertura, mantendo 16:9 sem deformação. Em proporções diferentes haverá recorte; prefira manter a versão horizontal do menu ou ajustar a composição para que a ação não fique encoberta.
5. O vídeo já contém todos os sons sincronizados. NÃO reproduza simultaneamente o mix externo nem dispare novamente os impactos. Para controle separado de SFX será necessária uma variante OGV sem áudio e uma implementação sincronizada própria; não use o MP4 como substituto nativo do Theora.
6. O volume inicial do exemplo é -17 dB. Respeite as configurações existentes de volume e mudo. Use o bus de áudio do menu se ele existir. Pare o vídeo e o som ao sair para a partida, evitando instâncias duplicadas ao retornar.
7. Uma camada preta discreta está incluída para contraste. Ajuste sua opacidade conforme a legibilidade do menu, sem esconder a ação na faixa inferior. Não incorporar título nem botões ao vídeo.
8. Para movimento reduzido, substitua o vídeo por `assets/fallback.jpg` e desligue o áudio. A cena de exemplo expõe `reduced_motion` para isso.
9. Confirme que o OGV faz parte da exportação para Android. Teste desempenho em aparelho real. A cena auxiliar é uma base de integração e não foi executada no projeto do usuário.

## Critérios de aceite
- Vídeo atrás da interface, sem interceptar mouse, toque ou foco.
- Botões e atalhos antigos funcionando; nenhum salvamento alterado.
- Sem carro estático duplicado.
- Barricada destruída e hostil atingido nos tempos definidos.
- Som único, sem duplicação ou reprodução fora da tela inicial.
- Volume e mudo respeitados; modo estático disponível.
- Imagem sem deformação em 16:9, 16:10 e tela redimensionada; revisar recorte em retrato.
- Loop revisado por pelo menos três repetições no editor e no aparelho exportado.

## Referência técnica
Documentação oficial: https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html
O suporte nativo de vídeo do Godot utiliza Ogg Theora; o MP4 acompanha o pacote como alternativa de reprodução e prévia.
