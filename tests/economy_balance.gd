extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func _initialize() -> void:
	call_deferred("run")

func simulate(seed_value: int, style: String, minutes: int = 600, opening: String = "manual", use_chat: bool = true, feature: String = "") -> Dictionary:
	var model = Campaign.new(seed_value)
	var st = model.street
	var eco = st.economy
	var times := {"seed":seed_value,"style":style,"opening":opening,"chat":use_chat,"feature":feature,"promoter":-1,"compact":-1,"hire":-1,"manager":-1,"chapter1":-1,"longest_investment_gap":0,"manager_saving_gap":0,"first":-1,"pool":-1,"stage2":-1,"second":-1,"stage3":-1}
	var last_investment := 0
	var last_investments := investment_count(model.s.street.bars)
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
		if not eco.automatic_service(bar) and second%click_interval==0 and eco.action_status(bar,"serve").enabled: st.action("serve")
		if use_chat and style!="mostly-idle" and second%click_interval==0 and eco.action_status(bar,"chat").enabled:
			st.action("chat")
		elif second%(10 if style=="click-heavy" else 30 if style=="balanced" else 120)==0 and eco.action_status(bar,"welcome").enabled:
			st.action("welcome")
		if not bar.open: st.action("open")
		if bar.stock<8 and model.s.cash>150: eco.restock(bar)
		# Buy small capacity upgrades before the first renovation; no free money.
		var next_item := -1
		var owner_first := opening=="manual" and style!="mostly-idle"
		if feature=="early-bartender" and bar.team.is_empty():
			st.action("hire",0)
		elif owner_first and bar.action_levels.pouring==0:
			st.action("action_upgrade",0)
			if bar.action_levels.pouring>0 and times.first<0: times.first = second
		elif bar.equipment.sign==0: next_item = 0
		elif owner_first and bar.equipment.seating==0: next_item = 4
		elif owner_first and bar.equipment.pool==0: next_item = 3
		elif not owner_first and bar.team.is_empty() and model.s.cash>=C.BARTENDER_CONTRACT_COST+1000: st.action("hire",0)
		elif not bar.restock and model.s.cash>=1100 and (not owner_first or bar.stage>=2): st.action("restock")
		elif bar.equipment.seating==0: next_item = 4
		elif bar.equipment.pool==0: next_item = 3
		elif bar.equipment.fridge==0 and (not owner_first or bar.stage>=2): next_item = 2
		if next_item>=0 and model.s.cash >= int(C.EQUIPMENT[next_item].cost)+eco.operating_rate(bar)*2:
			st.action("equipment",next_item)
			if bar.equipment[C.EQUIPMENT[next_item].id]>0 and times.first<0: times.first = second
		if bar.equipment.pool>0 and times.pool<0: times.pool = second
		if not feature.is_empty() and bar.equipment.pool>0:
			if feature=="compact-first" and bar.equipment.seating<3: st.action("equipment",4)
			if feature in ["promoter-first","service-first"]:
				if bar.action_levels.pouring<2: st.action("action_upgrade",0)
				elif bar.equipment.seating<3: st.action("equipment",4)
				elif eco.promoter_index(bar)<0 and (feature=="promoter-first" or bar.stage>=2): st.action("hire",3)
			var promoter: int = eco.promoter_index(bar)
			if promoter>=0:
				if times.promoter<0: times.promoter = second
				if not eco.contracted(bar.team[promoter]): st.action("rehire",promoter)
				if bar.stage>=2 and bar.team[promoter].audience_training<int(bar.stage)-1: st.action("train_audience",promoter)
			if bar.equipment.seating==3 and times.compact<0: times.compact = second
		if feature in ["music-first","auto-serve","supplier-first","automation-bundle"] and bar.equipment.pool>0:
			if feature in ["music-first","automation-bundle"] and not bar.equipment.music: st.action("equipment",8)
			if feature in ["auto-serve","automation-bundle"] and bar.stage>=2:
				if not bar.auto_serve: st.action("auto_serve")
				elif bar.action_levels.pouring<4: st.action("action_upgrade",0)
			if feature in ["supplier-first","automation-bundle"] and bar.stage>=2 and bar.supplier_level<3: st.action("restock")
		if bar.stage==1 and eco.upgrade_reason(bar).is_empty(): st.action("upgrade")
		if bar.stage>=2 and times.stage2<0: times.stage2 = second
		if owner_first and bar.stage>=2 and bar.action_levels.pouring<3:
			st.action("action_upgrade",0)
		# A contract is a late investment: do not block smaller purchases while saving.
		if bar.stage>=2 and model.s.cash>=C.BARTENDER_CONTRACT_COST+1000:
			if eco.floor_staff(bar)==0: st.action("hire",0)
			else:
				for member in bar.team.size():
					if bar.team[member].role==0 and not eco.contracted(bar.team[member]): st.action("rehire",member)
		if eco.floor_staff(bar)>0:
			if times.hire<0: times.hire = second
			for member in bar.team.size():
				if bar.team[member].role==0 and int(bar.team[member].get("training",0))<2 and model.s.cash>2500: st.action("train_staff",member)
		if bar.stage>=2 and not bar.manager and model.s.cash>2000: st.action("manager")
		if bar.manager and opening=="manual" and style!="mostly-idle" and bar.action_levels.welcoming==0:
			st.action("action_upgrade",1)
		if model.s.street.bars.size()==1 and model.s.street.chapter>=1 and model.s.cash>=st.purchase_cost(1)+st.opening_reserve(1):
			st.action("buy",1)
			if model.s.street.bars.size()>1: times.second = second
		if model.s.street.bars.size()>1:
			model.s.street.selected = 1
			var other: Dictionary = st.selected()
			if model.s.cash>C.BARTENDER_CONTRACT_COST+1000:
				if other.team.is_empty(): st.action("hire",0)
				elif not eco.contracted(other.team[0]): st.action("rehire",0)
			if not other.team.is_empty() and int(other.team[0].get("training",0))<2 and model.s.cash>2500: st.action("train_staff",0)
			if not other.restock and model.s.cash>1100: st.action("restock")
			if other.stock<8 and model.s.cash>150: eco.restock(other)
			model.s.street.selected = 0
			if bar.stage==2 and eco.upgrade_reason(bar).is_empty(): st.action("upgrade")
		if bar.manager and times.manager<0:
			times.manager = second
			times.manager_saving_gap = second-last_investment
		if model.s.street.chapter>=1 and times.chapter1<0: times.chapter1 = second
		var investments := investment_count(model.s.street.bars)
		if investments>last_investments:
			times.longest_investment_gap = maxi(times.longest_investment_gap,second-last_investment)
			last_investment = second
			last_investments = investments
		if bar.stage==3:
			times.stage3 = second
			break
		if not model.s.street.event.is_empty() and model.s.street.event.phase=="warning" and model.s.cash>700:
			if model.s.street.event.id in [0,3]: st.action("prepare")
		st.tick(1)
	times.music = st.selected().equipment.music
	times.auto_serve = st.selected().auto_serve
	times.supplier = st.selected().supplier_level
	times.cash = model.s.cash
	times.happy = st.selected().happy
	times.regulars = st.selected().regulars
	times.healthy = st.selected().healthy
	times.sales = model.s.street.served
	times.pouring = st.selected().action_levels.pouring
	times.welcoming = st.selected().action_levels.welcoming
	times.orders = model.s.street.orders
	times.offered = model.s.street.offered
	times.arrivals = model.s.street.arrivals
	return times

