// Full-screen "feel" pass — the one back-buffer/screen-read in the whole HUD.
// Replaces the flat colour flash with: a radial shockwave displacement, RGB
// chromatic aberration on hits, a low-HP crimson vignette, and a colour wash
// (gold parry / crimson hit / green deny). Everything is driven by uniforms the
// HUD tweens; when they all sit at rest the output equals the screen (identity),
// and the HUD hides this node entirely so idle frames pay nothing.
//
// GL-Compatibility + WebGL2 note: reading the screen texture forces a back-buffer
// copy. Keep it to THIS single pass.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amt = 0.0;
uniform float aberration = 0.0;              // RGB split amount
uniform vec2 shock_center = vec2(0.5, 0.5);
uniform float shock_t = -1.0;                // 0 → 1 while active; < 0 = off
uniform float shock_amt = 0.0;
uniform float vignette = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.82, 0.25, 0.22, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;

	// expanding shockwave ring: push pixels outward as the ring sweeps past them
	if (shock_t >= 0.0 && shock_amt > 0.001) {
		vec2 dvec = uv - shock_center;
		float dist = length(dvec);
		float ring = shock_t;
		float infl = smoothstep(0.07, 0.0, abs(dist - ring)) * (1.0 - shock_t);
		uv += normalize(dvec + vec2(1e-6)) * infl * shock_amt * 0.05;
	}

	// chromatic aberration: split R/B radially outward from screen centre
	vec2 dir = uv - vec2(0.5);
	float ab = aberration * 0.012;
	vec3 col;
	col.r = texture(screen_tex, uv + dir * ab).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - dir * ab).b;

	// low-HP vignette: darken + bleed crimson into the corners
	float vig = smoothstep(0.35, 0.95, length(dir)) * vignette;
	col = mix(col, vignette_color.rgb * 0.12, vig);

	// screen-wide colour wash (parry / hit / deny)
	col = mix(col, flash_color.rgb, clamp(flash_amt, 0.0, 0.85));

	COLOR = vec4(col, 1.0);
}
