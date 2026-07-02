// Gilded Arcane Glass — the LIVING LIQUID ORB, one pass: a deep glass sphere of
// resource-liquid with per-pixel depth, an animated two-wave surface with a hot
// meniscus, rising bubbles, a damage-CHIP ghost band that drains after a hit, a
// gain FLASH, a low-health BOIL, and the glass itself (rim volume, bottom
// crescent, gold rim-light bevel, wet speculars) — same light grammar as
// ui_orb.gdshader (one virtual light, top-left). GL Compatibility / WebGL2 safe:
// constant loops, no derivatives beyond fwidth.
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 liquid : source_color = vec4(0.604, 0.169, 0.157, 1.0);
uniform float frac : hint_range(0.0, 1.0) = 1.0;   // eased fill level
uniform float chip : hint_range(0.0, 1.0) = 1.0;   // trails frac after damage (>= frac)
uniform float flash : hint_range(0.0, 1.0) = 0.0;  // gain pulse, decays CPU-side
uniform float throb : hint_range(0.0, 1.0) = 0.0;  // low-health boil + crimson breath
uniform vec4 rim_hi : source_color = vec4(1.0, 0.863, 0.576, 1.0);
uniform vec4 rim_mid : source_color = vec4(0.902, 0.706, 0.388, 1.0);
uniform vec4 rim_lo : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform vec4 crescent_col : source_color = vec4(0.169, 0.051, 0.047, 1.0);
uniform vec4 throb_col : source_color = vec4(0.816, 0.255, 0.227, 1.0);
uniform vec2 light_dir = vec2(-0.6, -0.8);

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;              // -1..1, +y down
	float d = length(p);
	float aa = fwidth(d) * 1.5 + 0.001;
	float disc = smoothstep(1.0, 1.0 - aa, d);
	vec2 nl = normalize(light_dir);
	vec2 np = d > 0.0001 ? p / d : vec2(0.0);
	float lit = clamp(dot(np, nl), -1.0, 1.0) * 0.5 + 0.5;

	// ---- the liquid surface: two travelling waves, livelier mid-fill / on boil ----
	float lvl = 1.0 - 2.0 * frac;
	float amp = (0.04 + 0.14 * frac * (1.0 - frac)) * (1.0 + throb * 0.9);
	float w = sin(p.x * 4.4 + TIME * 2.1) * 0.6 + sin(p.x * 7.3 - TIME * 3.3) * 0.4;
	float surf = lvl + w * amp;
	float saa = fwidth(p.y) * 1.5 + 0.004;
	float inliq = smoothstep(surf - saa, surf + saa, p.y);

	// ---- liquid body: bright at the surface, abyssal at the bottom, lit core ----
	float depth = clamp((p.y - surf) / max(1.0 - surf, 0.15), 0.0, 1.0);
	vec3 liq = mix(liquid.rgb * 1.30, liquid.rgb * 0.42, depth);
	liq += liquid.rgb * (1.0 - d) * (0.22 + 0.18 * frac);          // lit-from-within core
	float men = exp(-abs(p.y - surf) * 22.0);                       // hot meniscus band
	liq = mix(liq, liquid.rgb * 1.6 + vec3(0.18), men * (0.55 + 0.3 * throb));

	// ---- bubbles: four seeded columns rising from the deep to the surface ----
	float bub = 0.0;
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float sp = 0.22 + 0.15 * fract(fi * 0.73 + 0.31);
		float t = fract(TIME * sp + fi * 0.417);
		float bx = (fract(sin(fi * 17.23 + 1.7) * 437.5) * 1.24 - 0.62)
			+ sin(TIME * 1.1 + fi * 2.3) * 0.05;
		float by = mix(0.86, surf + 0.07, t);
		float br = 0.030 + 0.018 * fract(fi * 0.37) + 0.012 * throb;
		bub += smoothstep(br, br * 0.3, length(p - vec2(bx, by)))
			* step(surf + br, by) * (0.35 + 0.65 * t);              // fade in as they rise
	}
	liq += (liquid.rgb * 0.7 + vec3(0.22)) * bub * (0.5 + 0.5 * throb) * step(0.05, frac);

	// ---- recent damage: a pale ghost band between the old level and the new ----
	float surfc = (1.0 - 2.0 * chip) + w * amp;
	float ghost = smoothstep(surfc - saa, surfc + saa, p.y) * (1.0 - inliq);
	vec3 gcol = mix(liquid.rgb, vec3(1.0, 0.86, 0.76), 0.38) * 0.62;

	// ---- compose glass interior: empty vault above, liquid below, ghost between ----
	vec3 emp = liquid.rgb * 0.10 + vec3(0.016, 0.014, 0.024);
	vec3 col = mix(emp, liq, inliq);
	col = mix(col, gcol, ghost * 0.6);
	col += liquid.rgb * flash * 0.5;                                // gain pulse
	col = mix(col, throb_col.rgb, throb * 0.30 * smoothstep(0.25, 1.0, d));

	// ---- the glass itself (ui_orb mode-0 grammar) ----
	float vol = smoothstep(0.15, 1.0, d) * 0.40;
	col = mix(col, vec3(0.0), vol * 0.62);                          // rim volume darkening
	float cres = smoothstep(0.45, 1.0, d) * clamp(dot(np, vec2(0.0, 1.0)), 0.0, 1.0);
	col = mix(col, crescent_col.rgb, cres * 0.55);                  // bottom inner shadow
	float ring = smoothstep(0.82, 0.90, d) * smoothstep(1.0, 0.93, d);
	vec3 rimc = mix(mix(rim_lo.rgb, rim_mid.rgb, lit), rim_hi.rgb, smoothstep(0.6, 1.0, lit));
	col = mix(col, rimc, ring);                                     // gold rim-light bevel
	float spec = 1.0 - smoothstep(0.0, 0.34, length(p - vec2(-0.36, -0.40)));
	col = mix(col, vec3(1.0), spec * 0.80);                         // wet key specular
	float spec2 = 1.0 - smoothstep(0.0, 0.16, length(p - vec2(0.30, 0.42)));
	col = mix(col, rim_hi.rgb, spec2 * 0.22);                       // faint counter-glint

	COLOR = vec4(col, disc);
}
