extends RefCounted
## Adaptador hot-seat: mesma entrada de regras; observação pública opcional.
signal applied(action: String, args: Dictionary, before: Dictionary, actor: int)
var _engine: WeakRef

func _init(engine: RefCounted) -> void:
	_engine = weakref(engine)

func submit(action: String, args: Dictionary = {}) -> String:
	var engine: RefCounted = _engine.get_ref()
	var before: Dictionary = engine.state.duplicate(true) if applied.has_connections() else {}
	var actor: int = action_actor(engine, action, args) if not before.is_empty() else -1
	var error: String = engine.act(action, args)
	if error.is_empty() and action != "retrySave" and not before.is_empty():
		applied.emit(action, args, before, actor)
	return error

func action_actor(engine: RefCounted, action: String, args: Dictionary) -> int:
	if args.has("player_id"): return int(args.player_id)
	if action == "combatCard":
		return int(engine.combat_rules.reaction_player().get("id", engine.player().id))
	if action in ["raceGeneral", "racePass"]:
		return int(engine.campaign.world.race_reactor().get("id", engine.player().id))
	if action == "raceRoll" and not engine.state.race.is_empty():
		return int(engine.state.race.entrants[int(engine.state.race.cursor)].player_id)
	if action == "cardChoice": return int(engine.state.choice.get("player_id", engine.player().id))
	if action in ["combatRoll", "combatContinue"] and not engine.state.combat.is_empty():
		var e: Dictionary = engine.state.combat
		var fighter: Dictionary = e.left if int(e.side) == 0 else e.right
		return int(fighter.player_id) if int(fighter.player_id) >= 0 else int(e.left.player_id)
	return int(engine.player().id)
