extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const E = preload("res://scripts/economy.gd")
const C = preload("res://scripts/street_content.gd")

func fresh() -> RefCounted:
	var m = Campaign.new(72)
	m.s.street.pass_credit = -10000000
	return m

func run(test: SceneTree) -> void:
	cooldowns(test)
	chat(test)
	upgrades(test)
	saves(test)
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)

func cooldowns(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.street.advance(0.37)
	m.street.action("serve")
	for _i in 100: m.street.action("serve")
	test.check(b.sold==1 and is_equal_approx(b.serve_ready,10.37),"Serve consumes one real order and sets an exact ten-second deadline")
	m.street.advance(9.99)
	test.check(not e.action_status(b,"serve").enabled and b.sold==1,"Serve cannot complete even slightly early")
	m.street.advance(0.01)
	test.check(e.action_status(b,"serve").enabled,"Serve becomes ready exactly ten seconds after a fractional start")
	m.street.action("serve")
	test.check(b.sold==2 and b.stock==16,"Next serve consumes one stock unit")
	m.street.action("welcome")
	test.check(b.welcome==1 and not e.action_status(b,"chat").enabled,"Welcome starts the social cooldown independently of Serve")
	var now: float = e.action_time()
	m.s.phase = "guided_choice"
	m.street.advance(20.5)
	m.street.tick(20)
	test.check(is_equal_approx(now,e.action_time()),"Decision screens pause integer and fractional action time")
	m.pick(0)
	test.check(b.sold==2 and m.s.phase=="guided","Guided service cannot bypass a running cooldown")
	m.street.action("open")
	m.street.advance(10)
	test.check(e.action_status(b,"serve").remaining==0 and not e.action_status(b,"serve").enabled,"Closed-hour foreground time refills, but closure still blocks use")
	m.s.phase = "plan"
	m.s.street.minute = 60
	now = e.action_time()
	m.street.action("skip")
	test.check(e.action_time()==now,"Skipping to noon never refills actions")
	m.street.action("open")
	b.customers.clear()
	var before: Array = [m.s.cash,b.stock,b.serve_ready]
	m.street.action("serve")
	test.check(before==[m.s.cash,b.stock,b.serve_ready],"No-order attempt consumes neither stock nor cooldown")
	e.admit(b)
	b.stock = 0
	before = [m.s.cash,b.serve_ready]
	m.street.action("serve")
	test.check(before==[m.s.cash,b.serve_ready],"Stockout attempt does not consume cooldown")
	b.restock = true
	m.s.cash = C.STOCK_COST
	test.check(not e.action_status(b,"serve").enabled,"Automatic delivery availability includes its required operating cash")
	m.s.cash = 1000
	m.street.action("serve")
	test.check(b.sold==3 and b.stock>0,"Paid automatic delivery can fulfil a manual order")
	m = fresh()
	b = m.street.selected()
	m.s.cash = 10000
	m.street.action("hire",0)
	m.street.advance(20)
	m.street.action("serve")
	m.street.advance(5)
	test.check(b.sold==2 and not m.street.economy.action_status(b,"serve").enabled,"Bartenders serve during the owner's cooldown")
	# Owner-run recovery remains viable without chat, upgrades or free income.
	m = fresh()
	b = m.street.selected()
	m.s.cash = 0
	m.street.tick(4)
	b.stock = 0
	m.street.action("recovery")
	m.street.economy.admit(b)
	m.street.action("serve")
	test.check(m.s.cash==41 and b.consignment==5,"Recovery still earns only a real sale less its consignment cost")

func chat(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	test.check(not e.action_status(b,"chat").enabled,"Chat is unavailable while all guests are comfortable")
	b.customers[0].wait = 36
	b.customers[1].wait = 42
	b.customers[2].wait = 40
	var guest: Dictionary = b.customers[1]
	var life := int(guest.life)
	var before: Array = [m.s.cash,b.stock,b.happy,b.regulars,b.sold,b.welcome]
	m.street.action("chat")
	test.check(guest.chatted and not b.customers[0].chatted and guest.life==life+10 and e.patience(b,guest)==55,"Chat targets the guest nearest departure and adds ten seconds once")
	test.check(before==[m.s.cash,b.stock,b.happy,b.regulars,b.sold,b.welcome],"Chat grants no sales, satisfaction, regulars or attraction")
	m.street.action("chat")
	m.street.action("welcome")
	test.check(b.welcome==0 and guest.life==life+10 and is_equal_approx(b.welcome_ready,20),"Chat locks both social actions for twenty seconds")
	test.check(e.action_status(b,"serve").enabled,"Chat does not lock manual service")
	b.customers = [guest]
	guest.wait = 20
	guest.life = 100
	m.street.advance(20)
	test.check(e.action_status(b,"welcome").enabled,"Welcome returns after Chat's full recovery")
	guest.order = true
	guest.missed = false
	guest.wait = 50
	guest.life = 20
	test.check(e.chat_target(b).is_empty(),"A chatted customer cannot be reassured a second time, even on another order")
	guest.chatted = false
	guest.missed = true
	test.check(e.chat_target(b).is_empty(),"Chat cannot restore a missed order")
	# A nearly finished visit also qualifies, even if its order is new.
	guest.missed = false
	guest.wait = 0
	guest.life = 5
	test.check(e.chat_target(b)==guest,"Chat accounts for visit expiry as well as order patience")

func upgrades(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.s.cash = C.ACTION_UPGRADE_COSTS[0]+e.operating_rate(b)*2-1
	m.street.action("action_upgrade",0)
	test.check(b.action_levels.pouring==0,"Action purchase preserves next shift's reserve")
	m.s.cash += 1
	m.street.action("serve")
	var deadline: float = b.serve_ready
	var duration: float = b.serve_duration
	m.street.action("action_upgrade",0)
	test.check(b.action_levels.pouring==1 and b.serve_ready==deadline and b.serve_duration==duration,"Buying an upgrade does not shorten or reset the running refill")
	m.s.cash = 100000
	for level in range(1,4):
		if level>1: m.street.action("action_upgrade",0)
		m.street.action("action_upgrade",1)
		test.check(e.action_cooldown(b,"serve")==C.ACTION_COOLDOWNS[level] and e.action_cooldown(b,"welcome")==C.ACTION_COOLDOWNS[level],"Both tracks apply the chosen tier %d" % level)
	var cash_before := int(m.s.cash)
	m.street.action("action_upgrade",0)
	m.street.action("action_upgrade",1)
	m.street.action("action_upgrade",9)
	test.check(m.s.cash==cash_before,"Maxed and invalid upgrade purchases cannot charge")
	m.street.advance(10)
	m.street.action("serve")
	m.street.action("welcome")
	test.check(b.serve_duration==4 and b.welcome_duration==4,"Next uses receive four-second fully upgraded cooldowns")
	m.street.advance(4)
	b.customers.back().wait = 40
	m.street.action("chat")
	test.check(b.welcome_duration==20,"Welcome upgrades never reduce chat recovery")
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("buy",0)
	var other: Dictionary = m.street.selected()
	test.check(other.action_levels.pouring==0 and other.action_levels.welcoming==0 and e.action_status(other,"welcome").enabled,"New venues start with independent base upgrades and ready timers")
	e.admit(other)
	m.street.action("serve")
	test.check(other.serve_duration==10 and b.serve_duration==4,"Property switching neither transfers upgrades nor resets deadlines")

func saves(test: SceneTree) -> void:
	var m = fresh()
	var b: Dictionary = m.street.selected()
	m.street.advance(0.37)
	b.customers[0].wait = 40
	m.street.action("chat")
	m.street.action("serve")
	m.street.advance(2.17)
	m.s.cash = 10000
	m.street.action("action_upgrade",0)
	m.save_game()
	var loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.s.street==m.s.street,"Schema-five round-trip preserves fractions, deadlines, upgrades and chat allowance")
	var before: Dictionary = loaded.s.street.duplicate(true)
	loaded.street.claim_offline(int(loaded.s.street.last_seen)+3600)
	test.check(loaded.s.street.tick_fraction==before.tick_fraction and loaded.s.street.elapsed==before.elapsed and loaded.street.selected().serve_ready==before.bars[0].serve_ready and loaded.street.selected().customers==before.bars[0].customers,"Offline claims do not refill or replay actions or chats")
	# Actual v4 shape: remove all new fields before exercising the old validator.
	m = fresh()
	b = m.street.selected()
	b.serve_ready = 1
	b.welcome_ready = 10
	b.equipment.pool = 1
	for customer in b.customers: customer.pool = true
	m.street.economy.pool_tick(b)
	var games: Array = b.games.duplicate(true)
	m.s.version = 4
	m.s.street.erase("tick_fraction")
	for key in E.action_fields(): b.erase(key)
	for customer in b.customers:
		for key in E.customer_action_fields(): customer.erase(key)
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(m.s))
	file.close()
	loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.s.version==11,"A genuine v4 campaign migrates to v11")
	b = loaded.street.selected()
	test.check(b.serve_ready==1 and b.welcome_ready==10 and b.action_levels.pouring==0 and b.games==games and b.customers.size()==3 and not b.customers[0].chatted,"Migration preserves pending deadlines and paid games without granting upgrades or resetting customers")
	loaded.save_game()
	loaded.save_game()
	b.action_levels.pouring = 5
	file = FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(loaded.s))
	file.close()
	var recovered = Campaign.new(9)
	test.check(recovered.load_game() and recovered.street.selected().action_levels.pouring==0,"Invalid action levels recover from backup")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.muted = true
	app.start_new_game()
	app.show_tutorial_hint = false
	app.render()
	var serve: Button = test.find_button(app,"Serve a drink")
	var welcome: Button = test.find_button(app,"Welcome customers")
	var chat_button: Button = test.find_button(app,"Have a chat")
	test.check(not serve.disabled and not welcome.disabled and chat_button.disabled,"Opening UI shows eligible actions and disables unnecessary chat")
	test.check(not serve.get_rect().intersects(welcome.get_rect()) and not welcome.get_rect().intersects(chat_button.get_rect()),"Action touch targets do not overlap")
	app.street_action("serve")
	serve = test.find_button(app,"Serve a drink")
	test.check(serve.disabled and app.action_controls[0][2].text.contains("10s"),"Successful service immediately shows its refill")
	app.model.street.advance(4.5)
	var before: Dictionary = app.model.s.duplicate(true)
	app.update_action_controls()
	test.check(app.model.s==before and is_equal_approx(app.action_controls[0][1].size.x/(serve.size.x-4),0.45),"UI reads the fractional fill without advancing or rewarding the model")
	app.render()
	test.check(test.find_button(app,"Serve a drink").disabled,"Rebuilding the drawer does not reset cooldown")
	app.model.street.advance(5.5)
	app.update_action_controls()
	test.check(not test.find_button(app,"Serve a drink").disabled and app.action_controls[0][2].text.contains("Ready"),"Button re-enables at its deadline without a new render")
	app.model.street.selected().customers[1].wait = 40
	app.update_action_controls()
	test.check(not test.find_button(app,"Have a chat").disabled,"Chat button follows real customer urgency")
	app.street_action("chat")
	test.check(test.find_button(app,"Have a chat").disabled and test.find_button(app,"Welcome customers").disabled,"Chat visibly locks both social controls")
	app.model.s.cash = 10000
	app.update_action_controls()
	test.check(not app.upgrade_controls[0][0].disabled and app.upgrade_controls[0][0].text.contains("10s → 8s"),"Upgrade affordability updates live and shows exact improvement")
	app.queue_free()
	await test.process_frame
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)
