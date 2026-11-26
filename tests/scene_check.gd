extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const City = preload("res://scripts/city.gd")
const Art = preload("res://scripts/art.gd")

func run(test: SceneTree) -> void:
	# Successive crossings must not replay the same person or change their
	# appearance halfway through. Rebuilding the view uses the same clock.
	var street_looks := {}
	for crossing in 6:
		var first := City.passerby_at(crossing*24+2)
		var middle := City.passerby_at(crossing*24+10)
		var last := City.passerby_at(crossing*24+18)
		street_looks[middle.pose] = true
		test.check(first.pose==last.pose and first.flip==last.flip,"Passerby identity and facing stay stable during a crossing")
		test.check(middle==City.passerby_at(crossing*24+10),"Scene refresh preserves the current passerby")
		test.check(middle.pose!=City.passerby_at((crossing+1)*24+10).pose,"Consecutive crossings use different people")
		test.check((last.foot.x<first.foot.x)==first.flip,"Passerby faces their travel direction")
		for sample in 25:
			var walker := City.passerby_at(crossing*24+sample)
			test.check(walker.foot.x>=120 and walker.foot.x<=185,"Passerby remains in the outside lane")
		test.check(City.passerby_at(crossing*24+22).alpha==0,"Street has a clear gap between passersby")
	test.check(street_looks.size()==3,"Street cycles through three distinct patron appearances")
	var model := Campaign.new(72)
	var city := City.new()
	city.bars = model.s.street.bars
	city.street_state = model.s.street
	var bar: Dictionary = model.street.selected()
	var appearances := {}
	# Ownership, not renovation or rendering, controls the fan.
	test.check(not City.fan_owned(bar),"Opening bar has no purchased fan")
	model.street.action("equipment",1)
	test.check(not City.fan_owned(bar),"Failed comfort purchase does not display a fan")
	bar.stage = 3
	test.check(not City.fan_owned(bar),"Renovation alone does not grant a fan")
	model.s.cash = 10000
	model.street.action("equipment",1)
	test.check(City.fan_owned(bar),"Comfort purchase installs the fan")
	var saved_bar: Dictionary = JSON.parse_string(JSON.stringify(bar))
	test.check(City.fan_owned(saved_bar),"Saved equipment ownership retains the installed fan")
	bar.open = false
	test.check(City.fan_owned(bar),"Closure retains the owned fan")
	bar.open = true
	bar.equipment.comfort = 0
	# A purchase, not a renovation, enables the sports screen; existing save
	# ownership works without another payment or a new save field.
	model.s.cash = 0
	model.street.action("equipment",5)
	test.check(not City.screen_owned(bar),"Failed TV purchase leaves the room unequipped")
	model.s.cash = 10000
	model.street.action("equipment",5)
	test.check(City.screen_owned(bar),"Buying a sports screen enables its artwork")
	model.save_game()
	var loaded := Campaign.new()
	test.check(loaded.load_game() and City.screen_owned(loaded.street.selected()),"TV artwork follows saved ownership after reload")
	bar.open = false
	test.check(City.screen_owned(bar),"Closing does not uninstall the TV")
	bar.open = true
	var customer: Dictionary = bar.customers[0]
	customer.wait = 34
	test.check(marker_color(city,bar,customer.id)==City.GOLD,"Opening guest stays yellow with eleven seconds of patience")
	customer.wait = 35
	test.check(marker_color(city,bar,customer.id)==City.ORDER_URGENT,"Waiting marker becomes red at ten seconds remaining")
	bar.equipment.comfort = 1
	test.check(marker_color(city,bar,customer.id)==City.GOLD,"Comfort's extra patience delays the red warning")
	bar.equipment.comfort = 0
	model.street.action("chat")
	test.check(customer.chatted and marker_color(city,bar,customer.id)==City.GOLD,"Successful Chat updates the marker from the extended patience")
	customer.visit_phase = "legacy"
	customer.life = 10
	test.check(marker_color(city,bar,customer.id)==City.ORDER_URGENT,"A visit ending soon is urgent even with order patience left")
	model.street.action("serve")
	var served: Dictionary = city.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.get("customer_id",-1)==customer.id)[0]
	test.check(not served.order,"Serving removes the warning rather than leaving a red dot")
	# Rendering is a read-only view of real orders, even at full occupancy.
	for kind in 3:
		for stage in range(1,4):
			bar.type = kind
			bar.stage = stage
			bar.equipment.seating = 2
			bar.customers.clear()
			while bar.customers.size()<model.street.economy.seats(bar):
				model.street.economy.admit(bar)
			bar.team = [{"role":0,"on":true,"host":-1},{"role":1,"on":true,"host":1},{"role":2,"on":false,"host":-1}]
			bar.crew = 3
			bar.away = [1]
			var before := JSON.stringify(model.s)
			var people := city.scene_people(bar)
			var guests := people.filter(func(p: Dictionary) -> bool: return p.customer)
			var staff := people.filter(func(p: Dictionary) -> bool: return not p.customer)
			test.check(guests.size()==bar.customers.size(),"Scene shows every real guest at each venue stage")
			test.check(staff.size()==1 and staff[0].behind_bar,"Only available bartender appears behind the counter")
			test.check(people.filter(func(p: Dictionary) -> bool: return p.order).size()==model.street.economy.pending(bar),"Visible markers match actual waiting orders")
			for guest in guests:
				appearances["%s/%d" % Art.customer_sprite(guest.customer_id)] = true
				test.check(guest.foot.x>=240 and guest.foot.x<840,"Indoor guest stays out of street and fridge")
				test.check(guest.foot.y+4*City.person_scale(guest.foot.y)<373,"Guest feet clear the property dock")
				test.check(City.order_position(guest).y<guest.foot.y-180*City.person_scale(guest.foot.y),"Waiting-order marker is above the silhouette")
				test.check(City.person_scale(418)/City.person_scale(guest.foot.y)<1.35,"Anong and interior guests have comparable adult proportions")
			test.check(JSON.stringify(model.s)==before,"Scene layout never changes customers or the ledger")
			bar.open = false
			test.check(city.scene_people(bar).is_empty(),"Closed venue has no working team or indoor crowd")
			bar.open = true
			model.s.street.minute = 60
			test.check(city.scene_people(bar).is_empty(),"Scheduled closing hides the team and crowd in the perspective scene")
			bar.late_open = true
			test.check(not city.scene_people(bar).is_empty(),"Late permission keeps the perspective scene operating")
			bar.raided = true
			test.check(city.scene_people(bar).is_empty(),"Raid closure hides people despite late permission")
			bar.raided = false
			bar.late_open = false
			model.s.street.minute = 720
	test.check(appearances.size()==Art.CUSTOMER_VARIANTS.size()+2 and appearances.has("patrons-capybara/0") and appearances.has("patrons-rainbow-duo/0"),"Live crowds can display all guest appearances, including both companion sprites")
	# Stable table identities must survive completion of an earlier game.
	bar.type = 0
	bar.stage = 2
	bar.equipment.pool = 2
	bar.customers.clear()
	bar.games.clear()
	for i in 4:
		model.street.economy.admit(bar)
		bar.customers.back().pool = true
	model.street.economy.pool_tick(bar)
	var people_before := city.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.customer)
	bar.games[0].remaining = 1
	model.street.economy.pool_tick(bar)
	var people_after := city.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.customer)
	# The two players at the surviving table keep their positions.
	for player in bar.games[0].players:
		var old := people_before.filter(func(p: Dictionary) -> bool: return p.customer_id==player)
		var current := people_after.filter(func(p: Dictionary) -> bool: return p.customer_id==player)
		test.check(old[0].foot==current[0].foot,"Surviving pool game stays at its table")
	# Departure, reordering and JSON save representation do not change identities.
	bar.customers.pop_front()
	bar.customers.reverse()
	bar.customers = JSON.parse_string(JSON.stringify(bar.customers))
	var remaining := city.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.customer)
	for guest in remaining:
		var original: Dictionary = people_before.filter(func(p: Dictionary) -> bool: return p.customer_id==guest.customer_id)[0]
		test.check(guest.who==original.who and guest.pose==original.pose and guest.flip==original.flip,"Customer appearance survives departures, queue order and saved IDs")
	for table in 2:
		test.check(City.pool_rect(table).position.x>230 and City.pool_rect(table).end.x<650,"Both pool tables are indoors")
	city.free()

func marker_color(city: Control, bar: Dictionary, id: int) -> Color:
	var person: Dictionary = city.scene_people(bar).filter(func(p: Dictionary) -> bool: return p.get("customer_id",-1)==id)[0]
	return City.order_color(person.order_seconds_left)
