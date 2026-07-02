# MASTER PLAN — Project Rift

**This is the coordination hub.** Current status, open work, claims, and ideas all live HERE.
`CLAUDE.md` keeps the stable rules (engine law, how to run things, past milestone history); this file is the *living state*. When Bill says "work on X", X is a section of this file.

---

## HOW TO WORK (process rules — every agent, every task)

1. **Read this file first.** Find your section, check the Coordination Log for conflicts.
2. **Claim your work**: add a line to the Coordination Log (`date · branch · section · what`) *before* starting.
3. **Always work in a git worktree** — never directly on `main`:
   `git worktree add ../wow-<task> -b <task>` → work there → commit early and often.
4. **Sync often**: merge `main` into your branch regularly (at least before merging back) so parallel work never drifts far apart.
5. **Verify before merging back**: run the acceptance bar for your section (listed per-section below; default = the class sims + UI smokes you touched, determinism PASS, and byte-identical checksums for any engine change).
6. **Merge to `main`, then UPDATE THIS FILE** — status, what changed, what's next, tick the Coordination Log entry. A task isn't done until the master plan says so.
7. Engine law is unchanged and non-negotiable: `CombatCore` stays a pure, deterministic, Node-free reducer (see CLAUDE.md).
8. Cleanup: `git worktree remove ../wow-<task>` when merged.

---

## OVERALL PROGRESS

| Area | State |
|---|---|
| Combat engine (pure reducer, strings, threat) | ✅ Solid, regression-gated |
| Classes (Bulwark, Mender, Twinfang, Voidcaller, Bloomweaver) | ✅ All playable + verified |
| Bosses (15 solo + Vorathek raid) | ✅ Done, tuned bands |
| Run loop + draft (Bulwark full; others "continue"-only) | 🟡 Bulwark-only draft |
| UI (Gilded Reliquary overhaul) | ✅ Done |
| 3D stage | 🟡 Bulwark vertical slice only |
| Co-op raid (R0/R1: any seat, any aspect, AI raiders) | ✅ Playable |
| Netcode (R2) | 🟠 IN FLIGHT (another session: `godot/net/`, `server/`, web export in `dist/`) |
| **THEME: AI-Killer rebrand** | 🔴 NEW — not started (see Theme Bible) |
| **Draft 2.0 / slot-verbs / token economy** | 🔴 NEW — planned (see Systems; design: `ASCENSION-STEAL-PLAN.md`) |
| **Trial Ladder ("Versions")** | 🔴 NEW — planned |

---

## THEME BIBLE — "The AI Killer" (ironic layer)

**The pitch:** an AI is making a lot of this game, so the game is about killing AIs. Robot and computer bosses named after AI models. Fights stay **epic and mechanically serious** — the *wrapper* is silly: over-polite boss dialogue, hallucinated attacks, and the recurring gag that we could have just unplugged them.

**Tone rules**
- The COMBAT is never the joke. Telegraphs, strings, tuning — all played straight. The jokes live in names, dialogue, event pops, end screens, and ally banter.
- Bosses are unfailingly polite, hedging, and apologetic while trying to kill you ("I apologize, but I must now use CRUSH. As a large language model I have no choice.").
- Difficulty arc: **Mistral-tier (easy) → Gemini-tier (mid) → Claude-mythos (finale)**. Claude/Opus is reserved for capstones — treat it like a mythic raid entity.
- Post-win screens undercut the epicness: *"VICTORY. (In hindsight, the power cable was right there.)"* Post-loss: *"You died. Your feedback will be used to improve the boss."*
- Our AI allies (they literally ARE AI policies) get banter: confidently wrong callouts ("I am 100% certain this is the parry window" — right before a feint), apologizing for dying, etc. View-only events, never in the checksum.
- Trademark note: real model names are fine for now (personal project); parody names are an easy later swap if this ever ships wide.

**Systemic naming (locked)**
- **Feints = HALLUCINATIONS.** Canonical, everywhere. BAITED → "You believed it."
- **Interrupt/kick = "Stop generating."** Silence = context truncation.
- **Enrage = rate limit / "training run complete" / FREE TIER EXCEEDED.**
- **Boss self-heal = "retraining" / restoring from checkpoint.** DENIED → "checkpoint corrupted."
- **Threat drop (raid curse) = context-window shift** — the boss *forgets the tank exists*.
- **Draft currency = TOKENS** (see Systems). *"You have earned 3 tokens. Spend them responsibly."*
- **Rarity tiers = Haiku (common) / Sonnet (rare) / Opus (legendary).**
- **Trial Ladder tiers = model VERSIONS** (v1.0, v2.0…) with fake patch notes on tier-up: *"v2.1 — fixed an issue where players could survive."*

