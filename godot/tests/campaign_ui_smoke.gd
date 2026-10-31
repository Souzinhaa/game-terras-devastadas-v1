extends SceneTree
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); failures += 1

func find_button(node: Node, text: String) -> Button:
	if node is Button and text in node.text: return node
	for child in node.get_children():
		var found = find_button(child, text)
		if found: return found
	return null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(0.4).timeout
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	app.game.player().hand.clear()
	app.game.player().hand_instances.clear()
	app.handoff.hide()
	app.setup.hide()
	app.start_screen.hide()
	app.reveal.hide()
	app.preferences.reduced_motion = true
	app.reveal.reduced_motion = true
	app.refresh()
	await process_frame
	app.campaign_panel.administration()
	await process_frame
	await process_frame
	check(find_button(app.popup, "Comprar melhoria") != null, "Improvement purchase reachable")
	check(find_button(app.popup, "Moto") != null, "Upgrade choices reachable")
	check(find_button(app.popup, "Reparo complexo") != null, "Complex repair reachable")
	check(app.popup.panel.get_global_rect().end.x <= app.size.x + 1, "Administration stays within viewport")
	root.get_texture().get_image().save_png("res://../.tools/campaign-administration.png")
	app.campaign_panel.scoreboard()
	await process_frame
	check(app.popup.visible, "Scoreboard visible")
	app.game.state.events = ["V10"]
	app.game.campaign.travel_event()
	app.popup.hide()
	app.campaign_panel.pending_signature = ""
	app.refresh()
	await process_frame
	await process_frame
	var identity = find_button(app.popup, "Sou ")
	check(identity != null, "Event hidden behind recipient identity")
	if identity: identity.pressed.emit()
	await process_frame
	var flip = find_button(app.popup, "Virar carta")
	check(flip != null, "Event begins hidden")
	if flip: flip.pressed.emit()
	await process_frame
	await process_frame
	var choose = find_button(app.popup, "Receber ")
	check(choose != null, "Revealed event offers resource choice")
	root.get_texture().get_image().save_png("res://../.tools/campaign-event.png")
	if choose: choose.pressed.emit()
	await process_frame
	check(app.game.state.choice.is_empty(), "UI resolves event once")
	app.popup.hide()
	app.game.state.events = ["V12"]
	app.game.campaign.travel_event()
	app.game.act("cardChoice")
	app.game.act("cardChoice")
	app.campaign_panel.pending_signature = ""
	app.refresh()
	await process_frame
	await process_frame
	check(find_button(app.popup, "participar") != null, "Race entry reachable")
	root.get_texture().get_image().save_png("res://../.tools/campaign-race.png")
	# Private overflow must return the device to the active player afterwards.
	app.game.state.race = {}
	app.popup.hide()
	var recipient = app.game.state.players[1]
	recipient.hand.clear()
	recipient.hand_instances.clear()
	for id in ["G08", "G09", "G10", "G11", "G12", "G13"]: app.game.gain_card(recipient, id)
	app.campaign_panel.private_owner = -1
	app.campaign_panel.pending_signature = ""
	app.refresh()
	await process_frame
	await process_frame
	var receive = find_button(app.popup, "Sou ")
	check(receive != null and not app.hand.visible, "Off-turn excess asks recipient identity and hides active hand")
	if receive: receive.pressed.emit()
	await process_frame
	check(app.reveal.visible and app.reveal_owner == int(recipient.id), "Pending cards revealed to the overflow recipient")
	for i in range(6):
		var pending_card = app.game.pending_reveal(int(recipient.id))
		if pending_card.is_empty(): break
		check(app.game.act("acknowledgeCard", {"player_id": int(recipient.id), "ticket": pending_card.ticket}).is_empty(), "Private overflow acknowledgement")
	app.reveal.hide()
	app.refresh()
	await process_frame
	await process_frame
	var discard = find_button(app.popup, "Descartar ")
	check(discard != null and not discard.disabled, "Off-turn discard reachable")
	if discard: discard.pressed.emit()
	await process_frame
	await process_frame
	check(app.handoff.visible and not app.hand.visible, "Recipient returns to opaque active-player handoff")
	app.handoff.hide()
	app.popup.hide()
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	for player in app.game.state.players:
		player.hand.clear()
		player.hand_instances.clear()
	app.game.player().stock.scrap = 3
	app.game.state.improvements = ["E02"]
	check(app.game.act("buyImprovement").is_empty(), "Acquire test weapon")
	check(app.game.act("acknowledgeCard", {"ticket": app.game.pending_reveal().ticket}).is_empty(), "Reveal test weapon")
	check(app.game.act("install", {"index": 0}).is_empty(), "Install test weapon")
	app.game.player().stock.ammo = 1
	for id in app.game.state.territories:
		var t = app.game.state.territories[id]
		if t.city == app.game.player().city and int(t.owner) < 0:
			t.hostile = "H01"
			t.resistance = 3
			check(app.game.act("conquer", {"territory": id}).is_empty(), "Open equipped combat")
			break
	check(app.game.act("combatRoll").is_empty(), "Fixed weapon first")
	check(app.game.act("combatEquipmentAttack", {"slot": 0}).is_empty(), "Select additional weapon")
	app.refresh()
	await process_frame
	await process_frame
	check(find_button(app.combat_view, "Rolar dado de ataque") != null and app.game.state.combat.weapon_damage == 3, "Equipped attack ready in UI with actual damage")
	root.get_texture().get_image().save_png("res://../.tools/campaign-equipped-combat.png")
	app.game.new_game(["Ana", "Bruno", "Caio"], 42)
	app.game.state.started = true
	app.game.state.pending_reveals.clear()
	for player in app.game.state.players:
		player.hand.clear()
		player.hand_instances.clear()
	var winner = app.game.player()
	var defeated = app.game.state.players.filter(func(player): return int(player.id) != int(winner.id))[0]
	defeated.city = winner.city
	defeated.model = "suv"
	defeated.integrity = 1
	defeated.stock.scrap = 3
	app.game.gain_card(defeated, "G01")
	app.game.state.pending_reveals.clear()
	check(app.game.act("duel", {"defender": int(defeated.id)}).is_empty(), "Start reward UI fixture")
	app.game.state.combat.right.health = 0
	app.game.combat_rules.finish_combat(0)
	app.combat_view.reward_reveal_ticket = -1
	app.combat_view.reduce_motion = true
	app.handoff.hide()
	app.start_screen.hide()
	app.refresh()
	await process_frame
	await process_frame
	check(not app.reveal.visible, "Reward card stays private until winner identifies")
	var prize_receive = find_button(app.combat_view, "receber carta")
	check(prize_receive != null, "Winner can receive random card")
	if prize_receive: prize_receive.pressed.emit()
	await process_frame
	check(app.reveal.visible, "Winner identification opens acquired card")
	app.reveal.reduced_motion = true
	app.reveal.flip_button.pressed.emit()
	app.reveal.collect_button.pressed.emit()
	await process_frame
	await process_frame
	var repair = find_button(app.combat_view, "Reparar e trocar")
	check(repair != null and not repair.disabled, "Captured category offers explicit repair choice")
	if repair: check(repair.get_global_rect().end.y <= app.size.y, "Vehicle choice is visible without scrolling past fighters")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/pvp-vehicle-choice.png")
	if repair: repair.pressed.emit()
	await process_frame
	check(winner.model == "suv" and winner.integrity == 4, "Repair button applies selected vehicle")
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(app.handoff.visible and not app.hand.visible, "Pause locks private UI")
	print("Campaign UI smoke: %d failures" % failures)
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
