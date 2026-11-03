extends SceneTree
var app: Control
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func face(value: int) -> void:
	for seed_value in range(20000):
		var next = (seed_value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) + 1 == value:
			app.game.state.seed = seed_value
			return

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(1.3).timeout
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	for p in app.game.state.players: p.hand.clear()
	app.refresh()
	await process_frame
	check(app.vehicle_portrait.texture.resource_path.ends_with("-lateral.png"), "Imagem lateral no resumo")
	check(not app.vehicle_panel.visible, "Painel grande começa recolhido")
	app.toggle_map_mode()
	check(not app.hud_margin.visible, "Mapa livre remove HUD")
	for c in app.game.cities:
		var point = app.board.city_position(c)
		check(Rect2(Vector2.ZERO, app.size).has_point(point), "Cidade enquadrada: " + c.name)
		check(not app.map_toggle.get_global_rect().has_point(point), "Cidade fora do controle: " + c.name)
		app.board.pick(point)
		check(app.board.selected == c.id or app.vehicle_details.visible, "Cidade ou veículo selecionável: " + c.name)
		app.vehicle_details.hide()
		app.popup.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/map-free-preview.png")
	app.toggle_map_mode()
	app.vehicle_portrait.drive(0.2, true)
	check(app.vehicle_portrait.texture is AtlasTexture and app.vehicle_portrait.driving_frames.size() == 24, "24 quadros andando, com recorte individual")
	await create_timer(0.3).timeout
	check(app.vehicle_portrait.texture == app.vehicle_portrait.idle_texture, "Retorna ao repouso")
	var territory = ""
	for id in app.game.state.territories:
		var t = app.game.state.territories[id]
		if t.city == app.game.player().city and int(t.owner) < 0:
			t.hostile = "H01"
			t.resistance = 1
			territory = id
			break
	app.game.player().hand = ["G01"]
	app.dispatch("conquer", {"territory": territory})
	check(app.combat_view.visible and app.game.state.combat.phase == "cards", "Combate abre pergunta de carta")
	check(app.combat_view.find_child("ReactionCards", true, false) == null, "Arte privada até dono abrir a reação")
	app.dispatch("combatReaction", {"player_id": int(app.game.player().id)})
	await process_frame
	check(app.combat_view.find_child("QuickReactionCards", true, false) != null and not app.combat_view.card_picker.visible, "Cartas podem ser usadas na arena sem cobrir o combate")
	app.combat_view.controls.find_child("ReopenReactionCards", true, false).pressed.emit()
	check(app.combat_view.images.size() == 2 and app.combat_view.health_bars.size() == 2, "Dois adversários e barras de vida")
	var choice = app.combat_view.find_child("ReactionCard_0", true, false) as Button
	check(choice != null, "Carta elegível aparece como escolha visual")
	if choice != null:
		var art = choice.find_child("CardArt", true, false) as TextureRect
		check(art != null and art.texture != null and art.texture.resource_path.ends_with("/" + app.card_definition("G01").image), "Arte corresponde à carta elegível")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/combat-cards-preview.png")
	check(app.combat_view.card_picker.visible, "Seleção abre em sobreposição independente")
	check(app.combat_view.card_picker.get_parent() == app.combat_view, "Seleção está fora do ScrollContainer")
	var picker_rect = app.combat_view.card_picker.get_global_rect()
	for card in app.combat_view.card_picker.find_children("ReactionCard_*", "Button", true, false):
		check(picker_rect.encloses(card.get_global_rect()), "Arte inteira visível sem rolar")
	var minimize = app.combat_view.card_picker.find_child("MinimizeReactionCards", true, false) as Button
	check(minimize != null and picker_rect.encloses(minimize.get_global_rect()), "Minimizar visível sem rolar")
	if minimize: minimize.pressed.emit()
	check(not app.combat_view.card_picker.visible and app.game.player().hand.size() == 1, "Minimizar preserva carta e decisão")
	var reopen = app.combat_view.controls.find_child("ReopenReactionCards", true, false) as Button
	if reopen: reopen.pressed.emit()
	check(app.combat_view.card_picker.visible, "Ver cartas reabre seleção")
	var original_hand = app.game.player().hand.duplicate()
	app.game.player().hand = ["G01", "G01", "G01", "G01", "G01", "G01"]
	var seed_before_picker = app.game.state.seed
	app.combat_view.sync()
	await process_frame
	await process_frame
	var page_one = app.combat_view.card_picker.find_children("ReactionCard_*", "Button", true, false).size()
	check(page_one > 0 and page_one < 6, "Muitas cartas usam páginas sem rolagem")
	for node in app.combat_view.card_picker.find_children("*", "Button", true, false):
		if node.text == "Próxima":
			node.pressed.emit()
			break
	await process_frame
	await process_frame
	check(app.combat_view.picker_page == 1, "Próxima página acessível")
	for card in app.combat_view.card_picker.find_children("ReactionCard_*", "Button", true, false):
		check(picker_rect.encloses(card.get_global_rect()), "Página cabe inteira na tela")
	check(app.game.state.seed == seed_before_picker and app.game.player().hand.size() == 6, "Paginação não gasta carta ou RNG")
	app.game.player().hand = original_hand
	app.combat_view.sync()
	app.dispatch("combatCard", {"index": -1})
	face(6)
	app.reveal.reduced_motion = false
	app.dispatch("combatRoll")
	check(app.combat_view.busy, "Rola dado com animação")
	var seed_after = app.game.state.seed
	app.dispatch("combatRoll")
	check(app.game.state.seed == seed_after, "Cliques repetidos não repetem dano")
	await create_timer(0.2).timeout
	check(app.combat_view.arena.is_ancestor_of(app.combat_view.dice), "Dado continua entre combatentes durante rolagem")
	check(app.combat_view.health_bars[1].value == float(app.game.state.combat.last.before), "Vida preservada durante rolagem")
	await RenderingServer.frame_post_draw
	check(app.combat_view.dice.get_global_rect().get_center().x > app.size.x * 0.35, "Dado não aparece no canto esquerdo")
	root.get_texture().get_image().save_png("res://../.tools/combat-rolling-fixed.png")
	await create_timer(0.37).timeout
	check(app.combat_view.dice.value == 6 and app.combat_view.health_bars[1].value == float(app.game.state.combat.last.before), "Resultado do dado precede perda de vida")
	await create_timer(0.65).timeout
	check(not app.combat_view.busy and app.combat_view.dice.value == 6, "Exibe dado real no fim")
	check(app.combat_view.find_child("CombatReward", true, false) != null, "Resultado e itens adquiridos")
	check(not app.combat_view.arena.visible and not app.combat_view.feedback.visible, "Resultado prioriza itens sem repetir arena e dado")
	for resource: String in app.game.state.combat.reward:
		var row: Node = app.combat_view.find_child("Reward_" + resource, true, false)
		check(row != null and row.get_node("Icon").texture != null, "Recompensa com ícone: " + resource)
	var reward_state: String = JSON.stringify(app.game.state)
	app.combat_view.sync()
	check(JSON.stringify(app.game.state) == reward_state, "Reabrir resultado não concede os itens novamente")
	await RenderingServer.frame_post_draw
	for caption: Node in app.combat_view.find_child("RewardItems", true, false).find_children("*", "Label", true, false):
		check(caption.size.x >= 150 and caption.size.y < 80, "Nome do recurso legível sem quebrar por letra")
	root.get_texture().get_image().save_png("res://../.tools/combat-reward-preview.png")
	while app.game.cargo() > int(app.game.vehicle().capacity): app.dispatch("discardResource", {"resource": "scrap" if app.game.player().stock.scrap > 0 else "fuel"})
	app.dispatch("combatClose")
	check(not app.combat_view.visible, "Resultado fechado volta ao mapa")
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	for p in app.game.state.players: p.hand.clear()
	var reacting = app.game.state.players[1]
	app.game.gain_card(reacting, "G04")
	app.dispatch("conquer", {"territory": territory})
	app.dispatch("combatReaction", {"player_id": int(reacting.id)})
	check(app.reveal.visible and app.reveal_owner == int(reacting.id), "Reação fora do turno revela carta do dono")
	app.reveal.reduced_motion = true
	app.reveal.flip_button.pressed.emit()
	app.reveal.collect_button.pressed.emit()
	await process_frame
	check(app.game.pending_reveal(int(reacting.id)).is_empty(), "Confirmação fora do turno persistida")
	var opponent_choice = app.combat_view.find_child("ReactionCard_0", true, false) as Button
	check(opponent_choice != null, "Adversário escolhe por arte após revelar")
	if opponent_choice != null: opponent_choice.pressed.emit()
	check(app.combat_view.card_preview.visible and not reacting.used_general and reacting.hand.size() == 1, "Selecionar amplia sem consumir")
	check(app.combat_view.card_preview.z_index > app.combat_view.body.z_index, "Carta sobrepõe o combate")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/combat-card-confirm-preview.png")
	app.handle_back()
	check(not app.combat_view.card_preview.visible and reacting.hand.size() == 1, "Voltar cancela sem consumir")
	if opponent_choice != null: opponent_choice.pressed.emit()
	var confirm = app.combat_view.card_preview.find_child("ConfirmCardUse", true, false) as Button
	check(confirm != null, "Confirmação explícita de uso")
	if confirm != null: confirm.pressed.emit()
	check(int(reacting.id) in app.game.state.combat.get("round_generals", []) and reacting.hand.is_empty(), "Carta do adversário consome a cota da rodada")
	check(not app.combat_view.card_preview.visible, "Confirmação fecha a carta ampliada")
	# Turno do segundo jogador: compra só dele, reações não compram nem trocam a vez.
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.pending_reveals.clear()
	for index: int in range(app.game.state.players.size()):
		if app.game.state.players[index].name == "Ana": app.game.state.active = index
	for participant: Dictionary in app.game.state.players:
		participant.hand.clear()
		participant.hand_instances.clear()
		app.game.gain_card(participant, "G01")
	app.game.state.pending_reveals.clear()
	var bruno: Dictionary = app.game.combat_rules.player_by_id(0)
	var ana: Dictionary = app.game.combat_rules.player_by_id(1)
	var bruno_cards: int = bruno.hand.size()
	var ana_cards: int = ana.hand.size()
	check(app.game.act("start").is_empty(), "Segundo jogador inicia seu turno")
	check(ana.hand.size() == ana_cards + 1 and bruno.hand.size() == bruno_cards, "Compra inicial pertence apenas ao jogador ativo")
	while not app.game.pending_reveal().is_empty():
		var pending: Dictionary = app.game.pending_reveal()
		check(app.game.act("acknowledgeCard", {"ticket": pending.ticket, "player_id": ana.id}).is_empty(), "Jogador ativo confirma sua compra")
	for id: String in app.game.state.territories:
		var sector: Dictionary = app.game.state.territories[id]
		if sector.city == ana.city and int(sector.owner) < 0:
			territory = id
			break
	app.reveal.hide()
	app.combat_view.reaction_open = false
	app.dispatch("conquer", {"territory": territory})
	app.combat_view.reaction_open = false
	app.dispatch("combatReaction", {"player_id": bruno.id})
	check(not app.combat_view.reaction_open, "Identidade diferente da reação atual não abre cartas privadas")
	app.dispatch("combatCard", {"index": -1})
	check(app.game.combat_rules.reaction_player().id == bruno.id, "Bruno só participa na janela de reação")
	var before_reaction: String = JSON.stringify(app.game.state)
	app.dispatch("combatReaction", {"player_id": bruno.id})
	check(app.game.player().id == ana.id and JSON.stringify(app.game.state) == before_reaction, "Abrir cartas de Bruno não compra, não muda RNG e mantém a vez de Ana")
	check(not app.reveal.visible, "Cartas conhecidas de reação não abrem animação de compra")
	print("Combat UI smoke: %d falhas; cartas, dado, recompensa, 12 cidades e veículo." % failures)
	quit(0 if failures == 0 else 1)
