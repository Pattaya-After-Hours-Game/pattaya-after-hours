extends RefCounted
## Shared presentation catalog. No campaign state or simulation lives here.
const ROOT = "res://assets/art/"
const TYPES = ["beer", "soi", "gogo"]
const STAFF = ["dao", "mali", "fern", "nok", "jin", "pim"]
const HOSTS = ["bee", "may", "june", "lek", "fah", "nan"]
const FRIDGE_ORIGIN = Vector2i(800,160)
const FRIDGE_CELL = Vector2i(160,256)
const STREET_RECT = Rect2i(40,40,164,435)
static var street_masks: Dictionary = {}
# Appearance is independent of audience, spending budget and gameplay RNG.
const CUSTOMER_VARIANTS = [
	["patrons-men",0], ["patrons",1], ["patrons-men",2],
	["patrons-men",5], ["patrons-men",1], ["patrons-men",3],
	["patrons",0], ["patrons-men",4], ["patrons-men",6],
	["patrons",3], ["patrons-men",7], ["patrons-men",8]
]
# Names follow the original atlas identities; no save identity is reassigned.
const CUSTOMER_MOTION_NAMES = ["sunfaded-regular","silver-polo","maroon-casual","plum-club","sage-holiday","ivory-club","cobalt-evening","amber-local","beard-glasses","navy-tourist","teal-dress","gold-blouse","capybara","rainbow-duo"]
const COBALT_IDLE = 6
static var textures: Dictionary = {}
static var character_definitions: Dictionary = {}
const CUSTOMER_CATALOG = "res://assets/art/customer-characters.json"

static func customer_catalog() -> Dictionary:
	if character_definitions.is_empty() and FileAccess.file_exists(CUSTOMER_CATALOG):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUSTOMER_CATALOG))
		if parsed is Dictionary:
			for definition: Dictionary in parsed.values():
				for pose in definition.animations:
					definition.animations[pose] = definition.animations[pose].map(func(frame: Variant) -> int: return int(frame))
			character_definitions = parsed
	return character_definitions

static func customer_character_id(appearance: Array) -> String:
	var id := str(appearance[0])
	var catalog := customer_catalog()
	if catalog.has(id): return id
	var name := id.trim_prefix("customer-")
	if catalog.has(name) and str(catalog[name].atlas)==id: return name
	var motion_id := customer_motion_id(appearance)
	return "charcoal" if motion_id=="patrons-charcoal" else motion_id.trim_prefix("customer-motion-")

static func customer_visual(appearance: Array, state: String, time: float, fps: float = 8.0, phase: int = -1) -> Array:
	var definition: Dictionary = customer_catalog().get(customer_character_id(appearance),{})
	if definition.is_empty():
		var legacy := customer_motion_id(appearance)
		return [legacy,animation_frame(legacy,state,time,fps)]
	var frames: Array = definition.animations.get(state,definition.animations.idle)
	var index := phase if phase>=0 else int(time*fps)
	return [str(definition.atlas),int(frames[posmod(index,frames.size())])]

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

static func venue(kind: int, stage: int, has_fan: bool = true, has_screen: bool = false, fridge_tier: int = -1) -> Texture2D:
	kind = clampi(kind,0,2)
	stage = clampi(stage,1,3)
	var id := "%s-%d" % [TYPES[kind],stage]
	var original := texture(id)
	if original==null: return null
	var key := "%s#fan-%s#screen-%s#fridge-%d" % [id,has_fan,has_screen,fridge_tier]
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
		if fridge_tier>=0:
			var wall := texture("blue-hour-fridge-walls").get_image()
			var cabinet := texture("blue-hour-fridges").get_image()
			var wall_origin := Vector2i(stage-1,kind)*FRIDGE_CELL
			plate.blend_rect(wall,Rect2i(wall_origin,FRIDGE_CELL),FRIDGE_ORIGIN)
			plate.blend_rect(cabinet,Rect2i(Vector2i(fridge_tier*FRIDGE_CELL.x,0),FRIDGE_CELL),FRIDGE_ORIGIN)
		textures[key] = ImageTexture.create_from_image(plate)
	return textures[key]

static func frontage(kind: int, stage: int) -> Texture2D:
	return texture("frontage-%s-%d" % [TYPES[clampi(kind,0,2)],clampi(stage,1,3)])

