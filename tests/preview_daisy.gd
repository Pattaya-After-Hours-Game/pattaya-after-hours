extends "res://tests/preview_economy.gd"

func run() -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":
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
	app.show_tutorial_hint = false
	app.model.street.selected().cash = 200000
	app.model.s.rep = 100
	app.model.s.street.chapter = 2
	load("res://tests/finance_fixture.gd").buy(app.model.street,1)
	app.open_service_section("team")
	app.drawer_open = true
	await capture(app,"daisy-hire","Hire Daisy")
	app.model.street.action("hire_daisy")
	await capture(app,"daisy-roster","Daisy · On duty")
	app.model.street.action("hire_gabby")
	var b: Dictionary = app.model.street.selected()
	app.drawer_open = false
	for stage in range(1,4):
		b.stage = stage
		await capture(app,"daisy-venue-"+str(stage))
	b.team[0].on = false
	await capture(app,"daisy-off-duty")
	b.team[0].on = true
	b.away = [0]
	b.team[0].host_return = 30.0
	await capture(app,"daisy-away")
	b.away.clear()
	b.team[0].host_return = 0.0
	b.open = false
	await capture(app,"daisy-closed")
	b.open = true
	b.team[0].on = false
	b.team[0].contract_left = 0
	app.drawer_open = true
	await capture(app,"daisy-renewal","Rehire Daisy")
	app.model.street.action("rehire",0)
	await capture(app,"daisy-returned","Daisy · On duty")
	app.queue_free()
	await process_frame
	quit()
