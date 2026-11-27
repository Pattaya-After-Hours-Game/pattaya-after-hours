extends Control
const Art = preload("res://scripts/art.gd")
const Economy = preload("res://scripts/economy.gd")
const Content = preload("res://scripts/street_content.gd")
const RatSwarm = preload("res://scripts/rat_swarm.gd")
const StreetView = preload("res://scripts/street_view.gd")
const INK = Color("#21131e")
const TEAL = Color("#73f5dc")
const PINK = Color("#f37ab0")
const GOLD = Color("#e8ba7b")
const ORDER_URGENT = Color("#ff514d")
const KISS_SECONDS = 1.2
const FRIDGE_BOTTLE_BAYS = [
	[Vector2i(63,5)],
	[Vector2i(71,7)],
	[Vector2i(54,6),Vector2i(125,1)],
	[Vector2i(88,5),Vector2i(23,5)],
	[Vector2i(89,5),Vector2i(25,5)]
]
const HEART_OUTLINE = [Vector2(-6,-4),Vector2(-2,-4),Vector2(0,-2),
	Vector2(2,-4),Vector2(6,-4),Vector2(7,-1),Vector2(5,2),Vector2(0,7),
	Vector2(-5,2),Vector2(-7,-1)]
var clock := 0.0
var street_state: Dictionary = {}
var arrival_time := 0.0
var duo_reaction := {}
# Disposable presentation cache. Saves, admission and pool settlement stay in
# the model; walking never delays service, spends money or consumes RNG.
var customer_motion := {}
var motion_street: Dictionary = {}
var motion_selected := -1
var night := false
var celebrating := false
var godzilla := ""
var shot_flash := 0.0
var weather := 0
var guests := 0
var level := 1
var venue := 1
var rig := 0
var bars: Array = []
var selected_bar := 0
var street_event: Dictionary = {}

var service_flash := 0.0
var fridge_install_flash := 0.0
var fridge_capacity := 1
var legacy_staff: Array = []
var font = ThemeDB.fallback_font
signal site(tab: int)
signal select_bar(index: int)
signal rat_caught(index: int)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(delta: float) -> void:
	clock += delta
	arrival_time += delta
	service_flash = maxf(0,service_flash-delta)
	fridge_install_flash = maxf(0,fridge_install_flash-delta)
	update_customer_motion(delta)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var targets: Array = street_event.get("rats",[])
	if not targets.is_empty() and rat_pointer_input(event,targets): return
	if bars.is_empty(): return
	if event is InputEventMouseButton:
		if event.device==InputEvent.DEVICE_ID_EMULATION or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed or not event.double_click: return
	elif event is InputEventScreenTouch:
		if event.device==InputEvent.DEVICE_ID_EMULATION or not event.pressed: return
	else:
		return
	var point: Vector2 = event.position * Vector2(960,540) / size
	var people := scene_people(bars[selected_bar])
	people.reverse()
	for person in people:
		if person.behind_bar or not _person_contains(person,point): continue
		if person.who=="patrons-rainbow-duo":
			duo_reaction.assign({"id":person.customer_id,"until":clock+KISS_SECONDS})
			accept_event()
		return

func rat_pointer_input(event: InputEvent, targets: Array) -> bool:
	if event is InputEventKey and event.is_action_pressed("ui_accept") and not event.is_echo():
		accept_event()
		rat_caught.emit(targets.front())
		return true
	if event.device==InputEvent.DEVICE_ID_EMULATION: return false
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return false
	elif event is InputEventScreenTouch:
		if not event.pressed: return false
	else:
		return false
	var point: Vector2 = event.position*Vector2(960,540)/size
	var nearest := -1
	var best := 26.0*26.0
	for index: int in targets:
		var distance := point.distance_squared_to(RatSwarm.target_position(index,clock))
		if distance<best:
			best = distance
			nearest = index
	if nearest<0: return false
	accept_event()
	rat_caught.emit(nearest)
	return true

