extends SceneTree
const Fight = preload("res://scripts/fight.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")
var fight: Control

func _initialize() -> void:
	call_deferred("run")

func capture(name_text: String) -> void:
	fight.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_text+".png"))

func prepare() -> void:
	fight.reset_round()
	fight.countdown = 0
	fight.ai_timer = 999
	fight.held.clear()
	fight.fighters[0].x = 128.0
	fight.fighters[1].x = 152.0

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	fight = Fight.new()
	root.add_child(fight)
	fight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fight.set_physics_process(false)
	for mobile in [false,true]:
		fight.mobile_controls = mobile
		prepare()
		await capture("controls-"+("mobile" if mobile else "desktop"))
	fight.mobile_controls = false
	for move in ["jab","lowkick","uppercut","flykick","roundhouse"]:
		prepare()
		if move == "flykick":
			fight._jump(fight.fighters[0])
			fight._motion(fight.fighters[0],.10)
		fight._attack(fight.fighters[0],move)
		for i in 15:
			fight._physics_process(.016)
			if i in [5,10,14]: await capture(move+"-%02d" % i)
		for i in 15: fight._physics_process(.016)
		await capture(move+"-air")
		for i in 60: fight._physics_process(.016)
		await capture(move+"-landed")
	print("Fight impact previews: ",output)
	fight.queue_free()
	await process_frame
	quit()
