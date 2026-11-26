extends RefCounted

const Campaign = preload("res://scripts/campaign.gd")
const Local = preload("res://scripts/local_events.gd")

func run(test: SceneTree) -> void:
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	model.s.cash = 5000
	model.street.announce(Local.CART)
	model.street.start_event()
	test.check(not eco.stock_offer(bar).enabled and eco.mixed_delivery(bar)==0,"Cart Jam blocks pack and mixed deliveries at the affected venue")
	test.check(model.street.begin_event_game()==Local.CART,"The jam offers one puzzle attempt")
	var board := Local.BOARD.duplicate(true)
	test.check(not Local.slide(board,0,1),"A vehicle cannot slide into another vehicle")
	for move in [[3,1],[4,-1],[5,-1],[5,-1],[6,-1],[7,-1],[8,1],[6,-1],[9,-1],[9,-1],[0,1],[0,1],[1,-1],[2,-1],[10,1],[10,1],[0,1],[0,1]]:
		test.check(Local.slide(board,move[0],move[1]),"Authored Cart Jam board has a legal solution")
	test.check(Local.delivery_free(board),"Bo reaches the right-hand exit")
	model.street.settle_event_game(Local.CART,true)
	test.check(eco.stock_offer(bar).enabled and model.street.begin_event_game()==-1,"Solving restores deliveries without granting a repeat attempt")
	model.save_game()
	var loaded := Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.street.event.game_won,"Event outcomes persist across reload")
	model.street.finish_event()
	model.street.action("hire",0)
	model.street.announce(Local.BED)
	model.street.action("prepare")
	model.street.start_event()
	test.check(bar.away.size()==1 and model.street.begin_event_game()==Local.BED,"The bed race temporarily takes a bartender off service")
	var rep: int = model.s.rep
	model.street.settle_event_game(Local.BED,true)
	model.street.settle_event_game(Local.BED,true)
	test.check(bar.bed_trophy and model.s.rep==rep+3,"Winning grants one trophy and one reputation reward")
	model.street.finish_event()
	test.check(bar.away.is_empty(),"The bartender returns when the event ends")
	model.street.announce(Local.ZOMBIES)
	model.street.action("prepare")
	model.street.start_event()
	eco.admit(bar)
	test.check(bar.customers.back().planned_rounds==3 and bar.customers.back().costume,"Contest guests have a visible costume and an extra round")
	model.street.finish_event()
	model.street.announce(Local.ENCORE)
	model.s.street.event.early = true
	model.street.action("encore_solo")
	model.street.start_event()
	test.check(eco.traffic_rate()>eco.traffic_rate(true),"Opting into the opening rush creates a real crowd")
	for id in Local.ROTATION.slice(8):
		test.check(Local.SOURCES[id][2].begins_with("https://"),"New events include an independent source article")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.boot_menu = false
	app.model = Campaign.new(72)
	app.model.s.cash = 5000
	app.model.street.announce(Local.CART)
	app.render()
	app._process(1.0)
	test.check(app.news_issue.headline=="Cart Jam" and app.model.s.street.elapsed==0,"Newspaper pops up and pauses the street")
	test.check(test.find_button(app,"Read the original · The Pattaya News")!=null,"Newspaper includes the original reporting link")
	test.use_button(app,"Open Events")
	test.check(app.tab==1 and app.news_issue.is_empty(),"Newspaper routes to the current event")
	app.model.street.start_event()
	app.render()
	test.use_button(app,"Clear traffic · Play")
	test.check(app.event_game==Local.CART and app.cart_board.size()==11,"Events opens the sliding puzzle")
	app.end_event_game(false)
	app.model.street.finish_event()
	app.model.street.action("hire",0)
	app.model.street.announce(Local.BED)
	app.model.street.action("prepare")
	app.model.street.start_event()
	app.render()
	test.use_button(app,"Race the bed · Play")
	for i in Local.BED_TAPS:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		key.pressed = true
		app._input(key)
	test.check(app.event_game<0 and app.model.street.selected().bed_trophy,"Keyboard tapping wins the race and puts up the trophy")
	app.queue_free()
	await test.process_frame