func _person_contains(person: Dictionary, point: Vector2) -> bool:
	var draw_id: String = person.get("draw_who",person.who)
	var draw_pose: int = person.get("draw_pose",person.pose)
	var cell: Vector2 = Art.atlas_specs()[draw_id][0]
	var scale_value := person_scale(person.foot.y)
	var pixel := (point-Vector2(person.foot))/scale_value + Vector2(cell.x*.5,cell.y-4)
	if not Rect2(Vector2.ZERO,cell).has_point(pixel): return false
	var x := int(cell.x)-1-int(pixel.x) if person.flip else int(pixel.x)
	var texture := Art.texture(draw_id)
	var columns := int(texture.get_width()/cell.x)
	return texture.get_image().get_pixel(x+draw_pose%columns*int(cell.x),
		int(pixel.y)+draw_pose/columns*int(cell.y)).a>.5

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	var bar: Dictionary = bars[selected_bar] if not bars.is_empty() else {"type":0,"stage":clampi(level,1,3),"crew":legacy_staff.size(),"away":[],"closed":0,"name":"Blue Hour"}
	var kind := int(bar.type)
	var stage := int(bar.stage)
	var tier := fridge_tier(bar) if not bars.is_empty() else -1
	var backdrop := Art.venue(kind,stage,fan_owned(bar),screen_owned(bar),tier)
	# Exterior and its traffic sit UNDER the original room's exact-pixel shell.
	_draw_street(kind,stage)
	var shell := Art.room_shell(backdrop,kind,stage)
	if shell: draw_texture_rect(shell,Rect2(0,0,960,540),false)
	if tier>=0: _draw_fridge_stock(tier,int(bar.stock))
	if celebrating: _draw_celebration()
	var closed := not Economy.trading(bar,int(street_state.get("minute",720)))
	# Only the street opening contains ambient traffic. Interior sprites come
	# from the actual customers and available team, sorted by their floor depth.
	var people := scene_people(bar)
	for person in people:
		if person.behind_bar: _draw_person(person)
	# Reuse the bar fronts from the same production plate to hide staff legs.
	# Customers are drawn afterwards, on the public side of the counter.
	if backdrop:
		for region in counter_regions(kind,stage):
			draw_texture_rect_region(backdrop,region,region)
	if kind==0 and bar.get("equipment",{}).get("seating",0)>=3: _draw_compact_layout()
	# Tables and people share the depth order. The original illustrated table
	# remains visible (but labelled not open) when it is not owned.
	var floor_items := people.filter(func(person: Dictionary) -> bool: return not person.behind_bar)
	if kind==0:
		var table_count := int(bar.get("equipment",{}).get("pool",0))
		if stage>1: table_count = maxi(1,table_count)
		for table in table_count:
			floor_items.append({"table":table,"foot":pool_rect(table).end})
	floor_items.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.foot.y<b.foot.y)
	for item in floor_items:
		if item.has("table"):
			draw_texture_rect_region(Art.venue(0,2),pool_rect(item.table),Rect2(270,274,165,78))
		else:
			_draw_person(item)
	# Markers are drawn after the people so a nearer guest cannot hide an order.
	for person in people:
		if person.who=="patrons-rainbow-duo" and person.pose==1 and not person.get("motion_state","").begins_with("walk"): _draw_kiss_heart(person)
		if person.get("chat_until",0.0)>float(street_state.get("elapsed",0))+float(street_state.get("tick_fraction",0.0)):
			var feedback := order_position(person)+Vector2(-31,-14)
			draw_style_box(_sign_box(),Rect2(feedback-Vector2(4,15),Vector2(78,21)))
			draw_string(font,feedback,"+10s · chat",HORIZONTAL_ALIGNMENT_LEFT,-1,12,TEAL)
		if person.get("costume",false):
			var mask := order_position(person)+Vector2(0,19)
			draw_rect(Rect2(mask-Vector2(7,2),Vector2(14,5)),Color("#71975b"))
			for x in [-4,3]: draw_rect(Rect2(mask+Vector2(x,0),Vector2(2,2)),INK)
		if person.get("hosted_state","")!="":
			var marker := order_position(person)+Vector2(0,-8)
			draw_style_box(_sign_box(),Rect2(marker-Vector2(23,14),Vector2(46,20)))
			draw_string(font,marker+Vector2(-19,0),"POUR" if person.hosted_state=="waiting" else "CHEERS",HORIZONTAL_ALIGNMENT_LEFT,44,10,GOLD if person.hosted_state=="waiting" else TEAL)
		if person.order:
			var marker := order_position(person)
			draw_circle(marker,6,INK)
			draw_circle(marker,4,order_color(person.order_seconds_left))
		elif person.get("visit_phase","")=="drinking":
			# A cyan glass means drinking; only pending orders receive urgency dots.
			var marker := order_position(person)
			draw_rect(Rect2(marker-Vector2(3,3),Vector2(6,6)),INK)
			draw_polyline(PackedVector2Array([marker+Vector2(-3,-3),marker+Vector2(-2,3),marker+Vector2(2,3),marker+Vector2(3,-3)]),TEAL,1.5)
	if bar.has("games") and bar.equipment.pool>0:
		# Status is model-owned; the artwork never creates a pool fee.
		for i in int(bar.equipment.pool):
			var p := pool_rect(i).position+Vector2(5,37)
			draw_style_box(_sign_box(),Rect2(p,Vector2(145,23)))
			var label := "POOL / CLOSED" if closed else "POOL / ฿50"
			for game in bar.games:
				if int(game.get("table",0))==i: label = "%ds / %s" % [game.remaining,"FREE" if game.fee==0 else "PAID"]
			draw_string(font,p+Vector2(7,17),label,HORIZONTAL_ALIGNMENT_LEFT,135,13,GOLD)
	if kind==0 and stage>1 and bar.has("equipment") and bar.equipment.pool==0:
		draw_style_box(_sign_box(),Rect2(300,306,155,31))
		draw_string(font,Vector2(307,327),"POOL / NOT OPEN",HORIZONTAL_ALIGNMENT_LEFT,145,14,GOLD)
	if bar.get("equipment",{}).get("music",0)>0:
		draw_style_box(_sign_box(),Rect2(674,116,142,22))
		draw_string(font,Vector2(681,132),"MUSIC / "+("OFF" if closed else "PLAYING"),HORIZONTAL_ALIGNMENT_LEFT,130,12,TEAL)
	# Anong remains available at the service position even before the first hire.
	var idle := 0 if service_flash <= 0 or closed else 3
	Art.frame(self,"anong-service",idle,Vector2(817,418),person_scale(418),false,Vector2.ZERO,Color.WHITE,Vector2(1,1+.005*sin(clock*2)))
	# Leave the cabinet and its lower drawer visible beside Anong.
	Art.image(self,"counter",Rect2(650,344,198 if tier>=0 else 310,92))
	if tier==4 and fridge_install_flash>0: _draw_fridge_frost()
	if bar.get("bed_trophy",false):
		draw_rect(Rect2(697,104,35,25),Color("#2b242d"))
		draw_rect(Rect2(706,107,17,8),GOLD)
		draw_rect(Rect2(712,114,5,8),GOLD)
		draw_rect(Rect2(706,121,17,4),GOLD.darkened(.2))
	# Owned fans stay installed when closed, but only spin during trading.
	if fan_owned(bar) and not closed:
		var fan := Vector2(502,122) if kind==0 else Vector2(266,92)
		for i in 3:
			var ray := Vector2.from_angle(clock*9+i*TAU/3)*23
			draw_line(fan+ray*.22,fan+ray,Color("#8e5e5670"),5)
	if closed:
		draw_rect(Rect2(0,0,960,540),Color(0.08,0.03,0.09,.55))
		var reason := "RAID / UNTIL 12PM" if bar.get("raided",false) else "CLOSED / PREP TIME" if not Economy.scheduled(bar,int(street_state.get("minute",720))) else "TEMPORARILY CLOSED"
		draw_string(font,Vector2(160,250),reason,HORIZONTAL_ALIGNMENT_CENTER,390,23,GOLD)
		if bar.get("clean_remaining",0)>0:
			draw_string(font,Vector2(160,280),"CLEANING / %ds" % bar.clean_remaining,HORIZONTAL_ALIGNMENT_CENTER,390,18,TEAL)
	if bar.get("raided",false): Art.frame(self,"event-inspection",0,Vector2(505,365),person_scale(365))
	_draw_event(closed)
	if int(street_event.get("id",-1))==Content.RAT_PLAGUE:
		var viewport_scale := size/Vector2(960,540)
		if street_event.phase=="warning": RatSwarm.draw_warning(self,clock,viewport_scale)
		elif not street_event.rats.is_empty(): RatSwarm.draw_active(self,clock,viewport_scale,street_event.rats,has_focus())
	if weather >= 5:
		for i in 65:
			var p := Vector2(fposmod(i*53-clock*40,180),fposmod(i*71+clock*250,540))
			draw_line(p,p+Vector2(-3,13),Color("#92c7dc70"),1)
	if godzilla in ["attack","asleep"]:
		var state := 3 if godzilla == "asleep" else 2 if shot_flash > .1 else 1 if arrival_time > 1.0 else int(arrival_time*4)%2
		Art.frame(self,"monster",state,Vector2(400-maxf(0,1-arrival_time)*500,460),1.2,false,Vector2(320,320),Color.WHITE,Vector2(1,1+.012*sin(clock*(1.5 if state==3 else 3))))
		if shot_flash > .1: draw_circle(Vector2(445,255),9*shot_flash,Color(1,.8,.3,shot_flash*.6))

