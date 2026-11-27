extends RefCounted

const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var st = m.street
	var bar: Dictionary = st.selected()
	test.check(not st.afk_enabled(),"AFK defaults off for a fresh campaign")
	m.s.cash = 10000
	st.announce(8)
	var before := JSON.stringify(m.s)
	st.afk_status()
	st.afk_tick()
	test.check(JSON.stringify(m.s)==before,"AFK off and status reads make no purchases")
	st.action("afk")
	var cash_before: int = m.s.cash
	st.afk_tick()
	test.check(m.s.cash==cash_before-450 and m.s.street.event.prepared,"AFK pays the listed Godzilla preparation once")
	st.afk_tick()
	test.check(m.s.cash==cash_before-450,"Repeated AFK ticks do not charge prepared events again")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.afk_enabled(),"AFK preference round-trips through the campaign save")
	loaded.street.afk_tick()
	test.check(loaded.s.cash==m.s.cash,"Reload cannot repay an already-prepared event")
	# Normal live countdown settles paid monster visits without playing or
	# inventing a prize. Empty the room so only ordinary operating costs remain.
	st.economy.clear_visits(bar)
	m.s.street.pass_credit = 0.0
	st.start_event()
	m.s.street.event.remaining = 1
	cash_before = m.s.cash
	var reputation: int = m.s.rep
	st.tick(1)
	test.check(m.s.street.event.is_empty() and bar.closed==0 and m.s.cash<=cash_before and m.s.rep==reputation,"Paid AFK Godzilla ends without repairs, prize money or victory reputation")
	st.announce(9)
	st.start_event()
	cash_before = m.s.cash
	st.afk_tick()
	test.check(m.s.cash==cash_before-1200 and m.s.street.event.prepared,"Enabling AFK during an active festival can pay its listed response")
	m.s.street.event.remaining = 1
	st.tick(1)
	test.check(m.s.street.festival and m.s.street.festivals==1 and bar.closed==0,"AFK festival completes the festival without ending normal play")
	st.tick(1)
	test.check(m.s.street.festivals==1,"AFK festival completion cannot repeat")
	m.s.cash = 0
	st.announce(8)
	st.start_event()
	m.s.street.event.remaining = 1
	st.tick(1)
	test.check(m.s.cash==0 and m.s.street.event.is_empty() and bar.closed==30,"Unaffordable Godzilla takes its ordinary recoverable setback without debt")
	# Paid patrol still clears the real swarm, then catches one straggler/tick.
	m = Campaign.new(72)
	st = m.street
	bar = st.selected()
	m.s.cash = 5000
	st.action("afk")
	st.announce(C.RAT_PLAGUE)
	st.afk_tick()
	test.check(m.s.cash==4880,"AFK rat patrol costs the normal 120 baht")
	st.start_event()
	st.tick(6)
	test.check(st.rat_targets().size()==C.RAT_STRAGGLERS,"AFK retains the normal paid patrol sweep")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game(),"AFK stragglers save successfully")
	loaded.street.tick(C.RAT_STRAGGLERS)
	test.check(loaded.s.street.event.is_empty() and loaded.s.street.events_survived==1,"AFK finishes saved rat stragglers without clicks or duplicated settlement")
	st.action("afk")
	st.tick(10)
	test.check(st.rat_targets().size()==C.RAT_STRAGGLERS,"Turning AFK off restores manual straggler cleanup")
	m = Campaign.new(72)
	st = m.street
	m.s.cash = 0
	st.action("afk")
	st.announce(C.RAT_PLAGUE)
	st.start_event()
	st.afk_tick()
	test.check(m.s.street.event.is_empty() and m.s.day==2 and m.s.street.minute==C.OPEN_MINUTE and m.s.cash==0,"Unaffordable rats use the existing close-for-day recovery without a free trading-time patrol")
	# Every ordinary response uses its normal offer, including staff gates.
	for id in range(C.EVENTS.size()):
		m = Campaign.new(72)
		m.s.cash = 10000
		st = m.street
		st.action("afk")
		st.announce(id)
		st.afk_tick()
		test.check(m.s.street.event.prepared==(id!=C.Local.BED),"AFK respects the normal preparation offer for event %d" % id)
		test.check(m.s.cash==10000-int(C.EVENTS[id][3]),"AFK event %d charges only its listed price" % id)
	# Contracts across the street, including the separate promoter slot, keep
	# training, deadline, rota, identity and price; no other assets are bought.
	m = Campaign.new(72)
	st = m.street
	bar = st.selected()
	m.s.cash = 100000
	st.action("hire",0)
	st.action("hire",3)
	m.s.street.chapter = 2
	m.s.rep = 100
	st.action("buy",1)
	var other: Dictionary = st.selected()
	st.economy.action(other,"hire",1)
	for venue in m.s.street.bars:
		for person in venue.team:
			person.contract_left = 1
			person.training = 1
			person.service_ready = 17.25
	bar.team[1].on = false
	st.economy.advance_contracts(1)
	st.action("afk")
	cash_before = m.s.cash
	var selected: int = m.s.street.selected
	st.afk_tick()
	test.check(m.s.cash==cash_before-6900 and m.s.street.selected==selected,"AFK renews existing staff across venues at exact role prices without navigating")
	test.check(bar.team[0].on and not bar.team[1].on and other.team[0].on,"AFK renewal preserves on- and off-duty rotas")
	for venue in m.s.street.bars:
		for person in venue.team:
			test.check(person.contract_left==C.STAFF_CONTRACT_MINUTES and person.training==1 and person.service_ready==17.25,"AFK renewal retains training and fractional service deadlines")
	cash_before = m.s.cash
	st.afk_tick()
	test.check(m.s.cash==cash_before and bar.team.size()==2 and other.team.size()==1 and bar.stage==1 and not bar.auto_serve and not bar.restock,"AFK does not renew twice, duplicate staff or buy automation/upgrades")
	bar.team[0].contract_left = 0
	m.s.cash = 1199
	st.afk_tick()
	test.check(bar.team[0].contract_left==0 and m.s.cash==1199 and st.afk_status().contains("1 more"),"AFK waits for an unaffordable renewal with the exact shortfall")
	m.s.cash = 1200
	st.afk_tick()
	test.check(bar.team[0].contract_left==C.STAFF_CONTRACT_MINUTES and m.s.cash==0,"AFK retries renewal when exactly the contract price becomes available")
	m.s.phase = "guided_choice"
	before = JSON.stringify(m.s)
	st.afk_tick()
	st.advance(5)
	test.check(JSON.stringify(m.s)==before,"AFK does not bypass an explicitly entered guided decision")
	m.s.phase = "plan"
	# Offline time may expire a contract, but must not pay AFK fees or resolve
	# unseen events; only the next explicit live tick can do that work.
	bar.team[0].contract_left = 10
	m.s.cash = 5000
	st.announce(8)
	var event_before: Dictionary = m.s.street.event.duplicate(true)
	var now := int(Time.get_unix_time_from_system())
	m.s.street.last_seen = now-100
	st.claim_offline(now)
	test.check(m.s.cash==5000 and bar.team[0].contract_left==0 and m.s.street.event==event_before,"AFK never renews contracts or handles unseen incidents offline")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and not loaded.s.street.bars[0].team[1].on,"Renewal rota survives saving and loading")
	# Optional additive fields keep schema 17 saves compatible, defaulting off.
	var old: Dictionary = m.s.duplicate(true)
	old.street.erase("afk")
	for venue in old.street.bars:
		for person in venue.team: person.erase("renew_on")
	write_save(old)
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and not loaded.street.afk_enabled() and loaded.s.cash==m.s.cash,"Existing schema 17 saves migrate AFK off without gifts")
	old.street.afk = "yes"
	write_save(old)
	test.check(loaded._read(Campaign.SAVE)==null,"Malformed AFK preferences are rejected")
	old.street.afk = true
	old.street.bars[0].team[0].renew_on = 1
	write_save(old)
	test.check(loaded._read(Campaign.SAVE)==null,"Malformed saved renewal rotas are rejected")
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
	# Leave a sustainable, already-equipped bar completely unattended over
	# multiple openings and contract expiries. AFK must not invent new assets.
	m = Campaign.new(72)
	st = m.street
	bar = st.selected()
	m.s.cash = 100000
	st.action("hire",0)
	st.action("restock")
	st.action("auto_serve")
	st.action("afk")
	bar.team[0].contract_left = 60
	st.announce(C.RAT_PLAGUE)
	for i in 240: st.tick(60)
	test.check(m.s.day>10 and m.s.street.elapsed==14400 and m.s.phase=="plan" and bar.open and bar.team[0].contract_left>0,"AFK runs unattended through nights, incidents and repeated contract renewals")
	test.check(m.s.street.bars.size()==1 and bar.stage==1 and bar.team.size()==1 and int(bar.shift.sales)+int(bar.last_shift.get("sales",0))>0,"Unattended AFK continues real stocked service without buying progression")

