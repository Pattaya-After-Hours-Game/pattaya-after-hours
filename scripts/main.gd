extends Control

const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/content.gd")
const City = preload("res://scripts/city.gd")
const District = preload("res://scripts/district.gd")
const Fight = preload("res://scripts/fight.gd")
const WindowsUpdates = preload("res://scripts/windows_updates.gd")
const TEAL = Color("#71f9d2")
const PINK = Color("#ff80b2")
const GOLD = Color("#ffd083")
const WHITE = Color("#f6e4f3")
const MUTED = Color("#b8a9cb")
const EDGE = Color("#3b2c54")
const DARK = Color("#151027")
const TAB_NAMES = ["Service","Events","Tours","Empire","Journal"]
const PRACTICE_STOCK = 24
const SHOT_GOAL = 10
const SHOT_INTERVAL = 0.60
const GODZILLA_SECONDS = 10.0
const COMPACT_EFFECTS = {
	"trust":"neighbors","supplier":"supplier","morale":"morale","fatigue":"fatigue",
	"skill":"skill","condition":"condition","rival":"rivals","mine":"rig output",
	"tour":"tours","route":"tour route","demand":"demand","capacity":"capacity","partner":"Anong trust",
}
const EFFECT_LABELS = {
	"cash":"Till","reserve":"Reserve","debt":"Debt","stock":"Stock","rep":"Reputation",
	"trust":"Neighborhood trust","partner":"Anong trust","safety":"Safety","heat":"Heat",
	"supplier":"Supplier reliability","regulars":"Regulars","morale":"Team morale",
	"fatigue":"Team fatigue","skill":"Team skill","condition":"Building condition",
	"license":"Permits","visa":"Visa","rival":"Rival pressure","rig":"Rig cooling",
	"mine":"Rig output factor","tour":"Tour adjustment","route":"Tour route level",
	"demand":"Demand this wave","capacity":"Capacity this wave",
}

var model = Campaign.new()
var campaign_before_tutorial: Campaign
var show_tutorial_hint := false
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
var show_details := false
var godzilla_shots := 0
var godzilla_time := 0.0
var shot_delay := 0.0
var godzilla_meter: ProgressBar
var godzilla_meter_label: Label
var godzilla_clock: Label
var windows_updates: WindowsUpdates
var update_button: Button

func _ready() -> void:
	if WindowsUpdates.is_worker():
		WindowsUpdates.apply_update(get_tree())
		return
	if WindowsUpdates.supported():
		windows_updates = WindowsUpdates.new()
		add_child(windows_updates)
		windows_updates.update_available.connect(_update_available)
	var interface_font := FontVariation.new()
	interface_font.base_font = ThemeDB.fallback_font
	interface_font.fallbacks = [preload("res://assets/DejaVuSans.ttf")]
	theme = Theme.new()
	theme.default_font = interface_font
	show_tutorial_hint = not model.load_game()
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
	if windows_updates != null:
		windows_updates.confirm_restart()
		if DisplayServer.get_name() != "headless": windows_updates.check()

