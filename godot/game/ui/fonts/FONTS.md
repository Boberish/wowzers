# Fonts

The game's display font is applied globally by the `UiTheme` autoload
(`game/ui/ui_theme.gd`), which overrides `ThemeDB.fallback_font`. Every custom
widget draws with that font, and every Label/Button falls back to it, so one file
here re-skins the whole UI.

## Swap in your own font (2 minutes — the intended path)

1. Grab a display face — e.g. **Orbitron**, **Rajdhani**, **Chakra Petch**, or
   **Exo 2** from https://fonts.google.com (all open-licensed, free for commercial
   use, safe to ship in a WASM build).
2. Drop the `.ttf` (or `.otf` / `.woff2`) here and name it **`display.ttf`**
   (`res://game/ui/fonts/display.ttf`). `UiTheme` prefers it over everything else.
3. Run once: `godot --headless --path godot --import`, then launch. Done.

Tip: subset/`woff2` keeps the web download small.

## Interim font shipped here

`ubuntu.ttf` — the **Ubuntu** typeface (variable), a clean modern humanist face,
used as the default until you drop a `display.*`. Licensed under the **Ubuntu Font
License 1.0** (free to use and redistribute; keep this attribution). Replace it
with a display face when you want the more "arcane / techno HUD" feel.