func write_save(state: Dictionary) -> void:
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	file.close()

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.model = Campaign.new(72)
	app.model.s.cash = 10000
	app.model.street.action("afk")
	app.model.street.announce(8)
	var before := JSON.stringify(app.model.s)
	app._process(10)
	test.check(JSON.stringify(app.model.s)==before,"Startup menu with saved AFK on stays fully paused")
	app.boot_menu = false
	app.render()
	test.check(test.find_button(app,"AFK ON")!=null,"Live street exposes a visible AFK stop control")
	before = JSON.stringify(app.model.s)
	app.change_tab(1)
	app.model.street.afk_status()
	test.check(JSON.stringify(app.model.s)==before,"Events navigation and AFK readouts never purchase anything")
	app.news_issue = {"headline":"Old popup","id":8}
	app.supplier_special_open = true
	app.offline_notice = 25
	app._process(1)
	test.check(app.news_issue.is_empty() and not app.supplier_special_open and app.offline_notice==0 and app.model.s.street.elapsed==1 and app.model.s.street.event.prepared,"AFK dismisses blocking notices and advances through real event preparation")
	app.model.s.street.supplier_deal = {"day":1,"venue":0,"drink":2,"seen":false,"bought":false}
	app._process(1)
	test.check(app.model.s.street.supplier_deal.seen and not app.model.s.street.supplier_deal.bought and not app.supplier_special_open,"AFK suppresses supplier specials without buying them")
	app.model.s.day = 7
	app.model.street.celebration_tick()
	app.poll_news()
	app.model.street.selected().raided = true
	app.poll_news()
	test.check(app.news_issue.is_empty(),"AFK celebration and raid notices never open a blocking popup")
	test.use_button(app,"AFK ON")
	test.check(not app.model.street.afk_enabled(),"AFK can be stopped immediately from the HUD")
	app.model.street.announce(2)
	app._process(1)
	test.check(not app.news_issue.is_empty(),"Turning AFK off restores normal incident popups")
	app.close_news(false)
	app.start_tutorial()
	app.tutorial_step = 6
	app.render()
	test.check(has_label(app,"Leaving the game running?"),"Tutorial explains AFK incident handling and the need for purchased automation")
	app.finish_tutorial()
	app.queue_free()
	await test.process_frame

func has_label(node: Node, prefix: String) -> bool:
	if node is Label and node.text.begins_with(prefix): return true
	for child in node.get_children():
		if has_label(child,prefix): return true
	return false
