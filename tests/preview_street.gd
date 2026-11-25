extends SceneTree
# Run only with an isolated XDG_DATA_HOME (tools/preview-art.sh enforces this).
const Campaign = preload("res://scripts/campaign.gd")
const Fight = preload("res://scripts/fight.gd")
var output := OS.get_environment("PATTAYA_PREVIEW_DIR")
var captures: Array[String] = []
var filter := OS.get_environment("PATTAYA_PREVIEW_FILTER")

func _initialize() -> void:
	call_deferred("run")

func capture(app: Control, name_text: String, rebuild: bool = true) -> void:
	if not filter.is_empty():
		var matches := false
		for pattern in filter.split(","): matches = matches or name_text.match(pattern)
		if not matches: return
	if rebuild:
		app.render()
		app.city.set_process(false)
		app.city.clock = app.scene_clock
		app.city.arrival_time = 2
		app.city.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(output.path_join(name_text+".png"))
	captures.append(name_text)

func fresh(app: Control) -> void:
	app.model = Campaign.new(72)
	app.model.s.cash = 999999
	app.model.s.rep = 100
	app.model.s.street.chapter = 4
	app.offline_notice = 0
	app.drawer_open = false
	app.tab = 0
	app.scene_clock = 3.4
	app.show_tutorial_hint = false

func populate(app: Control, bar: Dictionary, stage: int) -> void:
	bar.stage = stage
	bar.crew = stage*2
	bar.team.clear()
	for i in bar.crew:
		var role: int = int(bar.type) if i%2 else 0
		bar.team.append({"role":role,"on":true,"host":i/2 if role==1 else -1})
	if bar.type==0 and stage>1: bar.equipment.pool = 1
	bar.customers.clear()
	for i in stage*2: app.model.street.economy.admit(bar)
	bar.manager = stage>1
	bar.restock = true
	app.model.s.street.seconds = 60

