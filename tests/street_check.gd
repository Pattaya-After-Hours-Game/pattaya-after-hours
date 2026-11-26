extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/street_content.gd")

func test_rat_plague(test: SceneTree) -> void:
	var plagues := 0
	for seed_value in range(1,401):
		var candidate = Campaign.new(seed_value)
		candidate.s.street.chapter = 1
		candidate.s.street.event_wait = 1
		candidate.s.street.pass_credit = -1_000_000
		candidate.street.tick(1)
		if candidate.s.street.event.id==Content.RAT_PLAGUE:
			plagues += 1
			test.check(candidate.s.street.event_index==0,"The rare infestation preserves the regular event rotation")
	test.check(plagues>0 and plagues<25,"Rat Plague can roll randomly and stays rare")

	var m = Campaign.new(72)
	var eco = m.street.economy
	var bar: Dictionary = m.street.selected()
	var baseline: float = eco.traffic_rate()
	var before := [bar.stock,m.s.cash,bar.happy,bar.tip_visits]
	m.street.announce(Content.RAT_PLAGUE)
	test.check(m.s.street.event.remaining==20 and eco.traffic_rate()==baseline,"The rat warning gives time to prepare without scaring guests off yet")
	m.street.start_event()
	test.check(bar.customers.is_empty() and eco.pending(bar)==0 and eco.is_trading(bar),"The swarm scares guests off without shutting down the bar")
	test.check(before==[bar.stock,m.s.cash,bar.happy,bar.tip_visits],"Running guests do not earn rewards or consume stock")
	test.check(is_equal_approx(eco.traffic_rate(),baseline*.15) and eco.traffic_rate(true)==baseline,"The rats deter live walk-ins while offline estimates ignore them")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.street.event.remaining==45 and loaded.street.selected().customers.is_empty(),"Reload preserves an active plague without restoring fleeing guests")
	loaded.street.tick(45)
	test.check(loaded.s.street.event.is_empty() and loaded.street.economy.traffic_rate()==baseline,"Traffic returns to normal when the swarm clears")

	m = Campaign.new(72)
	bar = m.street.selected()
	m.street.announce(Content.RAT_PLAGUE)
	var prep_cost: int = Content.EVENTS[Content.RAT_PLAGUE][3]
	var opening_cash: int = m.s.cash
	m.street.action("prepare")
	m.street.start_event()
	test.check(bar.customers.size()==3 and m.s.cash==opening_cash-prep_cost and is_equal_approx(m.street.economy.traffic_rate(),baseline*.55),"Bo's paid preparation keeps guests inside and saves some passing traffic")

