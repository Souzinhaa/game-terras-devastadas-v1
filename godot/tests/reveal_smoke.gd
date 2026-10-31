extends SceneTree
var app: Control
var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func reveal_current(animated: bool) -> void:
	var ticket = int(app.game.pending_reveal().ticket)
	var pending_count = app.game.state.pending_reveals.size()
	var card_id = app.game.pending_reveal().card_id
	check(app.reveal.visible and app.reveal.phase == "waiting", "Verso aguarda toque")
	check(app.reveal.art.texture == app.Reveal.back_for(card_id), "Verso correto")
	check(app.reveal.collect_button.disabled, "Não recolhe antes de revelar")
	check(app.reveal.flip_button.tooltip_text == "Carta recebida. Toque para revelar.", "Tooltip não revela nome")
	app.reveal.reduced_motion = not animated
	app.reveal.flip_button.pressed.emit()
	app.reveal.flip_button.pressed.emit()
	if animated: await create_timer(0.5).timeout
	check(app.reveal.phase == "revealed", "Frente revelada após toque")
	check(app.reveal.art.texture.resource_path == app.reveal.front_path, "Frente original preservada")
	check(not app.reveal.collect_button.disabled, "Pode recolher após virar")
	app.reveal.collect_button.pressed.emit()
	app.reveal.collect_button.pressed.emit()
	if animated: await create_timer(0.35).timeout
	await process_frame
	check(app.game.state.pending_reveals.size() == pending_count - 1, "Confirmação única")
	for pending in app.game.state.pending_reveals:
		check(int(pending.ticket) != ticket, "Ticket removido")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	if app.combat_view.busy: await create_timer(1.3).timeout
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.game.new_game(["Bruno", "Ana"], 42)
	app.refresh()
	await process_frame
	check(not app.game.act("start").is_empty(), "Carta inicial não pode ser ignorada")
	await reveal_current(true)
	app.dispatch("start")
	await process_frame
	check(not app.game.pending_reveal().is_empty(), "Compra do turno abre revelação")
	app.game.save_game()
	var loaded = app.Game.new()
	check(loaded.load_game().is_empty(), "Save de revelação carrega")
	check(JSON.stringify(loaded.pending_reveal()) == JSON.stringify(JSON.parse_string(JSON.stringify(app.game.pending_reveal()))), "Revelação pendente sobrevive à retomada")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/godot-reveal-back.png")
	await reveal_current(true)
	check(app.Reveal.back_for("E01") == app.Reveal.back_for("T01"), "E e T compartilham o mesmo verso")
	# Ganhos em lote usam o mesmo caminho, sem alterar a composição dos baralhos.
	var ids = ["G01", "E01", "T01", "R01"]
	for c in app.game.catalog:
		if c.id.begins_with("V"):
			ids.append(c.id)
			break
	for id in ids: app.game.gain_card(app.game.player(), id)
	app.refresh()
	await process_frame
	for id in ids:
		check(app.game.pending_reveal().card_id == id, "Fila preserva ordem: " + id)
		await reveal_current(false)
	check(not app.reveal.visible, "Fila concluída fecha apresentação")
	check(app.game.pending_reveal().is_empty(), "Nenhuma aquisição sem confirmação")
	# Limpar apenas a mão de teste para permitir passagem sem excedente.
	app.game.player().hand.resize(2)
	app.game.player().hand_instances.resize(2)
	app.dispatch("end")
	await process_frame
	check(app.reveal.visible and app.reveal.recipient.text.begins_with(app.game.player().name), "Carta inicial pertence ao próximo jogador")
	await reveal_current(false)
	print("Reveal smoke: %d falhas; inicial, compra, fila, cinco tipos, retomada, cliques repetidos e movimento reduzido." % failures)
	# O último pressed sintético também dispara o som; aguardar o mixer liberar
	# o playback antes de encerrar o processo de teste.
	app.ui_audio.stop()
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)
