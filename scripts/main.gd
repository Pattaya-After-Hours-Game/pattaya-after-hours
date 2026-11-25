extends Control

const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/content.gd")
const StreetContent = preload("res://scripts/street_content.gd")
const City = preload("res://scripts/city.gd")
const District = preload("res://scripts/district.gd")
const Art = preload("res://scripts/art.gd")
const Fight = preload("res://scripts/fight.gd")
const WindowsUpdates = preload("res://scripts/windows_updates.gd")
const TEAL = Color("#71f9d2")
const PINK = Color("#ff80b2")
const GOLD = Color("#ffd083")
const WHITE = Color("#f6e4f3")
const MUTED = Color("#b8a9cb")
const EDGE = Color("#79553e")
const DARK = Color("#241820")
const EFFECT_LABELS = {
	"cash":"Till","reserve":"Reserve","debt":"Debt","stock":"Stock","rep":"Reputation",
	"trust":"Neighborhood trust","partner":"Anong trust","safety":"Safety","heat":"Heat",
	"supplier":"Supplier reliability","regulars":"Regulars","morale":"Team morale",
	"fatigue":"Team fatigue","skill":"Team skill","condition":"Building condition",
	"license":"Permits","visa":"Visa","rival":"Rival pressure","rig":"Rig cooling",
	"mine":"Rig output factor","tour":"Tour adjustment","route":"Tour route level",
	"demand":"Demand this wave","capacity":"Capacity this wave",
}
const COMPACT_EFFECTS = {
	"trust":"neighbors","supplier":"supplier","morale":"morale","fatigue":"fatigue",
	"skill":"skill","condition":"condition","rival":"rivals","mine":"rig output",
	"tour":"tours","route":"tour route","demand":"demand","capacity":"capacity","partner":"Anong trust",
}
const TAB_NAMES = ["Service","Events","Tours","Empire","Journal"]
const PRACTICE_STOCK = 24
const SHOT_GOAL = 10
const SHOT_INTERVAL = 0.60
const GODZILLA_SECONDS = 10.0

var model = Campaign.new()
var campaign_before_tutorial: Campaign
var show_tutorial_hint := false
var offline_notice := 0
var drawer_open := false
var drawer: Control
var event_banner: Button
var scene_clock := 0.0
var service_animation := 0.0
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

var live_labels: Array = []
var live_seconds := 0.0
var save_seconds := 0.0
var serve_delay := 0.0
var refresh_street := false
var show_details := false
var confirmation := false
var godzilla_shots := 0
var godzilla_time := 0.0
var shot_delay := 0.0
var godzilla_meter: ProgressBar
var godzilla_meter_label: Label
var godzilla_clock: Label
var windows_updates: WindowsUpdates
var update_button: Button
var updater_worker := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	updater_worker = WindowsUpdates.is_worker()
	if updater_worker:
		set_process(false)
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
	if not show_tutorial_hint:
		offline_notice = model.street.claim_offline(int(Time.get_unix_time_from_system()))
		save_state()
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
	if is_instance_valid(update_button): update_button.show()
	if model.s.phase == "plan" and campaign_before_tutorial == null and not is_instance_valid(district) and not is_instance_valid(fight):
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
	element.mouse_filter = Control.MOUSE_FILTER_IGNORE
	element.text = value
	element.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element.add_theme_color_override("font_color",tint)
	element.add_theme_font_size_override("font_size",px)
	parent.add_child(element)
	return element

