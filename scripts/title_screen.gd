extends Control
## A title diorama, never a live venue. Receives display strings only.
const Art = preload("res://scripts/art.gd")
const INTRO_SECONDS = 2.6
const TITLE_SETTLED = 2.1
const INK = Color("#100f1c")
const CREAM = Color("#fff0d4")
const GOLD = Color("#ffcf83")
const MINT = Color("#8ff5d8")
const MUTED = Color("#bab6c8")

signal resume_requested
signal new_game_requested
signal confirm_requested
signal cancel_requested
signal sound_requested
signal update_requested
signal skip_requested

var clock := 0.0
var has_save := false
var confirming := false
var muted := false
var update_available := false
var campaign_summary := ""
var notice := ""
var logo: Control
var menu: Control
var splash: Button
var primary: Button
var sound_button: Button
var update_button: Button
var upper_title: Label
var lower_title: Label
var shade: GradientTexture2D
var bold: FontVariation

func _ready() -> void:
	size = Vector2(960,540)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 1.0
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,.47,.72,1])
	gradient.colors = PackedColorArray([Color("#100f1c"),Color("#100f1cf5"),Color("#100f1c45"),Color("#100f1c20")])
	shade = GradientTexture2D.new()
	shade.gradient = gradient
	shade.fill_from = Vector2.ZERO
	shade.fill_to = Vector2.RIGHT
	build_logo()
	build_menu()
	splash = Button.new()
	splash.name = "SkipIntro"
	splash.size = size
	splash.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	splash.accessibility_name = "Skip intro"
	for state in ["normal","hover","pressed","focus"]: splash.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	splash.pressed.connect(func() -> void: skip_requested.emit())
	add_child(splash)
	var hint := copy(splash,Rect2(0,486,960,28),"TAP / CLICK / PRESS A KEY TO SKIP",12,MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_time(clock)
	if is_intro(): splash.grab_focus()
	else: primary.grab_focus()

func is_intro() -> bool:
	return clock<INTRO_SECONDS and not confirming

func copy(parent: Control, rect: Rect2, value: String, font_size: int, color: Color = CREAM, heavy: bool = false) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if heavy: label.add_theme_font_override("font",bold)
	parent.add_child(label)
	return label

func style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(8)
	result.content_margin_left = 20
	result.content_margin_right = 20
	return result

func action(rect: Rect2, text: String, callback: Callable, featured: bool = false) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size",19 if featured else 15)
	button.add_theme_font_override("font",bold)
	button.add_theme_color_override("font_color",INK if featured else CREAM)
	button.add_theme_color_override("font_hover_color",INK if featured else CREAM)
	button.add_theme_color_override("font_pressed_color",INK if featured else CREAM)
	button.add_theme_color_override("font_focus_color",INK if featured else CREAM)
	button.add_theme_color_override("font_disabled_color",Color("#868494"))
	button.add_theme_stylebox_override("normal",style(MINT if featured else Color("#171725df"),MINT if featured else Color("#62555f")))
	button.add_theme_stylebox_override("hover",style(Color("#c4ffe9") if featured else Color("#33303e"),CREAM))
	button.add_theme_stylebox_override("pressed",style(Color("#73d7b9") if featured else Color("#282434"),GOLD))
	button.add_theme_stylebox_override("disabled",style(Color("#171725b0"),Color("#36313e")))
	var focus := style(Color.TRANSPARENT,GOLD,2)
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(callback)
	menu.add_child(button)
	return button

func build_logo() -> void:
	logo = Control.new()
	logo.size = Vector2(510,154)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	upper_title = copy(logo,Rect2(0,0,510,78),"PATTAYA",68,CREAM,true)
	lower_title = copy(logo,Rect2(0,76,510,68),"AFTER HOURS",52,GOLD,true)
	for label in [upper_title,lower_title]:
		label.add_theme_color_override("font_shadow_color",Color("#080913"))
		label.add_theme_constant_override("shadow_offset_y",4)
		label.add_theme_color_override("font_outline_color",Color("#db805d35"))
		label.add_theme_constant_override("outline_size",6)

func build_menu() -> void:
	menu = Control.new()
	menu.size = size
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu)
	copy(menu,Rect2(58,35,480,24),"ONE LITTLE BAR.  ONE VERY BIG NIGHT.",12,MINT,true)
	copy(menu,Rect2(58,222,490,28),"Cold drinks. Warm nights. Questionable business plans.",15,CREAM)
	if confirming:
		copy(menu,Rect2(58,270,480,28),"Start the street over?",22,GOLD,true)
		copy(menu,Rect2(58,310,460,48),"This erases your campaign and its backup.\nYour current street cannot be recovered.",15,CREAM)
		primary = action(Rect2(58,378,430,52),"Cancel",func() -> void: cancel_requested.emit(),true)
		var erase := action(Rect2(58,443,430,40),"Erase progress & start new game",func() -> void: confirm_requested.emit())
		erase.add_theme_color_override("font_color",Color("#ffa6b7"))
	else:
		copy(menu,Rect2(58,273,470,22),"YOUR STREET IS WAITING" if has_save else "FROM SIX STOOLS TO THE WHOLE STREET",12,GOLD,true)
		copy(menu,Rect2(58,300,475,25),campaign_summary if has_save else "Open the Blue Hour with Anong. Make a little trouble.",15,MUTED)
		var resume_rect := Rect2(58,343,430,58) if has_save else Rect2(58,415,205,44)
		var new_rect := Rect2(58,415,205,44) if has_save else Rect2(58,343,430,58)
		var resume := action(resume_rect,"Resume",func() -> void: resume_requested.emit(),has_save)
		resume.disabled = not has_save
		resume.tooltip_text = "Continue your saved street." if has_save else "No readable campaign saved on this device yet."
		var fresh := action(new_rect,"New Game",func() -> void: new_game_requested.emit(),not has_save)
		fresh.tooltip_text = "Start a new street. Existing progress requires confirmation before replacement."
		primary = resume if has_save else fresh
		copy(primary,Rect2(378,12,28,34),"→",24,INK)
		copy(menu,Rect2(58,474,475,22),"Your progress stays on this device.",12,MUTED)
		# A small printed welcome card gives Anong a voice without a modal.
		copy(menu,Rect2(623,432,300,22),"ANONG  /  YOUR CO-OWNER",11,MINT,true)
		copy(menu,Rect2(623,458,300,48),"“You came here to relax?\nCute. You're on ice duty.”",17,CREAM)
	sound_button = action(Rect2(824,25,108,40),"Muted" if muted else "Sound",func() -> void: sound_requested.emit())
	sound_button.tooltip_text = "Toggle music and game sounds."
	update_button = action(Rect2(702,25,108,40),"Update",func() -> void: update_requested.emit())
	update_button.visible = update_available
	var error_copy := copy(menu,Rect2(58,509,680,24),notice,12,Color("#ffa6b7"))
	error_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func update_time(value: float) -> void:
	var was_intro := is_intro()
	clock = maxf(0,value)
	if not is_instance_valid(logo): return
	var settle := smoothstep(1.1,TITLE_SETTLED,clock) if not confirming else 1.0
	logo.position = Vector2(292,155).lerp(Vector2(56,65),settle)
	logo.scale = Vector2.ONE*lerpf(1.05,1.0,settle)
	# Two gentle tube warm-ups; no repeated flashing or strobing.
	upper_title.modulate.a = lerpf(.16,1.0,smoothstep(.15,.65,clock)) if not confirming else 1.0
	lower_title.modulate.a = lerpf(.12,1.0,smoothstep(.55,1.1,clock)) if not confirming else 1.0
	menu.modulate.a = smoothstep(TITLE_SETTLED,INTRO_SECONDS,clock) if not confirming else 1.0
	menu.visible = menu.modulate.a>0
	splash.visible = is_intro()
	if was_intro and not is_intro(): primary.grab_focus()
	queue_redraw()

