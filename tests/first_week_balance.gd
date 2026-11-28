extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")

func _initialize() -> void:
	call_deferred("run")

func scenario(seed_value: int, day: int) -> Dictionary:
	var m = Campaign.new(seed_value)
	var b: Dictionary = m.street.selected()
	var st = m.street
	var e = st.economy
	m.s.cash = 50000
	m.s.day = day
	m.s.street.minute = 1080
	m.s.street.event_wait = 1000000
	b.stage = 2
	b.equipment.merge({"seating":3,"sign":2,"fridge":2,"pool":1,"music":1},true)
	b.action_levels.pouring = 2
	b.restock = true
	b.supplier_level = 1
	e.hire_staff(b,0)
	b.team[0].training = 2
	b.customers.clear()
	var start: int = m.s.cash+b.stock*38
	st.celebration_tick()
	for second in 240:
		if e.action_status(b,"serve").enabled: st.action("serve")
		if e.action_status(b,"welcome").enabled: st.action("welcome")
		st.tick(1)
	var inventory := 0
	for lot in b.stock_lots: inventory += int(lot.units)*int(lot.cost)
	return {"profit":m.s.cash+inventory-start,"sales":b.sold,"orders":b.orders,"arrivals":b.arrivals,"offered":m.s.street.offered,"cash":m.s.cash}

func run() -> void:
	var totals := [0,0,0,0]
	var sales := [0,0,0,0]
	var failures := 0
	for seed_value in range(1,21):
		for i in 4:
			var result := scenario(seed_value,[2,3,5,7][i])
			totals[i] += result.profit
			sales[i] += result.sales
			if result.sales>result.orders or result.arrivals>result.offered+3 or result.cash<0: failures += 1
	if totals[1]<=totals[0] or totals[2]<=totals[0] or sales[1]<=sales[0] or sales[2]<=sales[0]: failures += 1
	if totals[3]<=totals[2] or sales[3]<=sales[2]: failures += 1
	print("OPENING WEEK · normal / day 3 / day 5 / birthday · contribution %s · sales %s · %d failures across 80 matched nights" % [totals,sales,failures])
	quit(1 if failures else 0)
