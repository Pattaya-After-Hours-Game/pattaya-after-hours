extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")
const E = preload("res://scripts/economy.gd")

func fresh():
	var m = Campaign.new(72)
	m.s.cash = 100000
	m.s.street.pass_credit = -100000000
	m.s.street.event_wait = 1000000
	m.street.selected().customers.clear()
	return m

func guest_with_rounds(m, rounds: int) -> Dictionary:
	var b: Dictionary = m.street.selected()
	for i in 100:
		b.customers.clear()
		m.street.economy.admit(b)
		var guest: Dictionary = b.customers[0]
		guest.pool = false
		if guest.planned_rounds==rounds: return guest
	return {}

func run(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var g := guest_with_rounds(m,1)
	test.check(not g.is_empty() and g.budget==180,"One-round guest has an audience-based plan and finite budget")
	e.serve(b)
	var happy: int = b.happy
	m.street.tick(34)
	test.check(b.customers.size()==1 and g.next==1 and not g.order and b.happy==happy,"Guest occupies the seat while finishing the final drink")
	m.street.tick(1)
	test.check(b.customers.is_empty() and b.happy==happy+1 and b.completed==1 and b.tip_visits==1,"A satisfied one-round visit departs once and counts one tip")
	g = guest_with_rounds(m,2)
	e.serve(b)
	e.order(b,g)
	test.check(not g.order,"Direct order calls cannot bypass drinking time")
	m.street.action("equipment",8)
	test.check(g.next==35,"Music purchase preserves a drink already in progress")
	m.street.tick(35)
	test.check(g.order and g.visit_phase=="waiting","Next planned round becomes a real waiting order")
	e.serve(b)
	test.check(g.next==25,"New drinking interval uses purchased music")
	m.street.tick(25)
	test.check(b.customers.is_empty() and b.completed==2,"Second drink finishes and frees the seat without a fixed ninety-second stay")
	g = guest_with_rounds(m,2)
	e.serve(b)
	g.budget = 0
	m.street.tick(25)
	test.check(b.customers.is_empty() and b.completed==3,"Budget exhaustion ends an otherwise well-served affordable visit")
	g = guest_with_rounds(m,2)
	b.stock = 0
	happy = b.happy
	m.street.tick(31)
	test.check(b.customers.is_empty() and b.happy==happy and b.lost_stock>0,"Stockouts retain a distinct dissatisfied departure")
	# Final drinks do not interrupt a paid pool game.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	b.stage = 3
	b.equipment.music = 4
	b.equipment.pool = 1
	for i in 2:
		e.admit(b)
		b.customers.back().planned_rounds = 1
		b.customers.back().pool = true
	e.pool_tick(b)
	var cash_before: int = m.s.cash
	e.serve(b,2)
	m.street.tick(11)
	test.check(b.customers.size()==2 and b.games.size()==1 and b.customers[0].visit_phase=="finished","Finished drinkers wait for their paid pool game")
	m.street.tick(20)
	test.check(b.customers.is_empty() and b.games.is_empty() and b.pool_income==50 and b.completed==2,"Pool finishes once; both visits free their seats")
	g = guest_with_rounds(m,1)
	g.pool = true
	e.serve(b)
	m.street.tick(11)
	test.check(b.customers.size()==1 and g.visit_phase=="finished","Solo pool guest can wait after finishing the final drink")
	e.order(b,g)
	test.check(not g.order,"A finished guest cannot restart their visit while waiting for pool")
	m.street.tick(C.POOL_PATIENCE-11)
	test.check(b.customers.is_empty() and b.pool_income==50,"A solo pool wait is bounded and cannot manufacture a game fee")
	# Every stage grants options, not free purchased levels.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	for index in [0,2,4,8]:
		var id: String = C.EQUIPMENT[index].id
		for stage in range(1,4):
			b.stage = stage
			var cap: int = C.BEER_CAPS[id][stage-1]
			while b.equipment[id]<cap:
				var quote: Dictionary = e.equipment_offer(b,index)
				cash_before = m.s.cash
				m.street.action("equipment",index)
				test.check(m.s.cash==cash_before-quote.price,"Beer-bar tier settles its published price")
			var quote: Dictionary = e.equipment_offer(b,index)
			test.check(not quote.enabled and (quote.maxed if stage==3 else not quote.maxed and quote.reason.contains("stage")),"Stage cap leaves a locked next-tier offer")
		b.equipment[id] = 0
	b.equipment.pool = 1
	b.equipment.comfort = 1
	b.stage = 1
	b.equipment.seating = 3
	test.check(e.seats(b)==12,"Compact stage-one layout still holds twelve with furniture")
	b.stage = 2
	b.equipment.seating = 4
	test.check(e.seats(b)==20,"Further seating retains compact-layout recovery")
	b.stage = 3
	b.equipment.seating = 7
	b.equipment.pool = 2
	test.check(e.seats(b)==32,"Stage-three maximum furnished capacity is thirty-two")
	m.street.action("hire_gabby")
	var person: Dictionary = b.team[0]
	person.training = 4
	person.service_ready = 17.25
	m.street.action("train_staff",0)
	m.street.action("train_staff",0)
	test.check(e.service_seconds(person)==6 and person.service_ready==17.25 and person.identity=="gabby","New retained training works with Gabby and keeps her deadline")
	b.type = 1
	test.check(e.training_offer(b,0,false).maxed and e.equipment_limit(b,"sign",1)==1,"Other venue types do not gain beer-bar upgrade tracks")
	b.type = 0
	b.equipment.sign = 5
	b.equipment.music = 4
	b.equipment.seating = 7
	b.equipment.fridge = 4
	m.save_game()
	var tiers = Campaign.new(4)
	test.check(tiers.load_game() and tiers.street.selected().equipment==b.equipment and tiers.street.selected().team[0].training==6,"Schema thirteen preserves every purchased beer-bar tier and training")
	var malformed: Dictionary = m.s.duplicate(true)
	malformed.street.bars[0].equipment.sign = 6
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	test.check(m._read(Campaign.SAVE)==null,"Save validation rejects an impossible new frontage tier")
	var traffic: float = e.traffic_rate()
	m.s.street.bars.append(b.duplicate(true))
	test.check(is_equal_approx(e.base_traffic(),15.3) and e.traffic_rate()==traffic,"Frontage expands one bounded street pool, never one stream per bar")
	# Historical visitors and their quotes are not randomly replanned on update.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	g = guest_with_rounds(m,2)
	e.serve(b)
	m.save_game()
	var loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.street.selected().customers[0]==g,"Mid-drink save retains the exact plan and remaining timer")
	m.s.version = 12
	for key in E.visit_fields(): g.erase(key)
	b.erase("completed")
	m.save_game()
	loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.s.version==15 and loaded.s.cash==m.s.cash,"Schema-twelve campaign migrates with no cash or inventory gift")
	var old: Dictionary = loaded.street.selected().customers[0]
	test.check(old.visit_phase=="legacy" and old.next==35 and old.drinks==1 and old.budget==g.budget and old.quoted==g.quoted,"Legacy visit retains quote, budget, drink and departure commitments")
	for audience in 3:
		var one_round := 0
		for i in 1000:
			b.customers.clear()
			e.admit(b,false,false,audience)
			if b.customers[0].planned_rounds==1: one_round += 1
		test.check(absi(one_round-C.ONE_ROUND_CHANCE[audience]*10)<50,"Audience %d has variable one/two-round plans near its defined distribution" % audience)
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	g = guest_with_rounds(m,2)
	b.shift.merge({"open_seconds":120,"revenue":2000,"manager_income":1200,"consumed_stock":300,"operating":100},true)
	var snapshot := JSON.stringify(m.s)
	var summary: Dictionary = e.business_summary(b)
	test.check(summary.profit_per_minute==200 and summary.manager_per_minute==600 and snapshot==JSON.stringify(m.s),"Read-only business summary separates customer trading from guaranteed management")
	for loss in ["lost_stock","lost_service","lost_full"]:
		b.last_shift = E.ledger()
		b.last_shift[loss] = 1
		test.check(e.business_summary(b).bottleneck=={"lost_stock":"stock","lost_service":"service","lost_full":"seating"}[loss],"Advice reflects the completed shift's actual bottleneck")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model = fresh()
	var b: Dictionary = app.model.street.selected()
	b.equipment.seating = 3
	app.drawer_open = true
	app.upgrades_open = true
	app.upgrades_ready_only = false
	app.render()
	var card = app.column.find_child("Upgrade_seating",true,false)
	test.check(card!=null and card.disabled and app.column.find_child("Upgrade_seating_reason",true,false).text.contains("Needs venue stage 2"),"Next seating tier stays visible and locked at stage one")
	b.stage = 2
	app.render()
	card = app.column.find_child("Upgrade_seating",true,false)
	if card: card.pressed.emit()
	test.check(b.equipment.seating==4,"Unlocked seating buys through the shared model")
	app.upgrades_open = false
	guest_with_rounds(app.model,1)
	var snapshot := JSON.stringify(app.model.s)
	app.visit_plans_open = true
	app.open_service_section("reports")
	test.check(snapshot==JSON.stringify(app.model.s),"Visit-plan and profit UI are read-only")
	test.check(app.model.street.economy.visit_lines(b).contains("Waiting for round 1/1"),"Live detail exposes the actual one-round plan")
	app.model.street.economy.serve(b)
	test.check(app.model.street.economy.visit_lines(b).contains("Drinking round 1/1"),"Serving changes the same visit to drinking")
	app.render()
	var customers: Array = app.city.scene_people(b).filter(func(person: Dictionary) -> bool: return person.get("customer",false))
	test.check(customers.size()==1 and customers[0].get("visit_phase","")=="drinking","Production scene receives real drinking state")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
