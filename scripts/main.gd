extends Control

const Campaign = preload("res://scripts/campaign.gd")
const Content = preload("res://scripts/content.gd")
const StreetContent = preload("res://scripts/street_content.gd")
const Local = preload("res://scripts/local_events.gd")
const BedRaceCourse = preload("res://scripts/bed_race_course.gd")
const City = preload("res://scripts/city.gd")
const District = preload("res://scripts/district.gd")
const Art = preload("res://scripts/art.gd")
const Fight = preload("res://scripts/fight.gd")
const UpgradeIcons = preload("res://scripts/upgrade_icons.gd")
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
const EQUIPMENT_CAPTIONS = {
	"sign":"More walk-ins", "comfort":"More patient guests", "fridge":"+40 drinks of space",
	"pool":"฿50 per game", "screen":"Unlock Sports Night", "menu":"Unlock Mango cocktails",
	"music":"Repeat orders 10s sooner", "seating":"More seats",
}
const TAB_NAMES = ["Service","Events","Tours","Empire","Journal"]
const STAT_TIPS = {
	"TILL":"Shared cash for stock, wages, upgrades and leases. The small rate shows net trading per second over the last five seconds.",
	"STOCK":"Drinks in this venue's fridge. Each sale uses one. Tap to open the fridge.",
	"REPUTATION":"Happy customers build your reputation. It attracts visitors and unlocks new venue types.",
	"HEAT":"Trading after 1am raises Heat and increases the chance of a raid and fine. Closing on time lets it cool.",
	"TIME":"The day changes at midnight. Bars open at noon and normally close at 1am.",
}
const TUTORIAL_ACTIONS = ["stock","serve","welcome","chat","hire"]
const SHOT_GOAL = 10
const SHOT_INTERVAL = 0.60
const GODZILLA_SECONDS = 10.0

var model = Campaign.new()
var boot_menu := true
var resume_available := false
var new_game_confirmation := false
var campaign_before_tutorial: Campaign
var campaign_before_tuning: Campaign
var tuning_open := false
var tuning_speed := 1
var tutorial_step := 0
var stat_tip: Control
var stat_tip_key := ""
var show_tutorial_hint := false
var offline_notice := 0
var drawer_open := false
var drink_list_open := false
var nida_forecast_open := false
var drawer: Control
var event_banner: Button
var news_issue := {}
var seen_news := {}
var event_overlay: Control
var event_game := -1
const CART_CELL = 66
var cart_board := []
var cart_selected := 0
var cart_moves := 0
var cart_slide_offset := Vector2.ZERO
var cart_tiles: Array[Panel] = []
var cart_held := -1
var cart_pointer := -2
var cart_touch_start := Vector2.ZERO
var cart_tile_start := Vector2.ZERO
var cart_axis := Vector2.ZERO
var cart_limits := Vector2.ZERO
var cart_offset := 0.0
var race_left := 0.0
var race_finish_left := -1.0
var race_taps := 0
var race_meter: ProgressBar
var race_clock: Label
var race_course: Control
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
var order_sound: AudioStreamPlayer
var order_alert = preload("res://scripts/order_alert.gd").new()
var sfx: AudioStreamPlayer
var sfx_streams := {}
var muted := false
var training := false
var visit_plans_open := false
var arcade_circuit := false

var live_labels: Array = []
var action_controls: Array = []
var upgrades_open := false
var fridge_open := false
var upgrades_ready_only := true
var upgrade_badge: Button
var upgrades_entry: Button
var upgrade_ready: Array[String] = []
var stock_controls: Array = []
var live_seconds := 0.0
var save_seconds := 0.0
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
	$BuildVersion.text = str(ProjectSettings.get_setting("application/config/version"))
	resume_available = model.load_game()
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
	order_sound = AudioStreamPlayer.new()
	order_sound.stream = preload("res://assets/order_waiting.wav")
	order_sound.volume_db = -9
	add_child(order_sound)
	for kind in ["click","impact","block","gong"]:
		sfx_streams[kind] = load("res://assets/%s.wav" % kind)
	if not muted and DisplayServer.get_name() != "headless": music.play()
	render()
	if windows_updates != null:
		windows_updates.confirm_restart()
		if DisplayServer.get_name() != "headless": windows_updates.check()

func render_boot_menu() -> void:
	var background := TextureRect.new()
	background.texture = Art.venue(0,1)
	background.size = Vector2(960,540)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(background)
	pane(root_ui,Rect2(0,0,960,540),Color("#170f18b8"),Color.TRANSPARENT)
	var menu := pane(root_ui,Rect2(220,64,520,412),DARK,GOLD)
	abs_text(menu,Rect2(28,20,464,24),"THE BLUE HOUR IS WAITING",14,TEAL)
	abs_text(menu,Rect2(28,51,464,42),"PATTAYA AFTER HOURS",29,GOLD)
	if new_game_confirmation:
		abs_text(menu,Rect2(28,110,464,30),"Replace your saved campaign?",22,PINK)
		abs_text(menu,Rect2(28,151,464,65),"All progress in your current game will be erased.\nYou will start again at the Blue Hour.\nThis cannot be undone.",16,WHITE)
		at_button(menu,Rect2(28,242,464,48),"Erase progress & start new game",start_new_game)
		at_button(menu,Rect2(28,304,464,48),"Cancel",cancel_new_game,true).grab_focus()
	else:
		var summary := "No saved campaign yet. Start your first bar."
		if resume_available:
			summary = "Day %d · %s in the till · %d venue%s" % [model.s.day,cash(model.s.cash),model.s.street.bars.size(),"" if model.s.street.bars.size()==1 else "s"]
		abs_text(menu,Rect2(28,111,464,28),summary,16,WHITE)
		abs_text(menu,Rect2(28,148,464,48),"One street. One saved campaign.\nNew Game replaces your existing progress.",15,MUTED)
		var resume := at_button(menu,Rect2(28,224,464,48),"Resume",resume_game,true)
		resume.disabled = not resume_available
		var fresh := at_button(menu,Rect2(28,286,464,48),"New Game",request_new_game)
		if resume_available: resume.grab_focus()
		else: fresh.grab_focus()
	var notice := abs_text(menu,Rect2(28,359,464,36),message,14,PINK)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	at_button(root_ui,Rect2(848,14,98,40),"Muted" if muted else "Sound",set_sound)
	if windows_updates != null:
		update_button = at_button(root_ui,Rect2(14,14,98,40),"Update",windows_updates.ask)
		update_button.visible = not windows_updates.tag.is_empty()

func resume_game() -> void:
	if not boot_menu or not resume_available: return
	# Re-read on selection; time on the menu still counts as time away.
	if not model.load_game():
		resume_available = false
		message = "No readable save found. Start a new game."
		render()
		return
	boot_menu = false
	new_game_confirmation = false
	message = ""
	offline_notice = model.street.claim_offline(int(Time.get_unix_time_from_system()))
	save_state()
	render()
	if model.s.phase == "fight": enter_fight(false)

func request_new_game() -> void:
	if not boot_menu: return
	if FileAccess.file_exists(Campaign.SAVE) or FileAccess.file_exists(Campaign.BACKUP):
		new_game_confirmation = true
		message = ""
		render()
	else:
		start_new_game()

func cancel_new_game() -> void:
	new_game_confirmation = false
	message = ""
	render()

func start_new_game() -> void:
	if updater_worker or campaign_before_tutorial != null or campaign_before_tuning != null: return
	var fresh := Campaign.new()
	var error := fresh.save_game(true)
	if error != OK:
		message = "Could not start a new game: save failed (%d)." % error
		render(true)
		return
	model = fresh
	boot_menu = false
	new_game_confirmation = false
	confirmation = false
	offline_notice = 0
	live_seconds = 0.0
	save_seconds = 0.0
	guide = 2
	tab = 0
	drawer_open = false
	show_tutorial_hint = true
	message = ""
	render()

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
	if muted:
		music.stop()
		order_sound.stop()
	elif DisplayServer.get_name() != "headless": music.play()
	var config := ConfigFile.new()
	config.set_value("audio","muted",muted)
	config.save("user://settings.cfg")
	render(true)

func save_state() -> void:
	if boot_menu or campaign_before_tutorial != null or campaign_before_tuning != null: return
	show_tutorial_hint = false
	var error: int = model.save_game()
	if error != OK: message = "Save failed (%d)." % error


func change_tab(index: int) -> void:
	tuning_open = false
	upgrades_open = false
	fridge_open = false
	confirmation = false
	tab = index
	drawer_open = true
	message = ""
	render()

