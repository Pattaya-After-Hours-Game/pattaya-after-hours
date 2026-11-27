extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const City = preload("res://scripts/city.gd")
const Routine = preload("res://scripts/customer_routine.gd")
const Art = preload("res://scripts/art.gd")

func guest(view: Control, bar: Dictionary, id: int) -> Dictionary:
	return view.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.get("customer_id",-1)==id)[0]

func positions(view: Control, bar: Dictionary) -> Dictionary:
	var result := {}
	for p in view.scene_people(bar):
		if p.customer: result[int(p.customer_id)] = p.foot
	return result

func run(test: SceneTree) -> void:
	check_seats(test)
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.start_new_game()
	app.model = Campaign.new(72)
	app.model.s.cash = 50000
	app.render()
	app.city.set_process(false)
	var bar: Dictionary = app.model.street.selected()
	var room: Control = app.city
	room.clock = 5.43
	var before := positions(room,bar)
	var stock: int = bar.stock
	var sale: Button = test.find_button(app,"Serve a drink")
	test.check(sale!=null and not sale.disabled,"Continuity regression uses the real enabled Serve button")
	sale.pressed.emit()
	app.city.set_process(false)
	test.check(app.city==room and is_instance_valid(room),"Serving preserves the live room node through the HUD rebuild")
	test.check(bar.stock==stock-1 and bar.customers[0].drinks==1,"Actual button service still sells exactly one real drink")
	test.check(positions(room,bar)==before and room.clock==5.43,"The sale redraw cannot relocate anyone or reset an animation phase")
	var first: Dictionary = bar.customers[0]
	var p := guest(room,bar,first.id)
	test.check(p.visual_pose.begins_with("beer_walk") and p.get("body_height",180)==180,"A served guest starts a standing walk instead of changing immediately to seated art")
	var old := Vector2(p.foot)
	room.update_customer_motion(1.0/60.0)
	test.check(guest(room,bar,first.id).foot.distance_to(old)>0 and guest(room,bar,first.id).foot.distance_to(old)<=Routine.SPEED/60.0+.01,"The return journey advances smoothly one frame at a time")
	# Redraw every part of a real return walk; these are the paths the earlier
	# model-only preview missed. No record may be reseeded by navigation or HUD.
	var snapshot := JSON.stringify(app.model.s)
	var rng_before: int = app.model.rng.state
	for i in 480:
		var frame_before := positions(room,bar)
		if i%40==0:
			app.render(true)
			room.set_process(false)
			test.check(app.city==room and positions(room,bar)==frame_before,"Repeated HUD redraws keep every guest at the same visible point")
		room.clock += 1.0/60.0
		room.update_customer_motion(1.0/60.0)
		var after := positions(room,bar)
		for id in frame_before:
			test.check(Vector2(after[id]).distance_to(frame_before[id])<=Routine.SPEED/60.0+.01,"No customer warps between frames during a paid return")
	p = guest(room,bar,first.id)
	test.check(p.activity=="seat" and p.get("body_height",180)==140,"Sitting starts only after the complete walk reaches a clear chair")
	test.check(snapshot==JSON.stringify(app.model.s) and rng_before==app.model.rng.state,"Redraws and return walks preserve the campaign and gameplay RNG")
	# Repeat order, pool and management redraws all use the same retained routes.
	first.next = 0
	app.model.street.economy.order(bar,first)
	before = positions(room,bar)
	app.render()
	room.set_process(false)
	test.check(positions(room,bar)==before and guest(room,bar,first.id).motion_state.begins_with("walk"),"A new order starts a walk from the chair without jumping to the counter")
	app.change_tab(1)
	room.set_process(false)
	app.close_drawer()
	room.set_process(false)
	test.check(app.city==room and positions(room,bar)==before,"Opening and closing management cannot teleport any guest")
	bar.games = [{"table":0,"players":[first.id],"remaining":20,"fee":50}]
	first.playing = true
	app.render()
	room.set_process(false)
	test.check(positions(room,bar)==before,"Switching to a real pool destination reroutes from the current position")
	# Re-entering a known venue must not seed its existing records a second time.
	var records: Dictionary = room.customer_motion[str(bar.name)]
	Routine.update(bar,records,0,true,float(app.model.s.street.elapsed))
	test.check(positions(room,bar)==before,"Even a re-entry seed never moves an existing actor to a destination")
	room._process(5.0)
	var stalled := positions(room,bar)
	for id in before:
		test.check(Vector2(stalled[id]).distance_to(before[id])<=Routine.SPEED*.05+.01,"A stalled render frame cannot fast-forward walkers across the room")
	app.queue_free()
	await test.process_frame

func check_seats(test: SceneTree) -> void:
	for kind in 3:
		for stage in range(1,4):
			var model := Campaign.new(72)
			var bar: Dictionary = model.street.selected()
			bar.type = kind
			bar.stage = stage
			bar.equipment.seating = 3 if kind==0 else 2
			while bar.customers.size()<model.street.economy.seats(bar): model.street.economy.admit(bar)
			var city := City.new()
			city.bars = model.s.street.bars
			city.street_state = model.s.street
			city.update_customer_motion(0)
			var envelopes: Array[Rect2] = []
			for customer in bar.customers:
				var record: Dictionary = city.customer_motion[str(bar.name)][int(customer.id)]
				if record.seat==Vector2.ZERO: continue
				var appearance := Art.customer_sprite(int(customer.id),str(customer.get("appearance","")))
				var envelope := Routine.seat_envelope(appearance,record.seat,int(customer.id)%2==0)
				for other in envelopes: test.check(not envelope.intersects(other),"Seated people, pets and companion groups have real silhouette clearance in all nine rooms")
				envelopes.append(envelope)
			test.check(envelopes.size()>=2,"Physical chair spacing still leaves useful sitting places")
			city.free()
