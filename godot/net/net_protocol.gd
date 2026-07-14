## NetProtocol — the wire format for Rift online (R2). JSON text frames over
## WebSocket; every message is a Dictionary with "t" = type. Tiny by design:
## lockstep streams INPUTS, not state (see RAID-PLAN.md §R2).
##
## client -> server:  join{room,name,ver} · claim{seat} · unclaim{}
##                    aspect{aspect} · class{cls} · ready{on} · boss{enc} (host) · start{}
##                    mapstart{} (host — MAP-3b) · node{id} (leader) · choice{i} (leader)
##                    arm{...} · pick{id} (online boons: this seat's drafted boon) ·
##                    input{action} · leave{}
## server -> client:  welcome{id,ver} · err{msg} · room{...lobby snapshot incl enc...}
##                    start{spec, you} · f{n, in:[[seat_i,action]..], cs?, ai?:[seat_i..]}
##                    end{won,n,cause} · arming{...}
##                    map{...campaign snapshot incl seed...} · mapstop{title,body,choices,accent}
##                    draft{} (online boons: pick a boon now) · campaign{won}
class_name NetProtocol
extends RefCounted

const VERSION := 19     # v19: THE BIG-SWING ANSWER (TANK-PLAN §11) — CHARGED PARRY: new `defense_release` input action (ClassKit.on_defense_release, Duelist-only consumer) + the gather/release machine on CRUSH strikeless busters (hold ≥ charge_min_frac of the wind-up, release on the claim ladder, charged counter, flinch); THE WEAVE REWORK: flurry n default 4->6, gap 0.35->0.26 with seeded per-note flurry_jig (0.45) + authored per-step `gaps`/`n`, riposte scales ×(n/4). Whole-raid checksum rebaseline (stream rng draw order moved) — re-pin, rebuild+redeploy server with clients. v18: TANK-V3 (TANK-PLAN §0 v3 — attempt-3 rebuild, slices S1-S5, this ONE version carries the whole combat rebaseline; determinism still holds per pull, checksums move vs v17). S2 CONTINUITY: the STREAM barrier is RETIRED (combat_core) — publishing is unconditional up to the horizon and never reads s.telegraph/ability timers, so the melee flows through every global (kills the "second between generations" hitch); `stream_breathe` added as the forward-compat quiet-window knob (no caller yet, byte-neutral). S3 CROSS-CLASS RESTORATION (the merge-back gate v2 skipped): dodge_recovery reverted 0.8->0.35 (shared non-tank cadence), the multi-beat BARRAGE un-collapsed (one StrikeRes per beat = COMBAT PILLAR #2 dodge ration), rhythm melee added to Mistral+Gemini (tank channel never blank on any Seal). S4: LATE floor/cap + claim tie-break + legality matrix + landed-parry mit .95 restored — all on-top-of-v18 combat changes, no further bump. S6 THE PRESS RESTORED (§0 pass 2, the Twinfang model): stream presses judged INSTANTLY at the press (boss.stream_answers), symmetric around gate-touch on the grade_*_frac ladder (parry ±parry_land); damage bars hold stream_resolve_slack (0.15s) past gate-touch so hair-late presses connect; duel_answer carries signed off_ms + bar id; obs bars carry `answered` — still on-top-of-v18, no further bump. Re-pin every raid checksum; rebuild+redeploy server with clients (old versions rejected at handshake). v17: TANK-V2 (TANK-PLAN §0) — THE STREAM committed-timeline engine replaces rhythm_* (checksum rebaseline), Duelist kit rewritten deckless (v3 matrix, BULLSEYE grade), BARRAGE RETIREMENT game-wide (strings collapse to one beat) + dodge_recovery 0.35->0.8. v16: THE DUELIST — FLOW=AGGRO (taunt DELETED, passive flow/peel), tank class bulwark->duelist (Bulwark kept as sim fixture). v15: THE DESCENT REBUILD — 4-floor FLOORS (Vorathek=F1 Seal, rings 3-2-1-0), new node kinds (elite/market/jailbreak/minigame/wild + stubs), Prior layer deleted (V#8), claim drops `prior`. v14: net-layer integrity hash — `ih` rides beside `cs` every 30 ticks (seat HP/resource/absorb + rng stream; audit option b). v13: THE PURGE — Voidcaller/Mender/Reckoner deleted; caster=Alchemist, healer=Well(default)/Bloomweaver; gates gone. v12: blade class toggle (dead). v11: THE KILL SWITCH — ⏻ charge + OVERCLOCK arm/cash-out at a Seal
const DEFAULT_PORT := 9077
const DEFAULT_ROOM := "RIFT"

static func encode(msg: Dictionary) -> PackedByteArray:
	return JSON.stringify(msg).to_utf8_buffer()

static func decode(pkt: PackedByteArray) -> Dictionary:
	var v = JSON.parse_string(pkt.get_string_from_utf8())
	return v if v is Dictionary else {}
