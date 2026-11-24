extends Control

signal finished(won: bool)
signal sound(kind: String)
const FLOOR = 126.0
const ATTACKS = {
	"jab": [0.105,0.065,0.18,26,8,6.0],
	"kick":[0.20,0.09,0.29,39,15,13.0],
	"super":[0.24,0.14,0.36,52,29,22.0],
}
const RIVALS = [["JUNO",Color("#ab8bfa"),Color("#ef947b"),0.39],["VEGA",Color("#ff6a93"),Color("#c88570"),0.30],["ORCHID",Color("#ffc474"),Color("#cda086"),0.25]]
const BUTTONS = [["left","◀",22],["right","▶",98],["jump","JUMP",174],["guard","GUARD",250],
	["jab","JAB",636],["kick","KICK",712],["super","BURST",788]]
const KEYS = {KEY_A:"left", KEY_LEFT:"left", KEY_D:"right", KEY_RIGHT:"right", KEY_W:"jump", KEY_UP:"jump",
	KEY_S:"guard", KEY_DOWN:"guard", KEY_J:"jab", KEY_K:"kick", KEY_L:"super"}
var fighters: Array[Dictionary] = []
var wins := [0,0]
var rival_index := 0
var circuit := false
var time_left := 45.0
var countdown := 1.4
var next_round := 0.0
var ai_timer := 0.5
var ai_guard := 0.0
var elapsed := 0.0
var over := false
var result := false
var announced := ""
var held := {}
var touches := {}
var mouse_action := ""
var sparks: Array[Dictionary] = []
var flash := 0.0
var buffered := {}
var rng := RandomNumberGenerator.new()
var font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	reset_round()

