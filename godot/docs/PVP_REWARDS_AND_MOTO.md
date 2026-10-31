# Recebimento PvP e atributos da Moto

30/10/2026. Implementação nativa conforme decisões do usuário nesta sessão.

- Vitória contra carro recebe todos os recursos da carga e o combustível do tanque do derrotado, mais uma carta aleatória da mão, antes da regra de vidas descartar o restante. Instalados do derrotado são descartados, nunca transferidos. Carta passa por `gain_card`/`transfer_card`, com instância e revelação privada preservadas.
- Vencedor é o combatente vencedor real, inclusive o defensor fora do turno. Recursos entram na sua carga, sem abastecimento automático ou corte silencioso por capacidade. O resultado exige resolver excesso antes de fechar.
- Veículo derrotado de categoria diferente e superior ao Hatch oferece escolha persistida no combate. Aceitar custa 2 sucatas da carga, incluindo sucata recolhida; recupera estrutura 4, igual ao reparo de veículo encontrado já existente. Mantém o combustível capturado no tanque até a capacidade, o excedente na carga e move o combustível do tanque anterior para a carga. Equipamentos anteriores são descartados com aviso antes da confirmação. Recusar mantém o veículo atual e todos os recursos recebidos. Modelo igual entrega recursos e carta sem oferecer troca.
- Oferta e carta recebida sobrevivem a save/load. Confirmar duas vezes não repete a entrega nem o custo. Falta de sucata bloqueia recuperação e permite recusa.
- Moto: dano base do veículo 2, demais modelos 1. O bônus não altera o dado de ataque nem o dano próprio das armas adicionais. Equipamentos instalados na Moto não ocupam carga, inclusive na validação de instalação; continuam sujeitos aos espaços e demais custos. Sair da Moto restaura o peso normal.
- Hostis: os 12 perfis foram testados após a reclamação; o delta real de sucata/combustível na carga bate com a recompensa, respeitando 2–3/3–4/4–5 por dificuldade. Não foi reproduzida falta de entrega no motor atual. Acrescentados registro explícito no histórico, destino da recompensa no resultado e aviso de que combustível na carga não é tanque. Não foram concedidos itens retroativos sem evidência.

## Verificação e limites

`pvp_rewards.gd`: quatro modelos capturados, custo, recusa, falta de sucata, mesmo modelo, defensor vencedor, carta/instâncias, carga/tanque conservados, reload e repetição. `combat_smoke.gd`: 12 hostis e deltas reais. `campaign_ui_smoke.gd`: identificação do vencedor antes da carta e escolha de reparo acionável. Perfis de teste isolados; capturas em `.tools/pvp-vehicle-choice.png`. Testes Windows não comprovam Android físico.

O runtime React permanece referência histórica e ainda usa as regras anteriores de destruição PvP e carga/dano da Moto. Os contratos compartilhados atuais não incluem essas regras; não declarar paridade integral. O contrato em `rules.md` foi atualizado para o pedido do usuário.
