extends SceneTree

# Run with an isolated XDG_DATA_HOME; never preview against a personal save.
const Campaign = preload("res://scripts/campaign.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")
var filter := OS.get_environment("PATTAYA_PREVIEW_FILTER")

func _initialize() -> void:
	call_deferred("run")

func find_text(node: Node, text: String) -> Control:
	if (node is Label or node is Button) and node.text.begins_with(text): return node
	for child in node.get_children():
		var found := find_text(child,text)
		if found: return found
	return null

func capture(app: Control, name_text: String, scroll_to: String = "") -> void:
	if not filter.is_empty() and not name_text.match(filter): return
	var targets := {"Train Bee":"Upgrade_audience_0","Cycle seating":"Upgrade_seating","Cycle music":"Upgrade_music","Regulars Club":"Upgrade_club","Better sound system":"Upgrade_music","Train Bartender":"Upgrade_training_0","YOUR ACTION UPGRADES":"Upgrade_pouring","SUPPLIER AGREEMENT":"Upgrade_supplier","MANAGEMENT":"Upgrade_manager"}
	var upgrade_target: String = targets.get(scroll_to,"")
	var was_open: bool = app.upgrades_open
	var ready_only: bool = app.upgrades_ready_only
	var section: String = app.service_section
	var was_fridge: bool = app.fridge_open
	if app.tab==0 and upgrade_target.is_empty():
		if scroll_to in ["TEAM & PAYROLL","FRONTAGE PROMOTER","Hire Gabby","Rehire Gabby","+฿5 tip"] or scroll_to.begins_with("HOST") or name_text.begins_with("barfine-") and not scroll_to.is_empty(): app.service_section = "team"
		if scroll_to in ["PREP FOR OPENING","Heat"]: app.service_section = "hours"
		if scroll_to in ["YOUR PROFIT CYCLE","NIGHTLY TIPS","Show visit plans","Hide visit plans"]: app.service_section = "reports"
		if scroll_to.begins_with("Buy ") or name_text=="economy-drinks": app.fridge_open = true
	if not upgrade_target.is_empty():
		app.upgrades_open = true
		app.upgrades_ready_only = false
	app.render()
	await process_frame
	await process_frame
	if not upgrade_target.is_empty():
		var card := app.column.find_child(upgrade_target,true,false) as Control
		if card: app.scroll.ensure_control_visible(card)
		await process_frame
	elif not scroll_to.is_empty():
		var target_text := scroll_to.replace(" drinks"," House lager") if app.fridge_open and scroll_to.begins_with("Buy ") else scroll_to
		var help_target := "Explain Hire Nida · ฿1,200" if name_text=="promoter-hire-forecast" else "Explain Hire bartender · ฿1,200" if name_text=="service-team-help" else ""
		if not help_target.is_empty():
			for control in app.column.find_children("*","Button",true,false):
				if control.tooltip_text==help_target:
					control.pressed.emit()
					await create_timer(.22).timeout
					break
		var target := find_text(app.column,target_text)
		if target:
			if name_text.begins_with("hosted-") or name_text.begins_with("barfine-") or name_text.begins_with("lease-") or name_text.begins_with("cycle-") or name_text.begins_with("gabby-") or name_text.begins_with("club-") or name_text.begins_with("prices-") or name_text.begins_with("tips-") or name_text.begins_with("night-prep-") or name_text.begins_with("guidance-") or name_text.begins_with("promoter-") or name_text.begins_with("automation-") or name_text.begins_with("bulk-") or name_text.begins_with("party-") or name_text.begins_with("staff-ready-"): app.scroll.scroll_vertical = int(target.position.y)
			else: app.scroll.ensure_control_visible(target)
			if name_text=="gabby-hire": app.scroll.scroll_vertical = maxi(0,app.scroll.scroll_vertical-100)
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(output.path_join(name_text+".png"))
	app.upgrades_open = was_open
	app.upgrades_ready_only = ready_only
	app.close_service_help()
	app.service_section = section
	app.fridge_open = was_fridge

