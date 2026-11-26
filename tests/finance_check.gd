extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	var e = st.economy
	var bar: Dictionary = st.selected()
	test.check(bar.cash==228 and m.s.cash==0 and st.finance.total()==228,"Fresh cash belongs to Blue Hour, not the bank")
	var before := JSON.stringify(m.s)
	test.check(not st.finance.transfer(bar,0,true) and not st.finance.transfer(bar,229,true) and not st.finance.transfer(bar,-1,false) and not st.finance.transfer(bar.duplicate(true),1,true) and JSON.stringify(m.s)==before,"Invalid or foreign transfers are rejected without any mutation")
	st.finance.transfer(bar,100,true)
	test.check(bar.cash==128 and m.s.cash==100 and st.finance.total()==228 and bar.shift.revenue==0 and bar.earnings_net==0,"Transfers conserve wealth and do not count as trading")
	st.finance.transfer(bar,100,false)
	m.s.cash = 700000
	m.s.rep = 100
	m.s.street.chapter = 2
	var bank_before: int = m.s.cash
	st.action("buy",1)
	var other: Dictionary = st.selected()
	test.check(other.cash==st.opening_reserve(1) and m.s.cash==bank_before-24000-other.cash and bar.cash==228,"Leases spend bank money, fund the new till and leave other tills untouched")
	var total: int = st.finance.total()
	other.cash = 0
	var quote: Dictionary = st.funded_offer("upgrade")
	before = JSON.stringify(m.s)
	test.check(quote.enabled and quote.transfer==quote.required and JSON.stringify(m.s)==before,"A rich company can quote a new venue renovation without local milestones or side effects")
	total = st.finance.total()
	st.fund_and_buy("upgrade")
	test.check(other.stage==2 and st.finance.total()==total-18000 and other.cash==e.operating_rate(other)*2 and other.happy==0,"Fund-and-buy transfers only the shortfall and charges the renovation once")
	m.s.cash = 0
	before = JSON.stringify(m.s)
	st.fund_and_buy("upgrade")
	test.check(JSON.stringify(m.s)==before,"An unfunded compound purchase makes no partial transfer or stage change")
	other.cash = 10000
	e.income(other,100)
	e.cost(other,20,"operating")
	test.check(other.cash==10080 and bar.cash==228 and m.s.cash==0,"Venue receipts and expenses never borrow from another account")
	other.cash = 0
	other.customers.clear()
	m.s.street.pass_credit = -10000000
	st.tick(5)
	test.check(not other.open and m.s.debt==0 and bar.cash<=228,"An insolvent venue closes without creating debt or draining a neighbour")
	other.open = true
	other.cash = 100000
	other.manager = true
	other.manager_level = 3
	other.manager_bonus_carry = 0
	test.check(e.bonus_amount(other,42)==31 and other.manager_bonus_carry==50 and e.bonus_amount(other,42)==32 and other.manager_bonus_carry==0,"Bonuses preserve fractional carry and use earned margin")
	other.manager_bonus_carry = 0
	other.shift = e.ledger()
	other.stock = 30
	other.stock_lots = [{"units":30,"cost":38,"drink":0}]
	e.admit(other,false,true)
	var guest: Dictionary = other.customers.back()
	guest.drink = 0
	guest.quoted = 80
	guest.order = true
	total = other.cash
	e.serve(other)
	test.check(other.cash==total+111 and other.shift.manager_income==31 and other.shift.sales==1 and m.s.cash==0,"A real discounted drink earns the margin bonus separately from its customer receipt")
	other.customers.clear()
	var bonus: int = other.shift.manager_income
	st.tick(5)
	test.check(other.shift.manager_income==bonus,"Empty trading cannot produce manager bonuses")
	other.happy = 70
	other.regulars = 10
	other.healthy = 8
	test.check(e.loyalty_rank(other)==1,"Local milestones earn the first loyalty rank")
	other.happy = 450
	other.regulars = 70
	other.healthy = 40
	test.check(e.loyalty_rank(other)==2,"Second loyalty rank replaces rather than stacks the first")
	m.s.cash = 750000
	var traffic: float = e.base_traffic()
	for i in 10: st.buy_marketing()
	test.check(m.s.street.marketing_level==10 and m.s.cash==0 and is_equal_approx(e.base_traffic(),traffic+105),"Ten marketing purchases cost 750000 and add exactly 105 bounded potential visitors/min")
	before = JSON.stringify(m.s)
	st.buy_marketing()
	test.check(JSON.stringify(m.s)==before,"Completed marketing cannot be purchased again")
	# Migrate a real pre-finance shape; neither the total nor the paid assets change.
	m.s.cash = 700000
	m.s.reserve = 500
	for venue in m.s.street.bars:
		for key in e.Finance.fields(): venue.erase(key)
	m.s.version = 15
	m.s.street.erase("marketing_level")
	m.save_game()
	var loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.street.finance.total()==700500 and loaded.street.selected().manager_level==3 and loaded.street.selected().stage==2,"Schema sixteen migration conserves old till plus reserve and all paid levels")
	total = loaded.street.finance.total()
	loaded.save_game()
	var again = Campaign.new(5)
	test.check(again.load_game() and again.street.finance.total()==total and again.s.street.bars==loaded.s.street.bars,"Finance migration and allocation are repeat-safe")
	# With too little money, stable proportional allocation preserves every baht.
	var poor = Campaign.new(9)
	poor.s.cash = 1
	poor.s.version = 15
	poor.street.finance.migrate(poor.street.economy,false)
	test.check(poor.street.finance.total()==1 and poor.street.selected().cash==1,"Low-cash migration cannot mint a working float")

	run_growth(test)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.show_tutorial_hint = false
	app.model.s.cash = 700000
	app.model.s.rep = 100
	app.model.s.street.chapter = 2
	app.model.street.action("buy",1)
	var bar: Dictionary = app.model.street.selected()
	bar.cash = 0
	app.open_upgrades(true)
	var control: Button = app.column.find_child("Upgrade_renovate",true,false)
	test.check(control!=null and not control.disabled and control.text.contains("Fund & buy"),"A rich player's renovation clearly offers company funding")
	var total: int = app.model.street.finance.total()
	control.pressed.emit()
	test.check(bar.stage==2 and app.model.street.finance.total()==total-18000,"The funding control charges one renovation through the model")
	var snapshot := JSON.stringify(app.model.s)
	app.open_service_section("finance")
	test.check(test.find_button(app,"Deposit surplus")!=null and app.column.find_child("TransferAmount",true,false)!=null and JSON.stringify(app.model.s)==snapshot,"Cash & Bank exposes explicit transfers without changing funds just by opening")
	app.model.s.street.selected = 0
	app.open_service_section("finance")
	test.check(app.model.street.selected().cash==228,"Switching accounts preserves the original venue till")
	app.queue_free()
	await test.process_frame

