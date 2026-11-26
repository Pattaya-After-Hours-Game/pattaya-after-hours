extends RefCounted

# Warning rats follow the floor, furniture, shelving and wall trim.
const LANES = [
	[Vector2(13,387),Vector2(618,412)],
	[Vector2(306,356),Vector2(954,391)],
	[Vector2(660,207),Vector2(927,193)],
	[Vector2(634,74),Vector2(643,365)],
	[Vector2(257,289),Vector2(603,312)],
	[Vector2(278,168),Vector2(593,212)],
	[Vector2(19,121),Vector2(25,402)],
]
const Content = preload("res://scripts/street_content.gd")
# Keep all paths clear of the event controls and the management drawer.
const SWARM_LANES = [
	[Vector2(32,152),Vector2(531,165)],
	[Vector2(46,194),Vector2(507,182)],
	[Vector2(262,218),Vector2(533,205)],
	[Vector2(34,239),Vector2(336,227)],
	[Vector2(59,266),Vector2(520,256)],
	[Vector2(22,302),Vector2(473,284)],
	[Vector2(103,331),Vector2(528,310)],
	[Vector2(31,351),Vector2(540,345)],
	[Vector2(101,163),Vector2(117,334)],
	[Vector2(349,180),Vector2(369,333)],
	[Vector2(523,170),Vector2(486,324)],
]
const HIDING_SPOTS = [
	[Vector2(35,195),Vector2(76,202)],
	[Vector2(147,304),Vector2(217,292)],
	[Vector2(256,157),Vector2(299,163)],
	[Vector2(321,343),Vector2(380,350)],
	[Vector2(439,228),Vector2(494,217)],
	[Vector2(477,321),Vector2(530,322)],
]
const COATS = [Color("#ffffff"),Color("#e8bca6"),Color("#c3c5f9"),Color("#a9dcc7")]
const PIXELS = [
	"............dd...dd.....",
	"...........dcid.dcid....",
	".........dddciidciid....",
	".......ddhhhhhhhdhhd....",
	".....ddhhhhhalhhhhehd...",
	"....dhhhhlllllhhhhhhhdd.",
	"...dhhlllhhhhhhhhhhhhhcn",
	"....dhhhhhhhhhhhddddcc..",
	".....ddddddddddd........",
]
const PIXEL_COLORS = {
	"d":Color("#251326"),"h":Color("#856b82"),"l":Color("#ad90a0"),
	"a":Color("#c3acb6"),"c":Color("#c6a29a"),"i":Color("#e78da9"),
	"e":Color("#ffe6af"),"n":Color("#f6a2b9"),
}
static var frames: Array[Texture2D] = []

static func draw_warning(canvas: CanvasItem, clock: float, viewport_scale: Vector2) -> void:
	if frames.is_empty(): build_frames()
	for i in LANES.size():
		var start: Vector2 = LANES[i][0]
		var end: Vector2 = LANES[i][1]
		var direction := (end-start).normalized()
		var speed := 54.0+(i*29%79)
		var travel := fposmod(clock*speed/start.distance_to(end)+i*.618,2.0)
		var returning := travel>1.0
		var position := start.lerp(end,2.0-travel if returning else travel)
		var spread := float(i*19%35)-17.0
		position += direction.orthogonal()*spread
		# Stagger the little leaps so the pack never moves in unison.
		var scurry := clock*1.1+i*.37
		var hop := maxf(0.0,sin(scurry)-.88)*45.0
		position.y -= hop
		var frame := int(clock*14.0+i)%frames.size()
		var magnification := 0.85+(i*13%9)*.085
		var facing := -1.0 if returning else 1.0
		canvas.draw_set_transform(position.round()*viewport_scale,direction.angle()+facing*hop*.019,viewport_scale*Vector2(facing,1)*magnification)
		canvas.draw_texture(frames[frame],Vector2(-12,-6),COATS[i%COATS.size()])
	canvas.draw_set_transform(Vector2.ZERO,0,viewport_scale)

static func target_position(index: int, clock: float) -> Vector2:
	var hiding := index>=Content.RAT_COUNT-Content.RAT_STRAGGLERS
	var lane: Array = HIDING_SPOTS[index-(Content.RAT_COUNT-Content.RAT_STRAGGLERS)] if hiding else SWARM_LANES[index%SWARM_LANES.size()]
	var start: Vector2 = lane[0]
	var end: Vector2 = lane[1]
	var speed := 24.0 if hiding else 72.0+index*19%95
	var travel := pingpong(clock*speed/start.distance_to(end)+index*.618,1.0)
	var spread := 0.0 if hiding else float(index*17%21)-10.0
	return (start.lerp(end,travel)+(end-start).normalized().orthogonal()*spread).round()

static func draw_active(canvas: CanvasItem, clock: float, viewport_scale: Vector2, targets: Array, focused: bool) -> void:
	if frames.is_empty(): build_frames()
	for index: int in targets:
		var point := target_position(index,clock)
		var hiding := index>=Content.RAT_COUNT-Content.RAT_STRAGGLERS
		var scale_value := .9 if hiding else 1.1+(index%5)*.09
		var facing := 1.0 if target_position(index,clock+.04).x>=point.x else -1.0
		canvas.draw_set_transform(point*viewport_scale,0,viewport_scale*Vector2(facing,1)*scale_value)
		canvas.draw_texture(frames[int(clock*14.0+index)%frames.size()],Vector2(-12,-6),COATS[index%COATS.size()])
	canvas.draw_set_transform(Vector2.ZERO,0,viewport_scale)
	if focused:
		canvas.draw_arc(target_position(targets.front(),clock),17,0,TAU,22,Color("#ffda87"),2)

static func build_frames() -> void:
	for frame in 4:
		var sprite := Image.create_empty(24,11,false,Image.FORMAT_RGBA8)
		for y in PIXELS.size():
			for x in PIXELS[y].length():
				var ink: String = PIXELS[y][x]
				if PIXEL_COLORS.has(ink): sprite.set_pixel(x,y,PIXEL_COLORS[ink])
		var tail_bend: int = [1,0,1,2][frame]
		for x in 5:
			sprite.set_pixel(x,6+roundi((4-x)*tail_bend/4.0),PIXEL_COLORS.i)
		var stride: int = [-1,0,2,0][frame]
		for x in [8+stride,15-stride]:
			sprite.set_pixel(x,9,PIXEL_COLORS.d)
			sprite.set_pixel(x+1,10,PIXEL_COLORS.i)
		frames.append(ImageTexture.create_from_image(sprite))