func _draw_celebration() -> void:
	# Temporary bunting, with no decorative customers or replacement room plate.
	for i in 12:
		var x := 240.0+i*52.0
		var y := 12.0+sin(float(i)/11.0*PI)*12.0
		var end := Vector2(x+52,12.0+sin(float(i+1)/11.0*PI)*12.0)
		draw_line(Vector2(x,y),end,GOLD,1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(x+7,y+2),Vector2(x+37,y+4),Vector2(x+22,y+18)]),[PINK,TEAL,GOLD][i%3])

func _draw_compact_layout() -> void:
	# Fitted wall benches leave the pool aisle clear; actual guests draw above.
	for x in [257,465]: Art.image(self,"compact-bench",Rect2(x,294,150,80))

func _draw_fridge_stock(tier: int, stock: int) -> void:
	var bays: Array = FRIDGE_BOTTLE_BAYS[tier]
	var shelves := [191,145,100] if tier==0 else [190,154,118,83]
	var slots := 0
	for bay in bays: slots += shelves.size()*bay.y
	var fill := ceili(slots*clampf(float(stock)/fridge_capacity,0,1))
	for shelf in shelves:
		for bay in bays:
			for i in bay.y:
				if fill==0: return
				fill -= 1
				var p := Vector2(Art.FRIDGE_ORIGIN)+Vector2(bay.x+i*8,shelf)
				draw_rect(Rect2(p+Vector2(2,-13),Vector2(2,4)),Color("#e6c779"))
				draw_rect(Rect2(p+Vector2(0,-9),Vector2(6,9)),Color("#74924b"))
				draw_rect(Rect2(p+Vector2(1,-6),Vector2(4,4)),Color("#eee0a2"))

