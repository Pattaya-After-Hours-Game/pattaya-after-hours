extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.street.selected().cash = 10000
	m.street.action("restock")
	test.check(e.pack_quantity(b)==6 and e.pack_price(b)==228,"Supplier level one keeps six-drink deliveries")
	m.street.action("restock")
	for item in [[18,432,true],[19,1000,false],[18,431,false],[17,433,true]]:
		b.stock = item[0]
		m.street.selected().cash = item[1]
		var before := [b.stock,m.street.selected().cash]
		m.street.action("stock")
		test.check([b.stock,m.street.selected().cash]==([before[0]+12,before[1]-432] if item[2] else before),"Bulk delivery requires the whole price and twelve free spaces")
	b.equipment.fridge = 1
	b.stock = 59
	m.street.selected().cash = 10000
	test.check(not e.restock(b,true) and b.stock==59,"Automatic bulk delivery also rejects eleven free fridge spaces")
	b.stock = 58
	m.street.selected().cash = 432
	test.check(not e.restock(b,true),"Bulk auto-stock retains the next operating charge")
	m.street.selected().cash = 433
	test.check(e.restock(b,true) and b.stock==70 and m.street.selected().cash==1,"Bulk auto-stock settles twelve units and leaves its reserve")
	m.save_game()
	var loaded = Campaign.new(11)
	test.check(loaded.load_game(),"Bulk stock save reloads")
	var restored: Dictionary = loaded.street.selected()
	test.check(restored.stock==70 and restored.supplier_level==2 and loaded.street.selected().cash==1 and loaded.street.economy.pack_price(restored)==432,"Reload retains inventory and terms without repeating the delivery")
	# Colder beer earns reputation through satisfied departures, never buying alone.
	for fridge in 3:
		m = Campaign.new(72)
		b = m.street.selected()
		e = m.street.economy
		m.street.selected().cash = 10000
		var rep: int = m.s.rep
		for i in fridge: m.street.action("equipment",2)
		test.check(m.s.rep==rep,"Purchasing refrigeration does not immediately award reputation")
		b.happy = 9
		var guest: Dictionary = b.customers[0]
		guest.drinks = 2
		guest.missed = false
		guest.visit_complete = true
		e.depart(b,guest)
		test.check(m.s.rep==rep+1+fridge,"Ten satisfied visits earn base reputation plus each fridge tier")
		b.happy = 19
		guest = b.customers[0]
		guest.drinks = 2
		guest.missed = true
		e.depart(b,guest)
		test.check(b.happy==19 and m.s.rep==rep+1+fridge,"Missed orders do not earn cold-beer reputation")
		m.s.rep = 99
		guest = b.customers[0]
		guest.drinks = 2
		guest.missed = false
		guest.visit_complete = true
		e.depart(b,guest)
		test.check(m.s.rep==100,"Fridge reputation respects the reputation cap")
	# Role prices cannot be bypassed with a bartender contract.
	m = Campaign.new(72)
	m.street.selected().cash = 20000
	b = m.street.selected()
	b.type = 1
	e = m.street.economy
	m.street.action("hire",0)
	test.check(m.street.selected().cash==18800 and e.contract_cost(1)==4500 and e.contract_cost(2)==4500,"Only bartender contracts match Nida's upfront price")
	b.team[0].contract_left = 7200
	b.team[0].training = 2
	test.check(e.role_change_fee(b,0)==1650,"Specialist role adjustment is prorated to remaining contract time")
	m.street.selected().cash = 1650
	m.street.action("role",0)
	test.check(b.team[0].role==0 and m.street.selected().cash==1650,"Role adjustment retains next-shift operating reserve")
	m.street.selected().cash = 10000
	m.street.action("role",0)
	test.check(b.team[0].role==1 and m.street.selected().cash==8350 and b.team[0].contract_left==7200 and b.team[0].training==2,"Role adjustment charges once without extending the contract or losing training")
	m.street.action("role",0)
	test.check(b.team[0].role==0 and m.street.selected().cash==8350,"Returning to service does not mint a contract refund")

	# Offline bulk delivery spends only earned working capital and remains repeat-safe.
	var fixtures = load("res://tests/promoter_check.gd").new()
	var whole = fixtures.offline_model()
	var split = fixtures.offline_model()
	for campaign in [whole,split]:
		campaign.street.selected().supplier_level = 2
		campaign.street.selected().stock = 6
	var reserve: int = whole.street.selected().cash
	whole.street.claim_offline(1700)
	for timestamp in range(1001,1701): split.street.claim_offline(timestamp)
	test.check(split.street.selected().cash+split.street.selected().stock*36<=whole.street.selected().cash+whole.street.selected().stock*36 and whole.street.selected().cash>=reserve and split.street.selected().cash>=reserve,"Offline twelve-drink deliveries preserve reserves; shorter claims cannot mint extra value")
	test.check(str(whole.s.street.offline_report.notes).contains("deliveries of 12"),"Offline report names the actual bulk delivery size")
	var settled := [whole.street.selected().cash,whole.street.selected().stock]
	whole.street.claim_offline(1700)
	test.check(settled==[whole.street.selected().cash,whole.street.selected().stock],"Repeated offline claim cannot duplicate bulk stock or income")
