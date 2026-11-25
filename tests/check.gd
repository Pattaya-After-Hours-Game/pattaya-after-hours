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
	var model = Campaign.new(413)
	for card in C.GOOD + C.BAD:
		var card_id: int = (C.GOOD + C.BAD).find(card)
		for option in range(2,card.size(),2):
			model = Campaign.new(413)
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
	model = Campaign.new(72)
	check(model.booking(0,0).contains("Doesn't"),"Guide refuses")
	check(model.booking(2,2).contains("Confirmed"),"Interested guide accepts")
	model.s.event = 1
	check(model.start().is_empty(),"Start paid event")
	model.pick(0)
	check(model.save_game() == OK,"Write checkpoint")
	var restored = Campaign.new(713)
	check(restored.load_game() and restored.s.card == model.s.card and restored.rng.state == model.rng.state,"Checkpoint round-trip")
	model.pick(0)
	restored.pick(0)
	check(restored.s.night.guests == model.s.night.guests and restored.s.card == model.s.card
		and restored.s.night.results == model.s.night.results,"Deterministic reload, including decision results")
	check(restored.save_game() == OK,"Create backup")
	var corrupted := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	corrupted.store_string("truncated")
	corrupted.close()
	check(Campaign.new().load_game(),"Recover a valid save from backup")
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
	model = Campaign.new(291)
	var clean_days := 0
	var saw_week := false
	var saw_rush := false
	var saw_flood := false
	var saw_godzilla := false
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
		if model.s.phase == "godzilla":
			check(not saw_godzilla and model.s.day <= 3,"One early Godzilla encounter")
			saw_godzilla = true
			model.finish_godzilla(true)
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
	check(clean_days == 365 and model.s.phase == "end","Campaign completes the first year")
	check(saw_week and saw_rush and saw_flood and saw_godzilla and model.s.wins > 0,"Weekly ledger and anchor incidents")
	test_risk()
	test_windows_updates()
	await test_ui()
	if failures == 0:
		print("PASS · all 51 cards and responses, autosave recovery, full year, UI, arcade, tutorial, Godzilla, decision odds and Windows updates")
	quit(1 if failures else 0)

func test_ui() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.show_tutorial_hint,"New players see the tutorial hint")
	use_button(app,"Tutorial")
	check(not FileAccess.file_exists(Campaign.SAVE),"Opening a tutorial creates no campaign save")
	use_button(app,"Exit")
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
	check(app.model.s.phase == "incident","Opened the doors through UI")
	var story: String = app.model.current_card()[1]
	check(not panel_has_text(app,story),"Incident starts compact")
	use_button(app,"Story")
	check(panel_has_text(app,story) and app.model.s.night.wave == 0,"Story opens without advancing the wave")
	app.choose(0)
	check(app.model.s.night.wave == 1 and not app.show_details,"New wave returns to compact view")

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
		use_button(app,app.model.current_card()[2])
	check(app.model.s.phase == "report" and app.model.s.night.guests > 0,"Tutorial reaches a real closeout")
	check(not panel_has_text(app,"DECISIONS THIS SHIFT"),"Closeout starts with the summary")
	use_button(app,"Shift log")
	check(panel_has_text(app,"DECISIONS THIS SHIFT"),"Shift log retains all decisions")
	use_button(app,"Hide")
	check(not panel_has_text(app,"DECISIONS THIS SHIFT"),"Detailed log can close")
	use_button(app,"Finish tutorial")
	check(app.model == live_campaign and app.model.s.night.wave == 1,"Tutorial restores the live shift")
	check(FileAccess.get_file_as_string(Campaign.SAVE) == save_before,"Practice made no changes to the live save")
	use_button(app,"Tutorial")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	app._unhandled_key_input(escape)
	check(app.model == live_campaign,"Esc exits a replay")
	test_godzilla(app)
	app.queue_free()
	await process_frame


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
	app.model.s.day = Campaign.GODZILLA_TEST_DAY
	app.begin()
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
	check(app.model.s.phase == "incident" and app.city.godzilla == "asleep","Filling the meter resumes service and shows Godzilla asleep")
	check(reloaded.load_game() and reloaded.s.night.godzilla == "asleep","Sleeping Godzilla survives a reload")
	while app.model.s.phase == "incident":
		app.model.fallback()
	app.render()
	check(app.city.godzilla == "asleep" and app.model.s.night.gross > 0,"Normal sales and sleeping sprite through closeout")
	app.advance()
	check(app.city.godzilla.is_empty() and not app.model.s.night.has("godzilla"),"Godzilla is gone the next day")

	app.model = Campaign.new(104)
	app.model.s.day = Campaign.GODZILLA_TEST_DAY
	app.begin()
	use_button(app,"Serve a shot")
	app._process(app.GODZILLA_SECONDS + 0.01)
	check(app.model.s.phase == "report" and app.model.s.night.godzilla == "scared","Timeout goes straight to closeout")
	check(app.model.s.night.gross == 0 and app.model.s.night.guests == 0 and app.model.s.night.wages > 0,
		"Frightened patrons buy nothing but staff are paid")


func test_risk() -> void:
	var saw_worked := false
	var saw_setback := false
	for seed_value in range(1,61):
		var model = Campaign.new(seed_value)
		model.start()
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
	var model = Campaign.new(61)
	model.start()
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
