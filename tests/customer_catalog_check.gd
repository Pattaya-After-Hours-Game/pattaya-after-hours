extends RefCounted
const Art = preload("res://scripts/art.gd")
const Campaign = preload("res://scripts/campaign.gd")
const City = preload("res://scripts/city.gd")

func run(test: SceneTree) -> void:
	var catalog := Art.customer_catalog()
	test.check(catalog.size()>=15,"Every existing customer has an individual named-pose definition")
	var appearances: Array = Art.CUSTOMER_VARIANTS+[["patrons-capybara",0],["patrons-rainbow-duo",0],["patrons-charcoal",12],["shotgun",0]]
	for appearance in appearances:
		var name := Art.customer_character_id(appearance)
		var definition: Dictionary = catalog[name]
		var expected := "customer-"+name
		test.check(definition.atlas==expected and Art.texture(expected)!=null,"Every identity owns an independent complete runtime sheet")
		for state in ["idle","walk","walk_front","walk_back","drinking","chat","pool","seated_idle","seated_drinking","seated_chat","watch","beer_walk","beer_walk_front","beer_walk_back","beer_seated_idle","beer_seated_drinking","beer_stand","beer_watch"]:
			test.check(definition.animations.has(state),"Named-pose template covers the shared customer actions")
			var frames: Array = Art.animation_frames(expected,state)
			test.check(frames.size()==(4 if state.contains("walk") else 1),"Named states resolve without fixed sheet offsets in the scene")
			var visual := Art.customer_visual(appearance,state,.27)
			test.check(visual[0]==expected and visual[1] in frames,"The chosen identity and semantic action select the correct individual atlas")
		var direct := Art.customer_visual([name,0],"beer_seated_idle",0)
		test.check(direct[0]==expected and direct[1]==definition.animations.beer_seated_idle[0],"A data-defined identity renders without editing the legacy rotation or scene code")
		var fallback := Art.customer_visual(appearance,"future_optional_pose",0)
		test.check(fallback[1]==definition.animations.idle[0],"New optional states have a safe idle fallback until their art is authored")
	# A real first sale selects a carrying walk; a waiting order never manufactures
	# a glass. Sitting alternates lowering and sipping the same already-paid beer.
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var city := City.new()
	city.street_state = model.s.street
	city.bars = model.s.street.bars
	city.update_customer_motion(0)
	var first: Dictionary = bar.customers[0]
	var p: Dictionary = city.scene_people(bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id",-1)==first.id)[0]
	test.check(not p.carrying_drink and not p.visual_pose.begins_with("beer_"),"Unpaid pending orders keep empty hands")
	model.street.economy.serve(bar)
	city.update_customer_motion(.1)
	p = city.scene_people(bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id",-1)==first.id)[0]
	test.check(p.carrying_drink and p.visual_pose.begins_with("beer_walk"),"A genuine served drink stays in hand throughout the walk back")
	var paid := JSON.stringify(model.s)
	city.update_customer_motion(8)
	var seated_poses := {}
	for time in [0.0,2.0,6.0,8.0]:
		city.clock = time
		p = city.scene_people(bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id",-1)==first.id)[0]
		seated_poses[p.visual_pose] = true
		test.check(p.carrying_drink,"Resting between sips does not discard the glass")
	test.check(seated_poses.has("beer_seated_idle") and seated_poses.has("beer_seated_drinking"),"Seated customers visibly lower and sip their beer")
	test.check(JSON.stringify(model.s)==paid,"Beer poses cannot sell another drink or change its paid budget/timer")
	first.next = 0
	model.street.economy.order(bar,first)
	city.update_customer_motion(.1)
	p = city.scene_people(bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id",-1)==first.id)[0]
	test.check(not p.carrying_drink and not p.visual_pose.begins_with("beer_"),"An empty glass is gone when the next genuine order starts")
	city.free()
