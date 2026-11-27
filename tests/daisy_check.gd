extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const C = preload("res://scripts/street_content.gd")
const Art = preload("res://scripts/art.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	m.s.cash = 200000
	m.s.rep = 100
	m.s.street.chapter = 2
	var b: Dictionary = m.street.selected()
	m.street.action("hire_daisy")
	test.check(b.team.is_empty() and m.s.cash==200000,"Daisy cannot be hired into a beer bar")
	load("res://tests/finance_fixture.gd").buy(m.street,1)
	b = m.street.selected()
	var e = m.street.economy
	m.s.cash = 4499
	var money: int = m.s.cash
	m.street.action("hire_daisy")
	test.check(b.team.is_empty() and m.s.cash==money,"Daisy requires the full host contract price")
	m.s.cash += 1
	money = m.s.cash
	m.street.action("hire_daisy")
	var p: Dictionary = b.team[0]
	test.check(p.host==C.DAISY_HOST and p.role==1 and m.s.cash==money-4500 and Art.worker_id(b,0)=="daisy","Daisy uses a paid host slot and her own artwork")
	money = m.s.cash
	m.street.action("hire_daisy")
	test.check(b.team.size()==1 and m.s.cash==money,"Daisy cannot be duplicated or charged twice")
	m.street.action("role",0)
	test.check(p.role==1 and p.host==C.DAISY_HOST,"Daisy keeps her entertainer identity")
	m.s.cash = 200000
	m.street.action("hire_gabby")
	test.check(b.team.size()==2 and b.team[1].identity=="gabby" and Art.worker_id(b,1)=="gabby","Daisy and Gabby remain separate people with separate roles")
	b.team[1].on = false
	e.admit(b,false,false,2)
	var sold: int = b.sold
	e.staff_service(b)
	test.check(b.sold==sold and b.bonus_tips==0,"Daisy attracts but cannot serve or earn Gabby's bartender tips")
	var appeal: float = e.attraction(b)
	p.on = false
	test.check(e.attraction(b)<appeal,"Daisy's rota removes her attraction")
	p.on = true
	b.stage = 2
	m.street.action("train_host",0)
	var guest: Dictionary = b.customers.back()
	guest.drinks = 2
	guest.order = false
	guest.fine_budget = 1000
	b.host_requests.append(int(guest.id))
	m.street.action("bar_fine",0)
	test.check(b.away==[0] and b.shift.bar_fine_income==750,"Daisy uses trained host fees and an actual guest request")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game(),"Daisy's stable host ID survives a save round trip")
	b = loaded.street.selected()
	p = b.team[0]
	test.check(p.host==C.DAISY_HOST and p.host_training==1 and b.away==[0] and p.host_return==30,"Reload retains Daisy's training and active booking")
	p.contract_left = 0
	p.on = false
	loaded.street.action("rehire",0)
	test.check(b.team.size()==2 and p.host==C.DAISY_HOST and p.host_training==1 and p.contract_left==14400 and p.host_return==30,"Renewal keeps Daisy's slot, training and return deadline")
	load("res://tests/finance_fixture.gd").buy(loaded.street,1)
	var other: Dictionary = loaded.street.selected()
	money = loaded.s.cash
	loaded.street.action("hire_daisy")
	test.check(other.team.is_empty() and loaded.s.cash==money,"Daisy has only one roster place across the street")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.muted = true
	app.start_new_game()
	app.show_tutorial_hint = false
	app.model.s.cash = 200000
	app.model.s.rep = 100
	app.model.s.street.chapter = 2
	load("res://tests/finance_fixture.gd").buy(app.model.street,1)
	app.open_service_section("team")
	test.use_button(app,"Hire floor staff  ›")
	test.use_button(app,"Hire Daisy · ฿4,500")
	var b: Dictionary = app.model.street.selected()
	test.check(b.team.size()==1 and b.team[0].host==C.DAISY_HOST,"Daisy's visible hire control purchases her host contract")
	test.use_button(app,"Back")
	test.use_button(app,"Daisy · On duty  ›")
	test.use_button(app,"Go off duty")
	test.check(not b.team[0].on,"Daisy's named rota works")
	b.team[0].contract_left = 0
	app.render()
	test.use_button(app,"Rehire Daisy · ฿4,500")
	test.check(b.team.size()==1 and b.team[0].on and b.team[0].contract_left==14400,"Daisy's renewal control reuses her saved slot")
	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
