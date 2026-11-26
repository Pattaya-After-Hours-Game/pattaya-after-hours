extends SceneTree

const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/content.gd")
const Fight = preload("res://scripts/fight.gd")
const Updates = preload("res://scripts/windows_updates.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	check(C.GOOD.size() == 21 and C.BAD.size() == 30,"Full incident deck")
	var model = Campaign.new(413,true)
	for card in C.GOOD + C.BAD:
		var card_id: int = (C.GOOD + C.BAD).find(card)
		for option in range(2,card.size(),2):
			model = Campaign.new(413,true)
			model.s.cash = 20000
			model.start()
			model.s.card = card_id
			var effects: Dictionary = card[option+1]
			if not effects.has("fight"):
				var risk: Dictionary = model.response_risk(effects)
				check(risk.chance > 0 and risk.chance < 100 and risk.plan_changes != risk.setback_changes,"Distinct odds for " + card[option])
			var response: String = model.pick((option-2)/2)
			check(response.is_empty() and (model.s.phase == "fight" or model.s.night.wave == 1),"Incident option: " + card[0])
			if model.s.phase == "fight":
				model.finish_fight(false)
				check(model.s.staff[1].hurt > 0 and model.s.night.wave == 1,"Loss consequences")
	model = Campaign.new(72,true)
	check(model.booking(0,0).contains("Doesn't"),"Guide refuses")
	check(model.booking(2,2).contains("Confirmed"),"Interested guide accepts")
	model.s.event = 1
	check(model.start().is_empty(),"Start paid event")
	model.pick(0)
	check(model.save_game() == OK,"Write checkpoint")
	var restored = Campaign.new(713,true)
	check(restored.load_game() and restored.s.card == model.s.card and restored.rng.state == model.rng.state,"Checkpoint round-trip")
	model.pick(0)
	restored.pick(0)
	check(restored.s.night.guests == model.s.night.guests and restored.s.card == model.s.card
		and restored.s.night.results == model.s.night.results,"Deterministic reload, including decision results")
	check(restored.save_game() == OK,"Create backup")
	var corrupted := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	corrupted.store_string("truncated")
	corrupted.close()
	check(Campaign.new(0,true).load_game(),"Recover a valid save from backup")
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
	model = Campaign.new(291,true)
	var clean_days := 0
	var saw_week := false
	var saw_rush := false
	var saw_flood := false

	while model.s.phase != "end" and clean_days < 365:
		if model.s.stock < 85:
			model.action("buy")
			model.action("buy")
		for i in model.s.staff.size():
			var staff: Dictionary = model.s.staff[i]
			staff.work = staff.fatigue < 58 or (int(model.s.day) + i) % 3 != 0
		if int(model.s.day) % 12 == 0: model.action("paper")
		if model.s.condition < 34: model.action("repair")
		if model.s.staff[2].work: model.booking(2,0)
		model.start()
		check(model.s.phase == "incident","Started day %d" % model.s.day)
		while model.s.phase == "incident":
			saw_rush = saw_rush or model.s.card == 20
			saw_flood = saw_flood or model.s.card == 42
			if model.s.card == Campaign.FIGHT_CARD:
				model.pick(1)
				model.finish_fight(true)
			elif not model.pick(0).is_empty() and not model.pick(1).is_empty():
				model.fallback()
		check(model.s.phase == "report" and model.s.night.guests >= 0 and model.s.stock >= 0,"Closeout for day %d" % model.s.day)
		if model.s.day == 7:
			saw_week = model.s.last_week.nights == 7 and model.s.last_week.costs > 0
		clean_days += 1
		model.next_day()
	check(clean_days == 365 and model.s.phase == "plan" and model.s.day == 366,"Street continues beyond the first year")
	check(saw_week and saw_rush and saw_flood and model.s.wins > 0,"Weekly ledger and anchor incidents")
	load("res://tests/street_check.gd").new().run(self)
	load("res://tests/clock_check.gd").new().run(self)
	load("res://tests/night_prep_check.gd").new().run(self)
	load("res://tests/tips_check.gd").new().run(self)
	load("res://tests/drink_prices_check.gd").new().run(self)
	load("res://tests/regulars_club_check.gd").new().run(self)
	load("res://tests/profit_cycle_check.gd").new().run(self)
	load("res://tests/lease_check.gd").new().run(self)
	load("res://tests/action_check.gd").new().run(self)

	load("res://tests/staff_check.gd").new().run(self)
	load("res://tests/staff_ready_check.gd").new().run(self)
	load("res://tests/gabby_check.gd").new().run(self)
	load("res://tests/daisy_check.gd").new().run(self)
	load("res://tests/bar_fine_check.gd").new().run(self)
	load("res://tests/hosted_drinks_check.gd").new().run(self)
	load("res://tests/balance_guidance_check.gd").new().run(self)
	load("res://tests/promoter_check.gd").new().run(self)
	load("res://tests/automation_check.gd").new().run(self)
	load("res://tests/bulk_stock_check.gd").new().run(self)
	load("res://tests/celebration_check.gd").new().run(self)
	test_risk()
	test_windows_updates()
	load("res://tests/boot_menu_check.gd").new().run(self)
	await load("res://tests/action_check.gd").new().run_ui(self)
	await load("res://tests/tips_check.gd").new().run_ui(self)
	await load("res://tests/gabby_check.gd").new().run_ui(self)
	await load("res://tests/daisy_check.gd").new().run_ui(self)
	await load("res://tests/bar_fine_check.gd").new().run_ui(self)
	await load("res://tests/hosted_drinks_check.gd").new().run_ui(self)
	await load("res://tests/staff_ready_check.gd").new().run_ui(self)
	await load("res://tests/balance_guidance_check.gd").new().run_ui(self)
	await load("res://tests/regulars_club_check.gd").new().run_ui(self)
	await load("res://tests/profit_cycle_check.gd").new().run_ui(self)
	await load("res://tests/lease_check.gd").new().run_ui(self)
	await test_ui()
	load("res://tests/art_check.gd").new().run(self)
	load("res://tests/scene_check.gd").new().run(self)
	await load("res://tests/art_interaction_check.gd").new().run(self)
	var local_checks = load("res://tests/local_events_check.gd").new()
	local_checks.run(self)
	await local_checks.run_ui(self)
	await load("res://tests/drink_prices_check.gd").new().run_ui(self)
	if failures == 0:
		print("PASS · incident deck, endless year, street economy, chapters, migration, offline earnings, events, UI, arcade, tutorial, Godzilla, decision odds and Windows update checks")
	quit(1 if failures else 0)

func test_ui() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	use_button(app,"New Game")
	check(app.show_tutorial_hint,"New players see the tutorial hint")
	test_tuning(app)
	for stat in ["TILL","REPUTATION","HEAT","TIME"]:
		var button := find_button(app,stat)
		check(not button.tooltip_text.is_empty(),"Hover explains "+stat)
		use_button(app,stat)
		check(app.stat_tip_key==stat and app.stat_tip.visible,"Tapping opens the explanation for "+stat)
	var outside := InputEventScreenTouch.new()
	outside.position = Vector2(30,200)
	outside.pressed = true
	app._input(outside)
	check(app.stat_tip==null,"Touching outside a stat tip dismisses it")
	check(not find_button(app,"STOCK").tooltip_text.is_empty(),"Stock header still has a hover explanation")
	use_button(app,"STOCK")
	check(app.fridge_open and app.drawer_open and app.column.get_node_or_null("Drink_lager")!=null,"Tapping Stock opens the drink list")
	use_button(app,"Back")
	var bar: Dictionary = app.model.street.selected()
	var original_stock: int = bar.stock
	var original_cash: int = app.model.s.cash
	bar.stock = 0
	app.update_action_controls()
	use_button(app,"Restock fridge")
	check(app.fridge_open and bar.stock==0 and app.model.s.cash==original_cash and app.model.s.street.served==0,"Serve stockout opens the fridge without buying or selling")
	bar.stock = 30
	var original_customers: Array = bar.customers.duplicate(true)
	for customer in bar.customers:
		customer.drink = 2
		customer.lager_quote = 0
	app.update_action_controls()
	use_button(app,"Need Rum & cola")
	check(app.fridge_open and panel_has_text(app,"NEEDED NOW") and panel_has_text(app,"Return spare stock to free 6 slots."),"Wrong-stock shortcut highlights demand and explains how to make space")
	var demand_card: Control = app.column.get_node("Drink_rum")
	var house_card: Control = app.column.get_node("Drink_lager")
	check(demand_card.get_index()<house_card.get_index() and panel_has_text(app,"OTHER DRINKS") and bar.stock==30 and app.model.s.cash==original_cash,"The missing drink is separated from regular stock; opening the fridge is free")
	check(find_button(app,"Buy 6 · ฿114").disabled and demand_card.find_children("*","TextureRect",true,false).size()==1,"The needed drink has an icon and its purchase is blocked while the fridge is full")
	bar.stock = original_stock
	bar.customers = original_customers
	use_button(app,"Back")
	var initial_save := FileAccess.get_file_as_string(Campaign.SAVE)
	use_button(app,"Tutorial")
	check(FileAccess.get_file_as_string(Campaign.SAVE)==initial_save,"Opening a tutorial leaves the new campaign save untouched")
	use_button(app,"Exit")
	var opening_cash := int(app.model.s.cash)
	use_button(app,"Serve a drink")
	check(app.model.s.street.served == 1 and app.model.s.cash > opening_cash,"Main clicker button serves and earns")
	app.model.s.cash = 50000
	use_button(app,"Team")
	use_button(app,"Hire bartender · ฿1,200")
	app.model.street.tick(25)
	check(app.model.s.street.served == 2,"Hired staff serve without tapping")
	app.render()
	var staff_hud: Button = app.root_ui.find_child("Bartender0",true,false)
	check(staff_hud.tooltip_text.contains("1 drinks served"),"Top-right HUD reports real staff sales separately from owner taps")
	staff_hud.pressed.emit()
	check(app.tab==0 and app.drawer_open and app.service_section=="team","Staff indicator opens Team directly")
	app.model.street.announce(3)
	app.render()
	app.event_banner.pressed.emit()
	check(app.tab == 1,"The event banner opens preparation controls")
	use_button(app,"Raise stock & share pumps · ฿450")
	check(app.model.s.street.event.prepared,"Event preparation works through the UI")
	app.model.s.street.event = {}
	app.change_tab(0)
	use_button(app,"Team")
	use_button(app,"Train Bartender 1 · ฿400 · 20s")
	check(app.model.street.selected().team[0].training==1,"Individual training control works")
	app.model.street.economy.advance_contracts(14400)
	app.render()
	use_button(app,"Rehire Bartender 1 · ฿1,200")
	check(app.model.street.selected().team[0].training==1 and app.model.street.selected().team[0].on,"Rehire control retains training")
	use_button(app,"Hire Nida · ฿1,200")
	var nida: Dictionary = app.model.street.selected().team.back()
	nida.contract_left = 1
	nida.audience_training = 1
	app.model.s.cash = 1200
	app.render()
	var renewal_state: Array = app.street_ui_state()
	app._process(1.0)
	check(renewal_state!=app.street_ui_state(),"Contract expiry invalidates Service controls directly")
	check(find_button(app,"Rehire Nida · ฿1,200").disabled,"Nida renewal disables for insufficient cash including reserve")
	app.model.s.cash = 50000
	app._process(1.0)
	check(not find_button(app,"Rehire Nida · ฿1,200").disabled,"Earning the missing reserve enables renewal without reopening the drawer")
	use_button(app,"Rehire Nida · ฿1,200")
	check(nida.on and nida.contract_left>0 and nida.audience_training==1,"Nida renews through frontage UI after live expiry with training retained")
	for i in 5:
		app.change_tab(i)
		check(app.column.get_child_count() > 0,"Rendered tab %d" % i)
	app.walk_district()
	check(is_instance_valid(app.district),"Opened district")
	app.district.destination.emit(1)
	check(app.tab == 1 and app.district == null,"Visited Toybox")
	app.enter_fight(true)
	var f: Control = app.fight
	f.set_physics_process(false)
	f.fighters[0].x = 100.0
	f.fighters[1].x = 120.0
	check(f._attack(f.fighters[0],"jab"),"Jab starts")
	f._resolve(f.fighters[0],f.fighters[1],0.12)
	check(f.fighters[1].hp == 92 and f.fighters[0].meter > 0,"Jab hits in range")
	f.reset_round()
	f.fighters[0].x = 100.0
	f.fighters[1].x = 120.0
	f.fighters[1].guard = true
	f._attack(f.fighters[0],"kick")
	f._resolve(f.fighters[0],f.fighters[1],0.23)
	check(f.fighters[1].hp == 97,"Guard reduces damage")
	check(not f._attack(f.fighters[1],"super"),"Burst requires charge")
	var exit_touch := InputEventScreenTouch.new()
	exit_touch.position = f.exit_rect().get_center()
	exit_touch.pressed = true
	f._input(exit_touch)
	check(app.fight == null,"Touch exits sparring safely")
	app.begin()
	check(app.model.s.phase == "guided_choice","Opened guided service through UI")
	app.choose(0)
	check(app.model.s.phase == "guided","Guided choice resumes live service")
	app.model.street.tick(34)
	app.render()
	check(app.model.s.street.guided.wave == 1,"Next guided wave waits for the clock")

	var live_campaign = app.model
	var save_before := FileAccess.get_file_as_string(Campaign.SAVE)
	use_button(app,"Tutorial")
	check(app.model != live_campaign and app.model.s.phase == "plan","Tutorial opens its own practice shift")
	var practice_bar: Dictionary = app.model.street.selected()
	check(find_button(app,"Serve a drink").disabled,"Practice starts with a stock delivery")
	use_button(app,"Buy 6 drinks · ฿228")
	check(practice_bar.stock==18 and app.tutorial_step==1,"Practice delivery uses the live pack size")
	use_button(app,"Serve a drink")
	check(app.model.s.street.served==1 and practice_bar.stock==17 and find_button(app,"Serve a drink").disabled,"Practice serves a real order and starts the cooldown")
	use_button(app,"Welcome customers")
	var urgent: Dictionary = app.model.street.economy.chat_target(practice_bar)
	check(not urgent.is_empty() and app.tutorial_step==3,"Practice prepares a genuine urgent order")
	use_button(app,"Have a chat")
	check(urgent.get("chatted",false) and not app.model.street.economy.action_status(practice_bar,"welcome").enabled,"Practice Chat reassures the guest and shares Welcome's timer")
	use_button(app,"Hire bartender · ฿1,200")
	check(app.model.s.street.served>1 and app.tutorial_step==5,"The practice bartender serves automatically")
	use_button(app,"Advance to 1am")
	check(not app.model.street.any_trading() and practice_bar.last_tips.amount>0 and app.model.s.street.night_prep.remaining>0,"Practice closing counts tips and starts cleanup")
	use_button(app,"Finish tutorial")
	check(app.model == live_campaign and app.model.s.street.guided.wave == 1,"Tutorial restores the live shift")
	check(FileAccess.get_file_as_string(Campaign.SAVE) == save_before,"Practice made no changes to the live save")
	use_button(app,"Tutorial")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	app._unhandled_key_input(escape)
	check(app.model == live_campaign,"Esc exits a replay")
	test_godzilla(app)
	test_clock_ui(app)
	app.queue_free()
	await process_frame


func test_clock_ui(app: Control) -> void:
	app.model = Campaign.new(72)
	app.offline_notice = 0
	app.model.s.cash = 10000
	app.change_tab(0)
	var bar: Dictionary = app.model.street.selected()
	use_button(app,"Hours")
	use_button(app,"Stay open until 3am tonight")
	check(bar.late_open,"Nightly extension works through Service")
	app.model.s.street.minute = 120
	app.update_action_controls()
	check(not find_button(app,"Skip to open").visible,"Skip to open is hidden while a late venue is trading")
	app.model.s.street.minute = 59
	use_button(app,"Cancel late opening tonight")
	check(not bar.late_open,"Nightly extension can be cancelled through Service")
	bar.dirt = 80
	app.model.s.street.minute = 59
	app.model.street.tick(1)
	app.render()
	check(not app.action_controls[0][0].visible and not app.action_controls[1][0].visible,"The skip button replaces customer actions while the street is closed")
	check(panel_has_text(app,"PREP FOR OPENING") and find_button(app,"Skip to open").is_visible_in_tree(),"Skip to open is available during the closing countdown and outside the Hours panel")
	app.drawer.hide()
	check(find_button(app,"Skip to open").is_visible_in_tree(),"Skip to open is visible with management dismissed")
	app.drawer.show()
	check(bar.clean_remaining==15,"Night closure starts cleaning without a manager or manual click")
	app.root_ui.get_node("NightPrepCancel").pressed.emit()
	check(app.model.s.street.night_prep.cancelled,"Visible night countdown button cancels the jump")
	app.model.street.tick(5)
	var stock_before := int(bar.stock)
	use_button(app,"Back")
	check(not find_button(app,"Open Hours  ›").disabled,"Closed overview guides players to prep instead of serving")
	use_button(app,"Fridge")
	use_button(app,"Buy 6 · ฿228")
	check(bar.stock==stock_before+6,"Prep restocking uses the live stock action in Fridge")
	check(app.fridge_open and find_button(app,"Skip to open").is_visible_in_tree(),"Skip to open remains available in the Fridge after cancelling the countdown")
	app.model.s.street.minute = 719
	app.update_action_controls()
	check(find_button(app,"Skip to open").is_visible_in_tree(),"Skip to open is available up to the last minute before noon")
	use_button(app,"Skip to open")
	check(not find_button(app,"Skip to open").visible,"The skip button disappears when trading starts")
	check(bar.dirt==80 and bar.clean_remaining==0 and app.model.s.street.minute==720,"Skip control cancels unfinished cleaning")
	check(find_button(app,"Serve a drink").disabled and not find_button(app,"Welcome customers").disabled,"Noon allows welcoming; service waits for a real order")


func test_tuning(app: Control) -> void:
	app.change_tab(4)
	var campaign = app.model
	var elapsed: int = campaign.s.street.elapsed
	var stock: int = campaign.street.selected().stock
	use_button(app,"Start tuning playtest · 2×")
	var saved := FileAccess.get_file_as_string(Campaign.SAVE)
	check(app.model!=campaign and app.tuning_speed==2.0,"Tuning opens a separate campaign at double speed")
	app._process(1.0)
	check(app.model.s.street.elapsed==elapsed+2 and campaign.s.street.elapsed==elapsed,"Double speed advances two steps in the sandbox and keeps the main campaign frozen")
	use_button(app,"Street speed · 2×")
	app._process(1.0)
	check(app.model.s.street.elapsed==elapsed+3 and app.tuning_speed==1.0,"Switching back to normal advances one step")
	var eco = app.model.street.economy
	var usual: float = eco.traffic_rate()
	use_button(app,"Passing crowds · 100%")
	use_button(app,"Owner cooldowns · 100%")
	check(is_equal_approx(eco.traffic_rate(),usual*1.25),"Crowd tuning changes live traffic")
	use_button(app,"Serve a drink")
	check(app.model.street.selected().serve_duration==7.5 and app.model.street.selected().stock==stock-1,"Cooldown tuning affects a real sandbox sale")
	use_button(app,"Trigger Rat Plague")
	check(app.model.s.street.event.phase=="active" and app.model.street.selected().customers.is_empty(),"Sandbox can start the swarm immediately")
	app.model.street.checkpoint_requested.emit()
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(FileAccess.get_file_as_string(Campaign.SAVE)==saved,"Sandbox actions, pause, and automatic checkpoints leave the campaign save alone")
	app.change_tab(4)
	use_button(app,"End playtest")
	check(app.model==campaign and campaign.street.selected().stock==stock and campaign.s.street.event.is_empty(),"Ending the playtest restores untouched stock and events")
	app.change_tab(0)

func panel_has_text(app: Control, label: String) -> bool:
	for node in app.column.get_children():
		if node is Label and node.text == label: return true
	return false

func find_button(app: Control, label: String) -> Button:
	for b: Button in app.root_ui.find_children("*","Button",true,false):
		if b.text == label: return b
	check(false,"Missing button " + label)
	return null

func use_button(app: Control, label: String) -> void:
	var b := find_button(app,label)
	if b != null and not b.disabled:
		b.pressed.emit()


func test_godzilla(app: Control) -> void:
	app.model = Campaign.new(104)
	app.model.street.announce(8)
	app.model.street.start_event()
	app.model.start_street_boss()
	app.commit()
	check(app.model.s.phase == "godzilla" and app.city.godzilla == "attack","Godzilla appears before guests are served")
	var reloaded = Campaign.new(302)
	check(reloaded.load_game() and reloaded.s.phase == "godzilla","Pending encounter resumes from save")
	app._process(11.0)
	check(app.model.s.phase == "godzilla","Timer waits for the first shot")
	use_button(app,"Serve a shot")
	use_button(app,"Serve a shot")
	check(app.godzilla_shots == 1 and app.godzilla_meter.value == 1,"Cooldown prevents double counting")
	for i in range(1,app.SHOT_GOAL):
		app._process(app.SHOT_INTERVAL + 0.01)
		use_button(app,"Serve a shot")
	check(app.model.s.phase == "plan" and app.city.godzilla == "asleep","Filling the meter resumes service and shows Godzilla asleep")
	check(reloaded.load_game() and reloaded.s.night.godzilla == "asleep","Sleeping Godzilla survives a reload")
	app.model.street.end_shift()
	app.render()
	check(app.city.godzilla.is_empty(),"Godzilla is gone the next shift")

	app.model = Campaign.new(104)
	app.model.street.announce(8)
	app.model.street.start_event()
	app.model.start_street_boss()
	app.commit()
	use_button(app,"Serve a shot")
	app._process(app.GODZILLA_SECONDS + 0.01)
	check(app.model.s.phase == "plan" and app.model.s.night.godzilla == "scared","Timeout returns to the street")
	check(app.model.street.selected().closed == 30,"Monster loss causes a temporary closure")
	app.model.street.tick(30)
	check(app.model.street.selected().closed == 0,"The street recovers after monster damage")


func test_risk() -> void:
	var saw_worked := false
	var saw_setback := false
	for seed_value in range(1,61):
		var model = Campaign.new(seed_value,true)
		model.start()
		model.s.card = 100 # Legacy payroll story; milestones now drive new campaigns.
		var effects: Dictionary = model.current_card()[3]
		var before: Dictionary = model.s.duplicate(true)
		var rng_before: int = model.rng.state
		var risk: Dictionary = model.response_risk(effects)
		check(model.s == before and model.rng.state == rng_before,"Preview leaves state and RNG untouched")
		model.pick(0)
		var result: Dictionary = model.s.night.results.back()
		saw_worked = saw_worked or result.worked
		saw_setback = saw_setback or not result.worked
		check(result.changes == (risk.plan_changes if result.worked else risk.setback_changes),"Rolled changes match advertised effects")
		check(result.changes.cash == -400 and result.changes.reserve == 400,"Payroll transfer is honored in both outcomes")
	check(saw_worked and saw_setback,"Both outcomes can actually occur")
	var model = Campaign.new(61,true)
	model.start()
	model.s.card = 100
	var delivery := {"cash":-440,"stock":20}
	model.s.supplier = 5
	var low_chance: int = model.response_risk(delivery).chance
	model.s.supplier = 95
	check(model.response_risk(delivery).chance > low_chance,"Supplier reliability improves the odds")
	model.s.cash = 50
	var start_rng: int = model.rng.state
	check(not model.pick(0).is_empty() and model.rng.state == start_rng and not model.s.night.has("results"),
		"Unaffordable choices do not roll or register")


func test_windows_updates() -> void:
	var release := {"tag_name":"v1.12.0","draft":false,"prerelease":false,
		"assets":[{"state":"uploaded","name":Updates.ARCHIVE},{"state":"uploaded","name":"SHA256SUMS.txt"}]}
	check(Updates.latest_tag(release,"1.9.9") == "v1.12.0","New versions compare numerically")
	check(Updates.latest_tag(release,"1.12.0").is_empty() and Updates.latest_tag(release,"1.13.0").is_empty(),"No reinstall or downgrade")
	release.prerelease = true
	check(Updates.latest_tag(release,"1.9.9").is_empty(),"Ignore prereleases")
	release.prerelease = false
	release.tag_name = "v1.12.0/../another"
	check(Updates.latest_tag(release,"1.9.9").is_empty(),"Reject malformed release tags")
	release.tag_name = "v1.12.0"
	release.assets.pop_back()
	check(Updates.latest_tag(release,"1.9.9").is_empty(),"Require the published checksum")
	var digest := "ab".repeat(32)
	check(Updates.expected_hash(digest + "  " + Updates.ARCHIVE + "\n") == digest,"Read the matching checksum")
	check(Updates.expected_hash("zz".repeat(32) + "  " + Updates.ARCHIVE).is_empty(),"Reject invalid checksums")
	var archive := "user://update-fixture.zip"
	var pack := ZIPPacker.new()
	check(pack.open(archive) == OK,"Create fixture archive")
	pack.start_file(Updates.EXECUTABLE)
	var payload := "MZ-test".to_utf8_buffer()
	pack.write_file(payload)
	pack.close_file()
	pack.start_file("other-file.txt")
	pack.write_file("ignore".to_utf8_buffer())
	pack.close_file()
	pack.close()
	check(Updates.stage_executable(archive,"user://staged.exe") == OK
		and FileAccess.get_file_as_bytes("user://staged.exe") == payload
		and not FileAccess.file_exists("user://other-file.txt"),"Stage only the expected executable")
	check(Updates.valid_folder(".pattaya-update-10-20") and not Updates.valid_folder(".pattaya-update-10-../other"),"Validate restart paths")