func _draw() -> void:
	if shade==null: return
	draw_rect(Rect2(Vector2.ZERO,size),INK)
	var reveal := smoothstep(.9,INTRO_SECONDS,clock)
	# Existing production art forms a self-contained title diorama. It reads
	# no customers, clock, ownership or RNG from the campaign behind the menu.
	Art.image(self,"beer-1",Rect2(140+6*sin(clock*.11),-12,960,570),Color(1,1,1,reveal*.86))
	draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)
	draw_rect(Rect2(0,0,960,540),Color(INK,1-reveal))
	if reveal>0:
		draw_sign(reveal)
		Art.frame(self,"anong-service",0,Vector2(796,434),1.5,false,Vector2.ZERO,Color(1,1,1,reveal),Vector2(1,1+.002*sin(clock*1.5)))
		if not confirming:
			var welcome_alpha := smoothstep(TITLE_SETTLED,INTRO_SECONDS,clock)
			draw_style_box(style(Color(Color("#10131dec"),welcome_alpha*.93),Color(Color("#59505c"),welcome_alpha)),Rect2(603,417,334,96))
	# A restrained cyan rule connects the title to its menu.
	var rule_alpha := smoothstep(TITLE_SETTLED,INTRO_SECONDS,clock)
	draw_line(Vector2(58,215),Vector2(58+430*rule_alpha,215),Color(MINT,rule_alpha*.65),1.5,true)
	if is_intro(): draw_splash_glass(1-smoothstep(1.15,1.7,clock))

