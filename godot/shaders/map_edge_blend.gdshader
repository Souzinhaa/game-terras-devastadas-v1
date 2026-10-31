shader_type canvas_item;
// Transição curta para a extensão decorativa; o centro original permanece intacto.
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	COLOR = vec4(source.rgb, source.a * smoothstep(0.0, 0.025, edge));
}