func render(keep_scroll: bool = false) -> void:
	live_labels.clear()
	stat_tip = null
	stat_tip_key = ""
	action_controls.clear()
	upgrade_badge = null
	upgrades_entry = null
	stock_controls.clear()
	refresh_street = false
	var previous := scroll.scroll_vertical if keep_scroll and is_instance_valid(scroll) else 0
	if is_instance_valid(root_ui):
		remove_child(root_ui)
		root_ui.queue_free()
	root_ui = Control.new()
	root_ui.size = Vector2(960,540)
	add_child(root_ui)
	if boot_menu:
		render_boot_menu()
		return
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
	city.bars = model.s.street.bars
	city.street_state = model.s.street
	city.selected_bar = int(model.s.street.selected)
	city.street_event = model.s.street.event
	city.celebrating = model.street.economy.celebrating(model.street.selected())
	root_ui.add_child(city)
	# Full-width scene, with all live text rendered at the UI resolution.
	pane(root_ui,Rect2(0,0,960,48),Color("#21161ff5"))
	var venue_name := abs_text(root_ui,Rect2(14,4,170 if windows_updates != null else 245,24),model.street.selected().name,19,GOLD)
	venue_name.name = "VenueName"
	venue_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var subtitle: String = "PRACTICE SHIFT" if practicing else model.weekday()
	if campaign_before_tuning != null: subtitle = "PLAYTEST · %d×" % tuning_speed
	abs_text(root_ui,Rect2(14,27,170,16),subtitle,12,TEAL)
	if windows_updates != null:
		update_button = at_button(root_ui,Rect2(190,5,66,37),"Update",windows_updates.ask,true)
		update_button.add_theme_font_size_override("font_size",12)
		update_button.visible = not windows_updates.tag.is_empty()
		update_button.disabled = model.s.phase == "godzilla"
	metric(268,104,"TILL",cash(model.s.cash),TEAL)
	metric(377,80,"STOCK",str(model.street.selected().stock),GOLD)
	metric(462,104,"REPUTATION",str(int(model.s.rep)),TEAL)
	metric(570,70,"HEAT",str(int(model.s.heat)),PINK)
	metric(644,99,"TIME",model.street.clock_text(),WHITE)
	var tutorial_button := at_button(root_ui,Rect2(748,5,92,37),"Exit" if practicing else "Tutorial",finish_tutorial if practicing else start_tutorial)
	tutorial_button.disabled = model.s.phase == "godzilla" or campaign_before_tuning != null
	at_button(root_ui,Rect2(848,5,98,37),"Muted" if muted else "Sound",set_sound)
	event_banner = null
	if not practicing and (not model.s.street.event.is_empty() or model.street.celebration_info().days_left<=2 or model.street.celebration_info().active):
		event_banner = at_button(root_ui,Rect2(14,56,540,36),"",change_tab.bind(1))
		event_banner.add_theme_color_override("font_color",PINK)
		var banner_text := func() -> String:
			var e: Dictionary = model.s.street.event
			if e.is_empty():
				var party: Dictionary = model.street.celebration_info()
				return "%s · %s · FREE  ›" % ["TONIGHT" if party.active else "DAY %d" % party.day,party.name]
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
				thumb.texture = Art.venue(int(b.type),int(b.stage),City.fan_owned(b),City.screen_owned(b))
				thumb.position = Vector2(3,3)
				thumb.size = Vector2(56,32)
				thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(thumb)
				abs_text(card,Rect2(2,34,58,18),"%d · %s %d" % [i+1,["BEER","HOST","GOGO"][int(b.type)],b.stage],10,Color("#241820") if i == model.s.street.selected else GOLD)
			else:
				card.text = "+\nLEASE"
				card.add_theme_font_size_override("font_size",11)
	var first_shift := show_tutorial_hint and not practicing
	var log_text := "Serve → upgrade → hire → grow" if first_shift else str(model.s.log.front())
	var note_y := 148 if event_banner != null else 56
	pane(root_ui,Rect2(14,note_y,540,27),Color("#21161fdd"))
	var note := abs_text(root_ui,Rect2(20,note_y+3,530,22),message if not message.is_empty() else log_text,13,GOLD)
	note.clip_text = true
	pane(root_ui,Rect2(0,482,960,58),Color("#21161ff8"))
	for index in TAB_NAMES.size():
		var b := at_button(root_ui,Rect2(14+index*62,490,56,40),TAB_NAMES[index],toggle_drawer.bind(index),drawer_open and tab == index)
		b.add_theme_font_size_override("font_size",12)
		b.disabled = model.s.phase != "plan" or practicing
	if not practicing and model.s.phase=="plan":
		upgrade_badge = at_button(root_ui,Rect2(56,478,21,21),"",open_upgrades.bind(true),true)
		upgrade_badge.name = "UpgradeBadge"
		upgrade_badge.custom_minimum_size = Vector2.ZERO
		upgrade_badge.size = Vector2(21,21)
		upgrade_badge.z_index = 2
		upgrade_badge.add_theme_font_size_override("font_size",11)
		var badge_style := box(GOLD,DARK,2)
		badge_style.set_corner_radius_all(10)
		for state in ["normal","hover","pressed"]: upgrade_badge.add_theme_stylebox_override(state,badge_style)
		sync_upgrade_badge()
	var walk := at_button(root_ui,Rect2(328,490,76,40),"Walk\ndistrict",walk_district)
	walk.add_theme_font_size_override("font_size",12)
	walk.disabled = practicing or model.s.phase != "plan"
	if not practicing:
		var staff_hud := at_button(root_ui,Rect2(666,408,278,68),"",change_tab.bind(0))
		staff_hud.name = "StaffIndicator"
		staff_hud.add_theme_font_size_override("font_size",13)
		staff_hud.add_theme_color_override("font_color",TEAL)
		staff_hud.tooltip_text = "Actual staff sales since hiring or this update. Bartenders serve whenever ready; owner auto-serve is a separate purchase. Tap for Service."
		var staff_text := func() -> String: return model.street.economy.staff_indicator(model.street.selected())
		staff_hud.text = staff_text.call()
		live_labels.append([staff_hud,staff_text])
	if not practicing and int(model.s.street.night_prep.remaining)>0:
		var stay := at_button(root_ui,Rect2(14,330,430,68),"",street_action.bind("stay"),true)
		stay.name = "NightPrepCancel"
		stay.add_theme_font_size_override("font_size",15)
		stay.text = model.street.night_prep_text()
		live_labels.append([stay,func() -> String: return model.street.night_prep_text()])
	drawer = Control.new()
	drawer.position = Vector2(570,54)
	drawer.size = Vector2(380,422)
	root_ui.add_child(drawer)
	pane(drawer,Rect2(0,0,380,422),Color("#241820f7"))
	var show_fridge: bool = fridge_open and not practicing and model.s.phase in ["plan","guided"]
	abs_text(drawer,Rect2(16,5,290,30),"FRIDGE" if show_fridge else "SHIFT DESK" if practicing or model.s.phase != "plan" else "UPGRADES" if upgrades_open and tab==0 else TAB_NAMES[tab].to_upper(),16,GOLD)
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
	match "tutorial" if practicing else model.s.phase:
		"tutorial":
			tutorial_panel()
		"plan":
			match tab:
				0:
					if show_fridge: fridge_panel()
					elif upgrades_open: upgrades_panel()
					else: service_panel()
				1: events_panel()
				2: tours_panel()
				3: empire_panel()
				4:
					if tuning_open: tuning_panel()
					else: journal_panel()
			action_label = "Serve a drink"
			action = street_action.bind("serve")
		"guided":
			if show_fridge: fridge_panel()
			else:
				title("Guided shift · live service")
				live_body(func() -> String: return "Wave %d/3 · %ds into this shift" % [int(model.s.street.guided.wave)+1,model.s.street.seconds],GOLD)
				street_panel()
			action_label = "Serve a drink"
			action = street_action.bind("serve")
		"guided_choice":
			title(["Open the doors","The rush","Last call"][int(model.s.street.guided.wave)])
			body("Anong: Read the room. Customers and stock are real; choosing a response does not skip the clock.")
			for choice in 2:
				var state: Dictionary = model.street.economy.action_status(model.street.selected(),"serve" if choice==0 else "welcome")
				var control := row_button("Serve a waiting order" if choice==0 else "Welcome passersby",choose.bind(choice))
				control.disabled = not state.enabled
				if not state.enabled: body(state.reason,MUTED,12)
			action_label = "Continue normal service"
			action = choose.bind(2)
		"guided_report":
			title("Guided shift complete")
			shift_report(model.street.selected())
			body("The same live ledger has already recorded these results. Returning to the street adds no extra money or time.")
			action_label = "Back to the street"
			action = advance
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
	if not live_service and not practicing:
		at_button(root_ui,Rect2(594,490,352,40),action_label,action,true)
	if live_service or practicing:
		cooldown_button(Rect2(414,490,170,40),"Serve a drink","serve")
		cooldown_button(Rect2(594,490,172,40),"Welcome customers","welcome")
		cooldown_button(Rect2(776,490,170,40),"Have a chat","chat")
		update_action_controls()
	if live_service:
		var demand_note := abs_text(root_ui,Rect2(14,100,540,42),"",14,GOLD)
		live_labels.append([demand_note,func() -> String:
			var bar: Dictionary = model.street.selected()
			var warning := ""
			if model.s.street.minute>=30 and model.s.street.minute<60: warning = "1am closing soon · "
			elif model.s.street.minute>=60 and model.s.street.minute<180 and model.street.economy.is_trading(bar): warning = "LATE TRADE · Heat %d · " % model.s.heat
			return "%d/%d customers · %d orders waiting\n%s%s" % [bar.customers.size(),model.street.economy.seats(bar),model.street.economy.pending(bar),warning,model.street.economy.forecast(bar).reason]])
		demand_note.text = live_labels.back()[1].call()
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
	draw_event_overlay()

func toggle_drawer(index: int) -> void:
	if drawer_open and tab == index:
		close_drawer()
	else:
		change_tab(index)

func close_drawer() -> void:
	upgrades_open = false
	fridge_open = false
	drawer_open = false
	render()

func metric(x: int,width: int,name_text: String,value: String,tint: Color) -> void:
	var stock_shortcut: bool = name_text=="STOCK" and campaign_before_tutorial==null and model.s.phase in ["plan","guided"]
	var callback := open_fridge if stock_shortcut else toggle_stat_tip.bind(name_text,x)
	var target := at_button(root_ui,Rect2(x-4,2,width,44),name_text,callback)
	target.tooltip_text = STAT_TIPS[name_text]
	var empty := StyleBoxEmpty.new()
	for state in ["normal","hover","pressed"]: target.add_theme_stylebox_override(state,empty)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		target.add_theme_color_override(state,Color.TRANSPARENT)
	var heading := abs_text(root_ui,Rect2(x,3,width,15),"DAY %d" % model.s.day if name_text=="TIME" else name_text,12 if name_text=="TIME" else 11,GOLD if name_text=="TIME" else MUTED)
	if name_text=="TIME":
		heading.clip_text = true
		live_labels.append([heading,func() -> String: return "DAY %d" % model.s.day])
	var label := abs_text(root_ui,Rect2(x,13 if name_text=="TILL" and campaign_before_tutorial==null else 20,105,24),value,16 if name_text=="TILL" else 18,tint)
	if name_text=="TILL" and campaign_before_tutorial==null:
		var rate := abs_text(root_ui,Rect2(x,33,105,14),"",10,TEAL)
		live_labels.append([rate,func() -> String: return "%s฿%.2f/s" % ["+" if model.s.street.net_per_second>=0 else "−",absf(model.s.street.net_per_second)]])
		rate.text = live_labels.back()[1].call()
	if campaign_before_tutorial == null:
		live_labels.append([label,func() -> String:
			match name_text:
				"TILL": return cash(model.s.cash) if model.s.cash < 100000 else "฿%.1fk" % (model.s.cash/1000.0)
				"STOCK": return str(model.street.selected().stock)
				"REPUTATION": return str(model.s.rep)
				"SHIFT": return "D%03d" % model.s.day
				"TIME": return model.street.clock_text()
			return str(model.s.heat)])

func toggle_stat_tip(key: String,x: int) -> void:
	var was_open := stat_tip_key == key
	close_stat_tip()
	if was_open: return
	stat_tip_key = key
	stat_tip = pane(root_ui,Rect2(clampi(x-4,14,626),50,320,88),DARK,GOLD)
	stat_tip.z_index = 2
	stat_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abs_text(stat_tip,Rect2(12,5,296,19),"DAY & TIME" if key=="TIME" else key,12,GOLD)
	var text_label := abs_text(stat_tip,Rect2(12,25,296,56),STAT_TIPS[key],13)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func close_stat_tip() -> void:
	if is_instance_valid(stat_tip):
		stat_tip.hide()
		stat_tip.queue_free()
	stat_tip = null
	stat_tip_key = ""

