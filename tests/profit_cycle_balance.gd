extends "res://tests/economy_balance.gd"

# Matched operating businesses, not fresh-game pacing. Only the stated upgrade differs.
func bottleneck_case(seed_value: int, kind: String, upgrade: String) -> Dictionary:
	var m = Campaign.new(seed_value)
	var st = m.street
	var e = st.economy
	var b: Dictionary = st.selected()
	m.s.cash = 50000
	m.s.rep = 50
	m.s.street.event_wait = 1000000
	b.stage = 1 if kind in ["seating","music"] else 2
	b.equipment.merge({"sign":1 if b.stage==1 or kind=="appeal" else 3,"fridge":2,"music":0 if b.stage==1 else 2},true)
	b.supplier_level = 2
	b.restock = true
	st.action("hire",0)
	st.action("hire",0)
	for person in b.team: person.training = 0 if kind=="service" else 2 if b.stage==1 else 4
	b.action_levels.pouring = 3
	b.auto_serve = kind in ["seating","music"]
	if kind in ["seating","music"]:
		st.announce(1)
		st.start_event()
		m.s.street.event.remaining = 1000
	if upgrade=="seating": b.equipment.seating += 1
	if upgrade=="music": b.equipment.music += 1
	if upgrade=="appeal": b.equipment.sign += 1
	if upgrade=="service":
		for person in b.team: person.training += 1
	e.clear_visits(b)
	b.stock = 70
	e.ensure_stock_lots(b)
	var opening: int = m.s.cash+b.stock*e.stock_unit_cost(b)
	for second in 600: st.tick(1)
	return {"profit":m.s.cash+b.stock*e.stock_unit_cost(b)-opening,"sales":b.sold,"orders":b.orders,"arrivals":b.arrivals,"offered":m.s.street.offered,"cash":m.s.cash,"lost_full":b.lost_full,"lost_service":b.lost_service,"lost_stock":b.lost_stock}

func run() -> void:
	var failures := 0
	var controls := 0
	for kind in ["seating","music","service","appeal"]:
		var totals := [0,0,0]
		var sales := [0,0,0]
		for seed_value in range(1,11):
			var unrelated := "appeal" if kind in ["seating","music"] else "seating"
			for option in 3:
				var result := bottleneck_case(seed_value,kind,["",kind,unrelated][option])
				totals[option] += result.profit
				sales[option] += result.sales
				if result.sales>result.orders or result.arrivals>result.offered+3 or result.cash<0: failures += 1
		print("CYCLE BOTTLENECK · %s · baseline/matched/unrelated · profit %s · sales %s" % [kind,totals,sales])
		if totals[1]<=totals[0] or totals[1]<=totals[2] or sales[1]<=sales[0]: failures += 1
	for style in ["click-heavy","balanced","mostly-idle"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,style,600,"manual",true,"profit-cycle")
			measure_cadence(result)
			print(JSON.stringify(result))
			if result.stage3<0 or result.cash<0 or result.sales>result.orders or result.arrivals>result.offered+3: failures += 1
			# The requested exceptional staff can beat the ordinary cadence floor.
			# Keep that floor on a matched ordinary-crew control and all macro gates
			# on the lucky run; never suppress random hiring in the normal policies.
			if style!="mostly-idle" and result.cycle_median<140 and "staff-platinum" in result.talents:
				var control := simulate(seed_value,style,600,"manual",true,"profit-cycle",1,true)
				measure_cadence(control)
				controls += 1
				print("LEGENDARY CADENCE · %s seed %d · lucky %.1fs / common control %.1fs" % [style,seed_value,result.cycle_median,control.cycle_median])
				if control.cycle_median<140 or control.cycle_median>300 or result.cycle_median>=control.cycle_median: failures += 1
				if roundi(result.stage2/60.0)<28 or roundi(result.stage2/60.0)>45 or roundi(result.second/60.0)<75 or roundi(result.second/60.0)>115 or roundi(result.stage3/60.0)<110 or roundi(result.stage3/60.0)>210 or result.manager_saving_gap>21*60 or result.longest_investment_gap>38*60: failures += 1
			elif style!="mostly-idle" and (result.cycle_median<140 or result.cycle_median>300):
				printerr("CYCLE CADENCE FAIL: %s seed %d median %ds" % [style,seed_value,result.cycle_median])
				failures += 1
	print("PROFIT CYCLE · %d failures across 120 paired scenarios, nine random-hire campaigns and %d ordinary controls" % [failures,controls])
	quit(1 if failures else 0)

func measure_cadence(result: Dictionary) -> void:
	var gaps := []
	var previous: int = result.stage2
	for investment in result.established_investments:
		gaps.append(int(investment)-previous)
		previous = investment
	var sorted := gaps.duplicate()
	sorted.sort()
	result.cycle_median = (float(sorted[(sorted.size()-1)/2])+float(sorted[sorted.size()/2]))/2.0 if not sorted.is_empty() else -1
	result.cycle_gaps = gaps
