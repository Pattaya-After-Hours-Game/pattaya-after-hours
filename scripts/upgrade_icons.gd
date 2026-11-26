extends RefCounted

# Hand-drawn eight-pixel symbols, enlarged with nearest-neighbor filtering.
const GLYPHS = {
	"clock": ["..####..", ".#....#.", "#..#...#", "#..#...#", "#..###.#", "#......#", ".#....#.", "..####.."],
	"club": [".##..##.", "########", "########", ".######.", "..####..", "...##...", "........", "........"],
	"upgrades": ["...##...", "..####..", ".##..##.", "##....##", "...##...", "...##...", "...##...", "........"],
	"pouring": [".######.", ".##..##.", ".######.", ".##..##.", ".##..##.", ".##..##.", "..####..", "........"],
	"welcoming": ["...####.", "...#..#.", "..##..#.", "######.#", "..##..##", "...#..#.", "...####.", "........"],
	"auto": ["..####..", ".#....#.", "#.#..#.#", "#......#", "#.####.#", ".#....#.", "..####..", "...##..."],
	"sign": ["########", "#......#", "#.#.#..#", "#..#.#.#", "########", ".#....#.", ".#....#.", "........"],
	"comfort": ["...##...", "...###..", ".#..##..", "########", "..##..#.", "..###...", "...##...", "........"],
	"fridge": [".######.", ".#....#.", ".##...#.", ".######.", ".#....#.", ".##...#.", ".#....#.", ".######."],
	"pool": ["..####..", ".######.", "###..###", "##.##.##", "###..###", ".######.", "..####..", "........"],
	"seating": [".##.....", ".##.....", ".##.....", ".######.", ".######.", ".##..##.", ".##..##.", "........"],
	"screen": ["########", "#......#", "#..#...#", "#..##..#", "#..#...#", "########", "...##...", "..####.."],
	"menu": ["########", ".#....#.", "..#..#..", "...##...", "...##...", "...##...", "..####..", "........"],
	"music": ["...#####", "...#...#", "...#...#", "...#...#", ".###.###", "####.###", ".##...#.", "........"],
	"supplier": ["######..", "#....##.", "#....#.#", "########", "##....##", ".##..##.", "..#..#..", "........"],
	"manager": ["..####..", "..#..#..", "########", "#......#", "########", "#..##..#", "#......#", "########"],
	"renovate": ["...##...", "..####..", ".##..##.", "##....##", ".######.", ".#..#.#.", ".#..#.#.", ".######."],
	"training": ["...##...", "..####..", "########", ".######.", "..####..", "..####..", ".##..##.", "........"],
	"audience": [".#####..", ".#...##.", ".#...###", ".#...###", ".#...##.", "..##....", "...#....", "........"],
}

static var textures := {}

static func get_icon(id: String) -> Texture2D:
	if not textures.has(id):
		var rows: Array = GLYPHS[id]
		var image := Image.create_empty(12,12,false,Image.FORMAT_RGBA8)
		image.fill_rect(Rect2i(0,1,12,10),Color("#31252f"))
		image.fill_rect(Rect2i(1,0,10,12),Color("#31252f"))
		for y in rows.size():
			for x in rows[y].length():
				if rows[y][x]=="#":
					image.set_pixel(x+2,y+2,Color("#ffd083") if id in ["upgrades","manager","renovate","training","audience"] else Color("#71f9d2"))
		image.resize(24,24,Image.INTERPOLATE_NEAREST)
		textures[id] = ImageTexture.create_from_image(image)
	return textures[id]

# Distinct glass silhouettes and colours at Fridge scale.
const DRINK_PIXELS = {
	"lager": [
		"................", "....www.........", "..wwwww.w.......", "..wwwwwww.......",
		"..hwwwwhho......", "..haaahadoooo...", "..hhaaaadohho...", "..hhaaahdo..o...",
		"..haaahado..o...", "..haahaadohho...", "..haaaaadoooo...", "..hhaaaado......",
		"...hhhhho.......", "....oooo........", "................", "................",
	],
	"soda": [
		"................", "...........ll...", "..........l.....", ".........l.gg...",
		"....kkkkklgglg..", "....okkkklggg...", "....ogllglgg....", ".....olgglgo....",
		".....olggggo....", ".....ogglkgo....", "......olggko....", "......olgggo....",
		"......olglgo....", "......okkko.....", ".......ooo......", "................",
	],
	"rum": [
		"................", "................", "................", "...kkkkkkk......",
		"..kkkwwkwwkkk...", "..okwwrkwrkko...", "..okkrdrkrrko...", "..okrrkwwrrko...",
		"..okrrkkrdrko...", "..okrdrrrrrko...", "...okrrddrko....", "...okkrrrkko....",
		"....okkkkko.....", ".....ooooo......", "................", "................",
	],
	"mango": [
		"................", "......ppp.......", ".....pmppp......", "....pmmwppp..g..",
		"....ooowooooogl.", "..kkmhwmmmmlgk..", "...kmhwmmlgmk...", "....kmhwmmmk....",
		".....kmmmdo.....", "......kkkk......", ".......kk.......", ".......ko.......",
		".......ko.......", ".....kkkkkk.....", "....oooooooo....", "................",
	],
}
const DRINK_PALETTE = {
	"o": Color("#17111e"), "w": Color("#fff0cb"), "h": Color("#ffd378"),
	"a": Color("#e98b27"), "d": Color("#8e4539"), "g": Color("#59ce76"),
	"l": Color("#c7f79a"), "k": Color("#9ed7e4"), "r": Color("#bd5539"),
	"m": Color("#ffab43"), "p": Color("#f35e98"),
}

static func get_drink_icon(id: String) -> Texture2D:
	if not textures.has(id):
		var rows: Array = DRINK_PIXELS[id]
		var image := Image.create_empty(16,16,false,Image.FORMAT_RGBA8)
		for y in rows.size():
			for x in rows[y].length():
				var pixel: String = rows[y][x]
				if pixel!=".": image.set_pixel(x,y,DRINK_PALETTE[pixel])
		textures[id] = ImageTexture.create_from_image(image)
	return textures[id]
