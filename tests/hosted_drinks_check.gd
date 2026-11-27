extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")
const BarFine = preload("res://tests/bar_fine_check.gd")

func guest(m: RefCounted, topic: int = 0) -> Dictionary:
	var b: Dictionary = m.street.selected()
	m.street.economy.admit(b,false,false,2)
	var g: Dictionary = b.customers.back()
	g.host_interest = topic
	g.hosted = false
	g.drinks = 1
	g.order = false
	g.next = 35
	g.visit_phase = "drinking"
	g.planned_rounds = 2
	g.fine_budget = 600
	return g

func run(test: SceneTree) -> void:
	var m = BarFine.new().fixture(3)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var g := guest(m)
	m.street.advance(0.37)
	var before := JSON.stringify(m.s)
	e.hosted_offer(b,1)
	e.auto_hosted_offer(b)
	e.hosted_buzz_text(b)
	test.check(before==JSON.stringify(m.s),"Hosted offers, matching and Buzz reads consume neither state nor RNG")
	test.check(e.hosted_offer(b,1).price==220 and e.hosted_offer(b,2).price==180,"Chat specialist earns the advertised forty-baht match premium")
	var appeal: float = e.attraction(b)
	var cash_before: int = m.s.cash
	var stock_before: int = b.stock
	m.street.action("host_drink",1)
	test.check(b.host_rounds.size()==1 and e.pending(b)==1 and m.s.cash==cash_before and b.stock==stock_before,"Choosing company creates one real order; only service earns cash or consumes stock")
	test.check(e.attraction(b)==appeal and b.away.is_empty(),"Hosted-drinks-only colleague stays present and keeps her appeal")
	m.street.action("host_drink",0)
	test.check(b.host_rounds.size()==1,"One guest cannot sponsor two hosts")
	m.street.action("train_host",1)
	test.check(b.host_rounds[0].quote==220,"Training never reprices an accepted sponsored order")
	cash_before = m.s.cash
	var drinks_before: int = g.drinks
	var original_deadline: float = b.host_rounds[0].host_deadline
	b.host_rounds[0].host_deadline = e.action_time()+5
	test.check(e.serve(b,0)==0 and m.s.cash==cash_before,"A zero-sized service request cannot sell an urgent hosted order")
	b.host_rounds[0].host_deadline = original_deadline
	m.street.action("serve")
	test.check(m.s.cash==cash_before+220 and b.stock==stock_before-1 and g.fine_budget==380,"Serving the sponsored order spends real entertainment budget and paid stock")
	test.check(b.shift.hosted_income==220 and b.shift.hosted_drinks==1 and b.shift.hosted_matches==1 and b.shift.consumed_stock==38,"Hosted receipts and consumed stock are separately reported in the actual ledger")
	test.check(g.drinks==drinks_before and b.tip_visits==0 and b.bonus_tips==0 and b.host_rounds[0].state=="drinking","Host's drink does not grant the sponsor another personal round or duplicate first-visit tips")
	before = JSON.stringify(m.s)
	m.street.economy.serve(b)
	test.check(before==JSON.stringify(m.s),"Re-serving a completed hosted order cannot double-charge or reset its timer")
	m.street.action("role",1)
	test.check(b.team[1].role==1,"Role switching cannot bypass a hosted round")
	m.save_game()
	var loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.s.version==17 and loaded.street.selected().host_rounds[0].state=="drinking" and is_equal_approx(loaded.street.selected().host_rounds[0].host_deadline,20.37),"Schema fifteen saves paid hosted rounds and fractional deadlines")
	loaded.street.advance(20)
	test.check(loaded.street.selected().host_rounds.is_empty() and loaded.street.selected().host_cheers==1,"A paid round completes once, including across reload")
	loaded.street.advance(1)
	test.check(loaded.street.selected().host_cheers==1,"Completed rounds cannot repeatedly fill Buzz")

	# Service clocks, no stock and finite waiting apply equally to hosted orders.
	m = BarFine.new().fixture(2)
	b = m.street.selected()
	e = m.street.economy
	g = guest(m)
	m.street.action("host_drink",1)
	b.stock = 0
	cash_before = m.s.cash
	test.check(not e.action_status(b,"serve").enabled and e.blocking_drink(b)==0,"Hosted-only queue correctly asks for house lager when empty")
	m.street.action("serve")
	test.check(m.s.cash==cash_before and b.shift.hosted_drinks==0,"No stock means no hosted sale")
	m.street.advance(30)
	test.check(b.host_rounds.is_empty() and b.host_cheers==0 and b.lost_stock==1,"Unserved hosted order expires without cash, Buzz or endless guest retention")
	m = BarFine.new().fixture(2)
	b = m.street.selected()
	e = m.street.economy
	guest(m)
	m.street.action("host_drink",1)
	e.hire_staff(b,0)
	e.staff_service(b)
	test.check(b.shift.hosted_drinks==1 and b.team[3].drinks_served==1 and b.team[3].service_ready==25,"Bartender's actual hosted sale starts the normal independent service cooldown")

	# Three real completions unlock temporary appeal, never a bonus receipt.
	m = BarFine.new().fixture(3)
	b = m.street.selected()
	e = m.street.economy
	for i in 3:
		guest(m,C.HOST_TOPICS[int(b.team[i].host)])
		m.street.action("host_drink",i)
		e.serve(b)
	cash_before = m.s.cash
	m.s.street.elapsed = 20
	e.hosted_tick(b)
	test.check(b.host_cheers==0 and b.host_buzz_until==50 and m.s.cash==cash_before,"Three paid completions trigger exactly thirty seconds of Room Buzz without a cash award")
	var with_buzz: float = e.attraction(b)
	var supply: float = e.traffic_rate()
	b.host_buzz_until = 0.0
	test.check(with_buzz>e.attraction(b) and supply==e.traffic_rate(),"Buzz competes for existing street visitors without manufacturing customers")

	# Automation prioritises matches and respects the barfine choice and budgets.
	m = BarFine.new().fixture(2)
	b = m.street.selected()
	e = m.street.economy
	g = guest(m)
	m.street.action("auto_host_drinks")
	e.auto_hosted(b)
	test.check(b.host_rounds.size()==1 and b.host_rounds[0].host==1,"Auto-host gives May the matching chat guest ahead of a booking-capable colleague")
	b.host_requests.append(int(g.id))
	test.check(not e.bar_fine_offer(b,0).enabled,"The same guest cannot be booked while sponsoring company")
	e.serve(b)
	m.s.street.elapsed = 20
	e.hosted_tick(b)
	test.check(not e.bar_fine_offer(b,0).enabled and g.fine_budget==380,"A hosted round spends the same finite budget as a barfine")
	m.street.action("auto_host_drinks")
	guest(m)
	e.auto_hosted(b)
	test.check(b.host_rounds.is_empty(),"Auto-host toggle stops new invitations")
	m.street.action("host_drink",1)
	var saved_rounds := JSON.stringify(b.host_rounds)
	b.manager = true
	b.manager_level = 1
	b.restock = true
	m.s.street.last_seen = 1000
	m.street.claim_offline(1100)
	test.check(JSON.stringify(b.host_rounds)==saved_rounds and b.shift.hosted_drinks==1,"Offline estimates never serve or complete sponsored rounds")
	b.open = false
	e.hosted_tick(b)
	test.check(b.host_rounds.is_empty(),"Closure cancels hosted activity without another reward")

	# Old guests keep their original budgets and receive no new invitations.
	m = BarFine.new().fixture(2)
	b = m.street.selected()
	g = guest(m)
	g.fine_budget = 321
	load("res://tests/finance_fixture.gd").legacy(m)
	m.s.version = 14
	for venue in m.s.street.bars:
		for key in e.hosted_fields(): venue.erase(key)
		for visitor in venue.customers:
			visitor.erase("host_interest")
			visitor.erase("hosted")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game(),"A schema-fourteen campaign still loads")
	var lb: Dictionary = loaded.street.selected()
	test.check(lb.customers[0].fine_budget==321 and lb.customers[0].host_interest==-1 and not lb.auto_host_drinks,"Migration preserves old guest money and grants no invitations or automation")
	guest(loaded)
	loaded.street.action("host_drink",1)
	loaded.save_game()
	var invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.SAVE))
	var ib: Dictionary = invalid.street.bars[int(invalid.street.selected)]
	ib.host_rounds.append(ib.host_rounds[0].duplicate(true))
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	test.check(loaded._read(Campaign.SAVE)==null,"Save validation rejects duplicate sponsored orders for the same host and guest")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model = BarFine.new().fixture(2)
	guest(app.model)
	app.drawer_open = false
	var before := JSON.stringify(app.model.s)
	app.render()
	app.update_bar_fine_controls()
	test.check(before==JSON.stringify(app.model.s),"Good Company UI reads offers without inviting, charging or advancing time")
	var invite: Button = app.root_ui.find_child("HostDrink1",true,false)
	test.check(not invite.disabled and invite.text=="Match · ฿220","HUD offers May an actual topic-matched paid round")
	invite.pressed.emit()
	var b: Dictionary = app.model.street.selected()
	test.check(b.host_rounds.size()==1 and b.host_rounds[0].host==1,"Visible Host button queues the shared model order")
	test.use_button(app,"Serve a drink")
	test.check(b.shift.hosted_income==220,"Normal Serve button fulfills the sponsored drink order")
	app.root_ui.find_child("ManageHosts",true,false).pressed.emit()
	test.check(app.service_section=="team","Good Company manage arrow opens the Team controls")
	test.use_button(app,"Host settings  ›")
	test.use_button(app,"Auto-host rounds · ฿1,500")
	test.check(b.auto_host_drinks,"Service exposes the paid auto-host upgrade")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
