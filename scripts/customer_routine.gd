extends RefCounted
## Visible guest choreography only. Never runs the economy or consumes RNG.
const Art = preload("res://scripts/art.gd")
const SPEED = 58.0
const AISLE_Y = 368.0
const SEAT_GAP = 12.0
static var seated_shapes := {}

static func seats(bar: Dictionary) -> Array[Vector2]:
	# Cushion positions follow the production room plates. On tall bar stools
	# shoes can sit behind the property dock, like the stool legs themselves.
	var xs: Array
	var y: float
	match int(bar.type):
		0:
			xs = [294,342,389,435,482,529] if int(bar.stage)==1 else [444,505,566,628,690]
			y = 365.0 if int(bar.stage)==1 else 387.0
		1:
			xs = [340,388,438,485,532,580] if int(bar.stage)==1 else [350,394,438,482,526,570]
			y = 390.0 if int(bar.stage)==1 else 366.0
		_:
			xs = [260,302,346,390,550,594,638,680]
			y = 370.0
	var result: Array[Vector2] = []
	for x in xs: result.append(Vector2(x,y))
	return result

static func home(kind: int, slot: int) -> Vector2:
	var columns := [300,440,580,370,510,650,720,790]
	var row := slot/8
	return Vector2(columns[slot%8]+(15 if row%2 else 0),366-row*9 if kind==2 else 362-row*19)

static func pool_foot(bar: Dictionary, guest: Dictionary, fallback: Vector2) -> Vector2:
	if guest.get("playing",false):
		for game in bar.get("games",[]):
			var player: int = game.players.find(guest.id)
			if player>=0: return Vector2(250+int(game.get("table",0))*200+player*205,355+int(game.get("table",0))*12)
	return fallback

static func bar_foot(bar: Dictionary, position: int) -> Vector2:
	# Front places stand on the public side of the illustrated counter. Overflow
	# is a visual line of real pending orders, never an extra admission queue.
	var points: Array = [Vector2(705,366),Vector2(770,366),Vector2(825,366)] if int(bar.type)==0 and int(bar.stage)==1 else [Vector2(745,366),Vector2(805,366)] if int(bar.type)==0 else [Vector2(720,366),Vector2(775,366),Vector2(825,366)]
	if position<points.size(): return points[position]
	var n := position-points.size()
	return Vector2(635-(n%6)*61,maxi(344,364-(n/6)*5))

static func watch_foot(bar: Dictionary, position: int) -> Vector2:
	var screen := Art.screen_region(int(bar.type),int(bar.stage))
	return Vector2(clampf(screen.get_center().x+position*62-30,270,790),357)

static func hosted_foot(bar: Dictionary, guest: Dictionary) -> Vector2:
	for round in bar.get("host_rounds",[]):
		if int(round.get("guest",-1))==int(guest.id):
			var floor_index := 0
			for index in mini(int(round.get("host",0)),bar.get("team",[]).size()):
				var worker: Dictionary = bar.team[index]
				if worker.get("on",false) and not index in bar.get("away",[]) and int(worker.get("role",0))==1: floor_index += 1
			return Vector2(599+(floor_index%3)*66,364-(floor_index/3)*12)
	return Vector2.ZERO

static func seat_envelope(appearance: Array, foot: Vector2, flip: bool) -> Rect2:
	return actor_envelope(appearance,foot,flip,true)

static func actor_envelope(appearance: Array, foot: Vector2, flip: bool, seated: bool = false) -> Rect2:
	var definition: Dictionary = Art.customer_catalog().get(Art.customer_character_id(appearance),{})
	var id: String = definition.get("atlas",Art.customer_seated_id(appearance))
	var key := id+("#seated" if seated else "#standing")
	if not seated_shapes.has(key):
		var cell: Vector2 = Art.atlas_specs()[id][0]
		var image := Art.texture(id).get_image()
		var columns := int(image.get_width()/cell.x)
		var frames: Array = [0,1,2]
		if not definition.is_empty():
			frames = []
			var poses := ["seated_idle","seated_drinking","seated_chat","beer_seated_idle","beer_seated_drinking"] if seated else ["idle","chat","beer_stand"]
			for pose in poses:
				frames.append_array(definition.animations.get(pose,[]))
		var bounds := Rect2i()
		var first := true
		for index in frames:
			var origin := Vector2i(int(index)%columns,int(index)/columns)*Vector2i(cell)
			var used := image.get_region(Rect2i(origin,Vector2i(cell))).get_used_rect()
			bounds = used if first else bounds.merge(used)
			first = false
		seated_shapes[key] = Rect2(Vector2(bounds.position)-Vector2(cell.x*.5,cell.y-4),Vector2(bounds.size))
	var shape: Rect2 = seated_shapes[key]
	if flip: shape.position.x = -shape.end.x
	var scale_value := clampf(.75+(foot.y-300)*.0022,.70,1.04)
	return Rect2(foot+shape.position*scale_value,shape.size*scale_value).grow(SEAT_GAP*.5)

