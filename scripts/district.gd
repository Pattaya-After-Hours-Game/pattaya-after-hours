extends Control
const Art = preload("res://scripts/art.gd")
const StreetView = preload("res://scripts/street_view.gd")
signal destination(index: int)
signal dismissed
const TEAL = Color("#73ffdc")
const PINK = Color("#ff70b1")
const GOLD = Color("#ffcb7c")
# Door positions follow the illustrated map; destinations retain the existing tabs.
const SITES = [
	["Blue Hour",Vector2(160,105),0,TEAL,"Anong checks payroll at the Blue Hour."],
	["Toybox",Vector2(267,105),1,PINK,"Mali trains here. Match nights bring a crowd."],
	["Market",Vector2(61,105),2,GOLD,"Fern starts the market loop at the noodle stall."],
	["Harbor",Vector2(56,43),2,Color("#bbb0ff"),"The harbor walk leaves from the covered pier."],
	["Rig loft",Vector2(155,160),3,PINK,"The loft power meter is visible from the street."],
	["High Tide",Vector2(265,160),3,TEAL,"A vacant lease and one optimistic agent."],
]
const LANES = [58.0,114.0,169.0]
const ALLEYS = [12.0,103.0,216.0,310.0]
# Absolute street activity, rather than how full one small bar is.
const ACTIVITY_GUESTS = StreetView.GUEST_BANDS
const ACTIVITY_NAMES = StreetView.NAMES
var street_state: Dictionary = {}
var plate_level := -1
var previous_plate := -1
var plate_blend := 1.0
var point := Vector2(160,114)
var target := point
var waypoints: Array[Vector2] = []
var clock := 0.0
var facing := 0
var walking := false
var focus_site := -1
var nearby := -1
var font = ThemeDB.fallback_font
var weather := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	update_activity(delta)
	var axis := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if Input.is_physical_key_pressed(KEY_A): axis.x -= 1
	if Input.is_physical_key_pressed(KEY_D): axis.x += 1
	if Input.is_physical_key_pressed(KEY_W): axis.y -= 1
	if Input.is_physical_key_pressed(KEY_S): axis.y += 1
	if axis != Vector2.ZERO:
		waypoints.clear()
		focus_site = -1
		var next := point+axis.normalized()*45*delta
		if on_path(next): target = next
		else: target = point
	elif not waypoints.is_empty() and point.distance_to(target)<.5:
		target = waypoints.pop_front()
	var motion := target-point
	walking = motion.length()>.5
	if walking:
		facing = (3 if motion.x>0 else 1) if absf(motion.x)>absf(motion.y) else (0 if motion.y>0 else 2)
	point = point.move_toward(target,45*delta)
	nearby = -1
	for i in SITES.size():
		if point.distance_to(SITES[i][1]+Vector2(0,9))<14:
			nearby = i
			break
	if focus_site>=0 and waypoints.is_empty() and point.distance_to(target)<.5:
		var selected := focus_site
		focus_site = -1
		destination.emit(SITES[selected][2])
	queue_redraw()

func live_guests() -> int:
	return StreetView.live_guests(street_state)

func activity_level() -> int:
	return StreetView.activity(street_state)

func update_activity(delta: float) -> void:
	var next := activity_level()
	if plate_level<0:
		plate_level = next
		previous_plate = next
	elif next!=plate_level:
		previous_plate = plate_level
		plate_level = next
		plate_blend = 0.0
	plate_blend = minf(1.0,plate_blend+delta*2.5)

func on_path(p: Vector2) -> bool:
	if not Rect2(5,48,310,127).has_point(p): return false
	for y in LANES:
		if absf(p.y-y)<5 and (y!=LANES[0] or p.x<=104): return true
	for x in ALLEYS:
		if absf(p.x-x)<5 and (x<=103 or p.y>=110): return true
	return false

func nearest_lane(p: Vector2) -> float:
	var result: float = LANES[0]
	for y in LANES:
		if absf(p.y-y)<absf(p.y-result): result = y
	return result