func run(test: SceneTree) -> void:
	test_rat_plague(test)
	var m = Campaign.new(72)
	var eco = m.street.economy
	var bar: Dictionary = m.street.selected()
	test.check(bar.customers.size()==3 and eco.pending(bar)==3,"Opening rush supplies three real orders")
	bar.customers.clear()
	var before := [m.s.cash,bar.stock,m.s.street.served]
	m.street.action("serve")
	test.check(before==[m.s.cash,bar.stock,m.s.street.served],"No order means no sale or consumed stock")
	m.s.cash = 10000
	m.street.action("hire",0)
	m.street.action("hire",0)
	m.s.street.pass_credit = -10000000
	m.street.tick(60)
	test.check(bar.sold==0 and m.s.cash<7600,"Idle staff incur payroll without minting sales")
	var paused_cash := int(m.s.cash)
	m.street.action("open")
	m.street.tick(60)
	test.check(m.s.cash==paused_cash,"Closing pauses wages and overhead")
	m.street.action("open")
	m.street.economy.admit(bar)
	bar.stock = 0
	m.street.tick(40)
	test.check(bar.lost_stock>0 and bar.lost_service==0,"Stockouts have a distinct lost-order reason")
	bar.stock = 30
	for person in bar.team: person.on = false
	eco.admit(bar)
	m.street.tick(40)
	test.check(bar.lost_service>0,"Slow service loses waiting customers")
	bar.customers.clear()
	for _i in eco.seats(bar): eco.admit(bar)
	test.check(not eco.admit(bar) and bar.lost_full>0,"Full venues reject arrivals without selling to them")
	# Pool charges once per table, not per player, and persists the game timer.
	m = Campaign.new(4)
	eco = m.street.economy
	bar = m.street.selected()
	m.s.cash = 10000
	bar.equipment.pool = 1
	bar.customers.clear()
	for _i in 2:
		eco.admit(bar)
		bar.customers.back().pool = true
	var cash_start := int(m.s.cash)
	eco.pool_tick(bar)
	test.check(m.s.cash==cash_start+50 and bar.games.size()==1 and bar.pool_games==1,"A two-player game pays exactly ฿50 once")
	for _i in 44: eco.pool_tick(bar)
	test.check(m.s.cash==cash_start+50 and bar.games.size()==1,"An occupied table cannot collect another fee")
	m.save_game()
	var loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.street.selected().games[0].remaining==1,"Pool timer survives save/reload")
	loaded.street.economy.pool_tick(loaded.street.selected())
	test.check(loaded.s.cash==m.s.cash and loaded.street.selected().games.is_empty(),"Finishing a saved game never charges twice")
	eco.pool_tick(bar)
	bar.customers.clear()
	for _i in 2:
		eco.admit(bar)
		bar.customers.back().pool = true
	m.street.action("promotion",0)
	cash_start = m.s.cash
	eco.pool_tick(bar)
	test.check(m.s.cash==cash_start and bar.games[0].fee==0 and bar.free_games==1,"Free pool charges zero at game start")
	bar.promo.remaining = 1
	m.street.tick(1)
	cash_start = m.s.cash
	eco.pool_tick(bar)
	test.check(bar.games[0].fee==0 and m.s.cash==cash_start,"Promotion expiry never retroactively bills a free game")
	test.check(bar.promo_report.free_games==1 and bar.promo_cooldown==120,"Promotion records forgone fees and starts cooldown")
	m.street.action("promotion",1)
	test.check(bar.promo.is_empty(),"Promotions cannot stack or skip cooldown")
	bar.promo_cooldown = 0
	m.street.action("promotion",0)
	test.check(bar.promo.repetition==2,"Repeated promotion has diminishing attraction")
	var base_price := int(eco.price(bar))
	m.street.announce(1)
	m.street.start_event()
	test.check(eco.price(bar)==base_price,"Navy traffic never multiplies the price of a drink")
	# Welcoming has no direct income and uses a bounded public visitor budget.
	m = Campaign.new(72)
	cash_start = m.s.cash
	for _i in 100: m.street.action("welcome")
	test.check(m.s.cash==cash_start and m.street.selected().welcome==1,"Welcome clicks are rate-limited and never pay money")
	m.s.cash = 1000000
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("buy",0)
	var first: Dictionary = m.s.street.bars[0]
	var second: Dictionary = m.s.street.bars[1]
	var split := float(m.street.economy.forecast(first).arrivals)
	second.open = false
	test.check(m.street.economy.forecast(first).arrivals>split,"Another beer bar competes for the existing traffic")
	second.open = true
	for _i in 5: m.street.tick(60)
	test.check(m.s.street.arrivals<=m.s.street.offered+3,"All venues share a bounded supply of people")
	# Stage and role gates, even when cash is abundant.
	m.s.street.selected = 0
	m.street.action("upgrade")
	test.check(first.stage==1,"Money cannot buy a missing local customer base")
	first.happy = 70
	first.regulars = 10
	first.healthy = 8
	m.street.action("upgrade")
	test.check(first.stage==2,"A healthy established bar can renovate")
	test.check(m.street.drink_value(first)==80,"Renovating does not automatically raise beer prices")
	m.street.action("buy",2)
	bar = m.street.selected()
	m.street.action("hire",2)
	test.check(m.street.economy.service_rate(bar)==0 and bar.team[0].role==2,"Dancers attract visitors but do not serve orders")
	m.street.action("hire",0)
	test.check(is_equal_approx(m.street.economy.service_rate(bar),2.4),"A bartender adds actual service capacity")
	# Bar fines need a real request and preserve staff preferences.
	m.street.action("buy",1)
	bar = m.street.selected()
	bar.stage = 2
	m.street.action("hire",1)
	m.street.action("hire",1)
	cash_start = m.s.cash
	m.street.action("bar_fine",0)
	test.check(m.s.cash==cash_start and bar.away.is_empty(),"No customer request means no bar-fine income")
	m.street.economy.admit(bar,false,false,2)
	bar.host_requests = [int(bar.customers.back().id)]
	m.street.action("bar_fine",1)
	test.check(bar.away.is_empty(),"A host's refusal is respected")
	m.street.action("bar_fine",0)
	test.check(bar.away==[0] and bar.host_requests.is_empty(),"Accepted request consumes demand and removes availability")
	cash_start = m.s.cash
	m.street.action("bar_fine",0)
	test.check(m.s.cash==cash_start,"Host absence prevents duplicate fees")
	# Offline profit uses bounded demand, preserves state and cannot spend reserves.
	m = Campaign.new(72)
	bar = m.street.selected()
	bar.stage = 3
	bar.manager = true
	bar.restock = true
	bar.equipment.sign = 1
	bar.team = [{"role":0,"on":true,"host":-1}]
	bar.crew = 1
	m.s.cash = 10000
	m.s.street.last_seen = 1000
	m.street.announce(3)
	var event: Dictionary = m.s.street.event.duplicate(true)
	var day := int(m.s.day)
	var capped = Campaign.new(3)
	capped.s = m.s.duplicate(true)
	capped.street = Campaign.Street.new(capped.s)
	var expected: int = capped.street.claim_offline(1000+28800)
	test.check(m.street.claim_offline(1000+86400)==expected,"Offline profit is demand-limited and capped at eight hours")
	test.check(m.s.day==day and m.s.street.event==event,"Offline time cannot advance disasters or calendar")
	test.check(m.street.claim_offline(87400)==0 and m.street.claim_offline(900)==0,"Repeated claims and backward clocks cannot create money")
	bar.team = []
	bar.equipment.pool = 0
	m.s.street.last_seen = 0
	cash_start = m.s.cash
	test.check(m.street.claim_offline(100)==0 and m.s.cash==cash_start,"Unviable offline trading cannot consume the opening till")
	# Empty tills close gently and retain a manual path to recovery.
	m = Campaign.new(1)
	m.s.cash = 0
	m.street.tick(4)
	bar = m.street.selected()
	test.check(not bar.open and m.s.debt==0,"Unaffordable overhead closes before creating debt")
	bar.stock = 0
	m.street.action("recovery")
	test.check(bar.open and bar.stock==6 and m.s.cash==0,"Recovery supplies are charged only when sold")
	m.street.economy.admit(bar)
	m.street.action("serve")
	test.check(m.s.cash==66 and bar.consignment==5,"Recovery still needs a buyer and pays the stock cost")
	# Guided shifts cannot accelerate time or create parallel sales.
	m = Campaign.new(72)
	m.start()
	m.pick(2)
	var current_day := int(m.s.day)
	var elapsed := int(m.s.street.elapsed)
	for _i in 30:
		m.pick(0)
		m.next_day()
		m.start()
	test.check(m.s.day==current_day and m.s.street.elapsed==elapsed and m.s.street.served==0,"Guided clicks cannot skip time or generate income")
	for _i in 3:
		m.street.tick(40)
		if m.s.phase=="guided_choice": m.pick(2)
	test.check(m.s.phase=="guided_report" and m.s.day==current_day,"Guided report settles on the ordinary two-minute clock")
	cash_start = m.s.cash
	m.next_day()
	m.next_day()
	test.check(m.s.cash==cash_start and m.s.day==current_day,"Report dismissal cannot pay or advance twice")
	# Happy Hour quotes once, and reloading an active promotion cannot restart it.
	m = Campaign.new(72)
	m.s.cash = 1000
	bar = m.street.selected()
	var unchanged: Dictionary = bar.duplicate(true)
	var estimate: Dictionary = m.street.economy.forecast(bar,false,1)
	test.check(estimate.costs==m.street.economy.operating_rate(bar)+40 and bar==unchanged,"Promotion forecast includes its fee without changing live state")
	m.street.action("promotion",1)
	m.street.economy.admit(bar)
	test.check(bar.customers[0].quoted==80 and bar.customers.back().quoted==64,"Happy Hour discounts new orders, not existing quotes")
	m.street.tick(20)
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().promo.remaining==100,"Promotion keeps its remaining time across reload")
	cash_start = loaded.s.cash
	loaded.street.action("promotion",1)
	test.check(loaded.s.cash==cash_start and loaded.street.selected().promo.remaining==100,"Repeated promotion clicks cannot restart or duplicate rewards")
	# A second game's table identity survives the first table finishing and reload.
	m = Campaign.new(2)
	bar = m.street.selected()
	bar.equipment.pool = 2
	bar.equipment.seating = 2
	bar.customers.clear()
	for i in 4:
		m.street.economy.admit(bar)
		bar.customers.back().pool = true
	m.street.economy.pool_tick(bar)
	bar.games[0].remaining = 1
	m.street.economy.pool_tick(bar)
	test.check(bar.games.size()==1 and bar.games[0].table==1,"A game stays at table two when table one finishes")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().games[0].table==1,"Pool table identity survives reload")
	test_promotions(test)
	test_drink_stock(test)
	test_migration(test)
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)

