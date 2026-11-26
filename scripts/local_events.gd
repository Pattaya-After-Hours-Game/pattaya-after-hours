extends RefCounted

const ENCORE = 11
const CART = 12
const ZOMBIES = 13
const BED = 14
const LIZARD = 15
const DINO = 16
const ROTATION = [1,2,3,4,5,6,7,8,ENCORE,CART,ZOMBIES,BED,LIZARD,DINO]
const SOURCES = {
	1: ["Pattaya has welcomed visiting US carrier crews on shore leave.", "Associated Press", "https://apnews.com/article/d4ae5003b856940a522ef943deac4685"],
	3: ["Floodwater from Soi 6 carved trenches in the beach opposite.", "Pattaya Mail", "https://www.pattayamail.com/news/beach-road-pumps-flunk-first-test-42564"],
	4: ["Songkran water fights packed Soi 6–8 and Beach Road after dark.", "Pattaya Mail", "https://www.pattayamail.com/news/sleepless-songkran-nights-grip-pattaya-as-visitors-face-traffic-crawls-and-water-war-zones-543952"],
	ENCORE: ["In 2006 Soi 6 hosted a music festival stage. Heavy rain delayed the final day's sets.", "Pattaya Mail", "https://www.pattayamail.com/660/features.shtml"],
	CART: ["At a 2026 city forum, residents said parked food carts were narrowing Soi 6.", "The Pattaya News", "https://thepattayanews.com/2026/02/19/pattaya-city-holds-community-meeting-on-resolving-worsening-traffic-problems-on-soi-6/"],
	ZOMBIES: ["A 2010 Halloween parade marched from Walking Street to Soi 6.", "Pattaya Mail", "https://www.pattayamail.com/news/zombies-invade-pattaya-143"],
	BED: ["Pattaya's charity bed race ran down Beach Road towards Walking Street.", "Pattaya Mail", "https://www.pattayamail.com/news/planning-begins-for-jan-27-international-bed-race-20909"],
	LIZARD: ["Rescuers helped a monitor lizard outside a restaurant. Neighbours joked about the lucky address.", "Pattaya Mail", "https://www.pattayamail.com/news/injured-monitor-lizard-rescued-outside-pattaya-restaurant-as-locals-eye-lucky-house-number-549279"],
	DINO: ["Pattaya's 2026 music festival featured a 12-metre-tall animatronic dinosaur.", "Pattaya Mail", "https://www.pattayamail.com/news/giant-moving-dinosaurs-add-prehistoric-fun-to-pattaya-music-festival-538385"],
}
const RULES = {
	ENCORE: "Work the concert rush solo or book relief. An encore may split the crowd into two waves.",
	CART: "Clear Bo’s route in a sliding puzzle, book a hand delivery, or wait for traffic to clear.",
	ZOMBIES: "Host a contest to draw costumed guests who stay for judging and can order a third round. They’ll tie up seats.",
	BED: "Enter with an available bartender, then tap to race. The bartender misses the event, even if you lose.",
	LIZARD: "Clear the entrance for rescuers. Some locals may come for a lucky round after the lizard is gone.",
	DINO: "Open a photo spot for a visitor rush, or keep the entrance clear for regular trade.",
}

# x, y, length, horizontal. The first vehicle is Bo's delivery van.
const BOARD = [[0, 2, 2, true], [1, 3, 3, false], [2, 5, 3, true], [5, 2, 3, false], [3, 4, 2, true], [2, 1, 2, true], [3, 2, 2, false], [1, 0, 2, true], [3, 0, 2, true], [2, 2, 2, false], [4, 1, 3, false]]
const BED_TAPS = 38
const BED_SECONDS = 8.0

static func slide(board: Array, vehicle: int, direction: int) -> bool:
	if vehicle not in range(board.size()) or abs(direction)!=1: return false
	var car: Array = board[vehicle]
	var step := Vector2i(direction,0) if car[3] else Vector2i(0,direction)
	var start := Vector2i(car[0],car[1])+step
	var axis := Vector2i.RIGHT if car[3] else Vector2i.DOWN
	for i in int(car[2]):
		var cell := start+axis*i
		if not Rect2i(0,0,6,6).has_point(cell): return false
		for j in board.size():
			if j==vehicle: continue
			var other: Array = board[j]
			if Rect2i(other[0],other[1],other[2] if other[3] else 1,1 if other[3] else other[2]).has_point(cell): return false
	car[0] = start.x
	car[1] = start.y
	return true

static func delivery_free(board: Array) -> bool:
	return int(board[0][0])==4
