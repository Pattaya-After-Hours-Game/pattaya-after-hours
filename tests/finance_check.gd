extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	var e = st.economy
	var bar: Dictionary = st.selected()
	test.check(m.s.cash==228 and not bar.has("cash") and st.finance.total()==228,"Fresh campaign has exactly one shared 228-baht balance")
	m.s.cash = 24000
	m.s.rep = 100
	m.s.street.chapter = 2
	var before := JSON.stringify(m.s)
	var lease: Dictionary = st.lease_quote(1)
	test.check(lease.enabled and lease.required==24000 and lease.reserve==0 and JSON.stringify(m.s)==before,"Lease quote needs exactly its price and is read-only")
	st.action("buy",1)
	var other: Dictionary = st.selected()
	test.check(m.s.cash==0 and not other.has("cash") and m.s.street.bars.size()==2,"Lease spends the shared balance once without a startup float")
	e.income(bar,100)
	e.cost(other,20,"fines")
	test.check(m.s.cash==80 and bar.shift.revenue==100 and other.shift.fines==20,"Either venue uses the shared balance while reports retain attribution")
	m.s.cash = 18000
	var quote: Dictionary = st.funded_offer("upgrade")
	test.check(quote.enabled and quote.required==quote.price,"Renovation requires no reserve")
	st.fund_and_buy("upgrade",0,18000)
	test.check(other.stage==2 and m.s.cash==0,"Exact-price renovation works with zero cash left")
	before = JSON.stringify(m.s)
	st.fund_and_buy("upgrade",0,18000)
	test.check(JSON.stringify(m.s)==before,"Stale purchase cannot buy the next stage")
	# All purchase offers expose only the payable cost, retaining other gates.
	m.s.cash = 100000
	st.action("hire",0)
	st.action("restock")
	for offer in [e.manager_offer(other),e.supplier_offer(other),e.hire_offer(other,1),e.training_offer(other,0,false),e.equipment_offer(other,0),e.action_upgrade_status(other,0),e.auto_serve_offer(other),e.auto_bar_fine_offer(other),e.auto_hosted_offer(other),e.club_offer(other)]:
		test.check(offer.required==offer.price,"Purchase quote has no hidden working-cash requirement")
	other.stock = 0
	other.stock_lots = []
	m.s.cash = e.pack_price(other)
	test.check(e.restock(other,true) and m.s.cash==0,"Automatic supplier can spend exactly the pack price")
	# Old bank, tills and reserve consolidate exactly once; paid assets survive.
	m.s.version = 16
	m.s.cash = 321
	m.s.reserve = 17
	bar.cash = 222
	other.cash = 444
	m.save_game()
	var loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.s.version==17 and loaded.s.cash==1004 and loaded.s.reserve==0 and loaded.street.selected().stage==2,"Schema sixteen balances merge without gifts, loss or asset changes")
	loaded.save_game()
	var again = Campaign.new(5)
	test.check(again.load_game() and again.s.cash==1004 and not again.street.selected().has("cash"),"Shared account migration is repeat-safe")
	loaded.s.version = 15
	loaded.s.cash = 1
	loaded.s.reserve = 7
	loaded.save_game()
	test.check(again.load_game() and again.s.cash==8,"Pre-sixteen cash plus reserve conserves every baht without allocation")
	run_recovery(test)
	run_growth(test)

