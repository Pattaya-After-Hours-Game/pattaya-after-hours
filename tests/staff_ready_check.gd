extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const E = preload("res://scripts/economy.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	m.s.cash = 100000
	m.s.street.pass_credit = -10000000
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.street.action("hire",0)
	var p: Dictionary = b.team[0]
	e.staff_service(b)
	test.check(b.sold==1 and p.drinks_served==1 and p.last_served==0 and p.service_ready==25,"Available staff immediately settles one actual sale and records its owner")
	var ready: float = p.service_ready
	for i in 10:
		m.street.action("rota",0)
		m.street.action("rota",0)
		m.street.action("open")
		m.street.action("open")
		e.staff_service(b)
	test.check(b.sold==1 and p.service_ready==ready,"Rota, closure and repeated service calls cannot reset or bypass cooldown")
	b.customers.clear()
	m.street.tick(25)
	b.stock = 0
	e.admit(b)
	e.staff_service(b)
	test.check(p.service_ready==ready and p.drinks_served==1 and e.staff_indicator(b).contains("out of stock"),"A ready but empty bar consumes neither sale nor cooldown")
	b.stock = 12
	e.staff_service(b)
	test.check(p.drinks_served==2 and e.staff_indicator(b).contains("Served a drink!"),"Restoring stock lets ready staff serve without another warmup")
	m.save_game()
	var loaded = Campaign.new(11)
	test.check(loaded.load_game(),"Cooldown and staff counter save reloads")
	var lb: Dictionary = loaded.street.selected()
	loaded.street.economy.staff_service(lb)
	test.check(lb.team[0].drinks_served==2 and lb.team[0].service_ready==p.service_ready,"Reload preserves remaining cooldown and cannot duplicate a serve")
	# Manual service has its own timer and cannot restart staff recovery.
	b.customers.clear()
	e.admit(b)
	ready = p.service_ready
	m.street.action("serve")
	test.check(p.service_ready==ready and p.drinks_served==2,"Owner clicks do not count as staff sales or change staff cooldown")
	var before := JSON.stringify(m.s)
	e.staff_indicator(b)
	e.staff_status(b,p)
	test.check(JSON.stringify(m.s)==before,"Indicator reads never simulate or award sales")
	# Two ready workers share real orders; only the successful worker cools down.
	m.street.action("hire",0)
	b.customers.clear()
	e.admit(b)
	m.s.street.elapsed = int(p.service_ready)
	e.staff_service(b)
	test.check(p.drinks_served==3 and b.team[1].drinks_served==0 and b.team[1].service_ready==0,"Two ready workers cannot double-sell one waiting order")
	# Staff wins the first queued order when owner auto-serve is also ready.
	m.street.action("auto_serve")
	b.customers.clear()
	e.admit(b)
	var owner_deadline: float = b.serve_ready
	m.street.tick(1)
	test.check(b.team[1].drinks_served==1 and b.serve_ready==owner_deadline,"Staff priority makes real help visible without spending the owner's cooldown")
	# A genuine v8 partial work timer migrates once, not on every reload.
	m.s.version = 8
	for person in b.team:
		person.erase("service_ready")
		person.erase("last_served")
		person.erase("drinks_served")
	p.service_clock = 9
	m.save_game()
	loaded = Campaign.new(11)
	test.check(loaded.load_game() and loaded.s.version==12,"V8 staff records migrate without changing owned progress")
	lb = loaded.street.selected()
	test.check(lb.team[0].service_ready==loaded.s.street.elapsed+16 and lb.team[0].drinks_served==0,"Legacy partial work retains its remaining sixteen seconds; historical sales are not invented")

	# Fractional foreground clocks survive serialization without an early serve.
	m = Campaign.new(72)
	m.s.cash = 10000
	m.street.advance(0.37)
	m.street.action("hire",0)
	b = m.street.selected()
	m.street.economy.staff_service(b)
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and is_equal_approx(loaded.street.selected().team[0].service_ready,25.37),"Fractional staff deadlines survive save/restore")
	loaded.street.economy.staff_service(loaded.street.selected())
	test.check(loaded.street.selected().team[0].drinks_served==1,"Repeated calls at a fractional timestamp cannot create another serve")

	# Owner automation is relief for a staffed bar, not competition for quiet orders.
	m = Campaign.new(72)
	m.s.cash = 20000
	m.s.street.pass_credit = -10000000
	b = m.street.selected()
	e = m.street.economy
	m.street.action("hire",0)
	m.street.action("auto_serve")
	e.staff_service(b)
	b.customers.clear()
	e.admit(b)
	m.street.tick(1)
	test.check(b.team[0].drinks_served==1 and e.pending(b)==1 and b.serve_ready==0,"Quiet order waits for recovering bartender without spending owner's timer")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and not loaded.street.economy.owner_relief_needed(loaded.street.selected()),"Reload does not turn a quiet order into a rush")
	e.admit(b)
	m.street.tick(1)
	test.check(e.pending(b)==1 and b.serve_ready==e.action_time()+10 and b.team[0].drinks_served==1,"Overflow gets one owner sale on the unchanged shared cooldown")
	b.customers.clear()
	e.admit(b)
	var urgent: Dictionary = b.customers.back()
	urgent.wait = e.patience(b,urgent)-10
	test.check(e.owner_relief_needed(b),"Owner rescues urgent order when bartender would miss its deadline")
	b.team[0].service_ready = e.action_time()+2
	test.check(not e.owner_relief_needed(b),"A bartender recovering before the deadline still owns a quiet urgent order")
	b.team[0].service_ready = 0
	m.street.tick(1)
	test.check(b.team[0].drinks_served==2 and e.pending(b)==0,"Ready bartender still wins before owner relief")
	m.street.action("rota",0)
	e.admit(b)
	test.check(e.owner_relief_needed(b),"Off-duty staff do not block owner auto-serve coverage")
	b.team[0].on = true
	b.team[0].contract_left = 0
	test.check(e.owner_relief_needed(b),"Expired staff do not block owner coverage")
	b.customers.clear()
	test.check(not e.owner_relief_needed(b),"Relief never creates demand")