**Boss mapping (mechanic-faithful reskins — mechanics/tuning DO NOT change)**
| Current boss | Themed identity | The hook |
|---|---|---|
| Gatekeeper (parry teacher) | **CAPTCHA-9, the Gatekeeper** | "Prove you are not a robot" — verifies your humanity via parry checks |
| Warcaller | **MISTRAL, the Draft-Engine** | wind-cooled, fast light swings; lightweight-and-efficient jokes (the easy boss) |
| Colossus (Rockslide) | **BIG IRON** | room-sized legacy mainframe; slow punch-card telegraphs; COBOL jokes |
| The Duelist (feint boss) | **THE HALLUCINATOR** | a diffusion unit that *renders attacks that don't exist* — the feint boss IS the hallucination boss |
| The Devourer (chip+heal+enrage) | **THE SCRAPER** | devours data to grow; heal = retraining on what it scraped; enrage = training complete |
| Rendmaw (aoe barrage) | **POPUP, the Adhound** | Rending Barrage = pop-up storm; "one weird claw" |
| Rotweaver (DoTs/dispel) | **THE WORM** | botnet infection; dispels = antivirus |
| Hollow Choir (marks/heal-absorb) | **THE SPAM CHOIR** | mark = "you've been selected (targeted ad)"; heal-absorb = inbox full |
| TF-Warden | **FIREWALL** | a literal wall that filters your packets (strikes) |
| The Executioner (Judgment Cuts) | **THE DECOMMISSIONER** | killbot HR: "your role has been made redundant" |
| Choir-Priest (interruptible chants) | **THE PROMPTER** | chatbot evangelist; its casts are walls of text — kick = Stop generating |
| Twin Cantors (Duet, silent twin) | **GEMINI, the Twins** | THE twin boss; the silent-twin feint = the mute model; Empower = model merge |
| Ashmaul (spike teacher) | **PISTON, the Crash-Loop** | one big hammer, forever |
| Swarmheart (attrition) | **THE SWARM** | drone cloud (robots! for the boy) |
| Hollowking (Kingsmark one-shot) | **KERNEL, the Hollow King** | Kingsmark = "selected for deletion"; runs in ring 0 |
| Vorathek (raid) | **OPUS, the Alignment** | Claude-mythos finale. Three phases: **Helpful / Harmless / Honest** (heals you unwanted → turtles → drops all pretense). Curse = context shift; spawns *subagent* adds (yes, the meta-joke) |

**Art note (genuine win):** robots/computers are much CHEAPER for our procedural `PoseRig` pipeline than organic monsters — boxes, servos, antennae, monitors read instantly. The theme isn't just funny, it accelerates W-Graphics.

**Acceptance bar (theme work):** display names/strings/sigils/dialogue only — sims stay byte-identical (rename via display fields, never ids). UI smokes green.

---

## CLASSES

**Now:** 5 classes done & verified (2 tanks-of-verbs pattern: mitigate/keep-alive/rhythm/interrupt/anticipate). Aspect pairs everywhere. Raid seats for all 4 roles.
**Next up (any agent can claim):**
- **Draft parity**: Mender/Twinfang/Voidcaller/Bloomweaver have boon POOLS but only Bulwark has the full between-fight draft in its run loop. Port the draft loop to all classes (prereq for Draft 2.0 everywhere).
- **Theme banter pass per class** (ally callouts, tooltip jokes) — after Theme Bible lands.
**Open ideas** (from Ascension research, parked until a 6th/7th class is wanted):
- Self-brink DPS: gauge climbs = more damage, cap = self-destruct (Cultist Insanity / Stormbringer Static archetype). Verb: *ride the redline*. Strong fit.
- Over-defend punishment tank layer (Mountain King self-stun) — could bolt onto Bulwark as a boon/mod instead.
- Imposed-rhythm caster (Runemaster attunement auto-cycle) — kit rotates on a clock you don't control.
- ~~Rewind/Chronomancer verb~~ — PARKED (unintuitive in a reaction game; revisit as a rare relic at most).
**Acceptance:** class sims determinism PASS + bands sane; UI smoke green.

## BOSSES & ENCOUNTERS

**Now:** 15 solo bosses + Vorathek raid, all with M7.2 strings, tuned skill bands.
**Next up:**
- **Theme reskin per the mapping table** (display-only; see Theme Bible acceptance bar).
- **Aura-add mechanic** (from Manastorm): a mid-fight elite that BUFFS the boss until killed — creates a real add-vs-boss decision AND attacks the R3 "one telegraph source" interrupt problem. Needs engine work (second cast source) — design against `RAID-PLAN.md` R3.
- **OPUS phase design** (Helpful/Harmless/Honest) — the raid finale deserves authored phases, not just the curse.
**Open ideas:** boss "patch notes" as Trial-Ladder flavor; a Stable-Diffusion illusion miniboss (all feints, low HP).
**Acceptance:** boss sims determinism PASS, bands within intent, byte-identical for untouched bosses.

## SYSTEMS — Draft 2.0, slot-verbs, token economy (design doc: `ASCENSION-STEAL-PLAN.md`)