func run_recovery(test: SceneTree) -> void:
	var m = Campaign.new(82)
	var e = m.street.economy
	var b: Dictionary = m.street.selected()
	m.s.cash = 0
	b.stock = 0
	b.stock_lots = []
	b.tip_visits = 23
	b.bonus_tips = 5
	var revenue: int = b.shift.revenue
	m.street.action("close_and_count")
	test.check(not b.open and m.s.cash==235 and b.tip_visits==0 and b.bonus_tips==0 and b.shift.revenue==revenue and b.earnings_net==0,"Early closing counts earned tips once outside customer trading")
	m.street.tick(10)
	test.check(m.s.cash==235,"Closed venue stops rent, electricity and wages")
	m.save_game()
	var loaded = Campaign.new(9)
	loaded.load_game()
	loaded.street.action("close_and_count")
	test.check(loaded.s.cash==235,"Reload and repeat closing cannot duplicate paid tips")
	loaded.street.action("stock")
	test.check(loaded.s.cash==7 and loaded.street.selected().stock==6,"Closing tips can buy a complete stock pack while shut")
	m.s.street.minute = C.CLOSE_MINUTE
	e.settle_tips()
	test.check(m.s.cash==235,"Nightly settlement cannot repay an early counted jar")
	# An unpaid rounded bill must not immediately close a zero-cash recovery shift.
	var stranded = Campaign.new(24)
	var empty: Dictionary = stranded.street.selected()
	stranded.s.cash = 0
	empty.open = false
	empty.stock = 0
	empty.stock_lots = []
	empty.cost_credit = 70
	stranded.street.action("recovery")
	stranded.street.tick(1)
	test.check(empty.open and empty.recovery==119 and empty.cost_credit==70 and stranded.s.cash==0,"Recovery defers an unpaid operating bill instead of immediately reclosing")
	stranded.street.economy.admit(empty,false,true)
	stranded.street.action("serve")
	test.check(stranded.s.cash==66 and empty.consignment==5,"Zero-cash recovery earns only a real sale less consignment repayment")
	empty.recovery = 1
	stranded.street.tick(1)
	test.check(stranded.s.cash==65 and empty.cost_credit==28 and empty.open,"Earned cash pays the carried bill when recovery ends, with exact remainder")
	var before := JSON.stringify(m.s)
	e.operating_breakdown(b)
	e.operating_description(b)
	test.check(JSON.stringify(m.s)==before,"Cost descriptions do not charge or change the model")
	b.open = true
	m.s.street.minute = C.OPEN_MINUTE
	m.s.street.pass_credit = -100000
	m.street.tick(60)
	test.check(m.s.cash==217 and b.shift.operating==18,"Opening charges exactly the existing 12 rent plus 6 electricity per minute")
	var movements := 0
	for entry in m.s.street.cashbook:
		movements += int(entry.amount)
		test.check(not entry.reason.is_empty(),"Every recorded cash movement names its cause")
	test.check(movements==m.s.cash,"Recorded tips and operating outgoings reconcile to cash")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.show_tutorial_hint = false
	app.model.s.cash = 18000
	app.model.street.selected().type = 1
	app.open_upgrades(true)
	var control: Button = app.column.find_child("Upgrade_renovate",true,false)
	test.check(control!=null and not control.disabled and not control.text.contains("Fund & buy"),"Renovation offers a direct purchase at the exact shared balance")
	control.pressed.emit()
	test.check(app.model.street.selected().stage==2 and app.model.s.cash==0,"Visible purchase charges the shared account once")
	var snapshot := JSON.stringify(app.model.s)
	app.open_service_section("finance")
	test.check(not test.panel_has_text(app,"Deposit surplus") and app.column.find_child("TransferAmount",true,false)==null and JSON.stringify(app.model.s)==snapshot,"Money view is read-only and contains no transfer controls")
	test.check(test.find_button(app,"Close & count tips")!=null,"Money view exposes closing-tip recovery")
	app.model = Campaign.new(82)
	var bar: Dictionary = app.model.street.selected()
	app.model.s.cash = 0
	bar.stock = 0
	bar.stock_lots = []
	bar.tip_visits = 24
	app.open_fridge()
	test.find_button(app,"Close & count tips").pressed.emit()
	test.check(not bar.open and app.model.s.cash==240 and bar.tip_visits==0,"The empty-fridge closing control credits only the earned jar")
	test.find_button(app,"Buy 6 · ฿228").pressed.emit()
	test.check(bar.stock==6 and app.model.s.cash==12 and not bar.open,"The real fridge control buys stock with counted tips while closed")
	app.open_service_section("hours")
	test.find_button(app,"Enable opening").pressed.emit()
	test.check(bar.open and app.model.s.cash==12,"The real opening control resumes the restocked venue without an extra payment")
	var loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.s.cash==12 and loaded.street.selected().stock==6 and loaded.street.selected().tip_visits==0,"UI recovery checkpoints stock, money and the paid jar together")
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
	var cash_before: int = m.s.cash
	e.pool_tick(b)
	var bonus: int = b.shift.manager_income
	e.pool_tick(b)
	test.check(m.s.cash==cash_before+87 and bonus==37 and b.shift.manager_income==bonus and b.pool_income==50,"A paid game settles one fee and one fractional management bonus")
	b.games.clear()
	for guest in b.customers:
		guest.played = false
		guest.playing = false
	b.promo = {"kind":0,"pool_revenue":0,"free_games":0}
	e.pool_tick(b)
	test.check(m.s.cash==cash_before+87 and b.shift.manager_income==bonus and b.free_games==1,"Free pool cannot earn a management bonus")
	b.promo.clear()
	snapshot = JSON.stringify(m.s)
	e.sample_earnings()
	test.check(b.earnings_net==87,"Only real trading enters the local trading sample")
	# A managed claim credits only its own till, never company cash or neighbours.
	m.s.cash = 10000
	b.restock = true
	b.supplier_level = 1
	st.action("hire",0)
	b.team[0].training = 4
	b.stock = 30
	b.stock_lots = [{"units":30,"cost":38,"drink":0}]
	b.equipment.pool = 0
	m.s.street.last_seen = 1000
	cash_before = m.s.cash
	var earned: int = e.offline(1060,28800)
	test.check(earned>0 and m.s.cash==cash_before+earned,"Offline managed trade credits shared cash without spending opening cash")
	test.check(e.offline(1060,28800)==0 and m.s.cash==cash_before+earned,"Offline credits are repeat-safe")
	m.save_game()
	var path := "user://invalid-finance.json"
	for field in ["cash","manager_bonus_carry"]:
		var invalid: Dictionary = m.s.duplicate(true)
		if field=="cash": invalid.cash = -1
		else: invalid.street.bars[0][field] = -1
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		test.check(m._read(path)==null,"Schema seventeen rejects invalid "+field)

	var recovery = Campaign.new(11)
	var recovered: Dictionary = recovery.street.selected()
	recovered.manager = true
	recovered.manager_level = 3
	recovered.stock = 6
	recovered.consignment = 6
	recovered.stock_lots = [{"units":6,"cost":14,"drink":0}]
	var opening: int = recovery.s.cash
	recovery.street.economy.serve(recovered)
	test.check(recovery.s.cash==opening+80-14+49 and recovered.manager_bonus_carry==50,"Consignment repayment is deducted once, not again as a prepaid stock cost")

	var returns = Campaign.new(72)
	var returned: Dictionary = returns.street.selected()
	returned.manager = true
	returned.manager_level = 3
	var cash_start: int = returns.s.cash
	returns.street.action("return_drink",0)
	test.check(returns.s.cash==cash_start+57 and returned.earnings_net==57 and returned.shift.manager_income==0 and returned.manager_bonus_carry==0,"Paid stock returns enter only that till's cashflow and earn no manager bonus")
