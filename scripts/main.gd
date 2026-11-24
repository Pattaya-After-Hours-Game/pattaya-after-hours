extends Control

const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/content.gd")
const City = preload("res://scripts/city.gd")
const District = preload("res://scripts/district.gd")
const Fight = preload("res://scripts/fight.gd")
const TEAL = Color("#71f9d2")
const PINK = Color("#ff80b2")
const GOLD = Color("#ffd083")
const WHITE = Color("#f6e4f3")
const MUTED = Color("#b8a9cb")
const EDGE = Color("#3b2c54")
const DARK = Color("#151027")
const TAB_NAMES = ["Service","Events","Tours","Empire","Journal"]

var model = Campaign.new()
var tab := 0
var guide := 2
var message := ""
var scroll: ScrollContainer
var column: VBoxContainer
var city: Control
var root_ui: Control
var fight: Control
var district: Control
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var sfx_streams := {}
var muted := false
var training := false
var arcade_circuit := false

var confirmation := false

func _ready() -> void:
	var interface_font := FontVariation.new()
	interface_font.base_font = ThemeDB.fallback_font
	interface_font.fallbacks = [preload("res://assets/DejaVuSans.ttf")]
	theme = Theme.new()
	theme.default_font = interface_font
	model.load_game()
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK: muted = config.get_value("audio","muted",false)
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/after_hours.ogg")
	music.volume_db = -17
	add_child(music)
	music.finished.connect(music.play)
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -13
	add_child(sfx)
	for kind in ["click","impact","block","gong"]:
		sfx_streams[kind] = load("res://assets/%s.wav" % kind)
	if not muted and DisplayServer.get_name() != "headless": music.play()
	render()
	if model.s.phase == "fight": enter_fight(false)

func box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	return style

func pane(parent: Control, rect: Rect2, fill: Color, border: Color = EDGE) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel",box(fill,border))
	parent.add_child(panel)
	return panel

func abs_text(parent: Control, rect: Rect2, value: String, px: int, tint: Color = WHITE) -> Label:
	var element := Label.new()
	element.position = rect.position
	element.size = rect.size
	element.text = value
	element.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element.add_theme_color_override("font_color",tint)
	element.add_theme_font_size_override("font_size",px)
	parent.add_child(element)
	return element

