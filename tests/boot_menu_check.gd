extends RefCounted

const Campaign = preload("res://scripts/campaign.gd")

func launch(test: SceneTree) -> Control:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.muted = true
	app.music.stop()
	return app

func close(app: Control) -> void:
	app.get_parent().remove_child(app)
	app.free()

func idle_at_menu(app: Control) -> void:
	for i in 20: app._process(1.0)
	app.save_state()
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	app._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	app._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)

func run(test: SceneTree) -> void:
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var app := launch(test)
	test.check(app.title_screen.is_intro(),"Boot begins with the short presentation-only splash")
	var intro_state := JSON.stringify(app.model.s)
	var intro_rng: int = app.model.rng.state
	app._process(.8)
	test.check(app.title_screen.clock==.8 and JSON.stringify(app.model.s)==intro_state and app.model.rng.state==intro_rng,"Splash animation advances without running the campaign or RNG")
	for input_kind in 3:
		app.title_clock = 0
		app.render()
		var skip: InputEvent
		if input_kind==0:
			var pointer := InputEventMouseButton.new()
			pointer.button_index = MOUSE_BUTTON_LEFT
			pointer.pressed = true
			pointer.position = Vector2(100,370)
			skip = pointer
		elif input_kind==1:
			var touch := InputEventScreenTouch.new()
			touch.pressed = true
			touch.position = Vector2(100,370)
			skip = touch
		else:
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER
			key.pressed = true
			skip = key
		app._input(skip)
		test.check(app.boot_menu and not app.title_screen.is_intro() and not FileAccess.file_exists(Campaign.SAVE),"Mouse, touch and keyboard skip without starting a campaign")
	test.check(app.title_screen.primary.text=="New Game" and app.title_screen.primary.has_focus(),"Fresh title focuses New Game after the intro")
	app.set_sound()
	test.check(not app.title_screen.is_intro(),"Sound redraw does not replay the splash")
	test.check(JSON.stringify(app.model.s)==intro_state,"Skipping and title sound controls preserve the campaign")
	test.check(app.boot_menu and test.find_button(app,"Resume").disabled,"Fresh boot offers New Game and disables Resume")
	var state := JSON.stringify(app.model.s)
	idle_at_menu(app)
	test.check(JSON.stringify(app.model.s)==state and not FileAccess.file_exists(Campaign.SAVE),"Menu, pause, resume and exit never simulate or create a save")
	test.use_button(app,"New Game")
	test.check(not app.boot_menu and app.show_tutorial_hint and app.model.s.cash==228,"New Game opens the fresh Blue Hour")
	test.check(FileAccess.file_exists(Campaign.SAVE),"New Game persists immediately")
	app.model.s.cash = 4321
	app.model.s.day = 7 # The pending birthday must not start on the menu.
	app.model.street.selected().equipment.pool = 1
	app.save_state()
	app.save_state()
	close(app)
	var saved := FileAccess.get_file_as_string(Campaign.SAVE)
	var backup := FileAccess.get_file_as_string(Campaign.BACKUP)
	app = launch(test)
	test.check(app.resume_available and not test.find_button(app,"Resume").disabled,"Existing campaign enables Resume")
	app.skip_title_intro()
	test.check(app.title_screen.primary.text=="Resume" and app.title_screen.primary.has_focus(),"Returning players get Resume as the focused primary action")
	test.check(app.title_screen.campaign_summary.contains("Day 7") and app.title_screen.campaign_summary.contains("4,321"),"Title displays the saved day and shared balance")
	state = JSON.stringify(app.model.s)
	idle_at_menu(app)
	test.check(JSON.stringify(app.model.s)==state and FileAccess.get_file_as_string(Campaign.SAVE)==saved and FileAccess.get_file_as_string(Campaign.BACKUP)==backup,"Waiting at boot leaves both saved files and model untouched")
	test.use_button(app,"New Game")
	test.check(app.new_game_confirmation and FileAccess.get_file_as_string(Campaign.SAVE)==saved,"New Game warns before replacing existing progress")
	test.check(app.title_screen.primary.text=="Cancel" and app.title_screen.primary.has_focus(),"Replacement confirmation defaults keyboard focus to Cancel")
	test.use_button(app,"Cancel")
	test.check(not app.new_game_confirmation and app.boot_menu,"Cancel returns to the boot menu")
	test.use_button(app,"New Game")
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	test.check(not app.new_game_confirmation,"Android back cancels replacement")
	test.use_button(app,"New Game")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	app._unhandled_key_input(escape)
	test.check(not app.new_game_confirmation,"Escape cancels replacement")
	test.use_button(app,"Resume")
	test.check(not app.boot_menu and app.model.s.cash==4321 and app.model.s.day==7 and app.model.street.selected().equipment.pool==1,"Resume restores money, date and equipment")
	var resumed := JSON.stringify(app.model.s)
	app.resume_game()
	test.check(JSON.stringify(app.model.s)==resumed,"Repeated Resume cannot claim or reload twice")
	close(app)
	# Backup recovery is still resumable when the primary file is unreadable.
	var broken := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	broken.store_string("broken")
	broken.close()
	app = launch(test)
	test.check(app.resume_available,"A valid backup enables Resume")
	test.use_button(app,"Resume")
	test.check(app.model.s.cash==4321,"Resume recovers the backup")
	close(app)
	app = launch(test)
	test.use_button(app,"New Game")
	test.use_button(app,"Erase progress & start new game")
	test.check(not app.boot_menu and app.model.s.cash==228 and app.model.s.day==1 and app.model.street.selected().equipment.pool==0,"Confirmed New Game clears previous progress")
	test.check(not FileAccess.file_exists(Campaign.BACKUP),"New Game removes the previous backup")
	close(app)
	var restored := Campaign.new()
	test.check(restored.load_game() and restored.s.cash==228 and restored.s.day==1,"A new run survives an immediate relaunch")
	broken = FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	broken.store_string("broken")
	broken.close()
	app = launch(test)
	test.check(not app.resume_available and test.find_button(app,"Resume").disabled,"Unreadable primary with no backup disables Resume")
	test.check(not Campaign.new().load_game(),"Corrupting the new save cannot resurrect the erased campaign")
	test.use_button(app,"New Game")
	test.check(app.new_game_confirmation,"Even an unreadable existing save requires replacement confirmation")
	test.use_button(app,"Erase progress & start new game")
	# In-game restart uses the same replacement semantics.
	app.model.s.cash = 6789
	app.save_state()
	app.save_state()
	app.restart()
	app.restart()
	test.check(app.model.s.cash==228 and not FileAccess.file_exists(Campaign.BACKUP),"In-game restart also removes the erased backup")
	saved = FileAccess.get_file_as_string(Campaign.SAVE)
	app.start_tutorial()
	app.start_new_game()
	test.check(FileAccess.get_file_as_string(Campaign.SAVE)==saved,"Practice cannot replace the real campaign")
	app.finish_tutorial()
	close(app)
	# Managed earnings are claimed on Resume, not when merely viewing the menu.
	var managed := Campaign.new(72)
	var bar: Dictionary = managed.street.selected()
	bar.stage = 3
	bar.manager = true
	bar.restock = true
	bar.equipment.sign = 1
	bar.team = [{"role":0,"on":true,"host":-1}]
	for person in bar.team: managed.street.economy.ensure_staff_service(person)
	bar.crew = 1
	managed.s.cash = 10000
	managed.s.street.last_seen = int(Time.get_unix_time_from_system())-3600
	managed.s.rng = str(managed.rng.state)
	var fixture := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	fixture.store_string(JSON.stringify(managed.s))
	fixture.close()
	saved = FileAccess.get_file_as_string(Campaign.SAVE)
	app = launch(test)
	idle_at_menu(app)
	test.check(app.model.s.cash==10000 and app.offline_notice==0 and FileAccess.get_file_as_string(Campaign.SAVE)==saved,"Managed offline profit waits for Resume")
	test.use_button(app,"Resume")
	test.check(app.offline_notice>0 and app.model.s.cash==10000+app.offline_notice,"Resume claims the eligible managed profit")
	var credited := int(app.model.s.cash)
	var claimed_at := int(app.model.s.street.last_seen)
	close(app)
	restored = Campaign.new()
	test.check(restored.load_game() and restored.s.cash==credited and restored.street.claim_offline(claimed_at)==0,"Resume persists offline credit without replaying it")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
