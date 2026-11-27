extends SceneTree
## Run through tools/preview-art.sh; never uses the player's campaign.
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(app: Control, name_text: String) -> void:
	app.title_screen.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_text+".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	app.music.stop()
	for frame in 37:
		app.title_clock = frame*.1
		app.title_screen.update_time(app.title_clock)
		await capture(app,"title-intro-%02d" % frame)
	await capture(app,"title-new")
	app.set_sound()
	await capture(app,"title-muted")
	app.start_new_game()
	app.model.s.day = 42
	app.model.s.cash = 18450
	app.boot_menu = true
	app.resume_available = true
	app.render()
	await capture(app,"title-resume")
	app.request_new_game()
	await capture(app,"title-confirm")
	app.cancel_new_game()
	app.model.s.day = 12345
	app.model.s.cash = 123456789
	app.render()
	await capture(app,"title-long-save")
	app.message = "Could not start a new game: save failed (13)."
	app.render()
	await capture(app,"title-save-error")
	app.queue_free()
	await process_frame
	quit()