func test_drink_stock(test: SceneTree) -> void:
	var model = Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	var normal_mix: Array = eco.drink_popularity(bar)
	test.check(eco.drink_demand_hint(bar,2,normal_mix[2])=="Visitor pick","Normal demand teaches the audience for the drink")
	bar.promo = {"kind":1}
	var discount_mix: Array = eco.drink_popularity(bar)
	test.check(eco.drink_demand_hint(bar,2,discount_mix[2])=="Happy Hour boost" and eco.drink_demand_hint(bar,1,discount_mix[1])=="Popular with locals","Only orders more popular because of the discount get a Happy Hour cue")
	bar.promo = {}
	model.street.announce(1)
	model.street.start_event()
	var tourist_mix: Array = eco.drink_popularity(bar)
	test.check(tourist_mix[2]>normal_mix[2] and eco.drink_demand_hint(bar,2,tourist_mix[2])=="Visitor crowd boost","Shore leave explains higher demand for mixed drinks")
	test.check(eco.drink_demand_hint(bar,1,tourist_mix[1])=="Popular with locals","A tourist-heavy crowd does not claim to boost soda orders")
	model.street.announce(6)
	model.street.start_event()
	var locals_mix: Array = eco.drink_popularity(bar)
	test.check(eco.drink_demand_hint(bar,1,locals_mix[1])=="Local crowd boost","Low season explains higher demand for budget drinks")
	test.check(eco.price(bar,2)-Content.DRINKS[2].cost>eco.price(bar)-Content.STOCK_COST,"Rum earns more per sale than house lager")
	var cash_before := int(model.s.cash)
	model.street.action("buy_drink",3)
	test.check(model.s.cash==cash_before and not bar.drink_stock.has("mango"),"Premium stock requires a premium menu")
	var guest: Dictionary = bar.customers[0]
	guest.opening = false
	guest.order = false
	guest.taste_roll = 99
	eco.order(bar,guest)
	test.check(guest.drink==0,"Budget crowd passes on rum at full price")
	guest.order = false
	guest.audience = 1
	eco.order(bar,guest)
	guest.lager_quote = 0
	test.check(guest.drink==2 and bar.shift.drink_requests.rum==1 and eco.stock_waiting(bar)==1,"Unstocked rum demand is recorded even with lager in the fridge")
	model.street.action("serve")
	test.check(guest.order and eco.stock_of(bar,0)==11,"An unavailable drink does not block the next guest's order")
	cash_before = int(model.s.cash)
	model.street.action("buy_drink",2)
	test.check(eco.stock_of(bar,2)==6 and model.s.cash==cash_before-114,"A delivery charges the selected drink's actual wholesale cost")
	model.save_game()
	var loaded = Campaign.new(11)
	test.check(loaded.load_game(),"Drink stock saves and loads")
	bar = loaded.street.selected()
	eco = loaded.street.economy
	test.check(eco.stock_of(bar,2)==6 and bar.customers[0].drink==2,"Reload preserves both stock and the pending order")
	cash_before = int(loaded.s.cash)
	bar.serve_ready = 0
	loaded.street.action("serve")
	test.check(eco.stock_of(bar,2)==5 and loaded.s.cash==cash_before+98 and bar.shift.consumed_stock==57,"Serving a rum order consumes rum stock and settles the saved quote and its own cost")
	loaded.street.action("return_drink",2)
	test.check(eco.stock_of(bar,2)==2 and loaded.s.cash==cash_before+98+28,"Returning overstock frees fridge space at half wholesale")
	bar.restock = true
	test.check(eco.auto_drink(bar,2) and not eco.auto_drink(bar,1),"Automatic deliveries stick to the chosen drinks")
	var next_guest: Dictionary = bar.customers[2]
	next_guest.drink = 1
	next_guest.quoted = 36
	next_guest.lager_quote = 44
	cash_before = int(loaded.s.cash)
	eco.serve(bar)
	test.check(loaded.s.cash==cash_before+44 and eco.stock_of(bar,1)==0 and bar.shift.drink_misses.soda==1,"A player stocks around unmet demand even when a guest accepts quoted-price lager")
	for _i in 2: eco.consume_stock(bar,2)
	next_guest.order = true
	next_guest.drink = 2
	next_guest.quoted = 73
	cash_before = int(loaded.s.cash)
	eco.serve(bar)
	test.check(loaded.s.cash==cash_before+73-6*19 and eco.stock_of(bar,2)==5,"An automated rum delivery pays wholesale and fills the rum order")
	bar.restock = false
	bar.manager = true
	bar.manager_level = 1
	bar.team = [{"role":0,"on":true,"host":-1,"contract_left":6000}]
	loaded.s.cash = 2000
	loaded.s.street.last_seen = 1000
	var offline_gain: int = loaded.street.claim_offline(1600)
	test.check(offline_gain>0 and eco.stock_of(bar,2)==0 and eco.stock_of(bar,1)==0,"A manager's offline estimate respects the stock limit of each drink")
	# Shape of a pre-drinks save with an order already in progress.
	model = Campaign.new(72)
	bar = model.street.selected()
	bar.erase("drink_stock")
	for key in ["drink_requests","drink_misses"]: bar.shift.erase(key)
	for order in bar.customers:
		order.quoted = 55
		order.erase("drink")
		order.erase("lager_quote")
	model.save_game()
	loaded = Campaign.new(11)
	test.check(loaded.load_game() and loaded.street.economy.stock_of(loaded.street.selected(),0)==12,"Existing inventory becomes house lager without losing any units")
	cash_before = int(loaded.s.cash)
	loaded.street.action("serve")
	test.check(loaded.s.cash==cash_before+55,"Existing pending orders retain their original quote")