func pose(fight: Control, index: int) -> void:
	fight.reset_round()
	fight.countdown = 0
	fight.elapsed = 7.0
	fight.over = false
	for f in fight.fighters:
		match index:
			1,2:
				f.motion = 1
				fight.elapsed = 7.0+(index-1)*.125
			3: f.y = Fight.FLOOR-28
			4: f.guard = true
			5:
				f.move = "jab"
				f.timer = .05
			6,7,8:
				f.move = ["jab","kick","super"][index-6]
				f.timer = Fight.ATTACKS[f.move][0]+.02
			9: f.stun = .15
			10: f.hp = 0
			11:
				fight.over = true
				fight.result = false
				fight.fighters[0].hp = 0
	fight.queue_redraw()

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
	app.offline_notice = 0
	await capture(app,"opening")
	# Present updater controls without making requests or replacing a binary.
	app.windows_updates = preload("res://scripts/windows_updates.gd").new()
	app.add_child(app.windows_updates)
	app.windows_updates.tag = "v9.0.0"
	await capture(app,"windows-update")
	app.windows_updates.queue_free()
	app.windows_updates = null
	fresh(app)
	for crossing in 6:
		app.scene_clock = crossing*24+10
		await capture(app,"passerby-%d" % crossing)
	app.scene_clock = 22
	await capture(app,"passerby-gap")
	app.scene_clock = 3.4
	for kind in 3:
		if kind > 0: app.model.street.action("buy",kind)
		for stage in range(1,4):
			var bar: Dictionary = app.model.street.selected()
			populate(app,bar,stage)
			await capture(app,"type-%d-stage-%d" % [kind,stage])
	# Purchased equipment must be visible only after ownership, at every stage.
	for kind in 3:
		app.model.s.street.selected = kind
		var bar: Dictionary = app.model.street.selected()
		for stage in range(1,4):
			bar.stage = stage
			for owned in [false,true]:
				bar.equipment.comfort = 1 if owned else 0
				await capture(app,"fan-%d-%d-%s" % [kind,stage,"owned" if owned else "unowned"])
		bar.equipment.comfort = 0
	# Occupancy extremes reveal clipping and layering hidden by light fixtures.
	for kind in 3:
		app.model.s.street.selected = kind
		var bar: Dictionary = app.model.street.selected()
		populate(app,bar,3)
		bar.customers.clear()
		bar.games.clear()
		bar.equipment.pool = 0
		await capture(app,"empty-%d" % kind)
		bar.equipment.seating = 2
		while bar.customers.size()<app.model.street.economy.seats(bar):
			app.model.street.economy.admit(bar)
		await capture(app,"full-%d" % kind)
		bar.open = false
		await capture(app,"closed-%d" % kind)
		bar.open = true
	while app.model.s.street.bars.size()<8: app.model.street.action("buy",app.model.s.street.bars.size()%3)
	for i in 8:
		app.model.s.street.selected = i
		await capture(app,"property-%d" % (i+1))
	app.model.s.street.selected = 2
	app.model.street.selected().away = [0,2,4]
	await capture(app,"staff-absent")
	app.model.street.selected().closed = 30
	await capture(app,"venue-closed")
	app.model.street.selected().closed = 0
	app.model.street.selected().away = []
	for tab in 5:
		app.tab = tab
		app.drawer_open = true
		await capture(app,"drawer-%d" % tab)
		app.scroll.scroll_vertical = 10000
		await capture(app,"drawer-%d-bottom" % tab,false)
	app.drawer_open = false
	for event in 10:
		for bar in app.model.s.street.bars: bar.closed = 0
		app.model.street.announce(event)
		await capture(app,"event-%02d-warning" % event)
		app.model.street.start_event()
		await capture(app,"event-%02d-active" % event)
		app.model.s.street.event = {}
	fresh(app)
	app.offline_notice = 1234
	await capture(app,"offline-income")
	app.offline_notice = 0
	app.start_tutorial()
	await capture(app,"tutorial-stock")
	app.do_action("buy")
	app.begin()
	await capture(app,"tutorial-incident")
	app.choose(0)
	app.choose(0)
	await capture(app,"tutorial-report")
	app.finish_tutorial()
	fresh(app)
	app.begin()
	await capture(app,"managed-incident")
	while app.model.s.phase in ["guided_choice","guided"]:
		if app.model.s.phase=="guided_choice": app.model.pick(2)
		app.model.street.tick(40)
	await capture(app,"managed-report")
	app.model.s.phase = "end"
	app.model.s.end = "The Neighborhood Institution"
	await capture(app,"outcome")
	app.confirmation = true
	await capture(app,"restart-confirmation")
	for won in [true,false]:
		fresh(app)
		app.model.street.announce(8)
		app.model.street.start_event()
		app.model.start_street_boss()
		await capture(app,"monster-encounter")
		app.city.arrival_time = .65
		app.city.queue_redraw()
		await capture(app,"monster-arrival",false)
		app.city.arrival_time = 2
		app.city.shot_flash = .8
		app.city.queue_redraw()
		await capture(app,"monster-drinking",false)
		app.model.finish_godzilla(won)
		await capture(app,"monster-sleeping" if won else "monster-closure")
	fresh(app)
	app.walk_district()
	app.district.set_process(false)
	for i in 6:
		var door: Vector2 = app.district.SITES[i][1]+Vector2(0,9)
		app.district.point = Vector2(door.x,app.district.nearest_lane(door))
		app.district.nearby = i
		app.district.queue_redraw()
		await capture(app,"district-%d" % i,false)
	for direction in 4:
		app.district.facing = direction
		app.district.walking = true
		for frame in 4:
			app.district.clock = frame/24.0
			app.district.queue_redraw()
			await capture(app,"walk-%d-%d" % [direction,frame],false)
	app.close_district()
	for rival in 3:
		app.enter_fight(true)
		app.fight.set_physics_process(false)
		app.fight.rival_index = rival
		for state in 12:
			pose(app.fight,state)
			await capture(app,"fight-%d-state-%02d" % [rival,state],false)
		pose(app.fight,10)
		app.fight.fighters[0].x = 18
		app.fight.fighters[1].x = 302
		app.fight.queue_redraw()
		await capture(app,"fight-%d-corner-ko" % rival,false)
		app.fight.fighters[0].hp = 100
		app.fight.fighters[1].hp = 0
		app.fight.fighters[0].x = 90
		app.fight.fighters[1].x = 230
		app.fight.over = true
		app.fight.result = true
		app.fight.queue_redraw()
		await capture(app,"fight-%d-mali-victory" % rival,false)
		app.leave_fight(false)
	fresh(app)
	populate(app,app.model.street.selected(),3)
	for n in 24:
		app.scene_clock = n*.25
		await capture(app,"service-playback-%02d" % n)
	app.model.street.action("buy",2)
	populate(app,app.model.street.selected(),3)
	for n in 12:
		app.scene_clock = n*.125
		await capture(app,"dance-playback-%02d" % n)
	# Time-sampled, in-engine attack playback for checking contact and recovery.
	app.enter_fight(true)
	app.fight.set_physics_process(false)
	app.fight.reset_round()
	app.fight.countdown = 0
	app.fight.elapsed = 6.0
	app.fight.ai_timer = 999
	app.fight.fighters[0].x = 130
	app.fight.fighters[1].x = 155
	for n in 30:
		if n in [0,10,20]:
			app.fight.fighters[0].meter = 100
			app.fight._attack(app.fight.fighters[0],["jab","kick","super"][n/10])
		app.fight._physics_process(.08)
		app.fight.queue_redraw()
		await capture(app,"playback-%02d" % n,false)
	app.leave_fight(false)
	app.queue_free()
	await process_frame
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(captures,"\t"))
	print("Art previews: %d captures in %s" % [captures.size(),output])
	quit()