static func plan_route(from: Vector2, to: Vector2) -> Array[Vector2]:
	# Walk in front of the pool tables and counters instead of cutting across
	# their tops. Short changes within a group need no trip around the room.
	if from.distance_to(to)<26 or minf(from.y,to.y)>=365: return [to]
	var result: Array[Vector2] = []
	for point in [Vector2(from.x,AISLE_Y),Vector2(to.x,AISLE_Y),to]:
		if (result.is_empty() and from.distance_to(point)>.5) or (not result.is_empty() and result.back().distance_to(point)>.5): result.append(point)
	return result

static func step(record: Dictionary, delta: float) -> void:
	var distance := maxf(0,delta)*SPEED
	record.moving = false
	while not record.route.is_empty():
		var point: Vector2 = record.route[0]
		var offset: Vector2 = point-record.foot
		if offset.length()<=.00001:
			record.foot = point
			record.route.pop_front()
			continue
		if distance<=0: break
		# Tiny final adjustments should not flash a front/rear pose for one frame.
		if offset.length()>8 or Vector2(record.direction)==Vector2.ZERO: record.direction = offset.normalized()
		record.moving = true
		var used := minf(distance,offset.length())
		var next_foot: Vector2 = record.foot.move_toward(point,used)
		record.walk_distance = float(record.get("walk_distance",0.0))+used/Art.person_scale((record.foot.y+next_foot.y)*.5)
		record.foot = next_foot
		distance -= used
		record.walk_distance = float(record.get("walk_distance",0))+used
		if record.foot.distance_to(point)<=.00001:
			record.foot = point
			record.route.pop_front()
		else: break
	record.moving = not record.route.is_empty()
	if not record.moving: record.dwell += maxf(0,delta)

