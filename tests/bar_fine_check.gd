extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func fixture(stage: int = 2) -> RefCounted:
	var m = Campaign.new(72)
	m.s.cash = 200000
	m.s.rep = 100
	m.s.street.chapter = 2
	load("res://tests/finance_fixture.gd").buy(m.street,1)
	var b: Dictionary = m.street.selected()
	b.stage = stage
	m.street.economy.hire_staff(b,1) # Bee accepts.
	m.street.economy.hire_staff(b,1) # May declines.
	if stage>1: m.street.economy.hire_staff(b,1) # June accepts.
	m.s.street.pass_credit = -1000000
	return m

func request(m: RefCounted, budget: int = 1800) -> Dictionary:
	var b: Dictionary = m.street.selected()
	m.street.economy.admit(b,false,false,2)
	var guest: Dictionary = b.customers.back()
	guest.drinks = 2
	guest.order = false
	guest.next = 35
	guest.planned_rounds = 2
	guest.visit_phase = "drinking"
	guest.fine_budget = budget
	b.host_requests.append(int(guest.id))
	return guest

func run(test: SceneTree) -> void:
	var m = fixture()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var before := JSON.stringify(m.s)
	e.bar_fine_offer(b,0)
	e.host_training_offer(b,0)
	e.auto_bar_fine_offer(b)
	test.check(JSON.stringify(m.s)==before,"Bar-fine quotes and upgrade previews do not alter cash, time or RNG")
	test.check(not e.bar_fine_offer(b,0).enabled,"Bar-fine acceptance requires a real customer request")
	var guest := request(m)
	m.street.advance(0.5)
	var appeal: float = e.attraction(b)
	var cash_before: int = m.s.cash
	var stock_before: int = b.stock
	m.street.action("bar_fine",1)
	test.check(m.s.cash==cash_before and b.away.is_empty(),"A declining host keeps her availability and never earns a booking fee")
	m.street.action("bar_fine",0)
	test.check(m.s.cash==cash_before+500 and guest.fine_budget==1300 and b.away==[0] and b.team[0].host_return==30.5,"Accepted booking pays exactly 500 and saves a fractional thirty-second return deadline")
	test.check(is_equal_approx(e.attraction(b),appeal-0.6) and b.stock==stock_before and b.sold==0 and b.tip_visits==0,"Host absence removes her appeal without manufacturing drinks, stock use or tips")
	test.check(b.shift.bar_fines==1 and b.shift.bar_fine_income==500 and b.shift.revenue==500,"Booking fee appears once in the actual venue ledger")
	before = JSON.stringify(m.s)
	e.accept_bar_fine(b,0)
	test.check(JSON.stringify(m.s)==before,"Repeating acceptance cannot double-pay or consume another request")
	m.street.end_shift()
	test.check(0 in b.away and b.team[0].host_return==30.5,"A report boundary cannot return a host before her booking deadline")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.version==17 and loaded.street.selected().team[0].host_return==30.5,"Schema fourteen round-trips an active booking without rounding or repayment")
	loaded.street.advance(29.5)
	test.check(0 in loaded.street.selected().away,"Host remains away before the saved deadline")
	loaded.street.advance(0.5)
	test.check(not 0 in loaded.street.selected().away and loaded.street.selected().team[0].host_return==0,"Host returns after exactly thirty foreground seconds")

	# Slots, affordability, availability and automation share the manual gate.
	m = fixture(1)
	b = m.street.selected()
	e = m.street.economy
	b.team[1].host = 2
	request(m,499)
	var affordable := request(m,500)
	m.street.action("bar_fine",0)
	test.check(b.shift.bar_fine_income==500 and affordable.fine_budget==0 and b.host_requests.size()==1,"Acceptance skips an unaffordable request without discarding it")
	request(m)
	test.check(e.bar_fine_offer(b,1).reason=="Booking spaces full","Simultaneous bookings respect venue-stage capacity")
	b.open = false
	m.street.advance(30)
	test.check(b.away.is_empty() and not e.bar_fine_offer(b,1).enabled,"Closed foreground time returns hosts without accepting new bookings")
	b.open = true
	request(m) # Closing legitimately clears the previous guests and requests.
	b.team[0].on = false
	test.check(e.bar_fine_offer(b,0).reason=="Off duty","Off-duty hosts cannot accept requests")
	m.street.action("auto_bar_fine")
	cash_before = m.s.cash
	e.auto_bar_fines(b)
	test.check(b.away==[1] and m.s.cash==cash_before+500,"Auto-accept uses the same available willing host and real budget checks")
	m.street.action("auto_bar_fine")
	m.street.advance(30)
	cash_before = m.s.cash
	e.auto_bar_fines(b)
	test.check(b.away.is_empty() and m.s.cash==cash_before,"Switching auto-accept off stops bookings without resetting return timers")

	# Personal progression is purchased, stage-gated and retained through rehire.
	m = fixture(1)
	b = m.street.selected()
	e = m.street.economy
	m.street.action("train_host",0)
	test.check(b.team[0].host_training==0,"Host training tier one needs venue stage two")
	b.stage = 2
	var price: int = e.host_training_offer(b,0).price
	m.s.cash = price-1
	m.street.action("train_host",0)
	test.check(b.team[0].host_training==0,"Host training requires exactly its listed price")
	m.s.cash += 1
	m.street.action("train_host",0)
	test.check(b.team[0].host_training==1 and m.s.cash==0 and e.host_fee(b.team[0])==750,"First paid host tier costs 1500 and raises the fee to 750")
	m.s.cash = 100000
	m.street.action("train_host",0)
	test.check(b.team[0].host_training==1,"Host training tier two needs venue stage three")
	b.stage = 3
	m.street.action("train_host",0)
	test.check(b.team[0].host_training==2 and e.host_fee(b.team[0])==1000 and is_equal_approx(e.host_appeal(b.team[0]),1.8),"Second paid tier costs 3000 and raises appeal and fee")
	request(m)
	m.street.action("bar_fine",0)
	b.team[0].contract_left = 1
	e.advance_contracts(1)
	test.check(0 in b.away and not b.team[0].on,"Contract expiry cannot cancel an active booking's absence")
	m.street.action("rehire",0)
	test.check(b.team[0].host_training==2 and 0 in b.away and b.team[0].host_return==30,"Rehire retains host training and the pending return deadline")
	before = JSON.stringify(b.team)
	m.street.action("role",0)
	test.check(JSON.stringify(b.team)==before,"Role switching cannot bypass an active booking")
	b.manager = true
	b.manager_level = 1
	b.restock = true
	m.s.street.last_seen = 1000
	m.street.claim_offline(1100)
	test.check(b.team[0].host_return==30 and 0 in b.away and b.shift.bar_fine_income==1000,"Offline estimates cannot replay booking fees or advance the live absence")

	# Higher appeal competes for the same finite traffic; it does not add passersby.
	m = fixture(3)
	b = m.street.selected()
	e = m.street.economy
	var before_arrivals: float = e.forecast(b).arrivals
	var before_traffic: float = e.traffic_rate()
	m.street.action("train_host",0)
	m.street.action("train_host",0)
	test.check(e.forecast(b).arrivals>before_arrivals and e.traffic_rate()==before_traffic,"Host upgrades improve expected customer share without creating street traffic")
	m.street.action("train_host",1)
	test.check(b.team[1].host_training==1 and not e.bar_fine_offer(b,1).enabled,"Hosted-drinks-only colleagues can improve appeal without changing consent")
	# The new event runner remains unavailable through the same report boundary.
	m.street.action("hire",0)
	var runner: int = b.team.size()-1
	m.s.street.event = {"id":C.Local.BED,"venue":m.s.street.selected,"runner":runner,"phase":"active","remaining":45,"prepared":true}
	b.away.append(runner)
	request(m)
	m.street.action("bar_fine",0)
	m.street.end_shift()
	test.check(0 in b.away and runner in b.away,"Bed-race runner and timed booking both survive a report boundary")
	m.street.finish_event(true)
	test.check(0 in b.away and not runner in b.away,"Ending the pulled bed-race event returns only its own runner")

	# Old paid absences finish on their legacy report boundary, with no freebies.
	m = fixture()
	b = m.street.selected()
	b.away = [0]
	load("res://tests/finance_fixture.gd").legacy(m)
	m.s.version = 13
	for key in e.bar_fine_fields(): b.erase(key)
	for person in b.team:
		person.erase("host_training")
		person.erase("host_return")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.finance.total()==m.street.finance.total() and loaded.street.selected().away==[0],"Schema thirteen migration retains old paid absences and cash")
	var lb: Dictionary = loaded.street.selected()
	test.check(not lb.auto_bar_fine and lb.team[0].host_training==0,"Migration grants neither auto-accept nor host training")
	loaded.street.end_shift()
	test.check(lb.away.is_empty(),"Legacy absences still finish at their original shift boundary")
	loaded.save_game()
	var invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.SAVE))
	invalid.street.bars[invalid.street.selected].team[0].host_training = 3
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	test.check(loaded._read(Campaign.SAVE)==null,"Save validation rejects out-of-range host training")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model = fixture()
	app.drawer_open = false
	request(app.model)
	var before := JSON.stringify(app.model.s)
	app.render()
	app.update_bar_fine_controls()
	test.check(JSON.stringify(app.model.s)==before,"Bar-fine HUD and Service offers are read-only")
	var accept: Button = app.root_ui.find_child("AcceptBarFine0",true,false)
	test.check(accept!=null and not accept.disabled and accept.text.contains("500"),"Room HUD exposes an enabled 500-baht accept button")
	accept.pressed.emit()
	var b: Dictionary = app.model.street.selected()
	test.check(b.away==[0] and b.shift.bar_fine_income==500,"Room accept button executes the shared booking action")
	accept = app.root_ui.find_child("AcceptBarFine0",true,false)
	test.check(accept.disabled and accept.tooltip_text.contains("30s"),"Accepted host shows her remaining absence without another payment button")
	app.change_tab(0)
	test.use_button(app,"Team")
	test.use_button(app,"Bee · Away  ›")
	test.use_button(app,"Train host · ฿1,500")
	test.check(b.team[0].host_training==1 and b.team[0].host_return==30,"Visible training improves the host without resetting an active booking")
	test.use_button(app,"Back")
	test.use_button(app,"Host settings  ›")
	test.use_button(app,"Auto-accept bar fines · ฿3,000")
	test.check(b.auto_bar_fine and b.auto_bar_fine_on,"Visible automation purchase installs auto-accept")
	test.use_button(app,"Auto-accept bar fines · On")
	test.check(not b.auto_bar_fine_on,"Visible auto-accept toggle can pause automation")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
