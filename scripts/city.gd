extends Control

const INK = Color("#140e26")
const TEAL = Color("#65ffd5")
const PINK = Color("#ff63ae")
const GOLD = Color("#ffd075")
const LABELS = [["BLUE HOUR",Vector2(123,103),TEAL,0],["TOYBOX",Vector2(211,84),PINK,1],
	["MARKET",Vector2(56,120),GOLD,2],["HIGH TIDE",Vector2(233,166),TEAL,3],
	["HARBOR",Vector2(37,72),Color("#adabff"),2],["RIG",Vector2(118,162),PINK,3]]
var clock := 0.0
var night := false
var godzilla := ""
var shot_flash := 0.0
var weather := 0
var guests := 0
var level := 1
var venue := 1
var rig := 0
var last_frame := -1
var font = ThemeDB.fallback_font
var placement: Array = []
signal site(tab: int)

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 82:
		placement.append(Vector2((i * 73 + i * i * 11) % 272, (i * 19 + i * i * 5) % 170))

func _process(delta: float) -> void:
	clock += delta
	var frame := int(clock * 22.0)
	if frame != last_frame:
		last_frame = frame
		queue_redraw()

func _gui_input(input: InputEvent) -> void:
	if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = input.position / (size / Vector2(278,188))
		for item in LABELS:
			var p: Vector2 = item[1]
			if Rect2(p - Vector2(28,8), Vector2(56,16)).has_point(point):
				accept_event()
				site.emit(item[3])
				return

func px(x: float,y: float,w: float,h: float,col: Color) -> void:
	draw_rect(Rect2(floorf(x),floorf(y),w,h),col)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size / Vector2(278,188))
	var dusk := Color("#250f45") if night else Color("#342048")
	for i in 38:
		px(0,i * 3,278,3,dusk.lerp(Color("#9c2f5c") if night else Color("#de735f"),i / 55.0))
	for i in 35:
		var p: Vector2 = placement[i]
		px(p.x,p.y / 3,1 + int(i % 8 == 0),1,Color("#f8c8b5") * Color(1,1,1,0.35 + (i % 5) / 10.0))
	draw_circle(Vector2(235,29),15,Color("#f797aa") if night else Color("#ffbd73"),true,-1,false)
	for i in 5:
		px(218,29 + i * 3,34,1,dusk.lerp(Color("#b63d75"),0.35))
	for i in 31:
		var x := i * 10 - 3
		var h := 8 + (i * 51 + i * i * 13) % 37
		px(x,70-h,8,h,Color("#372044"))
		px(x + 2,67-h,4,4,Color("#493053"))
		for y in range(74-h,68,5):
			if (x+y) % 4 != 0: px(x+2,y,1,2,Color("#a35e7b"))
			if (x+y) % 3 != 0: px(x+5,y,1,2,Color("#775075"))
	px(0,66,278,55,Color("#173454").lerp(Color("#233967"),0.4 if night else 0.8))
	for i in 46:
		var p: Vector2 = placement[i]
		var wave := int(p.x + clock * (3 + i % 3)) % 278
		px(wave,67 + int(p.y) % 51,3 + i % 15,1,Color("#285474") if i % 4 != 0 else Color("#635580"))
	px(0,119,278,69,Color("#211735"))
	px(0,118,278,3,Color("#5a4269"))
	px(8,88,65,5,Color("#493758"))
	px(28,79,21,8,Color("#db9b8e"))
	px(20,85,39,3,Color("#713b66"))
	px(36,73,3,7,Color("#eda4a6"))
	_palm(9,121)
	_palm(74,119)
	_palm(269,121)
	_building(80,59,78,66,true,TEAL,5)
	_building(169,51,82,74,false,PINK,2)
	_building(17,100,50,25,false,GOLD,3)
	px(0,129,278,8,Color("#59445e"))
	px(0,131,278,2,Color("#a16d79"))
	px(0,137,278,22,Color("#302742"))
	px(0,139,278,1,Color("#785371"))
	px(0,157,278,2,Color("#59405f"))
	for x in range(0,278,12): px(x,148,6,1,Color("#93738a"))
	for i in range(0 if godzilla in ["attack","scared"] else 5 + mini(15,guests / 8)):
		var x := fposmod(float(i * 57) + (10.0 if i % 2 else -9.0) * clock,278.0)
		_person(x,136 + i % 2, i, i % 2)
	for i in 8:
		var x := fposmod(31.0 + float(i * 47) + (1.0 if i % 2 else -1.0) * clock * (14.0 + (i % 3) * 5),296.0)-9.0
		_traffic(x,144 + (i % 2) * 10,i)
	_building(186,164,82,32,false,TEAL.darkened(0.30) if venue == 1 else TEAL,4)
	_building(88,162,58,29,true,PINK.darkened(0.28) if rig == 0 else PINK,7)
	_palm(55,188)
	_palm(165,184)
	if level > 1:
		px(89,55,62,4,TEAL.darkened(.5))
		for i in level - 1: px(141-i*7,52,4,3,GOLD)
	if godzilla in ["attack","asleep"]: _draw_godzilla()
	for item in LABELS:
		var position_on_map: Vector2 = Vector2(117,54) if godzilla == "attack" and item[3] == 0 else item[1]
		_sign(item[0],position_on_map,item[2])
	if weather >= 5:
		for i in 56:
			var p: Vector2 = placement[i]
			var rain := Vector2(fposmod(p.x - clock * 25,278),fposmod(p.y + clock * 129,188))
			draw_line(rain,rain+Vector2(-2,5 + int(weather == 6) * 2),Color("#81bad27d"),1)
		if weather == 6:
			for i in 8: px(9+i*35,155+i%3,17+i%4*2,1,Color("#618bc6"))

