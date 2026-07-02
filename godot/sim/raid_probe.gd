## Mechanical probe for the Raid Seals engine additions (MASTER-PLAN §RAID SEALS):
## proves the paths the AI party never exposes in the band sims (its two kickers
## shut out every hotfix, so boss-healed stays 0 there — by skill, not by accident).
##  1. add waves: spawn at threshold -> damage routes to the add -> boss returns
##  2. HEAL_BOSS during an add heals the WITHDRAWN main body (the Opus hotfix)
##  3. cast chains: a kick SKIPS one verse; the chain continues; the empower
##     verse landing raises dmg_buff
##  4. a live silence KILLS the rest of the chain
##  5. rand_target beats roll one living victim each at cast start
##
##   godot --headless --path godot --script res://sim/raid_probe.gd
extends SceneTree

var _fails := 0

func _initialize() -> void:
	print("=== raid_probe — Seals engine mechanics ===")
	_probe_add_and_hotfix()
	_probe_chain_kick_and_empower()
	_probe_silence_kills_chain()
	_probe_rand_beats()
	print("RAID PROBE: %s" % ("ALL OK" if _fails == 0 else "%d FAILURES" % _fails))
	quit(1 if _fails > 0 else 0)

func _check(cond: bool, label: String) -> void:
	print("  %s %s" % [("PASS" if cond else "FAIL"), label])
	if not cond:
		_fails += 1

## Build a mythos raid with NO policies (nobody acts unless the probe does) and
## an unkillable party — undefended melee would end the fight before the slower
## casts (Chain-of-Thought ~5-13s in) ever telegraph.
func _mythos(seed: int) -> CombatState:
	var s := RaidContent.make_state(seed, RaidContent.make_mythos())
	for seat in s.seats:
		seat.policy = null
		seat.hp_max = 100000.0
		seat.hp = 100000.0
	return s

## Tick until `pred` is true (or a cap) — the boss acts, the party stands there.
func _until(s: CombatState, cap_ticks: int, pred: Callable) -> bool:
	for i in cap_ticks:
		if s.over:
			return false
		CombatCore.update(s)
		if pred.call(s):
			return true
	return false

func _probe_add_and_hotfix() -> void:
	print("add waves + hotfix heal-during-add:")
	var s := _mythos(7)
	var tank := s.seats[0]
	# burst to the first threshold (0.65) — the SONNET wave must take the field
	CombatCore.damage_boss(s, tank, s.boss.hp - s.boss.hp_max * 0.60)
	var spawned := _until(s, 900, func(st): return st.boss.add_i >= 0)
	_check(spawned, "crossing 65% spawns an add between swings")
	if s.boss.add_i < 0:
		return
	_check(String((s.encounter.adds[s.boss.add_i] as AddRes).id) == "sonnet", "first wave is the SONNET subagent")
	var main_hp := s.boss.hp
	var add_hp := s.boss.add_hp
	CombatCore.damage_boss(s, tank, 100.0)
	_check(s.boss.hp == main_hp and s.boss.add_hp == add_hp - 100.0,
		"damage routes to the add; the withdrawn boss is untouchable")
	# kill the sonnet -> the boss returns
	CombatCore.damage_boss(s, tank, s.boss.add_hp + 10.0)
	var back := _until(s, 300, func(st): return st.boss.add_i < 0)
	_check(back, "add death returns the field to the boss")
	# burst to the OPUS wave (0.32) and let a hotfix RESOLVE unkicked
	CombatCore.damage_boss(s, tank, s.boss.hp - s.boss.hp_max * 0.30)
	var opus := _until(s, 900, func(st): return st.boss.add_i >= 0)
	_check(opus and String((s.encounter.adds[s.boss.add_i] as AddRes).id) == "opus", "crossing 32% spawns the OPUS subagent")
	main_hp = s.boss.hp
	var healed := _until(s, 1200, func(st): return st.boss.heal_total > 0.0)
	_check(healed, "an unkicked Hotfix Deployment resolves")
	_check(s.boss.hp > main_hp, "…and it healed the WITHDRAWN main body (+%d)" % int(s.boss.hp - main_hp))

func _probe_chain_kick_and_empower() -> void:
	print("cast chains (Chain-of-Thought):")
	var s := _mythos(11)
	var got := _until(s, 3000, func(st):
		return st.telegraph != null and String(st.telegraph.ability.id) == "myth_cot")
	_check(got, "the chain opener telegraphs")
	if s.telegraph == null:
		return
	CombatCore.stagger_boss(s)           # the kick
	_check(s.telegraph != null and String(s.telegraph.ability.id) == "myth_cot2",
		"a kick SKIPS one verse — verse II starts immediately")
	var buff_before := s.boss.dmg_buff
	var done := _until(s, 400, func(st): return st.telegraph == null)
	_check(done, "the remaining verses resolve")
	_check(s.boss.dmg_buff > buff_before, "the landed Conclusion raised dmg_buff (+%.2f)" % (s.boss.dmg_buff - buff_before))

func _probe_silence_kills_chain() -> void:
	print("silence vs the chain:")
	var s := _mythos(13)
	var got := _until(s, 3000, func(st):
		return st.telegraph != null and String(st.telegraph.ability.id) == "myth_cot")
	_check(got, "the chain opener telegraphs")
	if s.telegraph == null:
		return
	s.boss.silenced_until_tick = s.tick + 120
	CombatCore.stagger_boss(s)
	_check(s.telegraph == null, "a kick under silence ends the whole litany")

func _probe_rand_beats() -> void:
	print("rand_target beats (Agentic Fan-Out):")
	var s := _mythos(17)
	var got := _until(s, 3000, func(st):
		return st.telegraph != null and String(st.telegraph.ability.id) == "myth_fanout")
	_check(got, "the fan-out telegraphs")
	if s.telegraph == null:
		return
	var tg := s.telegraph
	_check(tg.beat_targets.size() == tg.ability.strikes.size(),
		"every beat rolled a victim at cast start")
	var all_alive := true
	var mine_counts_ok := true
	for i in tg.ability.strikes.size():
		var v: Seat = tg.beat_targets.get(i)
		if v == null or not v.alive():
			all_alive = false
		var mine := 0
		for seat in s.seats:
			var obs := CombatCore.observe(s, seat)
			var beats: Array = obs["telegraph"].get("strikes", [])
			if bool((beats[i] as Dictionary).get("mine", false)):
				mine += 1
		if mine != 1:
			mine_counts_ok = false
	_check(all_alive, "every victim is a living raider")
	_check(mine_counts_ok, "each beat is 'mine' for exactly ONE seat")
