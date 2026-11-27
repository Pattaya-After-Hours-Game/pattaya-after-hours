extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const City = preload("res://scripts/city.gd")
const Routine = preload("res://scripts/customer_routine.gd")
const Art = preload("res://scripts/art.gd")

func person(view: Control, bar: Dictionary, id: int) -> Dictionary:
	return view.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.get("customer_id",-1)==id)[0]

func records(view: Control, bar: Dictionary) -> Dictionary:
	return view.customer_motion[str(bar.name)]

func run(test: SceneTree) -> void:
	# Match steps to distance, independent of render rate or elapsed idle time.
	var whole_step := {"foot":Vector2(300,368),"route":[Vector2(700,368)],"dwell":0.0}
	var fine := whole_step.duplicate(true)
	Routine.step(whole_step,1.0)
	for frame in 60: Routine.step(fine,1.0/60.0)
	test.check(whole_step.foot.distance_to(fine.foot)<.001 and absf(whole_step.walk_distance-fine.walk_distance)<.001,"Walking distance is independent of frame rate")
	var gait := float(whole_step.walk_distance)
	Routine.step(whole_step,0)
	test.check(whole_step.walk_distance==gait,"Zero-time refreshes do not advance gait")
	test.check(gait/20.0>2.5 and gait/20.0<4.0,"Normal walking uses a relaxed three-ish frames per second instead of eight")
	for name in Art.CUSTOMER_MOTION_NAMES+["charcoal"]:
		var id: String = "customer-seated-"+name
		test.check(Art.atlas_specs()[id][1]==4,"Every customer has seated actions and a still rear watcher")
		for state in ["idle","drinking","chat","watch"]:
			test.check(Art.animation_frames(id,state).size()==1,"Seat/watch poses are still activities rather than frozen walk loops")
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var view := City.new()
	view.street_state = model.s.street
	view.bars = model.s.street.bars
	view.update_customer_motion(0)
	for i in bar.customers.size():
		var guest: Dictionary = bar.customers[i]
		var p := person(view,bar,guest.id)
		test.check(p.activity=="order" and p.foot==Routine.bar_foot(bar,i),"Real pending guests approach the public side of the counter")
	var stock: int = bar.stock
	var cash: int = model.s.cash
	var before := JSON.stringify(model.s)
	var rng_before: int = model.rng.state
	for i in 20: view.update_customer_motion(.1)
	test.check(JSON.stringify(model.s)==before and model.rng.state==rng_before,"Waiting at the bar cannot pour or pay for a drink")
	test.check(model.street.economy.serve(bar,3)==3,"Normal service can serve all three genuine orders")
	test.check(bar.stock==stock-3 and model.s.cash>cash,"Only real service consumes paid stock and earns receipts")
	view.update_customer_motion(.1)
	var first: Dictionary = bar.customers[0]
	var moving := person(view,bar,first.id)
	test.check(moving.activity=="seat" and moving.motion_state.begins_with("walk"),"A served guest leaves the bar for a seat")
	view.update_customer_motion(8)
	var seated := person(view,bar,first.id)
	test.check(seated.activity=="seat" and seated.draw_who.begins_with("customer-seated-") and seated.body_height==140,"A guest genuinely sits using shorter bent-knee art")
	var stable_seat: Vector2 = records(view,bar)[int(first.id)].seat
	var duo: Dictionary = records(view,bar)[3]
	test.check(duo.seat!=records(view,bar)[2].seat and duo.seat!=stable_seat,"The duo reserves two adjacent physical seats without displacing another guest")
	bar.customers.reverse()
	view.update_customer_motion(0)
	test.check(records(view,bar)[int(first.id)].seat==stable_seat,"Queue reordering cannot change a surviving guest's reserved chair")
	bar.equipment.screen = 1
	before = JSON.stringify(model.s)
	rng_before = model.rng.state
	var seen := {}
	for i in 500:
		view.clock += .1
		view.update_customer_motion(.1)
		var p := person(view,bar,first.id)
		seen[p.activity] = true
		var watchers := 0
		for g in bar.customers:
			var other := person(view,bar,g.id)
			if other.activity=="watch":
				watchers += 1
				if not other.motion_state.begins_with("walk"):
					test.check(other.draw_pose==3 and not other.flip,"Watching uses a planted rear stance facing the real purchased screen")
			if other.activity=="mingle":
				test.check(other.partner>=0 and records(view,bar).has(int(other.partner)),"Mingling always has a real available conversation partner")
			test.check(other.order==g.order,"Walking and leisure keep exact order markers")
		test.check(watchers<=2,"The TV has bounded viewing places")
	test.check(seen.has("seat") and seen.has("mingle") and seen.has("watch"),"A real guest relaxes, mingles and watches between drinks")
	test.check(before==JSON.stringify(model.s) and rng_before==model.rng.state,"Complete social routines preserve every model field and RNG")
	# New orders interrupt leisure immediately, but their walk cannot gate service.
	first.next = 0 # The test finishes the paid drinking interval before requesting.
	model.street.economy.order(bar,first)
	view.update_customer_motion(.1)
	test.check(person(view,bar,first.id).activity=="order" and person(view,bar,first.id).order,"A repeat order sends its guest back toward the counter")
	var drinks: int = first.drinks
	bar.customers.erase(first)
	bar.customers.push_front(first)
	test.check(model.street.economy.serve(bar)==1 and first.drinks==drinks+1,"A pending order can be served while its guest is still walking")
	bar.equipment.screen = 0
	view.update_customer_motion(.1)
	for guest in bar.customers:
		test.check(person(view,bar,guest.id).activity!="watch","An unowned TV can never attract a watcher")
	# Real pool and hosted rounds take priority over social choreography.
	bar.equipment.pool = 1
	bar.games = [{"table":0,"players":[first.id],"remaining":20,"fee":50}]
	first.playing = true
	view.update_customer_motion(8)
	test.check(person(view,bar,first.id).activity=="pool" and person(view,bar,first.id).draw_pose==15,"Actual pool games retain their table and cue pose")
	first.playing = false
	bar.games.clear()
	bar.host_rounds = [{"host":0,"guest":first.id,"state":"cheers","host_deadline":20.0}]
	view.update_customer_motion(8)
	test.check(person(view,bar,first.id).activity=="host","An active hosted round stays together instead of joining a conversation elsewhere")
	bar.host_rounds.clear()
	# A lone guest must not chat to an imaginary partner.
	bar.customers = [first]
	records(view,bar)[int(first.id)].choice = 1
	view.update_customer_motion(.1)
	test.check(person(view,bar,first.id).activity=="stand" and person(view,bar,first.id).partner==-1,"A solo guest never invents a companion")
	model.street.economy.depart(bar,first)
	view.update_customer_motion(.1)
	test.check(view.scene_people(bar).is_empty() and records(view,bar).is_empty(),"A completed visit immediately releases all visual places")
	# Nine room layouts keep targets inside their actual public floor, with
	# traversals in the clear aisle below furniture rather than across tabletops.
	for kind in 3:
		for stage in range(1,4):
			var fixture := {"type":kind,"stage":stage}
			for seat in Routine.seats(fixture):
				test.check(seat.x>=240 and seat.x<=820 and seat.y<=395,"Reserved chairs match the furnished public area")
			for position in 40:
				var counter := Routine.bar_foot(fixture,position)
				test.check(counter.y>=344 and counter.x>=240 and counter.x<=830,"A packed counter line stays on the public side of the room")
			var route := Routine.plan_route(Vector2(300,340),Vector2(700,350))
			test.check(route.size()==3 and route[0].y==Routine.AISLE_Y and route[1].y==Routine.AISLE_Y,"Long walks go around the tables on the public aisle")
	# A departure frees a chair without shuffling seated survivors along the bar.
	var next_model := Campaign.new(72)
	bar = next_model.street.selected()
	view.street_state = next_model.s.street
	view.bars = next_model.s.street.bars
	view.update_customer_motion(0)
	next_model.street.economy.serve(bar,3)
	view.update_customer_motion(8)
	var preserved: Vector2 = records(view,bar)[2].seat
	next_model.street.economy.depart(bar,bar.customers[0])
	view.update_customer_motion(0)
	test.check(records(view,bar)[2].seat==preserved,"A departing neighbour cannot pull a seated guest into a different chair")
	view.free()