func reset_round() -> void:
	fighters = []
	for x in [88.0,232.0]:
		fighters.append({"x":x,"y":FLOOR,"vy":0.0,"hp":100,"meter":0,"facing":1 if x < 100 else -1,
			"move":"","timer":0.0,"hit":false,"stun":0.0,"guard":false,"motion":0})
	time_left = 45.0
	countdown = 1.4
	next_round = 0.0
	ai_timer = 0.42
	ai_guard = 0
	announced = ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		held.clear()
		touches.clear()
		mouse_action = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and KEYS.has(event.physical_keycode):
		if event.echo: return
		var key: String = KEYS[event.physical_keycode]
		if event.pressed:
			buffer(key)
			held[event.physical_keycode] = key
			if over and key == "jab": finished.emit(result)
		else:
			held.erase(event.physical_keycode)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		finished.emit(result if over else false)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			activate(event.position,event.index)
		else: touches.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if touches.has(event.index):
			touches[event.index] = action_at(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		mouse_action = action_at(event.position) if event.pressed else ""
		if event.pressed:
			buffer(mouse_action)
			activate(event.position,-1)
		get_viewport().set_input_as_handled()

func activate(point: Vector2, index: int) -> void:
	if Rect2(880,465,72,61).has_point(point):
		finished.emit(result if over else false)
	elif over:
		if Rect2(345,281,270,82).has_point(point): finished.emit(result)
	elif index != -1:
		touches[index] = action_at(point)
		buffer(touches[index])

func action_at(point: Vector2) -> String:
	for item in BUTTONS:
		if Rect2(item[2],464,68,60).has_point(point): return item[0]
	return ""

func buffer(key: String) -> void:
	if key in ["jab","kick","super","jump"]:
		buffered[key] = elapsed + 0.17

func pressed(key: String) -> bool:
	return float(buffered.get(key,-1.0)) >= elapsed or mouse_action == key or key in held.values() or key in touches.values()

func _physics_process(delta: float) -> void:
	elapsed += delta
	flash = maxf(0,flash-delta)
	for i in range(sparks.size()-1,-1,-1):
		sparks[i].life -= delta
		sparks[i].p += sparks[i].v * delta
		if sparks[i].life <= 0: sparks.remove_at(i)
	queue_redraw()
	if over: return
	if next_round > 0:
		next_round -= delta
		if next_round <= 0:
			if wins[0] >= 2 or wins[1] >= 2:
				if circuit and wins[0] >= 2 and rival_index < RIVALS.size() - 1:
					rival_index += 1
					wins = [0,0]
					reset_round()
				else:
					over = true
					result = wins[0] > wins[1]
			else:
				reset_round()
		return
	if countdown > 0:
		countdown -= delta
		return
	time_left = maxf(0,time_left-delta)
	var me := fighters[0]
	var cpu := fighters[1]
	var distance := absf(me.x - cpu.x)
	me.facing = 1 if me.x < cpu.x else -1
	cpu.facing = -me.facing
	me.guard = pressed("guard") and me.y == FLOOR
	var move := int(pressed("right")) - int(pressed("left"))
	_walk(me,move,delta)
	if pressed("jump"):
		_jump(me)
		buffered.erase("jump")
	for action in ["super","kick","jab"]:
		if pressed(action) and _attack(me,action):
			buffered.erase(action)
			break
	ai_timer -= delta
	ai_guard -= delta
	cpu.guard = ai_guard > 0 and cpu.y == FLOOR
	var ai_move := int(cpu.facing) if distance > 31 else -int(cpu.facing) if distance < 16 else 0
	_walk(cpu,ai_move,delta * (0.75 + rival_index * 0.11))
	if ai_timer <= 0:
		ai_timer = float(RIVALS[rival_index][3]) + rng.randf_range(0.07,0.35)
		var chance := rng.randf()
		if distance > 46 and chance < [0.10,0.60,0.27][rival_index]:
			_jump(cpu)
		elif distance < 44 and (chance < [0.32,0.13,0.21][rival_index] or (me.move == "super" and chance < 0.7)):
			ai_guard = [0.54,0.29,0.38][rival_index]
		elif distance < 52:
			var likes_kicks: bool = chance > [0.71,0.49,0.24][rival_index]
			_attack(cpu,"super" if cpu.meter >= 100 else "kick" if (distance > 24 or likes_kicks) else "jab")
	_resolve(me,cpu,delta)
	_resolve(cpu,me,delta)
	if absf(me.x-cpu.x) < 15 and absf(me.y-cpu.y) < 13:
		var middle: float = clampf((me.x+cpu.x)/2,23,297)
		me.x = middle - me.facing * 7.5
		cpu.x = middle - cpu.facing * 7.5
	if me.hp <= 0 or cpu.hp <= 0 or time_left <= 0:
		if me.hp == cpu.hp:
			wins[0] += 1
			wins[1] += 1
			if wins[0] == wins[1] and wins[0] >= 2:
				wins[0] = 1
				wins[1] = 1
			announced = "DRAW"
		else:
			wins[0 if me.hp > cpu.hp else 1] += 1
			announced = "TIME" if time_left <= 0 else "K.O."
		sound.emit("gong")
		next_round = 1.65

func _walk(f: Dictionary,dir: int,delta: float) -> void:
	f.motion = 0
	if f.stun > 0 or not f.move.is_empty() or f.guard: return
	f.motion = dir
	f.x = clampf(f.x + dir*91*delta,12,308)

func _jump(f: Dictionary) -> void:
	if f.y == FLOOR and f.stun <= 0 and f.move.is_empty() and not f.guard:
		f.vy = -165

func _attack(f: Dictionary,action: String) -> bool:
	if f.stun > 0 or f.guard or not f.move.is_empty(): return false
	if action == "super":
		if f.meter < 100: return false
		f.meter = 0
	f.move = action
	f.timer = 0.0
	f.hit = false
	return true

func _resolve(f: Dictionary,other: Dictionary,delta: float) -> void:
	if f.vy != 0 or f.y < FLOOR:
		f.y = minf(FLOOR,f.y + f.vy*delta)
		f.vy += 445*delta
		if f.y == FLOOR: f.vy = 0
	f.stun = maxf(0,f.stun-delta)
	if f.move.is_empty(): return
	var timing: Array = ATTACKS[f.move]
	f.timer += delta
	if f.timer >= timing[0] and f.timer < timing[0]+timing[1] and not f.hit:
		var gap: float = (other.x-f.x)*f.facing
		if gap >= -6 and gap < timing[3] and absf(f.y-other.y) < 25:
			f.hit = true
			var blocked: bool = other.guard and other.facing == -f.facing
			var damage: int = maxi(1,int(timing[4] / 5.0)) if blocked else timing[4]
			other.hp = maxi(0, other.hp-damage)
			other.x = clampf(other.x + f.facing * timing[5] * (0.4 if blocked else 1.0),12,308)
			other.stun = 0.09 if blocked else 0.20
			if not blocked: other.move = ""
			f.meter = mini(100,f.meter + (11 if blocked else 19))
			other.meter = mini(100,other.meter + (12 if blocked else 8))
			flash = 0.11
			sound.emit("block" if blocked else "impact")
			for i in 10:
				sparks.append({"p":Vector2(other.x,other.y-24),"v":Vector2(rng.randf_range(-77,77),rng.randf_range(-72,39)),
					"life":rng.randf_range(0.13,0.39),"color":Color("#75ffed") if blocked else Color("#ffcb79")})
	if f.timer >= timing[0]+timing[1]+timing[2]: f.move = ""

func p(x: float,y: float,w: float,h: float,tint: Color) -> void:
	draw_rect(Rect2(floorf(x),floorf(y),w,h),tint)

func label_at(x: float,y: float,value: String,px: int,tint: Color) -> void:
	draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func centered(x: float,y: float,value: String,px: int,tint: Color) -> void:
	var w := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	label_at(x-w/2,y,value,px,tint)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(3,3))
	var neon := Color("#65ffd5")
	var gold := Color("#ffce77")
	var pink: Color = RIVALS[rival_index][1]
	p(0,0,320,180,Color("#100e23"))
	for row in 26: p(0,24+row*4,320,4,Color("#2b1647").lerp(Color("#753151"),row/28.0))
	for i in 19:
		var x := i*19
		var h := 16 + (i*51)%37
		p(x,100-h,14,h,Color("#342044"))
		for y in range(102-h,98,6):
			if (i+y)%4: p(x+3,y,2,2,Color("#9c5377"))
	p(0,98,320,38,Color("#372641"))
	p(0,101,320,2,Color("#ff6299"))
	p(0,112,320,2,Color("#db8294"))
	for x in range(5,319,19):
		p(x,96,2,34,Color("#918099"))
		p(x-1,95,4,2,gold)
	for i in 27:
		var x := i*13-4
		var y := 99+(i*11)%9 + int(sin(elapsed*2.0+i)*2)
		p(x,y-6,4,5,Color("#c08083").darkened((i%3)*0.15))
		p(x-2,y-1,8,9,[Color("#2c243f"),Color("#463058"),Color("#752d62")][i%3])
	p(0,127,320,25,Color("#302742"))
	for y in [132,141,149]: p(0,y,320,1,Color("#5c3b60"))
	for x in range(-40,390,31):
		draw_line(Vector2((x+160)/2,127),Vector2(x,152),Color("#594164"))
	centered(160,69,"T O Y B O X",15,pink.darkened(.17))
	centered(160,82,"CIRCUIT · MATCH %d / %d" % [rival_index+1,RIVALS.size()] if circuit else "AFTER HOURS CIRCUIT",6,gold)
	if fighters.size() == 2:
		_sprite(fighters[0],neon,Color("#d99c73"),0)
		_sprite(fighters[1],pink,RIVALS[rival_index][2],1+rival_index)
		for spark in sparks:
			p(spark.p.x,spark.p.y,2,2,spark.color)
		if flash > 0: p(0,25,320,123,Color(1,.56,.68,flash*.24))
		p(9,16,129,7,Color("#503050"))
		p(182,16,129,7,Color("#503050"))
		p(9,16,int(fighters[0].hp*1.29),7,neon)
		var right := int(fighters[1].hp*1.29)
		p(311-right,16,right,7,pink)
		p(9,26,int(fighters[0].meter*1.29),2,gold)
		p(311-int(fighters[1].meter*1.29),26,int(fighters[1].meter*1.29),2,gold)
	label_at(9,12,"MALI  •  %d" % wins[0],8,neon)
	var rival_label := "%d  •  %s" % [wins[1],RIVALS[rival_index][0]]
	centered(286,12,rival_label,8,pink)
	centered(160,24,"%02d" % ceili(time_left),15,gold)
	p(0,152,320,28,Color("#151126"))
	for item in BUTTONS:
		var x: float = item[2]/3.0
		p(x,154,22,20,neon if pressed(item[0]) else Color("#38294b"))
		p(x+1,155,20,18,Color("#211835"))
		centered(x+11,167,item[1],6,gold if item[0] == "super" else neon)
	p(294,154,23,20,Color("#3c2545"))
	centered(305,167,"EXIT",6,pink)
	if countdown > 0:
		centered(160,109,"READY" if countdown > 0.4 else "FIGHT!",18,gold)
	elif next_round > 0:
		centered(160,100,announced,25,gold)
	elif over:
		p(80,68,160,59,Color("#120e24f4"))
		centered(160,87,("TOYBOX CHAMPION" if circuit else "MALI WINS") if result else "CORNER CALLED IT",14,neon if result else pink)
		p(115,94,90,24,Color("#39274e"))
		centered(160,109,"CONTINUE",9,gold)
	elif elapsed < 5 and not OS.has_feature("mobile"):
		centered(160,146,"A/D MOVE  W JUMP  S GUARD  J/K/L ATTACK",6,Color("#dbc5df"))

