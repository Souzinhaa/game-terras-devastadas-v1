extends Control
## Tabuleiro público: acompanha fatos da projeção, sem capacidades de jogador.
const TurnSteps = preload("res://scripts/turn_steps.gd")
const Feedback = preload("res://scripts/ui_feedback.gd")
const Dice = preload("res://scripts/dice.gd")
const COLORS = [Color("ed8e42"), Color("51c9ef"), Color("b68be2"), Color("c4d27b")]
var app: Control
var top: PanelContainer
var heading: Label
var connection: Label
var steps: PanelContainer
var scorebar: PanelContainer
var score_row: HBoxContainer
var score_buttons: Dictionary = {}
var score_values: Dictionary = {}
var encounter: PanelContainer
var encounter_scroll: ScrollContainer
var encounter_body: VBoxContainer
var encounter_signature: String = ""
var previous_values: Dictionary = {}
var banner: PanelContainer
var banner_text: Label
var motion_button: Button
var latest: Dictionary = {}
var context_id: String = ""
var last_revision: int = -1
var banner_tween: Tween
var public_arena: Control
var race_board: Control
var activity_line: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top = PanelContainer.new()
	top.name = "TVTopBar"
	add_child(top)
	var column: VBoxContainer = VBoxContainer.new()
	top.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	heading = app.label("TERRAS DEVASTADAS · TABULEIRO", row, 25)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.clip_text = true
	heading.custom_minimum_size.x = 100
	app.button("Cidades", app.show_city_menu, row)
	app.button("Placar", show_scoreboard, row)
	motion_button = app.button("Animações", toggle_motion, row)
	app.button("Música", app.show_music_settings, row)
	app.button("Sair", app.leave_screen, row)
	for control: Node in row.get_children():
		if control is Button:
			control.autowrap_mode = TextServer.AUTOWRAP_OFF
			control.clip_text = false
			control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	steps = TurnSteps.new()
	steps.name = "TurnSteps"
	column.add_child(steps)
	connection = app.label("", column, 18)
	connection.hide()
	scorebar = PanelContainer.new()
	scorebar.name = "TVCompactScoreboard"
	add_child(scorebar)
	score_row = HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 12)
	scorebar.add_child(score_row)
	encounter = PanelContainer.new()
	encounter.name = "TVEncounter"
	add_child(encounter)
	encounter_scroll = ScrollContainer.new()
	encounter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	encounter_scroll.custom_minimum_size.y = 80
	encounter_scroll.focus_mode = Control.FOCUS_ALL
	encounter_scroll.tooltip_text = "Detalhes públicos · use ↑/↓ para rolar; nas extremidades, navegue para outro controle."
	encounter_scroll.gui_input.connect(scroll_encounter)
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("71d4d8")
	focus.set_border_width_all(2)
	encounter_scroll.add_theme_stylebox_override("focus", focus)
	encounter.add_child(encounter_scroll)
	encounter_body = VBoxContainer.new()
	encounter_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_body.add_theme_constant_override("separation", 12)
	encounter_scroll.add_child(encounter_body)
	public_arena = preload("res://scripts/combat_view.gd").new()
	public_arena.public_only = true
	public_arena.custom_minimum_size.y = 380
	encounter_body.add_child(public_arena)
	race_board = preload("res://scripts/race_board.gd").new()
	encounter_body.add_child(race_board)
	encounter.hide()
	banner = PanelContainer.new()
	banner.name = "TVActionBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	banner_text = app.label("", banner, 23)
	banner_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.hide()
	activity_line = app.label("", self, 18)
	activity_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(fit)
	fit()

func fit() -> void:
	if not is_instance_valid(top): return
	var inset: float = clampf(size.x * 0.03, 24, 48)
	var top_height: float = 164 if connection.visible else 140
	top.position = Vector2(inset, 24)
	top.size = Vector2(maxf(320, size.x - inset * 2), top_height)
	scorebar.position = Vector2(inset, size.y - 136)
	scorebar.size = Vector2(top.size.x, 112)
	activity_line.position = Vector2(inset, size.y - 198)
	activity_line.size = Vector2(top.size.x, 58)
	var detail_width: float = clampf(size.x * 0.27, 280, 390)
	if not latest.get("combat", {}).is_empty() or not latest.get("race", {}).is_empty(): detail_width = minf(size.x - inset * 2, maxf(540, size.x * 0.62))
	encounter.position = Vector2(size.x - inset - detail_width, 24 + top_height + 16)
	encounter.custom_maximum_size = Vector2(detail_width, maxf(100, size.y - top_height - 238))
	encounter.size = encounter.custom_maximum_size
	banner.position = Vector2(inset, 24 + top_height + 16)
	banner.size = Vector2(minf(550, maxf(250, size.x - detail_width - inset * 2 - 24)), 84)
	app.board.content_insets = Vector2(top_height + 38, 142)
	app.board.occlusions.clear()
	app.board.occlusions.append(top.get_global_rect())
	app.board.occlusions.append(scorebar.get_global_rect())
	if encounter.visible: app.board.occlusions.append(encounter.get_global_rect())
	app.board.queue_redraw()