func test_migration(test: SceneTree) -> void:
	var legacy = Campaign.new(72,true)
	legacy.s.erase("street")
	legacy.s.erase("practice")
	legacy.s.version = 1
	legacy.s.cash = 9876
	legacy.s.level = 2
	legacy.s.venue = 2
	var legacy_file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy.s))
	legacy_file.close()
	var migrated = Campaign.new(9)
	test.check(migrated.load_game() and migrated.s.street.bars.size()==2,"Version-one second lease survives migration")
	test.check(migrated.street.selected().crew==3 and migrated.street.selected().stock==legacy.s.stock and migrated.s.cash==9876,"Version-one staff, inventory and cash survive migration")
	var old = Campaign.new(72)
	old.s.cash = 9876
	old.s.street.bars[0].stage = 2
	old.s.street.bars[0].crew = 2
	var fields: Dictionary = old.street.economy.new_fields()
	for key in fields: old.s.street.bars[0].erase(key)
	old.s.version = 2
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(old.s))
	file.close()
	var model = Campaign.new(9)
	test.check(model.load_game(),"Version-two save loads")
	var bar: Dictionary = model.street.selected()
	test.check(model.s.version==12 and model.s.cash==9876 and bar.stage==2 and bar.team.size()==2,"Migration preserves money, stage and staff")
	test.check(bar.equipment.pool==1 and bar.customers.is_empty(),"Existing illustrated pool table is granted; migration creates no buyers")
	model.save_game()
	model.save_game()
	file = FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string('{"version":3,"staff":[],"phase":"plan"}')
	file.close()
	test.check(Campaign.new().load_game(),"Invalid version-three save falls back to backup")