func _draw_fridge_frost() -> void:
	var progress := 1.0-fridge_install_flash
	for i in 8:
		var p := Vector2(890+i*6,396-i%3*4)-Vector2(progress*(12+i*2),progress*16)
		draw_rect(Rect2(p,Vector2(8+i%3*2,3)),Color(.70,.94,1.0,.8*fridge_install_flash))

static func fridge_tier(bar: Dictionary) -> int:
	return clampi(int(bar.get("equipment",{}).get("fridge",0)),0,4)

static func fan_owned(bar: Dictionary) -> bool:
	return int(bar.get("equipment",{}).get("comfort",0))>0

static func screen_owned(bar: Dictionary) -> bool:
	return int(bar.get("equipment",{}).get("screen",0))>0

static func order_color(seconds_left: int) -> Color:
	return ORDER_URGENT if seconds_left<=Content.CHAT_THRESHOLD else GOLD

static func pool_rect(table: int) -> Rect2:
	return Rect2(270+table*200,274+table*12,165,78)

# All adult silhouettes are packed to 180px at rest. Use one perspective
# rule for guests, staff and Anong, rather than a different size per role.
static func person_scale(floor_y: float) -> float:
	return clampf(.75+(floor_y-300)*.0022,.70,1.04)

static func order_position(person: Dictionary) -> Vector2:
	return person.foot-Vector2(0,180*person_scale(person.foot.y)+10)