func _input(event: InputEvent) -> void:
	if event_game==Local.CART and cart_pointer_input(event):
		get_viewport().set_input_as_handled()
		return
	if (event_game>=0 or not news_issue.is_empty()) and event is InputEventKey:
		var playing := event_game>=0
		if event.is_action_pressed("ui_cancel"):
			if event_game>=0: end_event_game(false)
			else: close_news(false)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event_game==Local.BED and event.physical_keycode==KEY_SPACE: tap_race()
			elif event_game==Local.CART and cart_held<0:
				var horizontal: bool = cart_board[cart_selected][3]
				if (horizontal and event.physical_keycode==KEY_LEFT) or (not horizontal and event.physical_keycode==KEY_UP): slide_cart(-1)
				if (horizontal and event.physical_keycode==KEY_RIGHT) or (not horizontal and event.physical_keycode==KEY_DOWN): slide_cart(1)
		if playing or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	if not is_instance_valid(stat_tip): return
	if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT or event is InputEventScreenTouch) and event.pressed:
		if not Rect2(264,0,479,48).has_point(event.position): close_stat_tip()

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

func row_button(value: String, call: Callable, primary: bool = false) -> Button:
	var control := button(value,call,primary)
	column.add_child(control)
	return control

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
	if campaign_before_tutorial != null or campaign_before_tuning != null: return
	campaign_before_tutorial = model
	tutorial_step = 0
	show_tutorial_hint = false
	confirmation = false
	message = ""
	model = Campaign.new(72)
	model.street.checkpoint_requested.disconnect(model.save_checkpoint)
	model.s.cash = 2000
	model.s.street.minute = StreetContent.DAY_MINUTES+StreetContent.CLOSE_MINUTE-75
	render()

func finish_tutorial() -> void:
	if campaign_before_tutorial == null: return
	model = campaign_before_tutorial
	campaign_before_tutorial = null
	message = ""
	render()

func tutorial_panel() -> void:
	var bar: Dictionary = model.street.selected()
	var headings := ["Stock the fridge","Serve an order","Welcome passersby","Help a waiting guest","Hire a bartender","Close at 1am","Check the books"]
	title("%d / %d  ·  %s" % [tutorial_step+1,headings.size(),headings[tutorial_step]])
	match tutorial_step:
		0:
			body("Buy a pack. In a live shift, tap Stock or Restock fridge to open this menu.")
			stock_controls.append(row_button("Buy drinks",street_action.bind("stock"),true))
		1:
			body("A gold dot marks an order. Tap Serve a drink to fill it and start the refill timer.")
		2:
			body("Serve is refilling. Try Welcome customers to draw more of the passing crowd while you wait.")
		3:
			body("A red dot means an order is about to be lost. Chat gives that guest 10 more seconds and shares Welcome’s timer.")
		4:
			body("Bartenders serve on their own when ready. Contracts last 10 game days, and training stays with the worker.")
			row_button("Hire bartender · "+cash(StreetContent.BARTENDER_CONTRACT_COST),street_action.bind("hire"),true)
		5:
			body("Staff served %d drinks in practice. Close on time to let Heat cool. Staying open after 1am risks a raid and fine." % (int(model.s.street.served)-1))
			row_button("Advance to 1am",tutorial_close,true)
		6:
			body("%d drinks sold · %s in tips" % [bar.last_shift.get("sales",0),cash(bar.last_tips.get("amount",0))],TEAL,16)
			body("Serve the specialty drink a guest asks for on their first round for a chance at a ฿5 tip. Tips pay out at closing.")
			body("At closing, wait for noon or tap Stay here. Follow Anong’s next step in Service to grow the bar.",MUTED,13)
			row_button("Finish tutorial",finish_tutorial,true)

func tutorial_close() -> void:
	model.street.tick(StreetContent.CLOSE_MINUTE-int(model.s.street.minute))
	tutorial_step += 1
	message = "Tips counted. Cleaning has started."
	render()

func service_panel() -> void:
	street_panel()
	title("Guided service")
	body("Optional three-wave guidance uses the same customers, stock and two-minute clock. Choices cannot skip time or generate extra sales.")
	row_button("Open managed shift",begin)

func events_panel() -> void:
	street_event_panel()
	celebration_panel()
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
	live_body(func() -> String: return "Pool revenue %s · %d free games\nFees forgone %s\nAttributed customers %d · regulars %d · lost to queues %d\nAttributed drinks %s · stock %s · commission %s\nShift operating costs %s · promotion fee %s\nAttributed contribution after these costs %s\nBaseline visitors without promotion: %.1f (estimate)" % [cash(report.pool_revenue),report.free_games,cash(int(report.free_games)*50),report.customers,report.regulars,report.lost,cash(report.drink_revenue),cash(report.drink_cost),cash(report.get("commission",0)),cash(report.operating),cash(report.fee),cash(int(report.drink_revenue)+int(report.pool_revenue)-int(report.drink_cost)-int(report.operating)-int(report.fee)-int(report.get("commission",0))),float(report.baseline)],WHITE,13)

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
		var quote: Dictionary = model.street.lease_quote(kind)
		var buy := row_button("Lease %s · %s" % [info.name,cash(quote.price)],street_action.bind("buy",kind))
		buy.name = "Lease_"+str(kind)
		buy.disabled = not quote.enabled
		body("Base %s + %s repeat premium (%d earlier purchases). Blue Hour excluded." % [cash(quote.base),cash(quote.surcharge),quote.repeats],MUTED,12)
		if quote.discount>0: body("Retiring-owner offer · today only: %d%% off (save %s)" % [StreetContent.LEASE_SALE_PERCENT,cash(quote.discount)],TEAL,12)
		body("Pay now: %s\nKeep in till: %s for hiring, next stock pack and opening payroll\nCash needed to open: %s" % [cash(quote.price),cash(quote.reserve),cash(quote.required)],WHITE,13)
		body("Bare premises %s/min · with one bartender %s/min\nEstimated break-even %.1f house drinks/min before pool or manager income. Running costs exclude stock; break-even includes it. Shared traffic does not guarantee buyers.\nNeeds chapter 2 · %d reputation" % [cash(quote.overhead),cash(quote.running),quote.break_even,info.rep],MUTED,12)
		if not quote.enabled: body(quote.reason,PINK,12)

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
	if campaign_before_tutorial != null:
		if tutorial_step>=TUTORIAL_ACTIONS.size() or id!=TUTORIAL_ACTIONS[tutorial_step]: return
		var bar: Dictionary = model.street.selected()
		var before := [bar.stock,bar.team.size(),bar.welcome_ready,model.s.street.served]
		message = model.street.action(id,index)
		if before!=[bar.stock,bar.team.size(),bar.welcome_ready,model.s.street.served]:
			tutorial_step += 1
			if id=="welcome": model.street.tick(35) # Let the opening orders become urgent.
			if id=="hire": model.street.tick(StreetContent.STAFF_SERVICE_SECONDS[0])
		render()
		return
	if id=="serve" and model.street.economy.action_status(model.street.selected(),id).needs_stock:
		open_fridge()
		return
	var sold_before := int(model.s.street.served)
	message = model.street.action(id,index)
	if id=="serve" and model.s.street.served>sold_before: service_animation = 0.7
	commit(true)

