extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	m.s.cash = 500000
	m.s.rep = 100
	m.s.street.chapter = 1
	st.selected().name = "Renamed flagship"
	test.check([st.purchase_cost(0),st.purchase_cost(1),st.purchase_cost(2)]==[12000,24000,60000],"First leases follow the beer/hostess/gogo ladder; renamed Blue Hour is excluded")
	var snapshot := JSON.stringify(m.s)
	for kind in 3: st.lease_quote(kind)
	test.check(snapshot==JSON.stringify(m.s),"Lease forecasts never spend cash, age time or run RNG")
	for kind in 3:
		var quote: Dictionary = st.lease_quote(kind)
		m.s.cash = quote.required-1
		var count: int = m.s.street.bars.size()
		st.action("buy",kind)
		test.check(m.s.street.bars.size()==count,"Lease requires the full opening reserve")
		m.s.cash = quote.required
		st.action("buy",kind)
		test.check(m.s.street.bars.size()==count+1 and m.s.cash==0 and st.selected().cash==quote.reserve,"Lease price is spent and the operating float transfers into the new till")
		test.check(st.purchase_cost(kind)==int(C.LEASES[kind])*125/100,"Next same-type lease adds 25 percent of base, never compounds")
		st.action("buy",kind)
		test.check(m.s.street.bars.size()==count+1,"Repeated unaffordable purchase cannot duplicate a venue")
		m.s.cash = 500000
		st.action("manager")
		test.check(not st.selected().manager,"A cheap empty stage-one shell cannot immediately farm manager income")
	m.s.day = 14
	var sale: Dictionary = st.lease_quote(1)
	test.check(sale.price==27000 and sale.discount==3000 and not st.lease_sale(0),"Retiring-owner offer visibly discounts only the advertised category")
	m.s.day = 15
	test.check(st.purchase_cost(1)==30000,"Offer ends at the day boundary without changing paid ownership")
	m.s.day = 28
	test.check(st.lease_sale(0) and not st.lease_sale(1),"Fortnightly offers rotate through venue types")
	m.save_game()
	var loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.s.cash==m.s.cash and loaded.s.street.bars==m.s.street.bars,"Existing cash, venues and stock survive the label/quote change with no refund")
	test.check(loaded.street.purchase_cost(0)==st.purchase_cost(0),"Sale price and repeat count survive reload without reward state")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.start_new_game()
	app.model.s.street.chapter = 1
	app.model.s.rep = 100
	app.model.s.cash = 100000
	app.change_tab(3)
	var button = app.column.find_child("Lease_1",true,false)
	test.check(button!=null and not button.disabled and button.text.contains("Hostess bar") and button.text.contains("24,000"),"Empire presents the named hostess lease and real current price")
	app.model.s.cash = 1
	app.update_lease_controls()
	test.check(button.disabled,"Open Empire disables a lease when cash drops")
	app.model.s.day = 14
	app.model.s.cash = 100000
	app.update_lease_controls()
	test.check(not button.disabled and button.text.contains("21,600"),"Open Empire refreshes affordability and the current sale quote without reopening")
	app.model.s.day = 15
	app.update_lease_controls()
	if button: button.pressed.emit()
	test.check(app.model.street.selected().type==1 and app.model.s.cash==76000-app.model.street.opening_reserve(1),"Lease button purchases through the authoritative quote")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