func _update_available() -> void:
	update_button.show()
	if model.s.phase == "plan" and campaign_before_tutorial == null and not is_instance_valid(district):
		windows_updates.ask()

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
	if campaign_before_tutorial != null: return
	show_tutorial_hint = false
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
	var practicing := campaign_before_tutorial != null
	pane(root_ui,Rect2(0,0,960,540),Color("#100c1d"),Color("#100c1d"))
	pane(root_ui,Rect2(0,0,960,3),PINK,PINK)
	abs_text(root_ui,Rect2(17,7,360,26),"PATTAYA AFTER HOURS",24,WHITE)
	var status: String = "%s · %s" % [model.weekday(),Content.WEATHER[int(model.s.weather)]]
	abs_text(root_ui,Rect2(18,36,320,20),("PRACTICE SHIFT" if practicing else "THE BLUE HOUR")+"   /   "+status,13,GOLD if practicing else TEAL)
	if windows_updates != null:
		update_button = at_button(root_ui,Rect2(296,14,55,40),"Update",windows_updates.ask,true)
		update_button.add_theme_font_size_override("font_size",12)
		update_button.visible = not windows_updates.tag.is_empty()
		update_button.disabled = model.s.phase == "godzilla"
	metric(355,"TILL",cash(model.s.cash) if model.s.cash < 100000 else "฿%.1fk" % (model.s.cash / 1000.0),TEAL)
	metric(465,"STOCK",str(int(model.s.stock)),GOLD)
	metric(558,"REPUTATION",str(int(model.s.rep)),TEAL)
	metric(676,"HEAT",str(int(model.s.heat)),PINK)
	metric(762,"SHIFT","D%03d" % int(model.s.day),WHITE)
	var tutorial_button := at_button(root_ui,Rect2(816,14,63,40),"Exit" if practicing else "Tutorial",finish_tutorial if practicing else start_tutorial)
	tutorial_button.disabled = model.s.phase == "godzilla"
	at_button(root_ui,Rect2(883,14,62,40),"Muted" if muted else "Sound",set_sound)
	pane(root_ui,Rect2(14,66,550,386),DARK)
	city = City.new()
	city.position = Vector2(16,68)
	city.size = Vector2(546,370)
	city.clip_contents = true
	city.night = model.s.phase in ["incident","fight","report","godzilla"]
	city.godzilla = model.s.night.get("godzilla","") if city.night else ""
	city.guests = model.s.night.get("guests",0) if city.night else 0
	city.weather = int(model.s.weather)
	city.level = int(model.s.level)
	city.venue = int(model.s.venue)
	city.rig = int(model.s.rig)
	city.site.connect(func(index: int):
		if not practicing and model.s.phase == "plan": change_tab(index))
	root_ui.add_child(city)
	pane(root_ui,Rect2(16,438,546,14),Color("#251a36"),EDGE)
	var district_status := "SERVICE LIVE" if city.night else "PRE-SHIFT"
	match city.godzilla:
		"attack": district_status = "GODZILLA AT THE DOOR"
		"asleep": district_status = "GODZILLA ASLEEP OUT FRONT"
		"scared": district_status = "BAR EMPTY"
	abs_text(root_ui,Rect2(24,435,527,19),"BAY DISTRICT   /   "+district_status,10,WHITE)
	pane(root_ui,Rect2(14,461,550,65),DARK)
	var first_shift := show_tutorial_hint and not practicing
	var results: Array = model.s.night.get("results",[]) if city.night else []
	if results.is_empty():
		abs_text(root_ui,Rect2(26,467,265,20),"YOUR FIRST SHIFT" if first_shift else "THE SHIFT LOG",13,GOLD)
		var log_text := "Select Tutorial above to try a practice shift." if first_shift else str(model.s.log.front()).left(61)
		abs_text(root_ui,Rect2(26,490,410,24),log_text,14,MUTED)
	else:
		var last: Dictionary = results.back()
		var heading := abs_text(root_ui,Rect2(26,465,524,17),result_heading(last),13,TEAL if last.worked else PINK)
		heading.clip_text = true
		var detail := abs_text(root_ui,Rect2(26,482,524,27),effect_text(last.changes,true),12,WHITE)
		detail.clip_text = true
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.max_lines_visible = 2
		var wave: Dictionary = model.s.night.get("last_wave",{})
		if not wave.is_empty():
			var limit := " · "+str(wave.limit) if not str(wave.limit).is_empty() else ""
			abs_text(root_ui,Rect2(26,509,524,15),"Last wave: %d served · %s sales · %d missed%s" % [
				wave.served,cash(wave.sales),wave.missed,limit],12,MUTED)
	if not practicing and model.s.phase == "plan":
		at_button(root_ui,Rect2(435,473,117,41),"Walk district",walk_district)
	pane(root_ui,Rect2(576,66,370,460),DARK)
	if model.s.phase == "plan" and not practicing:
		for index in TAB_NAMES.size():
			var b := at_button(root_ui,Rect2(582 + 71*index,72,69,37),TAB_NAMES[index],change_tab.bind(index),tab == index)
			b.add_theme_font_size_override("font_size",13)
	elif model.s.phase in ["incident","report"]:
		var section := "SHIFT SUMMARY"
		var details := "Shift log"
		if model.s.phase == "incident":
			section = "WAVE %d / %d" % [int(model.s.night.wave)+1,2 if model.s.hours == 0 else 3]
			details = "Story"
		abs_text(root_ui,Rect2(586,72,220,37),section,13,GOLD)
		at_button(root_ui,Rect2(842,72,94,37),"Hide" if show_details else details,toggle_details)
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
			if practicing:
				title("1 / 3    Stock the bar")
				if model.s.stock == PRACTICE_STOCK:
					body("Buy stock to open the bar.")
					row_button(stock_label(),do_action.bind("buy"),true)
				else:
					body("Stock is ready. Open the doors.",TEAL)
			else:
				match tab:
					0: service_panel()
					1: events_panel()
					2: tours_panel()
					3: empire_panel()
					4: journal_panel()
			action_label = "Open the doors"
			action = begin
		"incident":
			if practicing:
				title("2 / 3    Run the shift")
				body("Pick a response. The result appears below the map.")
			incident_panel()
			action_label = "Scale back service"
			action = func():
				model.fallback()
				commit()
		"report":
			if practicing:
				title("3 / 3    Check the books")
				body("Check the net and how many guests you served.")
			report_panel()
			if practicing:
				action_label = "Finish tutorial"
				action = finish_tutorial
			else:
				action_label = "Finish the story" if not model.s.end.is_empty() else "Next day"
				action = advance
		"end":
			ending_panel()
			action_label = "Start a new run" if not confirmation else "Confirm new run"
			action = restart
		"godzilla":
			godzilla_panel()
			action_label = "Serve a shot"
			action = serve_godzilla
		"fight":
			title("Toybox showdown")
			body("Mali is ready to return to the floor.")
			action_label = "Resume the fight"
			action = enter_fight.bind(false)
	if not message.is_empty():
		var note := abs_text(root_ui,Rect2(588,454,344,27),message,12,PINK)
		note.clip_text = true
	elif model.s.phase == "incident":
		var chance: int = model.response_risk(Campaign.SCALE_BACK).chance
		abs_text(root_ui,Rect2(588,454,344,27),"Scale back · %d%% contained / %d%% worse" % [chance,100-chance],12,MUTED)
	var primary := at_button(root_ui,Rect2(585,480,352,37),action_label,action,true)
	primary.disabled = practicing and model.s.phase == "plan" and model.s.stock == PRACTICE_STOCK
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

