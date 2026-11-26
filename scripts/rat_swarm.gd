extends RefCounted

# Paths follow the floor, doorway, furniture, shelving, ceiling and wall trim.
const LANES = [
	[Vector2(13,387),Vector2(618,412)],
	[Vector2(306,356),Vector2(954,391)],
	[Vector2(10,455),Vector2(949,450)],
	[Vector2(635,343),Vector2(950,337)],
	[Vector2(660,207),Vector2(927,193)],
	[Vector2(671,261),Vector2(953,245)],
	[Vector2(224,52),Vector2(948,36)],
	[Vector2(101,57),Vector2(643,95)],
	[Vector2(634,74),Vector2(643,365)],
	[Vector2(931,86),Vector2(938,327)],
	[Vector2(220,134),Vector2(244,364)],
	[Vector2(257,289),Vector2(603,312)],
	[Vector2(7,292),Vector2(222,344)],
	[Vector2(278,168),Vector2(593,212)],
	[Vector2(19,121),Vector2(25,402)],
	[Vector2(804,154),Vector2(799,316)],
	[Vector2(313,483),Vector2(957,477)],
	[Vector2(366,272),Vector2(654,251)],
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

static func draw_scurriers(canvas: CanvasItem, clock: float, viewport_scale: Vector2, active: bool, prepared: bool) -> void:
	if frames.is_empty(): build_frames()
	var count := (144 if prepared else 240) if active else 7
	for i in count:
		var lane: int = i%LANES.size() if active else [0,1,4,8,11,13,14][i]
		var start: Vector2 = LANES[lane][0]
		var end: Vector2 = LANES[lane][1]
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
		var umbrella_rat := active and i==3
		var magnification := 1.75 if umbrella_rat or lane==16 else 0.85+(i*13%9)*.085
		var facing := -1.0 if returning else 1.0
		var upside_down := -1.0 if lane in [6,7] else 1.0
		canvas.draw_set_transform(position.round()*viewport_scale,direction.angle()+facing*hop*.019,viewport_scale*Vector2(facing,upside_down)*magnification)
		canvas.draw_texture(frames[frame],Vector2(-12,-6),COATS[i%COATS.size()])
		if umbrella_rat:
			canvas.draw_rect(Rect2(6,-12,1,9),Color("#ffd79a"))
			canvas.draw_rect(Rect2(0,-12,13,3),Color("#ff5bb4"))
			canvas.draw_rect(Rect2(2,-14,9,2),Color("#ffc2dd"))
			canvas.draw_rect(Rect2(5,-15,3,1),Color("#fff0b2"))
	canvas.draw_set_transform(Vector2.ZERO,0,viewport_scale)

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
