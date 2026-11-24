extends SceneTree

const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/content.gd")
const Fight = preload("res://scripts/fight.gd")
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
	check(restored.s.night.guests == model.s.night.guests and restored.s.card == model.s.card,"Deterministic reload")
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
	check(clean_days == 365 and model.s.phase == "end","Campaign completes the first year")
	check(saw_week and saw_rush and saw_flood and model.s.wins > 0,"Weekly ledger and anchor incidents")
	await test_ui()
	if failures == 0:
		print("PASS · all 51 cards and responses, autosave recovery, full year, UI and arcade")
	quit(1 if failures else 0)

func test_ui() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
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
	app.choose(0)
	check(app.model.s.night.wave == 1,"Resolved a card through UI")
	app.queue_free()
	await process_frame
