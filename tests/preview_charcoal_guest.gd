extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
const Art = preload("res://scripts/art.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(name_text: String) -> void:
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
	var bar: Dictionary = app.model.street.selected()
	bar.customers.clear()
	app.model.s.street.next_customer = 24
	app.model.street.economy.admit(bar)
	var guest: Dictionary = bar.customers[0]
	for kind in 3:
		bar.type = kind
		for state in ["idle","drinking","chat","pool"]:
			guest.visit_phase = "drinking" if state=="drinking" else "waiting"
			guest.chat_until = float(app.model.s.street.elapsed)+3 if state=="chat" else 0.0
			guest.playing = state=="pool"
			bar.equipment.pool = 1 if state=="pool" else 0
			bar.games = [{"table":0,"players":[24],"remaining":20,"fee":50}] if state=="pool" else []
			app.render()
			app.city.set_process(false)
			app.city.clock = 4
			app.city.arrival_time = 2
			app.city.queue_redraw()
			await capture("charcoal-%d-%s" % [kind,state])
	bar.type = 0
	bar.games.clear()
	guest.playing = false
	bar.equipment.pool = 0
	bar.equipment.seating = 3
	while bar.customers.size()<12: app.model.street.economy.admit(bar)
	app.render()
	app.walk_district()
	app.district.set_process(false)
	for i in 8:
		app.district.clock = 6+i*.15
		app.district.queue_redraw()
		await capture("charcoal-district-%d" % i)
	app.close_district()
	app.render()
	app.city.set_process(false)
	for i in 8:
		app.city.clock = 90+i*.15
		app.city.queue_redraw()
		await capture("charcoal-approach-%d" % i)
	app.queue_free()
	await process_frame
	quit()
