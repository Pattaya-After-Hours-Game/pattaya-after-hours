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
	load("res://tests/action_check.gd").new().run(self)

	load("res://tests/staff_check.gd").new().run(self)
	load("res://tests/staff_ready_check.gd").new().run(self)
	load("res://tests/promoter_check.gd").new().run(self)
	load("res://tests/automation_check.gd").new().run(self)
	load("res://tests/bulk_stock_check.gd").new().run(self)
	load("res://tests/celebration_check.gd").new().run(self)
	test_risk()
	test_windows_updates()
	load("res://tests/boot_menu_check.gd").new().run(self)
	await load("res://tests/action_check.gd").new().run_ui(self)
	await test_ui()
	load("res://tests/art_check.gd").new().run(self)
	load("res://tests/scene_check.gd").new().run(self)
	await load("res://tests/art_interaction_check.gd").new().run(self)
	if failures == 0:
		print("PASS · incident deck, endless year, street economy, chapters, migration, offline earnings, events, UI, arcade, tutorial, Godzilla, decision odds and Windows update checks")
	quit(1 if failures else 0)

func test_ui() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	use_button(app,"New Game")
	check(app.show_tutorial_hint,"New players see the tutorial hint")
	var initial_save := FileAccess.get_file_as_string(Campaign.SAVE)
	use_button(app,"Tutorial")
	check(FileAccess.get_file_as_string(Campaign.SAVE)==initial_save,"Opening a tutorial leaves the new campaign save untouched")
	use_button(app,"Exit")
	var opening_cash := int(app.model.s.cash)
	use_button(app,"Serve a drink")
	check(app.model.s.street.served == 1 and app.model.s.cash > opening_cash,"Main clicker button serves and earns")
	app.model.s.cash = 50000
	use_button(app,"Hire bartender · ฿1,200")
	app.model.street.tick(25)
	check(app.model.s.street.served == 2,"Hired staff serve without tapping")
	app.render()
	var staff_hud: Button = app.root_ui.get_node("StaffIndicator")
	check(staff_hud.text.contains("drinks served: 1"),"Bottom-right HUD reports real staff sales separately from owner taps")
	staff_hud.pressed.emit()
	check(app.tab==0 and app.drawer_open,"Staff indicator opens the Service panel")
	app.model.street.announce(3)
	app.render()
	app.event_banner.pressed.emit()
	check(app.tab == 1,"The event banner opens preparation controls")
	use_button(app,"Raise stock & share pumps · ฿450")
	check(app.model.s.street.event.prepared,"Event preparation works through the UI")
	app.model.s.street.event = {}
	app.change_tab(0)
	use_button(app,"Train Bartender 1 · ฿800")
	check(app.model.street.selected().team[0].training==1,"Individual training control works")
	app.model.street.economy.advance_contracts(14400)
	app.render()
	use_button(app,"Rehire Bartender 1 · ฿1,200")
	check(app.model.street.selected().team[0].training==1 and app.model.street.selected().team[0].on,"Rehire control retains training")
	use_button(app,"Hire Nida · ฿1,200 + 10% drinks")
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
	exit_touch.position = Vector2(915,490)
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
	check(find_button(app,"Open the doors").disabled,"Practice shift waits for stock")
	use_button(app,app.stock_label())
	check(not find_button(app,"Open the doors").disabled,"Delivery unlocks opening")
	use_button(app,"Open the doors")
	for wave in 2:
		check(app.model.s.phase == "incident" and app.model.s.night.wave == wave,"Practice wave %d" % (wave + 1))
		if wave == 0:
			var story: String = app.model.current_card()[1]
			check(not panel_has_text(app,story),"Legacy incident starts compact")
			use_button(app,"Story")
			check(panel_has_text(app,story),"Legacy Story opens without advancing the wave")
		use_button(app,app.model.current_card()[2])
	check(app.model.s.phase == "report" and app.model.s.night.guests > 0,"Tutorial reaches a real closeout")
	check(not panel_has_text(app,"DECISIONS THIS SHIFT"),"Closeout starts with the summary")
	use_button(app,"Shift log")
	check(panel_has_text(app,"DECISIONS THIS SHIFT"),"Shift log retains all decisions")
	use_button(app,"Hide")
	check(not panel_has_text(app,"DECISIONS THIS SHIFT"),"Detailed log can close")
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
	use_button(app,"Stay open until 3am tonight")
	check(bar.late_open,"Nightly extension works through Service")
	use_button(app,"Cancel late opening tonight")
	check(not bar.late_open,"Nightly extension can be cancelled through Service")
	bar.dirt = 80
	app.model.s.street.minute = 59
	app.model.street.tick(1)
	app.render()
	check(find_button(app,"Serve a drink").disabled and find_button(app,"Welcome customers").disabled,"Closed-hours UI disables customer actions")
	check(panel_has_text(app,"PREP FOR OPENING") and find_button(app,"Skip to 12pm")!=null,"Closed-hours Service exposes prep and skipping")
	use_button(app,"Clean venue · 15 seconds")
	check(bar.clean_remaining==15,"Cleaning starts through the prep control")
	app.model.street.tick(5)
	var stock_before := int(bar.stock)
	use_button(app,"Buy 6 drinks · ฿84")
	check(bar.stock==stock_before+6,"Prep restocking uses the live stock action")
	use_button(app,"Skip to 12pm")
	check(bar.dirt==80 and bar.clean_remaining==0 and app.model.s.street.minute==720,"Skip control cancels unfinished cleaning")
	check(find_button(app,"Serve a drink").disabled and not find_button(app,"Welcome customers").disabled,"Noon allows welcoming; service waits for a real order")


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
