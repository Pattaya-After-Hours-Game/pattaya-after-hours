extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func close_night(m) -> void:
	m.s.day = 2
	m.s.street.minute = 59
	m.street.tick(1)

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var money: int = m.s.cash
	e.serve(b)
	test.check(b.tip_visits==1 and m.s.cash==money+55 and b.tips_total==0,"First real sale banks one ten-baht tip without paying it early")
	var guest: Dictionary = b.customers[0]
	e.order(b,guest)
	e.serve(b)
	test.check(guest.drinks==2 and b.tip_visits==1,"Repeat drink during the same visit cannot earn another tip")
	m.street.action("open")
	m.street.action("open")
	e.settle_tips()
	test.check(b.tips_total==0 and b.tip_visits==1,"Daytime closure toggles and direct settlement cannot cash tips early")
	b.customers.clear()
	e.serve(b)
	e.admit(b)
	b.stock = 0
	e.serve(b)
	test.check(b.tip_visits==1,"Empty orders and stockouts cannot earn tips")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().tip_visits==1,"Pending jar persists across reload")
	m.s.street.pass_credit = -10000000
	money = m.s.cash
	close_night(m)
	test.check(m.s.cash==money+10 and b.tip_visits==0 and b.tips_total==10 and b.last_tips.visits==1,"Night closure pays exactly ten per served visit and clears the jar")
	test.check(b.last_shift.revenue==110 and b.last_tips.amount==10,"Tip receipts remain separate from drink/healthy-shift accounting")
	m.street.action("stay")
	m.street.night_prep_tick()
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game(),"Settled tips reload")
	money = loaded.s.cash
	loaded.street.action("skip")
	loaded.street.count_tips()
	test.check(loaded.s.cash==money and loaded.street.selected().tips_total==10,"Cancellation, reload, manual skip and repeated settlement cannot repay a jar")
	m = Campaign.new(72)
	m.s.cash = 100000
	m.s.rep = 100
	m.s.street.chapter = 1
	b = m.street.selected()
	m.street.economy.serve(b)
	m.street.action("buy",1)
	var other: Dictionary = m.street.selected()
	m.street.action("late")
	m.street.economy.admit(other)
	m.street.economy.serve(other)
	close_night(m)
	test.check(b.tips_total==0 and other.tips_total==0,"Late venue delays the street-wide count")
	m.s.street.minute = 179
	money = m.s.cash
	m.street.tick(1)
	test.check(b.tips_total==10 and other.tips_total==10 and m.s.cash==money+19,"After the ordinary baht of overhead, each venue's real customers contribute once at final closure")
	# All service paths contribute visits, while Nida's commission stays drink-only.
	m = Campaign.new(72)
	m.s.cash = 10000
	b = m.street.selected()
	m.street.action("hire",0)
	m.street.action("hire",3)
	m.street.action("auto_serve")
	m.street.economy.staff_service(b)
	m.street.tick(1)
	test.check(b.tip_visits==2 and b.team[0].drinks_served==1 and b.sold==2,"Staff and owner automation bank the same first-serve tips")
	var commission: int = b.commission_paid
	close_night(m)
	test.check(b.tips_total==20 and b.commission_paid==commission,"Nida's commission excludes the tip jar")
	# Reproduce the screenshot without awarding money or deleting waiting orders.
	m = Campaign.new(72)
	m.s.cash = 39
	b = m.street.selected()
	b.stock = 0
	var orders: int = m.street.economy.pending(b)
	m.street.action("emergency_stock")
	test.check(b.stock==6 and b.consignment==6 and m.s.cash==39 and m.street.economy.pending(b)==orders,"Emergency delivery recovers the exact screenshot state without fake buyers or cash")
	m.street.action("emergency_stock")
	test.check(b.stock==6 and b.recovery==120,"Repeated emergency clicks cannot stack stock or cover")
	m.street.economy.serve(b,2)
	test.check(m.s.cash==121 and b.consignment==4 and b.tip_visits==2,"Two real recovery sales repay their stock costs and earn enough for a normal pack")
	m.street.action("stock")
	test.check(b.stock==10 and m.s.cash==37,"Recovered business can purchase a normal full pack")
	m = Campaign.new(72)
	b = m.street.selected()
	b.stock = 0
	b.supplier_level = 2
	m.s.cash = 130
	m.street.action("emergency_stock")
	test.check(b.stock==6 and m.s.cash==130,"Bulk-pack affordability uses the actual 144-baht bill; recovery stays the six-drink exception")
	# Current customers already served before migration do not retroactively tip.
	m = Campaign.new(72)
	b = m.street.selected()
	m.street.economy.serve(b)
	m.s.version = 10
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.version==11 and loaded.street.selected().tip_visits==0,"Old saves start with an empty tip jar, retaining cash and progress")
	b = loaded.street.selected()
	loaded.street.economy.order(b,b.customers[0])
	loaded.street.economy.serve(b)
	test.check(b.tip_visits==0,"A migrated repeat drink cannot grant a historical first-serve tip")
	loaded.s.street.last_seen = 1000
	var pending: int = b.tip_visits
	loaded.street.claim_offline(2000)
	test.check(b.tip_visits==pending and b.tips_total==0,"Offline income cannot earn or count tips")
	b.tip_visits = -1
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(loaded.s))
	file.close()
	test.check(loaded._read(Campaign.SAVE)==null,"Negative saved tip counts are rejected")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.muted = true
	app.start_new_game()
	app.show_tutorial_hint = false
	app.model.s.cash = 39
	app.model.street.selected().stock = 0
	app.model.s.street.minute = 1045
	app.change_tab(0)
	test.check(test.find_button(app,"Bo's recovery delivery · 6 drinks").visible,"Screenshot stockout exposes recovery directly beside stock")
	test.use_button(app,"Bo's recovery delivery · 6 drinks")
	test.check(app.model.s.cash==39 and app.model.street.selected().stock==6,"Recovery UI invokes model consignment without cash handout")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
