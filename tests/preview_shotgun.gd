extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
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
	app.muted = true
	app.music.stop()
	app.model = Campaign.new(72)
	var bar: Dictionary = app.model.street.selected()
	bar.customers.clear()
	app.model.s.street.next_customer = 12
	app.model.street.economy.admit(bar)
	for kind in 3:
		bar.type = kind
		app.render()
		app.city.set_process(false)
		app.city.clock = 0
		app.city.shotgun_reaction.clear()
		app.city.queue_redraw()
		await capture("shotgun-%d-idle" % kind)
		load("res://tests/shotgun_check.gd").new().pointer(app)
		for time in [0.0,.3,.6,3.3]:
			app.city.clock = time
			app.city.queue_redraw()
			await capture("shotgun-%d-%03d" % [kind,int(time*100)])
	app.queue_free()
	await process_frame
	quit()
