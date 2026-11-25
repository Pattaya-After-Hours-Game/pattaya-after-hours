extends RefCounted

const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var model = Campaign.new(72)
	var street = model.street
	# Play the first arc with the real opening budget and no optional tours/rig.
	street.action("upgrade")
	street.action("hire")
	street.action("restock")
	street.action("manager")
	street.action("prepare")
	for _minute in 3: street.tick(60)
	test.check(model.s.street.chapter == 1 and model.s.street.served >= 10,"Reopening, regulars and Dao complete the first chapter")
	var rounds := 0
	while model.s.cash < street.purchase_cost(1) and rounds < 60:
		street.tick(60)
		rounds += 1
	street.action("buy",1)
	test.check(model.s.street.bars.size() == 2 and model.s.street.chapter == 2,"First playable arc buys a Soi bar through idle trade")
	test.check(model.s.rig == 0 and model.s.bookings.is_empty(),"Tours and crypto never gate progress")
	# Stock depletion and automatic supplies use the real ledger.
	var bar: Dictionary = street.selected()
	bar.stock = 0
	var cash_before := int(model.s.cash)
	street.action("serve")
	test.check(model.s.cash == cash_before,"An empty fridge cannot produce money")
	model.s.cash = 1000000
	street.action("hire")
	street.action("hire")
	street.action("restock")
	street.action("serve")
	test.check(bar.stock == street.capacity(bar)-1,"Automatic delivery refills before service")
	var old_cash := int(model.s.cash)
	street.action("bar_fine",1)
	test.check(bar.away.is_empty() and model.s.cash == old_cash,"A host's refusal is respected without income")
	street.action("bar_fine",0)
	test.check(bar.away == [0] and street.available(bar) == 1,"Accepted bar fine removes the host from service")
	old_cash = model.s.cash
	street.action("bar_fine",0)
	test.check(model.s.cash == old_cash,"An unavailable host cannot be booked twice")
	street.end_shift()
	test.check(bar.away.is_empty() and street.available(bar) == 2,"Hosts return the next shift")
	street.action("upgrade")
	street.action("manager")
	test.check(model.s.street.chapter == 3,"Two managers and a Soi venue unlock the neon chapter")
	model.s.rep = 45
	street.action("buy",2)
	street.action("hire")
	street.action("upgrade")
	test.check(model.s.street.chapter == 4,"Gogo showroom unlocks the final chapter")
	# Every upgrade remains its original type and increases earning potential.
	for i in model.s.street.bars.size():
		model.s.street.selected = i
		bar = street.selected()
		var kind := int(bar.type)
		while bar.stage < 3:
			var rate := int(street.net_rate(bar,true))
			street.action("upgrade")
			test.check(bar.type == kind and (not bar.manager or street.net_rate(bar,true) > rate),"Stage upgrade retains type and improves earnings")
		old_cash = model.s.cash
		street.action("upgrade")
		test.check(bar.stage == 3 and model.s.cash == old_cash,"Max-stage renovation cannot charge again")
	test.check(street.festival_ready(),"A mixed fully upgraded street qualifies for the festival")
	model.s.street.event = {}
	street.action("festival")
	test.check(model.s.street.event.id == 9 and model.s.street.event.phase == "warning","Festival is announced before its boss")
	street.action("prepare")
	street.tick(60)
	model.start_street_boss()
	test.check(model.s.phase == "godzilla","Festival uses the playable Godzilla encounter")
	model.finish_godzilla(true)
	test.check(model.s.street.chapter == 5 and model.s.street.festival and model.s.phase == "plan","Festival completes the story without ending play")
	street.action("festival")
	test.check(model.s.street.event.id == 9,"Festival can be hosted again")
	# Offline credit is capped, repeat-safe, manager-only, and doesn't advance events.
	model.s.street.last_seen = 1000
	var snapshot: Dictionary = model.s.street.event.duplicate(true)
	var day := int(model.s.day)
	var expected := int(street.total_rate(true) * 480)
	test.check(street.claim_offline(1000+86400) == expected,"Offline profit is capped at eight hours")
	test.check(model.s.day == day and model.s.street.event == snapshot,"Offline time cannot trigger disasters or advance the calendar")
	test.check(street.claim_offline(1000+86400) == 0,"The same absence is never credited twice")
	test.check(street.claim_offline(900) == 0 and model.s.street.last_seen == 87400,"Clock rollback cannot create income")
	model.s.street.bars[0].closed = 20
	test.check(street.net_rate(model.s.street.bars[0],true) == 0,"Existing closures cannot earn offline")
	model.s.street.bars[1].away = [0]
	var one_host_rate := int(street.net_rate(model.s.street.bars[1],true))
	model.s.street.bars[1].away.clear()
	test.check(street.net_rate(model.s.street.bars[1],true) == one_host_rate*2,"Offline profit honours existing host absence")
	for item in model.s.street.bars: item.manager = false
	model.s.street.last_seen = 0
	test.check(street.claim_offline(100) == 0,"Unmanaged bars earn nothing offline")
	# All announced events, including recoverable failure and protective neighbours.
	for id in Content.EVENTS.size():
		model = Campaign.new(72)
		model.street.announce(id)
		model.street.tick(59)
		test.check(model.s.street.event.phase == "warning","Event %d allows preparation" % id)
		model.street.action("prepare")
		model.street.tick(1)
		test.check(model.s.street.event.phase == "active" and model.street.selected().closed == 0,"Prepared event %d opens safely" % id)
		model.street.tick(60)
		model.street.tick(30)
		test.check(model.s.street.event.is_empty() and model.s.street.events_survived == 1,"Event %d resolves once" % id)
	model = Campaign.new(72)
	model.s.license = 20
	model.street.announce(2)
	model.street.start_event()
	test.check(model.street.selected().closed == 40 and model.s.cash < 6400,"Unprepared inspection has a fine and recoverable closure")
	model.street.tick(40)
	test.check(model.street.selected().closed == 0,"Inspection closure expires")
	model.s.trust = 70
	model.street.announce(3)
	model.street.start_event()
	test.check(model.street.selected().closed == 0,"Helpful neighbours protect the flood response")
	# Reputation and chapter requirements cannot be bypassed by cash alone.
	model = Campaign.new(72)
	model.s.cash = 1000000
	model.street.action("buy",2)
	test.check(model.s.street.bars.size() == 1,"Opening chapter gates expansion")
	model.s.street.chapter = 1
	model.street.action("buy",2)
	test.check(model.s.street.bars.size() == 1,"Gogo requires reputation as well as cash")
	model.s.rep = 100
	for i in 7: model.street.action("buy",i%3)
	model.street.action("buy",0)
	test.check(model.s.street.bars.size() == 8,"Eight distinct street properties fit the map")
	# Version-one migration preserves money, staff, progress and a second lease.
	model = Campaign.new(72)
	model.s.erase("street")
	model.s.version = 1
	model.s.level = 4
	model.s.venue = 2
	model.s.phase = "end"
	model.s.day = 365
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(model.s))
	file.close()
	var loaded = Campaign.new(9)
	test.check(loaded.load_game(),"Version-one save loads")
	test.check(loaded.s.version == 2 and loaded.s.street.bars.size() == 2 and loaded.s.street.bars[0].stage == 3,"Legacy renovations and lease migrate")
	test.check(loaded.s.cash == 6400 and loaded.s.staff.size() == 3 and loaded.s.phase == "plan","Legacy finances, team and ended campaigns survive migration")
	loaded.s.street.event = {"id":3,"phase":"warning","remaining":23,"prepared":true}
	loaded.s.street.bars[1].away = [0]
	loaded.save_game()
	var reloaded = Campaign.new(2)
	test.check(reloaded.load_game() and reloaded.s.street.event.remaining == 23 and reloaded.s.street.event.prepared,"Pending event and preparation round-trip")
	test.check(reloaded.s.street.bars[1].away == [0],"Host absence survives a reload")
	loaded.save_game()
	file = FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string('{"version":2,"staff":[],"phase":"plan"}')
	file.close()
	test.check(Campaign.new().load_game(),"Incomplete version-two save falls back to backup")
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
