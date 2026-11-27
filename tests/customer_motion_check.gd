extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Art = preload("res://scripts/art.gd")
const City = preload("res://scripts/city.gd")
const StreetView = preload("res://scripts/street_view.gd")

func customer(view: Control, bar: Dictionary, id: int) -> Dictionary:
	return view.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.get("customer_id",-1)==id)[0]

func run(test: SceneTree) -> void:
	var covered := {}
	for appearance in Art.CUSTOMER_VARIANTS+[["patrons-capybara",0],["patrons-rainbow-duo",0],["patrons-charcoal",12]]:
		var id := Art.customer_motion_id(appearance)
		covered[id] = true
		for state in ["walk","walk_front","walk_back","idle","drinking","chat","pool"]:
			var frames: Array = Art.animation_frames(id,state)
			test.check(frames.size()==(4 if state.begins_with("walk") else 1),"Every customer has directional gait and bar-action frames")
	test.check(covered.size()==15,"All fifteen existing customer identities have full animation sheets")
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var view := City.new()
	view.street_state = model.s.street
	view.bars = model.s.street.bars
	view.update_customer_motion(0)
	var first: Dictionary = bar.customers[0]
	var before := JSON.stringify(model.s)
	var original := customer(view,bar,first.id)
	# Initial visitors are already present after load or navigation.
	test.check(original.motion_state=="idle","Initial visitors do not replay an arrival on opening the room")
	view.update_customer_motion(1)
	test.check(customer(view,bar,first.id).foot==original.foot,"Stationary visitors do not slide on a decorative walking loop")
	for guest in bar.customers:
		guest.visit_phase = "drinking"
		var person := customer(view,bar,guest.id)
		test.check(person.draw_pose==13 and person.motion_state=="drinking","Every real drinking phase uses a drinking pose")
		guest.chat_until = float(model.s.street.elapsed)+3.0
		person = customer(view,bar,guest.id)
		test.check(person.motion_state=="chat" and person.draw_pose==14,"Live Chat selects a conversation pose, including companions")
		guest.chat_until = 0.0
		guest.visit_phase = "waiting"
	# Queue order and another visitor's departure cannot teleport a survivor.
	bar.customers.reverse()
	view.update_customer_motion(.1)
	test.check(customer(view,bar,first.id).foot==original.foot,"A queue reorder preserves stable occupied floor slots")
	model.street.economy.admit(bar)
	var arrival: Dictionary = bar.customers.back()
	view.update_customer_motion(.1)
	var arriving := customer(view,bar,arrival.id)
	test.check(arriving.motion_state.begins_with("walk") and arriving.draw_pose in range(12) and arriving.foot!=Vector2(242,362),"A real new visitor walks in using side gait frames")
	test.check(arriving.order,"Arrival animation keeps the model's order immediately available to service")
	view.update_customer_motion(20)
	view.update_customer_motion(0)
	var settled := customer(view,bar,arrival.id)
	test.check(settled.motion_state=="idle" and settled.foot!=arriving.foot,"Walking stops at the allocated place")
	# Pool creates movement only when a real saved game has assigned a table.
	bar.games = [{"table":0,"players":[first.id],"remaining":20,"fee":50}]
	first.playing = true
	view.update_customer_motion(.1)
	var walking := customer(view,bar,first.id)
	test.check(walking.motion_state.begins_with("walk") and walking.foot.distance_to(original.foot)<=5.81,"Pool transition interpolates rather than teleporting")
	view.update_customer_motion(20)
	view.update_customer_motion(0)
	var at_pool := customer(view,bar,first.id)
	test.check(at_pool.foot==City.customer_pool_foot(bar,first,original.foot) and at_pool.draw_pose==15,"Pool cue pose begins at the actual table")
	first.playing = false
	bar.games.clear()
	view.update_customer_motion(.1)
	test.check(customer(view,bar,first.id).motion_state.begins_with("walk"),"Finished pool walks back toward the same home slot")
	view.update_customer_motion(20)
	view.update_customer_motion(0)
	test.check(customer(view,bar,first.id).foot==original.foot,"Pool return keeps the customer's original floor position")
	# Explicit model operations above are allowed; presentation cannot change any
	# part of the resulting ledger, visit plan, paid stock or gameplay RNG.
	before = JSON.stringify(model.s)
	for i in 20:
		view.clock += .05
		view.update_customer_motion(.05)
		view.scene_people(bar)
		StreetView.traffic(7,view.clock,true)
	test.check(before==JSON.stringify(model.s),"Visual frames preserve the entire campaign including ledgers, plans, stock and RNG")
	var frozen_rng: int = model.rng.state
	for i in 10: view.update_customer_motion(.1)
	test.check(model.rng.state==frozen_rng,"Walking never consumes model RNG")
	bar.open = false
	view.update_customer_motion(.1)
	test.check(view.scene_people(bar).is_empty() and view.customer_motion.is_empty(),"Closure clears all indoor customer movement")
	# Switching campaigns cannot carry old ID positions into a new save.
	var fresh := Campaign.new(12)
	view.street_state = fresh.s.street
	view.bars = fresh.s.street.bars
	view.update_customer_motion(0)
	test.check(customer(view,fresh.street.selected(),1).motion_state=="idle","New campaign starts without old transient routes")
	view.free()

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.start_new_game()
	app.city.set_process(false)
	var bar: Dictionary = app.model.street.selected()
	app.city.update_customer_motion(0)
	app.model.street.economy.admit(bar)
	var id := int(bar.customers.back().id)
	app.city._process(.75)
	var initial := customer(app.city,bar,id)
	var snapshot: Dictionary = app.city.customer_motion.duplicate(true)
	var clock_before: float = app.city.clock
	var model_before := JSON.stringify(app.model.s)
	# These are real button handlers, including drawer open/close and mute,
	# all of which previously discarded the room's animation cache.
	for action in [app.change_tab.bind(0),app.close_drawer,app.set_sound]:
		action.call()
		app.city.set_process(false)
		test.check(app.city.customer_motion==snapshot and app.city.clock==clock_before,"UI buttons retain routes, seats, dwell and gesture phase")
		test.check(customer(app.city,bar,id)==initial,"A button redraw cannot teleport a walking guest or change their frame")
	test.check(JSON.stringify(app.model.s)==model_before,"Animation continuity through navigation leaves the campaign unchanged")
	app.city.clock += 10
	test.check(customer(app.city,bar,id).draw_pose==initial.draw_pose,"A walk frame cannot advance without movement")
	app.city._process(.25)
	var next := customer(app.city,bar,id)
	test.check(next.foot.distance_to(initial.foot)>0 and next.foot.distance_to(initial.foot)<=14.51,"The next movement frame continues from the pre-click position")
	# A real sale can retarget its customer, but cannot snap anyone to a seat.
	var feet := {}
	for guest in bar.customers: feet[int(guest.id)] = customer(app.city,bar,guest.id).foot
	var sold_before := int(app.model.s.street.served)
	app.street_action("serve")
	app.city.set_process(false)
	app.city.update_customer_motion(0)
	test.check(int(app.model.s.street.served)==sold_before+1,"Serve still sells exactly one real pending drink")
	for guest in bar.customers:
		test.check(customer(app.city,bar,guest.id).foot==feet[int(guest.id)],"Serve retargets from the current position without cancelling other walks")
	# Feedback clocks survive the same UI refresh independently of movement.
	app.city.fridge_install_flash = .65
	app.city.arrival_time = .75
	app.render(true)
	app.city.set_process(false)
	test.check(app.city.fridge_install_flash==.65 and app.city.arrival_time==.75,"HUD refresh preserves equipment and arrival animation progress")
	app.model = Campaign.new(72)
	app.render()
	app.city.set_process(false)
	test.check(app.city.customer_motion.is_empty(),"New campaign does not inherit routes or seated state for reused customer IDs")
	app.city.update_customer_motion(0)
	test.check(not customer(app.city,app.model.street.selected(),1).motion_state.begins_with("walk"),"Loaded visitors initialise normally without replaying old walks")
	app.queue_free()
	await test.process_frame
