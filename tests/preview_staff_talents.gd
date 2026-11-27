extends "res://tests/preview_economy.gd"
const TalentsCheck = preload("res://tests/staff_talents_check.gd")

func discover(app: Control, role: int, identity: String) -> void:
	var draw := 0
	for choice in app.model.street.economy.hiring_odds(role):
		if choice.identity==identity: break
		draw += int(choice.chance)
	app.model.s.street.hiring_seed = TalentsCheck.seed_for(draw)
	app.street_action("hire",role)
	assert(app.model.street.selected().team.back().get("identity","")==identity)

func run() -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":
		push_error("Use tools/preview-art.sh with a graphical display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.muted = true
	app.music.stop()
	app.start_new_game()
	app.model = Campaign.new(72)
	app.model.s.cash = 250000
	app.model.s.rep = 100
	app.model.s.street.chapter = 1
	app.model.street.selected().stage = 3
	app.show_tutorial_hint = false
	app.open_service_section("team")
	await capture(app,"talents-hiring-odds")
	for control in app.column.find_children("*","Button",true,false):
		if control.tooltip_text=="Explain Hire bartender · ฿1,200":
			control.pressed.emit()
			await create_timer(.25).timeout
			break
	await capture(app,"talents-odds-help","",false)
	for id in ["staff-platinum","staff-copper","staff-rose","staff-ruby"]:
		discover(app,0,id)
	await capture(app,"talents-platinum-card","Platinum")
	await capture(app,"talents-rose-card","Rose")
	app.model.street.economy.staff_service(app.model.street.selected())
	app.drawer_open = false
	await capture(app,"talents-bartender-sales")
	app.drawer_open = true
	app.service_section = "team"
	var p: Dictionary = app.model.street.selected().team[0]
	p.on = false
	await capture(app,"talents-off-duty","Platinum")
	p.contract_left = 0
	await capture(app,"talents-renewal","Rehire Platinum")
	app.model.street.action("buy",1)
	app.model.s.street.selected = app.model.s.street.bars.size()-1
	app.model.street.selected().stage = 3
	for id in ["host-violet","host-goldie"]: discover(app,1,id)
	await capture(app,"talents-goldie-card","Goldie\nAttracts")
	app.drawer_open = false
	await capture(app,"talents-hostess-room")
	app.model.street.action("buy",2)
	app.model.s.street.selected = app.model.s.street.bars.size()-1
	app.model.street.selected().stage = 3
	for id in ["host-onyx","host-scarlet"]: discover(app,2,id)
	app.drawer_open = true
	app.service_section = "team"
	await capture(app,"talents-onyx-card","Onyx")
	app.model.s.street.seconds = 40
	app.drawer_open = false
	await capture(app,"talents-gogo-set")
	app.model.street.action("close_and_count")
	await capture(app,"talents-closed-room")
	app.model.save_game()
	app.model = Campaign.new(1)
	if not app.model.load_game():
		push_error("Talent preview save failed to reload")
		quit(1)
		return
	app.drawer_open = true
	app.service_section = "team"
	await capture(app,"talents-reloaded","Onyx")
	app.queue_free()
	await process_frame
	quit()
