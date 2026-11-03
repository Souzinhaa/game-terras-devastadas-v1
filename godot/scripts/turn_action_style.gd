extends RefCounted
## Indicador compartilhado do custo da ação principal; não executa comandos.
const Style = preload("res://scripts/ui_style.gd")

static func costs_action(game: RefCounted, action: String, args: Dictionary = {}) -> bool:
	if action == "playGeneral":
		var p: Dictionary = game.combat_rules.player_by_id(int(args.get("player_id", game.player().id)))
		var index: int = int(args.get("index", -1))
		return index >= 0 and index < p.get("hand", []).size() and p.hand[index] == "G17"
	if action == "install" and args.has("territory"):
		var territory: Dictionary = game.state.territories.get(args.territory, {})
		return not territory.is_empty() and territory.city != game.player().city
	return action in ["explore", "conquer", "duel", "loot", "repairComplex", "repairTerritory", "upgradeVehicle", "swap", "repairFound"]

static func apply(button: Button, consumes: bool) -> void:
	if not consumes: return
	button.set_meta("consumes_turn_action", true)
	button.icon = load("res://assets/ui/turn_action.svg")
	button.add_theme_constant_override("icon_max_width", 26)
	button.add_theme_constant_override("h_separation", 10)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var surface := Style.box(Color("493821") if state != "hover" else Color("634a29"), Style.SELECTION)
		if state == "disabled": surface.border_color = Color("77654a")
		button.add_theme_stylebox_override(state, surface)
	button.add_theme_color_override("font_color", Color("ffe0a4"))
	button.add_theme_color_override("icon_normal_color", Color("ffe0a4"))
	button.tooltip_text += "\nUsa a ação principal do turno."
	button.accessibility_description = "Usa a ação principal do turno."
