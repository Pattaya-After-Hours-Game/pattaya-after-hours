extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Art = preload("res://scripts/art.gd")

func actor(app: Control) -> Dictionary:
	return app.city.scene_people(app.model.street.selected()).filter(func(p: Dictionary) -> bool: return p.get("who","")=="shotgun")[0]

func pointer(app: Control, touch: bool = false, emulated: bool = false) -> void:
	var person := actor(app)
	var point := Vector2.ZERO
	for height in range(30,160,5):
		var candidate: Vector2 = person.foot+Vector2(0,-height)
		if app.city._person_contains(person,candidate):
			point = candidate*app.city.size/Vector2(960,540)
			break
	var event: InputEvent
	if touch:
		event = InputEventScreenTouch.new()
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	if emulated: event.device = InputEvent.DEVICE_ID_EMULATION
	app.city._gui_input(event)

func run(test: SceneTree) -> void:
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	bar.customers.clear()
	model.s.street.next_customer = 12
	model.street.economy.admit(bar)
	var guest: Dictionary = bar.customers[0]
	test.check(guest.appearance=="shotgun" and guest.order,"Shotgun joins as a real customer with an order")
	test.check(Art.customer_sprite(12)==["patrons-men",8],"Saved visitors without the new identity keep their existing artwork")
	test.check(model.save_game()==OK,"Shotgun saves without a schema reset")
	var restored := Campaign.new(1)
	test.check(restored.load_game(),"Shotgun appearance passes campaign validation")
	test.check(restored.street.selected().customers[0]==guest,"Shotgun reload preserves the complete visit and paid quote")
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.music.stop()
	app.muted = true
	app.boot_menu = false
	app.model = model
	app.render()
	app.city.set_process(false)
	var shouts: Array = []
	app.city.shotgun_shout.connect(func(kind: String) -> void: shouts.append(kind))
	var before := JSON.stringify(model.s)
	var rng_before: int = model.rng.state
	var foot: Vector2 = actor(app).foot
	pointer(app)
	test.check(actor(app).visual_pose=="bbq" and shouts==["shotgun"],"A single mouse click starts ribs and one shout")
	var poses := {}
	for time in [.0,.15,.3,.45]:
		app.city.clock = time
		poses[actor(app).draw_pose] = true
		app.city.update_customer_motion(.1)
		test.check(actor(app).foot==foot,"Rib reaction holds its feet without sliding through the room")
	test.check(poses.size()==2,"Ribs alternate between showing the rack and taking a bite")
	pointer(app)
	test.check(shouts.size()==1,"Repeated clicks during eating never overlap shouts or restart the timer")
	app.render()
	app.city.set_process(false)
	test.check(actor(app).bbq,"Normal HUD refresh preserves Shotgun's active reaction")
	app.city.clock += 4
	test.check(not actor(app).bbq,"Eating ends and returns to normal customer activity")
	pointer(app,true,true)
	test.check(shouts.size()==1,"Emulated touch duplicates cannot replay the shout")
	pointer(app,true)
	test.check(shouts.size()==2 and actor(app).bbq,"A real touchscreen tap starts the same reaction")
	test.check(JSON.stringify(model.s)==before and model.rng.state==rng_before,"Eating, audio and redraws never change money, orders, stock, visits, deadlines or RNG")
	test.check(not app.sfx.playing,"Muted Shotgun interaction stays silent")
	var old_city: Control = app.city
	app.model = Campaign.new(9)
	app.render()
	test.check(app.city==old_city and app.city.shotgun_reaction.is_empty(),"Changing campaign clears disposable Shotgun reaction state")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
