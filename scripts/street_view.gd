extends RefCounted
## Read-only outdoor presentation. Never admits customers or consumes model RNG.
const Economy = preload("res://scripts/economy.gd")
const Art = preload("res://scripts/art.gd")
const GUEST_BANDS = [0,1,3,6,10,16,24,36]
const NAMES = ["Quiet","Sleepy","Warming up","Steady","Lively","Busy","Buzzing","Packed"]
const TIME_STARTS = [0,180,300,420,660,1020,1140,1260]
const TIME_NAMES = ["Late night","Before dawn","Dawn","Morning","Daylight","Sunset","Dusk","Night"]
const PEDESTRIANS = [0,1,3,6,10,16,24,36]
const SCOOTERS = [0,0,1,1,2,3,4,6]
const CARS = [0,0,0,1,1,1,2,3]

static func live_guests(state: Dictionary) -> int:
	var count := 0
	for bar: Dictionary in state.get("bars",[]):
		if Economy.trading(bar,int(state.get("minute",720))): count += bar.get("customers",[]).size()
	return count

static func activity(state: Dictionary) -> int:
	return band(live_guests(state),GUEST_BANDS)

static func period(minute: int) -> int:
	return band(posmod(minute,1440),TIME_STARTS)

static func band(value: int, starts: Array) -> int:
	var result := 0
	for i in starts.size():
		if value>=starts[i]: result = i
	return result

static func traffic(level: int, time: float, closeup: bool = false, terrace: bool = false) -> Array[Dictionary]:
	level = clampi(level,0,7)
	var items: Array[Dictionary] = []
	var counts := [PEDESTRIANS[level],SCOOTERS[level],CARS[level]]
	if closeup:
		counts = [[0,1,1,2,3,4,5,7][level],[0,0,1,1,1,2,2,3][level],[0,0,0,0,1,1,1,2][level]]
	for kind in 3:
		for i: int in int(counts[kind]):
			var duration: float = [22.0,11.0,15.0][kind]*(1.0+.07*(i%4))
			# Existing actors keep their route phase when a busier band adds more.
			var phase := fposmod(time/duration+i*.61803398875+kind*.31,1.0)
			var cycle := floori(time/duration+i*.61803398875+kind*.31)
			var forward: bool = (i+cycle)%2==0 if closeup else i%2==0
			var depth := phase if forward else 1.0-phase
			var foot: Vector2
			var scale_value: float
			if closeup:
				foot = Vector2(190,266).lerp(Vector2(117,372),depth)
				if kind==0: foot.x += 10 if forward else -9
				scale_value = lerpf(.27,.59,depth) if kind==0 else lerpf(.20,.49,depth)
				if terrace:
					foot = Vector2(193,215).lerp(Vector2(183,281),depth)
					scale_value *= .42
			else:
				var lane: int = i%3 if kind==0 else 1+i%2
				var width: float = 274 if lane==0 else 900
				foot = Vector2(30+depth*width,[177,346,510][lane])
				if kind==0: foot.y -= 7+i%2*9
				scale_value = [.30,.30,.31][kind]
			var id: String = ["street-walkers","street-scooters","street-cars"][kind]
			var row: int = i%5 if kind==0 else i%2 if kind==1 else 0
			var charcoal: bool = kind==0 and row==4
			if closeup:
				id += "-depth"
				# Front/rear are authored views, never mirrored side profiles.
				# Change identity only at the invisible end of a crossing.
				var identities: int = [5,2,1][kind]
				var identity := posmod(i/2+cycle,identities)
				charcoal = kind==0 and identity==4
				row = (0 if charcoal else identity)*2+(0 if forward else 1)
			if charcoal:
				id = "street-charcoal-depth" if closeup else "street-charcoal"
				if not closeup: row = 0
			var frame := row*4+posmod(int(time*(7 if kind==0 else 5))+i,4)
			var alpha := smoothstep(0,.07,phase)*(1-smoothstep(.93,1,phase))
			var tint := Color(.48,.51,.59,alpha) if closeup and kind==0 else Color(1,1,1,alpha)
			items.append({"key":"%d/%d" % [kind,i],"id":id,"frame":frame,"foot":foot,"scale":scale_value,"flip":false if closeup else not forward,"facing":("front" if forward else "back") if closeup else ("right" if forward else "left"),"tint":tint})
	items.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.foot.y<b.foot.y)
	return items

static func draw_traffic(canvas: CanvasItem, level: int, time: float, closeup: bool = false, terrace: bool = false) -> void:
	for item in traffic(level,time,closeup,terrace):
		Art.frame(canvas,item.id,item.frame,item.foot,item.scale,item.flip,Vector2.ZERO,item.tint)