func cooldown_button(rect: Rect2, label: String, id: String) -> void:
	var button := at_button(root_ui,rect,"",street_action.bind(id),id=="serve")
	button.add_theme_font_size_override("font_size",13)
	button.add_theme_stylebox_override("disabled",box(DARK,EDGE.darkened(.5)))
	var fill := ColorRect.new()
	fill.color = Color(0.44,0.98,0.82,0.24)
	fill.position = Vector2(2,2)
	fill.size = Vector2(rect.size.x-4,rect.size.y-4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(fill)
	var caption := Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",13)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(caption)
	action_controls.append([button,fill,caption,label,id])

func update_action_controls() -> void:
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	for entry in action_controls:
		if not is_instance_valid(entry[0]): continue
		var state: Dictionary = eco.action_status(bar,entry[4])
		var practice_action: bool = campaign_before_tutorial == null or (tutorial_step<TUTORIAL_ACTIONS.size() and entry[4]==TUTORIAL_ACTIONS[tutorial_step])
		var stock_shortcut: bool = state.needs_stock and campaign_before_tutorial==null
		var needed := "Need "+str(StreetContent.DRINKS[state.short_drink].name) if stock_shortcut else ""
		var caption: String = entry[3]
		if stock_shortcut: caption = "Restock fridge" if bar.stock==0 else needed
		elif entry[4]=="serve" and eco.automatic_service(bar): caption = "Auto-serve"
		entry[0].disabled = not (state.enabled or stock_shortcut) or not practice_action
		entry[0].tooltip_text = state.reason+" Open the stock menu." if stock_shortcut else "Follow the current lesson." if not practice_action else "Ready" if state.enabled else state.reason
		# Keep native button text for keyboard/accessibility; a child draws the caption over the fill.
		entry[0].text = caption if stock_shortcut else entry[3]
		for color_name in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
			entry[0].add_theme_color_override(color_name,Color.TRANSPARENT)
		entry[1].size.x = 0 if state.no_orders or stock_shortcut else (entry[0].size.x-4)*state.fill
		var refilling: bool = state.remaining>0.000001 and not state.no_orders and not stock_shortcut
		entry[1].color.a = 0.24 if refilling or not entry[0].disabled else 0.07
		var detail := "Ready" if state.enabled else "Unavailable"
		if not eco.is_trading(bar): detail = "Venue closed"
		elif state.no_orders: detail = "Waiting for orders"
		elif stock_shortcut: detail = needed if bar.stock==0 else "Open stock menu"
		elif refilling: detail = "Refilling · %ds" % ceili(state.remaining)
		elif not state.enabled and entry[4]=="serve": detail = "Restock fridge"
		elif not state.enabled and entry[4]=="chat": detail = "No guest needs chat"
		elif not state.enabled and entry[4]=="welcome" and eco.promoter_bonus(bar)>0: detail = "Nida is welcoming"
		elif not practice_action: detail = "Practice step"
		entry[2].text = caption+"\n"+detail
		entry[2].modulate = DARK if not entry[0].disabled and entry[4]=="serve" else WHITE if not entry[0].disabled or refilling else MUTED
	for button in stock_controls:
		if not is_instance_valid(button): continue
		var offer: Dictionary = eco.stock_offer(bar)
		button.disabled = not offer.enabled
		button.tooltip_text = "%d drinks; cash after purchase %s" % [offer.quantity,cash(offer.remaining_cash)] if offer.enabled else offer.reason
		button.text = "Buy %d %s · %s" % [offer.quantity,"House lager" if fridge_open else "drinks",cash(offer.price)]+("\n"+offer.reason if not offer.enabled else "")

func stock_button(in_fridge: bool = false) -> void:
	live_body(func() -> String:
		var bar: Dictionary = model.street.selected()
		var eco = model.street.economy
		return "Standard drink %s · next delivery %s per drink" % [cash(eco.price(bar)),cash(eco.stock_unit_cost(bar))],TEAL,12)
	stock_controls.append(row_button("Buy drinks",street_action.bind("stock")))
	var recovery := row_button("Bo's recovery delivery · 6 drinks",street_action.bind("emergency_stock"))
	recovery.name = "EmergencyStock"
	var bar: Dictionary = model.street.selected()
	var recovery_note := body("",GOLD,12)
	var note := func() -> String:
		recovery.visible = model.street.economy.emergency_stock_available(bar)
		recovery_note.visible = recovery.visible
		return "No upfront cash. ฿14 per drink is paid when sold. Staff go off duty; Anong covers 2 minutes of overhead. Existing orders stay." if recovery.visible else ""
	recovery_note.text = note.call()
	live_labels.append([recovery_note,note])
	if in_fridge: return
	live_body(func() -> String: return "%d/%d stocked · cash after pack %s · next operating charge ≤%s" % [bar.stock,model.street.capacity(bar),cash(int(model.s.cash)-model.street.economy.pack_price(bar)),cash(ceili(model.street.economy.operating_rate(bar)/60.0))],MUTED,12)

func open_fridge() -> void:
	tab = 0
	drawer_open = true
	upgrades_open = false
	fridge_open = true
	message = ""
	render()

func fridge_panel() -> void:
	row_button("‹  Service",change_tab.bind(0))
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	var shortage: int = eco.blocking_drink(bar)
	var wrong_stock: bool = shortage>=0 and bar.stock>0
	if wrong_stock:
		live_body(func() -> String:
			var offer: Dictionary = eco.stock_offer(bar,false,shortage)
			var line := "Orders need %s." % StreetContent.DRINKS[shortage].name
			if offer.room<offer.quantity:
				return line+" Return spare stock to free %d slots." % (offer.quantity-offer.room)
			if not offer.enabled: return line+" "+offer.reason
			return line,GOLD,13)
		drink_panel(bar,true,shortage)
		stock_button(true)
	else:
		stock_button(true)
		drink_panel(bar,true)
	live_body(func() -> String: return model.street.economy.tips_text(bar),TEAL,12)

func drink_panel(bar: Dictionary, in_fridge: bool = false, shortage: int = -1) -> void:
	var eco = model.street.economy
	if not in_fridge:
		row_pair("Mixed delivery",street_action.bind("mixed_drinks"),"Hide drink list" if drink_list_open else "Drinks & margins",func() -> void:
			drink_list_open = not drink_list_open
			render(true))
		if not drink_list_open: return
	var drinks := range(eco.drink_count(bar))
	if in_fridge:
		drinks.sort_custom(func(a: int,b: int) -> bool: return eco.stock_waiting(bar,a)>eco.stock_waiting(bar,b))
		if shortage>=0:
			drinks.erase(shortage)
			drinks.push_front(shortage)
	for drink in drinks:
		var item: Dictionary = StreetContent.DRINKS[drink]
		live_body(func() -> String:
			var recent := int(bar.shift.drink_requests.get(item.id,0))+int(bar.last_shift.get("drink_requests",{}).get(item.id,0))
			var missed := int(bar.shift.drink_misses.get(item.id,0))+int(bar.last_shift.get("drink_misses",{}).get(item.id,0))
			var share: float = eco.drink_popularity(bar)[drink]
			var hint: String = eco.drink_demand_hint(bar,drink,share)
			var waiting: int = eco.stock_waiting(bar,drink) if in_fridge else 0
			var line := "%s · %s · %d stocked\n%d%% popular · +฿%d/sale" % [item.name,item.tier,eco.stock_of(bar,drink),roundi(100.0*share),eco.price(bar,drink)-eco.drink_cost(bar,drink)]
			if waiting>0:
				return line+" · %d waiting" % waiting+("\n"+hint if not hint.is_empty() else "")
			var history := "%d asked · %d short" % [recent,missed]
			return line+"\n"+(hint+" · " if not hint.is_empty() else "")+history,TEAL,13)
		row_pair("Buy %d · ฿%d ea" % [eco.pack_quantity(bar),eco.drink_cost(bar,drink)],street_action.bind("buy_drink",drink),"Return up to 3",street_action.bind("return_drink",drink))
	if in_fridge:
		row_button("Mixed delivery",street_action.bind("mixed_drinks"))

func live_body(value: Callable,tint: Color = MUTED,px: int = 15) -> void:
	var label := body(value.call(),tint,px)
	live_labels.append([label,value])

func chapter_panel() -> void:
	var chapter := int(model.s.street.chapter)
	body("CHAPTER %d · %s" % [mini(5,chapter+1),StreetContent.CHAPTERS[chapter][0]],GOLD,14)
	body(StreetContent.CHAPTERS[chapter][1],MUTED,13)

func next_goal_panel() -> void:
	body("ANONG'S NEXT STEP",GOLD,14)
	live_body(func() -> String:
		var goal: Dictionary = model.street.next_goal()
		return goal.title+"\n"+goal.detail,TEAL,12)
	var button := row_button("Show next step",show_next_goal)
	button.name = "NextGoalButton"

func show_next_goal() -> void:
	var goal: Dictionary = model.street.next_goal()
	model.s.street.selected = goal.venue
	var upgrade_target: String = {"Upgrade ·":"Upgrade_renovate","SUPPLIER AGREEMENT":"Upgrade_supplier","MANAGEMENT":"Upgrade_manager"}.get(goal.focus,"")
	if not upgrade_target.is_empty():
		open_upgrades(false)
		await get_tree().process_frame
		var card := column.find_child(upgrade_target,true,false) as Control
		if card != null: scroll.ensure_control_visible(card)
		return
	change_tab(goal.tab)
	if goal.focus=="serve":
		close_drawer()
		for entry in action_controls:
			if entry[4]=="serve": entry[0].grab_focus()
		return
	if str(goal.focus).is_empty(): return
	await get_tree().process_frame
	if not is_instance_valid(scroll): return
	for node in column.get_children():
		if (node is Label or node is Button) and node.text.begins_with(goal.focus):
			scroll.ensure_control_visible(node)
			break

func upgrade_offers() -> Array[Dictionary]:
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	var offers: Array[Dictionary] = []
	for i in StreetContent.ACTION_UPGRADES.size():
		var item: Dictionary = StreetContent.ACTION_UPGRADES[i]
		var status: Dictionary = eco.action_upgrade_status(bar,i)
		if status.maxed: continue
		status.reason = "Needs venue stage 2." if not status.stage_ok else "Need %s more with the operating reserve." % cash(status.shortfall) if not status.enabled else ""
		var help := "Shortens your Serve refill." if i==0 else "Shortens Welcome. Chat still takes 20s. Nida uses her own timer."
		offers.append(upgrade_offer(item.id,item.name,"%ds → %ds" % [status.current,status.next],help,"action_upgrade",i,status))
	if not bar.auto_serve:
		offers.append(upgrade_offer("auto","Auto-serve","Owner helps automatically","Staff serve first. Auto-serve helps the rush or fills in when no bartender is on duty.","auto_serve",0,eco.auto_serve_offer(bar)))
	for i in StreetContent.EQUIPMENT.size():
		var item: Dictionary = StreetContent.EQUIPMENT[i]
		if item.id=="training" or (item.id=="pool" and bar.type!=0): continue
		var status: Dictionary = eco.equipment_offer(bar,i)
		if status.maxed: continue
		var caption: String = EQUIPMENT_CAPTIONS[item.id]
		var name_text: String = item.name
		if bar.type==0 and StreetContent.BEER_CAPS.has(item.id): name_text += " · Level %d" % (int(bar.equipment[item.id])+1)
		if item.id=="sign": caption = "+2 appeal"+(" · street draw uses the best sign" if bar.type==0 and bar.equipment.sign>=1 else "")
		if item.id=="fridge": caption = "+40 stock room · colder-beer reputation"
		if item.id=="music":
			caption = "%ds → %ds between rounds" % [StreetContent.MUSIC_INTERVALS[bar.equipment.music],StreetContent.MUSIC_INTERVALS[bar.equipment.music+1]]
			if bar.equipment.music==1: name_text = "Better sound system"
		if item.id=="seating":
			var proposed := bar.duplicate()
			proposed.equipment = bar.equipment.duplicate()
			proposed.equipment.seating += 1
			caption = "%d → %d seats" % [eco.seats(bar),eco.seats(proposed)]
			if bar.equipment.seating==2: name_text = "Compact layout"
		offers.append(upgrade_offer(item.id,name_text,caption,item.help,"equipment",i,status))
	var club: Dictionary = eco.club_offer(bar)
	if club.level<3:
		var estimate: Dictionary = eco.club_forecast(bar)
		var help := "Members plan and budget for one extra round, up to three. After the final drink they leave or finish pool. Birthday visits still cap at three. Needs stock, service and local regulars. Estimated automatic net change: %+.2f baht/s; actual takings vary." % estimate.delta
		offers.append(upgrade_offer("club","Regulars Club · Level %d" % (club.level+1),"%d%% of new visitors · extra round" % club.chance,help,"regulars_club",0,club))
	var supplier: Dictionary = eco.supplier_offer(bar)
	if supplier.level<StreetContent.SUPPLIER_PRICES.size():
		offers.append(upgrade_offer("supplier","Supplier · Level %d" % (supplier.level+1),"%d drinks / %s" % [supplier.quantity,cash(supplier.pack)],"Automatic deliveries buy whole packs when orders need stock. Later levels lower wholesale prices.","restock",0,supplier))
	var manager: Dictionary = eco.manager_offer(bar)
	if manager.level<StreetContent.MANAGER_PRICES.size():
		offers.append(upgrade_offer("manager","Manager · Level %d" % (manager.level+1),"+%s/s while open" % cash(manager.rate),"Manager income uses no stock. Management also enables offline trading.","manager",0,manager))
	if bar.stage<3:
		var reason: String = eco.upgrade_reason(bar)
		var status := {"price":model.street.upgrade_cost(bar),"enabled":reason.is_empty(),"reason":reason}
		offers.append(upgrade_offer("renovate","Renovate to stage %d" % (bar.stage+1),"More room & new upgrades","Renovation uses the happy visits, regulars and healthy shifts earned at this venue.","upgrade",0,status))
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if not int(person.role) in [0,2,3]: continue
		var audience: bool = person.role!=0
		var status: Dictionary = eco.training_offer(bar,i,audience)
		if status.maxed: continue
		var caption := "Attract more guests" if audience else "%ds → %ds per drink" % [eco.service_seconds(person),StreetContent.STAFF_SERVICE_SECONDS[status.level+1]]
		var name_text := "Gabby" if person.get("identity","")=="gabby" else "Nida" if person.role==3 else "%s %d" % [StreetContent.ROLE_NAMES[person.role],i+1]
		offers.append(upgrade_offer("audience" if audience else "training","Train "+name_text,caption,"Training stays with this worker when their contract expires.","train_audience" if audience else "train_staff",i,status))
	return offers

func upgrade_offer(icon: String, name_text: String, caption: String, help: String, action_id: String, index: int, status: Dictionary) -> Dictionary:
	return {"icon":icon,"name":name_text,"caption":caption,"help":help,"action":action_id,"index":index,"status":status}

func sync_upgrade_badge(rebuild: bool = false) -> void:
	if not is_instance_valid(upgrade_badge): return
	var offers := upgrade_offers()
	var ready: Array[String] = []
	for offer in offers:
		if offer.status.enabled: ready.append("%s/%d" % [offer.action,offer.index])
	var changed := upgrade_ready != ready
	upgrade_ready = ready
	upgrade_badge.visible = not ready.is_empty()
	upgrade_badge.text = str(ready.size())
	upgrade_badge.tooltip_text = "%d upgrades ready at this venue" % ready.size()
	if is_instance_valid(upgrades_entry):
		upgrades_entry.text = "Upgrades" if ready.is_empty() else "Upgrades   ·   %d ready" % ready.size()
	if changed and rebuild and drawer_open and upgrades_open: render(true)

func open_upgrades(ready_only: bool) -> void:
	fridge_open = false
	tab = 0
	drawer_open = true
	upgrades_open = true
	upgrades_ready_only = ready_only
	render()

func upgrades_panel() -> void:
	var offers := upgrade_offers()
	row_pair("‹  Service",change_tab.bind(0),"Show all" if upgrades_ready_only else "Ready only",open_upgrades.bind(not upgrades_ready_only))
	var bar: Dictionary = model.street.selected()
	body("Stage %d/3 · Supplier %d/5 · Manager %d/3" % [bar.stage,bar.supplier_level,bar.manager_level],MUTED,12)
	var ready: Array[Dictionary] = []
	var locked: Array[Dictionary] = []
	for offer in offers:
		(ready if offer.status.enabled else locked).append(offer)
	if ready.is_empty():
		body("No upgrades ready" if not offers.is_empty() else "All upgrades installed",MUTED,13)
	else:
		body("READY TO BUY",TEAL,12)
		for offer in ready: upgrade_card(offer)
	if not upgrades_ready_only and not locked.is_empty():
		body("LOCKED",MUTED,12)
		for offer in locked: upgrade_card(offer)

func upgrade_card(offer: Dictionary) -> void:
	var status: Dictionary = offer.status
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	column.add_child(row)
	var caption := "%s · %s" % [offer.caption,cash(status.price)]
	if status.get("required_stage",1)>model.street.selected().stage:
		caption += "\nNeeds venue stage %d" % status.required_stage
	var purchase := button("%s\n%s" % [offer.name,caption],street_action.bind(offer.action,offer.index))
	purchase.name = "Upgrade_"+offer.icon if not offer.action.begins_with("train_") else "Upgrade_%s_%d" % [offer.icon,offer.index]
	purchase.icon = UpgradeIcons.get_icon(offer.icon)
	purchase.alignment = HORIZONTAL_ALIGNMENT_LEFT
	purchase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase.custom_minimum_size.y = 50
	purchase.add_theme_font_size_override("font_size",13)
	purchase.add_theme_constant_override("h_separation",10)
	purchase.add_theme_stylebox_override("normal",box(Color("#252b31"),TEAL.darkened(.45)))
	purchase.add_theme_stylebox_override("disabled",box(DARK,EDGE.darkened(.35)))
	purchase.add_theme_color_override("font_disabled_color",MUTED)
	purchase.disabled = not status.enabled
	row.add_child(purchase)
	var details := body(offer.help if status.enabled else offer.help+"\n"+status.reason,MUTED,12)
	details.hide()
	var info := button("?",func() -> void: details.visible = not details.visible)
	info.custom_minimum_size.x = 38
	info.tooltip_text = "About "+offer.name
	row.add_child(info)

func street_panel() -> void:
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	var info: Dictionary = StreetContent.TYPES[int(bar.type)]
	title(bar.name)
	body("%s · Stage %d/3\n%s" % [info.name,bar.stage,info.stages[int(bar.stage)-1][0]],TEAL,16)
	if model.s.phase=="plan":
		upgrades_entry = row_button("Upgrades",func() -> void: open_upgrades(not upgrade_ready.is_empty()))
		upgrades_entry.name = "OpenUpgrades"
		upgrades_entry.icon = UpgradeIcons.get_icon("upgrades")
		sync_upgrade_badge()
	drink_panel(bar)
	live_body(func() -> String: return "%s · %s" % [model.street.clock_text(),eco.status(bar)],TEAL,14)
	live_body(func() -> String: return eco.peak_status(bar),TEAL,12)
	live_body(func() -> String:
		var party: Dictionary = model.street.celebration_info()
		return "%s · %s at the Blue Hour · details in Events" % ["Party tonight" if party.active else "Next: day %d" % party.day,party.name],PINK,12)
	next_goal_panel()
	if bar.auto_serve:
		var auto_button := row_button("Auto-serve · "+("On" if bar.auto_serve_on else "Off"),street_action.bind("auto_serve"))
		auto_button.icon = UpgradeIcons.get_icon("auto")
		auto_button.tooltip_text = eco.auto_serve_status(bar)
	if not eco.is_trading(bar):
		body("PREP FOR OPENING",GOLD,14)
		live_body(func() -> String: return eco.tips_text(bar),TEAL,12)
		live_body(func() -> String: return "Cleanliness %d%% · %.1f%% less attraction\n%s\nStock %d/%d · %d bartenders ready" % [100-int(bar.dirt),float(bar.dirt)/StreetContent.DIRT_LIMIT*StreetContent.DIRT_ATTRACTION_PENALTY*100.0,"Cleaning: %ds remaining" % bar.clean_remaining if bar.clean_remaining>0 else "Clean" if bar.dirt==0 else "Cleaning unfinished",bar.stock,eco.stock_capacity(bar),eco.on_duty(bar,0)],WHITE,13)
		if bar.dirt>0 and bar.clean_remaining==0: row_button("Clean venue · 15 seconds",street_action.bind("clean"))
		stock_button()
		if model.street.can_skip():
			if int(model.s.street.night_prep.remaining)>0:
				live_body(func() -> String: return model.street.night_prep_text(),TEAL,13)
				row_button("Stay here · cancel jump",street_action.bind("stay"))
			elif model.s.street.night_prep.cancelled:
				body("Automatic jump cancelled for this night. Cleaning continues.",TEAL,13)
			body("Skip leaves unfinished cleaning and stock as they are.",MUTED,12)
			for venue in model.s.street.bars:
				live_body(func() -> String: return "%s · %s · stock %d/%d" % [venue.name,"clean" if venue.dirt==0 else "needs cleaning",venue.stock,eco.stock_capacity(venue)],MUTED,12)
			row_button("Skip to 12pm",street_action.bind("skip"),true)
		body("Sales and operating charges pause while closed.",MUTED,12)
	else:
		live_body(func() -> String:
			var view: Dictionary = eco.forecast(bar)
			return "Rates per real minute\nDemand %.1f drinks · Automatic service %.1f\n%d orders · %d/%d customers · Stock %d\nRecent net %s · Auto forecast %s\nCosts %s · Break-even %.1f drinks\n%s" % [view.demand,view.service,eco.pending(bar),bar.customers.size(),eco.seats(bar),bar.stock,cash(eco.actual_rate(bar)),cash(view.net),cash(view.costs),view.break_even,view.reason],GOLD,13)
		live_body(func() -> String: return "Cleanliness %d%% · %.1f%% less attraction" % [100-int(bar.dirt),float(bar.dirt)/StreetContent.DIRT_LIMIT*StreetContent.DIRT_ATTRACTION_PENALTY*100.0],MUTED,12)
		stock_button()
	if not bar.raided and (bar.late_open or model.s.street.minute>=StreetContent.OPEN_MINUTE or model.s.street.minute<StreetContent.CLOSE_MINUTE):
		live_body(func() -> String: return "Heat %d · Raid chance %.1f%% each 15 late minutes\nPossible fine %s · closed until noon if raided" % [model.s.heat,model.street.raid_chance(),cash(StreetContent.RAID_FINE_PER_STAGE*int(bar.stage))],PINK,12)
		row_button("Cancel late opening tonight" if bar.late_open else "Stay open until 3am tonight",street_action.bind("late"))
	row_button("Close venue" if bar.open else "Enable opening",street_action.bind("open"))
	if not bar.open:
		body(bar.close_reason,PINK,13)
		row_button("Owner-run recovery shift",street_action.bind("recovery"))
	if bar.club_level>0:
		live_body(func() -> String: return "Regulars Club %d/3 · %d%% of new guests plan an extra round (max 3)" % [bar.club_level,StreetContent.CLUB_CHANCE[bar.club_level]],TEAL,12)
	body("YOUR PROFIT CYCLE",TEAL,14)
	live_body(func() -> String:
		var view: Dictionary = eco.business_summary(bar)
		return "%s (%ds) · customer profit %s/min\nManager income %s/min (separate)\n%d arrivals · %d orders · %d sales · %d completed visits\nNow: %d waiting · %d drinking · %d finishing\n%s" % [view.sample,view.sample_seconds,cash(view.profit_per_minute),cash(view.manager_per_minute),view.arrivals,view.orders,view.sales,view.completed,view.waiting,view.drinking,view.finishing,view.reason],WHITE,13)
	row_button("Hide visit plans" if visit_plans_open else "Show visit plans",func() -> void:
		visit_plans_open = not visit_plans_open
		render(true))
	if visit_plans_open: live_body(func() -> String: return eco.visit_lines(bar),MUTED,12)
	live_body(func() -> String: return "Next business report in %ds of trading" % (model.street.SHIFT_SECONDS-int(model.s.street.seconds)),MUTED,12)
	if bar.equipment.pool>0:
		body("POOL · ฿50 PER GAME",GOLD,14)
		live_body(func() -> String:
			var timers := []
			for game in bar.games: timers.append("Table %d: %ds (%s)" % [int(game.get("table",0))+1,game.remaining,"free" if game.fee==0 else "paid"])
			return "%d/%d tables busy · %d waiting\n%s\n%d games · %s pool income · %d free games" % [bar.games.size(),bar.equipment.pool,eco.pool_queue(bar).size(),", ".join(timers),bar.pool_games,cash(bar.pool_income),bar.free_games],WHITE,13)
	if bar.type==2:
		live_body(func() -> String: return "Performance: %s · dancers attract; bartenders serve." % ("on stage" if int(model.s.street.seconds) in range(40,80) else "next set at 40s into each shift"),TEAL,13)
	body("TEAM & PAYROLL",GOLD,14)
	body("10-day contracts · On-duty wages while trading",MUTED,12)
	if eco.floor_staff(bar)<model.street.staff_limit(bar):
		for role in 3:
			if role>0 and role!=bar.type: continue
			row_button("Hire %s · %s" % [StreetContent.ROLE_NAMES[role].to_lower(),cash(eco.contract_cost(role))],street_action.bind("hire",role))
			body("Adds ฿%d/real min. Forecast break-even after hire: %.1f drinks/real min. %s" % [StreetContent.ROLE_WAGES[role],maxf(0,(eco.operating_rate(bar)+int(StreetContent.ROLE_WAGES[role])-eco.forecast(bar).pool-eco.forecast(bar).manager)/maxf(1,eco.price(bar)-eco.stock_unit_cost(bar))),"One drink every 25s; help with the rush." if role==0 else "Attracts visitors; does not serve drinks."],MUTED,12)
	if eco.floor_staff(bar)<model.street.staff_limit(bar) and eco.gabby_venue().is_empty():
		character_card("gabby","Gabby · adult bartender","Red dress, quick wit, generous regulars")
		row_button("Hire Gabby · ฿1,200",street_action.bind("hire_gabby"))
		body("10 days · normal bartender wages and training. +฿%d per drink she serves, counted at closing. Uses one team position." % StreetContent.GABBY_TIP_PER_DRINK,MUTED,12)
	body("FRONTAGE PROMOTER",GOLD,14)
	body("Nida · adult promoter · ฿1,200 / ten days. No commission or hourly wage. One frontage slot; never serves drinks.",MUTED,12)
	if bar.commission_paid>0: body("Historical commission paid: %s. No further commission is charged." % cash(bar.commission_paid),MUTED,12)
	if eco.promoter_index(bar)<0:
		row_button("Hire Nida · ฿1,200",street_action.bind("hire",3))
		row_button("Hide forecast" if nida_forecast_open else "Show Nida forecast",func() -> void:
			nida_forecast_open = not nida_forecast_open
			render(true))
		if nida_forecast_open:
			live_body(func() -> String:
				var auto: Dictionary = eco.promoter_forecast(bar)
				var active: Dictionary = eco.promoter_forecast(bar,true)
				return "Estimate after hire · cash %s; retain %s plus %s stock.\nArrivals %.1f → %.1f/min · staff service %.1f/min\nUnattended net %s → %s/min\nOwner serving whenever ready: net %s → %s/min\nStreet net change: %s/min unattended; %s/min owner-active.\n%s" % [cash(int(model.s.cash)-1200),cash(eco.operating_rate(bar)*2),cash(eco.pack_price(bar)),auto.before.arrivals,auto.after.arrivals,auto.after.service,cash(auto.before.net),cash(auto.after.net),cash(active.before.net),cash(active.after.net),cash(auto.street_delta),cash(active.street_delta),"Service is limiting sales; improve pouring/staff first." if auto.after.service<auto.after.demand else "Requires stock and spare seats; estimates are not actual income."],MUTED,12)
	else:
		var nida_index: int = eco.promoter_index(bar)
		var renew := row_button("Rehire Nida · ฿1,200",street_action.bind("rehire",nida_index))
		live_body(func() -> String:
			var offer: Dictionary = eco.rehire_offer(bar,nida_index)
			renew.disabled = not offer.enabled
			return "Renewal: ฿%d fee; keep ฿%d for payroll and one delivery. %s" % [offer.price,offer.reserve,offer.reason],GOLD,12)
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		var name_text: String = StreetContent.ROLE_NAMES[int(person.role)]+" %d" % (i+1)
		if person.role==1: name_text = StreetContent.HOSTS[int(person.host)][0]
		if person.role==3: name_text = "Nida"
		if person.get("identity","")=="gabby": name_text = "Gabby"
		if person.get("identity","")=="gabby": body("+฿%d tip per drink Gabby serves · paid at closing" % StreetContent.GABBY_TIP_PER_DRINK,TEAL,12)
		character_card(Art.worker_id(bar,i),name_text,"Contract finished" if not eco.contracted(person) else "Serves waiting orders" if person.role==0 else "Attracts visitors")
		live_body(func() -> String:
			var remaining := int(person.get("contract_left",StreetContent.STAFF_CONTRACT_MINUTES))
			return ("Contract: %dd %dh %dm left" % [remaining/1440,remaining%1440/60,remaining%60] if remaining>0 else "Contract finished · rehire available")+" · Training %d/%d" % [int(person.get("audience_training",0) if person.role in [2,3] else person.get("training",0)),2 if person.role in [2,3] else eco.training_limit(bar)],GOLD,12)
		if not eco.contracted(person):
			if person.role!=3:
				row_button("Rehire %s · %s" % [name_text,cash(eco.contract_cost(int(person.role)))],street_action.bind("rehire",i))
				live_body(func() -> String: return eco.rehire_offer(bar,i).reason,MUTED,12)
			continue
		if person.role==0:
			live_body(func() -> String: return eco.staff_status(bar,person).text+" · %d staff drinks served" % int(person.get("drinks_served",0)),TEAL,12)
			body("Ready staff serve immediately, then recover for %ds (%.1f/min). You can serve alongside them." % [eco.service_seconds(person),60.0/eco.service_seconds(person)],MUTED,12)
			if int(person.get("training",0))<eco.training_limit(bar):
				var offer: Dictionary = eco.training_offer(bar,i,false)
				var training_button := row_button("Train %s · %s · %ds" % [name_text,cash(offer.price),StreetContent.STAFF_SERVICE_SECONDS[offer.level+1]],street_action.bind("train_staff",i))
				live_body(func() -> String:
					var current: Dictionary = eco.training_offer(bar,i,false)
					training_button.disabled = not current.enabled
					return current.reason,MUTED,12)
				training_button.icon = UpgradeIcons.get_icon("training")
		if person.role in [2,3]:
			var audience_level := int(person.get("audience_training",0))
			body("Attraction +%.1f; replaces Welcome taps." % StreetContent.PROMOTER_BONUS[audience_level] if person.role==3 else "Dancer attraction ×%.2f; no drink service." % StreetContent.DANCER_TRAINING[audience_level],MUTED,12)
			if audience_level<2:
				var training_button := row_button("Train %s · %s · needs stage %d" % [name_text,cash(StreetContent.AUDIENCE_TRAINING_COST*(audience_level+1)),audience_level+2],street_action.bind("train_audience",i))
				training_button.icon = UpgradeIcons.get_icon("audience")
		row_button("%s · %s" % [name_text,"On duty" if person.on else "Off duty"],street_action.bind("rota",i))
		if bar.type>0 and person.role!=3 and person.get("identity","")!="gabby": row_button("Reassign role · %s · %s" % [name_text,cash(eco.role_change_fee(bar,i))],street_action.bind("role",i))
		if person.role==1:
			body(StreetContent.HOSTS[int(person.host)][1],MUTED,12)
			row_button("Bar-fine request · "+name_text,street_action.bind("bar_fine",i))
	if bar.type==1: live_body(func() -> String: return "%d actual customer requests · %d hosts away" % [bar.host_requests.size(),bar.away.size()],MUTED,12)
	body("NIGHTLY TIPS",GOLD,14)
	live_body(func() -> String: return eco.tips_text(bar),TEAL,13)
	shift_report(bar)
	chapter_panel()
	row_button("Promotions & free pool",change_tab.bind(1))
	row_button("View street & buy bars",change_tab.bind(3))

func shift_report(bar: Dictionary) -> void:
	if bar.last_shift.is_empty(): return
	var report: Dictionary = bar.last_shift
	body("LAST SHIFT",GOLD,14)
	body("%d arrivals · %d orders · %d drinks sold\nRevenue %s · inventory %s · operating %s · promotions %s · fines %s · commission %s\nManager income %s (included in revenue)\nNet %s\nLost: full %d · slow %d · out of stock %d\n%s" % [report.arrivals,report.orders,report.sales,cash(report.revenue),cash(report.stock_cost),cash(report.operating),cash(report.promo_cost),cash(report.get("fines",0)),cash(report.get("commission",0)),cash(report.get("manager_income",0)),cash(report.net),report.lost_full,report.lost_service,report.lost_stock,report.reason],WHITE,13)

func celebration_panel() -> void:
	var info: Dictionary = model.street.celebration_info()
	title(info.name,PINK)
	body("FREE neighbourhood celebration · Blue Hour",TEAL,14)
	live_body(func() -> String:
		var current: Dictionary = model.street.celebration_info()
		return "LIVE until 1am · day %d opening" % current.day if current.active else "Day %d at noon · %s" % [current.day,"today" if current.days_left==0 else "tomorrow" if current.days_left==1 else "%d game days to go" % current.days_left],GOLD,14)
	body(StreetContent.CELEBRATIONS[model.street.Economy.celebration_index(int(info.day))][1],WHITE,14)
	body("+40% shared street traffic and extra Blue Hour appeal. One extra planned round, up to 3 if budgets allow. Drinking takes 26/19/14/11/8s by music tier, including the final round. Visitors wait 10s longer for orders. Traffic boosts cap at 2.4× normal. Normal prices, pool fees and wages still apply.",MUTED,13)
	body("Prepare: clean the bar, fill the fridge, check staff contracts and leave room for deliveries. Serve the queue or use Chat before advertising harder. No entry fee or paid preparation; offline time cannot use up the party.",WHITE,13)
	var report: Dictionary = model.s.street.celebration.report
	if report.is_empty(): report = model.s.street.celebration.last_report
	if not report.is_empty():
		body("PARTY TRADING · "+model.street.Economy.celebration_name(int(report.day)),GOLD,14)
		live_body(func() -> String: return "%d visitors · %d drinks · %d happy visits · %d new regulars\nDrinks %s · pool %s\nStock consumed %s · commission %s\nOperating %s · promotions %s · fines %s\nTrading contribution %s\nLost: full %d · slow %d · stock %d" % [report.arrivals,report.sales,report.happy,report.regulars,cash(report.drink_income),cash(report.pool_income),cash(report.drink_cost),cash(report.commission),cash(report.operating),cash(report.promo_cost),cash(report.fines),cash(model.street.Economy.celebration_contribution(report)),report.lost_full,report.lost_service,report.lost_stock],WHITE,13)
		body("Actual Blue Hour trading during the celebration, not estimated extra income. Contribution deducts consumed stock and venue trading costs; excludes managers, street-wide charges, investments and unused deliveries. No bonus is paid again when this report opens.",MUTED,12)

func street_event_panel() -> void:
	var event: Dictionary = model.s.street.event
	if event.is_empty(): return
	var info: Array = StreetContent.EVENTS[int(event.id)]
	title(info[0],PINK)
	body(info[1],WHITE,14)
	var rules := [
		"Without a generator: a 20-second closure.",
		"More shore-leave customers; stock, seats and service still limit sales.",
		"Prepare or maintain permits (75) and safety (65). Gaps can mean a fine and 40-second closure.",
		"Pumps or neighbour trust (60) prevent a 40-second closure. Helping builds trust.",
		"Beer bars benefit most. Unprotected equipment closes for 20 seconds.",
		"Door cover brings a bigger bonus and better reviews.",
		"Beer bars retain regular trade; premium venues slow down. A locals' night builds regulars.",
		"Promote your lineup to capture overflow; otherwise expect quieter trade.",
		"Preparation adds four seconds to the challenge. A loss closes venues for 30 seconds.",
		"Double street traffic during the festival. Preparation adds four seconds against Godzilla.",
		"Guests bolt and walk-ins dry up for 45 seconds. Bo keeps seated guests inside and helps save some trade."
	]
	body(Local.RULES[int(event.id)] if Local.RULES.has(int(event.id)) else rules[int(event.id)],MUTED,12)
	if event.has("venue"): body(model.s.street.bars[int(event.venue)].name,GOLD,12)
	row_button("Read the Dispatch",func() -> void: show_news(street_issue()))
	live_body(func() -> String: return "%s · %ds · %s" % ["Starts in" if event.phase == "warning" else "Time remaining",event.remaining,"Prepared" if event.prepared else "Unprepared"],GOLD,14)
	if event.phase == "warning" and not event.prepared:
		if event.id==Local.ENCORE and not event.get("solo",false): row_button("Work the rush solo",street_action.bind("encore_solo"))
		row_button("%s · %s" % [info[2],cash(info[3])] if info[3]>0 else info[2],street_action.bind("prepare"))
	if event.phase=="active" and not event.get("attempted",false):
		if event.id==Local.CART and not event.prepared: row_button("Clear traffic · Play",start_event_game,true)
		if event.id==Local.BED and event.prepared: row_button("Race the bed · Play",start_event_game,true)
	if event.phase == "active" and int(event.id) in [8,9]:
		row_button("Face Godzilla",func():
			message = model.start_street_boss()
			commit(),true)

func street_issue() -> Dictionary:
	var event: Dictionary = model.s.street.event
	var id := int(event.id)
	var info: Array = StreetContent.EVENTS[id]
	return {"id":id,"headline":info[0],"lead":info[1],"source":Local.SOURCES.get(id,[])}

func poll_news() -> void:
	if model.s.phase!="plan" or offline_notice>0 or is_instance_valid(district) or is_instance_valid(fight): return
	var prefix := "%d/" % model.get_instance_id()
	var event: Dictionary = model.s.street.event
	if not event.is_empty():
		var key := prefix+"event/%s/%s" % [event.id,event.get("serial",model.s.day)]
		if not seen_news.has(key):
			seen_news[key] = true
			show_news(street_issue())
			return
	var party: Dictionary = model.street.celebration_info()
	if party.active and not seen_news.has(prefix+"party/%d" % party.day):
		seen_news[prefix+"party/%d" % party.day] = true
		show_news({"headline":party.name,"lead":"The Blue Hour is hosting a neighbourhood celebration. Expect more traffic and more rounds.","source":[]})
		return
	for bar in model.s.street.bars:
		if not bar.raided: continue
		var key := prefix+"raid/%d/%s" % [model.s.day,bar.name]
		if seen_news.has(key): continue
		seen_news[key] = true
		show_news({"headline":"Late-night raid","lead":"%s was fined and closed until noon." % bar.name,"source":[]})
		return

func show_news(issue: Dictionary) -> void:
	news_issue = issue
	draw_event_overlay()

func close_news(details: bool) -> void:
	var id := int(news_issue.get("id",-1))
	news_issue = {}
	if details:
		if id>=Local.ENCORE and model.s.street.event.get("id",-1)==id:
			model.s.street.selected = int(model.s.street.event.venue)
		change_tab(1)
	else:
		draw_event_overlay()

func overlay_panel(rect: Rect2, fill: Color, border: Color) -> Panel:
	event_overlay = pane(root_ui,Rect2(0,0,960,540),Color(0.03,0.02,0.04,.68),Color.TRANSPARENT)
	event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	event_overlay.z_index = 12
	return pane(event_overlay,rect,fill,border)

func draw_event_overlay() -> void:
	if is_instance_valid(event_overlay):
		event_overlay.hide()
		event_overlay.queue_free()
		event_overlay = null
	if event_game>=0:
		draw_event_game()
	elif not news_issue.is_empty():
		draw_newspaper()

func draw_newspaper() -> void:
	var ink := Color("#392526")
	var paper := overlay_panel(Rect2(171,65,618,414),Color("#f4e2be"),Color("#aa7053"))
	var masthead := abs_text(paper,Rect2(25,15,455,44),"The Soi Dispatch",30,ink)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","Noto Serif","DejaVu Serif"])
	masthead.add_theme_font_override("font",serif)
	abs_text(paper,Rect2(498,20,95,30),"DAY %03d" % model.s.day,15,ink)
	pane(paper,Rect2(25,63,568,2),ink,ink)
	var headline := abs_text(paper,Rect2(25,79,568,68),news_issue.headline,29,ink)
	headline.add_theme_font_override("font",serif)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var photo := TextureRect.new()
	photo.position = Vector2(25,147)
	photo.size = Vector2(136,69)
	photo.texture = Art.texture("beer-1")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.modulate = Color("#b9a490")
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(photo)
	var lead := abs_text(paper,Rect2(177,146,416,70),news_issue.lead,17,ink)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var source: Array = news_issue.source
	if not source.is_empty():
		pane(paper,Rect2(25,226,568,1),ink,ink)
		abs_text(paper,Rect2(25,235,568,22),"IN THE REAL PATTAYA",13,ink)
		var context := abs_text(paper,Rect2(25,260,568,49),source[0],15,ink)
		context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		at_button(paper,Rect2(25,314,568,38),"Read the original · "+str(source[1]),func() -> void: OS.shell_open(source[2]))
	var dismiss := at_button(paper,Rect2(25,364,270,38),"Back to the bar",close_news.bind(false))
	at_button(paper,Rect2(305,364,288,38),"Open Events",close_news.bind(true),true)
	dismiss.grab_focus()

func start_event_game() -> void:
	event_game = model.street.begin_event_game()
	if event_game<0: return
	save_state()
	cart_board = Local.BOARD.duplicate(true)
	cart_selected = 0
	cart_moves = 0
	cart_held = -1
	race_left = Local.BED_SECONDS
	race_finish_left = -1.0
	race_taps = 0
	draw_event_overlay()

func end_event_game(won: bool) -> void:
	if event_game!=Local.BED or race_finish_left<0:
		message = model.street.settle_event_game(event_game,won)
	event_game = -1
	cart_held = -1
	commit(true)

func slide_cart(direction: int) -> void:
	if event_game!=Local.CART: return
	var horizontal: bool = cart_board[cart_selected][3]
	if Local.slide(cart_board,cart_selected,direction):
		cart_moves += 1
		cart_slide_offset = Vector2(-direction*CART_CELL,0) if horizontal else Vector2(0,-direction*CART_CELL)
	if Local.delivery_free(cart_board): end_event_game(true)
	else: draw_event_overlay()

func cart_pointer_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var point: Vector2 = event_overlay.get_global_transform_with_canvas().affine_inverse()*event.position
		return begin_cart_drag(point,event.index) if event.pressed else finish_cart_drag(point,event.index,event.canceled)
	if event is InputEventScreenDrag:
		return move_cart_drag(event_overlay.get_global_transform_with_canvas().affine_inverse()*event.position,event.index)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION: return cart_held>=0
		var point: Vector2 = event_overlay.get_global_transform_with_canvas().affine_inverse()*event.position
		return begin_cart_drag(point,-1) if event.pressed else finish_cart_drag(point,-1,false)
	if event is InputEventMouseMotion:
		return move_cart_drag(event_overlay.get_global_transform_with_canvas().affine_inverse()*event.position,-1)
	return false

func begin_cart_drag(point: Vector2, pointer: int) -> bool:
	if cart_held>=0: return true
	for i in cart_tiles.size():
		var tile := cart_tiles[i]
		if not Rect2(tile.position,tile.size).has_point(point): continue
		cart_selected = i
		cart_held = i
		cart_pointer = pointer
		cart_touch_start = point
		cart_tile_start = tile.position
		cart_axis = Vector2.RIGHT if cart_board[i][3] else Vector2.DOWN
		cart_offset = 0.0
		cart_limits = Vector2.ZERO
		for direction in [-1,1]:
			var board := cart_board.duplicate(true)
			var steps := 0
			while Local.slide(board,i,direction): steps += 1
			if direction<0: cart_limits.x = -steps*CART_CELL
			else: cart_limits.y = steps*CART_CELL
		for j in cart_tiles.size(): style_cart_tile(cart_tiles[j],j==i)
		tile.z_index = 1
		return true
	return false

func move_cart_drag(point: Vector2, pointer: int) -> bool:
	if cart_held<0 or pointer!=cart_pointer: return false
	cart_offset = clampf((point-cart_touch_start).dot(cart_axis),cart_limits.x,cart_limits.y)
	cart_tiles[cart_held].position = cart_tile_start+cart_axis*cart_offset
	return true

func finish_cart_drag(point: Vector2, pointer: int, cancelled: bool) -> bool:
	if not move_cart_drag(point,pointer): return false
	var steps := 0 if cancelled else roundi(cart_offset/CART_CELL)
	cart_held = -1
	if steps!=0:
		for i in absi(steps): Local.slide(cart_board,cart_selected,signi(steps))
		cart_moves += 1
		tone("click")
	cart_slide_offset = cart_axis*(cart_offset-float(steps*CART_CELL))
	if Local.delivery_free(cart_board): end_event_game(true)
	else: draw_event_overlay()
	return true

func tap_race() -> void:
	if event_game!=Local.BED or race_left<=0 or race_finish_left>=0: return
	race_taps += 1
	if race_taps==Local.BED_TAPS:
		race_finish_left = .65
		message = model.street.settle_event_game(event_game,true)
		save_state()
	update_race()

func update_race() -> void:
	race_meter.value = race_taps
	race_clock.text = "FIRST ACROSS!" if race_finish_left>=0 else "%.1fs left · %d / %d pushes" % [race_left,race_taps,Local.BED_TAPS]
	race_course.victory = race_finish_left>=0
	race_course.target = float(race_taps)/Local.BED_TAPS
	race_course.rival = 1.0-race_left/Local.BED_SECONDS

func cart_art(vehicle: Panel, index: int, horizontal: bool, slide: Vector2) -> void:
	var tile := 0 if index==0 else 1+(index-1)%3
	var atlas := AtlasTexture.new()
	atlas.atlas = Art.texture("cart-jam-overhead")
	atlas.region = Rect2((tile%2)*144,(tile/2)*72,144,72)
	var sprite := TextureRect.new()
	sprite.texture = atlas
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.size = vehicle.size-Vector2(8,8) if horizontal else Vector2(vehicle.size.y-8,vehicle.size.x-8)
	var resting := (vehicle.size-sprite.size)*.5
	sprite.position = resting+slide
	sprite.pivot_offset = sprite.size*.5
	sprite.rotation = 0.0 if horizontal else PI/2
	vehicle.add_child(sprite)
	if slide!=Vector2.ZERO:
		sprite.create_tween().tween_property(sprite,"position",resting,.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func draw_event_game() -> void:
	var stage := overlay_panel(Rect2(0,0,960,540),Color("#1d1526"),Color("#1d1526"))
	if event_game==Local.CART:
		draw_cart_game(stage)
	else:
		draw_bed_game(stage)

func draw_cart_game(stage: Panel) -> void:
	abs_text(stage,Rect2(50,13,480,47),"Cart Jam",33,GOLD)
	abs_text(stage,Rect2(50,64,815,30),"Drag the food carts along their lanes. Get Bo’s mint van to the exit.",16)
	var cell := CART_CELL
	cart_tiles.clear()
	var origin := Vector2(54,111)
	pane(stage,Rect2(origin-Vector2(8,8),Vector2(412,412)),Color("#58414c"),Color("#9f735d"))
	for y in 6:
		for x in 6:
			var tile := origin+Vector2(x,y)*cell
			pane(stage,Rect2(tile,Vector2(cell,cell)),Color("#332b3e") if (x+y)%2==0 else Color("#393144"),Color("#55475a"))
			pane(stage,Rect2(tile+Vector2(29,31),Vector2(9,3)),Color("#705966"),Color("#705966"))
	pane(stage,Rect2(450,245,75,62),Color("#24565b"),Color("#71f9d2"))
	abs_text(stage,Rect2(462,255,62,43),"EXIT →",15,TEAL)
	for i in cart_board.size():
		var car: Array = cart_board[i]
		var top_left := origin+Vector2(car[0],car[1])*cell+Vector2(2,2)
		var span := Vector2(car[2],1) if car[3] else Vector2(1,car[2])
		var vehicle := pane(stage,Rect2(top_left,span*cell-Vector2(4,4)),DARK)
		vehicle.mouse_default_cursor_shape = Control.CURSOR_DRAG
		vehicle.tooltip_text = "Bo’s delivery van" if i==0 else ["Noodle cart","Skewer cart","Fruit cart"][(i-1)%3]
		style_cart_tile(vehicle,i==cart_selected)
		cart_tiles.append(vehicle)
		cart_art(vehicle,i,car[3],cart_slide_offset if i==cart_selected else Vector2.ZERO)
	cart_slide_offset = Vector2.ZERO
	abs_text(stage,Rect2(569,117,310,28),"SOI 6 · DELIVERY ROUTE",14,GOLD)
	abs_text(stage,Rect2(569,151,310,46),"%d moves" % cart_moves,25,TEAL)
	var legend := pane(stage,Rect2(569,218,148,68),Color("#253b42"),TEAL)
	cart_art(legend,0,true,Vector2.ZERO)
	abs_text(stage,Rect2(730,220,155,62),"BO’S VAN  →",18,TEAL)
	abs_text(stage,Rect2(569,298,316,32),"Desktop: select a cart and use arrows.",13,MUTED)
	at_button(stage,Rect2(569,350,316,49),"Reset board",func() -> void:
		cart_board = Local.BOARD.duplicate(true)
		cart_selected = 0
		cart_moves = 0
		draw_event_overlay()).focus_mode = Control.FOCUS_NONE
	at_button(stage,Rect2(569,428,316,49),"Wait out the jam",end_event_game.bind(false)).focus_mode = Control.FOCUS_NONE

func style_cart_tile(tile: Panel, selected: bool) -> void:
	tile.add_theme_stylebox_override("panel",box(Color("#253b42") if selected else Color("#322738"),TEAL if selected else Color("#5a4349"),2))

func draw_bed_game(stage: Panel) -> void:
	abs_text(stage,Rect2(26,9,650,42),"Bo’s Bed Race",32,GOLD)
	abs_text(stage,Rect2(28,52,660,24),"BEACH ROAD · PATTAYA",13,TEAL)
	race_clock = abs_text(stage,Rect2(675,29,265,37),"",18,WHITE)
	race_course = BedRaceCourse.new()
	race_course.position = Vector2(0,80)
	race_course.size = Vector2(960,320)
	stage.add_child(race_course)
	race_meter = ProgressBar.new()
	race_meter.position = Vector2(26,418)
	race_meter.size = Vector2(909,10)
	race_meter.max_value = Local.BED_TAPS
	race_meter.show_percentage = false
	race_meter.add_theme_stylebox_override("fill",box(TEAL,TEAL,0))
	race_meter.add_theme_stylebox_override("background",box(Color("#493a50"),Color("#493a50"),0))
	stage.add_child(race_meter)
	at_button(stage,Rect2(26,447,711,67),"PUSH!   ·   Tap or press Space",tap_race,true).focus_mode = Control.FOCUS_NONE
	at_button(stage,Rect2(754,447,181,67),"Drop out",end_event_game.bind(false)).focus_mode = Control.FOCUS_NONE
	update_race()

func start_tuning() -> void:
	if campaign_before_tuning != null or campaign_before_tutorial != null or model.s.phase!="plan": return
	save_state()
	campaign_before_tuning = model
	model = model.tuning_copy()
	tuning_speed = 2
	open_tuning()

func open_tuning() -> void:
	tuning_open = true
	message = ""
	render()

func stop_tuning() -> void:
	model = campaign_before_tuning
	campaign_before_tuning = null
	tuning_speed = 1
	change_tab(4)

func tuning_panel() -> void:
	title("Tuning playtest")
	body("Test copy · Your main campaign is paused.",GOLD,13)
	row_button("Street speed · %d×" % tuning_speed,func() -> void:
		tuning_speed = 1 if tuning_speed==2 else 2
		render(true))
	var eco = model.street.economy
	row_button("Passing crowds · %d%%" % roundi(eco.walk_in_scale*100),func() -> void:
		var rates := [1.0,1.25,1.5,.75]
		eco.walk_in_scale = rates[(rates.find(eco.walk_in_scale)+1)%rates.size()]
		render(true))
	row_button("Owner cooldowns · %d%%" % roundi(eco.owner_recharge_scale*100),func() -> void:
		var rates := [1.0,.75,.5,1.25]
		eco.owner_recharge_scale = rates[(rates.find(eco.owner_recharge_scale)+1)%rates.size()]
		render(true))
	var rats := row_button("Trigger Rat Plague",func() -> void:
		model.street.announce(StreetContent.RAT_PLAGUE)
		model.street.start_event()
		tab = 0
		close_drawer())
	rats.disabled = not model.s.street.event.is_empty() or not model.street.any_trading()
	rats.tooltip_text = "Available during trading when the street has no active event." if rats.disabled else "Start the full swarm now."
	row_pair("‹  Journal",change_tab.bind(4),"End playtest",stop_tuning)

func journal_panel() -> void:
	if campaign_before_tuning == null:
		row_button("Start tuning playtest · 2×",start_tuning)
	else:
		row_pair("Tuning settings",open_tuning,"End playtest",stop_tuning)
	character_card("anong","Anong","The street, the stories, and the books.")
	chapter_panel()
	body("NIGHTLY TIP JARS",GOLD,14)
	for venue in model.s.street.bars:
		body(venue.name,GOLD,13)
		live_body(func() -> String: return model.street.economy.tips_text(venue),TEAL,13)
	celebration_panel()
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
	if campaign_before_tuning == null:
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
	state.append([int(model.s.street.night_prep.remaining)>0,model.s.street.night_prep.cancelled])
	for venue in model.s.street.bars:
		state.append([venue.raided,venue.clean_remaining>0,venue.dirt==0])
		for person in venue.team: state.append([model.street.economy.contracted(person),person.on,person.role])
	return state

func _process(delta: float) -> void:
	if updater_worker or boot_menu: return
	scene_clock += delta
	service_animation = maxf(0,service_animation-delta)
	if event_game>=0:
		if event_game==Local.BED:
			if race_finish_left>=0:
				race_finish_left = maxf(0,race_finish_left-delta)
				if race_finish_left==0: end_event_game(true)
			else:
				race_left = maxf(0,race_left-delta)
				if race_left<=0: end_event_game(false)
				else: update_race()
		return
	if not news_issue.is_empty(): return
	if campaign_before_tutorial == null:
		poll_news()
		if not news_issue.is_empty(): return
		var before := street_ui_state()
		model.street.night_prep_visible = not is_instance_valid(fight) and not is_instance_valid(district)
		model.street.advance(minf(delta,1.0)*tuning_speed)
		refresh_street = refresh_street or before != street_ui_state()
		update_action_controls()
		live_seconds += minf(delta,1.0)
		save_seconds += minf(delta,1.0)
		if live_seconds >= 1.0:
			live_seconds -= 1.0
			if not is_instance_valid(fight) and not is_instance_valid(district): sync_upgrade_badge(true)
			if refresh_street and model.s.phase in ["plan","guided","guided_choice","guided_report"] and not is_instance_valid(fight) and not is_instance_valid(district): render(true)
			for entry in live_labels:
				if is_instance_valid(entry[0]): entry[0].text = entry[1].call()
		if save_seconds >= 15.0:
			save_seconds = 0.0
			save_state()
	var alert_enabled: bool = campaign_before_tutorial==null and model.s.phase in ["plan","guided"] and not is_instance_valid(fight) and not is_instance_valid(district) and not muted
	var waiting := false
	var selected_bar: Dictionary = model.street.selected()
	if alert_enabled and model.street.economy.is_trading(selected_bar): waiting = model.street.economy.pending(selected_bar)>0
	if order_alert.tick(waiting,delta,alert_enabled) and DisplayServer.get_name()!="headless": order_sound.play()
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
	start_new_game()

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
	if boot_menu:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST and new_game_confirmation: cancel_new_game()
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if campaign_before_tutorial == null: save_state()
	if what == NOTIFICATION_APPLICATION_RESUMED and campaign_before_tutorial == null and campaign_before_tuning == null:
		offline_notice = model.street.claim_offline(int(Time.get_unix_time_from_system()))
		save_state()
		refresh_street = true
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if event_game>=0: end_event_game(false)
		elif not news_issue.is_empty(): close_news(false)
		elif is_instance_valid(district): close_district()
		elif is_instance_valid(fight): leave_fight(fight.result if fight.over else false)
		elif campaign_before_tutorial != null: finish_tutorial()
		elif offline_notice > 0 and model.s.phase == "plan": dismiss_offline()
		elif drawer_open and model.s.phase == "plan": close_drawer()

func _unhandled_key_input(event: InputEvent) -> void:
	if boot_menu:
		if event.is_action_pressed("ui_cancel") and new_game_confirmation:
			get_viewport().set_input_as_handled()
			cancel_new_game()
		return
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
	for player in [music, sfx, order_sound]:
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
