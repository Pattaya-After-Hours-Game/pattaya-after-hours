extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Economy = preload("res://scripts/economy.gd")
const C = preload("res://scripts/street_content.gd")
const City = preload("res://scripts/city.gd")

func fresh():
	var m = Campaign.new(72)
	m.s.cash = 300000
	m.s.street.pass_credit = -10000000
	return m

func run(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.street.action("equipment",8)
	test.check(b.equipment.music==1 and m.s.cash==298800,"Music costs 1200 with no free demand or orders")
	b.customers = [b.customers[0]]
	m.street.action("serve")
	test.check(b.customers[0].next==25,"Music brings the next real order forward to 25 seconds")
	m.street.tick(24)
	test.check(not b.customers[0].order,"Music never creates a repeat order early")
	m.street.tick(1)
	test.check(b.customers[0].order and b.orders==4,"Music creates one budget-limited repeat order")
	m.street.action("serve")
	m.street.tick(25)
	test.check(not b.customers[0].order and b.sold==2,"Music preserves the two-drink visit budget")
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	m.street.advance(0.37)
	m.street.action("serve")
	var deadline: float = b.serve_ready
	m.street.action("auto_serve")
	test.check(b.auto_serve and b.serve_ready==deadline and e.action_cooldown(b,"serve")==10,"Buying auto-serve retains the manual deadline and speed")
	for i in 10:
		m.street.action("auto_serve")
		m.street.action("auto_serve")
	m.street.advance(9.63)
	test.check(b.sold==1,"Toggling automation cannot reset or bypass the existing cooldown")
	m.street.advance(1)
	test.check(b.sold==2 and not e.action_status(b,"serve").enabled,"Automatic settlement uses the shared Serve deadline")
	m.street.action("serve")
	test.check(b.sold==2,"Manual clicking cannot double an automatic sale")
	b.customers.clear()
	var stock: int = b.stock
	m.street.tick(20)
	test.check(b.stock==stock,"Auto-serve with no real order consumes no stock")
	b.stage = 2
	for i in 4: m.street.action("action_upgrade",0)
	test.check(e.action_cooldown(b,"serve")==2 and b.action_levels.welcoming==0,"Pouring gains a fourth two-second tier without changing Welcome")
	deadline = b.serve_ready
	m.street.action("auto_serve")
	m.street.action("auto_serve")
	test.check(b.serve_ready==deadline,"Rota toggles preserve cooldown after upgrading")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.version==7 and loaded.street.selected().auto_serve and loaded.street.selected().action_levels.pouring==4,"Schema seven preserves auto-serve and the new pouring tier")
	# Supplier buys and stock costs retain their own paid identities.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	m.street.action("restock")
	m.street.action("restock")
	test.check(b.supplier_level==2 and e.pack_price(b)==72,"Supplier level two reduces pack price from 84 to 72")
	b.stage = 3
	for i in 3: m.street.action("restock")
	test.check(b.supplier_level==5 and e.pack_price(b)==36,"Each supplier level reduces cost, down to 36 per six-pack")
	var cash_before: int = m.s.cash
	m.street.action("restock")
	test.check(m.s.cash==cash_before,"Maxed supplier cannot charge repeatedly")
	m.street.action("stock")
	test.check(b.stock==24 and m.s.cash==cash_before-36,"Discounted restocking still buys a complete six-pack")
	for i in 18: test.check(Economy.consume_stock(b)==14,"Previously purchased drinks keep their old cost")
	test.check(Economy.consume_stock(b)==6,"New discounted stock uses its actual purchase cost")
	b.stock = 0
	b.stock_lots.clear()
	m.s.cash = 36
	test.check(not e.restock(b,true) and b.stock==0,"Discounted supplier retains the operating reserve")
	m.s.cash = 37
	test.check(e.restock(b,true) and b.stock==6 and m.s.cash==1,"Supplier settlement uses the discounted atomic pack price")
	# Passive manager income is separate from real drinks and promotion results.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	b.stage = 2
	b.healthy = 8
	m.street.action("hire",0)
	m.street.action("restock")
	cash_before = m.s.cash
	m.street.action("manager")
	test.check(b.manager_level==1 and m.s.cash==cash_before-18000,"Manager level one costs 18000 and retains its operating gates")
	b.customers.clear()
	stock = b.stock
	m.street.tick(5)
	test.check(b.shift.manager_income==50 and b.stock==stock and b.sold==0 and b.shift.commission==0,"Manager earns 10 per open second without fake drinks, stock or commission")
	test.check(is_equal_approx(m.s.street.net_per_second,(50.0-b.shift.operating)/5.0),"Till rate samples actual trading net every five seconds")
	var sampled: float = m.s.street.net_per_second
	m.street.tick(4)
	test.check(m.s.street.net_per_second==sampled,"Till rate remains stable between five-second updates")
	m.street.action("open")
	cash_before = m.s.cash
	m.street.tick(10)
	test.check(m.s.cash==cash_before and m.s.street.net_per_second==0,"Closed venues earn no manager money and rate falls to zero")
	b.stage = 3
	m.street.action("manager")
	m.street.action("manager")
	test.check(b.manager_level==3 and e.manager_rate(b)==40,"Manager upgrades scale from ten to twenty to forty")
	m.street.action("open")
	m.street.action("hire",3)
	var city = City.new()
	test.root.add_child(city)
	city.bars = m.s.street.bars
	city.street_state = m.s.street
	var nida: Array = city.scene_people(b).filter(func(person): return person.who=="nida")
	test.check(nida.size()==1 and nida[0].flip,"Nida faces toward the street using her production sprite")
	city.free()
	b.stock = 0
	b.stock_lots.clear()
	b.auto_serve = true
	m.s.street.last_seen = 1000
	cash_before = m.s.cash
	var live_sold: int = b.sold
	var gain: int = m.street.claim_offline(1060)
	test.check(gain>0 and m.s.cash==cash_before+gain and b.sold==live_sold,"Offline manager earnings fund whole packs without creating live sales")
	var once := [m.s.cash,b.stock,b.commission_paid,b.stock_lots.duplicate(true)]
	m.street.claim_offline(1060)
	test.check(once==[m.s.cash,b.stock,b.commission_paid,b.stock_lots],"Offline manager, stock and commission settlement is repeat-safe")
	# Manager income must not turn unhealthy drink service into a milestone.
	b.shift = Economy.ledger()
	b.shift.merge({"revenue":1420,"manager_income":1200,"sales":4,"orders":4,"consumed_stock":56,"operating":200},true)
	var healthy: int = b.healthy
	e.settle_shift(b)
	test.check(b.healthy==healthy,"Manager receipts cannot subsidise a healthy-service milestone")
	# Manager and auto-service projection costs survive split claims as well.
	var whole = fresh()
	var split = fresh()
	for projection_model in [whole,split]:
		var venue: Dictionary = projection_model.street.selected()
		venue.manager = true
		venue.manager_level = 1
		venue.auto_serve = true
		venue.restock = true
		venue.supplier_level = 3
		venue.stock = 30
		Economy.ensure_stock_lots(venue)
		projection_model.s.street.last_seen = 1000
	whole.street.claim_offline(1120)
	for stamp in range(1010,1121,10): split.street.claim_offline(stamp)
	test.check(whole.s.cash==split.s.cash and whole.street.selected().stock==split.street.selected().stock,"Splitting manager/auto-serve offline time cannot avoid costs or mint stock")
	# Real v6 shape migrates the already-paid supplier/manager appointments.
	m = fresh()
	b = m.street.selected()
	b.manager = true
	b.restock = true
	m.s.version = 6
	for key in Economy.automation_fields(): b.erase(key)
	b.equipment.erase("music")
	for key in ["earnings_seconds","earnings_net","net_per_second"]: m.s.street.erase(key)
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game(),"A genuine v6 save migrates")
	b = loaded.street.selected()
	test.check(b.manager_level==1 and b.supplier_level==1 and not b.auto_serve and b.equipment.music==0 and b.stock==18 and loaded.s.cash==300000,"Migration preserves paid appointments and cash without free music or automation")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
