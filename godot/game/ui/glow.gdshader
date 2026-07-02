// Reusable additive radial glow for CanvasItems (runes / orbs / dial cores).
// GL-Compatibility + WebGL2 safe. One shared program; every GlowCore instance
// just supplies its own uniforms — so this compiles once (kind to web warm-up).
//
//   peak    0.0 = a solid core that peaks dead-centre; ~0.5 = a ring/halo.
//   spread  gaussian falloff width.
//   The glow amount is written into COLOR.a; blend_add turns that into light
//   added over whatever is beneath (no WorldEnvironment glow needed — that one
//   is unavailable on the Compatibility renderer).
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float intensity = 0.0;
uniform float peak = 0.0;
uniform float spread = 0.35;

void fragment() {
	float d = distance(UV, vec2(0.5)) * 2.0;          // 0 centre → 1 at mid-edge
	float g = exp(-pow((d - peak) / max(spread, 0.001), 2.0));
	g *= smoothstep(1.1, 0.55, d);                    // fade before the square corners show
	COLOR = vec4(glow_color.rgb, g * intensity);
}
