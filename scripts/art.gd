extends RefCounted
## Shared presentation catalog. No campaign state or simulation lives here.
const ROOT = "res://assets/art/"
const TYPES = ["beer", "soi", "gogo"]
const STAFF = ["dao", "mali", "fern", "nok", "jin", "pim"]
const HOSTS = ["bee", "may", "june", "lek", "fah", "nan"]
# Appearance is independent of audience, spending budget and gameplay RNG.
const CUSTOMER_VARIANTS = [
	["patrons-men",0], ["patrons",1], ["patrons-men",2],
	["patrons-men",5], ["patrons-men",1], ["patrons-men",3],
	["patrons",0], ["patrons-men",4], ["patrons-men",6],
	["patrons",3], ["patrons-men",7], ["patrons-men",8]
]
static var textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if not textures.has(id):
		var path := ROOT + id + ".png"
		if not ResourceLoader.exists(path): return null
		textures[id] = load(path)
	return textures[id]

static func fan_region(kind: int) -> Rect2i:
	if kind==0: return Rect2i(458,78,84,122)
	if kind==1: return Rect2i(238,60,56,84)
	return Rect2i(235,60,62,96)

static func screen_region(kind: int, stage: int) -> Rect2i:
	if kind==0:
		return Rect2i(395,180,81,54) if stage==3 else Rect2i(336,195,96,61)
	if kind==1:
		return Rect2i(421,193,96,61) if stage==1 else Rect2i(397,193,114,64)
	return Rect2i(300,147,96,61)

static func venue(kind: int, stage: int, has_fan: bool = true, has_screen: bool = false) -> Texture2D:
	kind = clampi(kind,0,2)
	stage = clampi(stage,1,3)
	var id := "%s-%d" % [TYPES[kind],stage]
	var original := texture(id)
	if original==null: return null
	var key := "%s#fan-%s#screen-%s" % [id,has_fan,has_screen]
	if not textures.has(key):
		var plate: Image = original.get_image().duplicate()
		plate.convert(Image.FORMAT_RGBA8)
		# Beer/gogo plates contain a fan; Soi plates need the purchased prop added.
		if has_fan!=(kind!=1):
			var patch := texture("wall-fan" if kind==1 else "fan-hidden-"+id)
			if patch!=null:
				var overlay: Image = patch.get_image().duplicate()
				overlay.convert(Image.FORMAT_RGBA8)
				plate.blend_rect(overlay,Rect2i(Vector2i.ZERO,overlay.get_size()),fan_region(kind).position)
		var screen := screen_region(kind,stage)
		if has_screen:
			# Reuse the finished sports TV from the production beer-bar artwork.
			# Renovated beer bars already contain it at their own fitted size.
			if kind!=0 or stage==1:
				var television := texture("beer-2").get_image().get_region(screen_region(0,2))
				television.convert(Image.FORMAT_RGBA8)
				television.resize(screen.size.x,screen.size.y,Image.INTERPOLATE_NEAREST)
				plate.blit_rect(television,Rect2i(Vector2i.ZERO,television.get_size()),screen.position)
		elif kind==0 and stage>1:
			# The fitted bezel remains, but its display is off until purchased.
			plate.fill_rect(screen.grow(-4),Color("#171824"))
		textures[key] = ImageTexture.create_from_image(plate)
	return textures[key]

static func frontage(kind: int, stage: int) -> Texture2D:
	return texture("frontage-%s-%d" % [TYPES[clampi(kind,0,2)],clampi(stage,1,3)])

