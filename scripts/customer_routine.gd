extends RefCounted
## Visible guest choreography only. Never runs the economy or consumes RNG.
const Art = preload("res://scripts/art.gd")
const SPEED = 58.0
const AISLE_Y = 368.0

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

static func plan_route(from: Vector2, to: Vector2) -> Array[Vector2]:
	# Walk in front of the pool tables and counters instead of cutting across
	# their tops. Short changes within a group need no trip around the room.
	if from.distance_to(to)<26: return [to]
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
		if offset.length()<=.5:
			record.foot = point
			record.route.pop_front()
			continue
		if distance<=0: break
		record.direction = offset.normalized()
		record.moving = true
		var used := minf(distance,offset.length())
		record.foot = record.foot.move_toward(point,used)
		distance -= used
		if record.foot.distance_to(point)<=.5:
			record.foot = point
			record.route.pop_front()
		else: break
	record.moving = not record.route.is_empty()
	if not record.moving: record.dwell += maxf(0,delta)

static func update(bar: Dictionary, records: Dictionary, delta: float, seed: bool, now: float) -> void:
	var guests: Array = bar.get("customers",[]).duplicate()
	guests.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.id)<int(b.id))
	var live := {}
	for guest in guests: live[int(guest.id)] = true
	for id in records.keys():
		if not live.has(id): records.erase(id)
	var occupied := {}
	for record in records.values(): occupied[int(record.slot)] = true
	for guest in guests:
		var id := int(guest.id)
		if not records.has(id):
			var slot := 0
			while occupied.has(slot): slot += 1
			occupied[slot] = true
			records[id] = {"slot":slot,"foot":Vector2(242,362),"direction":Vector2.RIGHT,"moving":false,"route":[],"target":Vector2(242,362),"activity":"enter","dwell":0.0,"choice":0,"was_order":false,"was_playing":false,"partner":-1}
	# Stable occupied slots keep every survivor's seat through queue reordering.
	guests.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(records[int(a.id)].slot)<int(records[int(b.id)].slot))
	var chair_points := seats(bar)
	var reserved := {}
	for guest in guests:
		var record: Dictionary = records[int(guest.id)]
		var appearance := Art.customer_sprite(int(guest.id),str(guest.get("appearance","")))
		record.span = 2 if appearance[0]=="patrons-rainbow-duo" else 1
		var index: int = record.get("chair",-1)
		if index>=0 and index+int(record.span)<=chair_points.size():
			for n in int(record.span): reserved[index+n] = true
		else: record.chair = -1
	for guest in guests:
		var record: Dictionary = records[int(guest.id)]
		if int(record.get("chair",-1))>=0: continue
		for index in chair_points.size():
			if index+int(record.span)>chair_points.size(): break
			var available := true
			for n in int(record.span):
				if reserved.has(index+n): available = false
			if record.span==2 and chair_points[index].distance_to(chair_points[index+1])>90: available = false
			if available:
				record.chair = index
				for n in int(record.span): reserved[index+n] = true
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
	# Conversation requires another available, actual guest. Neither participant
	# can be waiting at the counter, playing pool or busy with a host.
	for i in range(0,minglers.size(),2):
		var id: int = minglers[i]
		if i+1>=minglers.size() or i>=6:
			plans[id].activity = "stand"
			if i+1<minglers.size(): plans[int(minglers[i+1])].activity = "stand"
			continue
		var other: int = minglers[i+1]
		var center := Vector2([350,545,725][i/2],363)
		plans[id].target = center-Vector2(35,0)
		plans[other].target = center+Vector2(35,0)
		records[id].partner = other
		records[other].partner = id
	for guest in guests:
		var id := int(guest.id)
		var record: Dictionary = records[id]
		var plan: Dictionary = plans[id]
		if seed:
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
