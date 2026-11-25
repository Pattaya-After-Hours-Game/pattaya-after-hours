extends SceneTree

# Run with an isolated XDG_DATA_HOME; never preview against a personal save.
const Campaign = preload("res://scripts/campaign.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")
var filter := OS.get_environment("PATTAYA_PREVIEW_FILTER")

func _initialize() -> void:
	call_deferred("run")

func find_text(node: Node, text: String) -> Control:
	if node is Label and node.text.begins_with(text): return node
	for child in node.get_children():
		var found := find_text(child,text)
		if found: return found
	return null

func capture(app: Control, name_text: String, scroll_to: String = "") -> void:
	if not filter.is_empty() and not name_text.match(filter): return
	app.render()
	await process_frame
	await process_frame
	if not scroll_to.is_empty():
		var target := find_text(app.column,scroll_to)
		if target: app.scroll.scroll_vertical = int(target.position.y)
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
	app.show_tutorial_hint = false
	app.drawer_open = true
	await capture(app,"economy-opening")
	app.model.s.cash = 250000
	var first: Dictionary = app.model.street.selected()
	first.equipment.pool = 1
	first.equipment.seating = 1
	for guest in first.customers: guest.pool = true
	app.model.street.economy.pool_tick(first)
	await capture(app,"economy-pool","POOL")
	app.model.street.action("promotion",0)
	app.tab = 1
	await capture(app,"economy-free-pool","Venue promotions")
	for i in 120:
		app.model.street.action("serve")
		app.model.street.tick(1)
	await capture(app,"economy-promotion-report","LAST PROMOTION")
	app.tab = 0
	await capture(app,"economy-milestones","LAST SHIFT")
	first.stage = 2
	first.equipment.pool = 2
	first.customers.clear()
	first.games.clear()
	for i in 4:
		app.model.street.economy.admit(first)
		first.customers.back().pool = true
	app.model.street.economy.pool_tick(first)
	first.games[0].remaining = 1
	app.model.street.economy.pool_tick(first)
	app.drawer_open = false
	await capture(app,"pool-two-tables")
	first.equipment.pool = 0
	first.games.clear()
	for guest in first.customers: guest.playing = false
	await capture(app,"pool-not-open")
	app.drawer_open = true
	first.open = false
	app.model.s.cash = 0
	await capture(app,"economy-recovery")
	first.open = true
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
			bar.team.clear()
			for i in bar.crew: bar.team.append({"role":kind if i%2 else 0,"on":true,"host":i if kind==1 else -1})
			if kind==0 and stage>1: bar.equipment.pool = 1
			bar.customers.clear()
			for i in stage*2: app.model.street.economy.admit(bar)
			bar.manager = stage > 1
			bar.restock = true
			app.model.s.street.seconds = 60
			app.drawer_open = false
			await capture(app,"type-%d-stage-%d" % [kind,stage])
	app.drawer_open = true
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
	for rival in 3:
		var duel = load("res://scripts/fight.gd").new()
		duel.rival_index = rival
		duel.size = Vector2(960,540)
		root.add_child(duel)
		duel.set_physics_process(false)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("fight-%d.png" % rival))
		duel.queue_free()
		await process_frame
	app.queue_free()
	await process_frame
	print("Street previews: "+output)
	quit()
