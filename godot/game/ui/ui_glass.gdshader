// Gilded Arcane Glass — the foundational frosted surface for every panel/card/tooltip/
// well/raid-frame AND the cast-dial sigil disc. One canvas_item pass over a rounded-rect
// (shape 0) or disc (shape 1) SDF composites: a soft drop shadow (outside the box), a
// top-lit glass fill with in-shader grain, an inner accent-edge glow, and a 2-tone gold
// bevel border + dark inner seam. The host ColorRect is grown by `shadow_pad` so the
// shadow has room; `rect_px` is the grown size (set from resized()). No screen read.
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform int shape = 0;                       // 0 = rounded rect, 1 = disc
uniform vec2 rect_px = vec2(240.0, 120.0);   // grown node size (incl. shadow_pad)
uniform float shadow_pad = 24.0;
uniform float corner_radius = 12.0;
uniform float border_width = 2.0;
uniform float edge_softness = 1.2;
uniform vec4 fill_top : source_color = vec4(0.110, 0.102, 0.157, 1.0);
uniform vec4 fill_bot : source_color = vec4(0.051, 0.047, 0.082, 1.0);
uniform float fill_alpha = 0.90;
uniform vec4 accent_color : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform float glow_boost = 0.14;
uniform float noise_amt = 0.028;
uniform vec4 gold_hi : source_color = vec4(1.0, 0.863, 0.576, 1.0);
uniform vec4 gold_mid : source_color = vec4(0.902, 0.706, 0.388, 1.0);
uniform vec4 gold_lo : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform vec4 inner_line_col : source_color = vec4(0.173, 0.141, 0.212, 1.0);
uniform vec4 shadow_col : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 shadow_offset = vec2(0.0, 6.0);
uniform float shadow_size = 18.0;
uniform float shadow_alpha = 0.5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

float sd_shape(vec2 p, vec2 half, float rad) {
	if (shape == 1) { return length(p) - min(half.x, half.y); }
	return sd_round_box(p, half, rad);
}

void fragment() {
	vec2 px = UV * rect_px;
	vec2 center = rect_px * 0.5;
	vec2 half = center - vec2(shadow_pad);
	float d = sd_shape(px - center, half, corner_radius);
	float sd = sd_shape(px - center - shadow_offset, half, corner_radius);

	// drop shadow (only outside the glass box)
	float shadow = smoothstep(shadow_size, 0.0, sd) * shadow_alpha * smoothstep(-1.0, 1.0, d);
	vec3 col = shadow_col.rgb;
	float alpha = shadow;

	float inside = smoothstep(edge_softness, -edge_softness, d);
	if (inside > 0.001) {
		float ty = clamp((px.y - shadow_pad) / max(rect_px.y - 2.0 * shadow_pad, 1.0), 0.0, 1.0);
		vec3 fill = mix(fill_top.rgb, fill_bot.rgb, ty);
		fill += (hash(floor(px * 0.5)) - 0.5) * 2.0 * noise_amt;                 // frosted grain
		float bd = -d;                                                           // inside distance
		fill = mix(fill, accent_color.rgb, smoothstep(22.0, 0.0, bd) * glow_boost);
		fill += vec3(1.0) * smoothstep(3.0, 0.0, abs(bd - 1.5)) * 0.06;          // faint top rim highlight
		float fa = fill_alpha;

		// 2-tone gold bevel border + 1px dark seam
		float tl = clamp(0.5 - (px.x + px.y) / (rect_px.x + rect_px.y), 0.0, 1.0);
		vec3 gold = mix(gold_lo.rgb, gold_mid.rgb, smoothstep(0.0, 0.5, tl));
		gold = mix(gold, gold_hi.rgb, smoothstep(0.5, 1.0, tl));
		float m_seam = clamp(smoothstep(border_width - 0.5, border_width + 0.5, bd)
			- smoothstep(border_width + 0.5, border_width + 1.5, bd), 0.0, 1.0);
		float m_gold = 1.0 - smoothstep(border_width - 0.5, border_width + 0.5, bd);
		fill = mix(fill, inner_line_col.rgb, m_seam);
		fill = mix(fill, gold, m_gold);
		fa = mix(fa, 1.0, clamp(m_gold + m_seam, 0.0, 1.0));

		col = mix(col, fill, inside);
		alpha = max(alpha * (1.0 - inside), fa * inside);
	}
	COLOR = vec4(col, alpha);
}
