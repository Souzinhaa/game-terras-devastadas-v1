extends SceneTree
const Game = preload("res://scripts/game_state.gd")
var failures = 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func reveal_all(game: WastelandGame) -> void:
	while not game.pending_reveal().is_empty():
		check(game.act("acknowledgeCard", {"ticket": game.pending_reveal().ticket}).is_empty(), "Confirmação da carta")

func _initialize() -> void:
	var a = Game.new()
	var b = Game.new()
	check(a.new_game(["A", "B", "C", "D"], 42).is_empty(), "Nova partida")
	b.new_game(["A", "B", "C", "D"], 42)
	check(JSON.stringify(a.state) == JSON.stringify(b.state), "Seed reproduzível")
	check(a.state.territories.size() == 35, "35 setores preservados")
	check(a.player().fuel == 3 and a.player().integrity == 6, "Hatch inicial")
	reveal_all(a)
	check(not a.act("end").is_empty(), "Não pode encerrar antes de iniciar")
	check(a.act("start").is_empty(), "Iniciar turno")
	reveal_all(a)
	check(a.player().hand.size() == 2, "Compra no primeiro turno")
	var route: Dictionary = {}
	for candidate in a.routes:
		if a.route_reason(candidate).is_empty():
			route = candidate
			break
	check(not route.is_empty(), "Existe rota inicial pavimentada")
	if not route.is_empty():
		# This scenario checks travel; event resolution has its own campaign suite.
		a.state.events = ["V01"]
		var destination = route.to if route.from == a.player().city else route.from
		check(a.act("move", {"route": route.id}).is_empty(), "Viagem válida")
		check(a.act("cardChoice").is_empty() and a.act("cardChoice").is_empty(), "Resolver evento de passagem tranquila")
		check(a.player().city == destination and a.player().fuel == 2, "Destino e consumo")
		check(a.state.actions == 1, "Viagem preserva ação principal")
		check(not a.act("move", {"route": route.id}).is_empty(), "Segunda viagem bloqueada")
	var active = a.state.active
	check(a.act("end").is_empty(), "Encerrar turno")
	check(a.state.active != active and not a.state.started, "Alternância local")
	reveal_all(a)
	a.act("start")
	reveal_all(a)
	var own = ""
	for id in a.state.territories:
		var t = a.state.territories[id]
		if t.city == a.player().city and t.owner == a.player().id: own = id
	check(not own.is_empty(), "Setor inicial próprio")
	check(a.act("explore", {"territory": own}).is_empty(), "Explorar setor próprio")
	check(a.state.actions == 0, "Exploração consome ação")
	check(not a.act("explore", {"territory": own}).is_empty(), "Ação não pode ser repetida")
	a.player().stock.fuel = 1
	check(a.act("refuel").is_empty(), "Abastecimento")
	a.player().integrity = 5
	check(a.act("repair").is_empty() and a.player().integrity == 6, "Reparo simples")
	var saved = JSON.stringify(a.state)
	check(b.load_game().is_empty(), "Carregar save")
	check(JSON.stringify(b.state) == JSON.stringify(JSON.parse_string(saved)), "Roundtrip do save")
	# Executar com APPDATA/LOCALAPPDATA isolados, conforme README.
	print("Native smoke: %d falhas" % failures)
	quit(0 if failures == 0 else 1)