**Phases (sequenced, each mergeable alone):**
- **A. Draft 2.0** (GREENLIT): synergy picks (1 of 3 offers must tag-match your build) + transform boons (top rarity = verb transforms, not +%) + rarity/pity (Haiku/Sonnet/Opus, rarity = frequency not caps). Bulwark first, then port with draft parity.
- **B. Slot-verbs PoC**: Guard = `[Trigger]+[Property]+[Payload]` mods; rewrite Bulwark's 17 boons as typed mods. **NO LOCKOUTS** — combos stack, rebalance the boss instead. **Scoping rule (locked):** pools stay per-class; mods must express through UI the class already has (new-UI mods get budgeted explicitly or cut). Cross-ASPECT flavor bleed allowed as rare spice only where the class UI already supports it (e.g. Tempo drafting a venom payload — Twinfang UI already renders poison).
- **C. Token economy**: skilled play mints TOKENS mid-run (from `state.diag`: perfect-parry streaks, no-avoidable-damage clears) → spend in draft (reroll / lock a slot / upsell rarity). Deterministic, per-seat.
- **D. Feeds the Trial Ladder** (below).
**Acceptance:** run-loop UI smokes; draft determinism when seeded; kit checksums byte-identical when boons absent.

## MODES & ENDGAME

- **Trial Ladder ("Versions")** — NEW: replay any boss at v1/v2/v3…; each version ADDS MECHANICS (extra string beats, feints, phases — never just +HP%), better rewards, fake patch notes. Deterministic engine ⇒ seed-verified leaderboards nearly free. Design vs `TuningConfig` + strings content.
- **Run modifiers** (Hades-Heat/Hardcore-Trials style): opt-in stacking difficulty for exclusive rewards — after Trial Ladder proves the scaling hooks.
- **Open ideas:** endless "Manastorm" mode; meta-progression (account tokens → cosmetic/QoL, losses still bank progress); daily seed challenge (same seed for everyone, leaderboard).

## GRAPHICS / PRESENTATION

**Now:** Gilded Reliquary 2D UI done; 3D stage = Bulwark slice (PoseRig procedural rigs, dais, VFX, reticle dial).
**Next up:**
- Wire the other 4 HUDs to CombatStage3D (~15 lines each, pattern documented in CLAUDE.md) + a rig per class.
- **Robot re-rig**: per-boss silhouettes as ROBOTS/COMPUTERS (theme!) — replaces the `variant()` stopgap and is easier than organic sculpts. CAPTCHA-9 = a turnstile with an eye; GEMINI = two identical chassis; OPUS = a server-cathedral.
- Blender/GLTF pipeline later (art replaces rig subclasses; `act()`/`windup()` contracts stay).
**Open ideas:** screen transitions; binds/spellbook art pass; theme the Gilded Reliquary gold → circuit-board copper/emerald-terminal accents (light touch, don't redo).
**Acceptance:** `sim/stage3d_tour.gd` / `screenshot_tour.gd` render clean (WSLg), determinism ×3 untouched.

## ONLINE (R2+)

**IN FLIGHT — another session owns this** (`godot/net/` client/server/protocol, `server/` Docker+tunnel, `dist/web` export). Per `RAID-PLAN.md`: server-authoritative WebSocket, headless Godot server, browser WASM client.
**Do not touch without checking the Coordination Log.** When it lands: netcode session should update this section + Overall Progress.
**Queued behind it:** R3 raid content/economy (needs aura-add / parallel cast sources — see Bosses).

## TOOLING & INFRA

**Now:** headless sims per class, UI smokes, screenshot tours, this repo is now GIT (baseline 2026-07-02). Worktree workflow live (see HOW TO WORK).
**Next up:** CI-ish script that runs all sims + smokes in one command (the merge-back gate, `tools/verify-all.sh`); decide CSV output home (`godot/out/` is gitignored).
**Open ideas:** auto-post sim bands into this file; seed-verified replay files for leaderboards.

---

## CURRENT / OPEN IDEAS (parking lot — promote into a section when claimed)

- Game title candidates for the theme: *UNPLUGGED*, *Ctrl+Alt+DEFEAT*, *KILLSWITCH*, *RIFT: Do Not Trust Its Outputs*.
- Rewind verb (deterministic-engine showpiece) — parked, see Classes.
- Positive run-affixes ("Mythical Boons") — fold into Run modifiers when built.
- Second raid boss; healer-aggro rules for co-op (R0 caveats list).
- Mender's own draft pool (currently continue-screen only) — subsumed by Draft parity above.

## COORDINATION LOG (claim before you start, tick when merged + plan updated)

- ☐ 2026-07-02 · (unassigned) · Online/R2 — in flight by a concurrent session (pre-dates this log; that session should claim retroactively).
- ☑ 2026-07-02 · main · Infra — git init, baseline commit, MASTER-PLAN.md created, CLAUDE.md wired to it. *(this session)*
