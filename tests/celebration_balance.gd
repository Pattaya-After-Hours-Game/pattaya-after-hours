extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")

func _initialize() -> void:
	call_deferred("run")

func scenario(seed_value: int, party: bool, prepared: bool) -> Dictionary:
	var m = Campaign.new(seed_value)
	var st = m.street
	var e = st.economy
	var b: Dictionary = st.selected()
	m.street.selected().cash = 50000
	# Fixed comparable day-six businesses; these are paired scenarios, not pacing runs.
	st.action("equipment",0)
	st.action("equipment",2)
	st.action("equipment",3)
	if prepared:
		for i in 3: st.action("equipment",4)
		st.action("equipment",8)
		st.action("hire",0)
		for i in 2:
			st.action("train_staff",0)
			st.action("action_upgrade",0)
	m.street.selected().cash = 3000
	b.customers.clear()
	b.stock = 70
	e.ensure_stock_lots(b)
	m.s.day = 7 if party else 6
	m.s.street.minute = 720
	st.celebration_tick()
	var start_value: int = m.street.selected().cash+b.stock*e.stock_unit_cost(b)
	for second in 780:
		if b.stock<12: e.restock(b)
		if e.action_status(b,"serve").enabled: st.action("serve")
		if e.action_status(b,"chat").enabled: st.action("chat")
		elif e.action_status(b,"welcome").enabled: st.action("welcome")
		st.tick(1)
	return {"arrivals":b.arrivals,"sales":b.sold,"happy":b.happy,"regulars":b.regulars,"lost":b.lost_full+b.lost_service+b.lost_stock,"contribution":m.street.selected().cash+b.stock*e.stock_unit_cost(b)-start_value,"cash":m.street.selected().cash,"orders":b.orders,"offered":m.s.street.offered,"report":m.s.street.celebration.last_report}

func run() -> void:
	var failures := 0
	for prepared in [false,true]:
		var totals := {"ordinary_sales":0,"party_sales":0,"ordinary_profit":0,"party_profit":0,"ordinary_lost":0,"party_lost":0}
		for seed_value in range(1,31):
			var ordinary := scenario(seed_value,false,prepared)
			var party := scenario(seed_value,true,prepared)
			totals.ordinary_sales += ordinary.sales
			totals.party_sales += party.sales
			totals.ordinary_profit += ordinary.contribution
			totals.party_profit += party.contribution
			totals.ordinary_lost += ordinary.lost
			totals.party_lost += party.lost
			if party.cash<0 or party.sales>party.orders or party.arrivals>party.offered+3 or party.report.sales!=party.sales or party.report.arrivals!=party.arrivals-3: failures += 1
		if prepared and (totals.party_profit<=totals.ordinary_profit or totals.party_sales<=totals.ordinary_sales): failures += 1
		print("CELEBRATION COMPARISON · prepared=%s · %s" % [prepared,JSON.stringify(totals)])
	print("CELEBRATION BALANCE · %d failures across 60 paired trading-day scenarios" % failures)
	quit(1 if failures else 0)
