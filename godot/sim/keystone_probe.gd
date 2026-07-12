extends SceneTree
## Validate the elite-gate keystone rules (Bill 2026-07-12):
##  1. the NORMAL draft pool (offerable) NEVER contains a keystone
##  2. roll_keystone_offer yields up to KEYSTONE_OFFER_N keystones (all keystone-tagged)
##  3. taking a keystone CAPS the run — a second offer is empty
## Checked for the Well (both specs) + Twinfang (tempo/fermata).

func _initialize() -> void:
	var ok := true
	for pair in [["well", "draw"], ["well", "brim"], ["twinfang", "tempo"], ["twinfang", "fermata"]]:
		var cls: String = pair[0]
		var asp: String = pair[1]
		var run = _start(cls, asp, 4242)
		# 1. no keystone leaks into the normal pool
		var normal := Draft.offerable(run)
		var leaked: Array = []
		for b in normal:
			if Draft.is_keystone(b):
				leaked.append(b["id"])
		var pool_ok := leaked.is_empty()
		# 2. the elite offer is keystones only
		var offer := Draft.roll_keystone_offer(run)
		var offer_ok := offer.size() >= 1 and offer.size() <= Draft.KEYSTONE_OFFER_N
		for b in offer:
			if not Draft.is_keystone(b):
				offer_ok = false
		# 3. take one -> capped
		var cap_ok := true
		if not offer.is_empty():
			Draft.take(run, offer[0])
			cap_ok = Draft.has_keystone(run) and Draft.roll_keystone_offer(run).is_empty()
			# and the taken keystone STILL isn't in the normal pool
			for b in Draft.offerable(run):
				if Draft.is_keystone(b):
					cap_ok = false
		var line := "%s/%s  pool_excludes_keystones=%s  offer=%d %s  cap_after_take=%s" % [
			cls, asp, pool_ok, offer.size(),
			("[" + ", ".join(offer.map(func(b): return String(b["id"]))) + "]"), cap_ok]
		var pass_all := pool_ok and offer_ok and cap_ok
		ok = ok and pass_all
		print(("PASS  " if pass_all else "FAIL  ") + line)
		if not leaked.is_empty():
			print("    LEAKED into normal pool: ", leaked)
	print("\n== ", ("ALL PASS" if ok else "FAILURES"), " ==")
	quit(0 if ok else 1)

func _start(cls: String, aspect: String, seed_v: int):
	match cls:
		"well": return RunState.start_well(aspect, seed_v)
		"twinfang": return RunState.start_twinfang(aspect, seed_v)
		"alchemist": return RunState.start_alchemist(aspect, seed_v)
		"bloomweaver": return RunState.start_bloomweaver(aspect, seed_v)
	return RunState.start_duelist(aspect, seed_v)