func _draw_person(person: Dictionary) -> void:
	var foot: Vector2 = person.foot
	var scale_value := person_scale(foot.y)
	# Small contact shadows make the common floor plane visible.
	draw_set_transform(foot*size/Vector2(960,540),0,Vector2(1,.24)*size/Vector2(960,540))
	if not person.behind_bar:
		var offsets := [-35,32] if person.who=="patrons-rainbow-duo" else [0]
		for offset in offsets:
			draw_circle(Vector2(offset*scale_value,0),18*scale_value,Color(0,0,0,.24))
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	Art.frame(self,person.get("draw_who",person.who),person.get("draw_pose",person.pose),foot,scale_value,person.flip)

func _draw_kiss_heart(person: Dictionary) -> void:
	var progress := 1.0-(float(duo_reaction.until)-clock)/KISS_SECONDS
	# Mouth contact in the kiss sprite is at (57,44), relative to its (80,188) pivot.
	var scale_value := person_scale(person.foot.y)
	var origin: Vector2 = person.foot+Vector2(23 if person.flip else -23,-144-progress*38)*scale_value
	var points := PackedVector2Array()
	for point in HEART_OUTLINE: points.append(origin+point*scale_value)
	draw_colored_polygon(points,Color(1.0,.32,.55,1.0-smoothstep(.35,1.0,progress)))

static func counter_regions(kind: int, stage: int) -> Array[Rect2]:
	if kind==0:
		if stage==1: return [Rect2(250,270,300,85),Rect2(665,290,180,110)]
		return [Rect2(440,278,400,120)]
	return [Rect2(665,290,180,110)]

func _draw_street(kind: int, stage: int) -> void:
	var minute := int(street_state.get("minute",720))
	var period := StreetView.period(minute)
	var blend := clampf(float(minute-StreetView.TIME_STARTS[period])+float(street_state.get("tick_fraction",0.0)),0,1)
	if blend<1:
		Art.image(self,"street-day-%d" % posmod(period-1,8),Rect2(Art.STREET_RECT))
	Art.image(self,"street-day-%d" % period,Rect2(Art.STREET_RECT),Color(1,1,1,blend))
	StreetView.draw_traffic(self,StreetView.activity(street_state),clock,true,kind==0 and stage==3)

static func customer_home(kind: int, slot: int) -> Vector2:
	var columns := [300,440,580,370,510,650,720,790]
	var row := slot/8
	return Vector2(columns[slot%8]+(15 if row%2 else 0),366-row*9 if kind==2 else 362-row*19)

static func customer_pool_foot(bar: Dictionary, guest: Dictionary, home: Vector2) -> Vector2:
	if guest.playing:
		for game in bar.games:
			var player: int = game.players.find(guest.id)
			if player>=0: return Vector2(250+int(game.get("table",0))*200+player*205,355+int(game.get("table",0))*12)
	return home

func update_customer_motion(delta: float) -> void:
	if not is_same(motion_street,street_state):
		customer_motion.clear()
		motion_street = street_state
		motion_selected = -1
	if bars.is_empty() or selected_bar>=bars.size(): return
	var changed_view := motion_selected!=selected_bar
	motion_selected = selected_bar
	var bar: Dictionary = bars[selected_bar]
	var key := str(bar.get("name",selected_bar))
	if not Economy.trading(bar,int(street_state.get("minute",720))):
		customer_motion.erase(key)
		return
	var first_view := not customer_motion.has(key)
	if first_view: customer_motion[key] = {}
	var records: Dictionary = customer_motion[key]
	var ids: Array = bar.customers.map(func(g: Dictionary) -> int: return int(g.id))
	for id in records.keys():
		if not ids.has(id): records.erase(id)
	var occupied := {}
	for record in records.values(): occupied[int(record.slot)] = true
	for i in bar.customers.size():
		var guest: Dictionary = bar.customers[i]
		var id := int(guest.id)
		if not records.has(id):
			var slot := 0
			while occupied.has(slot): slot += 1
			occupied[slot] = true
			var home := customer_home(int(bar.type),slot)
			var foot := customer_pool_foot(bar,guest,home) if first_view or changed_view else Vector2(242,362)
			records[id] = {"slot":slot,"foot":foot,"direction":Vector2.ZERO,"moving":false}
		var record: Dictionary = records[id]
		var target := customer_pool_foot(bar,guest,customer_home(int(bar.type),int(record.slot)))
		var offset: Vector2 = target-record.foot
		record.moving = offset.length()>.5
		if record.moving:
			record.direction = offset.normalized()
			record.foot = record.foot.move_toward(target,maxf(0.0,delta)*52.0)
		else:
			record.foot = target

