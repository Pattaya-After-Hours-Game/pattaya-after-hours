extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(app: Control, name_text: String) -> void:
	app.city.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_text+".png"))

func fresh(app: Control, kind: int, stage: int) -> Dictionary:
	app.model = Campaign.new(72)
	var bar: Dictionary = app.model.street.selected()
	bar.type = kind
	bar.stage = stage
	app.model.s.cash = 999999
	bar.equipment.screen = 1
	bar.equipment.seating = 3
	bar.customers.clear()
	app.model.s.street.next_customer = 1
	for i in 3: app.model.street.economy.admit(bar,false,true)
	app.render()
	app.city.set_process(false)
	app.city.clock = 0
	app.city.update_customer_motion(0)
	return bar

func choose(app: Control, bar: Dictionary, choice: int) -> void:
	for record in app.city.customer_motion[str(bar.name)].values():
		record.choice = choice
		record.dwell = 0.0
	app.city.update_customer_motion(0)
	app.city.update_customer_motion(8)

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
			await capture(app,"routine-%d-%d-counter" % [kind,stage])
			app.model.street.economy.serve(bar,3)
			app.render()
			app.city.set_process(false)
			app.city.update_customer_motion(8)
			await capture(app,"routine-%d-%d-seated" % [kind,stage])
			choose(app,bar,1)
			await capture(app,"routine-%d-%d-mingle" % [kind,stage])
			choose(app,bar,2)
			await capture(app,"routine-%d-%d-watch" % [kind,stage])
			bar.customers[0].next = 0
			app.model.street.economy.order(bar,bar.customers[0])
			app.city.update_customer_motion(.3)
			await capture(app,"routine-%d-%d-repeat-order" % [kind,stage])
			bar.equipment.screen = 0
			app.city.update_customer_motion(.3)
			await capture(app,"routine-%d-%d-no-screen" % [kind,stage])
	# A continuous clip of actual arrival, counter approach and paid return to a
	# seat. Model operations occur only at the explicit admission/service points.
	var bar := fresh(app,0,1)
	bar.equipment.pool = 1
	bar.equipment.seating = 3
	app.model.street.economy.serve(bar,3)
	app.city.update_customer_motion(8)
	app.render()
	app.city.set_process(false)
	app.model.street.economy.admit(bar,false,true)
	for i in 96:
		app.city.clock = i*.125
		app.city.update_customer_motion(.125)
		# Exercise the controls that used to cancel the arrival mid-stride.
		if i==20: app.change_tab(0)
		if i==24: app.close_drawer()
		if i==34: app.set_sound()
		if i==74:
			app.street_action("serve")
		app.city.set_process(false)
		await capture(app,"routine-arrival-%03d" % i)
	# Real pool starts charge the fee once through the normal model helper.
	for guest in bar.customers: guest.pool = true
	app.model.street.economy.pool_tick(bar)
	for i in 48:
		app.city.clock += .125
		app.city.update_customer_motion(.125)
		await capture(app,"routine-pool-%03d" % i)
	bar.open = false
	app.city.update_customer_motion(0)
	await capture(app,"routine-closed")
	app.queue_free()
	await process_frame
	quit()
