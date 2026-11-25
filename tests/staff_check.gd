extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")
const Alert = preload("res://scripts/order_alert.gd")

func advance(m: RefCounted, seconds: int) -> void:
	for _i in seconds: m.street.tick(1)

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	m.s.cash = 200000
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	m.street.action("hire",0)
	var person: Dictionary = bar.team[0]
	test.check(m.s.cash==198800 and person.contract_left==14400,"A ten-day contract costs exactly 1,200 once")
	m.street.action("rehire",0)
	test.check(m.s.cash==198800,"An active contract cannot be bought twice")
	bar.customers.clear()
	m.s.street.pass_credit = -10000000
	eco.admit(bar,false,true)
	advance(m,24)
	test.check(bar.sold==0 and is_equal_approx(eco.service_rate(bar),2.4),"Base staff cannot serve before 25 seconds; forecast is 2.4/min")
	advance(m,1)
	test.check(bar.sold==1 and bar.stock==17,"Base staff completes one real order at 25 seconds")
	m.street.action("hire",0)
	m.street.action("train_staff",0)
	test.check(person.training==1 and bar.team[1].training==0 and eco.service_seconds(person)==20,"Training belongs only to the selected bartender")
	m.street.action("train_staff",0)
	test.check(person.training==2 and eco.service_seconds(person)==15,"Second training level gives a 15-second service interval")
	var cash_before := int(m.s.cash)
	m.street.action("train_staff",0)
	test.check(m.s.cash==cash_before,"Maxed training cannot be charged again")
	bar.team[1].on = false
	bar.customers.clear()
	person.service_clock = 0
	eco.admit(bar,false,true)
	advance(m,14)
	test.check(bar.sold==1,"Training does not instantly settle an order")
	advance(m,1)
	test.check(bar.sold==2,"Trained staff serves at the measured interval")
	bar.customers.clear()
	advance(m,30)
	test.check(bar.sold==2 and person.service_clock==0,"No customer means no auto sale or banked service")
	# Contracts expire even while off duty, closed or skipping prep.
	bar.open = false
	person.on = false
	person.contract_left = 2
	advance(m,1)
	test.check(person.contract_left==1,"Closed off-duty contracts still count down")
	advance(m,1)
	test.check(person.contract_left==0 and person.training==2 and not person.on,"Expiry retains the person and their training")
	test.check(eco.service_rate(bar)==0 and eco.operating_rate(bar)==C.OVERHEAD[0],"Departed staff provide no service and incur no wages")
	m.street.action("rota",0)
	test.check(not person.on,"Rota cannot reactivate an expired contract")
	cash_before = m.s.cash
	m.street.action("rehire",0)
	test.check(m.s.cash==cash_before-1200 and bar.team.size()==2 and person.training==2 and person.on and person.contract_left==14400,"Rehire keeps identity, training and a fresh ten-day contract")
	person.contract_left = 650
	m.s.street.minute = 60
	m.street.action("skip")
	test.check(person.contract_left==0,"Skipping eleven closed hours consumes eleven contract hours")
	# An unavailable host cannot attract or accept a request after expiry.
	bar.type = 1
	person.role = 1
	person.host = 0
	person.on = true
	bar.open = true
	test.check(eco.on_duty(bar,1)==0,"Expired hosts do not attract customers even if a stale rota says on duty")
	test.check(m.street.action("bar_fine",0).contains("unavailable"),"Expired hosts cannot accept bar-fine requests")
	# Migration and reload keep owned training, timers and expired status.
	bar.type = 0
	person.role = 0
	person.host = -1
	person.on = false
	bar.team[1].erase("training")
	bar.team[1].erase("contract_left")
	bar.team[1].erase("service_clock")
	bar.equipment.training = 2
	m.street = Campaign.Street.new(m.s)
	test.check(bar.team[1].training==2 and bar.team[1].contract_left==14400 and person.contract_left==0,"Legacy hires keep venue training without renewing expired hires")
	bar.team[1].service_clock = 9
	test.check(m.save_game()==OK,"Save individual staff contracts")
	var restored = Campaign.new(1)
	test.check(restored.load_game(),"Reload individual staff contracts")
	var loaded: Dictionary = restored.street.selected()
	test.check(loaded.team[0].contract_left==0 and loaded.team[0].training==2 and loaded.team[1].service_clock==9,"Reload preserves expiry, training and partial service")
	# One minute of a remaining contract cannot power an eight-hour projection.
	m = Campaign.new(72)
	m.s.cash = 100000
	bar = m.street.selected()
	m.street.action("hire",0)
	bar.manager = true
	bar.restock = true
	bar.team[0].contract_left = 60
	m.s.street.last_seen = 1000
	var short = Campaign.new(72)
	short.s = m.s.duplicate(true)
	short.street = Campaign.Street.new(short.s)
	var expected: int = short.street.claim_offline(1060)
	test.check(expected>0 and m.street.claim_offline(1000+28800)==expected,"Offline income stops serving at the exact staff expiry")
	test.check(bar.team[0].contract_left==0 and not bar.team[0].on,"Offline absence expires contracts")
	cash_before = m.s.cash
	m.street.claim_offline(1000+28800)
	test.check(m.s.cash==cash_before,"Repeated offline claims cannot renew or duplicate contracts")
	# Intermittent empty queues and UI redraws cannot spam the alert.
	var alert = Alert.new()
	test.check(not alert.tick(false,1) and alert.tick(true,0),"First waiting order requests a chime")
	test.check(not alert.tick(true,1) and not alert.tick(false,1) and not alert.tick(true,1),"Chime cooldown survives an empty/refilled queue")
	test.check(alert.tick(true,7),"Persistent waiting repeats the alert after ten seconds")
	test.check(not alert.tick(true,10,false),"Muted, practice and inactive screens suppress alerts")
	test.check(not alert.tick(false,10),"An empty queue never requests an alert")
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