static func street_mask(terrace: bool = false) -> Image:
	if not street_masks.has(terrace):
		# Conservative apertures protect posts, awnings, the threshold and terrace.
		var polygon := PackedVector2Array([Vector2(44,51),Vector2(50,50),Vector2(55,54),Vector2(60,57),Vector2(65,60),Vector2(70,61),Vector2(75,60),Vector2(80,67),Vector2(85,70),Vector2(90,72),Vector2(95,71),Vector2(100,73),Vector2(105,81),Vector2(110,82),Vector2(115,84),Vector2(120,84),Vector2(125,88),Vector2(130,91),Vector2(135,96),Vector2(140,98),Vector2(145,98),Vector2(150,103),Vector2(155,104),Vector2(160,109),Vector2(165,111),Vector2(170,113),Vector2(175,116),Vector2(180,122),Vector2(185,123),Vector2(190,127),Vector2(195,130),Vector2(198,131),Vector2(198,355),Vector2(44,468)])
		if terrace:
			polygon = PackedVector2Array([Vector2(180,193),Vector2(198,184),Vector2(198,278),Vector2(185,291),Vector2(185,252),Vector2(180,236)])
		var mask := Image.create(STREET_RECT.size.x,STREET_RECT.size.y,false,Image.FORMAT_RGBA8)
		for y in mask.get_height():
			for x in mask.get_width():
				if Geometry2D.is_point_in_polygon(Vector2(STREET_RECT.position)+Vector2(x+.5,y+.5),polygon):
					mask.set_pixel(x,y,Color.WHITE)
		street_masks[terrace] = mask
	return street_masks[terrace]

static func room_shell(backdrop: Texture2D, kind: int, stage: int) -> Texture2D:
	if backdrop==null: return null
	var key := "street-shell#%d" % backdrop.get_instance_id()
	if not textures.has(key):
		var room := backdrop.get_image().duplicate() as Image
		room.convert(Image.FORMAT_RGBA8)
		var mask := street_mask(kind==0 and stage==3)
		for y in mask.get_height():
			for x in mask.get_width():
				if mask.get_pixel(x,y).a>0:
					room.set_pixel(x+STREET_RECT.position.x,y+STREET_RECT.position.y,Color.TRANSPARENT)
		textures[key] = ImageTexture.create_from_image(room)
	return textures[key]

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
	var specs := {"anong-walk":[Vector2(128,192),16],"anong-service":[Vector2(160,192),4],"patrons":[Vector2(160,192),4],"patrons-men":[Vector2(160,192),12],"nida":[Vector2(160,192),4],"monster":[Vector2(320,320),4]}
	specs["patrons-capybara"] = [Vector2(224,192),5]
	specs["gabby"] = [Vector2(160,192),4]
	specs["daisy"] = [Vector2(160,256),6]
	specs["street-walkers"] = [Vector2(96,128),16]
	specs["patrons-charcoal"] = [Vector2(160,192),16]
	specs["street-charcoal"] = [Vector2(96,128),4]
	specs["street-charcoal-depth"] = [Vector2(96,128),8]
	specs["street-scooters"] = [Vector2(192,144),8]
	specs["street-cars"] = [Vector2(224,112),4]
	specs["street-walkers-depth"] = [Vector2(96,128),32]
	specs["street-scooters-depth"] = [Vector2(192,144),16]
	specs["street-cars-depth"] = [Vector2(224,112),8]
	specs["patrons-rainbow-duo"] = [Vector2(160,192),2]
	for id in STAFF: specs[id] = [Vector2(160,192),4]
	for id in HOSTS: specs[id] = [Vector2(160,256),6]
	for id in ["mali","juno","vega","orchid"]: specs["fight-"+id] = [Vector2(320,256),12]
	for name in CUSTOMER_MOTION_NAMES:
		var width := 288 if name=="rainbow-duo" else 256 if name=="capybara" else 160
		specs["customer-motion-"+name] = [Vector2(width,192),16]
		specs["street-customer-"+name] = [Vector2(192 if width>160 else 96,128),4]
		specs["street-customer-"+name+"-depth"] = [Vector2(192 if width>160 else 96,128),8]
	for name in CUSTOMER_MOTION_NAMES+["charcoal"]:
		var width := 288 if name=="rainbow-duo" else 256 if name=="capybara" else 160
		specs["customer-seated-"+name] = [Vector2(width,192),4]
	for definition: Dictionary in customer_catalog().values():
		specs[str(definition.atlas)] = [Vector2(definition.cell[0],definition.cell[1]),int(definition.frames)]
	return specs