func sync(view: Dictionary) -> void:
	if view.get("public", {}).is_empty(): return
	latest = view.public
	var next_context: String = str(view.get("match_id", "")) + ":" + str(view.get("epoch", ""))
	var next_revision: int = int(view.get("revision", -1))
	var new_context: bool = next_context != context_id
	if new_context:
		public_arena.reset_public()
		context_id = next_context
		last_revision = -1
		previous_values.clear()
		score_values.clear()
		encounter_signature = ""
		if banner_tween != null: banner_tween.kill()
		banner.hide()
	var players: Array = latest.players
	if players.is_empty(): return
	var active: Dictionary = players[int(latest.active)]
	heading.text = "TURNO %d · %s" % [int(latest.turn), str(active.name)]
	if latest.get("finished", false): heading.text = "PARTIDA ENCERRADA · veja o placar"
	connection.text = "CONEXÃO INDISPONÍVEL · dados da última atualização" if not app.endpoint.connected else "SALVAMENTO PENDENTE · aguardando anfitrião"
	connection.visible = not app.endpoint.connected or bool(view.get("save_pending", false))
	activity_line.text = str(latest.get("waiting", ""))
	var recent: Array = latest.get("activity", [])
	if not recent.is_empty(): activity_line.text += "\nÚltima ação: " + str(recent.back().message)
	steps.update_state(latest)
	motion_button.text = "Animações: " + ("reduzidas" if app.endpoint.reduced_motion else "ligadas")
	for p: Dictionary in players:
		var id: int = int(p.id)
		if not score_buttons.has(id):
			var control: Button = app.button("", func(): show_player(id), score_row)
			control.name = "TVScore_%d" % id
			control.custom_minimum_size = Vector2(80, 74)
			control.clip_text = true
			control.autowrap_mode = TextServer.AUTOWRAP_OFF
			control.add_theme_font_size_override("font_size", 21)
			score_buttons[id] = control
		var button: Button = score_buttons[id]
		button.theme_type_variation = &"Primary" if id == int(active.id) else &"Quiet"
		button.text = "%s%s%s\n%s/%d pontos · %s" % ["▶ " if id == int(active.id) else "", "★ " if p.announced else "", p.name, str(p.points), int(latest.get("victory_target", 4)), "eliminado" if p.eliminated else str(maxi(0, 2 - int(p.deaths))) + " vidas"]
		button.add_theme_color_override("font_color", COLORS[id % COLORS.size()])
		button.tooltip_text = str(p.name) + (" · anúncio territorial ativo" if p.announced else "") + " · selecionar para detalhes públicos"
		var value: String = str([p.points, p.deaths, p.announced, id == int(active.id)])
		if score_values.has(id) and str(score_values[id]) != value:
			Feedback.flash(button, Color("ffc477"), app.endpoint.reduced_motion)
		score_values[id] = value
	for id: int in score_buttons.keys():
		if not players.any(func(p: Dictionary) -> bool: return int(p.id) == id):
			score_buttons[id].queue_free()
			score_buttons.erase(id)
	var signature: String = JSON.stringify([latest.get("combat", {}), latest.get("race", {}), latest.get("loot", {}), latest.get("waiting", "")])
	if signature != encounter_signature:
		encounter_signature = signature
		render_encounter()
	if not new_context and next_revision > last_revision and int(latest.turn) > 0:
		if int(previous_values.get("turn", -1)) != int(latest.turn): announce("Agora é a vez de " + str(active.name))
	previous_values.turn = int(latest.turn)
	last_revision = next_revision
	fit()