static func image(canvas: CanvasItem, id: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var tex := texture(id)
	if tex: canvas.draw_texture_rect(tex,rect,false,tint)

static func frame(canvas: CanvasItem, id: String, index: int, foot: Vector2, scale_value: float = 1.0, flip: bool = false, cell: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, stretch: Vector2 = Vector2.ONE) -> void:
	var tex := texture(id)
	if tex == null: return
	if cell == Vector2.ZERO: cell = atlas_specs().get(id,[Vector2(160,192)])[0]
	var cols := maxi(1,int(tex.get_width()/cell.x))
	var count := cols*maxi(1,int(tex.get_height()/cell.y))
	index = clampi(index,0,count-1)
	var region := Rect2(Vector2(index%cols,index/cols)*cell,cell)
	var dest := Rect2(foot-Vector2(cell.x*.5,cell.y-4)*scale_value*stretch,cell*scale_value*stretch)
	if flip:
		dest.size.x = -dest.size.x
	canvas.draw_texture_rect_region(tex,dest,region,tint)

static func atlas_specs() -> Dictionary:
	var specs := {"anong-walk":[Vector2(128,192),16],"anong-service":[Vector2(160,192),4],"patrons":[Vector2(160,192),4],"patrons-men":[Vector2(160,192),9],"nida":[Vector2(160,192),4],"monster":[Vector2(320,320),4]}
	specs["patrons-capybara"] = [Vector2(224,192),1]
	specs["patrons-rainbow-duo"] = [Vector2(160,192),1]
	for id in STAFF: specs[id] = [Vector2(160,192),4]
	for id in HOSTS: specs[id] = [Vector2(160,256),6]
	for id in ["mali","juno","vega","orchid"]: specs["fight-"+id] = [Vector2(320,256),12]
	return specs

static func customer_sprite(customer_id: int) -> Array:
	# The companion sprites appear on opening orders and rotate back in later.
	if customer_id%24==2: return ["patrons-capybara",0]
	if customer_id%32==3: return ["patrons-rainbow-duo",0]
	# Existing saved IDs keep a guest's look stable as other guests leave.
	return CUSTOMER_VARIANTS[(maxi(1,customer_id)-1)%CUSTOMER_VARIANTS.size()]

# Semantic animation catalog. Contact frames are selected by the combat simulator.
static func animation_frames(id: String, state: String) -> Array:
	# Patron cells are separate appearances, not an animation sequence.
	if id.begins_with("patrons"): return [0]
	if id.begins_with("fight-"):
		return {"idle":[0],"walk":[1,2],"jump":[3],"guard":[4],"anticipation":[5],"jab":[6],"kick":[7],"burst":[8],"hit":[9],"ko":[10],"victory":[11]}.get(state,[0])
	if id == "monster": return {"arrival":[0,1],"idle":[1],"drinking":[2,1],"sleep":[3]}.get(state,[1])
	if id=="nida": return {"idle":[0],"welcome":[0,1,1,0,2,0,3,0]}.get(state,[0])
	if id in HOSTS: return {"idle":[0],"carry":[1],"serve":[1,0],"dance":[2,3],"walk":[4,5]}.get(state,[0])
	return {"idle":[0],"walk":[1,2],"carry":[3],"serve":[3,0]}.get(state,[0])

static func animation_frame(id: String, state: String, time: float, fps: float = 5.0) -> int:
	var frames := animation_frames(id,state)
	return frames[int(time*fps)%frames.size()]

static func event_treatment(id: int) -> String:
	return ["blackout","shore-leave","inspection","flood","songkran","bar-crawl","low-season","rival-promotion","monster-arrival","festival"][clampi(id,0,9)]

# Stable identity follows the host assignment, not their position in a mixed team.
static func worker_id(bar: Dictionary, index: int) -> String:
	if bar.has("team") and index<bar.team.size():
		var person: Dictionary = bar.team[index]
		if person.role==3: return "nida"
		if person.role==1: return HOSTS[clampi(int(person.host),0,HOSTS.size()-1)]
		if person.role==2: return HOSTS[index%HOSTS.size()]
		return STAFF[index%STAFF.size()]
	return HOSTS[index%HOSTS.size()] if bar.type>0 else STAFF[index%STAFF.size()]
