extends Control

signal destination(index: int)
signal dismissed
const TEAL = Color("#73ffdc")
const PINK = Color("#ff70b1")
const GOLD = Color("#ffcb7c")
const SITES = [
	["Blue Hour",Vector2(151,87),0,TEAL,"Anong checks payroll in the booth overlooking the bay."],
	["Toybox",Vector2(244,87),1,PINK,"Mali trains here. Match nights bring a crowd to the promenade."],
	["Market",Vector2(61,87),2,GOLD,"Fern starts the market loop at the noodle stall."],
	["Harbor",Vector2(56,48),2,Color("#bbb0ff"),"The harbor walk leaves from the covered pier."],
	["Rig loft",Vector2(145,132),3,PINK,"The loft power meter is visible from the street."],
	["High Tide",Vector2(251,132),3,TEAL,"The vacant lease has two doors and one optimistic agent."],
]
var point := Vector2(151,105)
var target := point
var clock := 0.0
var facing := 1
var focus_site := -1
var nearby := -1
var font = ThemeDB.fallback_font
var weather := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	clock += delta
	var axis := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if Input.is_physical_key_pressed(KEY_A): axis.x -= 1
	if Input.is_physical_key_pressed(KEY_D): axis.x += 1
	if Input.is_physical_key_pressed(KEY_W): axis.y -= 1
	if Input.is_physical_key_pressed(KEY_S): axis.y += 1
	if axis != Vector2.ZERO:
		target = point + axis.normalized() * 5
		focus_site = -1
	target = target.clamp(Vector2(12,47),Vector2(305,142))
	if absf(target.x-point.x) > 1:
		facing = 1 if target.x > point.x else -1
	point = point.move_toward(target,68*delta)
	nearby = -1
	for i in SITES.size():
		if point.distance_to(SITES[i][1] + Vector2(0,9)) < 13:
			nearby = i
			break
	if focus_site >= 0 and point.distance_to(target) < 1:
		destination.emit(SITES[focus_site][2])
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			dismissed.emit()
		elif (event.keycode == KEY_E or event.keycode == KEY_ENTER) and nearby >= 0:
			get_viewport().set_input_as_handled()
			destination.emit(SITES[nearby][2])
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		var hit: Vector2 = event.position / 3
		if Rect2(264,4,53,14).has_point(hit): dismissed.emit()
		elif hit.y >= 43 and hit.y < 151:
			focus_site = -1
			for i in SITES.size():
				var p: Vector2 = SITES[i][1]
				if Rect2(p-Vector2(17,12),Vector2(34,18)).has_point(hit):
					focus_site = i
					target = p+Vector2(0,9)
					break
			if focus_site < 0: target = hit

func px(x: float,y: float,w: float,h: float,color: Color) -> void:
	draw_rect(Rect2(floorf(x),floorf(y),w,h),color)

func text_at(x: float,y: float,value: String,size_px: int,tint: Color) -> void:
	draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,tint)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(3,3))
	px(0,0,320,180,Color("#110e23"))
	px(0,22,320,35,Color("#214762"))
	for i in 52:
		px(fposmod(i*37+clock*(3+i%4),320),23+(i*11)%34,4+i%14,1,Color("#36718a") if i%4 else Color("#635987"))
	px(0,56,320,104,Color("#342643"))
	px(0,56,320,4,Color("#9e677f"))
	px(32,43,52,12,Color("#6e4766"))
	for x in range(34,83,5): px(x,45,1,9,Color("#9d7581"))
	for y in [92,137]: px(0,y,320,10,Color("#69516a"))
	for y in [103,148]:
		px(0,y,320,11,Color("#24203b"))
		for x in range(1,320,12): px(x,y+5,6,1,Color("#9a6c82"))
	for x in [13,100,194,294]:
		px(x,60,9,92,Color("#51415e"))
		for y in range(60,150,11): px(x+4,y,1,5,Color("#94657c"))
	for item in SITES:
		var p: Vector2 = item[1]
		var tint: Color = item[3]
		if item[0] != "Harbor":
			px(p.x-22,p.y-20,44,21,Color("#120f24"))
			px(p.x-20,p.y-18,40,17,tint.darkened(.76))
			for x in [-16,-7,7,14]: px(p.x+x,p.y-15,5,6,tint.darkened(.48))
			px(p.x-3,p.y-5,6,8,tint.darkened(.37))
		px(p.x-18,p.y-11,36,10,Color("#130f27"))
		var w := font.get_string_size(item[0],HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
		text_at(p.x-w/2,p.y-4,item[0],7,tint)
	for i in 9:
		var x := fposmod(i*49+clock*(16+i%4*4),335)-8
		var y := 105 + (i%2)*45
		px(x,y,7 if i%3 else 14,4,[PINK,TEAL,GOLD][i%3].darkened(.4))
		px(x+2,y-2,3 if i%3 else 6,2,[PINK,TEAL,GOLD][i%3])
		px(x,y+3,3,2,Color("#120e23"))
		px(x+(4 if i%3 else 11),y+3,3,2,Color("#120e23"))
	for i in 14:
		var x := fposmod(i*71+clock*(3+i%4),320)
		var y := 97 + (i%2)*46
		px(x,y-4,2,2,Color("#e2a881"))
		px(x-1,y-2,4,3,[PINK,TEAL,GOLD][i%3].darkened(.37))
	px(point.x-4,point.y-8,9,10,Color("#151127"))
	px(point.x-2,point.y-8,5,3,GOLD)
	px(point.x-3,point.y-5,7,4,TEAL)
	px(point.x+facing*2,point.y-8,2,3,Color("#faf0d2"))
	px(point.x-2,point.y-1,2,3,Color("#b7aeff"))
	px(point.x+2,point.y-1,2,3,Color("#b7aeff"))
	if weather >= 5:
		for i in 62:
			var rain := Vector2(fposmod(i*67-clock*28,320),fposmod(i*i*19+clock*130,138)+22)
			draw_line(rain,rain+Vector2(-3,6),Color("#a2bfda7d"))
	text_at(9,11,"BAY DISTRICT / WALK THE BLOCK",10,TEAL)
	text_at(9,19,"Tap to walk or use WASD. Tap a place to visit it.",6,Color("#e7d0ed"))
	px(264,4,53,14,Color("#3b2750"))
	text_at(274,14,"BACK  [ESC]",7,GOLD)
	var footer := "Promenade runs from the market to Toybox. The harbor is across the road."
	if nearby >= 0: footer = SITES[nearby][4] + "  [E]"
	text_at(9,170,footer,8,GOLD)