func draw_sign(alpha: float) -> void:
	var origin := Vector2(763,147)
	var angle := sin(clock*.65)*.012
	draw_line(Vector2(675,57),origin+Vector2(-90,-46),Color(GOLD,alpha*.45),2,true)
	draw_line(Vector2(850,57),origin+Vector2(90,-46),Color(GOLD,alpha*.45),2,true)
	draw_set_transform(origin,angle)
	for width in [14,8,2]:
		var border := style(Color(Color("#0d1723"),alpha) if width==2 else Color.TRANSPARENT,Color(MINT,alpha*(.7 if width==2 else .035)),width)
		draw_style_box(border,Rect2(-124,-47,248,94))
	draw_string(bold,Vector2(-94,-10),"THE BLUE HOUR",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color(CREAM,alpha))
	draw_string(ThemeDB.fallback_font,Vector2(-75,20),"COLD BEER · BIG PLANS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(MINT,alpha))
	draw_set_transform(Vector2.ZERO)

func draw_splash_glass(alpha: float) -> void:
	if alpha<=0: return
	var center := Vector2(480,96)
	var fill := smoothstep(.05,.75,clock)
	for radius in [65,55,45]: draw_circle(center,radius,Color(GOLD,alpha*.025))
	draw_rect(Rect2(center+Vector2(-17,22-42*fill),Vector2(34,42*fill)),Color(GOLD,alpha*.75))
	var glass := PackedVector2Array([center+Vector2(-22,-25),center+Vector2(-18,26),center+Vector2(18,26),center+Vector2(22,-25)])
	draw_polyline(glass,Color(CREAM,alpha),3,true)
	if fill>.7:
		draw_line(center+Vector2(-20,-22),center+Vector2(20,-22),Color(CREAM,alpha),6,true)
	for i in 3:
		var bubble := fposmod(clock*.5+i*.31,1.0)
		draw_circle(center+Vector2(-10+i*10,20-bubble*37),1.5,Color(CREAM,alpha*fill*(1-bubble)))
	var twinkle := sin(clampf((clock-.65)/.6,0,1)*PI)*alpha
	for i in 4:
		var offset := Vector2.from_angle(i*PI*.5)*6
		draw_line(center+Vector2(39,-28)-offset,center+Vector2(39,-28)+offset,Color(MINT,twinkle),2,true)