func _sprite(f: Dictionary,coat: Color,skin: Color,style: int) -> void:
	var cx := int(f.x)
	var cy := int(f.y)
	p(cx-12,FLOOR,24,3,Color("#20162d"))
	var flip: int = f.facing
	var bob := int(elapsed*9)%2 if not f.motion else int(elapsed*15)%3
	var cy0 := cy - bob + (2 if f.guard else 0)
	var dark := coat.darkened(.54)
	var light := coat.lightened(.36)
	var ink := Color("#161224")
	var arm := 0
	if f.move == "jab" or f.move == "super": arm = 7 if f.timer > 0.09 else -2
	var kick := 13 if f.move == "kick" and f.timer > 0.17 else 0
	var stance := int(sin(elapsed*19)*3) if f.motion else 0
	_piece(cx,cy0,flip,-8,-43,15,12,ink)
	_piece(cx,cy0,flip,-7,-42,13,10,skin.darkened(.24))
	_piece(cx,cy0,flip,-3,-40,10,8,skin)
	_piece(cx,cy0,flip,4,-39,2,1,ink)
	_piece(cx,cy0,flip,-8,-45,13,4,ink if style != 2 else Color("#b97d51"))
	_piece(cx,cy0,flip,-10,-41,5,11 + style,ink)
	_piece(cx,cy0,flip,-5,-33,11,3,skin)
	_piece(cx,cy0,flip,-8,-30,16,15,dark)
	_piece(cx,cy0,flip,-5,-30,11,12,coat)
	_piece(cx,cy0,flip,-4,-28,8,2,light)
	_piece(cx,cy0,flip,-8,-17,16,4,ink)
	_piece(cx,cy,flip,-7+stance,-14,6,13,dark)
	_piece(cx,cy,flip,-9+stance,-3,8,3,ink)
	if kick > 0:
		_piece(cx,cy,flip,1,-15,6+kick,5,coat)
		_piece(cx,cy,flip,15,-16,5,7,light)
	else:
		_piece(cx,cy,flip,3-stance,-14,5,12,coat)
		_piece(cx,cy,flip,3-stance,-3,8,3,ink)
	_piece(cx,cy0,flip,7,-29,6+maxi(0,arm),5,skin.darkened(.18))
	_piece(cx,cy0,flip,10+arm,-31 if f.guard else -29,6,6,light)
	_piece(cx,cy0,flip,-9,-27,5,9,skin.darkened(.18))
	_piece(cx,cy0,flip,-7,-22,7,5,coat)
	_piece(cx,cy0,flip,-10,-24,4,4,light)
	_piece(cx,cy0,flip,-6,-41,4,1,skin.lightened(.15))
	_piece(cx,cy0,flip,-1,-35,5,1,skin.darkened(.33))
	_piece(cx,cy0,flip,-4,-15,11,1,light)
	if style == 0:
		_piece(cx,cy0,flip,-9,-40,4,4,coat)
		_piece(cx,cy0,flip,-11,-36,3,6,ink)
	else:
		_piece(cx,cy0,flip,-6,-44,10,2,light)
		_piece(cx,cy0,flip,-11,-40,4,2,dark)
	if f.move == "super" and arm > 0:
		_piece(cx,cy0,flip,18,-33,17,2,light)
		_piece(cx,cy0,flip,21,-26,19,2,coat)
	if f.guard:
		_piece(cx,cy0,flip,14,-40,2,19,light)

func _piece(x: int,y: int,flip: int,dx: int,dy: int,w: int,h: int,color: Color) -> void:
	p(x+dx if flip == 1 else x-dx-w,y+dy,w,h,color)
