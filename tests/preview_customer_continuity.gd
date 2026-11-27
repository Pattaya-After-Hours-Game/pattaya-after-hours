extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(app: Control, label: String) -> void:
	app.city.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func fresh(app: Control, kind: int, stage: int) -> Dictionary:
	app.model = Campaign.new(72)
	var bar: Dictionary = app.model.street.selected()
	bar.type = kind
	bar.stage = stage
	app.model.s.cash = 10000
	bar.equipment.seating = 3 if kind==0 else 2
	bar.customers.clear()
	app.model.s.street.next_customer = 1
	for i in 3: app.model.street.economy.admit(bar,false,true)
	app.render()
	app.city.set_process(false)
	return bar

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_new_game()
	app.set_process(false)
	app.music.stop()
	app.show_tutorial_hint = false
	for kind in 3:
		for stage in range(1,4):
			var bar := fresh(app,kind,stage)
			await capture(app,"clearance-%d-%d-counter" % [kind,stage])
			app.model.street.economy.serve(bar,3)
			app.render()
			app.city.set_process(false)
			for i in 300: app.city._process(1.0/30.0)
			await capture(app,"clearance-%d-%d-seated" % [kind,stage])
	if OS.get_environment("PATTAYA_PREVIEW_FAST")!="1":
		fresh(app,0,1)
		var sale: Button
		for button in app.find_children("*","Button",true,false):
			if button.text.begins_with("Serve a drink"): sale = button; break
		# Exercise the actual UI action and repeated HUD redraws, not just the
		# model helper. A 30fps clip makes the entire return walk reviewable.
		sale.pressed.emit()
		app.city.set_process(false)
		for i in 360:
			if i%15==0:
				app.render(true)
				app.city.set_process(false)
			app.city._process(1.0/30.0)
			await capture(app,"serve-return-%03d" % i)
	app.queue_free()
	await process_frame
	quit()