func button(value: String, call: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 40
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",Color("#111d22") if primary else WHITE)
	b.add_theme_color_override("font_hover_color",Color("#111d22") if primary else WHITE)
	b.add_theme_color_override("font_pressed_color",Color("#111d22") if primary else TEAL)
	b.add_theme_color_override("font_focus_color",Color("#111d22") if primary else WHITE)
	b.add_theme_stylebox_override("normal",box(TEAL if primary else Color("#2e2028"),TEAL.darkened(.15) if primary else EDGE))
	b.add_theme_stylebox_override("hover",box(Color("#b2ffe8") if primary else Color("#49303a"),PINK))
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
	drawer_open = true
	message = ""
	render()

func render(keep_scroll: bool = false) -> void:
	live_labels.clear()
	refresh_street = false
	var previous := scroll.scroll_vertical if keep_scroll and is_instance_valid(scroll) else 0
	if is_instance_valid(root_ui):
		remove_child(root_ui)
		root_ui.queue_free()
	root_ui = Control.new()
	root_ui.size = Vector2(960,540)
	add_child(root_ui)
	var practicing := campaign_before_tutorial != null
	pane(root_ui,Rect2(0,0,960,540),Color("#170f18"))
	city = City.new()
	city.position = Vector2(0,48)
	city.size = Vector2(960,540)
	city.clip_contents = true
	city.clock = scene_clock
	city.service_flash = service_animation
	city.night = model.s.phase in ["incident","fight","report","godzilla"]
	city.godzilla = model.s.night.get("godzilla","")
	city.guests = model.s.night.get("guests",0)
	city.weather = int(model.s.weather)
	city.level = int(model.s.level)
	city.legacy_staff = model.s.staff
	if not practicing:
		city.bars = model.s.street.bars
		city.street_state = model.s.street
		city.selected_bar = int(model.s.street.selected)
		city.street_event = model.s.street.event
	root_ui.add_child(city)
	# Full-width scene, with all live text rendered at the UI resolution.
	pane(root_ui,Rect2(0,0,960,48),Color("#21161ff5"))
	abs_text(root_ui,Rect2(14,4,170 if windows_updates != null else 235,24),"AFTER HOURS" if windows_updates != null else "PATTAYA / AFTER HOURS",19,GOLD)
	var date_label := abs_text(root_ui,Rect2(14,27,170 if windows_updates != null else 245,16),"PRACTICE SHIFT" if practicing else "D%d · %s · %s" % [model.s.day,model.weekday(),model.street.selected().name],12,TEAL)
	date_label.clip_text = true
	if windows_updates != null:
		update_button = at_button(root_ui,Rect2(190,5,66,37),"Update",windows_updates.ask,true)
		update_button.add_theme_font_size_override("font_size",12)
		update_button.visible = not windows_updates.tag.is_empty()
		update_button.disabled = model.s.phase == "godzilla"
	metric(268,"TILL",cash(model.s.cash),TEAL)
	metric(377,"STOCK",str(int(model.s.stock) if practicing else int(model.street.selected().stock)),GOLD)
	metric(462,"REPUTATION",str(int(model.s.rep)),TEAL)
	metric(570,"HEAT",str(int(model.s.heat)),PINK)
	metric(644,"SHIFT" if practicing else "TIME","D%03d" % int(model.s.day) if practicing else model.street.clock_text(),WHITE)
	var tutorial_button := at_button(root_ui,Rect2(748,5,92,37),"Exit" if practicing else "Tutorial",finish_tutorial if practicing else start_tutorial)
	tutorial_button.disabled = model.s.phase == "godzilla"
	at_button(root_ui,Rect2(848,5,98,37),"Muted" if muted else "Sound",set_sound)
	event_banner = null
	if not practicing and not model.s.street.event.is_empty():
		event_banner = at_button(root_ui,Rect2(14,56,540,36),"",change_tab.bind(1))
		event_banner.add_theme_color_override("font_color",PINK)
		var banner_text := func() -> String:
			var e: Dictionary = model.s.street.event
			if e.is_empty(): return ""
			return "%s · %s · %ds  ›" % ["SOON" if e.phase == "warning" else "LIVE",StreetContent.EVENTS[int(e.id)][0],e.remaining]
		event_banner.text = banner_text.call()
		live_labels.append([event_banner,banner_text])
	# Property cards remain selectable without opening management.
	if not practicing:
		for i in 8:
			var occupied: bool = i < model.s.street.bars.size()
			var card := at_button(root_ui,Rect2(14+i*67,421,62,55),"",select_bar.bind(i) if occupied else change_tab.bind(3),occupied and i == model.s.street.selected)
			card.name = "Property%d" % i
			card.clip_contents = true
			card.disabled = model.s.phase != "plan"
			card.tooltip_text = str(model.s.street.bars[i].name) if occupied else "Available lease · open Empire"
			if occupied:
				var b: Dictionary = model.s.street.bars[i]
				var thumb := TextureRect.new()
				thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				thumb.texture = Art.venue(int(b.type),int(b.stage))
				thumb.position = Vector2(3,3)
				thumb.size = Vector2(56,32)
				thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(thumb)
				abs_text(card,Rect2(2,34,58,18),"%d · %s %d" % [i+1,["BEER","SOI","GOGO"][int(b.type)],b.stage],10,Color("#241820") if i == model.s.street.selected else GOLD)
			else:
				card.text = "+\nLEASE"
				card.add_theme_font_size_override("font_size",11)
	var first_shift := show_tutorial_hint and not practicing
	var log_text := "Serve → upgrade → hire → grow" if first_shift else str(model.s.log.front())
	pane(root_ui,Rect2(14,390,540,27),Color("#21161fdd"))
	var note := abs_text(root_ui,Rect2(20,393,530,22),message if not message.is_empty() else log_text,13,GOLD)
	note.clip_text = true
	pane(root_ui,Rect2(0,482,960,58),Color("#21161ff8"))
	for index in TAB_NAMES.size():
		var b := at_button(root_ui,Rect2(14+index*88,490,82,40),TAB_NAMES[index],toggle_drawer.bind(index),drawer_open and tab == index)
		b.add_theme_font_size_override("font_size",13)
		b.disabled = model.s.phase != "plan" or practicing
	var walk := at_button(root_ui,Rect2(459,490,116,40),"Walk district",walk_district)
	walk.disabled = practicing or model.s.phase != "plan"
	drawer = Control.new()
	drawer.position = Vector2(570,54)
	drawer.size = Vector2(380,422)
	root_ui.add_child(drawer)
	pane(drawer,Rect2(0,0,380,422),Color("#241820f7"))
	abs_text(drawer,Rect2(16,5,290,30),"SHIFT DESK" if practicing or model.s.phase != "plan" else TAB_NAMES[tab].to_upper(),16,GOLD)
	if not practicing and model.s.phase == "plan":
		at_button(drawer,Rect2(324,4,48,36),"×",close_drawer)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(14,44)
	scroll.size = Vector2(352,366)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.scroll_deadzone = 8
	drawer.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",9)
	scroll.add_child(column)
	drawer.visible = drawer_open or practicing or model.s.phase != "plan"
	var action_label := ""
	var action: Callable
	match model.s.phase:
		"plan":
			if practicing:
				title("1 / 3    Stock the bar")
				if model.s.stock == PRACTICE_STOCK:
					body("Check STOCK at the top. Every two guests use one unit. Buy a delivery before opening.")
					row_button(stock_label(),do_action.bind("buy"),true)
				else:
					body("Delivery in. Open the doors to serve two waves of guests.",TEAL)
				body("Dao, Mali, and Fern are on tonight. In the campaign, give tired staff a night off.")
			else:
				match tab:
					0: service_panel()
					1: events_panel()
					2: tours_panel()
					3: empire_panel()
					4: journal_panel()
			action_label = "Open the doors" if practicing else "Serve a drink"
			action = begin if practicing else street_action.bind("serve")
		"guided":
			title("Guided shift · live service")
			live_body(func() -> String: return "Wave %d/3 · %ds into this shift" % [int(model.s.street.guided.wave)+1,model.s.street.seconds],GOLD)
			street_panel()
			action_label = "Serve a drink"
			action = street_action.bind("serve")
		"guided_choice":
			title(["Open the doors","The rush","Last call"][int(model.s.street.guided.wave)])
			body("Anong: Read the room. Customers and stock are real; choosing a response does not skip the clock.")
			row_button("Serve a waiting order",choose.bind(0))
			row_button("Welcome passersby",choose.bind(1))
			action_label = "Continue normal service"
			action = choose.bind(2)
		"guided_report":
			title("Guided shift complete")
			shift_report(model.street.selected())
			body("The same live ledger has already recorded these results. Returning to the street adds no extra money or time.")
			action_label = "Back to the street"
			action = advance
		"incident":
			if practicing:
				title("2 / 3    Run the shift")
				body("Choose a response to serve the next wave. Spending can help service or relationships.")
			incident_panel()
			action_label = "Scale back service"
			action = func():
				model.fallback()
				commit()
		"report":
			if practicing:
				title("3 / 3    Check the books")
				body("Compare sales with payroll and fees. Check guests turned away and stock used before planning tomorrow.")
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
	var live_service: bool = not practicing and model.s.phase in ["plan","guided"]
	var primary := at_button(root_ui,Rect2(594,490,170 if live_service else 352,40),action_label,action,true)
	if live_service:
		var welcome_button := at_button(root_ui,Rect2(774,490,172,40),"Welcome customers",street_action.bind("welcome"))
		welcome_button.disabled = not model.street.economy.is_trading(model.street.selected())
		var demand_note := abs_text(root_ui,Rect2(14,100,540,42),"",14,GOLD)
		live_labels.append([demand_note,func() -> String:
			var bar: Dictionary = model.street.selected()
			var warning := ""
			if model.s.street.minute>=30 and model.s.street.minute<60: warning = "1am closing soon · "
			elif model.s.street.minute>=60 and model.s.street.minute<180 and model.street.economy.is_trading(bar): warning = "LATE TRADE · Heat %d · " % model.s.heat
			return "%d/%d customers · %d orders waiting\n%s%s" % [bar.customers.size(),model.street.economy.seats(bar),model.street.economy.pending(bar),warning,model.street.economy.forecast(bar).reason]])
		demand_note.text = live_labels.back()[1].call()
	primary.disabled = (practicing and model.s.phase == "plan" and model.s.stock == PRACTICE_STOCK) or (live_service and not model.street.economy.is_trading(model.street.selected()))
	if offline_notice > 0 and not practicing and model.s.phase == "plan":
		var shade := ColorRect.new()
		shade.size = Vector2(960,540)
		shade.color = Color(0.04,0.02,0.05,.65)
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
		root_ui.add_child(shade)
		var welcome := pane(root_ui,Rect2(200,155,560,200),Color("#241820"),GOLD)
		abs_text(welcome,Rect2(24,15,500,35),"WELCOME BACK",23,GOLD)
		abs_text(welcome,Rect2(24,59,500,30),"Estimated managed profit: "+cash(offline_notice)+" net.",21,TEAL)
		abs_text(welcome,Rect2(24,96,500,26),"Demand and costs included · estimates in Journal",14,MUTED)
		at_button(welcome,Rect2(24,142,512,40),"Back to the street",dismiss_offline,true)
	if previous > 0: scroll.set_deferred("scroll_vertical",previous)

func toggle_drawer(index: int) -> void:
	if drawer_open and tab == index:
		close_drawer()
	else:
		change_tab(index)

func close_drawer() -> void:
	drawer_open = false
	render()

func metric(x: int,name_text: String,value: String,tint: Color) -> void:
	abs_text(root_ui,Rect2(x,3,105,15),name_text,11,MUTED)
	var label := abs_text(root_ui,Rect2(x,20,105,24),value,18,tint)
	if campaign_before_tutorial == null:
		live_labels.append([label,func() -> String:
			match name_text:
				"TILL": return cash(model.s.cash) if model.s.cash < 100000 else "฿%.1fk" % (model.s.cash/1000.0)
				"STOCK": return str(model.street.selected().stock)
				"REPUTATION": return str(model.s.rep)
				"SHIFT": return "D%03d" % model.s.day
				"TIME": return model.street.clock_text()
			return str(model.s.heat)])

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

func character_card(id: String, heading: String, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	column.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = Art.texture("portrait-"+id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.custom_minimum_size = Vector2(56,56)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var description := Label.new()
	description.text = heading+"\n"+detail
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color",WHITE)
	description.add_theme_font_size_override("font_size",13)
	row.add_child(description)

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
	campaign_before_tutorial = model
	show_tutorial_hint = false
	confirmation = false
	message = ""
	model = Campaign.new(72,true)
	model.s.stock = PRACTICE_STOCK
	model.s.hours = 0
	render()

func finish_tutorial() -> void:
	if campaign_before_tutorial == null: return
	model = campaign_before_tutorial
	campaign_before_tutorial = null
	message = ""
	render()

func stock_label() -> String:
	var amount := mini(30,105+int(model.s.level)*20-int(model.s.stock))
	return "Stock +%d · %s" % [amount,cash(amount*model.stock_price())]

func service_panel() -> void:
	street_panel()
	title("Guided service")
	body("Optional three-wave guidance uses the same customers, stock and two-minute clock. Choices cannot skip time or generate extra sales.")
	row_button("Open managed shift",begin)

func events_panel() -> void:
	street_event_panel()
	title("Venue promotions")
	var bar: Dictionary = model.street.selected()
	body("One promotion for two minutes, then a two-minute cooldown. Repeated promotions have less pull. Check your seats and service first.")
	live_body(func() -> String: return "Operating costs: ฿%d/real min · break-even %.1f drinks/real min" % [model.street.economy.forecast(bar).costs,model.street.economy.forecast(bar).break_even],GOLD,13)
	for i in StreetContent.PROMOTIONS.size():
		var offer: Dictionary = StreetContent.PROMOTIONS[i]
		row_button("%s · %s" % [offer.name,cash(offer.fee)],street_action.bind("promotion",i))
		body(offer.help,MUTED,13)
		var estimate: Dictionary = model.street.economy.forecast(bar,false,i)
		body("With promotion fee: break-even %.1f drinks/real min · estimated staff-only net %s/real min." % [estimate.break_even,cash(estimate.net)],MUTED,12)
	promotion_report(bar)
	body("TOYBOX ARCADE",GOLD,12)
	row_pair("Quick spar",enter_fight.bind(true),"Run the circuit",enter_fight.bind(true,true))

func promotion_report(bar: Dictionary) -> void:
	live_body(func() -> String:
		if not bar.promo.is_empty(): return "%s · %ds remaining · attraction ÷ %d" % [StreetContent.PROMOTIONS[int(bar.promo.kind)].name,bar.promo.remaining,bar.promo.repetition]
		return "Promotion cooldown: %ds" % bar.promo_cooldown if bar.promo_cooldown>0 else "Ready to promote.",TEAL,14)
	if bar.promo_report.is_empty(): return
	var report: Dictionary = bar.promo_report
	body("LAST PROMOTION · "+StreetContent.PROMOTIONS[int(report.kind)].name,GOLD,13)
	live_body(func() -> String: return "Pool revenue %s · %d free games\nFees forgone %s\nAttributed customers %d · regulars %d · lost to queues %d\nAttributed drinks %s · stock %s\nShift operating costs %s · promotion fee %s\nAttributed contribution after these costs %s\nBaseline visitors without promotion: %.1f (estimate)" % [cash(report.pool_revenue),report.free_games,cash(int(report.free_games)*50),report.customers,report.regulars,report.lost,cash(report.drink_revenue),cash(report.drink_cost),cash(report.operating),cash(report.fee),cash(int(report.drink_revenue)+int(report.pool_revenue)-int(report.drink_cost)-int(report.operating)-int(report.fee)),float(report.baseline)],WHITE,13)

func tours_panel() -> void:
	title("City tours")
	character_card(Art.STAFF[int(model.s.staff[guide].id)],"Your guide","Voluntary bookings · fair splits")
	body("Pay a guide upfront to recommend your street this shift. Guides increase its appeal to existing passersby; they do not generate guaranteed ticket income.")
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
		body("%s route listing · %s guide pay%s" % [cash(item[1]+int(model.s.route)*35),cash(model.guide_pay(i))," / "+declined if not declined.is_empty() else ""],MUTED,12)
	body("%d guide bookings tonight" % model.s.bookings.size(),GOLD,13)

func empire_panel() -> void:
	title("One bar to the whole soi")
	chapter_panel()
	for i in model.s.street.bars.size():
		var bar: Dictionary = model.s.street.bars[i]
		property_card(bar,i)
	body("AVAILABLE LEASES",GOLD,12)
	for kind in StreetContent.TYPES.size():
		var info: Dictionary = StreetContent.TYPES[kind]
		row_button("Buy %s · %s" % [info.name,cash(model.street.purchase_cost(kind))],street_action.bind("buy",kind))
		body("Needs chapter 2 · %d reputation\nBare premises: ฿%d/real min plus staff; opening reserve ฿%d.\nOne bartender: break-even %.1f drinks/real min before pool." % [info.rep,StreetContent.OVERHEAD[kind],model.street.opening_reserve(kind),float(StreetContent.OVERHEAD[kind]+StreetContent.ROLE_WAGES[0])/(int(info.drink)-StreetContent.STOCK_COST)],MUTED,12)
	row_button("Host After Hours Street Festival",street_action.bind("festival"))
	body("Needs stage 3 in all three bar types. A warned district boss event completes the first story arc.")
	body("Anong · %d trust / Neighbours · %d trust\nSafety %d / Permits %d" % [model.s.partner,model.s.trust,model.s.safety,model.s.license],WHITE,14)
	row_pair("Repairs · ฿500",do_action.bind("repair"),"Paperwork · ฿330",do_action.bind("paper"))
	body("Reserve %s · Outstanding %s" % [cash(model.s.reserve),cash(model.s.debt)],GOLD,13)
	row_pair("Save ฿500",do_action.bind("reserve"),"Release ฿500",do_action.bind("draw"))
	row_button("Repay debt · up to ฿500",repay_debt)
	row_button("Share festival dates · ฿420",do_action.bind("rival"))
	# Existing mining investments remain accessible without gating the street.
	if model.s.rig > 0:
		body("LEGACY RIG · OPTIONAL",GOLD,12)
		row_button("Rig: "+["Offline","Independent","Lantern contract"][int(model.s.contract)],do_action.bind("mine_switch"))
		row_button("Service cooling · ฿680",do_action.bind("cool"))

func repay_debt() -> void:
	var amount := mini(500,mini(int(model.s.cash),int(model.s.debt)))
	if model.spend(amount): model.s.debt -= amount
	message = "Repaid " + cash(amount)
	commit(true)

func select_bar(index: int) -> void:
	if model.s.phase != "plan" or index < 0 or index >= model.s.street.bars.size(): return
	model.s.street.selected = index
	tab = 0
	commit()

func street_action(id: String,index: int = 0) -> void:
	if id == "serve":
		if serve_delay > 0: return
		serve_delay = 0.2
		if model.street.economy.pending(model.street.selected())>0: service_animation = 0.7
	message = model.street.action(id,index)
	commit(true)

func live_body(value: Callable,tint: Color = MUTED,px: int = 15) -> void:
	var label := body(value.call(),tint,px)
	live_labels.append([label,value])

func chapter_panel() -> void:
	var chapter := int(model.s.street.chapter)
	body("CHAPTER %d · %s" % [mini(5,chapter+1),StreetContent.CHAPTERS[chapter][0]],GOLD,14)
	body(StreetContent.CHAPTERS[chapter][1],MUTED,13)

func street_panel() -> void:
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	var info: Dictionary = StreetContent.TYPES[int(bar.type)]
	title(bar.name)
	body("%s · Stage %d/3\n%s" % [info.name,bar.stage,info.stages[int(bar.stage)-1][0]],TEAL,16)
	live_body(func() -> String: return "%s · %s" % [model.street.clock_text(),eco.status(bar)],TEAL,14)
	live_body(func() -> String: return eco.peak_status(bar),TEAL,12)
	if not eco.is_trading(bar):
		body("PREP FOR OPENING",GOLD,14)
		live_body(func() -> String: return "Cleanliness %d%% · %.1f%% less attraction\n%s\nStock %d/%d · %d bartenders ready" % [100-int(bar.dirt),float(bar.dirt)/StreetContent.DIRT_LIMIT*StreetContent.DIRT_ATTRACTION_PENALTY*100.0,"Cleaning: %ds remaining" % bar.clean_remaining if bar.clean_remaining>0 else "Clean" if bar.dirt==0 else "Cleaning unfinished",bar.stock,eco.stock_capacity(bar),eco.on_duty(bar,0)],WHITE,13)
		if bar.dirt>0 and bar.clean_remaining==0: row_button("Clean venue · 15 seconds",street_action.bind("clean"))
		row_button("Restock fridge · ฿14 per drink",street_action.bind("stock"))
		if model.street.can_skip():
			body("Skip leaves unfinished cleaning and stock as they are.",MUTED,12)
			for venue in model.s.street.bars:
				live_body(func() -> String: return "%s · %s · stock %d/%d" % [venue.name,"clean" if venue.dirt==0 else "needs cleaning",venue.stock,eco.stock_capacity(venue)],MUTED,12)
			row_button("Skip to 12pm",street_action.bind("skip"),true)
		body("Sales and operating charges pause while closed.",MUTED,12)
	else:
		live_body(func() -> String:
			var view: Dictionary = eco.forecast(bar)
			return "Rates per real minute\nDemand %.1f drinks · Staff service %.1f\n%d orders · %d/%d customers · Stock %d\nRecent net %s · Auto forecast %s\nCosts %s · Break-even %.1f drinks\n%s" % [view.demand,view.service,eco.pending(bar),bar.customers.size(),eco.seats(bar),bar.stock,cash(eco.actual_rate(bar)),cash(view.net),cash(view.costs),view.break_even,view.reason],GOLD,13)
		live_body(func() -> String: return "Cleanliness %d%% · %.1f%% less attraction" % [100-int(bar.dirt),float(bar.dirt)/StreetContent.DIRT_LIMIT*StreetContent.DIRT_ATTRACTION_PENALTY*100.0],MUTED,12)
		row_button("Restock fridge · ฿14 per drink",street_action.bind("stock"))
	if not bar.raided and (bar.late_open or model.s.street.minute>=StreetContent.OPEN_MINUTE or model.s.street.minute<StreetContent.CLOSE_MINUTE):
		live_body(func() -> String: return "Heat %d · Raid chance %.1f%% each 15 late minutes\nPossible fine %s · closed until noon if raided" % [model.s.heat,model.street.raid_chance(),cash(StreetContent.RAID_FINE_PER_STAGE*int(bar.stage))],PINK,12)
		row_button("Cancel late opening tonight" if bar.late_open else "Stay open until 3am tonight",street_action.bind("late"))
	row_button("Close venue" if bar.open else "Enable opening",street_action.bind("open"))
	if not bar.open:
		body(bar.close_reason,PINK,13)
		row_button("Owner-run recovery shift",street_action.bind("recovery"))
	live_body(func() -> String: return "Next business report in %ds of trading" % (model.street.SHIFT_SECONDS-int(model.s.street.seconds)),MUTED,12)
	if bar.equipment.pool>0:
		body("POOL · ฿50 PER GAME",GOLD,14)
		live_body(func() -> String:
			var timers := []
			for game in bar.games: timers.append("Table %d: %ds (%s)" % [int(game.get("table",0))+1,game.remaining,"free" if game.fee==0 else "paid"])
			return "%d/%d tables busy · %d waiting\n%s\n%d games · %s pool income · %d free games" % [bar.games.size(),bar.equipment.pool,eco.pool_queue(bar).size(),", ".join(timers),bar.pool_games,cash(bar.pool_income),bar.free_games],WHITE,13)
	body("EQUIPMENT",GOLD,14)
	for i in StreetContent.EQUIPMENT.size():
		var item: Dictionary = StreetContent.EQUIPMENT[i]
		if bar.equipment[item.id]>=item.max or (item.id=="pool" and bar.type!=0): continue
		row_button("%s · %s" % [item.name,cash(int(item.cost)*(int(bar.equipment[item.id])+1))],street_action.bind("equipment",i))
		body(item.help,MUTED,12)
	if bar.type==2:
		live_body(func() -> String: return "Performance: %s · dancers attract; bartenders serve." % ("on stage" if int(model.s.street.seconds) in range(40,80) else "next set at 40s into each shift"),TEAL,13)
	body("TEAM & PAYROLL",GOLD,14)
	if bar.crew<model.street.staff_limit(bar):
		for role in 3:
			if role>0 and role!=bar.type: continue
			row_button("Hire %s · %s" % [StreetContent.ROLE_NAMES[role].to_lower(),cash(600*(int(bar.crew)+1))],street_action.bind("hire",role))
			body("Adds ฿%d/real min. Forecast break-even after hire: %.1f drinks/real min. %s" % [StreetContent.ROLE_WAGES[role],maxf(0,(eco.operating_rate(bar)+int(StreetContent.ROLE_WAGES[role])-eco.forecast(bar).pool)/maxf(1,eco.price(bar)-StreetContent.STOCK_COST)),"Serves waiting orders." if role==0 else "Attracts visitors; does not serve drinks."],MUTED,12)
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		var name_text: String = StreetContent.ROLE_NAMES[int(person.role)]+" %d" % (i+1)
		if person.role==1: name_text = StreetContent.HOSTS[int(person.host)][0]
		character_card(Art.worker_id(bar,i),name_text,"Serves waiting orders" if person.role==0 else "Attracts visitors")
		row_button("%s · %s" % [name_text,"On duty" if person.on else "Off duty"],street_action.bind("rota",i))
		if bar.type>0: row_button("Reassign role · "+name_text,street_action.bind("role",i))
		if person.role==1:
			body(StreetContent.HOSTS[int(person.host)][1],MUTED,12)
			row_button("Bar-fine request · "+name_text,street_action.bind("bar_fine",i))
	if bar.type==1: live_body(func() -> String: return "%d actual customer requests · %d hosts away" % [bar.host_requests.size(),bar.away.size()],MUTED,12)
	if not bar.restock: row_button("Automate deliveries · ฿900",street_action.bind("restock"))
	if not bar.manager:
		row_button("Appoint manager · ฿1,800",street_action.bind("manager"))
		body("Needs stage 2, a bartender, deliveries and eight healthy shifts. Adds ฿12/real min; unlocks demand-limited offline earnings.",MUTED,12)
	else: body("Manager on duty · offline estimate uses demand, capacity and costs.",TEAL,12)
	if bar.stage<3:
		row_button("Upgrade · "+cash(model.street.upgrade_cost(bar)),street_action.bind("upgrade"),true)
		live_body(func() -> String: return eco.upgrade_reason(bar),MUTED,13)
	shift_report(bar)
	chapter_panel()
	row_button("Promotions & free pool",change_tab.bind(1))
	row_button("View street & buy bars",change_tab.bind(3))

func shift_report(bar: Dictionary) -> void:
	if bar.last_shift.is_empty(): return
	var report: Dictionary = bar.last_shift
	body("LAST SHIFT",GOLD,14)
	body("%d arrivals · %d orders · %d drinks sold\nRevenue %s · inventory %s · operating %s · promotions %s · fines %s\nNet %s\nLost: full %d · slow %d · out of stock %d\n%s" % [report.arrivals,report.orders,report.sales,cash(report.revenue),cash(report.stock_cost),cash(report.operating),cash(report.promo_cost),cash(report.get("fines",0)),cash(report.net),report.lost_full,report.lost_service,report.lost_stock,report.reason],WHITE,13)

func street_event_panel() -> void:
	var event: Dictionary = model.s.street.event
	if event.is_empty(): return
	var info: Array = StreetContent.EVENTS[int(event.id)]
	title(info[0],PINK)
	body(info[1],WHITE,14)
	body([
		"Without a generator: a 20-second closure.",
		"More shore-leave customers; stock, seats and service still limit sales.",
		"Prepare or maintain permits (75) and safety (65). Gaps can mean a fine and 40-second closure.",
		"Pumps or neighbour trust (60) prevent a 40-second closure. Helping builds trust.",
		"Beer bars benefit most. Unprotected equipment closes for 20 seconds.",
		"Door cover brings a bigger bonus and better reviews.",
		"Beer bars retain regular trade; premium venues slow down. A locals' night builds regulars.",
		"Promote your lineup to capture overflow; otherwise expect quieter trade.",
		"Preparation adds four seconds to the challenge. A loss closes venues for 30 seconds.",
		"Double street traffic during the festival. Preparation adds four seconds against Godzilla."
	][int(event.id)],MUTED,12)
	live_body(func() -> String: return "%s · %ds · %s" % ["Starts in" if event.phase == "warning" else "Time remaining",event.remaining,"Prepared" if event.prepared else "Unprepared"],GOLD,14)
	if event.phase == "warning" and not event.prepared:
		row_button("%s · %s" % [info[2],cash(info[3])],street_action.bind("prepare"))
	if event.phase == "active" and int(event.id) in [8,9]:
		row_button("Face Godzilla",func():
			message = model.start_street_boss()
			commit(),true)

func journal_panel() -> void:
	character_card("anong","Anong","The street, the stories, and the books.")
	chapter_panel()
	body("STREET STORIES",GOLD,12)
	for line in model.s.street.history: body(str(line),WHITE,13)
	if not model.s.street.offline_report.is_empty():
		var report: Dictionary = model.s.street.offline_report
		body("LAST OFFLINE ESTIMATE",GOLD,14)
		body("%d real minutes away · %.1f eligible trading minutes\n%d estimated customers · income %s · costs %s · net %s" % [int(report.seconds)/60,float(report.get("legal_seconds",report.seconds))/60.0,report.customers,cash(report.get("income",report.net)),cash(report.get("costs",0)),cash(report.net)],WHITE,13)
		for note in report.notes: body(str(note),MUTED,12)
	title("Anong's books")
	body("Week %d · Till %s · Reserve %s
Live overhead includes premises costs." % [model.week(),cash(model.s.cash),cash(model.s.reserve)])
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
	row_button("Hide" if show_details else "Story",toggle_details)
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
	body("Godzilla wants a cold one. Fill the giant glasses before time runs out. A loss closes street venues for 30 seconds; your business survives.",WHITE)
	godzilla_meter_label = body("",GOLD,14)
	godzilla_meter = ProgressBar.new()
	godzilla_meter.custom_minimum_size.y = 22
	godzilla_meter.max_value = SHOT_GOAL
	godzilla_meter.show_percentage = false
	godzilla_meter.add_theme_stylebox_override("background",box(Color("#241638"),EDGE))
	godzilla_meter.add_theme_stylebox_override("fill",box(PINK,PINK))
	column.add_child(godzilla_meter)
	godzilla_clock = body("",TEAL,19)
	body("Tap Serve a shot or press Space. Give the glass a moment to refill between shots.",MUTED,14)
	update_godzilla_panel()

func update_godzilla_panel() -> void:
	godzilla_meter.value = godzilla_shots
	city.shot_flash = shot_delay / SHOT_INTERVAL
	godzilla_meter_label.text = "INTOXICATION  ·  %d%%" % (godzilla_shots * 100 / SHOT_GOAL)
	if godzilla_shots == 0:
		godzilla_clock.text = "%d seconds from the first shot" % (int(GODZILLA_SECONDS) + (4 if model.s.street.event.get("prepared",false) else 0))
	else:
		godzilla_clock.text = "%.1fs   ·   %s" % [godzilla_time,"READY" if shot_delay <= 0 else "REFILLING"]

func serve_godzilla() -> void:
	if model.s.phase != "godzilla" or shot_delay > 0: return
	if godzilla_shots == 0: godzilla_time = GODZILLA_SECONDS + (4.0 if model.s.street.event.get("prepared",false) else 0.0)
	godzilla_shots += 1
	shot_delay = SHOT_INTERVAL
	if godzilla_shots >= SHOT_GOAL:
		resolve_godzilla(true)
	else:
		update_godzilla_panel()

func street_ui_state() -> Array:
	var bar: Dictionary = model.street.selected()
	var state := [model.s.street.chapter,model.s.street.event.get("id",-1),model.s.street.event.get("phase",""),model.s.day,model.s.phase,bar.open,bar.promo.is_empty(),model.street.economy.is_trading(bar),bar.late_open,bar.raided,bar.clean_remaining>0,bar.dirt==0,model.street.can_skip(),int(model.s.street.minute)/30,"" if model.s.street.history.is_empty() else model.s.street.history.front()]
	for venue in model.s.street.bars: state.append([venue.raided,venue.clean_remaining>0,venue.dirt==0])
	return state

func _process(delta: float) -> void:
	if updater_worker: return
	scene_clock += delta
	service_animation = maxf(0,service_animation-delta)
	serve_delay = maxf(0.0,serve_delay-delta)
	if campaign_before_tutorial == null:
		live_seconds += minf(delta,1.0)
		save_seconds += minf(delta,1.0)
		if live_seconds >= 1.0:
			live_seconds -= 1.0
			var before := street_ui_state()
			model.street.tick(1)
			var after := street_ui_state()
			refresh_street = refresh_street or before != after
			if refresh_street and model.s.phase in ["plan","guided","guided_choice","guided_report"] and not is_instance_valid(fight) and not is_instance_valid(district): render(true)
			for entry in live_labels:
				if is_instance_valid(entry[0]): entry[0].text = entry[1].call()
		if save_seconds >= 15.0:
			save_seconds = 0.0
			save_state()
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
	row_button("Hide" if show_details else "Shift log",toggle_details)
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
	if updater_worker: return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if campaign_before_tutorial == null: save_state()
	if what == NOTIFICATION_APPLICATION_RESUMED and campaign_before_tutorial == null:
		offline_notice = model.street.claim_offline(int(Time.get_unix_time_from_system()))
		save_state()
		refresh_street = true
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(district): close_district()
		elif is_instance_valid(fight): leave_fight(fight.result if fight.over else false)
		elif campaign_before_tutorial != null: finish_tutorial()
		elif offline_notice > 0 and model.s.phase == "plan": dismiss_offline()
		elif drawer_open and model.s.phase == "plan": close_drawer()

func _unhandled_key_input(event: InputEvent) -> void:
	if model.s.phase == "godzilla" and event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		serve_godzilla()
	elif campaign_before_tutorial != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_tutorial()

	elif event.is_action_pressed("ui_cancel") and offline_notice > 0 and model.s.phase == "plan":
		get_viewport().set_input_as_handled()
		dismiss_offline()
	elif event.is_action_pressed("ui_cancel") and drawer_open and model.s.phase == "plan":
		get_viewport().set_input_as_handled()
		close_drawer()

func _exit_tree() -> void:
	# Release active playback before the audio server shuts down.
	for player in [music, sfx]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func dismiss_offline() -> void:
	offline_notice = 0
	render()

func property_card(bar: Dictionary, index: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	column.add_child(row)
	var exterior := TextureRect.new()
	exterior.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exterior.texture = Art.frontage(int(bar.type),int(bar.stage))
	exterior.custom_minimum_size = Vector2(100,80)
	exterior.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(exterior)
	var select := button("%s\n%s · %d/3" % [bar.name,StreetContent.TYPES[int(bar.type)].name,bar.stage],select_bar.bind(index),index == model.s.street.selected)
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(select)
