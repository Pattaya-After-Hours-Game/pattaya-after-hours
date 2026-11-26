extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const E = preload("res://scripts/economy.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var e = m.street.economy
	var b: Dictionary = m.street.selected()
	m.s.day = 4
	m.s.street.minute = 1439
	m.street.tick(1)
	test.check(str(m.s.street.history.front()).contains("SAVE THE DATE"),"Two-day warning records the next celebration before the day-six lull")
	m.s.day = 6
	m.s.street.minute = 1439
	var original: int = m.s.cash
	m.street.tick(1)
	test.check(m.s.day==7 and not e.celebrating(b) and m.street.celebration_info().day==7,"Birthday waits for day-seven noon, not midnight")
	m.s.street.minute = 719
	m.street.tick(1)
	test.check(e.celebrating(b) and m.s.cash<=original and m.s.street.celebration.report.sales==0,"Noon begins a free celebration without awarding money or sales")
	var snapshot := JSON.stringify(m.s)
	for i in 10: m.street.celebration_info()
	test.check(JSON.stringify(m.s)==snapshot,"Countdown reads never advance or reward the event")
	b.customers.clear()
	e.admit(b,false,true)
	var guest: Dictionary = b.customers[0]
	test.check(guest.planned_rounds==3 and guest.party_patience==10 and E.patience(b,guest)==55,"Opening-party guest plans three rounds and retains party plus opening-rush patience")
	e.serve(b)
	test.check(guest.next==26,"Party repeat order is faster at normal drink prices")
	guest.order = false
	guest.drinks = 2
	guest.budget = 80
	guest.next = 0
	e.order(b,guest)
	test.check(guest.order,"Party guests can request a third drink if they can afford it")
	e.serve(b)
	guest.budget = 10000
	guest.next = 0
	e.order(b,guest)
	test.check(not guest.order and guest.drinks==3,"Celebrations never create an unlimited drink budget or order count")
	b.equipment.music = 1
	test.check(e.repeat_order_seconds(b)==19,"Music remains useful during celebrations")
	var report: Dictionary = m.s.street.celebration.report
	test.check(report.arrivals==1 and report.sales==2 and report.drink_income==160 and report.drink_cost==76,"Party report counts actual transactions and paid inventory costs")
	b.customers.clear()
	snapshot = JSON.stringify(report)
	e.serve(b,100)
	test.check(JSON.stringify(report)==snapshot,"Empty-order clicks cannot create party rewards")
	m.s.street.event = {"id":1,"phase":"active","remaining":90,"prepared":true}
	test.check(e.traffic_rate()<=m.street.C.TRAFFIC_PER_MINUTE*2.4,"Party and Navy traffic share a cap instead of multiplying without limit")
	m.s.street.event = {}
	var shared_traffic: float = e.traffic_rate()
	var other: Dictionary = b.duplicate(true)
	other.name = "Other beer bar"
	other.customers.clear()
	m.s.street.bars.append(other)
	test.check(e.traffic_rate()==shared_traffic and not e.celebrating(other) and e.repeat_order_seconds(other)==25,"Buying another bar shares traffic and cannot duplicate the flagship party bonus")
	e.admit(other)
	other.customers[0].order = false
	other.customers[0].drinks = 2
	e.order(other,other.customers[0])
	test.check(not other.customers[0].order,"Other venues retain their normal two-drink limit")
	m.s.street.bars.pop_back()
	m.save_game()
	var loaded = Campaign.new(11)
	test.check(loaded.load_game() and loaded.s.version==14 and JSON.stringify(loaded.s.street.celebration.report)==snapshot,"Reload preserves one active party ledger")
	loaded.street.celebration_tick()
	test.check(JSON.stringify(loaded.s.street.celebration.report)==snapshot,"Reloading cannot restart or clear party results")
	m.s.day = 8
	m.s.street.minute = 0
	test.check(e.celebrating(b),"Day-seven opening continues through midnight")
	m.s.street.minute = 60
	m.street.celebration_tick()
	test.check(not e.celebrating(b) and m.s.street.celebration.report.is_empty() and m.s.street.celebration.last_report.sales==2,"Normal 1am close finalises the report exactly once")
	original = m.s.cash
	m.street.celebration_tick()
	test.check(m.s.cash==original and m.street.celebration_info().day==14,"Reading or finishing the party never pays a duplicate bonus")
	m.s.day = 14
	m.s.street.minute = 720
	m.street.celebration_tick()
	test.check(e.celebrating(b) and m.street.celebration_info().name=="The Regulars' Reunion","Later weeks rotate neighbourhood stories instead of weekly birthdays")
	b.open = false
	test.check(not e.celebrating(b) and e.traffic_rate()==e.traffic_rate(true),"A closed host venue cannot manufacture party traffic")
	# Reputation affects attraction, not repeat timers, budgets or serving speed.
	b.open = true
	m.s.day = 15
	m.street.celebration_tick()
	b.dirt = 0
	m.s.rep = 0
	var attraction: float = e.attraction(b)
	var forecast: float = e.forecast(b).arrivals
	m.s.rep = 100
	test.check(is_equal_approx(e.attraction(b)-attraction,1.25) and e.forecast(b).arrivals>forecast and e.repeat_order_seconds(b)==25,"Reputation raises capture of shared visitors, not drink timing")
	# Offline projections must ignore temporary calendar bonuses and not use them up.
	var regular = load("res://tests/promoter_check.gd").new().offline_model()
	var party = load("res://tests/promoter_check.gd").new().offline_model()
	party.s.day = 7
	party.street.celebration_tick()
	snapshot = JSON.stringify(party.s.street.celebration)
	regular.street.claim_offline(1700)
	party.street.claim_offline(1700)
	test.check(regular.s.cash==party.s.cash and regular.street.selected().stock==party.street.selected().stock and JSON.stringify(party.s.street.celebration)==snapshot,"Offline claims neither replay nor consume birthday bonuses")
	# Existing campaigns retain ownership/cash and get no retroactive celebration.
	m = Campaign.new(72)
	m.s.version = 7
	m.s.day = 9
	m.s.cash = 4321
	m.s.street.erase("celebration")
	for guest_old in m.street.selected().customers: guest_old.erase("party_patience")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.cash==4321 and loaded.street.celebration_info().day==14 and loaded.s.street.celebration.report.is_empty(),"V7 migration preserves cash and schedules the next weekly event without retroactive rewards")

	loaded.s.street.celebration = {"day":7,"report":{"day":7},"last_report":{}}
	loaded.save_game()
	test.check(loaded._read(Campaign.SAVE)==null,"Incomplete celebration ledgers are rejected instead of crashing the live game")