func body(value: String,tint: Color = MUTED, px: int = 15) -> Label:
	var element := Label.new()
	element.text = value
	element.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	element.add_theme_color_override("font_color",tint)
	element.add_theme_font_size_override("font_size",px)
	column.add_child(element)
	return element

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
	show_details = false
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

func start_tutorial() -> void:
	if campaign_before_tutorial != null: return
	show_details = false
	campaign_before_tutorial = model
	show_tutorial_hint = false
	confirmation = false
	message = ""
	model = Campaign.new(72)
	model.s.stock = PRACTICE_STOCK
	model.s.hours = 0
	render()

func finish_tutorial() -> void:
	if campaign_before_tutorial == null: return
	show_details = false
	model = campaign_before_tutorial
	campaign_before_tutorial = null
	message = ""
	render()

func stock_label() -> String:
	var amount := mini(30,105+int(model.s.level)*20-int(model.s.stock))
	return "Stock +%d · %s" % [amount,cash(amount*model.stock_price())]

func service_panel() -> void:
	title("Set the shift")
	body("%s traffic expected" % ("Heavy" if model.s.forecast >= 9 else "Light" if model.s.forecast < 0 else "Steady"))
	row_pair("Hours: "+Campaign.HOURS[int(model.s.hours)],cycle.bind("hours",Campaign.HOURS),
		Campaign.PROMOS[int(model.s.promo)],cycle.bind("promo",Campaign.PROMOS))
	row_pair(stock_label(),do_action.bind("buy"),"Hire · ฿980",do_action.bind("hire"))
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
	var disrupted: int = model.event_disruption_percent()
	var canceled := disrupted * Campaign.CANCEL_IF_DISRUPTED
	body("%d%% on time · %.1f%% delayed · %.1f%% canceled
Booking fee applies if canceled." % [100-disrupted,disrupted-canceled,canceled])
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
	body("Short tours 1 wave · Long tours 2 waves
Guides get paid if a tour is disrupted.")
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
		var chance: int = model.tour_disruption_percent(crew[guide],i)
		var risk_text := declined if not declined.is_empty() else "%d%% disruption" % chance
		body("%s ticket · %s pay · %s" % [cash(item[1]+int(model.s.route)*35),cash(model.guide_pay(i)),risk_text],MUTED,12)
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

func toggle_details() -> void:
	show_details = not show_details
	render()

func incident_panel() -> void:
	var card: Array = model.current_card()
	title(card[0],PINK)
	if show_details: body(card[1],WHITE)
	for i in range(2,card.size(),2):
		var effects: Dictionary = card[i+1]
		var option := button(card[i],choose.bind((i-2)/2))
		option.disabled = model.s.cash < -int(effects.get("cash",0))
		column.add_child(option)
		if option.disabled: body("Not enough cash",PINK,12)
		if effects.has("fight"):
			body("Win · ฿240 repairs · Reputation up · Rivals back off",TEAL,12)
			body("Lose · ฿740 repairs · Reputation down · Mali off",PINK,12)
		else:
			response_odds(effects)
	if show_details:
		body("SCALE BACK SERVICE",GOLD,12)
		response_odds(Campaign.SCALE_BACK)

func response_odds(effects: Dictionary) -> void:
	var risk: Dictionary = model.response_risk(effects)
	body("%d%% works · %s" % [risk.chance,effect_text(risk.plan_changes,not show_details)],TEAL,13)
	body("%d%% setback · %s" % [100-int(risk.chance),effect_text(risk.setback_changes,not show_details)],PINK,13)

func effect_text(changes: Dictionary, compact: bool = false) -> String:
	var details := PackedStringArray()
	for key in changes:
		var delta: Variant = changes[key]
		match key:
			"security":
				details.append("Protection deal ends")
			"exit":
				details.append("Explore selling the bar")
			"food":
				details.append("Add food service")
			_:
				var value := ""
				if delta is Array:
					var low: int = delta.min()
					var high: int = delta.max()
					value = signed_delta(low) if low == high else "%s to %s" % [signed_delta(low),signed_delta(high)]
				elif key in ["cash","reserve","debt","tour"]:
					value = ("+" if int(delta) > 0 else "") + cash(delta)
				else:
					value = signed_delta(int(delta))
				if compact:
					var label: String = COMPACT_EFFECTS.get(key,str(EFFECT_LABELS[key]).to_lower())
					details.append(value if key == "cash" else "%s %s" % [value,label])
				else:
					details.append("%s %s" % [EFFECT_LABELS[key],value])
	return " · ".join(details) if not details.is_empty() else "No direct changes"

func signed_delta(value: int) -> String:
	return "%+d" % value if value != 0 else "0"

func result_heading(result: Dictionary) -> String:
	var odds := " (%d%%)" % int(result.chance) if result.chance > 0 else ""
	return result.outcome + odds + " · " + result.label

func choose(index: int) -> void:
	message = model.pick(index)
	commit()
	if model.s.phase == "fight": enter_fight(false)

func godzilla_panel() -> void:
	title("Godzilla attacks!",PINK)
	body("10 shots to save tonight’s bar sales.",WHITE)
	godzilla_meter_label = body("",GOLD,14)
	godzilla_meter = ProgressBar.new()
	godzilla_meter.custom_minimum_size.y = 22
	godzilla_meter.max_value = SHOT_GOAL
	godzilla_meter.show_percentage = false
	godzilla_meter.add_theme_stylebox_override("background",box(Color("#241638"),EDGE))
	godzilla_meter.add_theme_stylebox_override("fill",box(PINK,PINK))
	column.add_child(godzilla_meter)
	godzilla_clock = body("",TEAL,19)
	body("Tap or press Space when the glass is ready.",MUTED,14)
	update_godzilla_panel()

func update_godzilla_panel() -> void:
	godzilla_meter.value = godzilla_shots
	city.shot_flash = shot_delay / SHOT_INTERVAL
	godzilla_meter_label.text = "INTOXICATION  ·  %d%%" % (godzilla_shots * 100 / SHOT_GOAL)
	if godzilla_shots == 0:
		godzilla_clock.text = "%d seconds from the first shot" % int(GODZILLA_SECONDS)
	else:
		godzilla_clock.text = "%.1fs   ·   %s" % [godzilla_time,"READY" if shot_delay <= 0 else "REFILLING"]

func serve_godzilla() -> void:
	if model.s.phase != "godzilla" or shot_delay > 0: return
	if godzilla_shots == 0: godzilla_time = GODZILLA_SECONDS
	godzilla_shots += 1
	shot_delay = SHOT_INTERVAL
	if godzilla_shots >= SHOT_GOAL:
		resolve_godzilla(true)
	else:
		update_godzilla_panel()

func _process(delta: float) -> void:
	if model.s.phase != "godzilla" or godzilla_shots == 0: return
	godzilla_time = maxf(0.0,godzilla_time - delta)
	shot_delay = maxf(0.0,shot_delay - delta)
	if godzilla_time <= 0:
		resolve_godzilla(false)
	else:
		update_godzilla_panel()

func resolve_godzilla(won: bool) -> void:
	model.finish_godzilla(won)
	godzilla_shots = 0
	godzilla_time = 0.0
	shot_delay = 0.0
	message = "Godzilla passed out. Open for service." if won else ""
	tone("gong")
	commit()

func report_panel() -> void:
	var n: Dictionary = model.s.night
	title("Closeout  /  Day %d" % model.s.day)
	body("%s net    ·    %d served    ·    %d missed" % [cash(n.cash),n.guests,n.turned],TEAL,17)
	if n.get("godzilla","") == "scared":
		body("The crowd fled. No bar sales tonight.",PINK)
	body("Bar %s · Payroll %s · Fees %s\nStock used %d · Tour tickets %d" % [
		cash(n.gross),cash(n.wages),cash(n.fees),n.sold,n.tours],WHITE,14)
	if int(model.s.day)%7 == 0: week_lines(model.s.last_week)
	if not show_details: return
	var results: Array = n.get("results",[])
	if not results.is_empty():
		body("DECISIONS THIS SHIFT",GOLD,12)
		for result in results:
			body(result_heading(result),TEAL if result.worked else PINK,13)
			body(effect_text(result.changes),WHITE,12)
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
		elif campaign_before_tutorial != null: finish_tutorial()
		elif tab != 0 and model.s.phase == "plan": change_tab(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if model.s.phase == "godzilla" and event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		serve_godzilla()
	elif campaign_before_tutorial != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_tutorial()
