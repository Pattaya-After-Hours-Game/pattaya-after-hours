extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Art = preload("res://scripts/art.gd")
const City = preload("res://scripts/city.gd")
const StreetView = preload("res://scripts/street_view.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	bar.customers.clear()
	m.s.street.next_customer = 24
	m.street.economy.admit(bar)
	var guest: Dictionary = bar.customers[0]
	test.check(guest.get("appearance","")=="charcoal" and guest.order,"New reference guest joins through normal admission with a real order")
	test.check(Art.customer_sprite(24)==["patrons-men",8],"Existing saved ID without the optional appearance retains its old look")
	var before := JSON.stringify(m.s)
	var rng_before: int = m.rng.state
	var view := City.new()
	view.street_state = m.s.street
	view.clock = 10000 # Scene clock is deliberately different from the model.
	test.check(view.scene_people(bar)[0].pose==12,"Waiting guest stands idle without inventing a drink")
	guest.visit_phase = "drinking"
	test.check(view.scene_people(bar)[0].pose==13,"Actual drinking phase selects the drinking pose")
	guest.chat_until = float(m.s.street.elapsed)+3
	test.check(view.scene_people(bar)[0].pose==14,"Chat uses the saved model deadline, not the animation clock")
	guest.playing = true
	test.check(view.scene_people(bar)[0].pose==15,"Active pool selects the cue pose")
	guest.playing = false
	guest.chat_until = 0.0
	guest.visit_phase = "waiting"
	test.check(JSON.stringify(m.s)==before and m.rng.state==rng_before,"All pose/catalog reads preserve the model and RNG")
	bar.open = false
	test.check(view.scene_people(bar).is_empty(),"Closure removes the new guest along with the normal crowd")
	bar.open = true
	view.free()
	test.check(m.save_game()==OK,"Reference guest saves in the existing schema")
	var restored = Campaign.new(1)
	test.check(restored.load_game(),"Optional cosmetic identity loads")
	var saved: Dictionary = restored.street.selected().customers[0]
	test.check(saved.appearance=="charcoal" and saved.budget==guest.budget and saved.quoted==guest.quoted and saved.planned_rounds==guest.planned_rounds and restored.rng.state==rng_before,"Reload preserves identity, quote, budget, visit plan and RNG")
	var directions := {}
	for closeup in [false,true]:
		for second in range(180):
			for item in StreetView.traffic(7,second,closeup):
				if item.id.begins_with("street-charcoal"):
					directions[item.facing] = true
					test.check(item.frame<Art.atlas_specs()[item.id][1],"Reference guest walk frames remain in bounds")
	test.check(directions.size()==4,"Reference guest can walk both district directions and approach/depart the bar")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
