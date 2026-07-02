// Gilded Arcane Glass — the stage ground. One opaque full-rect ColorRect replacing
// the flat BG0 rectangle: aspect-corrected radial vignette, a whisper of scrolled
// nebula grain, a low gold floor-pool behind the boss, and a warm grade — all driven
// cool->crimson by a cosmetic `mood` uniform (enrage / low party HP). No screen read.
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 aspect = vec2(1.0, 1.0);
uniform float vignette_inner = 0.16;
uniform float vignette_outer = 0.98;
uniform vec4 center_color : source_color = vec4(0.055, 0.055, 0.094, 1.0);
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 nebula_cool : source_color = vec4(0.141, 0.106, 0.200, 1.0);
uniform vec4 nebula_warm : source_color = vec4(0.290, 0.216, 0.125, 1.0);
uniform float nebula_scale = 2.2;
uniform float nebula_amt = 0.06;
uniform vec2 horizon_center = vec2(0.5, 0.46);
uniform vec2 horizon_size = vec2(0.72, 0.20);
uniform vec4 horizon_dim : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform vec4 horizon_enrage : source_color = vec4(0.478, 0.137, 0.125, 1.0);
uniform float horizon_amt = 0.12;
uniform float mood = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 c = (uv - vec2(0.5)) * aspect;
	float r = length(c) / max(length(vec2(0.5) * aspect), 0.0001);

	// radial vignette: a faintly-lit centre sinking to pure black at the corners
	float vig = smoothstep(vignette_outer, vignette_inner, r);
	vec3 col = mix(edge_color.rgb, center_color.rgb, vig);

	// nebula: two slow scrolled taps of the shared noise, masked to the lit region
	float n1 = texture(noise_tex, uv * nebula_scale + vec2(TIME * 0.004, TIME * 0.002)).r;
	float n2 = texture(noise_tex, uv * nebula_scale * 0.6 - vec2(TIME * 0.003, 0.0)).r;
	float neb = n1 * 0.6 + n2 * 0.4;
	col += mix(nebula_cool.rgb, nebula_warm.rgb, neb) * neb * nebula_amt * vig;

	// low gold floor-pool behind the boss (warms to crimson on enrage)
	vec2 hc = (uv - horizon_center) / horizon_size;
	float pool = smoothstep(1.0, 0.0, length(hc));
	col += mix(horizon_dim.rgb, horizon_enrage.rgb, clamp(mood, 0.0, 1.0)) * pool * horizon_amt;

	// warm grade + violet shadow lift
	col *= vec3(1.03, 1.00, 0.95);
	col += vec3(0.006, 0.005, 0.009);
	COLOR = vec4(col, 1.0);
}
