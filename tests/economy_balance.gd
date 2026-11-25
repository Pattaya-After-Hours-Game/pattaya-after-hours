extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func _initialize() -> void:
	call_deferred("run")

func simulate(seed_value: int, style: String, minutes: int = 300, opening: String = "manual", use_chat: bool = true) -> Dictionary:
	var model = Campaign.new(seed_value)
	var st = model.street
	var eco = st.economy
	var times := {"seed":seed_value,"style":style,"opening":opening,"chat":use_chat,"first":-1,"pool":-1,"stage2":-1,"second":-1,"stage3":-1}
	for second in minutes*60:
		# Real player prep actions; seconds spent cleaning count toward pacing.
		if st.can_skip():
			var ready := true
			for i in model.s.street.bars.size():
				model.s.street.selected = i
				var venue: Dictionary = st.selected()
				if venue.dirt>0:
					st.action("clean")
					ready = false
			if ready: st.action("skip")
		model.s.street.selected = 0
		var bar: Dictionary = st.selected()
		var click_interval := 1 if style=="click-heavy" else 2 if style=="balanced" else 15
		if second%click_interval==0 and eco.action_status(bar,"serve").enabled: st.action("serve")
		if use_chat and style!="mostly-idle" and second%click_interval==0 and eco.action_status(bar,"chat").enabled:
			st.action("chat")
		elif second%(10 if style=="click-heavy" else 30 if style=="balanced" else 120)==0 and eco.action_status(bar,"welcome").enabled:
			st.action("welcome")
		if not bar.open: st.action("open")
		if bar.stock<8 and model.s.cash>150: eco.restock(bar)
		# Buy small capacity upgrades before the first renovation; no free money.
		var next_item := -1
		var owner_first := opening=="manual" and style!="mostly-idle"
		if owner_first and bar.action_levels.pouring==0:
			st.action("action_upgrade",0)
			if bar.action_levels.pouring>0 and times.first<0: times.first = second
		elif bar.equipment.sign==0: next_item = 0
		elif owner_first and bar.equipment.seating==0: next_item = 4
		elif owner_first and bar.equipment.pool==0: next_item = 3
		elif bar.team.is_empty() and model.s.cash>=720: st.action("hire",0)
		elif not bar.restock and model.s.cash>=1100 and (not owner_first or bar.stage>=2): st.action("restock")
		elif bar.equipment.seating==0: next_item = 4
		elif bar.equipment.pool==0: next_item = 3
		elif bar.equipment.fridge==0 and (not owner_first or bar.stage>=2): next_item = 2
		if next_item>=0 and model.s.cash >= int(C.EQUIPMENT[next_item].cost)+eco.operating_rate(bar)*2:
			st.action("equipment",next_item)
			if bar.equipment[C.EQUIPMENT[next_item].id]>0 and times.first<0: times.first = second
		if bar.equipment.pool>0 and times.pool<0: times.pool = second
		if bar.stage==1 and eco.upgrade_reason(bar).is_empty(): st.action("upgrade")
		if bar.stage>=2 and times.stage2<0: times.stage2 = second
		if bar.stage>=2 and not bar.manager and model.s.cash>2000: st.action("manager")
		if bar.manager and opening=="manual" and style!="mostly-idle" and bar.action_levels.welcoming==0:
			st.action("action_upgrade",1)
		if model.s.street.bars.size()==1 and model.s.street.chapter>=1 and model.s.cash>=st.purchase_cost(1)+st.opening_reserve(1):
			st.action("buy",1)
			if model.s.street.bars.size()>1: times.second = second
		if model.s.street.bars.size()>1:
			model.s.street.selected = 1
			var other: Dictionary = st.selected()
			if other.team.is_empty() and model.s.cash>800: st.action("hire",0)
			if not other.restock and model.s.cash>1100: st.action("restock")
			if other.stock<8 and model.s.cash>150: eco.restock(other)
			model.s.street.selected = 0
			if bar.stage==2 and eco.upgrade_reason(bar).is_empty(): st.action("upgrade")
		if bar.stage==3:
			times.stage3 = second
			break
		if not model.s.street.event.is_empty() and model.s.street.event.phase=="warning" and model.s.cash>700:
			if model.s.street.event.id in [0,3]: st.action("prepare")
		st.tick(1)
	times.cash = model.s.cash
	times.happy = st.selected().happy
	times.regulars = st.selected().regulars
	times.healthy = st.selected().healthy
	times.sales = model.s.street.served
	times.pouring = st.selected().action_levels.pouring
	times.welcoming = st.selected().action_levels.welcoming
	return times

func run() -> void:
	var failures := 0
	for style in ["click-heavy","balanced","mostly-idle"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,style)
			print(JSON.stringify(result))
			var bounds := {"first":[120,300],"pool":[600,1200],"stage2":[1800,2700],"second":[5400,9000],"stage3":[10800,18000]}
			for milestone in bounds:
				var seconds := int(result[milestone])
				# Mostly-idle is intentionally slower; still must remain solvent and finish.
				if seconds<0 or (style!="mostly-idle" and (seconds<bounds[milestone][0] or seconds>bounds[milestone][1])):
					printerr("PACING FAIL: %s / %s / seed %d = %ds" % [style,milestone,seed_value,seconds])
					failures += 1
	# Optional actions are investments, never mandatory progression requirements.
	for opening in ["manual","staff"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,"balanced",300,opening,false)
			print(JSON.stringify(result))
			if result.stage3<0 or (opening=="manual" and (result.pouring!=1 or result.welcoming!=1)):
				printerr("OPTIONAL ACTION FAIL: %s without chat / seed %d" % [opening,seed_value])
				failures += 1
	print("PACING · %d failures across nine target campaigns and six no-chat comparisons" % failures)
	quit(1 if failures else 0)
