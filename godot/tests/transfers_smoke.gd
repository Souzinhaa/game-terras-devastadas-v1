extends SceneTree
var failures = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(1.3).timeout
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	var game = app.game
	game.new_game(["A", "B"], 42)
	game.state.pending_reveals.clear()
	game.state.started = true
	var p = game.player()
	p.hand = ["G03", "G07"]
	p.hand_instances = [game.campaign.instance("G03"), game.campaign.instance("G07")]
	var own = ""
	for id in game.state.territories:
		var t = game.state.territories[id]
		if t.city == p.city and int(t.owner) == int(p.id): own = id
	var depot = game.state.territories[own]
	depot.stock.fuel = 6
	p.stock.scrap = int(game.vehicle().capacity)
	p.fuel = int(game.vehicle().tank) - 2
	var rng = game.state.get("rng", 0)
	var actions = game.state.actions
	check(game.act("refuelDepot", {"territory": own}).is_empty(), "Direct fill works with full cargo")
	check(p.fuel == game.vehicle().tank and depot.stock.fuel == 4 and game.cargo() == game.vehicle().capacity, "Direct fill conserves fuel and bypasses cargo")
	check(game.act("deposit", {"territory": own, "resource": "scrap"}).is_empty(), "Deposit")
	check(depot.stock.scrap == 1 and game.cargo() == int(game.vehicle().capacity) - 1, "Deposit direction")
	check(game.act("withdraw", {"territory": own, "resource": "scrap"}).is_empty(), "Withdraw")
	check(depot.stock.scrap == 0 and game.cargo() == game.vehicle().capacity, "Withdraw direction")
	depot.owner = 99
	check(not game.act("refuelDepot", {"territory": own}).is_empty(), "Foreign depot blocked")
	depot.owner = p.id
	var local_city = depot.city
	depot.city = "remote"
	check(not game.act("deposit", {"territory": own, "resource": "scrap"}).is_empty(), "Remote blocked")
	depot.city = local_city
	depot.stock.fuel = 10
	check(not game.act("deposit", {"territory": own, "resource": "scrap"}).is_empty(), "Depot capacity")
	p.stock.fuel = 3
	p.fuel = int(game.vehicle().tank) - 2
	game.state.combat = {"phase": "ready"}
	check(not game.act("refuelExcess").is_empty(), "Cannot refuel mid combat")
	game.state.combat = {"phase": "finished"}
	check(game.act("refuelExcess").is_empty(), "Recover excess in combat result")
	check(p.stock.fuel == 1 and p.fuel == game.vehicle().tank and game.cargo() == int(game.vehicle().capacity) + 1, "Only what fits enters tank")
	check(game.act("discardResource", {"resource": "fuel"}).is_empty(), "Discard remaining excess")
	check(game.cargo() == game.vehicle().capacity, "Excess resolved")
	game.state.combat = {}
	check(game.state.actions == actions and game.state.get("rng", 0) == rng, "Transfers preserve actions and RNG")
	game.save_game()
	check(game.load_game().is_empty(), "Roundtrip save")
	app.refresh()
	for resource in game.RESOURCES:
		check(app.cargo_amounts[resource].text == str(int(game.player().stock[resource])), "Integer quantity after JSON load")
	app.show_resource_discard()
	var icons = 0
	for node in app.popup.find_children("*", "Button", true, false):
		if node.icon != null: icons += 1
	check(icons > 0, "Visual resource choice")
	app.show_hand_list()
	icons = 0
	for node in app.popup.find_children("*", "Button", true, false):
		if node.icon != null: icons += 1
	check(icons == 2, "Card choice contains artwork")
	app.show_card(0)
	for node in app.card_center.find_children("*", "Button", true, false):
		if node.text == "Descartar": node.pressed.emit()
	check(app.popup.find_children("*", "TextureRect", true, false).size() > 0, "Discard confirmation contains card")
	app.show_sectors()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/transfers-preview.png")
	p = game.player()
	p.fuel = 2
	p.stock.fuel = 1
	p.stock.scrap = 0
	app.refresh()
	check(app.excess_refuel_button.disabled, "Excess button disabled when cargo fits")
	check(not app.refuel_button.disabled, "Normal refuel enabled with reserve and tank space")
	p.stock.scrap = int(game.vehicle().capacity)
	app.refresh()
	check(not app.excess_refuel_button.disabled, "Excess button enabled when transfer is legal")
	check(game.act("refuelExcess").is_empty(), "Enabled excess transfer succeeds")
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled, "Buttons update immediately after fuel is consumed")
	p.stock.fuel = 1
	p.fuel = game.vehicle().tank
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled, "Full tank disables both fuel actions")
	p.fuel = 2
	game.state.started = false
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled and app.repair_button.disabled and app.discard_resource_button.disabled, "Inventory actions disabled before turn")
	game.state.started = true
	p.penalty = true
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled, "Recovery disables refueling")
	p.penalty = false
	game.gain_card(p, "G03")
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled and app.discard_resource_button.disabled, "Pending reveal disables inventory actions")
	game.state.pending_reveals.clear()
	p.stock.scrap = 0
	for id in game.state.territories:
		var sector = game.state.territories[id]
		if sector.city == p.city and int(sector.owner) != int(p.id):
			check(game.act("conquer", {"territory": id}).is_empty(), "Start real combat for button validation")
			break
	check(not game.state.combat.is_empty(), "Combat fixture initialized")
	app.refresh()
	check(app.excess_refuel_button.disabled and app.refuel_button.disabled, "Active combat disables fuel actions")
	game.state.combat = {}
	p.stock.fuel = 0
	app.refresh()
	app.popup.hide()
	app.reveal.hide()
	app.vehicle_panel.show()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/disabled-inventory-preview.png")
	print("Transfers smoke: %d failures" % failures)
	app.queue_free()
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
