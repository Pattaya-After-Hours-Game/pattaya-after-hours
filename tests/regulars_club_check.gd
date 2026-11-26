extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.s.cash = 10000
	m.street.action("regulars_club")
	test.check(b.club_level==0,"Club cannot bypass stage two")
	b.stage = 2
	b.regulars = 9
	m.street.action("regulars_club")
	test.check(b.club_level==0,"Club needs its own venue's regulars")
	b.regulars = 40
	var offer: Dictionary = e.club_offer(b)
	m.s.cash = offer.price+offer.reserve-1
	m.street.action("regulars_club")
	test.check(b.club_level==0,"Club keeps a whole pack plus operating reserve")
	m.s.cash += 1
	var old_guest: Dictionary = b.customers[0].duplicate(true)
	m.street.action("regulars_club")
	test.check(b.club_level==1 and m.s.cash==offer.reserve and b.customers[0]==old_guest,"Exact club purchase changes future visits without adding cash, budgets or orders to existing guests")
	m.s.cash = 10000
	m.street.action("regulars_club")
	m.street.action("regulars_club")
	var money: int = m.s.cash
	m.street.action("regulars_club")
	test.check(b.club_level==3 and m.s.cash==money,"Maximum club level rejects further purchase charges")
	var snapshot := JSON.stringify(m.s)
	e.club_offer(b)
	e.club_forecast(b)
	test.check(snapshot==JSON.stringify(m.s),"Club forecasts do not roll RNG or change the business")
	b.customers.clear()
	e.admit(b,false,true)
	var guest: Dictionary = b.customers[0]
	test.check(guest.club and guest.planned_rounds==3 and guest.budget==340,"A club visitor has three planned rounds and a finite budget")
	for i in 3:
		guest.next = 0
		e.order(b,guest)
		e.serve(b)
	guest.next = 0
	e.order(b,guest)
	test.check(guest.drinks==3 and not guest.order and b.tip_visits==1,"Club serves three real drinks but only one base tip")
	m.s.day = 7
	m.street.celebration_tick()
	guest.next = 0
	e.order(b,guest)
	test.check(not guest.order,"Club and birthday cannot stack into a fourth drink")
	guest.drinks = 2
	guest.budget = 0
	guest.next = 0
	e.order(b,guest)
	test.check(not guest.order,"An extra round still needs a customer budget")
	guest.budget = 100
	guest.next = 0
	e.order(b,guest)
	b.stock = 0
	money = m.s.cash
	e.serve(b)
	test.check(guest.drinks==2 and m.s.cash==money,"Club never turns a stockout into income")
	# Stage-two music changes future repeats, never existing order deadlines.
	b.customers.clear()
	m.s.day = 8
	m.s.cash = 20000
	b.stage = 1
	m.street.action("equipment",8)
	m.street.action("equipment",8)
	test.check(b.equipment.music==1,"Second music tier requires stage two")
	b.stage = 2
	e.admit(b,false,true)
	guest = b.customers[0]
	guest.next = 21
	money = m.s.cash
	m.street.action("equipment",8)
	test.check(b.equipment.music==2 and m.s.cash==money-2400 and guest.next==21 and e.repeat_order_seconds(b)==18,"Better sound costs 2400 and preserves current repeat deadline")
	b.stock = 12
	e.ensure_stock_lots(b)
	e.serve(b)
	test.check(guest.next==18,"Better sound sets the next real repeat to eighteen seconds")
	m.s.day = 7
	test.check(e.repeat_order_seconds(b)==14,"Better sound shortens party repeats without adding rounds")
	m.s.day = 8
	m.street.action("hire",0)
	var person: Dictionary = b.team[0]
	person.training = 2
	person.service_ready = 17.25
	b.stage = 1
	m.street.action("train_staff",0)
	test.check(person.training==2,"Advanced bartender training requires stage two")
	b.stage = 2
	money = m.s.cash
	m.street.action("train_staff",0)
	test.check(person.training==3 and e.service_seconds(person)==12 and m.s.cash==money-1200 and person.service_ready==17.25,"Twelve-second training costs 1200 without resetting recovery")
	m.street.action("train_staff",0)
	test.check(person.training==4 and e.service_seconds(person)==10 and m.s.cash==money-2800,"Ten-second training costs another 1600")
	money = m.s.cash
	m.street.action("train_staff",0)
	test.check(person.training==4 and m.s.cash==money,"Maximum bartender training cannot charge again")
	person.contract_left = 0
	m.street.action("rehire",0)
	test.check(person.training==4 and person.service_ready==17.25,"Advanced training and deadline survive rehire")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.version==14 and loaded.street.selected().club_level==3 and loaded.street.selected().customers[0].club,"Club level and visit entitlement survive reload")
	test.check(loaded.street.selected().equipment.music==2 and loaded.street.selected().team[0].training==4 and loaded.street.selected().team[0].service_ready==17.25,"Schema thirteen retains better sound and advanced training")
	guest.order = true
	guest.budget = 300
	person.service_ready = 0.0
	var before_sales: int = b.sold
	e.staff_service(b)
	test.check(b.sold==before_sales+1 and person.service_ready==e.action_time()+10,"Advanced bartender performs a real sale then waits ten seconds")
	e.staff_service(b)
	test.check(b.sold==before_sales+1,"Advanced training does not double-serve during recovery")
	b.manager = true
	b.manager_level = 1
	b.restock = true
	b.supplier_level = 4
	m.s.street.last_seen = 1000
	money = m.s.cash
	var sold: int = b.sold
	var tips: int = b.tip_visits
	var gain: int = m.street.claim_offline(1120)
	test.check(gain>0 and m.s.cash==money+gain and b.sold==sold and b.tip_visits==tips,"Club offline projection earns after costs without live sales or tips")
	var once := [m.s.cash,b.stock,b.stock_lots.duplicate(true),b.commission_paid,b.offline_sales_credit,b.sold,b.tip_visits]
	m.street.claim_offline(1120)
	test.check([m.s.cash,b.stock,b.stock_lots,b.commission_paid,b.offline_sales_credit,b.sold,b.tip_visits]==once,"Club offline projection is repeat-safe")
	# The update gives old campaigns no free club, refund or retroactive extra round.
	b.equipment.music = 1
	b.team[0].training = 2
	m.s.version = 11
	b.erase("club_level")
	for customer in b.customers: customer.erase("club")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.cash==m.s.cash and loaded.street.selected().club_level==0 and not loaded.street.selected().customers[0].club,"Schema eleven migrates without gifts or changed customer entitlements")
	b = loaded.street.selected()
	b.club_level = 4
	var f := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	f.store_string(JSON.stringify(loaded.s))
	f.close()
	test.check(loaded._read(Campaign.SAVE)==null,"Malformed club levels cannot enter a save")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model = Campaign.new(72)
	var b: Dictionary = app.model.street.selected()
	b.stage = 2
	b.regulars = 40
	app.model.s.cash = 2611
	app.drawer_open = true
	app.upgrades_open = true
	app.upgrades_ready_only = false
	app.render()
	var card = app.column.find_child("Upgrade_club",true,false)
	test.check(card!=null,"Regulars Club appears in the actual upgrade drawer")
	if card:
		var button: Button = card
		test.check(not button.disabled and button.text.contains("600"),"Day-eight cash can afford the first club offer")
		button.pressed.emit()
		test.check(b.club_level==1 and app.model.s.cash==2011,"Club UI purchases exactly once through the shared model")
	app.model.s.cash = 10000
	app.model.street.action("equipment",8)
	app.model.street.action("hire",0)
	b.team[0].training = 2
	app.render()
	for key in ["music","training_0"]:
		card = app.column.find_child("Upgrade_"+key,true,false)
		test.check(card!=null,"Stage-two offer visible: "+key)
		if card: card.pressed.emit()
	test.check(b.equipment.music==2 and b.team[0].training==3,"Stage-two sound and training purchase through the drawer")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