func button(value: String, call: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 37
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",Color("#111d22") if primary else WHITE)
	b.add_theme_color_override("font_hover_color",Color("#111d22") if primary else WHITE)
	b.add_theme_color_override("font_pressed_color",Color("#111d22") if primary else TEAL)
	b.add_theme_color_override("font_focus_color",Color("#111d22") if primary else WHITE)
	b.add_theme_stylebox_override("normal",box(TEAL if primary else Color("#231936"),TEAL.darkened(.15) if primary else EDGE))
	b.add_theme_stylebox_override("hover",box(Color("#b2ffe8") if primary else Color("#352046"),PINK))
	b.add_theme_stylebox_override("pressed",box(Color("#a0ead8") if primary else Color("#3f2954"),TEAL))
	var focus := box(Color.TRANSPARENT,GOLD)
	focus.draw_center = false
	b.add_theme_stylebox_override("focus",focus)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(func():
		tone("click")
		call.call())
	return b

func at_button(parent: Control,rect: Rect2,value: String,call: Callable,primary: bool = false) -> Button:
	var b := button(value,call,primary)
	b.position = rect.position
	b.size = rect.size
	parent.add_child(b)
	return b

func tone(kind: String) -> void:
	if muted or DisplayServer.get_name() == "headless": return
	sfx.stream = sfx_streams[kind]
	sfx.play()

func set_sound() -> void:
	muted = not muted
	if muted: music.stop()
	elif DisplayServer.get_name() != "headless": music.play()
	var config := ConfigFile.new()
	config.set_value("audio","muted",muted)
	config.save("user://settings.cfg")
	render(true)

func save_state() -> void:
	var error: int = model.save_game()
	if error != OK: message = "Save failed (%d)." % error


func change_tab(index: int) -> void:
	confirmation = false
	tab = index
	message = ""
	render()

func render(keep_scroll: bool = false) -> void:
	var previous := scroll.scroll_vertical if keep_scroll and is_instance_valid(scroll) else 0
	if is_instance_valid(root_ui):
		remove_child(root_ui)
		root_ui.queue_free()
	root_ui = Control.new()
	root_ui.size = Vector2(960,540)
	add_child(root_ui)
	pane(root_ui,Rect2(0,0,960,540),Color("#100c1d"),Color("#100c1d"))
	pane(root_ui,Rect2(0,0,960,3),PINK,PINK)
	abs_text(root_ui,Rect2(17,7,360,26),"PATTAYA AFTER HOURS",24,WHITE)
	var status: String = "%s · %s" % [model.weekday(),Content.WEATHER[int(model.s.weather)]]
	abs_text(root_ui,Rect2(18,36,244,20),"THE BLUE HOUR   /   "+status,13,TEAL)
	metric(355,"TILL",cash(model.s.cash) if model.s.cash < 100000 else "฿%.1fk" % (model.s.cash / 1000.0),TEAL)
	metric(465,"STOCK",str(int(model.s.stock)),GOLD)
	metric(558,"REPUTATION",str(int(model.s.rep)),TEAL)
	metric(676,"HEAT",str(int(model.s.heat)),PINK)
	metric(762,"SHIFT","D%03d" % int(model.s.day),WHITE)
	at_button(root_ui,Rect2(851,14,94,40),"Muted" if muted else "Sound",set_sound)
	pane(root_ui,Rect2(14,66,550,386),DARK)
	city = City.new()
	city.position = Vector2(16,68)
	city.size = Vector2(546,370)
	city.clip_contents = true
	city.night = model.s.phase in ["incident","fight","report"]
	city.guests = model.s.night.get("guests",0) if city.night else 0
	city.weather = int(model.s.weather)
	city.level = int(model.s.level)
	city.venue = int(model.s.venue)
	city.rig = int(model.s.rig)
	city.site.connect(func(index: int):
		if model.s.phase == "plan": change_tab(index))
	root_ui.add_child(city)
	pane(root_ui,Rect2(16,438,546,14),Color("#251a36"),EDGE)
	abs_text(root_ui,Rect2(24,435,527,19),"BAY DISTRICT   /   %s" % ("SERVICE LIVE" if city.night else "PRE-SHIFT"),10,WHITE)
	pane(root_ui,Rect2(14,461,550,65),DARK)
	abs_text(root_ui,Rect2(26,467,265,20),"THE SHIFT LOG",13,GOLD)
	abs_text(root_ui,Rect2(26,490,410,24),str(model.s.log.front()).left(61),14,MUTED)
	if model.s.phase == "plan":
		at_button(root_ui,Rect2(435,473,117,41),"Walk district",walk_district)
	pane(root_ui,Rect2(576,66,370,460),DARK)
	for index in TAB_NAMES.size():
		var b := at_button(root_ui,Rect2(582 + 71*index,72,69,37),TAB_NAMES[index],change_tab.bind(index),tab == index and model.s.phase == "plan")
		b.add_theme_font_size_override("font_size",13)
		b.disabled = model.s.phase != "plan"
	scroll = ScrollContainer.new()
	scroll.position = Vector2(586,119)
	scroll.size = Vector2(350,330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.scroll_deadzone = 8
	root_ui.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",7)
	scroll.add_child(column)
	var action_label := ""
	var action: Callable
	match model.s.phase:
		"plan":
			match tab:
				0: service_panel()
				1: events_panel()
				2: tours_panel()
				3: empire_panel()
				4: journal_panel()
			action_label = "Open the doors"
			action = begin
		"incident":
			incident_panel()
			action_label = "Scale back service"
			action = func():
				model.fallback()
				commit()
		"report":
			report_panel()
			action_label = "Finish the story" if not model.s.end.is_empty() else "Next day"
			action = advance
		"end":
			ending_panel()
			action_label = "Start a new run" if not confirmation else "Confirm new run"
			action = restart
		"fight":
			title("Toybox showdown")
			body("Mali is ready to return to the floor.")
			action_label = "Resume the fight"
			action = enter_fight.bind(false)
	if not message.is_empty():
		var note := abs_text(root_ui,Rect2(588,454,344,27),message,12,PINK)
		note.clip_text = true
	at_button(root_ui,Rect2(585,480,352,37),action_label,action,true)
	if previous > 0:
		scroll.set_deferred("scroll_vertical",previous)

func metric(x: int,name_text: String,value: String,tint: Color) -> void:
	abs_text(root_ui,Rect2(x,7,124,17),name_text,11,MUTED)
	abs_text(root_ui,Rect2(x,25,124,25),value,20,tint)

func cash(amount: Variant) -> String:
	return "%s฿%s" % ["−" if int(amount) < 0 else "",_group_digits(absi(int(amount)))]

func _group_digits(value: int) -> String:
	var digits := str(value)
	for i in range(digits.length()-3,0,-3):
		digits = digits.insert(i,",")
	return digits

func title(value: String, tint: Color = TEAL) -> void:
	body(value,tint,21)

func body(value: String,tint: Color = MUTED, px: int = 15) -> void:
	var element := Label.new()
	element.text = value
	element.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	element.add_theme_color_override("font_color",tint)
	element.add_theme_font_size_override("font_size",px)
	column.add_child(element)

func row_button(value: String, call: Callable, primary: bool = false) -> void:
	column.add_child(button(value,call,primary))

func row_pair(first: String, left: Callable, second: String, right: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	column.add_child(row)
	for b in [button(first,left),button(second,right)]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)

func cycle(key: String, choices: Array) -> void:
	model.s[key] = (int(model.s[key]) + 1) % choices.size()
	if key == "pay" and model.s.pay == 0:
		for id in model.s.bookings.keys():
			if Content.ROUTES[int(model.s.bookings[id])][2] == 2:
				model.s.bookings.erase(id)
				message = "Long tours need standard pay."
	commit(true)

func do_action(id: String,index: int = 0) -> void:
	message = model.action(id,index)
	commit(true)

func commit(keep_scroll: bool = false) -> void:
	save_state()
	render(keep_scroll)

func begin() -> void:
	confirmation = false
	message = model.start()
	commit()

func advance() -> void:
	model.next_day()
	tab = 0
	message = ""
	commit()

func service_panel() -> void:
	title("Set the shift")
	body("%s traffic expected. Standard shifts have three waves." % ("Heavy" if model.s.forecast >= 9 else "Light" if model.s.forecast < 0 else "Steady"))
	row_pair("Hours: "+Campaign.HOURS[int(model.s.hours)],cycle.bind("hours",Campaign.HOURS),
		Campaign.PROMOS[int(model.s.promo)],cycle.bind("promo",Campaign.PROMOS))
	var amount := mini(30,105+int(model.s.level)*20-int(model.s.stock))
	row_pair("Stock +%d · %s" % [amount,cash(amount*model.stock_price())],do_action.bind("buy"),"Hire · ฿980",do_action.bind("hire"))
	body("TEAM ROTA    /    FATIGUE · MORALE",GOLD,12)
	for i in model.s.staff.size():
		var staff: Dictionary = model.s.staff[i]
		var profile: Array = Content.STAFF[int(staff.id)]
		body("%s  ·  %s\nSkill %d    Fatigue %d    Morale %d" % [profile[0], profile[1],staff.skill,staff.fatigue,staff.morale],WHITE,13)
		row_pair("Paid leave" if staff.hurt else "On rota" if staff.work else "Off duty",do_action.bind("rota",i),
			"Train · ฿410",do_action.bind("train",i))
	body("Supplier reliability %d · Regulars %d" % [model.s.supplier,model.s.regulars],MUTED,13)
	row_button("Close tonight for team recovery",func():
		model.rest()
		commit())

func events_panel() -> void:
	title("What's on tonight?")
	body("Events increase demand. Secure the door, check capacity, and budget for a thinner crowd.")
	for i in Content.EVENTS.size():
		var item: Array = Content.EVENTS[i]
		var value: String = item[0]+(" · "+cash(item[1]) if item[1] else "")
		row_button(value,func():
			model.s.event = i
			message = "%s selected." % item[0]
			commit(true), i == model.s.event)
	body("SECURITY & NEIGHBORS",GOLD,12)
	for i in Campaign.SECURITY.size():
		var crew: String = Campaign.SECURITY[i]
		row_button(crew+[" · no fee"," · ฿480"," · ฿255 / draws heat"][i],func():
			model.s.security = i
			commit(true),i == model.s.security)
	body("TOYBOX ARCADE",GOLD,12)
	row_pair("Quick spar",enter_fight.bind(true), "Run the circuit",enter_fight.bind(true,true))

func tours_panel() -> void:
	title("City tours")
	body("Guides opt in. Short tours use one wave. Long tours use two. Pay is due even if the route is disrupted.")
	var crew: Array = model.s.staff
	row_pair("Guide: "+Content.STAFF[crew[guide].id][0],func():
		guide = (guide+1)%crew.size()
		render(true),
		["Base split","Standard split","Premium split"][int(model.s.pay)],cycle.bind("pay",[0,1,2]))
	for i in Content.ROUTES.size():
		var item: Array = Content.ROUTES[i]
		var booked: bool = model.s.bookings.get(str(guide),-1) == i
		var declined: String = model.tour_offer(guide,i)
		row_button(("%s  ·  %s" % [item[0],"Confirmed" if booked else "Short" if item[2] == 1 else "Long"]),func():
			message = model.booking(guide,i)
			commit(true),booked)
		body("%s ticket · %s pay%s" % [cash(item[1]+int(model.s.route)*35),cash(model.guide_pay(i))," / "+declined if not declined.is_empty() else ""],MUTED,12)
	body("%d guide bookings tonight" % model.s.bookings.size(),GOLD,13)

func empire_panel() -> void:
	title("Build something that lasts")
	body("Anong · %d trust   /   Neighborhood · %d trust\nSafety %d   /   Repairs %d   /   Permits %d   /   Visa %d" % [
		model.s.partner,model.s.trust,model.s.safety,model.s.condition,model.s.license,model.s.visa],WHITE,14)
	row_pair("Repairs · ฿500",do_action.bind("repair"),"Paperwork · ฿330",do_action.bind("paper"))
	row_button("Renovate to level %d · %s" % [mini(4,int(model.s.level)+1),cash(1800*int(model.s.level))],do_action.bind("reno"))
	row_button("Nok's food counter · ฿1,050",do_action.bind("food"))
	row_button("Open High Tide · ฿9,600",do_action.bind("venue"))
	body("Reserve %s    ·    Outstanding %s" % [cash(model.s.reserve),cash(model.s.debt)],GOLD,13)
	row_pair("Save ฿500",do_action.bind("reserve"),"Release ฿500",do_action.bind("draw"))
	body("RIVAL PRESSURE %d  /  ANTON, LANTERN HOUSE" % model.s.rival,GOLD,12)
	row_button("Share festival dates · ฿420",do_action.bind("rival"))
	body("RIG MARKET %d   ·   COOLING %d%%" % [model.s.market,model.s.rig],GOLD,12)
	row_button("Install starter rig · ฿5,600",do_action.bind("rig"))
	if model.s.rig > 0:
		row_button("Rig: "+["Offline","Independent","Lantern contract"][int(model.s.contract)],do_action.bind("mine_switch"))
		row_button("Service cooling · ฿680",do_action.bind("cool"))

func journal_panel() -> void:
	title("Anong's books")
	body("Week %d · Till %s · Reserve %s
Rent and permits due on Tuesday." % [model.week(),cash(model.s.cash),cash(model.s.reserve)])
	week_lines(model.s.weekly)
	if not model.s.last_week.is_empty(): week_lines(model.s.last_week)
	body("RECENT SHIFTS",GOLD,12)
	for line in model.s.log: body(str(line),WHITE,14)
	row_button("Restart campaign" if not confirmation else "Erase this run and restart",restart)

func week_lines(entry: Dictionary) -> void:
	body("WEEK %d    %d shifts / %d guests / %d tour tickets" % [entry.weeks,entry.nights,entry.guests,entry.tours],GOLD,12)
	body("Intake %s   ·   Costs %s\nNet %s" % [cash(entry.revenue),cash(entry.costs),cash(entry.revenue-entry.costs)],WHITE,15)

func incident_panel() -> void:
	var card: Array = model.current_card()
	body("%s   /   WAVE %d" % [["EARLY SERVICE","THE RUSH","LAST CALL"][int(model.s.night.wave)],int(model.s.night.wave)+1],GOLD,12)
	title(card[0],PINK)
	body(card[1],WHITE)
	for i in range(2,card.size(),2):
		row_button(card[i],choose.bind((i-2)/2))
		var effects: Dictionary = card[i+1]
		if effects.has("cash") and effects.cash < 0:
			body("%s from the till" % cash(-effects.cash),MUTED,12)
	body("%d served so far   ·   %d turned away" % [model.s.night.guests,model.s.night.turned],GOLD,13)

func choose(index: int) -> void:
	message = model.pick(index)
	commit()
	if model.s.phase == "fight": enter_fight(false)

func report_panel() -> void:
	var n: Dictionary = model.s.night
	title("Closeout  /  Day %d" % model.s.day)
	body("%s net    ·    %d served    ·    %d missed" % [cash(n.cash),n.guests,n.turned],TEAL,17)
	body("Bar %s · Payroll %s · Fees %s\nStock used %d · Tour tickets %d" % [
		cash(n.gross),cash(n.wages),cash(n.fees),n.sold,n.tours],WHITE,14)
	if int(model.s.day)%7 == 0: week_lines(model.s.last_week)
	for line in model.s.report: body(str(line),MUTED,13)

func ending_panel() -> void:
	title(model.s.end,GOLD)
	var description: String = {
		"The Final Notice":"The landlord changes the lock. Dao has already organized a fair handover for the team.",
		"A Different Shore":"Anong and the owner make room for a life beyond the receipts and last calls.",
		"The Empty Office":"The lights are still on. Anong leaves a short note and the keys, and makes a plan of her own.",
		"The Neon Empire":"Across the bay, two neon signs are visible from the harbor. The next power bill is already in the inbox.",
		"The Neighborhood Institution":"The owner never got the empire. The team got a reliable rota, and the regulars saved them a table.",
	}.get(model.s.end,"The Blue Hour closes its books.")
	body(description,WHITE)
	body("%d days · %d guests · %d arcade wins" % [model.s.day,model.s.total_guests,model.s.wins],TEAL)
	body("Till %s · Reserve %s · Due %s" % [cash(model.s.cash),cash(model.s.reserve),cash(model.s.debt)],WHITE)

func restart() -> void:
	if not confirmation:
		confirmation = true
		message = "Press again to replace this campaign."
		render(true)
		return
	model = Campaign.new()
	confirmation = false
	guide = 2
	tab = 0
	message = ""
	commit()

func enter_fight(practice: bool, circuit: bool = false) -> void:
	if is_instance_valid(fight): return
	training = practice
	arcade_circuit = circuit
	fight = Fight.new()
	fight.size = Vector2(960,540)
	fight.rival_index = 0 if circuit else (int(model.s.day)+int(model.s.wins))%Fight.RIVALS.size()
	fight.circuit = circuit
	fight.finished.connect(leave_fight)
	fight.sound.connect(tone)
	root_ui.hide()
	city.set_process(false)
	add_child(fight)

func leave_fight(won: bool) -> void:
	if not is_instance_valid(fight): return
	remove_child(fight)
	fight.queue_free()
	fight = null
	if not training:
		model.finish_fight(won)
		commit()
	else:
		if arcade_circuit:
			message = "Toybox champion." if won else "Circuit ended. Try again from Events."
		render(true)


func walk_district() -> void:
	district = District.new()
	district.size = Vector2(960,540)
	district.weather = int(model.s.weather)
	district.destination.connect(func(index: int):
		close_district()
		change_tab(index))
	district.dismissed.connect(close_district)
	root_ui.hide()
	city.set_process(false)
	add_child(district)

func close_district() -> void:
	remove_child(district)
	district.queue_free()
	district = null
	city.set_process(true)
	root_ui.show()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(district): close_district()
		elif is_instance_valid(fight): leave_fight(fight.result if fight.over else false)
		elif tab != 0 and model.s.phase == "plan": change_tab(0)
