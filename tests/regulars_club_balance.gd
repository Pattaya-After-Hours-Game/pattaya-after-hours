extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")

func _initialize() -> void:
	call_deferred("run")

func scenario(seed_value: int, level: int, slow: bool = false, music_level: int = 1, training_level: int = 2) -> Dictionary:
	var m = Campaign.new(seed_value)
	var st = m.street
	var e = st.economy
	var b: Dictionary = st.selected()
	m.s.day = 8
	m.s.rep = 100
	m.s.cash = 20000
	m.s.street.event_wait = 10000000
	b.stage = 2
	b.regulars = 40
	b.club_level = level
	b.supplier_level = 4
	b.restock = true
	b.equipment.merge({"sign":1,"comfort":1,"fridge":1,"pool":2,"seating":2,"music":music_level},true)
	st.action("hire",0)
	if not slow:
		st.action("hire",0)
		for person in b.team: person.training = training_level
		b.action_levels.pouring = 3
		b.auto_serve = true
	b.customers.clear()
	b.stock = 50
	e.ensure_stock_lots(b)
	var opening: int = m.s.cash+b.stock*e.stock_unit_cost(b)
	for second in 600: st.tick(1)
	# One untrained recruit can now be a faster discovery. Bound actual service,
	# keeping the same random hire in each matched club scenario.
	return {"sales":b.sold,"orders":b.orders,"cash":m.s.cash,"profit":m.s.cash+b.stock*e.stock_unit_cost(b)-opening,"service_cap":1+600/e.service_seconds(b.team[0])}

func run() -> void:
	var failures := 0
	var profits := [0,0,0,0]
	var sales := [0,0,0,0]
	var upgrades := [0,0,0]
	for seed_value in range(1,11):
		for level in 4:
			var result := scenario(seed_value,level)
			profits[level] += result.profit
			sales[level] += result.sales
			if result.cash<0 or result.sales>result.orders: failures += 1
		for option in 3:
			var improved := scenario(seed_value,3,false,2 if option!=1 else 1,4 if option!=0 else 2)
			upgrades[option] += improved.profit
			if improved.cash<0 or improved.sales>improved.orders: failures += 1
		var slow := scenario(seed_value,3,true)
		if slow.sales>slow.service_cap: failures += 1
	for level in range(1,4):
		if profits[level]<=profits[level-1] or sales[level]<=sales[level-1]: failures += 1
	print("REGULARS CLUB · ten matched day-eight runs per tier · 600s each · profits %s · sales %s" % [profits,sales])
	print("STAGE TWO OPTIONS · music / training / both profits: %s (club-three baseline %d)" % [upgrades,profits[3]])
	if upgrades[2]<=profits[3]: failures += 1
	print("REGULARS CLUB BALANCE · %d failures across 80 scenarios" % failures)
	quit(1 if failures else 0)