func scene_people(bar: Dictionary) -> Array:
	var people: Array = []
	if not Economy.trading(bar,int(street_state.get("minute",720))): return people
	var kind := int(bar.type)
	var stage := int(bar.stage)
	var dancer_index := 0
	var floor_index := 0
	var bartender_index := 0
	for i in int(bar.crew):
		if i in bar.away or (bar.has("team") and i < bar.team.size() and not bar.team[i].on): continue
		var role: int = int(bar.team[i].role) if bar.has("team") and i < bar.team.size() else (2 if kind==2 else 0)
		var who := Art.worker_id(bar,i)
		if role==3:
			people.append({"who":who,"pose":Art.animation_frame(who,"welcome",clock,1),"foot":Vector2(207,362),"flip":true,"order":false,"customer":false,"behind_bar":false})
			continue
		if bars.is_empty() and i < legacy_staff.size():
			if not legacy_staff[i].work or legacy_staff[i].hurt: continue
			who = Art.STAFF[int(legacy_staff[i].id)]
		var foot: Vector2
		var state := "idle"
		var flip := false
		if role == 2 and dancer_index < stage and (street_state.is_empty() or int(street_state.seconds) in range(40,80)):
			var poles: Array = [[478],[402,545],[400,476,549]][stage-1]
			foot = Vector2(poles[dancer_index]-19,303)
			dancer_index += 1
			state = "dance"
		elif role == 0:
			# Service positions follow each venue's illustrated counters.
			if kind==0:
				var stations: Array = [280,360,440,520,705,785] if stage==1 else [475,540,605,670,735,800]
				foot = Vector2(stations[bartender_index%6],340)
			else:
				foot = Vector2(695+(bartender_index%3)*55,340-(bartender_index/3)*18)
			bartender_index += 1
			state = "serve" if bar.has("team") and i<bar.team.size() and float(bar.team[i].get("last_served",-1))>=0 and float(street_state.get("elapsed",0))-float(bar.team[i].last_served)<2.0 else "idle"
		else:
			foot = Vector2(565+(floor_index%3)*66,364-(floor_index/3)*12)
			floor_index += 1
			var cycle := fposmod(clock+i*1.7,9.0)
			if cycle<4:
				foot.x += (cycle if cycle<2 else 4-cycle)*8
				state = "walk"
				flip = cycle>=2
		people.append({"who":who,"pose":Art.animation_frame(who,state,clock+i,2),"foot":foot,"flip":flip,"order":false,"customer":false,"behind_bar":role==0})
		for round in bar.get("host_rounds",[]):
			if int(round.host)==i:
				people.back().foot.x = 565+((floor_index-1)%3)*66
				people.back().hosted_state = str(round.state)
				people.back().pose = Art.animation_frame(who,"idle",clock,2)

	var crowd: int = bar.customers.size() if bar.has("customers") else mini(8,guests)
	for i in crowd:
		var foot := customer_home(kind,i)
		if bar.has("customers"): foot = customer_pool_foot(bar,bar.customers[i],foot)
		var customer_id: int = int(bar.customers[i].id) if bar.has("customers") else i+1
		var appearance := Art.customer_sprite(customer_id,str(bar.customers[i].get("appearance","")) if bar.has("customers") else "")
		var pose: int = appearance[1]
		if appearance[0]=="patrons-charcoal" and bar.has("customers"):
			var guest: Dictionary = bar.customers[i]
			var now := float(street_state.get("elapsed",0))+float(street_state.get("tick_fraction",0.0))
			var state := "pool" if guest.playing else "chat" if now<float(guest.get("chat_until",0)) else "drinking" if guest.get("visit_phase","")=="drinking" else "idle"
			pose = Art.animation_frame("patrons-charcoal",state,clock)
		elif appearance[0]=="patrons-capybara":
			pose = Art.capybara_frame(clock+float(customer_id/24)*1.31)
		elif appearance[0]=="patrons-men" and pose==Art.COBALT_IDLE:
			pose = Art.cobalt_frame(clock+float(customer_id/Art.CUSTOMER_VARIANTS.size())*1.31)
		elif appearance[0]=="patrons-rainbow-duo" and duo_reaction.get("id",-1)==customer_id and clock<float(duo_reaction.get("until",0.0)):
			pose = 1
		people.append({"who":appearance[0],"pose":pose,"foot":foot,"flip":customer_id%2==0,"order":bar.has("customers") and bar.customers[i].order,"customer":true,"customer_id":customer_id,"chat_until":bar.customers[i].get("chat_until",0.0) if bar.has("customers") else 0.0,"behind_bar":false})
		var person: Dictionary = people.back()
		var guest: Dictionary = bar.customers[i] if bar.has("customers") else {}
		var state := "pool" if guest.get("playing",false) else "chat" if float(street_state.get("elapsed",0))+float(street_state.get("tick_fraction",0.0))<float(guest.get("chat_until",0)) else "drinking" if guest.get("visit_phase","")=="drinking" else "idle"
		var records: Dictionary = customer_motion.get(str(bar.get("name",selected_bar)),{})
		if records.has(customer_id):
			var record: Dictionary = records[customer_id]
			person.foot = record.foot
			if record.moving:
				var direction: Vector2 = record.direction
				state = ("walk_front" if direction.y>0 else "walk_back") if absf(direction.y)>absf(direction.x) else "walk"
				person.flip = state=="walk" and direction.x<0
		# Keep companion idle reactions and sunglasses exactly as authored.
		# A kiss is allowed only while stationary; it never interrupts a walk.
		var kissing: bool = appearance[0]=="patrons-rainbow-duo" and pose==1
		var keep_idle: bool = state=="idle" and (appearance[0] in ["patrons-capybara","patrons-rainbow-duo"] or (appearance[0]=="patrons-men" and int(appearance[1])==Art.COBALT_IDLE))
		if not keep_idle and not (kissing and not state.begins_with("walk")):
			var motion_id := Art.customer_motion_id(appearance)
			if not motion_id.is_empty():
				person.draw_who = motion_id
				person.draw_pose = Art.animation_frame(motion_id,state,clock+customer_id*.19,8)
				if not state.begins_with("walk"): person.flip = customer_id%2==0
		person.motion_state = state
		people.back().visit_phase = bar.customers[i].get("visit_phase","legacy") if bar.has("customers") else "legacy"
		people.back().costume = bar.has("customers") and bar.customers[i].get("costume",false)
		people.back().order_seconds_left = Economy.order_seconds_left(bar,bar.customers[i]) if bar.has("customers") else Content.PATIENCE_SECONDS
	people.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.foot.y<b.foot.y)
	return people