static func customer_sprite(customer_id: int, appearance: String = "") -> Array:
	if appearance=="charcoal": return ["patrons-charcoal",12]
	if not appearance.is_empty() and customer_catalog().has(appearance): return [appearance,0]
	# The companion sprites appear on opening orders and rotate back in later.
	if customer_id%24==2: return ["patrons-capybara",0]
	if customer_id%32==3: return ["patrons-rainbow-duo",0]
	# Existing saved IDs keep a guest's look stable as other guests leave.
	return CUSTOMER_VARIANTS[(maxi(1,customer_id)-1)%CUSTOMER_VARIANTS.size()]

static func customer_motion_id(appearance: Array) -> String:
	if appearance[0]=="patrons-charcoal": return "patrons-charcoal"
	var name := ""
	match appearance[0]:
		"patrons-men": name = CUSTOMER_MOTION_NAMES[int(appearance[1])]
		"patrons": name = {0:"navy-tourist",1:"teal-dress",3:"gold-blouse"}.get(int(appearance[1]),"")
		"patrons-capybara": name = "capybara"
		"patrons-rainbow-duo": name = "rainbow-duo"
	return "customer-motion-"+name if not name.is_empty() else ""

static func customer_seated_id(appearance: Array) -> String:
	var id := customer_motion_id(appearance)
	return "customer-seated-charcoal" if id=="patrons-charcoal" else id.replace("customer-motion-","customer-seated-")

static func capybara_frame(time: float) -> int:
	var phase := fposmod(time,8.0)
	if phase>=1.50 and phase<1.68: return 1
	if phase>=3.0 and phase<3.22 or phase>=6.5 and phase<6.72: return 2
	if phase>=3.22 and phase<6.5:
		return 4 if phase>=4.8 and phase<4.98 else 3
	return 0

static func cobalt_frame(time: float) -> int:
	var phase := fposmod(time,16.0)
	if (phase>=5.0 and phase<5.22) or (phase>=10.22 and phase<10.44): return 9
	if (phase>=5.22 and phase<5.44) or (phase>=10.0 and phase<10.22): return 10
	if phase>=5.44 and phase<10.0: return 11
	return COBALT_IDLE

# Semantic animation catalog. Contact frames are selected by the combat simulator.
static func animation_frames(id: String, state: String) -> Array:
	var definition: Dictionary = customer_catalog().get(id.trim_prefix("customer-"),{})
	if not definition.is_empty() and str(definition.atlas)==id: return definition.animations.get(state,definition.animations.idle)
	if id.begins_with("customer-seated-"):
		return {"idle":[0],"drinking":[1],"chat":[2],"watch":[3]}.get(state,[0])
	if id=="patrons-charcoal" or id.begins_with("customer-motion-"):
		return {"idle":[12],"walk":[0,1,2,3],"walk_front":[4,5,6,7],"walk_back":[8,9,10,11],"drinking":[13],"chat":[14],"pool":[15]}.get(state,[12])
	# Customer-specific poses are selected by the street scene.
	if id.begins_with("patrons"): return [0]
	if id.begins_with("fight-"):
		return {"idle":[0],"walk":[1,2],"jump":[3],"guard":[4],"anticipation":[5],"jab":[6],"kick":[7],"burst":[8],"hit":[9],"ko":[10],"victory":[11]}.get(state,[0])
	if id == "monster": return {"arrival":[0,1],"idle":[1],"drinking":[2,1],"sleep":[3]}.get(state,[1])
	if id=="nida": return {"idle":[0],"welcome":[0,1,1,0,2,0,3,0]}.get(state,[0])
	if id in HOSTS or id=="daisy": return {"idle":[0],"carry":[1],"serve":[1,0],"dance":[2,3],"walk":[4,5]}.get(state,[0])
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
		if person.get("identity","")=="gabby": return "gabby"
		if person.role==3: return "nida"
		if person.role==1 and int(person.host)==6: return "daisy"
		if person.role==1: return HOSTS[clampi(int(person.host),0,HOSTS.size()-1)]
		if person.role==2: return HOSTS[index%HOSTS.size()]
		return STAFF[index%STAFF.size()]
	return HOSTS[index%HOSTS.size()] if bar.type>0 else STAFF[index%STAFF.size()]
