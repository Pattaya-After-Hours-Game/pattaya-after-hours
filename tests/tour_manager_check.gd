extends RefCounted

const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	var eco = st.economy
	var bar: Dictionary = st.selected()
	test.check(m.s.street.tour_manager==0 and not m.s.street.tour_manager_on,"Tour manager starts unowned and off")
	m.s.cash = 100000
	m.upgrade_tours()
	test.check(m.s.cash==98000 and m.s.street.tour_manager==1 and m.s.street.tour_manager_on,"Manager level one costs its listed price and enables automation")
	var before := JSON.stringify(m.s)
	m.tour_upgrade_offer()
	m.tour_manager_ready()
	test.check(JSON.stringify(m.s)==before,"Tour manager offers and status are pure reads")
	m.s.cash = 1000
	m.tour_manager_tick()
	test.check(m.s.bookings.is_empty(),"Exactly 1000 cannot trigger automatic tours")
	m.s.cash = 1001
	m.tour_manager_tick()
	test.check(m.s.bookings=={"1":0} and m.s.cash==856,"Automation rechecks strict cash threshold before each guide")
	m.s.cash = 10000
	m.tour_manager_tick()
	test.check(m.s.bookings.size()==2 and m.s.cash==9855,"Automation skips active agreements and books eligible guides once")
	before = JSON.stringify(m.s)
	m.tour_manager_tick()
	test.check(JSON.stringify(m.s)==before,"Repeated automation cannot repay an active tour")
	m.booking(2,1)
	st.end_shift()
	m.s.staff[1].work = false
	m.tour_manager_tick()
	test.check(m.s.bookings=={"2":1},"Expired agreements renew the last route and respect off duty guides")
	m.s.bookings.clear()
	m.s.staff[2].hurt = 1
	m.tour_manager_tick()
	test.check(m.s.bookings.is_empty(),"Injured guides never auto-book")
	m.s.staff[2].hurt = 0
	m.s.weather = 6
	m.tour_manager_tick()
	test.check(m.s.bookings.is_empty(),"Automation retains route-specific weather refusal")
	m.s.weather = 0
	bar.open = false
	test.check(not m.tour_manager_ready(),"Closed venues cannot trigger tours")
	bar.open = true
	bar.closed = 10
	test.check(not m.tour_manager_ready(),"Disaster closure cannot trigger tours")
	bar.closed = 0
	while bar.customers.size()<eco.seats(bar): eco.admit(bar)
	test.check(not m.tour_manager_ready(),"Full venues cannot trigger tours")
	eco.clear_visits(bar)
	m.s.street.minute = 23*60
	test.check(not m.tour_manager_ready(),"Exactly two hours to normal close cannot trigger tours")
	m.s.street.minute -= 1
	test.check(m.tour_manager_ready(),"Two hours and one minute before close allows tours")
	bar.late_open = true
	m.s.street.minute = 0
	test.check(m.tour_manager_ready(),"Late permission uses the actual three am closing time")
	m.s.street.minute = 60
	test.check(not m.tour_manager_ready(),"Exactly two hours to late close cannot trigger tours")
	m.s.street.minute = 720
	bar.late_open = false
	m.toggle_tour_manager()
	test.check(not m.tour_manager_ready(),"Purchased tour automation can be switched off")
	m.s.cash = 100000
	m.upgrade_tours()
	test.check(m.s.street.tour_manager==2 and m.guide_pay(0)==131 and m.guide_pay(2)==261,"Manager level two saves ten percent with whole-baht upward rounding")
	m.upgrade_tours()
	test.check(m.s.cash==88000 and m.guide_pay(0)==109 and m.guide_pay(2)==218,"Manager level three saves twenty-five percent without stacking")
	m.s.pay = 0
	test.check(m.guide_pay(0)==75,"Manager discounts apply to the chosen pay split")
	m.s.pay = 1
	m.upgrade_tours(2)
	test.check(is_equal_approx(eco.guide_appeal(2),.55) and eco.guide_appeal(1)==.5,"Guide level two adds ten percent appeal only to that guide")
	m.upgrade_tours(2)
	test.check(m.s.cash==85600 and eco.guide_appeal(2)==.625 and m.guide_pay(0)==109,"Guide level three adds twenty-five percent appeal independently of fees")
	before = JSON.stringify(m.s)
	m.upgrade_tours()
	m.upgrade_tours(2)
	test.check(JSON.stringify(m.s)==before,"Maxed tour upgrades cannot charge again")
	m.booking(2,0)
	var without: float = eco.attraction(bar,false,-1,-1,0,false)
	var trained: float = eco.attraction(bar)
	m.s.staff[2].tour_training = 0
	test.check(trained>eco.attraction(bar) and eco.attraction(bar)>without,"Training changes live bounded attraction rather than creating guests")
	m.s.staff[2].tour_training = 2
	m.toggle_tour_manager()
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.street.tour_manager==3 and loaded.s.street.tour_manager_on and loaded.s.staff[2].tour_training==2 and loaded.s.staff[2].tour_route==0,"Tour manager, guide training and chosen routes round-trip")
	var saved_cash: int = loaded.s.cash
	loaded.tour_manager_tick()
	loaded.tour_manager_tick()
	test.check(loaded.s.cash==saved_cash and loaded.s.bookings==m.s.bookings,"Reload keeps paid agreements without repeating fees")
	# Validation checks the actual reader without falling back to a backup.
	var path := "user://tour-validation.json"
	for entry in [["tour_manager",4],["tour_manager",1.5],["tour_manager",true],["tour_manager_on",1]]:
		var bad: Dictionary = m.s.duplicate(true)
		bad.street[entry[0]] = entry[1]
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(bad))
		test.check(m._read(path)==null,"Invalid tour manager save field rejected: %s" % str(entry))
	for entry in [["tour_training",3],["tour_training",.5],["tour_route",4],["tour_route","0"]]:
		var bad: Dictionary = m.s.duplicate(true)
		bad.staff[2][entry[0]] = entry[1]
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(bad))
		test.check(m._read(path)==null,"Invalid guide save field rejected: %s" % str(entry))
	m.s.street.erase("tour_manager")
	m.s.street.erase("tour_manager_on")
	m.s.staff[2].erase("tour_training")
	m.s.staff[2].erase("tour_route")
	m.save_game()
	test.check(loaded.load_game() and loaded.s.street.tour_manager==0 and not loaded.s.street.tour_manager_on,"Older schema seventeen saves gain no free tour purchases")
	for phase in ["guided","guided_choice","report","godzilla"]:
		loaded.s.phase = phase
		loaded.s.street.tour_manager = 1
		loaded.s.street.tour_manager_on = true
		test.check(not loaded.tour_manager_ready(),"Tour manager stays paused in %s" % phase)
	loaded.s.phase = "plan"
	loaded.s.practice = true
	test.check(not loaded.tour_manager_ready(),"Practice never executes purchased tour automation")

	var exact = Campaign.new(72)
	exact.s.cash = 800
	exact.upgrade_tours(2)
	test.check(exact.s.cash==0 and exact.s.staff[2].tour_training==1,"Training needs only its listed price")
	exact.s.cash = 2000
	exact.upgrade_tours()
	test.check(exact.s.cash==0 and exact.s.street.tour_manager==1,"Manager needs only its listed price")
	exact.s.cash = 145
	exact.booking(2,0)
	test.check(exact.s.cash==0 and exact.s.bookings.has("2"),"Manual tours retain listed-fee affordability below the automation threshold")
	var live = Campaign.new(72)
	live.s.cash = 10000
	live.upgrade_tours(2)
	test.check(live.s.street.tour_manager==0 and live.s.staff[2].tour_training==1,"Personal guide training needs no manager")
	live.upgrade_tours()
	live.street.tick(1)
	test.check(live.s.bookings.size()==2,"The normal live clock runs purchased tour automation")
	live.s.bookings.clear()
	live.street.end_shift()
	var copy = live.tuning_copy()
	copy.street.tick(1)
	test.check(copy.s.bookings.size()==2 and live.s.bookings.is_empty(),"Tuning copies connect automation to their own street")
	live.s.street.last_seen = 1000
	live.street.claim_offline(1060)
	test.check(live.s.bookings.is_empty(),"Offline catch-up cannot buy tour agreements")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model.s.cash = 10000
	var before := JSON.stringify(app.model.s)
	app.change_tab(2)
	test.check(JSON.stringify(app.model.s)==before and app.column.has_node("TourManagerUpgrade"),"Tour manager navigation is read-only and exposes purchase")
	app.column.get_node("TourManagerUpgrade").pressed.emit()
	test.check(app.model.s.street.tour_manager==1 and app.column.has_node("TourManagerToggle"),"Manager UI purchases the model upgrade")
	app.column.get_node("TourManagerToggle").pressed.emit()
	test.check(not app.model.s.street.tour_manager_on,"Manager UI toggles automatic tours")
	app.column.get_node("TourGuide_2").pressed.emit()
	app.column.get_node("TourGuideTraining").pressed.emit()
	test.check(app.model.s.staff[2].tour_training==1,"Guide detail purchases personal training")
	before = JSON.stringify(app.model.s)
	app.render()
	for entry in app.live_labels: entry[1].call()
	test.check(JSON.stringify(app.model.s)==before,"Tour controls and live labels cannot spend or book")
	app.boot_menu = true
	before = JSON.stringify(app.model.s)
	app._process(5.0)
	test.check(JSON.stringify(app.model.s)==before,"Startup menu cannot run purchased tour automation")
	app.queue_free()
	await test.process_frame