func run_growth(test: SceneTree) -> void:
	var m = Campaign.new(291)
	var st = m.street
	var e = st.economy
	var b: Dictionary = st.selected()
	m.s.cash = 700000
	m.s.rep = 100
	m.s.street.chapter = 4
	b.stage = 3
	for kind in [1,1,2]: st.action("buy",kind)
	var total: int = st.finance.total()
	for slot in range(1,4):
		m.s.street.selected = slot
		var price: int = st.funded_offer("upgrade").price
		st.fund_and_buy("upgrade",0,price)
		var after: int = st.finance.total()
		st.fund_and_buy("upgrade",0,price)
		test.check(st.selected().stage==2 and st.finance.total()==after,"Stale renovation clicks cannot buy a second tier")
	test.check(st.finance.total()==total-18000*2-45000,"A four-venue company can fund all new stage-two premises without buying loyalty")
	var traffic: float = e.traffic_rate()
	st.buy_marketing()
	test.check(e.traffic_rate()>traffic and st.selected().sold==0,"Marketing expands potential traffic without awarding a sale")
	var snapshot := JSON.stringify(m.s)
	st.fund_and_buy("equipment",-1)
	st.fund_and_buy("train_staff",500)
	test.check(JSON.stringify(m.s)==snapshot,"Invalid compound purchases cannot transfer money")
	m.s.street.selected = 0
	b.manager = true
	b.manager_level = 3
	b.equipment.pool = 1
	b.customers.resize(2)
	for guest in b.customers:
		guest.pool = true
		guest.played = false
		guest.playing = false
		guest.budget = 500
	var cash_before: int = b.cash
	e.pool_tick(b)
	var bonus: int = b.shift.manager_income
	e.pool_tick(b)
	test.check(b.cash==cash_before+87 and bonus==37 and b.shift.manager_income==bonus and b.pool_income==50,"A paid game settles one fee and one fractional management bonus")
	b.games.clear()
	for guest in b.customers:
		guest.played = false
		guest.playing = false
	b.promo = {"kind":0,"pool_revenue":0,"free_games":0}
	e.pool_tick(b)
	test.check(b.cash==cash_before+87 and b.shift.manager_income==bonus and b.free_games==1,"Free pool cannot earn a management bonus")
	b.promo.clear()
	snapshot = JSON.stringify(m.s)
	st.finance.transfer(b,1,true)
	e.sample_earnings()
	test.check(b.earnings_net==87,"Transfers do not enter the local trading sample")
	# A managed claim credits only its own till, never company cash or neighbours.
	b.cash = 10000
	b.restock = true
	b.supplier_level = 1
	st.action("hire",0)
	b.team[0].training = 4
	b.stock = 30
	b.stock_lots = [{"units":30,"cost":38,"drink":0}]
	b.equipment.pool = 0
	m.s.street.last_seen = 1000
	var bank: int = m.s.cash
	var other: int = m.s.street.bars[1].cash
	cash_before = b.cash
	var earned: int = e.offline(1060,28800)
	test.check(earned>0 and b.cash==cash_before+earned and m.s.cash==bank and m.s.street.bars[1].cash==other,"Offline managed trade credits only the earning venue and protects other accounts")
	test.check(e.offline(1060,28800)==0 and b.cash==cash_before+earned,"Offline credits are repeat-safe")
	m.save_game()
	var path := "user://invalid-finance.json"
	for field in ["cash","manager_bonus_carry"]:
		var invalid: Dictionary = m.s.duplicate(true)
		invalid.street.bars[0][field] = -1
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		test.check(m._read(path)==null,"Schema sixteen rejects invalid "+field)

	var recovery = Campaign.new(11)
	var recovered: Dictionary = recovery.street.selected()
	recovered.manager = true
	recovered.manager_level = 3
	recovered.stock = 6
	recovered.consignment = 6
	recovered.stock_lots = [{"units":6,"cost":14,"drink":0}]
	var opening: int = recovered.cash
	recovery.street.economy.serve(recovered)
	test.check(recovered.cash==opening+80-14+49 and recovered.manager_bonus_carry==50,"Consignment repayment is deducted once, not again as a prepaid stock cost")

	var returns = Campaign.new(72)
	var returned: Dictionary = returns.street.selected()
	returned.manager = true
	returned.manager_level = 3
	var cash_start: int = returned.cash
	returns.street.action("return_drink",0)
	test.check(returned.cash==cash_start+57 and returned.earnings_net==57 and returned.shift.manager_income==0 and returned.manager_bonus_carry==0,"Paid stock returns enter only that till's cashflow and earn no manager bonus")