func _sign_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#1c1828")
	s.border_color = GOLD.darkened(.35)
	s.set_border_width_all(1)
	return s

func _draw_event(closed: bool) -> void:
	if street_event.get("phase","") != "active": return
	var id := int(street_event.get("id",-1))
	match id:
		0:
			if not street_event.get("prepared",false): draw_rect(Rect2(0,0,960,540),Color(0.02,.01,.06,.65))
		1:
			for i in 7:
				var p := Vector2(14+i*25,85+sin(clock*2+i)*2)
				draw_colored_polygon(PackedVector2Array([p,p+Vector2(18,3),p+Vector2(9,24)]),Color("#bcdbe3") if i%2 else Color("#27467a"))
		2:
			Art.frame(self,"event-inspection",0,Vector2(250,365),person_scale(365))
		3:
			draw_rect(Rect2(0,350,960,190),Color(.12,.52,.64,.42))
			for i in 20:
				var x := fposmod(i*71+clock*35,960)
				draw_line(Vector2(x,360+i%9*9),Vector2(x+40,360+i%9*9),Color("#91e4e880"),2)
		4:
			# Songkran water jets and splash rings are separate from flood water.
			for i in 18:
				var t := fposmod(clock*.6+i*.17,1.0)
				var p := Vector2(30+t*300,380-sin(t*PI)*140+i%3*14)
				draw_circle(p,2+i%2,Color("#a0eaffb0"))
			for i in 9:
				var t := fposmod(clock+i*.23,1.0)
				draw_arc(Vector2(80+i*79,380+i%3*12),5+t*18,0,TAU,18,Color(.4,.85,1,(1-t)*.6),1)
		5:
			if closed: return
			for i in 4:
				var p := Vector2(60+i*36,310)
				var burst := maxf(0,sin(clock*3+i*7)-.92)*12
				if burst>0:
					p += Vector2(14,-60)
					draw_line(p-Vector2(8,0),p+Vector2(8,0),Color(1,1,1,burst),2)
					draw_line(p-Vector2(0,8),p+Vector2(0,8),Color(1,1,1,burst),2)
		6:
			draw_rect(Rect2(0,0,960,540),Color(.16,.13,.24,.18))
		7:
			draw_rect(Rect2(0,0,100,540),Color(.8,.15,.45,.1+.07*sin(clock*4)))
		8:
			draw_rect(Rect2(0,0,180,540),Color(.08,.12,.2,.2))
		9:
			for i in 32:
				var p := Vector2(fposmod(i*59+sin(clock+i)*13,960),fposmod(i*83+clock*38,540))
				draw_rect(Rect2(p,Vector2(3,7)),[TEAL,PINK,GOLD][i%3])

		Content.Local.ENCORE:
			for i in 4:
				var beam := Vector2(10+i*18,120)
				var end := Vector2(210+sin(clock*2+i)*145,348)
				draw_colored_polygon(PackedVector2Array([beam,end,end+Vector2(15,8)]),Color(.8,.34,.6,.19))
		Content.Local.CART:
			for i in 4:
				var p := Vector2(13+i*37,352+i*11)
				draw_rect(Rect2(p,Vector2(27,16)),Color("#85545e"))
				draw_rect(Rect2(p-Vector2(2,10),Vector2(31,8)),[GOLD,TEAL,PINK,GOLD][i])
				draw_circle(p+Vector2(6,16),4,INK)
				draw_circle(p+Vector2(21,16),4,INK)
		Content.Local.ZOMBIES:
			for i in 5:
				var p := Vector2(28+i*30,178+sin(clock*3+i)*4)
				draw_circle(p,5,Color("#a4bc68"))
				draw_rect(Rect2(p+Vector2(-5,2),Vector2(10,13)),Color("#646e49"))
		Content.Local.BED:
			for i in 3:
				var p := Vector2(fposmod(clock*89+i*59,205)-13,398+i*8)
				draw_rect(Rect2(p,Vector2(39,9)),[GOLD,TEAL,PINK][i])
				draw_rect(Rect2(p-Vector2(0,9),Vector2(4,16)),INK)
				draw_circle(p+Vector2(5,9),3,INK)
				draw_circle(p+Vector2(34,9),3,INK)
		Content.Local.LIZARD:
			var p := Vector2(66+sin(clock*1.3)*27,344)
			draw_line(p,p-Vector2(23,7+sin(clock*6)*3),Color("#799365"),4)
			draw_rect(Rect2(p-Vector2(7,6),Vector2(25,9)),Color("#789958"))
			draw_rect(Rect2(p+Vector2(14,-8),Vector2(10,6)),Color("#9da266"))
			draw_rect(Rect2(p+Vector2(21,-7),Vector2(2,2)),GOLD)
		Content.Local.DINO:
			var p := Vector2(15+sin(clock*.9)*14,175)
			draw_colored_polygon(PackedVector2Array([p,p+Vector2(123,19),p+Vector2(158,-85),p+Vector2(182,-96),p+Vector2(196,-86),p+Vector2(178,-75),p+Vector2(148,64),p+Vector2(55,62)]),Color("#3c354c"))
			draw_rect(Rect2(p+Vector2(25,64),Vector2(150,12)),Color("#7f524e"))
			draw_circle(p+Vector2(180,-86),3,GOLD)