func render_encounter() -> void:
	for child: Node in encounter_body.get_children():
		if child in [public_arena, race_board]: continue
		encounter_body.remove_child(child)
		child.queue_free()
	var combat: Dictionary = latest.get("combat", {})
	var race: Dictionary = latest.get("race", {})
	var loot: Dictionary = latest.get("loot", {})
	public_arena.sync_public(combat, str(latest.get("waiting", "")), app.endpoint.reduced_motion)
	race_board.sync(race, latest.players, app.endpoint.reduced_motion, context_id)
	encounter.visible = not combat.is_empty() or not race.is_empty() or not loot.is_empty()
	if not encounter.visible: return
	if not combat.is_empty():
		pass # Mesma arena, dado e animação de dano do celular/local.
	elif not race.is_empty():
		app.label("CORRIDA · " + str(race.track), encounter_body, 25)
		app.label(str(latest.get("waiting", "")), encounter_body, 20)
		if not race.get("last", {}).is_empty(): app.label("Dado %d · avanço %d" % [int(race.last.natural), int(race.last.advance)], encounter_body, 20)
	elif not loot.is_empty():
		app.label("SAQUE EM ANDAMENTO", encounter_body, 25)
		app.label("Resolva a defesa ou a retirada nos celulares. O controle do setor permanece.", encounter_body, 20)
	else:
		app.label("DECISÃO EM ANDAMENTO", encounter_body, 25)
		app.label("Aguardando o jogador responsável no celular. Cartas e recursos privados ficam lá.", encounter_body, 20)

func meter(key: String, value: float, maximum: float, caption: String, parent: Node) -> void:
	app.label("%s %d/%d" % [caption, int(value), int(maximum)], parent, 19)
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size.y = 20
	bar.max_value = maxf(1, maximum)
	bar.show_percentage = false
	parent.add_child(bar)
	var before: float = float(previous_values.get(key, value))
	bar.value = before if not app.endpoint.reduced_motion else value
	if not app.endpoint.reduced_motion and not is_equal_approx(before, value):
		bar.create_tween().tween_property(bar, "value", value, 0.35).set_trans(Tween.TRANS_SINE)
	else: bar.value = value
	previous_values[key] = value

func announce(message: String) -> void:
	if message.is_empty(): return
	if banner_tween != null: banner_tween.kill()
	banner_text.text = message
	banner.modulate.a = 1.0
	banner.show()
	if not app.endpoint.reduced_motion:
		banner.modulate.a = 0.0
		banner_tween = create_tween()
		banner_tween.tween_property(banner, "modulate:a", 1.0, 0.16)
		banner_tween.tween_interval(2.4)
		banner_tween.tween_property(banner, "modulate:a", 0.0, 0.25)
		banner_tween.tween_callback(banner.hide)

func player(id: int) -> Dictionary:
	for p: Dictionary in latest.get("players", []):
		if int(p.id) == id: return p
	return {}

func show_player(id: int) -> void:
	var p: Dictionary = player(id)
	if p.is_empty(): return
	app.modal.title = str(p.name) + " · informações públicas"
	app.modal.dialog_text = "%s\n%s/%d pontos · estrutura %d · %d vida(s)%s" % [app.board_view.city(str(p.city)).name, str(p.points), int(latest.get("victory_target", 4)), int(p.integrity), maxi(0, 2 - int(p.deaths)), "\nAnúncio territorial ativo" if p.announced else ""]
	app.modal.popup_centered(Vector2i(mini(640, int(size.x - 64)), 260))

func show_scoreboard() -> void:
	app.modal.title = "PLACAR · objetivo %d pontos" % int(latest.get("victory_target", 4))
	var lines: PackedStringArray = []
	for p: Dictionary in latest.get("players", []): lines.append("%s · %s pontos · %d vida(s)%s" % [p.name, str(p.points), maxi(0, 2 - int(p.deaths)), " · anúncio ativo" if p.announced else ""])
	app.modal.dialog_text = "\n".join(lines)
	app.modal.popup_centered(Vector2i(mini(700, int(size.x - 64)), 300))

func toggle_motion() -> void:
	app.endpoint.reduced_motion = not app.endpoint.reduced_motion
	var config: ConfigFile = ConfigFile.new()
	config.load("user://ui-preferences.cfg")
	config.set_value("accessibility", "reduce_motion", app.endpoint.reduced_motion)
	config.save("user://ui-preferences.cfg")
	app.board_feedback.reduced = app.endpoint.reduced_motion
	app.board_feedback.reset_effects()
	if banner_tween != null: banner_tween.kill()
	banner.modulate.a = 1.0
	banner.hide()
	encounter_signature = ""
	sync(app.endpoint.view)

func focus_default() -> void:
	for control: Node in top.find_children("*", "Button", true, false):
		if control.is_visible_in_tree() and not control.disabled:
			control.grab_focus()
			return

func scroll_encounter(event: InputEvent) -> void:
	var direction: int = 1 if event.is_action_pressed("ui_down") else -1 if event.is_action_pressed("ui_up") else 0
	if direction == 0: return
	var bar: VScrollBar = encounter_scroll.get_v_scroll_bar()
	var next: int = clampi(encounter_scroll.scroll_vertical + direction * 72, 0, maxi(0, int(bar.max_value - bar.page)))
	if next != encounter_scroll.scroll_vertical:
		encounter_scroll.scroll_vertical = next
		encounter_scroll.accept_event()
