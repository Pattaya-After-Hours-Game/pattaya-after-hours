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
		_sign(item[0],item[1],item[2])
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

func _draw_godzilla() -> void:
	var outline := Color("#151625")
	var scales := Color("#36656a")
	var shadow := Color("#233949")
	var gleam := Color("#628e82")
	var spine := Color("#a28cda")
	var teeth := Color("#e7d8a2")
	if godzilla == "asleep":
		px(79,148,91,4,outline)
		_kaiju_shape([78,147,85,139,98,139,106,128,116,125,119,120,126,123,131,118,136,125,142,126,149,135,160,136,170,142,170,149,115,151,99,147],outline)
		_kaiju_shape([82,146,91,141,103,142,111,130,125,128,130,122,134,129,142,129,150,137,161,138,168,143,166,147,121,148,111,145,99,146],scales)
		_kaiju_shape([104,143,111,137,127,137,133,141,151,144,166,144,166,148,120,148],shadow)
		_kaiju_shape([111,129,115,126,119,122,121,127,126,127,131,120,134,128,141,129,145,135,137,131,126,132],spine)
		px(155,140,7,1,outline)
		px(160,145,7,1,outline)
		px(163,146,2,1,teeth)
		px(113,145,11,3,shadow)
		px(117,148,7,1,gleam)
		var zz := int(clock * 5.0) % 9
		draw_string(font,Vector2(161+zz,130-zz),"Z",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("#beafe7"))
		return

	var lift := int(sin(clock*3.4)*1.5)
	px(87,146,69,5,outline)
	_kaiju_shape([70,142,78,130,94,133,101,121,96,115,101,106,96,98,105,99,103,87,111,92,112,79,121,84,124,76,124,65,131,60,148,62,155,69,165,70,165,80,156,85,150,84,148,96,157,99,158,106,149,108,145,105,149,129,147,141,157,144,157,150,137,150,130,142,124,150,102,150,100,145,108,141,107,133,99,143,90,146,79,142],outline,lift)
	_kaiju_shape([74,140,80,133,94,136,106,125,104,113,111,99,108,90,115,95,117,84,125,89,127,76,127,67,133,63,146,65,154,72,163,73,162,79,151,82,146,96,154,101,154,104,147,105,143,101,141,111,146,129,142,141,153,145,152,147,139,147,132,137,127,129,122,144,120,147,105,147,113,143,114,127,106,134,98,141,90,144,79,139],scales,lift)
	_kaiju_shape([126,84,132,82,141,86,144,92,140,113,144,126,138,139,132,137,128,127,122,117,121,106],shadow,lift)
	_kaiju_shape([102,120,100,114,107,104,101,101,109,103,106,92,115,98,115,83,123,90,125,80,129,87,124,100,115,111],spine,lift)
	_kaiju_shape([130,66,140,65,147,67,151,73,145,72,142,70,131,72],gleam,lift)
	px(145,71+lift,4,2,Color("#ff9168"))
	px(148,71+lift,1,1,outline)
	px(149,76+lift,14,3,outline)
	for x in [152,156,160]: px(x,76+lift,2,1,teeth)
	px(134,97+lift,9,3,gleam)
	px(150,102+lift,3,2,teeth)
	px(109,145+lift,7,2,teeth)
	px(145,145+lift,7,2,teeth)
	for i in 12:
		px(115+(i*17)%27,105+(i*11)%31+lift,2,1,gleam if i%3 == 0 else shadow)
	if shot_flash > 0.15:
		var rise := int((1.0-shot_flash)*19)
		px(166+rise,72-rise,2,2,Color("#f9bc80"))
		px(169+rise,77-rise,2,2,Color("#ff80b2"))
		px(164+rise,68-rise,1,1,Color("#ffe4aa"))