# Purchases that improve the business; deliveries/renewals are ordinary upkeep.
func investment_count(bars: Array) -> int:
	var result := 0
	for bar in bars:
		result += int(bar.stage)+int(bar.auto_serve)+int(bar.manager_level)+int(bar.supplier_level)+bar.team.size()
		for value in bar.equipment.values(): result += int(value)
		for value in bar.action_levels.values(): result += int(value)
		for person in bar.team: result += int(person.get("training",0))+int(person.get("audience_training",0))
	return result

func run() -> void:
	var failures := 0
	for style in ["click-heavy","balanced","mostly-idle"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,style)
			print(JSON.stringify(result))
			if result.cash<0 or result.sales>result.orders or result.arrivals>result.offered+3:
				printerr("ECONOMY FAIL: strategy bypassed cash or customer limits")
				failures += 1
			# Opening-arc pass: preserve the first renovation, shorten the mid-game saving wall.
			var bounds := {"first":[120,300],"pool":[600,1200],"stage2":[1800,2700],"second":[5400,7500],"stage3":[7800,14400]}
			if style!="mostly-idle" and (result.manager_saving_gap>1800 or result.longest_investment_gap>2280):
				printerr("PACING FAIL: excessive saving gap / "+style)
				failures += 1
			for milestone in bounds:
				var seconds := int(result[milestone])
				# Mostly-idle is intentionally slower; still must remain solvent and finish.
				# Milestone targets are specified in minutes, not mandatory second-exact timers.
				var minute_precision := roundi(float(seconds)/60.0)*60
				if seconds<0 or (style!="mostly-idle" and (minute_precision<bounds[milestone][0] or minute_precision>bounds[milestone][1])):
					printerr("PACING FAIL: %s / %s / seed %d = %ds" % [style,milestone,seed_value,seconds])
					failures += 1
	# Optional actions are investments, never mandatory progression requirements.
	for opening in ["manual","staff"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,"balanced",600,opening,false)
			print(JSON.stringify(result))
			if result.stage3<0 or (opening=="manual" and (result.pouring!=3 or result.welcoming!=1)):
				printerr("OPTIONAL ACTION FAIL: %s without chat / seed %d" % [opening,seed_value])
				failures += 1
	print("PACING · %d failures across nine target campaigns and six no-chat comparisons" % failures)
	quit(1 if failures else 0)