func _sign(value: String, p: Vector2, tint: Color) -> void:
	var width := int(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x) + 8
	px(p.x - width/2.0,p.y-7,width,11,INK)
	px(p.x - width/2.0,p.y+4,width,1,tint.darkened(.35))
	draw_string(font,Vector2(int(p.x-width/2.0)+4,int(p.y)+1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,7,tint)

func _building(x: int,y: int,w: int,h: int,cutaway: bool,neon: Color,style: int) -> void:
	px(x-2,y,w+4,h,INK)
	px(x,y+3,w,h,Color("#4d2a52"))
	px(x-3,y,w+6,4,Color("#765574"))
	px(x-3,y+3,w+6,1,neon.darkened(.45))
	px(x+w-4,y+5,4,h-5,Color("#2d1b39"))
	for row in range(y+7,y+h-7,17):
		px(x+2,row,w-8,13,Color("#271c37"))
		px(x+2,row+13,w-8,2,Color("#92617e"))
		for col in range(x+6,x+w-12,10):
			if cutaway:
				px(col,row+3,6,2,neon.darkened(.48))
				px(col+1,row+8,6,2,Color("#bd7a6b"))
				px(col+2,row+9,1,4,Color("#90576c"))
				if (col+row+style)%3 != 0: _person(col+5,row+12,col+row,false)
			else:
				var lit := (col*11+row*15+style) % 8
				px(col,row+2,7,8,Color("#1c152b"))
				if lit > 1:
					var glass := Color("#e49771") if lit > 4 else neon.darkened(.45)
					px(col+1,row+3,2,6,glass)
					px(col+4,row+3,2,6,glass.darkened(.23))
	px(x+w/2-3,y+h-8,6,8,Color("#22162c"))
	px(x+w/2-2,y+h-8,4,1,neon)

func _palm(x: int,y: int) -> void:
	for i in 15: px(x + i / 7.0,y-i,2,1,Color("#79576b"))
	for k in range(-9,10):
		var yy := y-17 + absi(k)/3
		px(x+k,yy,1,2,Color("#2d766d"))
		px(x+k,yy+5,1,1,Color("#28575f"))

func _person(x: float,y: float,i: int,walking: bool) -> void:
	var skin: Color = [Color("#e9a087"),Color("#bd796d"),Color("#efbf93")][i%3]
	var coat: Color = [TEAL,PINK,GOLD,Color("#a999ff")][i%4]
	var step := int(clock*9+i)%2 if walking else 0
	px(x-1,y-7,3,2,skin)
	px(x-1,y-5,3,3,coat.darkened(.15))
	px(x-1-step,y-2,1,2,Color("#ac87ae"))
	px(x+1+step,y-2,1,2,Color("#ac87ae"))

func _traffic(x: float,y: float,i: int) -> void:
	var coat: Color = [PINK,TEAL,Color("#9889df"),GOLD][i%4]
	var pickup := i % 3 == 0
	var w := 16 if pickup else 8
	px(x-1,y+2,w+2,2,INK)
	px(x,y,w,3,coat.darkened(.22))
	px(x+1,y-3,7 if pickup else 3,3,coat)
	if pickup: px(x+3,y-2,4,2,Color("#45375e"))
	px(x+1,y+2,2,2,INK)
	px(x+w-4,y+2,2,2,INK)
	px(x+w-1,y+1,1,1,Color("#fff3a6"))


func _kaiju_shape(coords: Array, color: Color, lift: int = 0) -> void:
	var polygon := PackedVector2Array()
	for i in range(0,coords.size(),2):
		polygon.append(Vector2(coords[i],coords[i+1]+lift))
	draw_colored_polygon(polygon,color)

func _scale_marks(coords: Array, color: Color, lift: int = 0) -> void:
	for i in range(0,coords.size(),2):
		px(coords[i],coords[i+1]+lift,2,1,color)
		px(coords[i]+2,coords[i+1]+lift+1,1,1,color)

func _draw_godzilla() -> void:
	var outline := Color("#141322")
	var scales := Color("#386b68")
	var shadow := Color("#253a48")
	var light := Color("#6fae91")
	var glint := Color("#aecead")
	var teeth := Color("#efdfb8")
	var spine := Color("#7055a8")
	var glow := Color("#9bb0f0").lerp(Color("#ffd1fb"),shot_flash)
	if godzilla == "asleep":
		_draw_godzilla_asleep(outline,scales,shadow,light,teeth,spine,glow)
		return

	var lift := int(sin(clock*3.4)*1.5)
	px(88,147,72,4,Color("#231930"))
	_kaiju_shape([67,140,78,129,93,133,102,120,95,113,102,105,96,96,106,98,102,87,111,91,111,77,121,83,125,75,124,65,131,60,146,61,154,67,163,69,168,73,166,80,158,85,151,84,148,96,156,96,162,101,160,107,151,109,146,105,150,126,148,140,158,143,161,149,156,151,137,151,130,143,124,151,101,151,99,145,108,139,108,131,99,142,90,146,78,144],outline,lift)
	_kaiju_shape([72,140,80,133,93,136,105,125,105,115,112,103,108,92,117,99,117,83,124,89,128,76,127,67,134,63,145,64,152,70,161,72,165,74,163,79,151,82,146,96,155,99,158,103,155,106,149,105,143,101,141,112,147,128,144,141,154,145,156,148,139,148,132,136,127,129,121,145,118,148,104,148,112,142,113,126,105,135,98,140,90,143,79,141],scales,lift)
	# Reflected neon along the tail, shoulder and exposed thigh.
	_kaiju_shape([74,139,81,135,95,138,108,126,105,134,96,141,88,143,81,141],Color("#518584"),lift)
	_kaiju_shape([121,98,128,90,137,90,142,98,140,112,144,123,140,133,136,136,129,128,128,118,122,110],shadow,lift)
	_kaiju_shape([127,90,135,88,142,93,143,101,139,108,136,117,129,115,125,105],Color("#547c68"),lift)
	_kaiju_shape([109,126,114,118,121,115,128,119,130,126,125,136,122,146,117,148,109,147,114,142,116,132],Color("#294c55"),lift)
	_kaiju_shape([110,125,115,119,121,117,126,119,128,123,123,125,119,124,115,129,113,136,111,135],light,lift)
	# Segmented dorsal plates catch the blue light along their ridges.
	_kaiju_shape([98,122,100,114,97,111,105,112,108,105,108,111,113,109,109,118,104,123],spine,lift)
	_kaiju_shape([98,113,106,114,109,111,107,118,102,120],glow,lift)
	_kaiju_shape([103,108,103,101,98,97,107,100,109,93,113,100,118,96,116,105,110,112],spine,lift)
	_kaiju_shape([103,100,108,103,110,97,112,104,117,100,111,108,107,109],glow,lift)
	_kaiju_shape([110,100,112,91,105,87,113,91,113,79,118,85,122,83,123,78,126,86,123,95,117,103],spine,lift)
	_kaiju_shape([114,82,116,88,120,87,123,83,124,89,119,98,117,94],glow,lift)
	_kaiju_shape([87,136,90,131,93,135,97,134,95,139],spine,lift)
	_kaiju_shape([95,132,98,126,101,130,103,127,101,134],spine,lift)
	# Brow, snout, split jaw and the hand reaching for the glass.
	_kaiju_shape([129,69,135,64,144,65,150,68,151,72,158,72,164,74,158,76,150,75,144,71,137,69,130,73],light,lift)
	_kaiju_shape([128,72,135,70,139,72,146,73,150,76,147,81,143,84,136,82,130,78],Color("#458579"),lift)
	px(141,70+lift,7,1,outline)
	if fposmod(clock+0.8,4.2) >= 0.13:
		px(144,71+lift,4,2,Color("#ffad68"))
		px(146,71+lift,1,1,Color("#fff0c0"))
	px(161,73+lift,2,1,shadow)
	_kaiju_shape([147,77,154,77,159,76,164,77,160,82,154,83,147,81],outline,lift)
	px(150,80+lift,9,1,Color("#9a5171"))
	for x in [150,154,158,161]:
		px(x,77+lift,2,1,teeth)
	px(156,81+lift,2,1,teeth.darkened(0.25))
	px(138,82+lift,6,2,shadow)
	px(138,85+lift,4,1,light)
	_kaiju_shape([132,94,139,94,146,98,154,99,157,102,153,105,146,103,140,101,135,102],light,lift)
	px(151,100+lift,5,1,glint)
	for x in [151,154,157]:
		px(x,103+lift,1,2,teeth)
	for x in [105,109,113,145,149,153]:
		px(x,147+lift,2,1,teeth)
	_scale_marks([81,137,88,138,97,135,104,128,111,115,116,108,120,102,126,96,130,103,128,109,120,122,117,128,140,121,142,128,140,136,134,83,134,77,139,75],Color("#629286"),lift)
	_scale_marks([111,113,117,112,123,106,123,113,125,117,118,134,115,139,136,126,138,131,136,136,139,141,92,139,105,133,137,78,132,75],shadow,lift)
	if shot_flash > 0.15:
		var rise := int((1.0-shot_flash)*19)
		px(166+rise,72-rise,2,2,Color("#f9bc80"))
		px(169+rise,77-rise,2,2,Color("#ff80b2"))
		px(164+rise,68-rise,1,1,Color("#ffe4aa"))

func _draw_godzilla_asleep(outline: Color, scales: Color, shadow: Color, light: Color, teeth: Color, spine: Color, glow: Color) -> void:
	var breath := -int(sin(clock*1.9)>0.50)
	px(78,148,96,4,Color("#20182c"))
	_kaiju_shape([72,145,82,137,93,138,102,135,109,128,116,126,119,120,125,123,128,115,135,121,139,118,143,127,149,129,152,134,161,134,167,136,174,140,176,146,171,150,155,151,113,151,101,147,90,149,80,147],outline)
	_kaiju_shape([77,144,84,139,95,140,104,137,112,130,118,128,123,127,129,119,135,124,139,121,142,129,149,132,151,136,160,136,166,138,172,141,173,145,170,148,150,149,116,149,103,145,90,147,83,145],scales)
	_kaiju_shape([82,144,88,142,96,143,107,140,111,137,116,138,108,145,101,144,91,146],light)
	_kaiju_shape([106,143,112,136,120,134,130,135,135,140,132,144,128,148,115,149,111,146],shadow)
	_kaiju_shape([114,138,120,135,129,136,132,139,129,141,122,140,119,144,114,144],Color("#4e8173"),breath)
	_kaiju_shape([111,132,115,128,119,122,120,127,124,126,129,117,135,125,140,121,142,129,147,133,137,131,130,132,124,131,119,134],spine,breath)
	_kaiju_shape([115,129,119,124,120,129,126,128,129,119,134,127,139,123,140,130,132,129,127,131,120,131],glow.darkened(0.23),breath)
	_kaiju_shape([140,138,146,135,151,135,158,136,164,137,171,141,170,143,157,142,153,143,145,143],Color("#548b78"))
	px(153,138,6,1,light)
	px(154,140,5,1,outline)
	px(153,139,1,1,outline)
	px(168,141,2,1,shadow)
	px(159,145,13,1,outline)
	px(161,146,6,1,Color("#8e5a75"))
	px(167,145,2,1,teeth)
	px(141,144,13,2,shadow)
	px(140,146,11,2,Color("#527d74"))
	for x in [137,140,143]:
		px(x,147,2,1,teeth)
	_scale_marks([89,144,96,141,106,139,114,134,124,137,121,142,129,143,133,138,138,135,145,138,150,139,165,139],Color("#75a18b"))
	_scale_marks([86,145,97,144,111,144,116,146,125,145,134,144,136,138,145,142,151,142,164,143],shadow)
	var zz := int(clock * 6.0) % 14
	draw_string(font,Vector2(169+zz,132-zz),"Z",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("#d0c0f1"))
	if zz >= 5:
		draw_string(font,Vector2(163+zz,139-zz),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("#9e8cca"))
