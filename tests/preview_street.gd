extends SceneTree

# Run with an isolated XDG_DATA_HOME; never preview against a personal save.
const Campaign = preload("res://scripts/campaign.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(app: Control, name_text: String) -> void:
	app.render()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(output.path_join(name_text+".png"))

func run() -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless":
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
	app.model = Campaign.new(72)
	await capture(app,"opening")
	app.model.s.cash = 250000
	app.model.s.rep = 80
	app.model.s.street.chapter = 4
	app.show_tutorial_hint = false
	for kind in 3:
		if kind > 0: app.model.street.action("buy",kind)
		for stage in range(1,4):
			var bar: Dictionary = app.model.street.selected()
			bar.stage = stage
			bar.crew = stage*2
			bar.manager = stage > 1
			bar.restock = true
			await capture(app,"type-%d-stage-%d" % [kind,stage])
	app.tab = 3
	await capture(app,"empire")
	app.tab = 1
	app.model.street.announce(9)
	await capture(app,"festival-warning")
	app.model.street.start_event()
	app.model.start_street_boss()
	await capture(app,"festival-boss")
	app.model.finish_godzilla(true)
	app.tab = 0
	await capture(app,"festival-complete")
	app.queue_free()
	await process_frame
	print("Street previews: "+output)
	quit()
