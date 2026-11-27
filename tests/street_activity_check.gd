extends RefCounted
const District = preload("res://scripts/district.gd")
const Art = preload("res://scripts/art.gd")
const StreetView = preload("res://scripts/street_view.gd")

func run(test: SceneTree) -> void:
	var view := District.new()
	var guests: Array = []
	var bar := {"open":true,"customers":guests}
	view.street_state = {"minute":720,"bars":[bar]}
	var thresholds := [0,1,3,6,10,16,24,36]
	var hashes := {}
	for level in 8:
		guests.resize(thresholds[level])
		test.check(view.activity_level()==level,"Street art reaches activity level %d from real occupancy" % level)
		if level>0:
			guests.resize(thresholds[level]-1)
			test.check(view.activity_level()==level-1,"Street art changes at the guest boundary")
		var plate := Art.texture("street-activity-%d" % level)
		test.check(plate!=null and plate.get_size()==Vector2(960,540),"Eight full-resolution street activity plates exist")
		if plate: hashes[hash(plate.get_image().get_data())] = true
	test.check(hashes.size()==8,"Every street activity plate has distinct artwork")
	guests.resize(70)
	test.check(view.activity_level()==7,"Larger crowds stay at Packed")
	for closure in ["open","closed","raided"]:
		bar[closure] = false if closure=="open" else 1
		test.check(view.live_guests()==0 and view.activity_level()==0,"Closed venues do not produce street bustle: "+closure)
		bar.erase(closure)
	view.street_state.minute = 120
	test.check(view.activity_level()==0,"Ordinary venues are quiet after hours")
	bar.late_open = true
	test.check(view.activity_level()==7,"Permitted late trade still contributes activity")
	view.street_state.minute = 180
	test.check(view.activity_level()==0,"Late trade ends at 3am")
	view.street_state.minute = 720
	view.street_state.bars.append({"customers":[{},{},{}]})
	guests.clear()
	test.check(view.live_guests()==3 and view.activity_level()==2,"Street activity aggregates venues, including an empty flagship")
	var before := JSON.stringify(view.street_state)
	for i in 20:
		view.update_activity(.05)
		view.live_guests()
		view.activity_level()
	test.check(JSON.stringify(view.street_state)==before,"Activity reads and visual crossfades cannot mutate campaign state")
	view.free()
	check_underlays(test)
	check_traffic(test)

func check_underlays(test: SceneTree) -> void:
	for period in 8:
		var minute: int = StreetView.TIME_STARTS[period]
		test.check(StreetView.period(minute)==period and StreetView.period(minute+1440)==period,"Street lighting follows the clock across midnight")
		var underlay := Art.texture("street-day-%d" % period)
		test.check(underlay!=null and underlay.get_size()==Vector2(Art.STREET_RECT.size),"Reusable street underlay fits the aperture")
	test.check(StreetView.period(720)==4 and StreetView.period(1200)==6,"Noon is daylight and 8pm is dusk regardless of crowd")
	for kind in 3:
		for stage in range(1,4):
			var original := Art.venue(kind,stage,false,false,0)
			var room := original.get_image()
			room.convert(Image.FORMAT_RGBA8)
			var shell := Art.room_shell(original,kind,stage).get_image()
			var mask := Art.street_mask(kind==0 and stage==3)
			var rect := Art.STREET_RECT
			for strip in [Rect2i(0,0,960,rect.position.y),Rect2i(0,rect.end.y,960,540-rect.end.y),Rect2i(0,rect.position.y,rect.position.x,rect.size.y),Rect2i(rect.end.x,rect.position.y,960-rect.end.x,rect.size.y)]:
				test.check(room.get_region(strip).get_data()==shell.get_region(strip).get_data(),"All room pixels outside the street crop stay exactly unchanged")
			var intact := true
			var cut := true
			for y in mask.get_height():
				for x in mask.get_width():
					var p := Vector2i(x,y)+rect.position
					if mask.get_pixel(x,y).a==0:
						intact = intact and room.get_pixelv(p)==shell.get_pixelv(p)
					else:
						cut = cut and shell.get_pixelv(p).a==0
			test.check(intact and cut,"Only the outdoor aperture changes across all nine rooms, preserving terrace/furniture")
			test.check(original.get_image().get_data()==Art.venue(kind,stage,false,false,0).get_image().get_data(),"Creating the shell cannot change cached production art")

