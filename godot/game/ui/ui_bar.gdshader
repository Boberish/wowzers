// Gilded Arcane Glass — the one glossy bar, shared by boss HP, raid HP, and every
// resource bar. Over the host ColorRect's UV: a rounded-rect well with inner-shadow
// AO, a rich->bright horizontal fill masked by fill_frac, a top-third gloss sheen, a
// bright leading-edge line, a damage-chip ghost between fill and chip, and a 2-tone
// gold bevel frame + dark inner seam. Rounded corners + gradient live here (not _draw).
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec2 rect_size = vec2(100.0, 20.0);
uniform float corner_px = 6.0;
uniform float border_px = 3.0;
uniform float fill_frac = 1.0;
uniform float chip_frac = 1.0;
uniform vec4 col_well : source_color = vec4(0.030, 0.025, 0.050, 1.0);
uniform vec4 col_deep : source_color = vec4(0.306, 0.098, 0.090, 1.0);
uniform vec4 col_mid : source_color = vec4(0.733, 0.227, 0.204, 1.0);
uniform vec4 col_bright : source_color = vec4(0.867, 0.420, 0.392, 1.0);
uniform vec4 col_leading : source_color = vec4(1.0, 0.722, 0.675, 1.0);
uniform vec4 col_chip : source_color = vec4(0.898, 0.541, 0.518, 1.0);
uniform vec4 gold_hi : source_color = vec4(1.0, 0.863, 0.576, 1.0);
uniform vec4 gold_mid : source_color = vec4(0.902, 0.706, 0.388, 1.0);
uniform vec4 gold_lo : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform vec4 edge_line : source_color = vec4(0.173, 0.141, 0.212, 1.0);
uniform float gloss_alpha = 0.16;
uniform float gloss_top_frac = 0.42;

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 half = rect_size * 0.5;
	float d = sd_round_box(px - half, half, corner_px);
	float inside = smoothstep(1.2, -1.2, d);

	// recessed well + top/left inner-shadow AO
	vec3 col = col_well.rgb;
	float ao = clamp(smoothstep(6.0, 0.0, px.y) + smoothstep(5.0, 0.0, px.x), 0.0, 1.0);
	col = mix(col, vec3(0.0), ao * 0.55);

	float x = UV.x;
	if (x <= fill_frac) {
		float t = clamp(x / max(fill_frac, 0.001), 0.0, 1.0);
		vec3 fill = mix(col_deep.rgb, col_mid.rgb, smoothstep(0.0, 0.72, t));
		fill = mix(fill, col_bright.rgb, smoothstep(0.62, 1.0, t));
		col = fill;
		col += vec3(1.0) * smoothstep(gloss_top_frac, 0.0, UV.y) * gloss_alpha;      // top sheen
		col += col_leading.rgb * smoothstep(fill_frac - 0.014, fill_frac, x) * 0.75;  // leading edge
	} else if (x <= chip_frac) {
		col = col_chip.rgb;                                                          // damage chip ghost
	}

	// gold bevel border (outer band) + 1px dark inner seam, lit top-left -> bottom-right
	float bd = -d;   // distance INWARD from the edge (0 at rim, grows inside)
	float tl = clamp(0.5 - (px.x + px.y) / (rect_size.x + rect_size.y), 0.0, 1.0);
	vec3 gold = mix(gold_lo.rgb, gold_mid.rgb, smoothstep(0.0, 0.5, tl));
	gold = mix(gold, gold_hi.rgb, smoothstep(0.5, 1.0, tl));
	float m_seam = clamp(smoothstep(border_px - 0.5, border_px + 0.5, bd)
		- smoothstep(border_px + 0.5, border_px + 1.5, bd), 0.0, 1.0);
	float m_gold = 1.0 - smoothstep(border_px - 0.5, border_px + 0.5, bd);
	col = mix(col, edge_line.rgb, m_seam);
	col = mix(col, gold, m_gold);

	COLOR = vec4(col, inside);
}
