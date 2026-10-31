extends RefCounted
## Coordenadas lógicas compartilhadas por todas as telas LAN.
static func safe_rect(control: Control, profile: Dictionary = {}) -> Rect2:
	var bounds: Rect2 = Rect2(Vector2.ZERO, control.size)
	if not bool(profile.get("touch", OS.has_feature("android"))): return bounds
	var pixels: Vector2 = Vector2(profile.get("pixels", DisplayServer.screen_get_size()))
	if pixels.x <= 0 or pixels.y <= 0: return bounds
	var physical: Rect2 = Rect2(profile.get("safe_area", DisplayServer.get_display_safe_area()))
	if not physical.has_area(): return bounds
	var ratio: Vector2 = control.size / pixels
	return bounds.intersection(Rect2(physical.position * ratio, physical.size * ratio))

static func insets(control: Control, profile: Dictionary = {}) -> Vector4:
	var safe: Rect2 = safe_rect(control, profile)
	return Vector4(safe.position.x, safe.position.y, control.size.x - safe.end.x, control.size.y - safe.end.y)