static func update(bar: Dictionary, records: Dictionary, delta: float, seed: bool, now: float) -> void:
	var guests: Array = bar.get("customers",[]).duplicate()
	guests.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.id)<int(b.id))
	var live := {}
	var appearances := {}
	for guest in guests:
		live[int(guest.id)] = true
		appearances[int(guest.id)] = Art.customer_sprite(int(guest.id),str(guest.get("appearance","")))
	for id in records.keys():
		if not live.has(id): records.erase(id)
	var new_ids := {}
	var occupied := {}
	for record in records.values(): occupied[int(record.slot)] = true
	for guest in guests:
		var id := int(guest.id)
		if not records.has(id):
			new_ids[id] = true
			var slot := 0
			while occupied.has(slot): slot += 1
			occupied[slot] = true
			records[id] = {"slot":slot,"foot":Vector2(242,362),"direction":Vector2.RIGHT,"moving":false,"route":[],"target":Vector2(242,362),"activity":"enter","dwell":0.0,"choice":0,"was_order":false,"was_playing":false,"partner":-1,"walk_distance":0.0}
	# Stable occupied slots keep every survivor's seat through queue reordering.
	guests.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(records[int(a.id)].slot)<int(records[int(b.id)].slot))
	var chair_points := seats(bar)
	var reserved := {}
	var envelopes: Array[Rect2] = []
	for guest in guests:
		var record: Dictionary = records[int(guest.id)]
		var appearance: Array = appearances[int(guest.id)]
		record.span = int(Art.customer_catalog().get(Art.customer_character_id(appearance),{}).get("seat_span",1))
		var index: int = record.get("chair",-1)
		if index>=0 and index+int(record.span)<=chair_points.size():
			var seat := (chair_points[index]+chair_points[index+int(record.span)-1])*.5
			var envelope := seat_envelope(appearance,seat,int(guest.id)%2==0)
			if envelopes.any(func(other: Rect2) -> bool: return other.intersects(envelope)):
				record.chair = -1
			else:
				for n in int(record.span): reserved[index+n] = true
				envelopes.append(envelope)
		else: record.chair = -1
	for guest in guests:
		var record: Dictionary = records[int(guest.id)]
		if int(record.get("chair",-1))>=0: continue
		var appearance: Array = appearances[int(guest.id)]
		for index in chair_points.size():
			if index+int(record.span)>chair_points.size(): break
			var available := true
			for n in int(record.span):
				if reserved.has(index+n): available = false
			if record.span==2 and chair_points[index].distance_to(chair_points[index+1])>90: available = false
			var seat := (chair_points[index]+chair_points[index+int(record.span)-1])*.5
			var envelope := seat_envelope(appearance,seat,int(guest.id)%2==0)
			if envelopes.any(func(other: Rect2) -> bool: return other.intersects(envelope)): available = false
			if available:
				record.chair = index
				for n in int(record.span): reserved[index+n] = true
				envelopes.append(envelope)
				break
	var pending := 0
	var watchers := 0
	var minglers: Array = []
	var plans := {}
	for guest in guests:
		var id := int(guest.id)
		var record: Dictionary = records[id]
		record.partner = -1
		var base := home(int(bar.type),int(record.slot))
		base.y = maxf(348,base.y)
		var seat := Vector2.ZERO
		var chair: int = record.get("chair",-1)
		if chair>=0: seat = (chair_points[chair]+chair_points[chair+int(record.span)-1])*.5
		record.seat = seat
		if (record.was_order and not guest.get("order",false)) or (record.was_playing and not guest.get("playing",false)):
			record.choice = 0
			record.dwell = 0.0
		record.was_order = guest.get("order",false)
		record.was_playing = guest.get("playing",false)
		var activity := "stand"
		var target := base
		var hosted := hosted_foot(bar,guest)
		if guest.get("playing",false):
			activity = "pool"
			target = pool_foot(bar,guest,base)
		elif hosted!=Vector2.ZERO:
			activity = "host"
			target = hosted
		elif guest.get("order",false):
			activity = "order"
			target = bar_foot(bar,pending)
			pending += 1
		elif now<float(guest.get("chat_until",0)):
			activity = "chat"
			target = record.foot
		elif int(guest.get("pool_wait",0))>0 and guest.get("pool",false) and not guest.get("played",false) and int(bar.get("equipment",{}).get("pool",0))>0:
			activity = "pool_wait"
			target = Vector2(290+(int(record.slot)%3)*50,364)
		else:
			# Relax first, then choose another activity after a real visible dwell.
			# The phase is deterministic per visitor and never calls model RNG.
			if float(record.dwell)>=10.0+float(id%4)*2.0:
				record.choice = int(record.choice)+1
				record.dwell = 0.0
			var choice := int(record.choice)%3
			if choice==2 and int(bar.get("equipment",{}).get("screen",0))>0 and watchers<2:
				activity = "watch"
				target = watch_foot(bar,watchers)
				watchers += 1
			elif choice==1 or seat==Vector2.ZERO:
				activity = "mingle"
				minglers.append(id)
			else:
				activity = "seat"
				target = seat
		plans[id] = {"activity":activity,"target":target}
	# Reserve body space for actual seated destinations, then place conversations
	# and standing overflow in the remaining floor area rather than on their laps.
	var floor_occupied: Array[Rect2] = []
	for guest in guests:
		var id := int(guest.id)
		if plans[id].activity=="seat":
			floor_occupied.append(seat_envelope(appearances[id],plans[id].target,id%2==0))
	for i in range(0,minglers.size(),2):
		var id: int = minglers[i]
		plans[id].activity = "stand"
		if i+1>=minglers.size(): continue
		var other: int = minglers[i+1]
		plans[other].activity = "stand"
		if i>=6: continue
		var left := actor_envelope(appearances[id],Vector2.ZERO,false)
		var right := actor_envelope(appearances[other],Vector2.ZERO,true)
		var separation := maxf(80,left.end.x-right.position.x)
		var candidates: Array = [350.0,545.0,725.0]
		for x in range(260,801,10): candidates.append(float(x))
		for x: float in candidates:
			var left_foot := Vector2(x-separation*.5,363)
			var right_foot := Vector2(x+separation*.5,363)
			var area := Rect2(left.position+left_foot,left.size).merge(Rect2(right.position+right_foot,right.size))
			if area.position.x<240 or area.end.x>830: continue
			if floor_occupied.any(func(occupied_area: Rect2) -> bool: return occupied_area.intersects(area)): continue
			plans[id] = {"activity":"mingle","target":left_foot}
			plans[other] = {"activity":"mingle","target":right_foot}
			records[id].partner = other
			records[other].partner = id
			floor_occupied.append(area)
			break
	for guest in guests:
		var id := int(guest.id)
		if plans[id].activity!="stand": continue
		var appearance: Array = appearances[id]
		var candidates: Array[Vector2] = [plans[id].target]
		for x in range(260,801,10): candidates.append(Vector2(x,363))
		for point in candidates:
			var area := actor_envelope(appearance,point,id%2==0)
			if area.position.x<240 or area.end.x>830: continue
			if floor_occupied.any(func(occupied_area: Rect2) -> bool: return occupied_area.intersects(area)): continue
			plans[id].target = point
			floor_occupied.append(area)
			break
	for guest in guests:
		var id := int(guest.id)
		var record: Dictionary = records[id]
		var plan: Dictionary = plans[id]
		if seed and new_ids.has(id):
			record.foot = plan.target
			record.target = plan.target
			record.route = []
			record.moving = false
		elif record.target!=plan.target:
			record.target = plan.target
			record.route = plan_route(record.foot,plan.target)
			record.dwell = 0.0
		record.activity = plan.activity
		step(record,delta)
