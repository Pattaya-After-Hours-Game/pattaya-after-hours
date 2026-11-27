extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Economy = preload("res://scripts/economy.gd")

func run(test: SceneTree) -> void:
	var m := Campaign.new(72)
	m.s.cash = 1000000
	m.s.rep = 100
	m.s.street.chapter = 4
	var first: Dictionary = m.street.selected()
	m.s.street.next_customer = 12
	m.street.economy.admit(first)
	var shotgun: Dictionary = first.customers.back()
	# A second actual venue/Shotgun proves the cooldown and bonus are street-wide.
	m.street.action("buy",1)
	var second: Dictionary = m.street.selected()
	m.s.street.next_customer = 60
	m.street.economy.admit(second)
	var other_shotgun: Dictionary = second.customers.back()
	var legacy: Dictionary = first.customers[0]
	legacy.visit_phase = "legacy"
	legacy.life = 9
	var drinking: Dictionary = first.customers[1]
	drinking.visit_phase = "drinking"
	drinking.next = 19
	m.s.street.selected = 0
	m.s.street.tick_fraction = .25
	var expected: Dictionary = m.s.duplicate(true)
	for bar in expected.street.bars:
		for guest in bar.customers:
			guest.shotgun_patience = 5
			if guest.visit_phase=="legacy": guest.life += 5
	expected.street.shotgun_ready = 30.25
	var rng_before: int = m.rng.state
	var before := JSON.stringify(m.s)
	for i in 3: m.street.economy.shotgun_status(first,shotgun.id)
	test.check(JSON.stringify(m.s)==before,"Shotgun eligibility reads never start cooldown or grant patience")
	m.street.action("shotgun",shotgun.id)
	test.check(m.s==expected and m.rng.state==rng_before,"Shotgun changes exactly the shared cooldown and current guests' patience, including legacy lifetime caps")
	test.check(Economy.order_seconds_left(first,legacy)==14 and drinking.next==19,"Legacy visitors receive the full five seconds; paid drinking deadlines stay unchanged")
	before = JSON.stringify(m.s)
	m.street.action("shotgun",shotgun.id)
	m.s.street.selected = 1
	m.street.action("shotgun",other_shotgun.id)
	m.s.street.selected = 0
	test.check(JSON.stringify(m.s)==before,"Repeat activation and a second venue's Shotgun cannot bypass the shared cooldown")
	test.check(m.save_game()==OK,"Patience bonus and fractional cooldown save")
	var restored := Campaign.new(1)
	test.check(restored.load_game(),"Saved Shotgun bonus and cooldown load")
	test.check(restored.s.street.shotgun_ready==30.25 and restored.street.selected().customers.back().shotgun_patience==5,"Reload preserves exact deadline and granted patience without replay")
	restored.street.action("shotgun",shotgun.id)
	test.check(restored.street.selected().customers.back().shotgun_patience==5,"Reload cannot grant a second bonus during cooldown")
	restored.s.street.elapsed = 30
	restored.s.street.tick_fraction = .2499
	test.check(not restored.street.economy.shotgun_status(restored.street.selected(),shotgun.id).enabled,"Cooldown remains locked just before its exact fractional deadline")
	restored.s.street.tick_fraction = .25
	test.check(restored.street.economy.shotgun_status(restored.street.selected(),shotgun.id).enabled,"Cooldown becomes available at exactly thirty live seconds")
	restored.street.action("shotgun",shotgun.id)
	test.check(restored.street.selected().customers.back().shotgun_patience==10 and restored.s.street.shotgun_ready==60.25,"Another successful activation adds exactly five seconds and starts a fresh thirty-second deadline")
	# New arrivals receive no retroactive bonus; a departing Shotgun cannot activate.
	restored.street.economy.admit(restored.street.selected())
	test.check(restored.street.selected().customers.back().get("shotgun_patience",0)==0,"Future arrivals receive no retroactive patience")
	restored.s.street.elapsed = 61
	var bar: Dictionary = restored.street.selected()
	before = JSON.stringify(restored.s)
	restored.street.action("shotgun",-1)
	test.check(JSON.stringify(restored.s)==before,"Missing or non-Shotgun actors cannot activate the perk")
	for phase in ["incident","report","menu"]:
		restored.s.phase = phase
		before = JSON.stringify(restored.s)
		restored.street.action("shotgun",shotgun.id)
		test.check(JSON.stringify(restored.s)==before,"Paused decisions and menus cannot grant Shotgun patience")
	restored.s.phase = "plan"
	bar.open = false
	before = JSON.stringify(restored.s)
	restored.street.action("shotgun",shotgun.id)
	test.check(JSON.stringify(restored.s)==before,"Closed venues cannot activate Shotgun")
	# Verify the actual order-expiry loop, rather than only the displayed numbers.
	var live := Campaign.new(72)
	var room: Dictionary = live.street.selected()
	room.customers.clear()
	live.s.street.next_customer = 12
	live.street.economy.admit(room)
	var waiting: Dictionary = room.customers[0]
	waiting.wait = Economy.patience(room,waiting)
	live.street.action("shotgun",waiting.id)
	live.street.tick(5)
	test.check(waiting.order and not waiting.missed,"A waiting order survives five more real simulation seconds")
	live.street.tick(1)
	test.check(waiting.missed,"The same order still expires after its extended patience runs out")
	# Optional additive schema-17 fields reject malformed data and remain absent
	# in old saves, without resetting a visit or gifting a bonus.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.SAVE))
	var invalid_path := "user://shotgun-invalid.json"
	for field in ["shotgun_ready","shotgun_patience"]:
		for bad in [true,"5",-1,null]+([1.5] if field=="shotgun_patience" else []):
			var copy: Dictionary = data.duplicate(true)
			if field=="shotgun_ready": copy.street[field] = bad
			else: copy.street.bars[0].customers[0][field] = bad
			var file := FileAccess.open(invalid_path,FileAccess.WRITE)
			file.store_string(JSON.stringify(copy))
			file.close()
			test.check(Campaign.new(1)._read(invalid_path)==null,"Malformed optional Shotgun fields are rejected")
	data.street.erase("shotgun_ready")
	for venue in data.street.bars:
		for guest in venue.customers: guest.erase("shotgun_patience")
	var file := FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	test.check(Campaign.new(1)._read(invalid_path)!=null,"Existing schema-17 saves without Shotgun bonus fields remain valid")
	for path in [Campaign.SAVE,Campaign.BACKUP,invalid_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