func check_traffic(test: SceneTree) -> void:
	for closeup in [false,true]:
		test.check(StreetView.traffic(0,4,closeup).is_empty(),"An empty street has no decorative crowd or vehicles")
		var previous := 0
		for level in 8:
			var traffic := StreetView.traffic(level,4,closeup)
			test.check(traffic.size()>=previous,"Street crowd and vehicles grow with busyness")
			previous = traffic.size()
			for item in traffic:
				var frames: int = Art.atlas_specs()[item.id][1]
				test.check(item.frame>=0 and item.frame<frames,"Outdoor animation uses valid sprite frames")
				if closeup: test.check(Art.STREET_RECT.has_point(Vector2i(item.foot)),"Traffic feet stay in the outdoor crop")
		var first := StreetView.traffic(7,4,closeup)
		var later := StreetView.traffic(7,4.2,closeup)
		test.check(first!=later and first==StreetView.traffic(7,4,closeup),"Walking/riding motion advances and re-renders deterministically")
		for item in first:
			var matches := later.filter(func(other: Dictionary) -> bool: return other.key==item.key)
			var next: Dictionary = matches[0]
			if item.tint.a>.5 and next.tint.a>.5:
				if closeup:
					test.check((next.foot.y>item.foot.y)==(item.facing=="front") and not item.flip,"Bar traffic uses native front/rear views in its travel direction")
					test.check(item.id.ends_with("-depth") and (item.frame/4)%2==int(item.facing=="back"),"Bar animation selects the matching front or rear row")
				else:
					test.check((next.foot.x<item.foot.x)==item.flip and not item.id.ends_with("-depth"),"District traffic retains its side-profile sprites")
		for item in StreetView.traffic(4,4,closeup):
			var matches := first.filter(func(other: Dictionary) -> bool: return other.key==item.key)
			test.check(matches.size()==1 and matches[0]==item,"Busier bands add actors without teleporting existing traffic")
		test.check(first.any(func(item: Dictionary) -> bool: return item.id.begins_with("street-cars")) and first.any(func(item: Dictionary) -> bool: return item.id.begins_with("street-scooters")),"Busy streets include cars and scooters")
	var views := {}
	for second in range(0,600,3):
		for item in StreetView.traffic(7,second,true):
			views["%s/%d" % [item.id,item.frame/4]] = true
	test.check(views.size()==44,"All nineteen walkers, two scooters and the car can appear in front and rear views")
	var quiet_directions := {}
	for second in range(0,60,3):
		for item in StreetView.traffic(4,second,true):
			if item.id=="street-cars-depth": quiet_directions[item.facing] = true
	test.check(quiet_directions.size()==2,"Even a single car alternates approaching and departing crossings")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.start_new_game()
	var before := JSON.stringify(app.model.s)
	var rng_before: int = app.model.rng.state
	app.walk_district()
	app.district.set_process(false)
	test.check(app.district.live_guests()==3,"District opens on the campaign's actual opening guests")
	app.district.update_activity(.5)
	app.close_district()
	test.check(JSON.stringify(app.model.s)==before and app.model.rng.state==rng_before,"Opening and closing the activity map changes neither campaign nor RNG")
	app.walk_district()
	app.district.set_process(false)
	app.model.street.selected().customers.clear()
	test.check(app.district.activity_level()==0,"Open district reads live changes rather than an opening snapshot")
	app.close_district()
	app.queue_free()
	await test.process_frame