func route(p: Vector2) -> void:
	p = p.clamp(Vector2(10,48),Vector2(310,170))
	var y := nearest_lane(p)
	if y==LANES[0]: p.x = minf(p.x,103)
	var from_y := nearest_lane(point)
	var x: float = ALLEYS[0]
	var best := INF
	for alley in ALLEYS:
		if (y==LANES[0] or from_y==LANES[0]) and alley>103: continue
		var cost: float = absf(point.x-alley)+absf(p.x-alley)
		if cost < best:
			best = cost
			x = alley
	waypoints.clear()
	# Finish an interrupted alley segment before crossing to a different alley.
	if absf(point.y-from_y)>5:
		for alley in ALLEYS:
			if absf(point.x-alley)<5:
				waypoints.append(Vector2(alley,from_y))
				break
	if absf(y-from_y)>1:
		waypoints.append(Vector2(x,from_y))
		waypoints.append(Vector2(x,y))
	waypoints.append(Vector2(p.x,y))
	target = waypoints.pop_front()

func site_rect(index: int) -> Rect2:
	return Rect2(SITES[index][1]-Vector2(25,25),Vector2(50,16))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			dismissed.emit()
		elif event.keycode in [KEY_E,KEY_ENTER] and nearby>=0:
			get_viewport().set_input_as_handled()
			destination.emit(SITES[nearby][2])
	elif (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		var hit: Vector2 = (event.position-global_position)/(size/Vector2(320,180))
		if Rect2(276,2,42,14).has_point(hit):
			dismissed.emit()
			return
		focus_site = -1
		for i in SITES.size():
			if site_rect(i).has_point(hit):
				focus_site = i
				route(SITES[i][1]+Vector2(0,9))
				return
		route(hit)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	var current := activity_level() if plate_level<0 else plate_level
	var plate_rect := Rect2(0,0,960,540)
	if plate_blend<1.0 and previous_plate>=0:
		Art.image(self,"street-activity-%d" % previous_plate,plate_rect)
	Art.image(self,"street-activity-%d" % current,plate_rect,Color(1,1,1,plate_blend))
	for i in SITES.size():
		var item: Array = SITES[i]
		var rect := site_rect(i)
		rect.position *= 3
		rect.size *= 3
		draw_rect(rect,Color("#211621ee"))
		draw_rect(rect,item[3] if nearby==i else GOLD.darkened(.4),false,1)
		draw_string(font,rect.position+Vector2(5,30),item[0],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-10,16,item[3])
	StreetView.draw_traffic(self,activity_level(),clock)
	var breath := 1.0 if walking else 1.0+.008*sin(clock*2)
	Art.frame(self,"anong-walk",facing*4+(int(clock*24)%4 if walking else 0),point*3,.3,false,Vector2(128,192),Color.WHITE,Vector2(1,breath))
	if weather>=5:
		for i in 90:
			var p := Vector2(fposmod(i*67-clock*65,960),fposmod(i*i*19+clock*270,540))
			draw_line(p,p+Vector2(-4,12),Color("#a2bfda70"))
	draw_rect(Rect2(0,0,960,48),Color("#21161ff5"))
	draw_string(font,Vector2(15,29),"BAY DISTRICT",HORIZONTAL_ALIGNMENT_LEFT,-1,23,GOLD)
	draw_string(font,Vector2(242,29),"WASD / tap to walk · E to enter",HORIZONTAL_ALIGNMENT_LEFT,-1,14,TEAL)
	draw_string(font,Vector2(583,22),ACTIVITY_NAMES[current].to_upper(),HORIZONTAL_ALIGNMENT_LEFT,235,15,PINK)
	draw_string(font,Vector2(583,39),"%d guests in open venues" % live_guests(),HORIZONTAL_ALIGNMENT_LEFT,235,12,TEAL)
	draw_rect(Rect2(828,6,126,36),Color("#51333d"))
	draw_string(font,Vector2(839,30),"BACK  [ESC]",HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	if nearby>=0:
		draw_rect(Rect2(12,484,700,40),Color("#21161ff0"))
		draw_string(font,Vector2(23,510),SITES[nearby][4]+"  [E]",HORIZONTAL_ALIGNMENT_LEFT,680,15,GOLD)
