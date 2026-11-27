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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_new_game()
	app.set_process(false)
	app.music.stop()
	app.model = Campaign.new(72)
	app.show_tutorial_hint = false
	var bar: Dictionary = app.model.street.selected()
	app.model.s.cash = 999999
	bar.stage = 3
	bar.equipment.seating = 7
	bar.customers.clear()
	# First 24 IDs cover the full ordinary rotation and both companions;
	# optional charcoal appearance is explicitly added through normal admission.
	for i in 24: app.model.street.economy.admit(bar)
	for kind in 3:
		bar.type = kind
		for state in ["idle","drinking","chat","pool"]:
			bar.games.clear()
			bar.equipment.pool = 2 if state=="pool" else 0
			for i in bar.customers.size():
				var guest: Dictionary = bar.customers[i]
				guest.visit_phase = "drinking" if state=="drinking" else "waiting"
				guest.chat_until = float(app.model.s.street.elapsed)+3 if state=="chat" else 0.0
				guest.playing = state=="pool" and i<4
			if state=="pool":
				for table in 2:
					bar.games.append({"table":table,"players":[bar.customers[table*2].id,bar.customers[table*2+1].id],"remaining":20,"fee":50})
			app.render()
			app.city.set_process(false)
			app.city.customer_motion.clear()
			app.city.clock = 4
			await capture(app,"customer-motion-%d-%s" % [kind,state])
	# Live admission and model-driven pool transition at a readable occupancy.
	bar.type = 0
	bar.equipment.pool = 1
	bar.games.clear()
	bar.customers.resize(3)
	for guest in bar.customers:
		guest.playing = false
		guest.chat_until = 0.0
		guest.visit_phase = "waiting"
	app.render()
	app.city.set_process(false)
	app.city.customer_motion.clear()
	app.city.update_customer_motion(0)
	app.model.s.street.next_customer = 12 # Beard/glasses identity, real admission.
	app.model.street.economy.admit(bar)
	for frame in 20:
		app.city.clock = frame*.15
		app.city.update_customer_motion(.15)
		await capture(app,"customer-arrival-%02d" % frame)
	app.city.update_customer_motion(20)
	bar.customers[0].playing = true
	bar.games = [{"table":0,"players":[bar.customers[0].id],"remaining":20,"fee":50}]
	for frame in 12:
		app.city.clock = frame*.15
		app.city.update_customer_motion(.15)
		await capture(app,"customer-pool-walk-%02d" % frame)
	app.city.update_customer_motion(20)
	bar.open = false
	await capture(app,"customer-motion-closed")
	bar.open = true
	# Use the full stage-one aperture; the furnished terrace is distant.
	bar.stage = 1
	app.render()
	app.city.set_process(false)
	# All new street identities in native side/front/rear views.
	app.walk_district()
	app.district.set_process(false)
	for i in 19:
		app.district.clock = 5+i*22
		app.district.queue_redraw()
		await capture(app,"customer-district-%02d" % i)
	app.close_district()
	app.city.set_process(false)
	for i in 19:
		app.city.clock = 5+i*22
		await capture(app,"customer-street-depth-%02d" % i)
	app.queue_free()
	await process_frame
	quit()
