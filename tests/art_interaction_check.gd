extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Fight = preload("res://scripts/fight.gd")
const District = preload("res://scripts/district.gd")
const Art = preload("res://scripts/art.gd")

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

func fight_key(test: SceneTree, key: Key, down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = down
	event.echo = echo
	test.root.push_input(event,true)

func check_blue_hour_fridges(test: SceneTree, app: Control) -> void:
	app.model = Campaign.new(555)
	app.model.s.cash = 20000
	var bar: Dictionary = app.model.street.selected()
	var before: Texture2D = Art.venue(0,1,false,false,0)
	for tier in range(1,5):
		bar.stage = [1,1,2,3][tier-1]
		var capacity: int = app.model.street.economy.stock_capacity(bar)
		app.open_upgrades()
		var purchase := app.column.find_child("Upgrade_fridge",true,false) as Button
		test.check(purchase!=null and not purchase.disabled,"Blue Hour offers fridge tier %d" % tier)
		if purchase==null or purchase.disabled: return
		purchase.pressed.emit()
		var thumbnail := app.find_child("Property0",true,false).get_child(0) as TextureRect
		test.check(bar.equipment.fridge==tier and thumbnail.texture!=before and not app.drawer_open,
			"Buying Blue Hour fridge tier %d updates its artwork and reveals the room" % tier)
		test.check(app.city.fridge_capacity==capacity+40 and (app.city.fridge_install_flash>0)==(tier==4),
			"Fridge art uses the purchased capacity and only the final tier emits frost")
		before = thumbnail.texture
	var loaded := Campaign.new(555)
	test.check(loaded.load_game(),"Fridge purchase is saved")
	app.model = loaded
	app.render()
	var restored := app.find_child("Property0",true,false).get_child(0) as TextureRect
	test.check(restored.texture==before and app.city.fridge_install_flash==0,
		"Reload restores Blue Hour fridge art without replaying the installation")
	test.check(app.city.fridge_tier(bar,1)==-1,"Other beer bars keep their regular art")

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
	check_blue_hour_fridges(test,app)
	app.model = Campaign.new(555)
	app.offline_notice = 0
	app.show_tutorial_hint = false
	app.render()
	await test.process_frame
	test.check(not app.drawer.visible,"Management starts dismissed")
	var rep_bar: Dictionary = app.model.street.selected()
	var rep_guest: Dictionary = rep_bar.customers[0]
	var initial_rep: int = app.model.s.rep
	rep_bar.happy = 9
	rep_guest.visit_complete = true
	app.model.street.economy.depart(rep_bar,rep_guest)
	app.update_reputation_hud()
	var gain: Label = app.reputation_float
	test.check(is_instance_valid(gain) and gain.text=="+1" and app.reputation_label.text==str(initial_rep+1),"A satisfied departure shows its reputation gain immediately")
	app.render()
	test.check(is_instance_valid(gain) and app.reputation_float==gain and gain.get_parent()==app.root_ui,"HUD redraws preserve the current reputation animation")
	app.model.s.street.event = {"id":5,"prepared":false}
	app.model.street.finish_event()
	app.render()
	test.check(is_instance_valid(app.reputation_float) and app.reputation_float.text=="−2" and app.reputation_label.text==str(initial_rep-1),"Reputation loss shows the actual signed amount")
	app.model = Campaign.new(555)
	app.render()
	test.check(not is_instance_valid(app.reputation_float),"Switching campaigns does not animate their reputation difference")
	var duo_point := Vector2(592,300)
	var before_reaction := JSON.stringify(app.model.s)
	var mouse := InputEventMouseButton.new()
	mouse.position = duo_point
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	test.root.push_input(mouse,true)
	test.check(app.duo_reaction.is_empty(),"A single mouse click leaves the duo idle")
	mouse.pressed = false
	test.root.push_input(mouse,true)
	mouse.pressed = true
	mouse.double_click = true
	test.root.push_input(mouse,true)
	test.check(app.duo_reaction.get("id")==3,"Double-clicking the duo starts its kiss")
	mouse.pressed = false
	test.root.push_input(mouse,true)
	app.render()
	var opening_bar: Dictionary = app.model.street.selected()
	var duo: Dictionary = app.city.scene_people(opening_bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id")==3)[0]
	test.check(duo.pose==1,"The kiss pose survives a scene refresh")
	app.city.clock += 1.3
	duo = app.city.scene_people(opening_bar).filter(func(person: Dictionary) -> bool: return person.get("customer_id")==3)[0]
	test.check(duo.pose==0,"The duo returns to idle after the kiss")
	app.duo_reaction.clear()
	var finger := InputEventScreenTouch.new()
	finger.position = duo_point
	finger.pressed = true
	test.root.push_input(finger,true)
	test.check(app.duo_reaction.get("id")==3,"Tapping the duo starts its kiss")
	finger.pressed = false
	test.root.push_input(finger,true)
	app.duo_reaction.clear()
	test.check(JSON.stringify(app.model.s)==before_reaction,"The reaction leaves the campaign and waiting orders alone")
	await click(test,test.find_button(app,"Service"))
	test.check(app.drawer_open and app.drawer.visible,"Pointer opens Service drawer")
	test.check(app.scroll.get_v_scroll_bar().max_value<=app.scroll.get_v_scroll_bar().page,"The opening Service dashboard fits without scrolling")
	await click(test,test.find_button(app,"?"))
	test.check(is_instance_valid(app.service_help_panel) and app.service_help_panel.is_visible_in_tree(),"The goal explanation opens on demand")
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	test.check(app.drawer_open and app.service_help_panel==null,"Back dismisses help before leaving Service")
	await click(test,test.find_button(app,"Team"))
	await click(test,test.find_button(app,"?"))
	test.check(is_instance_valid(app.service_help_panel) and app.service_section=="team","Hiring explains the contract in a slide-out")
	test.check(app.service_help_panel.find_children("*","Button",true,false).is_empty(),"The explanation adds no nested close controls")
	await click(test,test.find_button(app,"Back"))
	test.check(app.service_help_panel==null and app.service_section=="team" and app.drawer_close_button.tooltip_text=="Back to Service","The pinned button backs out of help first")
	await click(test,app.drawer_close_button)
	test.check(app.service_section.is_empty() and app.drawer_close_button.text=="×","Only the overview closes")
	var fridge_bar: Dictionary = app.model.street.selected()
	var saved_stock: int = fridge_bar.stock
	var saved_customers: Array = fridge_bar.customers.duplicate(true)
	fridge_bar.equipment.menu = 1
	fridge_bar.stock = 30
	for guest in fridge_bar.customers:
		guest.drink = 2
		guest.lager_quote = 0
	await click(test,test.find_button(app,"Fridge"))
	test.check(app.fridge_open and test.find_button(app,"Buy 6 · ฿114")!=null,"Fridge shows the total pack price")
	var sprites: Array = []
	for card in app.column.find_children("Drink_*","PanelContainer",false,false):
		var icon: TextureRect = card.find_children("*","TextureRect",true,false)[0]
		if not sprites.has(icon.texture): sprites.append(icon.texture)
	test.check(sprites.size()==4 and app.column.size.x<=app.scroll.size.x,"Four distinct drink sprites fit the drawer without horizontal scrolling")
	await click(test,test.find_button(app,"?"))
	test.check(is_instance_valid(app.service_help_panel) and app.service_help_panel.find_children("*","Label",true,false)[1].text.contains("expected popularity"),"Drink economics open in the help slide-out")
	await click(test,app.drawer_close_button)
	var back_rect: Rect2 = app.drawer_close_button.get_global_rect()
	app.scroll.scroll_vertical = 1000
	await test.process_frame
	test.check(app.scroll.scroll_vertical>0 and app.drawer_close_button.get_global_rect()==back_rect,"Back stays pinned while Fridge scrolls")
	await click(test,app.drawer_close_button)
	test.check(not app.fridge_open and app.service_section.is_empty(),"Fridge returns to the compact dashboard from the bottom of the list")
	await click(test,test.find_button(app,"Fridge"))
	app.scroll.scroll_vertical = 1000
	await test.process_frame
	var cash_before: int = app.model.s.cash
	await click(test,test.find_button(app,"View auto-restock upgrade  ›"))
	await test.process_frame
	var supplier: Control = app.column.find_child("Upgrade_supplier",true,false)
	test.check(app.upgrades_open and supplier!=null and app.scroll.get_global_rect().intersects(supplier.get_global_rect()) and app.model.s.cash==cash_before,"Fridge opens the supplier upgrade without spending the till")
	await click(test,app.drawer_close_button)
	fridge_bar.equipment.menu = 0
	fridge_bar.stock = saved_stock
	fridge_bar.customers = saved_customers
	await click(test,test.find_button(app,"×"))
	test.check(not app.drawer.visible,"Pointer dismisses management")
	var before := int(app.model.s.street.served)
	await click(test,test.find_button(app,"Serve a drink"))
	test.check(app.model.s.street.served==before+1,"Serve remains accessible with drawer closed")
	app.model.s.cash = 1000
	app.sync_upgrade_badge(true)
	await click(test,app.upgrade_badge)
	test.check(app.upgrades_open and not app.upgrades_ready_only,"The Service notification opens the full list with a pointer tap")
	var pouring := app.column.find_child("Upgrade_pouring",true,false) as Button
	await test.process_frame
	app.scroll.ensure_control_visible(pouring)
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
		var heading: Label = app.root_ui.get_node("VenueName")
		test.check(heading.text==app.model.street.selected().name,"Header shows the selected venue's full name")
		var label_width := heading.get_theme_font("font").get_string_size(heading.text,HORIZONTAL_ALIGNMENT_LEFT,-1,heading.get_theme_font_size("font_size")).x
		test.check(label_width<=170,"Venue name fits beside the Windows update button")
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
	app.open_upgrades(false)
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
	for key in [KEY_J,KEY_K]:
		fight.reset_round()
		fight.countdown = 0
		fight_key(test,key,true)
		fight_key(test,key,false)
		fight._physics_process(.016)
		test.check(fight.fighters[0].move == ("jab" if key == KEY_J else "kick"),"Desktop punch and kick use the displayed keys")
		fight.reset_round()
		fight.countdown = 0
		var start_x: float = fight.fighters[0].x
		fight_key(test,KEY_DOWN,true)
		fight_key(test,KEY_RIGHT,true)
		fight._physics_process(.016)
		test.check(fight.fighters[0].crouch and fight.fighters[0].guard and fight.fighters[0].x == start_x,"Down crouches in place and guards")
		fight_key(test,key,true)
		fight_key(test,key,false)
		fight._physics_process(.016)
		test.check(fight.fighters[0].move == ("uppercut" if key == KEY_J else "roundhouse"),"The crouching modifier selects a distinct attack")
		fight_key(test,KEY_DOWN,false)
		fight_key(test,KEY_RIGHT,false)
	fight.reset_round()
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
	test.check(fight.pressed("guard") and not fight.pressed("left"),"Sliding down crouches and guards")
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
	fight.reset_round()
	fight.countdown = 0
	touch(fight,down,0,true)
	touch(fight,jab,1,true)
	fight._physics_process(.016)
	test.check(fight.fighters[0].move == "uppercut","A second finger can launch the crouching combo")
	touch(fight,down,0,false)
	touch(fight,jab,1,false)
	fight.reset_round()
	fight.countdown = 0
	var kick := fight.global_position+Vector2(841,440)*.8
	for point in [up,up,down,down,left,right,left,right,kick,jab]:
		touch(fight,point,0,true)
		touch(fight,point,0,false)
	test.check(fight.fighters[0].move == "ultimate","Touch D-pad and Kick/Punch enter the secret code")
	fight.ultimate_used = false
	fight.mobile_controls = false
	fight.reset_round()
	fight.countdown = 0
	var code := [KEY_UP,KEY_UP,KEY_DOWN,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_LEFT,KEY_RIGHT,KEY_B,KEY_A]
	fight_key(test,KEY_UP,true)
	fight_key(test,KEY_UP,true,true)
	fight_key(test,KEY_UP,false)
	test.check(fight.code_step == 1,"A held arrow does not count as repeated code presses")
	fight.elapsed += 2.1
	for key in code.slice(1):
		fight_key(test,key,true)
		fight_key(test,key,false)
	test.check(not fight.ultimate_used,"An expired code prefix cannot trigger the finisher")
	for key in code:
		fight_key(test,key,true)
		fight_key(test,key,false)
	test.check(fight.ultimate_used and fight.fighters[0].move == "ultimate","The full keyboard code starts the finisher")
	fight.ai_timer = 99.0
	fight.ai_guard = 10.0
	for i in 36:
		fight._physics_process(.016)
	test.check(fight.fighters[1].hp == 0 and fight.wins[0] == 1 and fight.announced == "ULTIMATE TAKEDOWN!","The finisher beats distant guard and awards one normal round")
	test.check(fight.frame_index(fight.fighters[0]) == 8,"The finisher keeps its contact pose at knock-out")
	for i in 110:
		fight._physics_process(.016)
	test.check(not fight.over and fight.fighters[1].hp == 100,"The next round starts normally after the finisher")
	fight.countdown = 0
	for key in code:
		fight_key(test,key,true)
		fight_key(test,key,false)
	test.check(fight.fighters[0].move.is_empty(),"The code cannot trigger again in the same session")
	fight.reset_round()
	var player: Dictionary = fight.fighters[0]
	var rival: Dictionary = fight.fighters[1]
	rival.x = player.x + 20
	rival.y = Fight.FLOOR - 31
	fight._attack(player,"uppercut")
	fight._resolve(player,rival,.18)
	test.check(rival.hp == 82,"Uppercut hits an airborne rival above jab range")
	player.move = ""
	rival.x = player.x + 28
	rival.y = Fight.FLOOR
	rival.crouch = true
	fight._attack(player,"roundhouse")
	fight._resolve(player,rival,.30)
	test.check(rival.hp == 82,"Crouching ducks a high roundhouse")
	rival.crouch = false
	fight._resolve(player,rival,.02)
	test.check(rival.hp == 60,"Roundhouse reaches farther than a jab")
	for name in Fight.ATTACKS:
		fight.reset_round()
		var f: Dictionary = fight.fighters[0]
		f.move = name
		f.timer = Fight.ATTACKS[name][0]-.001
		test.check(fight.frame_index(f)==5,"Attack anticipation: "+name)
		f.timer += .002
		test.check(fight.frame_index(f)==Fight.CONTACT_POSES[name],"Attack contact synchronized: "+name)
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
