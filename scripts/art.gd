extends RefCounted
## Shared presentation catalog. No campaign state or simulation lives here.
const ROOT = "res://assets/art/"
const TYPES = ["beer", "soi", "gogo"]
const STAFF = ["dao", "mali", "fern", "nok", "jin", "pim"]
const HOSTS = ["bee", "may", "june", "lek", "fah", "nan"]
static var textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if not textures.has(id):
		var path := ROOT + id + ".png"
		if not ResourceLoader.exists(path): return null
		textures[id] = load(path)
	return textures[id]

static func venue(kind: int, stage: int) -> Texture2D:
	return texture("%s-%d" % [TYPES[clampi(kind,0,2)],clampi(stage,1,3)])

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
		dest.position.x += dest.size.x
		dest.size.x = -dest.size.x
	canvas.draw_texture_rect_region(tex,dest,region,tint)

static func atlas_specs() -> Dictionary:
	var specs := {"anong-walk":[Vector2(128,192),16],"anong-service":[Vector2(160,192),4],"patrons":[Vector2(160,192),4],"monster":[Vector2(320,320),4]}
	for id in STAFF: specs[id] = [Vector2(160,192),4]
	for id in HOSTS: specs[id] = [Vector2(160,256),6]
	for id in ["mali","juno","vega","orchid"]: specs["fight-"+id] = [Vector2(320,256),12]
	return specs

# Semantic animation catalog. Contact frames are selected by the combat simulator.
static func animation_frames(id: String, state: String) -> Array:
	if id.begins_with("fight-"):
		return {"idle":[0],"walk":[1,2],"jump":[3],"guard":[4],"anticipation":[5],"jab":[6],"kick":[7],"burst":[8],"hit":[9],"ko":[10],"victory":[11]}.get(state,[0])
	if id == "monster": return {"arrival":[0,1],"idle":[1],"drinking":[2,1],"sleep":[3]}.get(state,[1])
	if id in HOSTS: return {"idle":[0],"carry":[1],"serve":[1,0],"dance":[2,3],"walk":[4,5]}.get(state,[0])
	return {"idle":[0],"walk":[1,2],"carry":[3],"serve":[3,0]}.get(state,[0])

static func animation_frame(id: String, state: String, time: float, fps: float = 5.0) -> int:
	var frames := animation_frames(id,state)
	return frames[int(time*fps)%frames.size()]

static func event_treatment(id: int) -> String:
	return ["blackout","shore-leave","inspection","flood","songkran","bar-crawl","low-season","rival-promotion","monster-arrival","festival"][clampi(id,0,9)]