func pool_scenario(seed_value: int, free_pool: bool, full: bool) -> int:
	var m = Campaign.new(seed_value)
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	m.s.cash = 10000
	bar.equipment.pool = 1
	bar.equipment.seating = 1
	bar.restock = true
	bar.stock = 90
	bar.customers.clear()
	if full:
		for _i in eco.seats(bar):
			eco.admit(bar)
			bar.customers.back().life = 300
			bar.customers.back().pool = true
	if free_pool: eco.start_promotion(bar,0)
	for _i in 120:
		eco.serve(bar,1,true)
		m.street.tick(1)
	return int(m.s.cash)-10000-int(90-bar.stock)*38

func test_promotions(test: SceneTree) -> void:
	var quiet_gain := 0
	var busy_gain := 0
	for seed_value in range(1,31):
		quiet_gain += pool_scenario(seed_value,true,false)-pool_scenario(seed_value,false,false)
		busy_gain += pool_scenario(seed_value,true,true)-pool_scenario(seed_value,false,true)
	test.check(quiet_gain>0,"Free pool improves average contribution across quiet-night scenarios")
	test.check(busy_gain<0,"A full house can lose money by giving pool away")
	print("POOL COMPARISON · quiet uplift %d / full-house change %d across 30 seeds" % [quiet_gain,busy_gain])
