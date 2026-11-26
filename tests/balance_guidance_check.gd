extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	var bar: Dictionary = st.selected()
	var e = st.economy
	var before := JSON.stringify(m.s)
	test.check(st.next_goal().title.contains("first ten"),"Opening guidance starts with real service")
	test.check(JSON.stringify(m.s)==before,"Reading guidance never rewards, advances time, rolls RNG or saves")
	m.s.street.served = 10
	test.check(st.next_goal().title=="Earn your first regular","First regular gives the opening a small story objective")
	bar.regulars = 1
	test.check(st.next_goal().detail.contains("70 happy") and st.next_goal().focus=="Upgrade ·","Renovation guidance uses actual local milestones and links to its control")
	bar.stage = 2
	test.check(st.next_goal().tab==1,"Reopening guidance sends player to Events")
	m.s.street.events_survived = 1
	test.check(st.next_goal().focus=="TEAM & PAYROLL","Management guidance explains the bartender prerequisite")
	m.s.cash = 50000
	st.action("hire",0)
	var person: Dictionary = bar.team[0]
	e.staff_service(bar)
	var deadline: float = person.service_ready
	var money: int = m.s.cash
	st.action("train_staff",0)
	test.check(m.s.cash==money-400 and e.service_seconds(person)==20 and person.service_ready==deadline,"First training costs 400, improves future service and keeps current recovery")
	st.action("train_staff",0)
	test.check(m.s.cash==money-1200 and e.service_seconds(person)==15,"Full bartender training costs 1200 in total")
	test.check(st.next_goal().focus=="SUPPLIER AGREEMENT","Guidance finds delivery automation before management")
	st.action("restock")
	bar.healthy = 8
	test.check(st.next_goal().focus=="MANAGEMENT" and st.next_goal().detail.contains("฿8000"),"Manager target quotes the current price")
	var reserve: int = (e.operating_rate(bar)+12)*2
	m.s.cash = 8000+reserve-1
	st.action("manager")
	test.check(not bar.manager,"Cheaper manager still requires the operating reserve")
	m.s.cash += 1
	st.action("manager")
	test.check(bar.manager and m.s.cash==reserve and m.s.street.chapter==1,"Exact manager threshold unlocks existing chapter through the shared rules")
	test.check(st.next_goal().tab==3 and st.next_goal().detail.contains("Reputation"),"Expansion guidance shows lease reserve and reputation rather than granting another crowd")
	m.save_game()
	var loaded = Campaign.new(8)
	test.check(loaded.load_game() and loaded.s.cash==m.s.cash and loaded.street.selected().team[0].training==2 and loaded.street.selected().manager,"Existing save schema retains purchased training/management with no price-change refund")
	for kind in 3:
		bar.type = kind
		bar.stage = 2
		bar.happy = 449
		bar.regulars = 70
		bar.healthy = 40
		m.s.cash = 1000000
		test.check(not e.upgrade_reason(bar).is_empty(),"Wealth cannot bypass the revised local happy-visit gate")
		bar.happy = 450
		bar.regulars = 69
		test.check(not e.upgrade_reason(bar).is_empty(),"Stage three still needs seventy regulars")
		bar.regulars = 70
		bar.healthy = 39
		test.check(not e.upgrade_reason(bar).is_empty(),"Stage three still needs forty healthy shifts")
		bar.healthy = 40
		money = m.s.cash
		st.action("upgrade")
		test.check(bar.stage==3 and m.s.cash==money-C.RENOVATIONS[kind][1],"Final renovation charges its venue-specific price after local gates")
	for chapter in range(2,6):
		m.s.street.chapter = chapter
		before = JSON.stringify(m.s)
		var view: Dictionary = st.next_goal()
		test.check(not view.title.is_empty() and JSON.stringify(m.s)==before,"Later story guidance remains read-only")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.muted = true
	app.start_new_game()
	app.show_tutorial_hint = false
	app.change_tab(0)
	var before := JSON.stringify(app.model.s)
	test.use_button(app,"Go to Serve  ›")
	await test.process_frame
	await test.process_frame
	test.check(not app.drawer_open and JSON.stringify(app.model.s)==before,"Opening next-step reveals serving controls without serving or simulating")
	app.model.street.selected().stock = 0
	app.change_tab(0)
	before = JSON.stringify(app.model.s)
	test.use_button(app,"Open Fridge  ›")
	await test.process_frame
	await test.process_frame
	test.check(app.fridge_open and JSON.stringify(app.model.s)==before,"Stockout guidance opens the fridge without buying")
	app.model.s.street.bars[0].stage = 2
	app.model.s.street.served = 10
	app.model.s.street.bars[0].regulars = 10
	app.change_tab(0)
	test.use_button(app,"Open Events  ›")
	test.check(app.tab==1 and app.drawer_open,"Reopening next-step button opens Events")
	# A rich street still has local gates; make them readable without opening help.
	app.model.s.cash = 659000
	app.model.s.rep = 100
	app.model.s.street.chapter = 2
	app.model.street.action("buy",1)
	var bar: Dictionary = app.model.street.selected()
	var eco = app.model.street.economy
	bar.happy = 21
	bar.regulars = 4
	bar.healthy = 3
	app.model.s.street.bars[0].happy = 1000
	app.model.s.street.bars[0].regulars = 100
	app.model.s.street.bars[0].healthy = 100
	before = JSON.stringify(app.model.s)
	var rng_before: int = app.model.rng.state
	app.open_upgrades(true)
	var progress: Label = app.column.find_child("RenovationProgress",true,false)
	test.check(progress!=null and progress.text.contains("21/70") and progress.text.contains("4/10") and progress.text.contains("3/8") and progress.text.contains("Cash ready"),"Ready filter still shows the selected venue's unmet milestones despite a rich successful flagship")
	test.check(app.column.find_child("Upgrade_renovate",true,false)==null,"Ready-only cards still exclude unearned renovations")
	test.use_button(app,"View renovation  ›")
	await test.process_frame
	await test.process_frame
	var renovate: Button = app.column.find_child("Upgrade_renovate",true,false)
	var reason: Label = app.column.find_child("Upgrade_club_reason",true,false)
	test.check(renovate!=null and renovate.disabled and not app.upgrades_ready_only and reason!=null and reason.visible and reason.text.contains("stage 2"),"Renovation link reveals the disabled card; stage-locked club explains itself without a question-mark tap")
	test.check(JSON.stringify(app.model.s)==before and app.model.rng.state==rng_before,"Progress and renovation navigation cannot buy, simulate, reward or roll RNG")
	bar.happy = 69
	app.sync_upgrade_badge(true)
	for entry in app.live_labels:
		if is_instance_valid(entry[0]): entry[0].text = entry[1].call()
	progress = app.column.find_child("RenovationProgress",true,false)
	test.check(progress.text.contains("69/70"),"Milestones refresh even while the purchase remains locked")
	bar.happy = 70
	bar.regulars = 10
	bar.healthy = 8
	app.model.s.cash = eco.upgrade_required_cash(bar)-1
	app.sync_upgrade_badge(true)
	for entry in app.live_labels:
		if is_instance_valid(entry[0]): entry[0].text = entry[1].call()
	progress = app.column.find_child("RenovationProgress",true,false)
	renovate = app.column.find_child("Upgrade_renovate",true,false)
	test.check(progress.text.contains("Need ฿1 more") and renovate.disabled,"Cash progress includes the operating reserve, even when local milestones are complete")
	app.model.s.cash += 1
	app.sync_upgrade_badge(true)
	renovate = app.column.find_child("Upgrade_renovate",true,false)
	test.check(not renovate.disabled,"The renovation becomes purchasable at the exact unchanged gate")
	renovate.pressed.emit()
	test.check(bar.stage==2 and app.column.find_child("RenovationProgress",true,false).text.contains("70/450"),"Buying once advances to the stage-three local targets without granting visits")
	bar.stage = 3
	app.open_upgrades(false)
	test.check(app.column.find_child("RenovationProgress",true,false)==null,"Final-stage venues show no impossible fourth renovation")

	app.queue_free()
	await test.process_frame
	# This runner is invoked only inside tools/test.sh's isolated save directory.
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
