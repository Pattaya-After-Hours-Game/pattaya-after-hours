extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Fight = preload("res://scripts/fight.gd")
const District = preload("res://scripts/district.gd")

func click(tree: SceneTree, control: Control) -> void:
	await tree.process_frame
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	tree.root.push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		tree.root.push_input(event,true)
	await tree.process_frame

func touch(fight: Control, point: Vector2, index: int, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = down
	fight._input(event)

func run(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.muted = true
	app.music.stop()
	await click(test,test.find_button(app,"New Game"))
	test.check(app.new_game_confirmation,"Pointer opens the new-game warning")
	await click(test,test.find_button(app,"Cancel"))
	test.check(app.boot_menu and not app.new_game_confirmation,"Pointer cancels without leaving the menu")
	await click(test,test.find_button(app,"Resume"))
	test.check(not app.boot_menu,"Pointer resumes the saved campaign")
	app.model = Campaign.new(555)
	app.offline_notice = 0
	app.show_tutorial_hint = false
	app.render()
	await test.process_frame
	test.check(not app.drawer.visible,"Management starts dismissed")
	await click(test,test.find_button(app,"Service"))
	test.check(app.drawer_open and app.drawer.visible,"Pointer opens Service drawer")
	await click(test,test.find_button(app,"Drinks & margins"))
	test.check(app.drink_list_open and test.find_button(app,"Buy 6 · ฿19 ea")!=null,"Drink list exposes individual wholesale prices")
	await click(test,test.find_button(app,"Hide drink list"))
	test.check(not app.drink_list_open,"Fridge details can be collapsed")
	await click(test,test.find_button(app,"×"))
	test.check(not app.drawer.visible,"Pointer dismisses management")
	var before := int(app.model.s.street.served)
	await click(test,test.find_button(app,"Serve a drink"))
	test.check(app.model.s.street.served==before+1,"Serve remains accessible with drawer closed")
	app.model.s.cash = 1000
	app.sync_upgrade_badge(true)
	await click(test,app.upgrade_badge)
	test.check(app.upgrades_open and app.upgrades_ready_only,"The Service notification opens the ready list with a pointer tap")
	var pouring := app.column.find_child("Upgrade_pouring",true,false) as Button
	await click(test,pouring)
	test.check(app.model.s.cash==100 and app.model.street.selected().action_levels.pouring==1 and not app.upgrade_badge.visible,"Buying from the upgrade card updates cash, speed and the badge")
	app.close_drawer()
	app.model.s.cash = 999999
	app.model.s.rep = 100
	app.model.s.street.chapter = 4
	for i in 7: app.model.street.action("buy",i%3)
	app.render()
	await test.process_frame
	for i in 8:
		var card: Button = app.root_ui.get_node("Property%d" % i)
		test.check(card.get_global_rect().size==Vector2(62,55),"Property hit region matches card")
		var thumb: TextureRect = card.get_child(0)
		test.check(thumb.size==Vector2(56,32),"Property thumbnail stays inside card")
		await click(test,card)
		test.check(app.model.s.street.selected==i,"Pointer selects property %d" % i)
	app.model.street.announce(2)
	app.close_drawer()
	await click(test,app.event_banner)
	test.check(app.drawer.visible and app.tab==1,"Visible event banner opens Events")
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	test.check(not app.drawer.visible,"Android Back dismisses management")
	app.change_tab(4)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	app._unhandled_key_input(escape)
	test.check(not app.drawer.visible,"Keyboard cancel dismisses management")
	app.change_tab(0)
	await test.process_frame
	var wheel := InputEventMouseButton.new()
	wheel.position = app.scroll.get_global_rect().get_center()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	for i in 12: test.root.push_input(wheel,true)
	await test.process_frame
	test.check(app.scroll.scroll_vertical>0,"Management drawer scrolls with pointer input")
	app.offline_notice = 1234
	app.render()
	before = app.model.s.street.served
	await click(test,test.find_button(app,"Serve a drink"))
	test.check(app.model.s.street.served==before,"Offline notice blocks controls behind it")
	await click(test,test.find_button(app,"Back to the street"))
	test.check(app.offline_notice==0,"Offline earnings notice dismisses")
	app.offline_notice = 123
	app.render()
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	test.check(app.offline_notice==0,"Android Back dismisses offline earnings")
	# Simulate update availability on Linux without network or executable replacement.
	app.windows_updates = preload("res://scripts/windows_updates.gd").new()
	app.add_child(app.windows_updates)
	app.windows_updates.tag = "v9.0.0"
	app.render()
	await test.process_frame
	test.check(app.update_button.visible and app.update_button.get_global_rect().end.x<268,"Windows Update fits before the till in the new header")
	test.check(test.find_button(app,"Serve a drink")!=null and test.find_button(app,"Welcome customers")!=null,"Updater integration retains both live economy actions")
	var saved_before := FileAccess.get_file_as_string(Campaign.SAVE) if FileAccess.file_exists(Campaign.SAVE) else ""
	var elapsed_before := int(app.model.s.street.elapsed)
	app.updater_worker = true
	app._process(20.0)
	app._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var saved_after := FileAccess.get_file_as_string(Campaign.SAVE) if FileAccess.file_exists(Campaign.SAVE) else ""
	test.check(saved_after==saved_before and app.model.s.street.elapsed==elapsed_before,"Update worker cannot run or autosave a fresh campaign")
	app.queue_free()
	await test.process_frame
	# Pointer coordinates use each view's displayed transform, not simulation units.
	var fight := Fight.new()
	fight.position = Vector2(32,19)
	fight.size = Vector2(768,432)
	fight.mobile_controls = false
	test.root.add_child(fight)
	fight.set_physics_process(false)
	for item in Fight.BUTTONS:
		var point := fight.global_position+Vector2(item[2]+34,494)*.8
		test.check(fight.action_at(point)==item[0],"Scaled combat hit region: "+item[0])
		fight.activate(point,0)
		test.check(fight.touches.get(0)==item[0],"Scaled touch dispatch: "+item[0])
	fight._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	fight.mobile_controls = true
	var pad_center := Fight.PAD.get_center()
	var right := fight.global_position+(pad_center+Vector2(Fight.PAD_CELL,0))*.8
	var up := fight.global_position+(pad_center+Vector2(0,-Fight.PAD_CELL))*.8
	var down := fight.global_position+(pad_center+Vector2(0,Fight.PAD_CELL))*.8
	var left := fight.global_position+(pad_center-Vector2(Fight.PAD_CELL,0))*.8
	var jab := fight.global_position+Vector2(766,482)*.8
	fight.countdown = 0
	var player_start: float = fight.fighters[0].x
	touch(fight,right,0,true)
	fight._physics_process(.1)
	fight._physics_process(.1)
	test.check(fight.fighters[0].x>player_start+15,"Held mobile D-pad moves across frames")
	touch(fight,jab,1,true)
	fight._physics_process(.02)
	test.check(fight.pressed("right") and fight.fighters[0].move=="jab","Second finger attacks while holding movement")
	touch(fight,jab,1,false)
	test.check(fight.pressed("right") and not fight.pressed("jab"),"Releasing attack keeps direction held")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(left.x,up.y)
	fight._input(drag)
	test.check(fight.pressed("left") and fight.pressed("jump") and not fight.pressed("right"),"Sliding to a diagonal combines jump and movement")
	drag.position = down
	fight._input(drag)
	test.check(fight.pressed("guard") and not fight.pressed("left"),"Sliding down guards")
	drag.position = jab
	fight._input(drag)
	test.check(not fight.pressed("guard") and not fight.pressed("jab"),"D-pad finger releases direction outside the pad without attacking")
	drag.position = right
	fight._input(drag)
	touch(fight,right,0,false)
	test.check(not fight.pressed("right"),"Releasing D-pad finger stops movement")
	for item in Fight.MOBILE_BUTTONS:
		var rect: Rect2 = item[2]
		var point := fight.global_position+rect.get_center()*.8
		test.check(fight.action_at(point)==item[0],"Scaled mobile attack hit region: "+item[0])
	touch(fight,jab,1,true)
	fight._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	test.check(not fight.pressed("jab") and not fight.pressed("jump"),"Focus loss clears held and buffered mobile input")
	for name in Fight.ATTACKS:
		fight.reset_round()
		var f: Dictionary = fight.fighters[0]
		f.move = name
		f.timer = Fight.ATTACKS[name][0]-.001
		test.check(fight.frame_index(f)==5,"Attack anticipation: "+name)
		f.timer += .002
		test.check(fight.frame_index(f)=={"jab":6,"kick":7,"super":8}[name],"Attack contact synchronized: "+name)
		f.timer = Fight.ATTACKS[name][0]+Fight.ATTACKS[name][1]+.001
		test.check(fight.frame_index(f)==5,"Attack recovery: "+name)
	fight.queue_free()
	await test.process_frame
	var district := District.new()
	district.position = Vector2(32,19)
	district.size = Vector2(768,432)
	test.root.add_child(district)
	district.set_process(false)
	for i in District.SITES.size():
		district.point = Vector2(160,114)
		var event := InputEventScreenTouch.new()
		event.pressed = true
		event.position = district.global_position+district.site_rect(i).get_center()*2.4
		district._input(event)
		test.check(district.focus_site==i,"Scaled district destination: %d" % i)
		var previous := district.point
		var path: Array = [district.target]
		path.append_array(district.waypoints)
		for waypoint: Vector2 in path:
			for step in 21:
				test.check(district.on_path(previous.lerp(waypoint,step/20.0)),"District route stays on streets: %d" % i)
			previous = waypoint
	# Retargeting while between lanes must not cross the upper shop roofs.
	for start in [Vector2(216,140),Vector2(310,145),Vector2(103,80)]:
		district.point = start
		district.route(Vector2(56,52))
		var previous: Vector2 = start
		var path: Array = [district.target]
		path.append_array(district.waypoints)
		for waypoint: Vector2 in path:
			for step in 21:
				test.check(district.on_path(previous.lerp(waypoint,step/20.0)),"Retargeted route stays on streets")
			previous = waypoint
	district.queue_free()
	await test.process_frame
