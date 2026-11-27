extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")
const Art = preload("res://scripts/art.gd")
const City = preload("res://scripts/city.gd")

static func seed_for(draw: int) -> int:
	for seed_value in range(1,10000):
		if (seed_value*48271)%2147483647%100==draw: return seed_value
	return 1

func fresh(kind: int = 0) -> RefCounted:
	var m = Campaign.new(72)
	m.s.cash = 200000
	var b: Dictionary = m.street.selected()
	b.type = kind
	b.stage = 3
	return m

func recruit(m: RefCounted, role: int, draw: int) -> Dictionary:
	m.s.street.hiring_seed = seed_for(draw)
	m.street.action("hire",role)
	return m.street.selected().team.back()

func run(test: SceneTree) -> void:
	# Failed actions and repeated readouts cannot spend a roll or create a buyer.
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var before := JSON.stringify(m.s)
	var history: Array = m.s.street.history.duplicate(true)
	var messages: Array = m.s.log.duplicate(true)
	e.hire_offer(b,0)
	e.hiring_odds(0)
	e.hiring_help(0)
	test.check(JSON.stringify(m.s)==before,"Hiring readouts are pure")
	m.street.action("hire",0)
	m.street.action("hire",1)
	m.s.street.history = history
	m.s.log = messages
	test.check(JSON.stringify(m.s)==before,"Hiring reads and unaffordable/wrong-venue hires preserve money, demand and all RNG")
	# Every profile is reachable through the real paid action at ordinary prices.
	for spec in [[0,70,"staff-copper",23],[0,82,"staff-rose",30],[0,94,"staff-ruby",18],[0,99,"staff-platinum",13],[1,70,"host-violet",0],[1,82,"host-goldie",0],[1,94,"host-scarlet",0],[1,99,"host-onyx",0]]:
		m = fresh(spec[0])
		b = m.street.selected()
		e = m.street.economy
		var money: int = m.s.cash
		var traffic_seed: int = m.s.street.economy_seed
		var guests := JSON.stringify(b.customers)
		var stock: int = b.stock
		var p := recruit(m,spec[0],spec[1])
		test.check(p.identity==spec[2] and m.s.cash==money-e.contract_cost(spec[0]),"Paid random hire discovers the expected specialist at the listed contract price")
		test.check(m.s.street.economy_seed==traffic_seed and JSON.stringify(b.customers)==guests and b.stock==stock,"Discovery never manufactures buyers, stock or traffic rolls")
		test.check(Art.worker_id(b,0)==spec[2] and Art.texture("portrait-"+spec[2])!=null,"Every discovery uses its new atlas and portrait")
		if spec[0]==0: test.check(e.service_seconds(p)==spec[3],"Bartenders have the advertised distinct base recovery")
		else: test.check(is_equal_approx(e.host_appeal(p),0.6*float(C.STAFF_TALENTS[spec[2]].appeal)),"Entertainer talents scale real host appeal")
		p.service_ready = 17.25
		p.training = 2
		var identity: String = p.identity
		m.save_game()
		var loaded = Campaign.new(1)
		test.check(loaded.load_game(),"All eight identities round-trip through saved JSON")
		var lp: Dictionary = loaded.street.selected().team[0]
		test.check(lp.identity==identity and lp.service_ready==17.25 and lp.training==2,"Reload preserves talent, training and fractional recovery")
		var hiring_seed: int = loaded.s.street.hiring_seed
		lp.contract_left = 0
		lp.on = false
		loaded.street.action("rehire",0)
		test.check(lp.identity==identity and lp.training==2 and lp.service_ready==17.25 and loaded.s.street.hiring_seed==hiring_seed,"Rehire retains the discovery and its deadline without another draw")
		loaded.street.action("role",0)
		test.check(lp.role==spec[0],"Named specialists retain their role and consistent art")
		var odds: Array = loaded.street.economy.hiring_odds(spec[0])
		test.check(odds.filter(func(choice: Dictionary) -> bool: return choice.identity==identity).is_empty(),"Owned and expired discoveries cannot get a second street slot")
	# Successful hires are deterministic after loading, separate from traffic RNG.
	m = fresh()
	m.s.street.hiring_seed = seed_for(99)
	m.save_game()
	var copy = Campaign.new(1)
	test.check(copy.load_game(),"Pre-hire campaign loads")
	m.street.action("hire",0)
	copy.street.action("hire",0)
	test.check(m.street.selected().team==copy.street.selected().team and m.s.street.hiring_seed==copy.s.street.hiring_seed,"Loading the same pre-hire state gives the same recruit and next stream")
	# A long series of paid hires exercises all tiers, including the rare tail.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	m.s.cash = 2000000
	var counts := {}
	for i in 1000:
		b.team.clear()
		m.street.action("hire",0)
		var id: String = b.team[0].get("identity","")
		counts[id] = int(counts.get(id,0))+1
	test.check(counts.size()==5 and counts.get("",0)>600 and counts.get("staff-platinum",0)>=3 and counts.get("staff-platinum",0)<30,"Paid hiring produces common crew, both uncommon hires, rares and a small legendary tail")
	# Actual service is the only source of bartender talent tips.
	m = fresh()
	b = m.street.selected()
	e = m.street.economy
	var star := recruit(m,0,99)
	var cash_before: int = m.s.cash
	e.staff_service(b)
	test.check(star.drinks_served==1 and star.service_ready==13 and b.talent_tips==15 and m.s.cash==cash_before+80,"Legendary bartender earns exactly one sale and one unpaid fifteen-baht bonus")
	var trading_net: int = m.s.street.earnings_net
	e.staff_service(b)
	test.check(b.talent_tips==15 and m.s.street.earnings_net==trading_net,"Cooldown cannot repeat a sale or include tips in trading samples")
	star.service_ready = 17.25
	m.street.action("train_staff",0)
	test.check(star.service_ready==17.25 and e.service_seconds(star)==10,"Training improves future specialist service while keeping current recovery")
	m.save_game()
	copy = Campaign.new(1)
	test.check(copy.load_game() and copy.street.selected().talent_tips==15,"Unpaid talent tips survive reload")
	var jar: int = e.pending_tips(b)
	cash_before = m.s.cash
	m.street.action("close_and_count")
	test.check(m.s.cash==cash_before+jar and b.talent_tips==0 and b.last_tips.talent==15,"Closing settles real talent tips once and retains their receipt")
	m.street.action("close_and_count")
	test.check(m.s.cash==cash_before+jar,"Repeat closing cannot pay talent tips twice")
	m.save_game()
	test.check(copy.load_game() and copy.street.selected().last_tips.talent==15,"Paid talent receipts round-trip")
	cash_before = copy.s.cash
	copy.street.action("close_and_count")
	test.check(copy.s.cash==cash_before,"Reload cannot repay counted talent tips")
	# Hosted tips need a paid, stocked round; invitation and dance loops pay nothing.
	m = fresh(1)
	b = m.street.selected()
	e = m.street.economy
	star = recruit(m,1,99)
	var guest: Dictionary = b.customers[0]
	b.customers.resize(1)
	guest.drinks = 1
	guest.order = false
	guest.fine_budget = 1000
	guest.host_interest = 1
	var traffic_before: int = m.s.street.economy_seed
	m.street.action("host_drink",0)
	test.check(b.talent_tips==0 and b.host_rounds.size()==1,"Inviting a legendary host creates an order, never an unpaid reward")
	e.serve_hosted(b)
	test.check(b.talent_tips==30 and b.shift.hosted_drinks==1,"A paid real hosted round earns thirty baht of Onyx talent tips")
	e.serve_hosted(b)
	test.check(b.talent_tips==30,"The same hosted round cannot award talent tips twice")
	var attraction: float = e.attraction(b)
	star.on = false
	test.check(attraction>e.attraction(b) and is_equal_approx(e.host_appeal(star),1.8) and m.s.street.economy_seed==traffic_before,"Off-duty star loses her full appeal without altering street traffic")
	# Gogo talents pay only on the first real drink during the normal set.
	m = fresh(2)
	b = m.street.selected()
	e = m.street.economy
	star = recruit(m,2,99)
	var understudy := recruit(m,2,83)
	m.s.street.seconds = 40
	guest = b.customers[0]
	b.customers.resize(1)
	e.staff_service(b)
	test.check(b.sold==0 and b.talent_tips==0,"Even legendary dancers never serve or earn passive tips")
	e.serve(b,1)
	test.check(b.talent_tips==30,"First real drink during the set awards only the strongest dancer's bonus")
	guest.order = true
	e.serve(b,1)
	test.check(b.talent_tips==30,"Repeat rounds do not duplicate the dancer's first-visit bonus")
	star.on = false
	test.check(e.dancer_tip(b)==20,"Off-duty star hands the set bonus to the eligible understudy")
	understudy.contract_left = 0
	test.check(e.dancer_tip(b)==0,"Expired/off-duty dancers cannot earn a set bonus")
	star.on = true
	m.s.street.seconds = 80
	test.check(e.dancer_tip(b)==0,"No dancer tips outside the performance window")
	b.manager = true
	b.restock = true
	m.s.street.last_seen = 1000
	m.street.claim_offline(1100)
	test.check(b.talent_tips==30,"Offline earnings cannot invent talent tips or replay performances")
	# Legacy workers remain ordinary; malformed new optional data fails closed.
	m = fresh()
	e = m.street.economy
	b = m.street.selected()
	e.hire_staff(b,0)
	var legacy: Dictionary = b.team[0].duplicate(true)
	m.save_game()
	test.check(copy.load_game() and copy.street.selected().team[0]==legacy,"Existing staff receive no random talent or changed service on load")
	for invalid in [true,0,-1,1.5,2147483647]:
		m.s.street.hiring_seed = invalid
		m.save_game()
		test.check(m._read(Campaign.SAVE)==null,"Malformed recruitment seed is rejected")
	m.s.street.hiring_seed = 1
	for invalid in [-5,3,true]:
		b.talent_tips = invalid
		m.save_game()
		test.check(m._read(Campaign.SAVE)==null,"Malformed talent tip amounts are rejected")
	b.talent_tips = 0
	var original: Dictionary = b.team[0].duplicate(true)
	for invalid in ["unknown-talent","host-onyx"]:
		b.team[0].identity = invalid
		m.save_game()
		test.check(m._read(Campaign.SAVE)==null,"Unknown identities and talents in the wrong role are rejected")
	b.team[0] = original
	b.team.clear()
	recruit(m,0,99)
	b.team.append(b.team[0].duplicate(true))
	m.save_game()
	test.check(m._read(Campaign.SAVE)==null,"Duplicate named discoveries cannot load into a second roster slot")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.start_new_game()
	app.model.s.cash = 10000
	app.model.s.street.hiring_seed = seed_for(99)
	app.open_service_section("team")
	var before := JSON.stringify(app.model.s)
	test.use_button(app,"Hire floor staff  ›")
	app.model.street.economy.hiring_help(0)
	app.render(true)
	test.check(JSON.stringify(app.model.s)==before,"Team navigation and odds help never roll a recruit")
	app.show_service_help("Hiring odds",app.model.street.economy.hiring_help(0))
	await test.process_frame
	var help_scroll: ScrollContainer = app.service_help_panel.get_node("HelpScroll")
	test.check(help_scroll.get_child(0).text.contains("1% · Platinum · Legendary"),"The scrollable hiring panel contains the exact legendary chance")
	app.close_service_help()
	test.use_button(app,"Hire bartender · ฿1,200")
	var b: Dictionary = app.model.street.selected()
	test.check(b.team[0].identity=="staff-platinum" and app.message.contains("Legendary"),"Visible hire button reveals the legendary recruit and paid stats")
	test.use_button(app,"Back")
	test.use_button(app,"Platinum · On duty  ›")
	test.check(app.team_member==0 and app.column.find_children("*","Label",true,false).any(func(label: Label) -> bool: return label.text.contains("Legendary")),"The recruit’s detail page shows their talent")
	test.use_button(app,"Go off duty")
	test.check(not b.team[0].on,"New staff's named rota controls their own slot")
	b.team[0].contract_left = 0
	app.render()
	test.use_button(app,"Rehire Platinum · ฿1,200")
	test.check(b.team.size()==1 and b.team[0].identity=="staff-platinum" and b.team[0].on,"Visible rehire keeps the same legendary person")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
