extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const City = preload("res://scripts/city.gd")

func run(test: SceneTree) -> void:
	var model := Campaign.new(72)
	var city := City.new()
	city.bars = model.s.street.bars
	city.street_state = model.s.street
	var bar: Dictionary = model.street.selected()
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
				test.check(guest.foot.x>=240 and guest.foot.x<840,"Indoor guest stays out of street and fridge")
				test.check(guest.foot.y+4*City.person_scale(guest.foot.y)<373,"Guest feet clear the property dock")
				test.check(City.order_position(guest).y<guest.foot.y-180*City.person_scale(guest.foot.y),"Waiting-order marker is above the silhouette")
				test.check(City.person_scale(418)/City.person_scale(guest.foot.y)<1.35,"Anong and interior guests have comparable adult proportions")
			test.check(JSON.stringify(model.s)==before,"Scene layout never changes customers or the ledger")
			bar.open = false
			test.check(city.scene_people(bar).is_empty(),"Closed venue has no working team or indoor crowd")
			bar.open = true
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
		var index := -1
		for i in bar.customers.size():
			if bar.customers[i].id==player: index = i
		var pose: int = index%4
		var old := people_before.filter(func(p: Dictionary) -> bool: return p.pose==pose)
		var current := people_after.filter(func(p: Dictionary) -> bool: return p.pose==pose)
		test.check(old[0].foot==current[0].foot,"Surviving pool game stays at its table")
	for table in 2:
		test.check(City.pool_rect(table).position.x>230 and City.pool_rect(table).end.x<650,"Both pool tables are indoors")
	city.free()
