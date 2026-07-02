# Gilded Reliquary — the Steam-quality UI overhaul

**Direction (locked with user 2026-07-01): "Gilded Reliquary."** Evolve the Arcane
Obsidian identity into full ornamental art: a dark gothic *stage* the fight happens on,
not a dashboard the fight is reported in. Boss presence included (animated per-boss
sigil center-stage). Not a rebuild — the Gilded Arcane Glass kit (`ui_kit.gd`, shaders,
`glass_panel.gd`, SVG rune icons, `palette.gd`) is the base layer we deepen.

## Art pillars
1. **Candle-lit reliquary, not neon hologram.** Warm ember-gold on near-black obsidian.
   Light behaves: one virtual top-left light (`UiKit.LIGHT_DIR`), soft shadows, gilded
   bevels lit on one side. Crimson = danger only. Class accents are stained-glass tints.
2. **The boss is a *presence*.** Center stage: a large ritual sigil unique to each boss —
   it breathes, winds up with the telegraph, flinches on hits, panics at low HP, dies.
   The telegraph dial wraps *around* it: the boss's body and its intent are one object.
3. **Ornament earns its place.** Filigree marks hierarchy (screen title > boss plate >
   card > chip). No bare rectangles: every surface is glass (GlassPanel), engraved rail,
   or jeweled bar; every string has a shadow; headers are serif smallcaps.
4. **Readable at combat speed.** Art never costs clarity: swing colors (LIGHT/HEAVY/
   CRUSH), the parry window, HP state must read in <100 ms peripheral vision.

## Type system (all SIL OFL, bundled in `game/ui/fonts/` with licenses — Steam-safe)
- **Cinzel Decorative** (`cinzel_decorative/`) — game title / VICTORY / DEFEAT only.
- **Cinzel** (variable wght; `cinzel/`) — display: boss names, screen headers, class
  names, big numerals (damage floats, orb numbers). Tracked-out UPPERCASE.
- **Spectral** (Regular/Medium/SemiBold; `spectral/`) — body: descriptions, tooltips,
  hints, stat lines. Medium is the UI default (ThemeDB fallback via `UiTheme` autoload).
- Access via `UiKit.display(weight)`, `UiKit.title(weight)`, `UiKit.body(weight)`;
  sizes via `UiKit.SIZE` — no magic literals.

## Layout grammar (per combat screen)
- Design space **1920×1080**, stretch `canvas_items`, aspect `expand` (project.godot).
  Corners anchor, center stage floats. Audit at 1280×720 / 2560×1440 / 1680×1050.
- **Top rail:** run breadcrumb (left) · ornate boss plate w/ jeweled HP (center) ·
  spellbook/menu (right).
- **Center stage:** backdrop (arches, rift, god-rays, embers) + boss sigil + telegraph
  ring + floating combat text.
- **Class band** (lower third): the class's own info — raid cards (Mender), rhythm bar
  (Twinfang), focus/cast (Voidcaller), counter pips (Bulwark).
- **Bottom rail:** resource orbs in gilded mounts (corners) + engraved ability rail
  with rune-coins + keybind plaques.

## Components
`stage_backdrop.gd` (scene atmosphere; calm variant for menus) · `boss_sigil.gd`
(per-boss glyph SVGs in `ui/icons/bosses/`, event-driven animation) · ornate boss
plate · engraved ability rail · reliquary raid cards · relic draft cards · tooltip
plaques · title wordmark. Reuse: gilded_ring/engraved_ticks/filigree_corner/glass bars.

## Hard constraints
- **GL Compatibility / WebGL2** — shared shader programs only (compile once), CPU
  particles, no backbuffer-read effects. Target: painless browser export.
- **CombatCore stays pure.** All visuals read `observe()` + drain `state.events`.
  No wall-clock in sim state; UI-side animation time is fine (view-only).
- Sims + `ui_smoke*.gd` must stay green; screenshot tour (`sim/screenshot_tour.gd`)
  after every chunk: `godot --path godot --script res://sim/screenshot_tour.gd
  --resolution 1920x1080 -- --out=<dir>` (needs WSLg display, not --headless).

## Campaign (all five chunks DONE 2026-07-02; verified at 1080p / 720p / 1680×1050)
1. **Foundation — DONE.** Stretch/scale settings, fonts bundled, UiTheme rewrite,
   menu center-bug fix.
2. **The Stage — DONE.** `stage_backdrop.gd` + 15 boss sigil glyphs (incl. the
   parallel Bloomweaver bosses); dial rebuilt as the living boss (`react()` API).
3. **Component art — DONE.** Ornate boss plate, keybind-plaque runes + hover ignite,
   reliquary raid cards, tarot `relic_card.gd`, clawed orb mounts.
4. **Screen passes — DONE.** Emblem-card class menu, `aspect_card.gd` banner selects,
   ceremonial Cinzel-Decorative headers/end banners, all four HUD stage layouts,
   CenterContainer fix on every centered screen.
