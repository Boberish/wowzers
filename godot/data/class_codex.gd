## ClassCodex — the DEV / PLAYTEST "how does this class work" rundown, as data.
## Pure content (no engine, no Node): the pause menu's Class Guide reads this to tell
## you — at a glance — the class fantasy, what each BAR does, what each MOVE encourages,
## the GOAL ROTATION, and THE BRANCHES (both Aspects + boon/gear sub-builds). Keyed by
## char_class id; the four raid seats are authored (tank/blade/caster/healer).
##
## Facts are lifted from the live kits/configs/boons + each class's HUD tips, so it
## tracks the current tuning — but it is a TEACHING doc, not the source of truth. If a
## number here drifts from the code, the code wins; fix the string.
##
## Schema per entry (all `tint` values are Palette keys resolved in PauseOverlay):
##   name, role, verb, accent, fantasy
##   resources: [{name, tint, body}]
##   defense:   {name, key, body}
##   moves:     [{name, key, cost, tag, body}]   # tag "" = shared, else an aspect id
##   aspects:   [{id, name, tint, tagline, identity, bar, rotation:[..], branches:[{name, via, body}]}]
##   gear
class_name ClassCodex
extends RefCounted

const DATA := {
# ============================================================ BULWARK · TANK
"bulwark": {
	"name": "THE BULWARK", "role": "TANK · MITIGATE", "accent": "steel",
	"verb": "Read the swing — bank the read, protect the streak, cash it.",
	"fantasy": "The wall. You don't move — you READ. Every telegraph is a question (parry it? hold the hallucination? dodge the combo beat?) and every correct answer feeds your engine while the wrong one hurts. You tank by being right, not by being big. In the raid you also hold THREAT (press Challenge to yank the boss back) so the squishies live.",
	"resources": [
		{"name": "HEALTH", "tint": "blood", "body": "Your life. Swings chip it; at 0 the run ends. Fortify, Bloodthirst and Warding-Light guard payloads heal it back — you're expected to trade HP, not hoard it."},
		{"name": "RAGE", "tint": "rage", "body": "Built by TAKING hits (and dealing them). The fuel for every ability. Eating a swing you couldn't fully negate isn't pure loss — it pays for your next Rampage/Fortify. Don't sit capped; spend it."},
	],
	"defense": {"name": "GUARD", "key": "SPACE",
		"body": "Your defensive verb, on its OWN cooldown (off the GCD). WARDEN presses it to PARRY (negate + reflect + bank Counter). JUGGERNAUT presses it to DODGE (negate — but it dumps Momentum, so dodge only what you must). A successful press eats the swing INSTANTLY. Separately, F = dodge string-combo BEATS (universal): a PERFECT beat pays your spec, guarding a Hallucination/feint = BAITED."},
	"moves": [
		{"name": "Cleave", "key": "1", "cost": "free · 42 · +6 rage", "tag": "",
			"body": "Filler that builds rage. In a Riposte window it hits far harder — parry, then Cleave the opening."},
		{"name": "Rampage", "key": "2", "cost": "40 rage · 130", "tag": "",
			"body": "Your rage dump and main hit. Spend the rage you banked from eating swings."},
		{"name": "Fortify", "key": "3", "cost": "30 rage · heal 130 · -30% dmg 3.5s", "tag": "",
			"body": "Turn rage into survival — heal + harden right before a dangerous stretch."},
		{"name": "Vindicate", "key": "4", "cost": "cash the CHAIN · 40/link · -25% dmg 3s", "tag": "warden",
			"body": "The Warden payoff: cash your whole Guard Chain at once. The longer the streak, the bigger the spike."},
		{"name": "Avalanche", "key": "4", "cost": "20 rage · 30/Momentum vented · staggers", "tag": "juggernaut",
			"body": "The Juggernaut VENT: cash SOME Momentum for burst + a stagger, and keep riding the redline. Partial by design — no self-destruct."},
		{"name": "Challenge", "key": "T", "cost": "taunt · 8s cd · off-GCD", "tag": "",
			"body": "RAID ONLY. Force the boss onto you and seize top threat. Press it the instant a Context-Shift curse peels aggro onto a raider."},
		{"name": "Bloodthirst", "key": "5*", "cost": "25 rage · 80 · heals 60%", "tag": "",
			"body": "Draftable. Attack to sustain — heals for most of the damage it deals."},
		{"name": "Shockwave", "key": "5*", "cost": "50 rage · 55 · interrupts", "tag": "",
			"body": "Draftable. Panic button — interrupts the boss's current swing outright."},
	],
	"aspects": [
		{"id": "warden", "name": "WARDEN", "tint": "steel", "tagline": "Read → Link → Cash.",
			"identity": "The disciplined tank. You protect a STREAK, not a bar — precision is rewarded, sloppiness is punished immediately.",
			"bar": "GUARD CHAIN (0–6): every won read — a parry, a PERFECT combo beat, or a correctly-HELD hallucination — links the chain, and each link passively boosts ALL your damage (+6%/link). But EAT a heavy/crush you should've parried and the chain HALVES. Reads also SUNDER the boss (the fracture pips on its bar) — while cracked, EVERYONE hits it harder.",
			"rotation": [
				"Read every swing: parry heavies, HOLD hallucinations, dodge (F) the string beats.",
				"Each clean read links the Chain (passive +dmg) and cracks Sunder for the team.",
				"Spend banked rage on Rampage — but never DROP the chain to a lazy hit.",
				"Fortify right before a burst window.",
				"Cash a fat Chain with Vindicate for a spike, then rebuild the streak.",
			],
			"branches": [
				{"name": "Chain-keeper", "via": "boons: Deep Counter, Mirror Edge, Vengeful Guard",
					"body": "All-in on never dropping the streak — +2 Counter/parry, double-reflect parries, riposte heals. The passive damage of a long chain carries the fight; you barely press Vindicate."},
				{"name": "Build-your-Guard", "via": "slot-verb pieces: triggers + payloads + Twin Guard (opus)",
					"body": "Turn Guard into a combo button. Add proc moments (feint READ, every-3rd guard, PERFECT beat, landed Riposte) and stack payloads (lash 35 / +Counter / Expose / mend). Twin Guard = a 2nd guard charge."},
				{"name": "Sunder-break (team)", "via": "payload Sunder Guard + curio Keystone of the Broken Wall",
					"body": "Feed the boss-side break meter hard; a cracked wall multiplies the WHOLE raid's damage. Tank-as-force-multiplier — your value is on the boss's bar, not your own."},
			]},
		{"id": "juggernaut", "name": "JUGGERNAUT", "tint": "momentum", "tagline": "Ride high, vent, never stop.",
			"identity": "The reckless tank. Momentum is a snowball you refuse to drop — forgiving of mistakes, greedy by nature.",
			"bar": "REDLINE / MOMENTUM (0–10, +4 with Unstoppable): dealing AND eating hits build it (more damage AND more mitigation). Below cap, DODGING DUMPS it (greed — a dodge costs your snowball). At CAP you hit OVERDRIVE: dodging is FREE. Avalanche VENTS part for burst + a stagger while you keep riding. Riding high lays a rising SUNDER floor on the boss.",
			"rotation": [
				"Take and deal hits to stack Momentum toward the cap.",
				"Below cap, DODGE only what you truly must — each dodge dumps the snowball.",
				"Hit the cap → OVERDRIVE: now dodging is free; stay pinned to the redline.",
				"Avalanche to vent a chunk (burst + stagger), then KEEP riding — don't reset to zero.",
				"Fortify / Bloodthirst to sustain through the hits that feed you.",
			],
			"branches": [
				{"name": "Snowball", "via": "boons: Unstoppable, Snowball, Bulldoze",
					"body": "Cap higher (14), decay later, +3 Momentum on eating heavies/crushes. Reach Overdrive fast and never leave it."},
				{"name": "Free footwork", "via": "boons: Sure-Footed, Overrun",
					"body": "Dodging only HALVES Momentum instead of dumping it, and 40% less Crush damage at 8+. Ride high AND stay safe — the answer to 'my own dodge kills my snowball'."},
				{"name": "Vent-sustain", "via": "boons: Landslide, Rolling Iron guard payload",
					"body": "Avalanche heals 40% of its damage; guard procs feed +2 Momentum. A self-sustaining vent loop that never runs dry."},
			]},
	],
	"gear": "CURIOS (Realm-1: PERIPHERALS) add fortune + new buttons ON TOP of your build. The Bulwark build-around is KEYSTONE OF THE BROKEN WALL (maxing Sunder resets the raid's defensive verbs). Most curios are drop-and-forget procs — check your equipped list after a drop.",
},
# ============================================================ TWINFANG · MELEE DPS
"twinfang": {
	"name": "THE TWINFANG", "role": "MELEE DPS · DRIVE THE RHYTHM", "accent": "flow",
	"verb": "There is NO global cooldown — Strike lands only when you tap in the GREEN.",
	"fantasy": "A dual-dagger duelist who plays the fight like an instrument. Strike is gated by a timing WINDOW, not a GCD: mash and you whiff, wait for the green and you Perfect. Perfects feed your Aspect engine (Tempo's accelerating Flow, or Venom's poison wheel), and dodging protects your damage as much as your health. The two Aspects are two different metronomes.",
	"resources": [
		{"name": "HEALTH", "tint": "blood", "body": "310 max. At 0 the run ends. You're a duelist — footwork (dodge) is your only defense, so read the boss."},
		{"name": "ENERGY", "tint": "rage", "body": "100, regens 20/s. Pays every ability. A GOOD dodge refunds +6, a READ (held-feint) beat +10. Rarely the bottleneck — the bottleneck is your timing."},
		{"name": "COMBO (cp)", "tint": "gold", "body": "0–5. Strike +1 (Perfect +2), Flurry +2, Coup +3. Your finisher (Eviscerate / Envenom) spends ALL of it — bank to 5, then dump."},
	],
	"defense": {"name": "DODGE / EVADE", "key": "SPACE",
		"body": "0.55s window, 2.4s cooldown. Protects HP AND your engine: a landed swing WIPES your Flow to zero (Tempo) — 'dodge protects your damage as much as your health.' F = dodge string-combo BEATS; a PERFECT beat pays Flow/energy, dodging a Hallucination = BAITED."},
	"moves": [
		{"name": "Strike", "key": "1", "cost": "12 energy · 19 (Perfect ×1.6)", "tag": "",
			"body": "The metronome. Tap in the GREEN window: Perfect = ×1.6 dmg, +2 cp, +1 Flow. Too early = ignored (no cost). This is 80% of the game."},
		{"name": "Eviscerate", "key": "2", "cost": "25 energy · 23 × combo", "tag": "tempo",
			"body": "Tempo finisher: dumps all combo (115 at 5 cp), Flow-scaled. Your burst spike."},
		{"name": "Envenom", "key": "2", "cost": "25 energy · fixate", "tag": "venomancer",
			"body": "Venom finisher: FIXATES the lit lane — dumps all combo as poison stacks WITHOUT turning the wheel. Over-stack one flavor."},
		{"name": "Kick", "key": "3", "cost": "10 energy · cd 7s · interrupt", "tag": "",
			"body": "Interrupt the boss's self-heal cast. Whiffs (still costs) if nothing's castable — read the violet bar before you press."},
		{"name": "Coup de Grâce", "key": "4", "cost": "30 energy · cd 5s · needs MAX Flow", "tag": "tempo",
			"body": "Tempo execute: 120 × Flow-mult, then CONSUMES Flow down to a seed of 2 and refunds +3 cp. Cash your Flow spike (best under an execute)."},
		{"name": "Rupture", "key": "4", "cost": "22 energy · cd 3.5s · needs poison", "tag": "venomancer",
			"body": "Venom detonate: all stacks × 9 × Synergy. SLAM zeroes your poison + Synergy — blow it at the ramp's peak."},
		{"name": "Flurry", "key": "5*", "cost": "28 energy · 3×13 · +2 cp", "tag": "",
			"body": "Draftable. Three quick hits for fast points when you can't wait for the beat."},
	],
	"aspects": [
		{"id": "tempo", "name": "TEMPO", "tint": "flow", "tagline": "Accelerando — Flow IS the BPM.",
			"identity": "Execution-heavy. Chain Perfects and the whole fight SPEEDS UP; eat one swing and it crashes to a walking pace. The demanding aspect — a sloppy Tempo loses the enrage race.",
			"bar": "FLOW (0–6, +2 with Momentum): +1 per Perfect Strike/dodge, ×8% ALL damage per point, decays 1 every 2.4s, WIPES to 0 when a swing hits you. As Flow climbs the green window slides EARLIER and TIGHTENS (0.35s → 0.20s wide) — the accelerando. Tier 1 (Flow≥3) = extra hit per Perfect; Tier 2 (≥5) = +cp/energy; Tier 3 (MAX) = Coup unlocked.",
			"rotation": [
				"Strike in the green → build Flow, and feel the window shift earlier.",
				"Chain Perfects to climb the tiers — DON'T get hit (Flow wipes).",
				"Bank combo while you ride.",
				"At MAX Flow → Coup de Grâce (consumes Flow to seed 2, refunds 3 cp).",
				"Chain an Eviscerate off the Coup refund, then rebuild from the seed.",
			],
			"branches": [
				{"name": "Ride-forever uptime", "via": "boons: Syncopation (opus), Virtuoso, Momentum",
					"body": "Free Strikes at max Flow, Flow decays 50% slower, cap +2. Never leave the top tier — the accelerando becomes permanent."},
				{"name": "Coup burst", "via": "boons: Crescendo, Encore",
					"body": "Coup +40%, and Tier-1 lights at Flow 2. Front-load spikes; get to the execute button faster."},
				{"name": "Perfect-payoff", "via": "boons: Killer's Eye, Dancer's Grace (opus)",
					"body": "Every 5th Perfect crits; a perfect DODGE auto-Perfects your next Strike. Rewards the cleanest hands."},
			]},
		{"id": "venomancer", "name": "VENOMANCER", "tint": "verdance", "tagline": "Poison wheel — keep all three alive.",
			"identity": "Forgiving of sloppy rhythm — poison ignores Flow, so the beat is a steady base tempo. The management aspect: juggle three DoTs and a synergy ramp, then detonate.",
			"bar": "POISON WHEEL (V→F→C, each 0–8): one lane is LIT — the next Strike stacks it, then the wheel ADVANCES. Riding the beat tops all three. Keep all three alive and TOXIC SYNERGY ramps (1.0→1.8), boosting every tick. Envenom FIXATES the lit lane (over-stack without advancing). Everything bleeds 1 every 4s.",
			"rotation": [
				"Strike on the beat V→F→C to light all three lanes.",
				"Keep all three alive so Toxic Synergy ramps.",
				"Envenom to over-stack a lane / dump a full combo.",
				"Rupture at the Synergy PEAK for the detonation.",
				"Maintain against the 4s decay — don't let a lane fall off (resets Synergy).",
			],
			"branches": [
				{"name": "Tick / DoT", "via": "boons: Potent Toxins, Fast Rot, Catalyst",
					"body": "+30% ticks, faster festering, Synergy ramps 60% faster. Pure attrition — the boss melts between your Ruptures."},
				{"name": "Rupture burst", "via": "boons: Rupturing Blades, Lingering Venom",
					"body": "+40% detonation; Lingering Venom turns Rupture into a SIP (keeps half + Synergy) for sustained blows instead of one big slam."},
				{"name": "Keep-3-live / defensive", "via": "boons: Contagion (opus), Debilitate",
					"body": "A Perfect seeds a random 2nd lane (easier uptime); Crippling stacks cut the boss's damage to you up to 30% — the survivable poison build."},
			]},
	],
	"gear": "CURIOS add procs: Powder Vial makes Kick carry toxin (Venom: +2 lit lane / Tempo: +1 Flow), LE CHAT's Bell gives +30 starting energy, Riftmaw Tooth pays energy on a denied self-heal. Tokens mint off your Perfect-Strike count.",
},
# ============================================================ ALCHEMIST · CASTER DPS (the Brew)
"alchemist": {
	"name": "THE ALCHEMIST", "role": "CASTER DPS · BREW THE REACTION", "accent": "react",
	"verb": "Hold to charge the VIAL — release in the sweet band, feed BOTH poisons, Rupture the ripe peak.",
	"fantasy": "The patient, deliberate brewer (base build — creeds/modules/boons come later). Two OPPOSING poisons sit on a see-saw: VENOM burns hot and fades fast, ROT creeps cold and lingers. They only react where they MEET — min(Venom, Rot) × balance — so blindly stacking one side is bad by design. The vial fills slow at the bottom and ACCELERATES hard near the top: the greed is how high you dare ride it. Keep the reaction balanced and fed and POTENCY multiplies everything; then RUPTURE the whole brew at its ripe peak and rebuild — a wave every ~15–25s.",
	"resources": [
		{"name": "HEALTH", "tint": "blood", "body": "330 max. At 0 the run ends. Your hands are full — footwork (dodge) is your only defense."},
		{"name": "VENOM · ROT", "tint": "venombrew", "body": "The two poisons, 0–12 each. Venom decays 2.0/s, Rot 0.5/s, and the reaction EATS both — no banking a stable pile. The reaction scales with the SMALLER side × balance, so keep them EVEN, not just high."},
		{"name": "POTENCY", "tint": "react", "body": "0–100%, ×1 → ×2.6 on EVERYTHING (reaction + Rupture). Fills while the reaction is balanced AND fed; drains fast when lopsided or dry. One bar = 'how well am I brewing' — and it IS your power."},
	],
	"defense": {"name": "DODGE", "key": "SPACE",
		"body": "Standard footwork (0.55s window, 2.4s cd) — the brew keeps cooking through your dodge, and a held charge is NOT dropped. F = dodge string-combo BEATS. No kick: the seat trades the interrupt for the brew (interrupt-by-ability comes with the world rework)."},
	"moves": [
		{"name": "Brew Venom", "key": "1 (hold)", "cost": "free · release = pour", "tag": "",
			"body": "Hold to charge the vial with VENOM, release to pour. Under 45% fizzles (no tap-spam); the green sweet band pays +8 POTENT; the last sliver before the red line pays +9 HOT; past it = SPOILED (+1)."},
		{"name": "Brew Rot", "key": "2 (hold)", "cost": "free · release = pour", "tag": "",
			"body": "The same vial, cold side. Rot lingers — anchor it, then tend the fast-fading Venom against it."},
		{"name": "Rupture", "key": "3 / tap the chamber", "cost": "consumes ~65% of the brew", "tag": "",
			"body": "Detonate the reaction: FUEL (balanced volume) × POWER (potency), multiplicative — the peak is both-high. The chamber glows RIPE when it's worth it. Cash the wave, rebuild from the seed."},
	],
	"aspects": [
		{"id": "brew", "name": "THE BREW", "tint": "react", "tagline": "Build → PEAK → rebuild.",
			"identity": "The whole class, for now — a second spec arrives with the full build. Deep minigame, narrow kit: the brew IS the class.",
			"bar": "THE ALEMBIC: twin reservoirs (hold-zones), the vial with its sweet band + red line, the reaction chamber (its number = your live dps; tap it to Rupture), the balance beam, and the POTENCY strip.",
			"rotation": [
				"Open by anchoring ROT high (it lingers), then feed VENOM against it.",
				"Ride each charge into the sweet band — release on the green.",
				"Keep min(V,R) fed and the see-saw level → POTENCY climbs.",
				"At the ripe peak (fuel high + potency hot) → RUPTURE.",
				"Rebuild from the 35% seed — the wave is the loop.",
			],
			"branches": [
				{"name": "(base build)", "via": "creeds / modules / boons land after live playtests",
					"body": "The Steady Hand / Volatile Mix / Reckless Brewer / Anchorite / Purist creeds, the Still, Ferment, Catalyst, Last Call and the rest are designed (ALCHEMIST-PLAN.md) and arrive once the base brew proves out."},
			]},
	],
	"gear": "CURIOS apply as usual (fortune + off-verb only — cross-class law). No class boon pool yet: REFORGE drafts skip this seat until the boon slate lands.",
},
# ============================================================ VOIDCALLER · CASTER DPS
"voidcaller": {
	"name": "THE VOIDCALLER", "role": "CASTER DPS · INTERRUPT", "accent": "void",
	"verb": "The boss's cast bar IS the fight — KICK it (Space), then nuke between kicks.",
	"fantasy": "A control caster who wins by silencing. The boss's purple cast is a clock you're racing: interrupt it on the last slice (a CLEAN kick) for extra reward and a heal, then Fracture into the gap. There's no hard enrage — the boss's own self-heal is your DPS check, so a missed kick loses you the race.",
	"resources": [
		{"name": "HEALTH", "tint": "blood", "body": "340 max. At 0 the run ends. You have no armor — you sustain by KICKING: every interrupt heals you 14."},
		{"name": "FOCUS", "tint": "void", "body": "0–100, starts EMPTY. Bolt +14, PERFECT dodge +12, READ beat +8. Spent on Fracture (26) and Quietus (30). The whole job: keep Fracture fed between kicks."},
	],
	"defense": {"name": "KICK (interrupt)", "key": "SPACE",
		"body": "Your defensive verb reused as offense. 5s cooldown (3s with Snap Cast), OFF the GCD. Cancels the boss's INTERRUPTIBLE cast and heals you 14. A CLEAN kick — pressed on the last 0.62s slice of the cast bar — pays DOUBLE and banks more spec. A whiff (nothing castable, or too early) STILL burns the cooldown, so don't panic-kick. Denying a self-heal = DENIED. F = dodge string beats."},
	"moves": [
		{"name": "Bolt", "key": "1", "cost": "free · 34 · +14 Focus", "tag": "",
			"body": "Instant filler between casts — your Focus battery."},
		{"name": "Fracture", "key": "2", "cost": "26 Focus · 1.15s cast · 118", "tag": "",
			"body": "Your nuke. Taking a hit mid-cast PUSHES IT BACK — protect it by kicking. Overload makes the next one instant."},
		{"name": "Barrier", "key": "3", "cost": "free · 45% DR 3s · cd 10", "tag": "",
			"body": "Eat the UNINTERRUPTIBLE channels — the casts you can't kick."},
		{"name": "Overload", "key": "4", "cost": "spend ALL Backlash · 68 × stack", "tag": "disruptor",
			"body": "Disruptor payoff: dump your Backlash for a spike, then your NEXT Fracture is instant. The reward for clean kicks."},
		{"name": "Quietus", "key": "4", "cost": "30 Focus · cd 9", "tag": "silencer",
			"body": "Silencer lockdown: cancel the cast + hard-Silence 5s + Expose (+50% dmg taken). Opens the burn window."},
		{"name": "Silence / Counterspell", "key": "5*", "cost": "free · interrupt", "tag": "",
			"body": "Draftable 2nd interrupt for overlapping casts (Silence adds a mute; Counterspell reflects 90). Kick-rotation insurance."},
	],
	"aspects": [
		{"id": "disruptor", "name": "DISRUPTOR", "tint": "kick", "tagline": "Clean-kick → bank → Overload.",
			"identity": "You race the boss's self-heals; clean interrupts are ammunition for a burst button. The DPS-check aspect.",
			"bar": "BACKLASH (0–5): a CLEAN kick banks +2, a regular kick +1. Dump the whole stack with Overload (68 × stack) → and your next Fracture goes instant.",
			"rotation": [
				"Bolt to build Focus.",
				"CLEAN-kick the boss's cast (last slice) → +2 Backlash + a heal.",
				"Fracture whenever Focus ≥ 26.",
				"At high Backlash → Overload for a spike, then cast the now-instant Fracture free.",
				"Barrier the channels you can't kick; DENY every self-heal or you lose the race.",
			],
			"branches": [
				{"name": "Overload burst", "via": "boons: Punish, Feedback, Backlash Burn",
					"body": "Interrupt dmg +40%, Overload refunds 20 Focus, clean kicks leave a burn. Stack Backlash and unload for big Overload windows."},
				{"name": "Machine-gun kicks", "via": "boons: Snap Cast, Twin Void (opus)",
					"body": "Kick cd → 3s + a SECOND kick charge. Interrupt everything, bank Backlash constantly, never let a cast finish."},
				{"name": "Denial", "via": "boons: Void Feast, Starve the Choir",
					"body": "Denying a heal strikes back for 50% of the denied healing, and a denial re-fires your kick payloads. Punish the boss for even trying to retrain."},
			]},
		{"id": "silencer", "name": "SILENCER", "tint": "void", "tagline": "Lock it out, burn the window.",
			"identity": "The control fantasy — the boss can't cast while you're on it. Trades the burst race for a hard lockout.",
			"bar": "SILENCE + EXPOSED: clean kicks Silence up to 4.6s and Expose (+30% dmg taken); Quietus hard-Silences 5s and Exposes +50%. All your damage scales up while the boss is Exposed.",
			"rotation": [
				"Clean-kick to Silence + Expose the boss.",
				"Quietus to cancel + hard-Silence 5s + Expose +50%.",
				"Unload Fracture / Bolt into the open Exposed window (everything hits harder).",
				"Re-kick as Silence fades — never let it finish a cast.",
			],
			"branches": [
				{"name": "Perma-lock", "via": "boons: Lingering Hush, Snap Cast, Twin Void (opus)",
					"body": "Silences +40% longer, kick cd → 3s, a 2nd charge. Chain silences so the boss literally never casts."},
				{"name": "Glass-cannon Expose", "via": "boons: Laid Bare, Quietus windows",
					"body": "Expose +50% stronger — every Quietus opens a huge damage window. Front-load everything into the exposed boss."},
				{"name": "Sustain-lock", "via": "boon: Reprieve",
					"body": "Each Silence heals you 30. Turns the lockout into self-sustain — you outlive anything the boss can chip you with."},
			]},
	],
	"gear": "CURIOS: Spark Plug refunds half the first kick's cd, LE CHAT's Bell gives +30 starting Focus, Riftmaw Tooth pays Focus on a denied self-heal. Tokens mint off your clean-kick count.",
},
# ============================================================ MENDER · HEALER
"mender": {
	"name": "THE MENDER", "role": "HEALER · KEEP-ALIVE", "accent": "win",
	"verb": "Feed one 5-pip LITANY chain — the two aspects fill it by playing OPPOSITE.",
	"fantasy": "You keep four bars alive through a raid you can NOT out-heal by spamming. Every in-condition heal links a Litany chain (bigger heals, then a party Benediction at 5), and your Aspect decides the condition: Tidecaller lights pips by topping AHEAD of damage, Brinkwarden by catching allies BEHIND, in the red. Same meter, opposite playstyle. You cast by hovering a raid frame and click-casting (or 1-6/Q/E/7).",
	"resources": [
		{"name": "MANA", "tint": "void", "body": "900 max, regens 8/s. Pays every spell (GCD 1.2s). A PERFECT dodge refunds 20; Meditate restores 280. Efficiency (mend over flash) matters — you can dry out."},
		{"name": "LITANY (pips)", "tint": "gold", "body": "0–5 combo meter. +1 per IN-CONDITION flash/mend; decays a pip after 3s idle. Payloads scale ×(1+0.15·pips), and the 5th pip cashes a party Benediction bloom then resets. The condition is INVERTED per aspect (see below)."},
	],
	"defense": {"name": "DODGE", "key": "SPACE / F",
		"body": "Healers ARE hittable — rand-target bolts and AoE 'doom beats' hit you (your own frame joins the triage list, self-castable). Dodge CANCELS your in-progress cast: mana is only charged at resolve, so the cancel costs you the TIME, not the mana. The cast-vs-dodge call is the healer's discipline test. A PERFECT dodge refunds 20 mana."},
	"moves": [
		{"name": "Flash Heal", "key": "1  (R-click)", "cost": "22 mana · 1.5s · heal 70", "tag": "",
			"body": "Emergency single heal — FEEDS Litany (topped→Tide / caught-low→Brink)."},
		{"name": "Mend", "key": "2  (L-click)", "cost": "16 mana · 2.6s · heal 95", "tag": "",
			"body": "Efficient filler single heal — also feeds Litany. Your bread and butter."},
		{"name": "Renew", "key": "3  (Sh+L)", "cost": "18 mana · instant HoT", "tag": "",
			"body": "12/tick over 9s. Pre-cast before damage lands."},
		{"name": "Ward", "key": "4  (Sh+R)", "cost": "20 mana · instant · 60 absorb · cd 6", "tag": "",
			"body": "Shield to blunt a spike. Tidecaller's flywheel food — the hits it eats re-bank Reservoir."},
		{"name": "Cascade", "key": "5  (Ct+L)", "cost": "40 mana · 2.0s · 3×45 smart", "tag": "",
			"body": "Smart AoE — heals the 3 lowest. Spread raid damage."},
		{"name": "Wellspring", "key": "6  (Ct+R)", "cost": "30 mana · instant · all ×90 · cd 30", "tag": "",
			"body": "Raid-wide burst heal cooldown. Your 'oh no' button for AoE."},
		{"name": "Dispel", "key": "Q  (M-click)", "cost": "10 mana · off-GCD · cd 8", "tag": "",
			"body": "Cleanse a debuff. Off-GCD, and your class-signature skill (mints Tokens)."},
		{"name": "Meditate", "key": "E", "cost": "free · off-GCD · +280 mana · cd 45", "tag": "",
			"body": "Mana recovery in a lull — don't let the raid dip while you channel intent."},
	],
	"aspects": [
		{"id": "tidecaller", "name": "TIDECALLER", "tint": "steel", "tagline": "Play AHEAD — keep every bar above the tide.",
			"identity": "The proactive healer. You bank the OVERHEAL and pre-empt spikes with shields — win before the damage lands.",
			"bar": "Litany lights when a flash/mend leaves the target ≥60% (topped AHEAD). RESERVOIR (0–520): overheal banks ×0.55. SURGE dumps the whole Reservoir as raid shields a beat AHEAD of a spike — and the FLYWHEEL re-banks 35% of what those shields absorb, so it re-arms out of the very hits it eats.",
			"rotation": [
				"Over-heal steadily (mend/flash), leaving targets ≥60% → bank overheal + light pips.",
				"Pre-Ward the incoming spike.",
				"Surge AHEAD of the AoE so shields are up when it lands.",
				"Shields eat the hit → flywheel refills the Reservoir.",
				"Cash the 5th pip Benediction; repeat a beat ahead of the boss.",
			],
			"branches": [
				{"name": "Shield-flywheel", "via": "boons: Floodgate, Deep Reservoir, Undertow",
					"body": "Surge also heals, Reservoir cap +200, +20% overheal banked. A self-refilling shield engine — spam Surge every spike."},
				{"name": "Ward-tank", "via": "boons: Bulwark, Sanctified Ward (opus)",
					"body": "Wards absorb +40%, and a fully-consumed Ward heals + cleanses. Pre-shield everything; damage barely touches HP."},
			]},
		{"id": "brinkwarden", "name": "BRINKWARDEN", "tint": "crimson", "tagline": "Play BEHIND — park them in the red.",
			"identity": "The reactive gambler. You let allies ride low (where your heals are cheap AND huge) and cash it into Nerve — bloodied allies also hit harder.",
			"bar": "Litany lights when a flash/mend CATCHES a target that was ≤40% (bloodied). Low-HP scaling makes those heals up to 2.5× and 45% cheaper. NERVE (0–100): +7/s per bloodied ally. LAST STAND spends most of it for a party DR window + a rolling HoT that deliberately KEEPS allies bloodied (so Nerve income + the damage buff survive the save).",
			"rotation": [
				"Let allies ride into the red (≤40%) — don't top them early.",
				"CATCH with a big-scaled flash/mend (cheap + huge) → lights pips.",
				"Accrue Nerve off the bloodied count.",
				"Last Stand to survive a spike WHILE keeping allies bloodied.",
				"Nerve keeps climbing across the save; cash pips into Benediction.",
			],
			"branches": [
				{"name": "Nerve-engine", "via": "boons: Blood Pact, Steel Nerve",
					"body": "Bloodied allies feed +50% Nerve, +3/s base. Last Stand comes up constantly — ride the edge with a safety net always charged."},
				{"name": "Clutch-catch", "via": "boons: Second Wind (opus), + shared Overflow/Afterglow",
					"body": "Last Stand also cleanses everything; catch-heals leave shields/HoTs. Let it get scary, then pull the whole raid back from the brink in one beat."},
			]},
	],
	"gear": "CURIOS: Salt Vial makes Dispel also heal 25, LE CHAT's Bell gives +30 starting mana, Riftmaw Tooth pays mana on a denied self-heal, Swan Song blasts + heals allies on your death. Tokens mint off your Dispel count.",
},
# ============================================================ BLOOMWEAVER · HEALER
"bloomweaver": {
	"name": "THE BLOOMWEAVER", "role": "HEALER · ANTICIPATE", "accent": "verdance",
	"verb": "No mana, no direct heals — plant HoTs & wards AHEAD, then BLOOM them on the spike.",
	"fantasy": "The proactive healer, the Mender's inverse: you can NOT react-heal — there are no direct heals in your book. You keep four bars alive by PRE-PLANTING (Growth HoTs, Barkskin wards) and cashing them at the right beat. Verdance, your spec gauge, only fills from healing that actually LANDS — overheal and wilted wards earn NOTHING, so the gauge doubles as your efficiency score. You cast by hovering a raid frame and click-casting (or 1-4/Q/E/7); double-tapping a growing ally BLOOMS it.",
	"resources": [
		{"name": "SAP", "tint": "sap", "body": "100 max, regens 12/s — a fast energy bar, not mana. Pays Growth and Barkskin: the short-horizon triage pressure. A PERFECT dodge (+12) and a Perfect Ward refund Sap; your signatures hand some back per ally hit. You CAN dry out mid-spike — plant before you need it, not after."},
		{"name": "VERDANCE", "tint": "verdance", "body": "0–100, EARNED not regened: +0.10 per point of effective HoT healing, +0.15 per point a ward actually absorbs. Overheal and wilted wards earn zero — the gauge IS your efficiency meter. Spent ALL AT ONCE by your Aspect signature (min 20 to fire)."},
	],
	"defense": {"name": "DODGE", "key": "SPACE / F",
		"body": "You ARE hittable — rand-target and AoE 'doom beats' hit your own frame (self-castable, on the triage list). Dodge CANCELS an in-flight Overgrowth: Sap is only charged at resolve, so the cancel costs you the TIME, not the Sap — the anticipation healer's cast-vs-dodge call. A PERFECT dodge refunds 12 Sap (Verdance stays healing-earned). F also dodges string-combo BEATS."},
	"moves": [
		{"name": "Growth", "key": "1  (L-click)", "cost": "15 sap · instant HoT", "tag": "",
			"body": "12/tick over 9s (6 ticks). The seed of everything — pre-plant it. DOUBLE-TAP a growing ally to BLOOM: cash its remaining ticks instantly (×0.9, slightly lossy — so bloom timing is a real decision)."},
		{"name": "Barkskin", "key": "2  (R-click)", "cost": "25 sap · 55 absorb · cd 8", "tag": "",
			"body": "A ward on one ally (lasts 6s). Fully CONSUMED by damage = a PERFECT WARD (refund Sap + bonus Verdance); left to expire unused = it WILTS (visible waste). Ward the telegraphed spike a beat early."},
		{"name": "Overgrowth", "key": "3  (Sh+L)", "cost": "40 sap · 2.0s cast · cd 12", "tag": "",
			"body": "Raid-wide: plants/refreshes a Growth on EVERY ally. Your setup button — cast it in a lull (a dodge cancels it, and you only eat the Sap if it resolves)."},
		{"name": "Thornlash", "key": "4  (Ct+R)", "cost": "10 sap · 18 dmg", "tag": "",
			"body": "Greed filler — poke the boss when the garden's tended and you've Sap to spare."},
		{"name": "Sap Rot", "key": "Q  (M-click)", "cost": "20 sap · off-GCD · cd 8", "tag": "",
			"body": "Cleanse a debuff — and 'rot becomes flowers': it plants/refreshes a Growth on the target. Off-GCD, and your class-signature skill (mints Tokens)."},
		{"name": "Lifesurge", "key": "E  (Ct+L)", "cost": "free · off-GCD · cd 30", "tag": "",
			"body": "The panic button: mass-BLOOMS every living Growth at once (×1.25). Its power = how much you pre-planted — useless on an empty field."},
		{"name": "Wildbloom", "key": "7  (Sh+R)", "cost": "spend ALL Verdance", "tag": "wildgrove",
			"body": "Wildgrove signature: heals every Growth'd ally for Verdance×1 and RESTARTS their Growths (min 20 gauge). Cash a fat gauge into a garden-wide surge."},
		{"name": "Briarheart", "key": "7  (Sh+R)", "cost": "spend ALL Verdance", "tag": "thornveil",
			"body": "Thornveil signature: converts Verdance into party-wide THORN wards (×0.8, biting harder at high snap-streak; min 20 gauge). Wrap the raid in reflecting bark."},
	],
	"aspects": [
		{"id": "wildgrove", "name": "WILDGROVE", "tint": "verdance", "tagline": "RIPEN the field → harvest in the window.",
			"identity": "The garden-tender. A Growth MATURES over its life; harvest it in the ripe window for a bloom bonus. Tending the whole field to peak — not just keeping HoTs up — is the game.",
			"bar": "FLOURISH + RIPEN: ≥3 allies carrying a Growth lights FLOURISH (all your healing +25%); when the field is also RIPE it upgrades to +42%. A Bloom cashed inside a Growth's ripe window (45%–88% matured) pays ×1.6. Signature WILDBLOOM heals every Growth'd ally for your whole Verdance gauge and restarts their Growths.",
			"rotation": [
				"Overgrowth (or seed Growths) to get ≥3 allies growing → light Flourish.",
				"Let the field MATURE into the ripe window (tend it to peak).",
				"Harvest ripe Growths with a double-tap Bloom (×1.6 in the window).",
				"Effective ticks fill Verdance — overheal earns nothing, so stay efficient.",
				"Cash a full gauge with Wildbloom for a garden-wide surge, then replant.",
			],
			"branches": [
				{"name": "Full-garden Flourish", "via": "boons: Evergreen, Photosynthesis, Deep Roots",
					"body": "Flourish at 2 Growths, +50% Verdance from ticks, Growths last 12s. Keep the whole field lit and efficient — the passive +healing carries the fight."},
				{"name": "Verdant surge", "via": "boons: Verdant Surge (opus), Quickbloom",
					"body": "Wildbloom also plants on allies who lacked a Growth; Bloom cashes 105%. Turn the signature into a raid-wide reseed + top-off in one beat."},
			]},
		{"id": "thornveil", "name": "THORNVEIL", "tint": "thorn", "tagline": "Snap wards → reflect → bite back.",
			"identity": "The healer-DPS hybrid. Your wards REFLECT the damage they eat, and chaining Perfect Wards ramps the reflect — you heal by hurting the boss. The forgiving, aggressive aspect.",
			"bar": "THORNS + SNAP-STREAK: a ward reflects 45% of what it absorbs, and every consecutive PERFECT WARD ('snap') ramps that toward 90% (plus a boss spike ~+26 that scales with the streak). A ward that WILTS breaks the streak. Signature BRIARHEART dumps Verdance into party-wide thorn wards that bite harder the higher your streak.",
			"rotation": [
				"Ward the ally about to be hit — time it so the ward is FULLY consumed (a snap).",
				"Chain snaps to ramp the reflect (45% → 90%) and spike the boss.",
				"Never let a ward WILT — an unused ward breaks the streak (the 'miss').",
				"Absorbs fill Verdance; keep the wards landing on real damage.",
				"Cash Verdance with Briarheart for party-wide thorn wards at peak streak.",
			],
			"branches": [
				{"name": "Barbed reflect", "via": "boons: Barbed Bark, Perfect Harvest",
					"body": "Barbed Bark lifts the whole reflect band (up to 100% at full streak); Perfect Harvest refunds 25 Sap and +8 more Verdance per snap. Lean all the way into damage-by-warding — the boss bleeds off your shields."},
				{"name": "Self-seeding wards", "via": "boons: Evergreen Cycle (opus), Ringbark",
					"body": "A Perfect Ward replants a Growth on its bearer; Barkskin cd -3s. Ward constantly, and every snap re-greens the field for free."},
			]},
	],
	"gear": "CURIOS: the healer curios apply — Salt Vial makes your cleanse (Sap Rot) also heal, LE CHAT's Bell gives +30 starting Sap, Riftmaw Tooth pays Sap on a denied self-heal, Swan Song blasts + heals allies on your death. Draft the GARDEN slot-verbs (Barkward Echo / Seedsower / Rootstep triggers + Bramble Burst / Sapwell / Petalfall payloads) to make every Bloom a proc moment; Deep Garden (opus) fires them TWICE at 3+ Growths. Tokens mint off your Perfect-Ward count.",
},
}

## The class guide for a char_class id (bulwark/twinfang/voidcaller/mender). {} if none.
static func entry(class_id: String) -> Dictionary:
	return DATA.get(class_id, {})

## The one aspect sub-dict for a class+aspect (or {} if not found).
static func aspect_of(class_id: String, aspect_id: String) -> Dictionary:
	for a in DATA.get(class_id, {}).get("aspects", []):
		if String(a.get("id", "")) == aspect_id:
			return a
	return {}
