// Gilded Arcane Glass — the circular glass-gem program, one virtual light (top-left).
//   mode 0 OVERLAY : transparent body drawn OVER the liquid orb — adds rim-light bevel,
//                    bottom crescent shadow, low-value crimson throb, and a wet specular.
//   mode 1 COIN    : opaque domed metal body for ability runes / the dial centre gem —
//                    dome fill + gold bevel rim + specular + inner shadow + enabled/hover/press.
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform int mode = 0;
uniform vec4 rim_hi : source_color = vec4(1.0, 0.863, 0.576, 1.0);
uniform vec4 rim_mid : source_color = vec4(0.902, 0.706, 0.388, 1.0);
uniform vec4 rim_lo : source_color = vec4(0.435, 0.325, 0.188, 1.0);
uniform vec4 crescent_col : source_color = vec4(0.169, 0.051, 0.047, 1.0);
uniform vec4 spec_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 throb_col : source_color = vec4(0.816, 0.255, 0.227, 1.0);
uniform float throb = 0.0;
uniform float body_vol = 0.40;
uniform vec2 light_dir = vec2(-0.6, -0.8);
uniform vec2 spec_uv = vec2(0.32, 0.30);
// coin
uniform vec4 body_core : source_color = vec4(0.125, 0.125, 0.180, 1.0);
uniform vec4 body_rim : source_color = vec4(0.047, 0.047, 0.078, 1.0);
uniform vec4 accent_tint : source_color = vec4(0.902, 0.706, 0.388, 1.0);
uniform float accent_amt = 0.14;
uniform float rim_width = 0.12;
uniform float spec_strength = 0.30;
uniform float enabled = 1.0;
uniform float hover = 0.0;
uniform float press = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;             // -1..1
	float d = length(p);
	float aa = fwidth(d) * 1.5 + 0.001;
	float disc = smoothstep(1.0, 1.0 - aa, d);
	vec2 nl = normalize(light_dir);
	vec2 np = d > 0.0001 ? p / d : vec2(0.0);
	float lit = clamp(dot(np, nl), -1.0, 1.0) * 0.5 + 0.5;   // top-left = bright
	vec2 spec_p = spec_uv * 2.0 - 1.0;
	float spec = 1.0 - smoothstep(0.0, 0.34, length(p - spec_p));

	vec3 col = vec3(0.0);
	float alpha = 0.0;

	if (mode == 0) {
		// OVERLAY over the liquid orb
		float vol = smoothstep(0.15, 1.0, d) * body_vol;                  // rim volume darkening
		col = vec3(0.0); alpha = vol;
		float cres = smoothstep(0.45, 1.0, d) * clamp(dot(np, vec2(0.0, 1.0)), 0.0, 1.0);
		col = mix(col, crescent_col.rgb, cres);                            // bottom inner shadow
		alpha = max(alpha, cres * 0.55);
		float ring = smoothstep(0.82, 0.90, d) * smoothstep(1.0, 0.93, d);
		vec3 rimc = mix(mix(rim_lo.rgb, rim_mid.rgb, lit), rim_hi.rgb, smoothstep(0.6, 1.0, lit));
		col = mix(col, rimc, ring); alpha = max(alpha, ring);             // gold rim-light bevel
		col = mix(col, throb_col.rgb, throb * 0.6);                        // low-value crimson throb
		alpha = max(alpha, throb * 0.4 * smoothstep(0.35, 1.0, d));
		col = mix(col, spec_col.rgb, spec * 0.85);                         // wet specular (last, brightest)
		alpha = max(alpha, spec * 0.85);
		alpha *= disc;
	} else {
		// COIN: opaque domed metal
		float dome = clamp(1.0 - d * d, 0.0, 1.0);
		vec3 body = mix(body_rim.rgb, body_core.rgb, dome);
		body += vec3(0.05) * clamp(dot(np, nl), 0.0, 1.0) * dome;          // top-light bias
		body = mix(body, accent_tint.rgb, accent_amt * dome);
		col = body;
		col = mix(col, vec3(0.0), smoothstep(0.35, 1.0, d)
			* clamp(dot(np, vec2(0.0, 1.0)), 0.0, 1.0) * 0.4);            // bottom inner shadow
		float ring = smoothstep(1.0 - rim_width - 0.04, 1.0 - rim_width, d) * smoothstep(1.0, 0.95, d);
		vec3 rimc = mix(mix(rim_lo.rgb, rim_mid.rgb, lit), rim_hi.rgb, smoothstep(0.6, 1.0, lit));
		col = mix(col, rimc, ring);
		col = mix(col, spec_col.rgb, spec * spec_strength);
		col = mix(vec3(dot(col, vec3(0.333))), col, mix(0.4, 1.0, enabled));  // desaturate if disabled
		col *= mix(1.0, 1.12, hover);
		col *= mix(1.0, 0.84, press);
		alpha = disc;
	}
	COLOR = vec4(col, alpha);
}