5. **Audit — DONE.** 3-resolution screenshot audit clean; all 4 sims determinism-PASS;
   both UI smokes green. Scratch diagnostics removed.

## Lessons (hard-won — respect these)
- **Place, then add.** Anchors set in `_ready` after tree entry never lay out if the
  parent is already sized. Set anchors in `_init` / before `add_child`. Centered
  stacks go in a full-rect CenterContainer — never PRESET_CENTER on the stack itself.
- `Dictionary.get(...)` into `:=` is a Variant-inference parse error here; type it.
- `const` can't hold `Palette` statics — use `static var`.
- 2D MSAA is a no-op on GL Compatibility; rely on `antialiased: true` draws.
- SVGs rasterise at their `width`/`height` attrs — author big art (boss sigils) at
  512, small chrome at 64.

6. **Gauge art pass — DONE (2026-07-02).** The whole gauge family speaks one language
   ("reliquary instruments"): `UiKit.engraved_plaque()` captions, gem pips on engraved
   rails, gilded needle + travelling shimmer on `rhythm_bar.gd`, ignite states when a
   payoff is castable (Riposte / Coup / Overload-instant / Silence / Surge / Last
   Stand), and the Mender's Label+ProgressBar replaced by the reusable
   `spec_strip.gd` (SpecStrip: plaque + jeweled bar + end-gems + charged glow).
7. **DPS medallions — DONE (2026-07-02).** The two DPS spec gauges rebuilt as winged
   reliquary medallions (600×130 center-stage band, `UiKit.wing_flourish()`):
   - `twinfang_gauge.gd`: the FLOW CRYSTAL — six facet-segments fill cyan per Flow
     point (gain-flash, full-blaze at max), display numeral, +DMG plaque; left wing =
     five ember combo gems on a rail (finisher gem pulses at full); right wing =
     Tempo's tier chain to a bursting COUP gem, or the Venomancer's V/F/C cocktail
     gems + Toxic Synergy ramp meter.
   - `voidcaller_gauge.gd`: the VOID CONDUIT — a caged void mote (rotating containment
     arcs) with five Backlash gems on a crescent; when Overload primes, the gems BEAM
     into the core and it blazes. Silencer: the core becomes the lockout clock
     (draining radial ring + countdown numerals) with the amber EXPOSED readout.
   - `rhythm_bar.gd` rebuilt as the gilded METRONOME CHANNEL (720×100): hatched
     crimson too-early reach, engraved beat ruler, stained-emerald Perfect window
     with boundary gems + travelling shimmer, jeweled end-caps + filigree, a needle
     with motion trail and diamond head, the live cue on its own line, and a held
     verdict that bursts AT THE SPOT YOU PRESSED (ghost needle + rays on PERFECT).
   - Mender cast bar rebuilt as `cast_channel.gd` (CastChannel, the "benediction
     channel", placed under the raid frames): spell-rune medallion, lit spell plaque
     + target, jeweled gold channel with travelling shimmer + end-gems, and a golden
     RELEASE BLOOM when the cast resolves (cancelled casts just fade). Replaces the
     last plain ProgressBar in combat. NOTE: the HUD var is `_castbar` — `_cast` is
     taken by the spell-dispatch method.
   - Verify every lit state without playing: `SHOT_OUT=<png> godot --path godot
     --script res://sim/gauge_gallery.gd` renders the full state matrix (medallions,
     all four rhythm-bar states incl. the held verdict, cast channel + bloom).

8. **Bloomweaver alignment + Blooming Medallion — DONE (2026-07-02).** The fifth class
   (built in a parallel session off the old Mender template) brought fully onto the
   system: CenterContainer fixes, Cinzel-Decorative select header + end banner,
   `AspectCard` selects (growth / briarheart icons, VERDANCE / THORN accents), dial
   enlarged + fed boss identity (its sigil never rendered before), CastChannel
   benediction bar (VERDANCE accent), and `verdance_gauge.gd` rebuilt as the winged
   BLOOMING MEDALLION: jade core + progress ring, eight leaf petals that unfurl per
   slice (petal-pop on completion, gold shimmer when spendable), Growth pips on the
   left wing rail with a GARDEN plaque, ◆ FLOURISH ◆ ignite line / Thornveil
   bark-amber thorn tally. Also swept the leftover inconsistency: mender / twinfang /
   voidcaller / bloomweaver draft screens now use `relic_card.gd` (tarot cards) like
   Bulwark, with Cinzel draft headlines. Gallery covers the three medallion states;
   screenshot tour gained bloomweaver select + combat steps (14 shots now).

## Still open (future polish, roughly in value order)
- Mender bind-hint row + stats line as engraved plaques; binds/spellbook screens.
- Screen transitions (fade/slide) + boss intro card ("THE GATEKEEPER" title splash).
- Boss glyph review at small sizes; per-boss accent tints.
- Menu card entrance stagger; draft-card deal-in animation.
