extends Control
const Art = preload("res://scripts/art.gd")
const Economy = preload("res://scripts/economy.gd")
const Content = preload("res://scripts/street_content.gd")
const INK = Color("#21131e")
const TEAL = Color("#73f5dc")
const PINK = Color("#f37ab0")
const GOLD = Color("#e8ba7b")
const ORDER_URGENT = Color("#ff514d")
var clock := 0.0
var street_state: Dictionary = {}
var arrival_time := 0.0
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
var legacy_staff: Array = []
var font = ThemeDB.fallback_font
signal site(tab: int)
signal select_bar(index: int)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	arrival_time += delta
	service_flash = maxf(0,service_flash-delta)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	var bar: Dictionary = bars[selected_bar] if not bars.is_empty() else {"type":0,"stage":clampi(level,1,3),"crew":legacy_staff.size(),"away":[],"closed":0,"name":"Blue Hour"}
	var kind := int(bar.type)
	var stage := int(bar.stage)
	var backdrop := Art.venue(kind,stage,fan_owned(bar),screen_owned(bar))
	if backdrop: draw_texture_rect(backdrop,Rect2(0,0,960,540),false)
	if celebrating: _draw_celebration()
	var closed := not Economy.trading(bar,int(street_state.get("minute",720)))
	# Only the street opening contains ambient traffic. Interior sprites come
	# from the actual customers and available team, sorted by their floor depth.
	_draw_passerby(kind,stage)
	var people := scene_people(bar)
	for person in people:
		if person.behind_bar: _draw_person(person)
	# Reuse the bar fronts from the same production plate to hide staff legs.
	# Customers are drawn afterwards, on the public side of the counter.
	if backdrop:
		for region in counter_regions(kind,stage):
			draw_texture_rect_region(backdrop,region,region)
	if kind==0 and bar.get("equipment",{}).get("seating",0)==3: _draw_compact_layout()
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
		if person.get("chat_until",0.0)>float(street_state.get("elapsed",0))+float(street_state.get("tick_fraction",0.0)):
			var feedback := order_position(person)+Vector2(-31,-14)
			draw_style_box(_sign_box(),Rect2(feedback-Vector2(4,15),Vector2(78,21)))
			draw_string(font,feedback,"+10s · chat",HORIZONTAL_ALIGNMENT_LEFT,-1,12,TEAL)
		if person.order:
			var marker := order_position(person)
			draw_circle(marker,6,INK)
			draw_circle(marker,4,order_color(person.order_seconds_left))
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
	# Foreground bar layer occludes the bartender's legs, never the interface.
	Art.image(self,"counter",Rect2(650,344,310,92))
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
	if not person.behind_bar: draw_circle(Vector2.ZERO,18*scale_value,Color(0,0,0,.24))
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	Art.frame(self,person.who,person.pose,foot,scale_value,person.flip)

static func counter_regions(kind: int, stage: int) -> Array[Rect2]:
	if kind==0:
		if stage==1: return [Rect2(250,270,300,85),Rect2(665,290,180,110)]
		return [Rect2(440,278,400,120)]
	return [Rect2(665,290,180,110)]

func _draw_passerby(kind: int, stage: int) -> void:
	# The stage-three beer bar has a furnished terrace in this opening.
	if kind==0 and stage==3: return
	var passerby := passerby_at(clock)
	var tint := Color(.72,.80,.92,passerby.alpha)
	Art.frame(self,"patrons",passerby.pose,passerby.foot,passerby.scale,passerby.flip,Vector2.ZERO,tint)

static func passerby_at(time: float) -> Dictionary:
	# Cells 0 and 2 depict the same man. Choose distinct appearances per
	# crossing, never per animation frame, and leave a gap between people.
	# This visual clock does not consume campaign RNG or create customers.
	var cycle := int(maxf(0,time)/24.0)
	var progress := clampf(fposmod(maxf(0,time),24.0)/20.0,0,1)
	var approaching := cycle%2==0
	var depth := progress if approaching else 1-progress
	return {
		"pose":[2,3,1][cycle%3],
		"foot":Vector2(183,278).lerp(Vector2(122,355),depth),
		"scale":lerpf(.36,.56,depth),
		"flip":approaching,
		"alpha":smoothstep(0,.12,progress)*(1-smoothstep(.88,1,progress))
	}

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
	var crowd: int = bar.customers.size() if bar.has("customers") else mini(8,guests)
	for i in crowd:
		# Fill spaced positions first; busy venues add staggered rows. All slots
		# stay inside the doorway and above the property dock (scene y=373).
		var columns := [300,440,580,370,510,650,720,790]
		var row := i/8
		var foot := Vector2(columns[i%8]+(15 if row%2 else 0),362-row*19)
		if kind==2:
			# Keep guests off the raised performance stage.
			foot.y = 366-row*9
		if bar.has("customers") and bar.customers[i].playing:
			for game in bar.games:
				var player: int = game.players.find(bar.customers[i].id)
				if player>=0: foot = Vector2(250+int(game.get("table",0))*200+player*205,355+int(game.get("table",0))*12)
		var customer_id: int = int(bar.customers[i].id) if bar.has("customers") else i+1
		var appearance := Art.customer_sprite(customer_id)
		people.append({"who":appearance[0],"pose":appearance[1],"foot":foot,"flip":customer_id%2==0,"order":bar.has("customers") and bar.customers[i].order,"customer":true,"customer_id":customer_id,"chat_until":bar.customers[i].get("chat_until",0.0) if bar.has("customers") else 0.0,"behind_bar":false})
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
