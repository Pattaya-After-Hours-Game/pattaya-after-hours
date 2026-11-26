extends Control

const Art = preload("res://scripts/art.gd")

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
const MOBILE_BUTTONS = [["jab","JAB",Rect2(732,450,68,64)],
	["kick","KICK",Rect2(807,408,68,64)],["super","BURST",Rect2(878,454,68,64)]]
const PAD_CELL = 60
const PAD = Rect2(24,346,PAD_CELL*3,PAD_CELL*3)
const PAD_BUTTONS = [[Vector2i.LEFT,"left","◀"],[Vector2i.RIGHT,"right","▶"],
	[Vector2i.UP,"jump","▲"],[Vector2i.DOWN,"guard","▼"]]
const MOUSE_POINTER = -1
const NO_PAD_POINTER = -2
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
var mobile_controls := OS.has_feature("mobile")
var pad_pointer := NO_PAD_POINTER
var pad_direction := Vector2i.ZERO
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
		buffered.clear()
		pad_pointer = NO_PAD_POINTER
		pad_direction = Vector2i.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and KEYS.has(event.physical_keycode):
		if event.echo: return
		get_viewport().set_input_as_handled()
		var key: String = KEYS[event.physical_keycode]
		if event.pressed:
			buffer(key)
			held[event.physical_keycode] = key
			if over and key == "jab": finished.emit(result)
		else:
			held.erase(event.physical_keycode)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		finished.emit(result if over else false)
	elif event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.canceled:
			activate(event.position,event.index)
		else:
			release_pointer(event.index)
	elif event is InputEventScreenDrag:
		drag_pointer(event.position,event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
		if event.pressed:
			activate(event.position,MOUSE_POINTER)
		else:
			release_pointer(MOUSE_POINTER)
	elif mobile_controls and event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		drag_pointer(event.position,MOUSE_POINTER)

func activate(point: Vector2, index: int) -> void:
	point = to_canvas(point)
	if exit_rect().has_point(point):
		finished.emit(result if over else false)
	elif over:
		if Rect2(345,281,270,82).has_point(point): finished.emit(result)
	elif mobile_controls and PAD.has_point(point):
		if pad_pointer == NO_PAD_POINTER:
			pad_pointer = index
			update_pad(point)
	else:
		var action := _action_at_canvas(point)
		if not mobile_controls or not action.is_empty():
			touches[index] = action
			buffer(action)

func drag_pointer(point: Vector2, index: int) -> void:
	if index == pad_pointer:
		update_pad(to_canvas(point))
	elif touches.has(index):
		var action := action_at(point)
		if mobile_controls and action != touches[index]:
			buffer(action)
		touches[index] = action

func release_pointer(index: int) -> void:
	if pad_pointer == index:
		pad_pointer = NO_PAD_POINTER
		pad_direction = Vector2i.ZERO
	touches.erase(index)

func update_pad(point: Vector2) -> void:
	var direction := Vector2i.ZERO
	if PAD.has_point(point):
		direction = Vector2i((point-PAD.position)/PAD_CELL)-Vector2i.ONE
	if direction.y < 0 and pad_direction.y >= 0:
		buffer("jump")
	pad_direction = direction

func exit_rect() -> Rect2:
	return Rect2(864,84,72,44) if mobile_controls else Rect2(880,465,72,61)

func to_canvas(point: Vector2) -> Vector2:
	return (point-global_position)/(size/Vector2(960,540))

func action_at(point: Vector2) -> String:
	return _action_at_canvas(to_canvas(point))

func _action_at_canvas(point: Vector2) -> String:
	for item in MOBILE_BUTTONS if mobile_controls else BUTTONS:
		var rect: Rect2 = item[2] if mobile_controls else Rect2(item[2],464,68,60)
		if rect.has_point(point): return item[0]
	return ""

func buffer(key: String) -> void:
	if key in ["jab","kick","super","jump"]:
		buffered[key] = elapsed + 0.17

func pressed(key: String) -> bool:
	if float(buffered.get(key,-1.0)) >= elapsed or key in held.values() or key in touches.values():
		return true
	match key:
		"left": return pad_direction.x < 0
		"right": return pad_direction.x > 0
		"jump": return pad_direction.y < 0
		"guard": return pad_direction.y > 0
	return false

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
				sparks.append({"p":Vector2(other.x,other.y-24),"v":Vector2(rng.randf_range(-77,77),rng.randf_range(-72,39)),"attack":f.move,
					"life":rng.randf_range(0.13,0.39),"color":Color("#75ffed") if blocked else Color("#ffcb79")})
	if f.timer >= timing[0]+timing[1]+timing[2]: f.move = ""

func frame_index(f: Dictionary) -> int:
	if f.hp <= 0: return 10
	if over or next_round > 0:
		if f.hp > fighters[1 if f == fighters[0] else 0].hp: return 11
	if f.stun > 0: return 4 if f.guard else 9
	if not f.move.is_empty():
		var timing: Array = ATTACKS[f.move]
		if f.timer < timing[0]: return 5
		if f.timer < timing[0]+timing[1]: return {"jab":6,"kick":7,"super":8}[f.move]
		return 5 if f.timer < timing[0]+timing[1]+timing[2]*.5 else 0
	if f.y < FLOOR: return 3
	if f.guard: return 4
	if f.motion: return 1+int(elapsed*8)%2
	return 0

func panel(rect: Rect2, fill: Color, border: Color = Color("#986748")) -> void:
	draw_rect(rect,fill)
	draw_rect(rect,border,false,1)

func label_at(x: float,y: float,value: String,px: int,tint: Color) -> void:
	draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func centered(x: float,y: float,value: String,px: int,tint: Color) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	label_at(x-width/2,y,value,px,tint)

func draw_mobile_controls(neon: Color, gold: Color) -> void:
	var hub := PAD.get_center()
	var fill := Color("#21161fe0")
	var edge := gold.darkened(.45)
	panel(Rect2(hub-Vector2.ONE*PAD_CELL/2,Vector2.ONE*PAD_CELL),fill,edge)
	draw_circle(hub,5,edge)
	for item in PAD_BUTTONS:
		var direction: Vector2i = item[0]
		var center := hub + Vector2(direction)*PAD_CELL
		var active := pressed(item[1])
		panel(Rect2(center-Vector2.ONE*PAD_CELL/2,Vector2.ONE*PAD_CELL),Color("#4d3941") if active else fill,neon if active else edge)
		centered(center.x,center.y+(0 if direction.y else 8),item[2],22,neon)
		if direction.y:
			centered(center.x,center.y+18,str(item[1]).to_upper(),11,gold)
	for item in MOBILE_BUTTONS:
		var rect: Rect2 = item[2]
		var center := rect.get_center()
		var active := pressed(item[0])
		var tint := gold if item[0] == "super" else neon
		draw_circle(center,32,Color("#4d3941") if active else fill,true,-1,true)
		draw_circle(center,31,tint if active else edge,false,2,true)
		centered(center.x,center.y+5,item[1],15,tint)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	var neon := Color("#73f5dc")
	var gold := Color("#e8ba7b")
	var pink: Color = RIVALS[rival_index][1]
	Art.image(self,"toybox",Rect2(0,0,960,540))
	centered(452,129,"TOYBOX",30,Color("#ff80b2"))
	centered(452,149,"AFTER HOURS CIRCUIT",11,gold)
	# Spectators and foreground effects remain independently animated.
	for i in 6:
		Art.frame(self,"patrons",i%4,Vector2(140+i*134,375),.42,i%2==1,Vector2.ZERO,Color.WHITE,Vector2(1,1+.018*sin(elapsed*3+i)))
	for i in fighters.size():
		var f: Dictionary = fighters[i]
		var pose := frame_index(f)
		var foot := Vector2(f.x*3,414 if pose in [10,11] else 414+(f.y-FLOOR)*3)
		# A fallen body stays visible inside the arena without moving simulation positions.
		if pose==10: foot.x = clampf(foot.x,160,800)
		draw_set_transform(Vector2(f.x*3,416)*size/Vector2(960,540),0,Vector2(1,.16)*size/Vector2(960,540))
		draw_circle(Vector2.ZERO,33,Color(0.05,.02,.07,.5))
		draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
		var id := "fight-mali" if i == 0 else "fight-"+str(RIVALS[rival_index][0]).to_lower()
		var breath := 1.0+.006*sin(elapsed*3+i) if pose in [0,4,11] else 1.0
		Art.frame(self,id,pose,foot,1.0,int(f.facing)<0,Vector2(320,256),Color.WHITE,Vector2(1,breath))
		if f.move == "super" and f.timer >= ATTACKS.super[0] and f.timer < ATTACKS.super[0]+ATTACKS.super[1]:
			for ray in 5:
				var origin := foot+Vector2(f.facing*35,-125+ray*7)
				draw_line(origin,origin+Vector2(f.facing*(60+ray*7),0),Color(neon,.6),2)
	for spark in sparks:
		var pos: Vector2 = Vector2(spark.p.x*3,369+(spark.p.y-FLOOR)*3)
		if spark.get("attack","kick") != "kick": pos.y -= 40
		draw_line(pos,pos+spark.v.normalized()*9,spark.color,2)
	if flash>0: draw_rect(Rect2(0,68,960,388),Color(1,.6,.7,flash*.3))
	panel(Rect2(0,0,960,72),Color("#21161ff8"))
	Art.image(self,"portrait-mali",Rect2(10,8,54,54))
	Art.image(self,"portrait-"+str(RIVALS[rival_index][0]).to_lower(),Rect2(896,8,54,54))
	label_at(76,25,"MALI  ·  %d" % wins[0],18,neon)
	label_at(575,25,"%d  ·  %s" % [wins[1],RIVALS[rival_index][0]],18,pink)
	centered(480,35,"%02d" % ceili(time_left),30,gold)
	centered(480,57,"ROUND %d" % (wins[0]+wins[1]+1),11,gold)
	for i in fighters.size():
		var x := 76 if i==0 else 575
		panel(Rect2(x,34,310,16),Color("#4b3040"))
		var width: float = fighters[i].hp*3.08
		draw_rect(Rect2(x+1 if i==0 else x+309-width,35,width,14),neon if i==0 else pink)
		draw_rect(Rect2(x,57,fighters[i].meter*3.1,5),gold)
	if mobile_controls:
		if not over:
			draw_mobile_controls(neon,gold)
	else:
		panel(Rect2(0,456,960,84),Color("#21161ff8"))
		for item in BUTTONS:
			var rect := Rect2(item[2],464,68,60)
			panel(rect,Color("#4d3941") if pressed(item[0]) else Color("#30212c"),neon if pressed(item[0]) else gold.darkened(.45))
			centered(rect.get_center().x,500,item[1],14,gold if item[0]=="super" else neon)
	var exit := exit_rect()
	panel(exit,Color("#392630"))
	centered(exit.get_center().x,exit.get_center().y+6,"EXIT",15,gold)
	if countdown>0:
		centered(480,270,"READY" if countdown>.4 else "FIGHT!",44,gold)
	elif next_round>0:
		centered(480,270,announced,44,gold)
	elif over:
		panel(Rect2(240,208,480,160),Color("#21161ff5"))
		centered(480,251,("TOYBOX CHAMPION" if circuit else "MALI WINS") if result else "CORNER CALLED IT",26,neon if result else pink)
		panel(Rect2(345,281,270,82),Color("#49303a"))
		centered(480,329,"CONTINUE",22,gold)
	elif elapsed<5 and not mobile_controls:
		panel(Rect2(255,426,450,23),Color("#21161fe8"))
		centered(480,443,"A/D MOVE   W JUMP   S GUARD   J/K/L ATTACK",13,gold)