func run() -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Set PATTAYA_PREVIEW_DIR and use a graphical display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.muted = true
	app.music.stop()
	app.start_new_game()
	app.model = Campaign.new(72)
	await capture(app,"opening")
	app.model.s.street.served = 10
	app.model.street.selected().regulars = 1
	app.model.s.cash = 4900
	app.model.s.street.minute = 840
	app.model.street.supplier_deal_tick()
	app.open_supplier_special()
	await capture(app,"supplier-special")
	app.close_supplier_special()
	app.model = Campaign.new(72)
	app.change_tab(0)
	await capture(app,"service-overview")
	await capture(app,"service-team","TEAM & PAYROLL")
	await capture(app,"service-team-help","TEAM & PAYROLL")
	await capture(app,"service-reports","YOUR PROFIT CYCLE")
	app.model.s.street.minute = 60
	await capture(app,"service-closed")
	app.model.s.street.minute = 720
	app.close_drawer()
	app.show_tutorial_hint = false
	app.model.s.street.chapter = 1
	app.model.s.rep = 100
	app.model.s.cash = 100000
	app.change_tab(3)
	await capture(app,"lease-first","Lease Beer bar")
	await capture(app,"lease-hostess","Lease Hostess bar")
	await capture(app,"lease-gogo","Lease Gogo bar")
	app.model.street.action("buy",1)
	app.change_tab(0)
	await capture(app,"lease-hostess-owned")
	app.change_tab(3)
	app.model.street.action("buy",0)
	app.model.s.cash = 1000
	await capture(app,"lease-repeat-shortfall","Lease Beer bar")
	app.model.s.day = 14
	await capture(app,"lease-retirement-offer","Lease Hostess bar")
	app.change_tab(0)

	var hosted_fixtures = load("res://tests/hosted_drinks_check.gd").new()
	var company_fixtures = load("res://tests/bar_fine_check.gd").new()
	app.model = company_fixtures.fixture(3)
	app.drawer_open = false
	app.show_tutorial_hint = false
	var toast_guest: Dictionary = hosted_fixtures.guest(app.model)
	await capture(app,"hosted-match")
	app.model.street.action("host_drink",1)
	await capture(app,"hosted-waiting")
	app.model.street.action("serve")
	await capture(app,"hosted-cheers")
	app.model.street.advance(20)
	for i in [0,2]:
		hosted_fixtures.guest(app.model,app.StreetContent.HOST_TOPICS[int(app.model.street.selected().team[i].host)])
		app.model.street.action("host_drink",i)
		app.model.street.economy.serve(app.model.street.selected())
	app.model.street.advance(20)
	await capture(app,"hosted-buzz")
	app.open_service_section("team")
	await capture(app,"hosted-service","GOOD COMPANY")
	app.model.street.action("train_host",1)
	app.model.street.action("auto_host_drinks")
	await capture(app,"hosted-upgraded","GOOD COMPANY")
	app.drawer_open = false
	app.model.street.selected().open = false
	await capture(app,"hosted-closed")
	app.model = Campaign.new(72)
	var barfine_fixtures = load("res://tests/bar_fine_check.gd").new()
	app.model = barfine_fixtures.fixture()
	app.show_tutorial_hint = false
	app.drawer_open = false
	barfine_fixtures.request(app.model)
	await capture(app,"barfine-ready")
	app.model.street.action("bar_fine",0)
	await capture(app,"barfine-accepted")
	app.model.street.advance(15)
	await capture(app,"barfine-away")
	app.model.street.advance(15)
	await capture(app,"barfine-returned")
	app.drawer_open = true
	await capture(app,"barfine-service","BAR FINES")
	await capture(app,"barfine-upgrades","Train Bee")
	app.model.street.action("train_host",0)
	app.model.street.action("auto_bar_fine")
	app.drawer_open = false
	barfine_fixtures.request(app.model)
	app.model.street.tick(1)
	await capture(app,"barfine-auto")
	app.model = barfine_fixtures.fixture(3)
	for i in 3: app.model.street.action("hire",1)
	barfine_fixtures.request(app.model)
	await capture(app,"barfine-full-roster")
	app.model.street.selected().open = false
	await capture(app,"barfine-closed")
	app.model = Campaign.new(72)
	var wrong_stock: Dictionary = app.model.street.selected()
	wrong_stock.stock = 30
	for guest in wrong_stock.customers:
		guest.drink = 2
		guest.lager_quote = 0
	app.open_fridge()
	await capture(app,"fridge-wrong-stock")
	app.change_tab(0)
	app.model = Campaign.new(72)
	app.show_tutorial_hint = false
	app.drawer_open = true
	app.model = Campaign.new(72)
	app.model.s.cash = 10000
	var cycle_bar: Dictionary = app.model.street.selected()
	cycle_bar.equipment.seating = 3
	await capture(app,"cycle-stage-one-lock","Cycle seating")
	cycle_bar.stage = 2
	await capture(app,"cycle-stage-two-seating","Cycle seating")
	cycle_bar.equipment.music = 2
	await capture(app,"cycle-stage-two-music-lock","Cycle music")
	app.visit_plans_open = true
	app.model.street.economy.serve(cycle_bar)
	await capture(app,"cycle-visit-plans","Hide visit plans")
	await capture(app,"cycle-profit","YOUR PROFIT CYCLE")
	app.drawer_open = false
	cycle_bar.stage = 3
	cycle_bar.equipment.seating = 7
	cycle_bar.equipment.pool = 2
	cycle_bar.equipment.comfort = 1
	for i in 40: app.model.street.economy.admit(cycle_bar)
	app.model.street.economy.pool_tick(cycle_bar)
	await capture(app,"cycle-full-furnished")
	cycle_bar.equipment.pool = 0
	cycle_bar.equipment.comfort = 0
	cycle_bar.games.clear()
	for i in 3: app.model.street.economy.admit(cycle_bar)
	await capture(app,"cycle-full-34")
	app.model = Campaign.new(72)
	cycle_bar = app.model.street.selected()
	cycle_bar.stage = 3
	cycle_bar.equipment.pool = 1
	cycle_bar.equipment.music = 4
	app.model.street.economy.clear_visits(cycle_bar)
	app.model.s.street.pass_credit = -1000000
	for i in 2:
		app.model.street.economy.admit(cycle_bar)
		cycle_bar.customers.back().planned_rounds = 1
		cycle_bar.customers.back().pool = true
	app.model.street.economy.pool_tick(cycle_bar)
	app.model.street.economy.serve(cycle_bar,2)
	app.model.street.tick(11)
	app.drawer_open = true
	await capture(app,"cycle-finishing-pool","Hide visit plans")
	app.visit_plans_open = false
	app.model = Campaign.new(72)
	app.model.s.cash = 10000
	await capture(app,"gabby-hire","Hire Gabby")
	app.model.street.action("hire_gabby")
	await capture(app,"gabby-roster","+฿5 tip")
	app.drawer_open = false
	for kind in 3:
		app.model.street.selected().type = kind
		await capture(app,"gabby-venue-"+str(kind))
	app.model.street.selected().type = 0
	app.model.street.economy.staff_service(app.model.street.selected())
	await capture(app,"gabby-serving")
	app.drawer_open = true
	await capture(app,"gabby-tips","+฿5 tip")
	app.model.street.selected().team[0].on = false
	app.drawer_open = false
	await capture(app,"gabby-off-duty")
	app.model.street.selected().team[0].contract_left = 0
	app.drawer_open = true
	await capture(app,"gabby-renewal","Rehire Gabby")
	app.model = Campaign.new(72)
	app.model.s.day = 8
	app.model.s.rep = 100
	app.model.s.cash = 2611
	var club_bar: Dictionary = app.model.street.selected()
	club_bar.stage = 2
	club_bar.regulars = 40
	club_bar.supplier_level = 4
	app.upgrades_open = true
	await capture(app,"club-day-eight","Regulars Club")
	app.model.street.action("regulars_club")
	app.model.street.action("regulars_club")
	await capture(app,"club-next-level","Regulars Club")
	app.model.s.cash = 5000
	app.model.street.action("equipment",8)
	app.model.street.action("hire",0)
	club_bar.team[0].training = 2
	await capture(app,"club-music","Better sound system")
	await capture(app,"club-training","Train Bartender")
	app.upgrades_open = false
	for kind in 3:
		app.model = Campaign.new(72)
		app.model.street.selected().type = kind
		app.model.street.selected().customers.clear()
		app.model.street.economy.admit(app.model.street.selected())
		await capture(app,"prices-"+str(kind),"Standard drink")
	app.model = Campaign.new(72)
	await capture(app,"economy-opening")
	app.model.street.selected().stock = 0
	app.open_fridge()
	await capture(app,"fridge-stockout")
	app.model.street.announce(1)
	app.model.street.start_event()
	await capture(app,"fridge-visitors","Rum & cola")
	app.model = Campaign.new(72)
	app.model.street.action("promotion",1)
	await capture(app,"fridge-happy-hour","Rum & cola")
	app.change_tab(0)
	app.model = Campaign.new(72)
	var start_cash: int = app.model.s.cash
	app.model.s.cash = 1800
	await capture(app,"upgrades-badge")
	app.upgrades_open = true
	await capture(app,"upgrades-ready")
	app.upgrades_ready_only = false
	await capture(app,"upgrades-all")
	app.model.s.cash = start_cash
	await capture(app,"upgrades-locked")
	app.upgrades_open = false
	app.upgrades_ready_only = true
	app.model.street.action("mixed_drinks")
	await capture(app,"economy-drinks")
	await capture(app,"actions-ready")
	app.model.street.action("serve")
	app.model.street.action("welcome")
	app.model.street.advance(5.25)
	await capture(app,"actions-refilling")
	app.model.street.advance(5)
	app.model.street.selected().customers[1].wait = 40
	await capture(app,"actions-chat-ready")
	app.model.street.action("chat")
	app.drawer_open = false
	await capture(app,"actions-chat-feedback")
	app.drawer_open = true
	await capture(app,"actions-upgrades","YOUR ACTION UPGRADES")
	app.model.s.cash = 250000
	for i in 3:
		app.model.street.action("action_upgrade",0)
		app.model.street.action("action_upgrade",1)
	await capture(app,"actions-max","YOUR ACTION UPGRADES")
	app.model.street.advance(20)
	app.model.street.selected().stock = 0
	await capture(app,"actions-stockout")
	app.model.street.action("open")
	await capture(app,"actions-closed")
	app.model = Campaign.new(72)

	app.drawer_open = false
	await capture(app,"staff-ready-unhired")
	# Full roster, mixed availability and the shared bonus jar, without new art.
	var empty_model = app.model
	app.model = Campaign.new(72)
	app.model.s.cash = 100000
	var hud_bar: Dictionary = app.model.street.selected()
	hud_bar.stage = 3
	app.model.street.action("hire_gabby")
	for i in 5: app.model.street.action("hire",0)
	hud_bar.team[0].training = 6
	app.model.street.economy.staff_service(hud_bar)
	app.model.s.street.tick_fraction = 0.5
	hud_bar.team[2].on = false
	hud_bar.team[3].contract_left = 0
	await capture(app,"staff-ready-full-roster")
	var hud_list = app.root_ui.find_child("BartenderList",true,false)
	if hud_list:
		hud_list.scroll_vertical = 200
		await process_frame
		await RenderingServer.frame_post_draw
		if filter.is_empty() or "staff-ready-full-roster".match(filter):
			get_root().get_texture().get_image().save_png(output.path_join("staff-ready-roster-scrolled.png"))
	hud_bar.open = false
	await capture(app,"staff-ready-venue-closed")
	app.model = empty_model
	app.model.s.cash = 10000
	app.model.street.action("hire",0)
	await capture(app,"staff-ready-waiting-order")
	app.model.street.tick(1)
	await capture(app,"staff-ready-served")
	app.model.street.tick(10)
	await capture(app,"staff-ready-cooldown")
	app.model.street.selected().customers.clear()
	app.model.s.street.pass_credit = -1000000
	app.model.street.tick(30)
	await capture(app,"staff-ready-quiet")
	app.model.street.selected().stock = 0
	await capture(app,"staff-ready-stockout")
	app.model.street.action("rota",0)
	await capture(app,"staff-ready-off-duty")
	app.model.street.economy.advance_contracts(14400)
	await capture(app,"staff-ready-expired")
	app.drawer_open = true
	await capture(app,"staff-ready-price","YOUR ACTION UPGRADES")
	app.model = Campaign.new(72)
	app.model.s.cash = 10000
	app.model.street.action("hire",0)
	app.model.street.action("hire",3)
	app.model.street.action("auto_serve")
	app.model.street.economy.advance_contracts(14400)
	app.model.s.cash = 1200
	await capture(app,"staff-ready-nida-shortfall","FRONTAGE PROMOTER")
	app.model.s.cash = 2000
	await capture(app,"staff-ready-nida-renew","FRONTAGE PROMOTER")
	app.model.street.action("rehire",1)
	await capture(app,"staff-ready-nida-renewed","FRONTAGE PROMOTER")
	app.model.s.cash = 10000
	app.model.street.action("rehire",0)
	app.model.street.selected().customers.clear()
	app.model.street.economy.admit(app.model.street.selected())
	await capture(app,"staff-ready-relief","YOUR ACTION UPGRADES")
	app.model = Campaign.new(72)
	app.drawer_open = true
	await capture(app,"guidance-opening","ANONG'S NEXT STEP")
	app.model.s.street.served = 10
	app.model.street.selected().regulars = 5
	app.model.street.selected().happy = 28
	app.model.street.selected().healthy = 4
	await capture(app,"guidance-renovation","ANONG'S NEXT STEP")
	app.model.s.cash = 7000
	app.model.street.action("hire",0)
	app.model.street.action("restock")
	app.model.street.selected().stage = 2
	app.model.street.selected().healthy = 8
	app.model.s.street.events_survived = 1
	await capture(app,"guidance-manager","ANONG'S NEXT STEP")
	app.model.s.street.chapter = 4
	await capture(app,"guidance-festival","ANONG'S NEXT STEP")
	app.model = Campaign.new(72)
	app.drawer_open = false
	app.model.street.selected().dirt = 80
	app.model.s.street.minute = 59
	app.model.street.tick(1)
	await capture(app,"night-prep-countdown")
	app.drawer_open = true
	app.model.street.tick(14)
	await capture(app,"night-prep-last-second","PREP FOR OPENING")
	app.model.street.action("stay")
	app.model.street.tick(1)
	await capture(app,"night-prep-cancelled","PREP FOR OPENING")
	app.model.street.action("skip")
	app.drawer_open = false
	await capture(app,"night-prep-noon")
	app.model = Campaign.new(72)
	app.model.s.cash = 39
	app.model.s.street.minute = 1045
	app.model.street.selected().stock = 0
	app.drawer_open = true
	await capture(app,"tips-stockout","Buy 6 drinks")
	app.model.street.action("emergency_stock")
	await capture(app,"tips-recovery","Buy 6 drinks")
	app.model.street.economy.serve(app.model.street.selected(),2)
	await capture(app,"tips-pending","NIGHTLY TIPS")
	app.model.s.day = 2
	app.model.s.street.minute = 59
	app.model.street.tick(1)
	app.drawer_open = false
	await capture(app,"tips-closing")
	app.drawer_open = true
	await capture(app,"tips-paid","PREP FOR OPENING")
	app.model = Campaign.new(72)
	app.model.s.day = 6
	app.drawer_open = false
	await capture(app,"party-tomorrow-scene")
	app.tab = 1
	app.drawer_open = true
	await capture(app,"party-countdown")
	app.model.s.day = 7
	app.model.s.cash = 10000
	app.model.street.action("equipment",2)
	app.model.street.action("equipment",8)
	app.model.street.action("hire",0)
	app.model.street.celebration_tick()
	app.drawer_open = false
	await capture(app,"party-live-scene")
	app.drawer_open = true
	await capture(app,"party-live-panel")
	for second in 180:
		app.model.street.action("serve")
		if app.model.street.selected().stock<12: app.model.street.action("stock")
		app.model.street.tick(1)
	await capture(app,"party-trading","PARTY TRADING")
	app.model.s.day = 8
	app.model.s.street.minute = 60
	app.model.street.celebration_tick()
	app.model.street.reconcile_closures()
	await capture(app,"party-finished","PARTY TRADING")
	app.model.s.day = 14
	app.model.s.street.minute = 720
	app.model.street.celebration_tick()
	await capture(app,"party-next-week")
	app.model = Campaign.new(72)
	app.tab = 0
	app.model.s.cash = 10000
	await capture(app,"bulk-hiring","TEAM & PAYROLL")
	app.model.street.action("hire",3)
	await capture(app,"bulk-welcome","YOUR ACTION UPGRADES")
	await capture(app,"bulk-fridge","Better fridge")
	app.model.street.action("restock")
	await capture(app,"bulk-level-one","SUPPLIER AGREEMENT")
	app.model.street.action("restock")
	app.model.street.selected().stock = 19
	await capture(app,"bulk-no-space","Buy 12 drinks")
	app.model.street.selected().stock = 18
	app.model.s.cash = 431
	await capture(app,"bulk-no-cash","Buy 12 drinks")
	app.model.s.cash = 432
	await capture(app,"bulk-ready","Buy 12 drinks")
	app.model.street.action("stock")
	await capture(app,"bulk-delivered","Buy 12 drinks")
	app.model = Campaign.new(72)
	app.model.s.cash = 50000
	app.model.street.action("hire",0)
	await capture(app,"staff-base","Train Bartender 1")
	app.model.street.action("train_staff",0)
	await capture(app,"staff-trained","Train Bartender 1")
	app.model.street.economy.advance_contracts(14400)
	await capture(app,"staff-expired","Rehire Bartender 1")
	app.drawer_open = false
	await capture(app,"staff-expired-scene")
	app.model.street.action("rehire",0)
	app.drawer_open = true
	await capture(app,"staff-rehired","Train Bartender 1")
	app.model.s.cash = 250000
	var first: Dictionary = app.model.street.selected()
	app.drawer_open = false
	await capture(app,"fan-before-purchase")
	app.model.street.action("equipment",1)
	await capture(app,"fan-after-purchase")
	await capture(app,"tv-before-purchase")
	app.model.street.action("equipment",5)
	await capture(app,"tv-after-purchase")
	first.customers[0].wait = app.model.street.economy.patience(first,first.customers[0])-10
	await capture(app,"tv-orders-urgent")
	app.model.street.action("chat")
	await capture(app,"tv-orders-reassured")
	app.model.street.action("serve")
	await capture(app,"tv-orders-served")
	app.drawer_open = true
	first.equipment.pool = 1
	first.equipment.seating = 1
	for guest in first.customers: guest.pool = true
	app.model.street.economy.pool_tick(first)
	await capture(app,"economy-pool","POOL")
	app.model.street.action("promotion",0)
	app.tab = 1
	await capture(app,"economy-free-pool","Venue promotions")
	for i in 120:
		app.model.street.action("serve")
		app.model.street.tick(1)
	await capture(app,"economy-promotion-report","LAST PROMOTION")
	app.tab = 0
	await capture(app,"economy-milestones","LAST SHIFT")
	first.stage = 2
	first.equipment.pool = 2
	first.customers.clear()
	first.games.clear()
	for i in 4:
		app.model.street.economy.admit(first)
		first.customers.back().pool = true
	app.model.street.economy.pool_tick(first)
	first.games[0].remaining = 1
	app.model.street.economy.pool_tick(first)
	app.drawer_open = false
	await capture(app,"pool-two-tables")
	first.equipment.pool = 0
	first.games.clear()
	for guest in first.customers: guest.playing = false
	await capture(app,"pool-not-open")
	app.drawer_open = true
	first.open = false
	app.model.s.cash = 0
	await capture(app,"economy-recovery")
	first.open = true
	app.model.s.cash = 250000
	app.model.s.rep = 80
	app.model.s.street.chapter = 4
	app.show_tutorial_hint = false
	for kind in 3:
		if kind > 0: app.model.street.action("buy",kind)
		for stage in range(1,4):
			var bar: Dictionary = app.model.street.selected()
			bar.stage = stage
			bar.crew = stage*2
			bar.team.clear()
			for i in bar.crew: bar.team.append({"role":kind if i%2 else 0,"on":true,"host":i if kind==1 else -1})
			if kind==0 and stage>1: bar.equipment.pool = 1
			bar.customers.clear()
			for i in stage*2: app.model.street.economy.admit(bar)
			bar.manager = stage > 1
			bar.restock = true
			app.model.s.street.seconds = 60
			app.drawer_open = false
			await capture(app,"type-%d-stage-%d" % [kind,stage])
			bar.equipment.screen = 0
			await capture(app,"tv-type-%d-stage-%d-unowned" % [kind,stage])
			app.model.street.action("equipment",5)
			await capture(app,"tv-type-%d-stage-%d-owned" % [kind,stage])
	app.drawer_open = true
	app.tab = 3
	await capture(app,"empire")
	app.tab = 1
	app.model.street.announce(9)
	await capture(app,"festival-warning")
	app.model.street.start_event()
	app.model.start_street_boss()
	await capture(app,"festival-boss")
	app.model.finish_godzilla(true)
	app.tab = 0
	await capture(app,"festival-complete")
	# Promoter controls and compact layout use the real paid actions.
	app.model = Campaign.new(72)
	app.model.s.cash = 50000
	app.drawer_open = false
	app.tab = 0
	app.message = ""
	var promo_bar: Dictionary = app.model.street.selected()
	await capture(app,"promoter-before-hire")
	app.drawer_open = true
	await capture(app,"promoter-hire-forecast","Hire Nida")
	app.drawer_open = false
	app.model.street.action("hire",3)
	await capture(app,"promoter-working")
	app.drawer_open = true
	await capture(app,"promoter-contract","FRONTAGE PROMOTER")
	app.model.street.action("rota",0)
	app.drawer_open = false
	await capture(app,"promoter-off-duty")
	app.model.street.action("rota",0)
	for i in 3: app.model.street.action("equipment",4)
	app.model.street.action("equipment",1)
	app.model.street.action("equipment",3)
	promo_bar.customers.clear()
	await capture(app,"promoter-compact-empty")
	while promo_bar.customers.size()<12: app.model.street.economy.admit(promo_bar)
	for guest in promo_bar.customers: guest.wait = 20
	await capture(app,"promoter-twelve-guests")
	promo_bar.stage = 2
	app.model.street.action("train_audience",0)
	app.drawer_open = true
	await capture(app,"promoter-trained","FRONTAGE PROMOTER")
	promo_bar.team[0].contract_left = 0
	promo_bar.team[0].on = false
	await capture(app,"promoter-expired","Rehire Nida")
	app.model.street.action("rehire",0)
	app.drawer_open = false
	for kind in 3:
		for stage in range(1,4):
			promo_bar.type = kind
			promo_bar.stage = stage
			promo_bar.equipment.pool = 1 if kind==0 else 0
			promo_bar.equipment.seating = 3 if kind==0 else 2
			promo_bar.customers.clear()
			while promo_bar.customers.size()<mini(12,app.model.street.economy.seats(promo_bar)): app.model.street.economy.admit(promo_bar)
			await capture(app,"promoter-type-%d-stage-%d" % [kind,stage])
	promo_bar.open = false
	await capture(app,"promoter-closed")
	# Purchased automation, supply and management use model operations.
	app.model = Campaign.new(72)
	app.model.s.cash = 300000
	app.drawer_open = false
	app.tab = 0
	var automated: Dictionary = app.model.street.selected()
	await capture(app,"automation-before")
	app.model.street.action("equipment",8)
	app.model.street.action("hire",3)
	await capture(app,"automation-music-nida")
	app.model.street.action("serve")
	app.model.street.action("auto_serve")
	app.model.street.advance(4)
	app.drawer_open = true
	await capture(app,"automation-controls","YOUR ACTION UPGRADES")
	automated.stage = 2
	for i in 4: app.model.street.action("action_upgrade",0)
	await capture(app,"automation-two-second","YOUR ACTION UPGRADES")
	app.model.street.action("hire",0)
	for i in 4: app.model.street.action("restock")
	automated.healthy = 8
	app.model.street.action("manager")
	await capture(app,"automation-supplier-manager","SUPPLIER AGREEMENT")
	app.drawer_open = false
	automated.customers.clear()
	app.model.s.street.pass_credit = -10000000
	app.model.street.advance(15)
	await capture(app,"automation-manager-income")
	automated.stage = 3
	app.model.street.action("restock")
	app.model.street.action("manager")
	app.model.street.action("manager")
	app.drawer_open = true
	await capture(app,"automation-max-tiers","SUPPLIER AGREEMENT")
	app.drawer_open = false
	app.model.street.action("open")
	app.model.street.advance(10)
	await capture(app,"automation-closed")
	# Clock and prep scenes use the same live actions/state as the game.
	app.model = Campaign.new(72)
	app.model.s.cash = 10000
	app.tab = 0
	app.drawer_open = true
	app.message = ""
	var clock_bar: Dictionary = app.model.street.selected()
	clock_bar.manager = true
	clock_bar.team = [{"role":0,"on":true,"host":-1}]
	clock_bar.crew = 1
	clock_bar.dirt = 65
	for kind in 3:
		clock_bar.type = kind
		app.model.s.street.minute = int(app.model.street.C.PEAK_HOURS[kind].start)
		await capture(app,"clock-peak-%d" % kind)
	clock_bar.type = 0
	app.model.s.day = 1234
	await capture(app,"clock-day-counter")
	app.model.s.day = 2
	app.model.s.street.minute = 30
	await capture(app,"clock-warning")
	app.model.street.action("late")
	app.model.s.street.minute = 90
	await capture(app,"clock-late")
	clock_bar.shift.open_seconds = 60
	app.model.s.street.seconds = 60
	app.model.street.raid(clock_bar)
	await capture(app,"clock-raid")
	app.drawer_open = false
	await capture(app,"clock-raid-scene")
	app.drawer_open = true
	await capture(app,"clock-prep","PREP FOR OPENING")
	for i in 15: app.model.street.tick(1)
	await capture(app,"clock-clean","PREP FOR OPENING")
	app.model.street.action("skip")
	await capture(app,"clock-noon")
	for rival in 3:
		var duel = load("res://scripts/fight.gd").new()
		duel.rival_index = rival
		duel.size = Vector2(960,540)
		root.add_child(duel)
		duel.set_physics_process(false)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("fight-%d.png" % rival))
		duel.queue_free()
		await process_frame
	app.queue_free()
	await process_frame
	print("Street previews: "+output)
	quit()
