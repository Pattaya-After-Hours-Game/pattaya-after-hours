extends SceneTree
# Real campaign fixtures; launch through tools/preview-art.sh for isolated saves.
const Campaign = preload("res://scripts/campaign.gd")
const District = preload("res://scripts/district.gd")
const StreetView = preload("res://scripts/street_view.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")

func _initialize() -> void:
	call_deferred("run")

func capture(name_text: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_text+".png"))

func fill(app: Control, count: int) -> void:
	for venue: Dictionary in app.model.s.street.bars: venue.customers.clear()
	for venue: Dictionary in app.model.s.street.bars:
		var admitted := mini(count,app.model.street.economy.seats(venue))
		for i in admitted: app.model.street.economy.admit(venue)
		count -= admitted
	assert(count==0,"Preview has sufficient real venue capacity")

func room(app: Control) -> void:
	app.render()
	app.city.set_process(false)
	app.city.clock = 4
	app.city.queue_redraw()

func run() -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":
		push_error("Use tools/preview-art.sh with a graphical display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.start_new_game()
	app.music.stop()
	app.muted = true
	app.model = Campaign.new(72)
	app.model.s.cash = 999999
	app.model.s.rep = 100
	app.model.s.street.chapter = 4
	var bar: Dictionary = app.model.street.selected()
	bar.stage = 3
	bar.equipment.seating = 7
	app.model.street.action("buy",1)
	app.model.street.action("buy",2)
	for venue: Dictionary in app.model.s.street.bars:
		venue.stage = 3
	bar.equipment.seating = 0
	bar.stage = 1
	app.offline_notice = 0
	app.render()
	app.walk_district()
	var district: Control = app.district
	district.set_process(false)
	for level in 8:
		fill(app,District.ACTIVITY_GUESTS[level])
		district.plate_level = -1
		district.update_activity(1)
		district.clock = 4
		district.queue_redraw()
		await capture("street-activity-%d" % level)
	# Capture live closure and rain, without resetting the map's state reference.
	app.model.s.street.minute = 240
	district.update_activity(1)
	district.queue_redraw()
	await capture("street-activity-closed")
	app.model.s.street.minute = 1320
	district.weather = 5
	district.update_activity(1)
	district.queue_redraw()
	await capture("street-activity-rain")
	district.weather = 0
	for frame in 24:
		district.clock = 4+frame*.15
		district.queue_redraw()
		await capture("district-traffic-frame-%02d" % frame)
	app.close_district()
	app.model.s.street.selected = 0
	fill(app,3)
	for period in 8:
		app.model.s.street.minute = StreetView.TIME_STARTS[period]+30
		if period==4: app.model.s.street.minute = 720
		room(app)
		await capture("bar-time-%d" % period)
	app.model.s.street.minute = 1320
	for level in 8:
		fill(app,District.ACTIVITY_GUESTS[level])
		room(app)
		await capture("bar-activity-%d" % level)
	for slot in app.model.s.street.bars.size():
		app.model.s.street.selected = slot
		for stage in range(1,4):
			app.model.street.selected().stage = stage
			fill(app,36)
			room(app)
			await capture("bar-aperture-%d-%d" % [slot,stage])
	app.model.s.street.selected = 0
	app.model.street.selected().stage = 1
	fill(app,36)
	room(app)
	for frame in 24:
		app.city.clock = 4+frame*.15
		app.city.queue_redraw()
		await capture("bar-traffic-frame-%02d" % frame)
	# Near/far front and rear silhouettes beside the parked scooter and patrons.
	for stage in range(1,4):
		app.model.street.selected().stage = stage
		for sample in [["far",2.2],["front",19.36],["rear",24.64],["charcoal",107.36],["scooter",6.49],["car",4.2]]:
			fill(app,10 if sample[0]=="car" else 3)
			room(app)
			app.city.clock = sample[1]
			app.city.queue_redraw()
			await capture("bar-traffic-scale-%d-%s" % [stage,sample[0]])
	app.queue_free()
	await process_frame
	print("Captured district activity, closure/rain, bar clock/activity, all nine apertures and traffic frames: "+output)
	quit()
