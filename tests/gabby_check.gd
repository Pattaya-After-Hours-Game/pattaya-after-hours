extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Art = preload("res://scripts/art.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	var before := JSON.stringify(m.s)
	load("res://tests/recruit_fixture.gd").named(m.street,"gabby")
	test.check(b.team.is_empty() and m.s.cash==228,"Gabby hire respects contract cash and reserve")
	m.s.cash = 10000
	load("res://tests/recruit_fixture.gd").named(m.street,"gabby")
	var p: Dictionary = b.team[0]
	test.check(p.identity=="gabby" and p.role==0 and m.s.cash==8800 and Art.worker_id(b,0)=="gabby","Gabby uses a paid bartender slot and her own artwork")
	before = JSON.stringify(b.team)
	load("res://tests/recruit_fixture.gd").named(m.street,"gabby")
	test.check(JSON.stringify(b.team)==before and m.s.cash==8800,"A second hire cannot duplicate Gabby or charge again")
	e.staff_service(b)
	test.check(p.drinks_served==1 and p.service_ready==25 and b.bonus_tips==5 and b.tip_visits==1,"Gabby earns five extra baht only after a real sale")
	var revenue: int = b.shift.revenue
	e.staff_service(b)
	m.street.action("serve")
	test.check(b.bonus_tips==5 and b.shift.revenue==revenue+80,"Cooldown and owner sales earn no Gabby tips; bonuses stay outside trading revenue")
	m.street.action("train_staff",0)
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game(),"Gabby's identity and jar load in the existing schema")
	b = loaded.street.selected()
	e = loaded.street.economy
	p = b.team[0]
	e.staff_service(b)
	test.check(p.identity=="gabby" and p.training==1 and p.service_ready==25 and b.bonus_tips==5,"Reload preserves identity, training, cooldown and unpaid tips without another bonus")
	b.type = 1
	loaded.street.action("role",0)
	test.check(p.role==0,"Gabby retains her bartender contract")
	p.contract_left = 0
	p.on = false
	loaded.street.action("rehire",0)
	test.check(p.identity=="gabby" and p.training==1 and p.service_ready==25,"Renewal retains Gabby's identity, skill and pending service deadline")
	loaded.s.street.elapsed = 25
	b.stock = 0
	e.staff_service(b)
	test.check(b.bonus_tips==5,"Stockouts earn no Gabby tips")
	b.stock = 10
	p.on = false
	e.staff_service(b)
	test.check(b.bonus_tips==5,"Off-duty Gabby earns no tips")
	p.on = true
	e.staff_service(b)
	test.check(b.bonus_tips==10 and p.drinks_served==2,"A later real sale earns the next bonus")
	loaded.s.day = 2
	loaded.s.street.minute = 60
	var money: int = loaded.s.cash
	var expected: int = b.tip_visits*10+b.bonus_tips
	e.settle_tips()
	test.check(loaded.s.cash==money+expected and b.bonus_tips==0 and b.last_tips.bonus==10,"Nightly settlement includes Gabby's actual tips")
	loaded.save_game()
	var paid = Campaign.new(1)
	test.check(paid.load_game(),"Gabby's settled receipt reloads")
	money = paid.s.cash
	paid.street.economy.settle_tips()
	test.check(paid.s.cash==money,"Reload cannot pay Gabby's settled tips twice")
	# Matched-drink tips and Gabby's service bonus are separate entitlements.
	m = Campaign.new(72)
	m.s.cash = 10000
	b = m.street.selected()
	e = m.street.economy
	load("res://tests/recruit_fixture.gd").named(m.street,"gabby")
	b.customers.resize(1)
	var guest: Dictionary = b.customers[0]
	while posmod(hash(Vector3i(int(guest.id),1,-7)),100)>=60: guest.id += 1
	guest.drink = 1
	guest.quoted = e.price(b,1)
	guest.lager_quote = e.price(b)
	e.restock(b,false,1)
	e.staff_service(b)
	test.check(b.bonus_tips==10,"Gabby's bonus stacks with the existing matched-drink bonus")
	guest.order = true
	m.s.street.elapsed = 25
	e.staff_service(b)
	test.check(b.bonus_tips==15 and b.tip_visits==1,"Gabby earns on repeat service without repeating first-visit or matched-drink tips")
	b.customers.clear()
	m.s.street.elapsed = 50
	e.staff_service(b)
	test.check(b.bonus_tips==15,"An empty queue cannot earn Gabby tips")
	b.manager = true
	b.manager_level = 1
	b.restock = true
	b.supplier_level = 1
	m.s.street.last_seen = 1000
	m.street.claim_offline(1100)
	test.check(b.bonus_tips==15 and b.team[0].drinks_served==2,"Managed offline estimates cannot invent Gabby service tips or actual-sale counts")
	m.save_game()
	var repeat_save = Campaign.new(1)
	test.check(repeat_save.load_game() and repeat_save.street.selected().bonus_tips==15,"Gabby's repeated-sale and matched-drink bonuses can exceed five baht per visit and still reload")
	repeat_save.street.action("close_and_count")
	repeat_save.save_game()
	var receipt = Campaign.new(1)
	test.check(receipt.load_game() and receipt.street.selected().last_tips.bonus==15,"Gabby's counted repeat-service receipt also survives reload")
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
	app.model.s.cash = 10000
	app.change_tab(0)
	test.use_button(app,"Team")
	test.use_button(app,"Hire floor staff  ›")
	app.model.s.street.hiring_seed = load("res://tests/recruit_fixture.gd").seed_for(60)
	test.use_button(app,"Hire bartender · ฿1,200")
	var b: Dictionary = app.model.street.selected()
	test.check(b.team.size()==1 and b.team[0].identity=="gabby" and app.model.s.cash==8800,"Random bartender hiring can reveal Gabby through the paid model action")
	app.model.s.street.hiring_seed = 100 # Common recruit for the roster fixture.
	test.use_button(app,"Hire bartender · ฿1,200")
	var roster_before := JSON.stringify(app.model.s)
	test.use_button(app,"Back")
	test.check(app.column.find_child("TeamMember_0",true,false)!=null and app.column.find_child("TeamMember_1",true,false)!=null,"The roster shows both workers as compact entries")
	test.use_button(app,"Bartender 2 · On duty  ›")
	test.check(app.team_member==1 and app.column.find_child("TeamMember_0",true,false)==null,"Only the selected worker’s controls are shown")
	test.use_button(app,"Back")
	test.use_button(app,"Gabby · On duty  ›")
	test.check(app.team_member==0 and JSON.stringify(app.model.s)==roster_before,"Opening details and going back leave the campaign untouched")
	test.use_button(app,"Go off duty")
	test.check(not b.team[0].on,"Gabby's named rota control updates her own slot")
	b.team[0].contract_left = 0
	app.render()
	test.use_button(app,"Rehire Gabby · ฿1,200")
	test.check(b.team[0].on and b.team[0].contract_left==14400 and b.team.size()==2 and b.team[1].on,"Gabby's visible renewal reuses her existing slot")
	b.team[0].contract_left = 11520
	app.render()
	var cash_before: int = app.model.s.cash
	var before := JSON.stringify(app.model.s)
	test.check(app.column.find_child("EndContract",true,false)!=null and JSON.stringify(app.model.s)==before,"Showing the exit quote cannot dismiss or pay staff")
	test.use_button(app,"End contract · refund ฿768")
	test.check(b.team.size()==1 and app.model.s.cash==cash_before+768 and app.model.s.street.former_staff.has("gabby"),"The visible end-contract control settles the approved refund and frees Gabby's slot")

	app.queue_free()
	await test.process_frame
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
