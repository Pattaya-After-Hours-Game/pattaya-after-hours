extends RefCounted

# Fictional venues; adult nightlife remains off-screen.
const TYPES = [
	{"name":"Beer bar", "rep":0, "drink":55, "stages":[
		["Plastic Chairs & Big Dreams", "Bottled beers, basic spirits, six stools and a secondhand fridge.", "Anong: The last owner said this place practically runs itself. He's at the airport. You're on ice duty."],
		["The Local Favourite", "More floor space for pool, cocktails and sports screens. Equipment is purchased separately.", "The new sign works. The reopening party trips the power. Bo offers a generator with only one previous flood."],
		["Soi Institution", "Live music and a packed terrace. Regulars keep this bar earning in low season.", "Mali's fight night finally pays. A regular asks for his own stool. Anong suggests he start by paying his tab."]]},
	{"name":"Soi 6-style bar", "rep":20, "drink":85, "stages":[
		["Something Upstairs", "Lady drinks, bar fines and one upstairs room. Adult hosts choose their own bookings.", "The previous owner retires for the fourth time. Dao checks the stairs before anyone checks the till."],
		["The Busy Staircase", "Two rooms, a larger team and better music. Room for more hosted-drink customers.", "Pim has a music programme. Bo has delivered a karaoke machine. Neither considers this the same thing."],
		["Soi Royalty", "Three rooms, experienced hosts and a recognisable neon frontage.", "Dao can now run both floors without you. Your new job is to stop offering advice during the rush."]]},
	{"name":"Gogo bar", "rep":45, "drink":140, "stages":[
		["First Spotlight", "One pole stage, an adult dance team and a very enthusiastic DJ.", "Anton sends flowers from Lantern House. The card includes the dimensions of his bigger LED screen."],
		["Neon Showroom", "Multiple poles, coordinated shows and bottle-service booths.", "Pim books the headline set. Anton announces a grand re-reopening on exactly the same night."],
		["Walking Street Headliner", "A spectacular three-pole stage, VIP service and queues around the block.", "The opening crowd blocks the street. Anong buys another fridge. Anton orders a screen visible from the moon."]]}
]
const NAMES = ["Blue Hour", "High Tide", "Neon Mango", "Lucky Gecko", "Last Baht", "Velvet Tuk Tuk", "Moonlight", "After Eight"]
const CHAPTERS = [
	["Rent Is Due on Tuesday", "Establish a loyal customer base, renovate to stage 2, hire a bartender, appoint Dao and survive the reopening."],
	["Everybody Knows Your Bar", "Buy a second property. Soi bars unlock at 20 reputation. Anong wants a street worth staying for."],
	["Upstairs, Downstairs, Everywhere", "Own a Soi bar and give two venues managers. Dao runs the floor; Pim builds the music programme."],
	["The Neon Arms Race", "Open a gogo and raise it to stage 2. Anton's LED budget is becoming a public nuisance."],
	["The Whole Soi Knows Your Name", "Own all three bar types, bring each to stage 3, then host the After Hours Street Festival."],
	["The Soi Never Sleeps", "The first festival is in the books. Keep growing, weather new seasons and host it again."]
]
const EVENTS = [
	["Reopening Blackout", "The new BLUE HOUR sign is ready. Bo suggests testing the generator before the party.", "Rent a generator", 350, "The sign lights up. So does the entire street. Only the karaoke machine loses power."],
	["US Navy Carrier Visit", "Shore leave is announced. A lot of people will want the same cold drink.", "Book relief shifts & ice", 500, "Last orders! The rush back to the ship begins. Bo counts the empty crates twice."],
	["Police Raid / Inspection", "A district inspection is scheduled. Dao wants clear exits and the actual paperwork.", "Check permits & exits", 330, "The music starts again. The inspector declines Anton's complimentary laser show."],
	["The Soi Becomes a Canal", "Heavy rain is coming. Move stock upstairs and check the pumps.", "Raise stock & share pumps", 450, "The water recedes. Your neighbours remember who helped with the pumps."],
	["Songkran", "Water fights are heading down the soi. Protect the speakers and open the terrace.", "Shield the electrics", 350, "Everything is soaked except, miraculously, Anong's receipts."],
	["The Viral Bar Crawl", "A creator has put your street on tonight's crawl. Plan space for the crowd.", "Arrange door cover", 400, "The video is online. Bo appears in the background carrying the wrong delivery."],
	["Low Season", "The tourist rush eases. The regulars are still here, arguing about the pool rules.", "Run a locals' night", 200, "The slow spell passes. Someone finally admits the pool table is not level."],
	["Anton's Grand Re-Reopening", "Lantern House has a new sign, a new promotion and exactly the same chairs.", "Promote your own lineup", 350, "Anton's screen blows a fuse. His overflow crowd discovers your street."],
	["Godzilla Wants a Cold One", "Something enormous is coming in from the bay. Find the largest glasses you own.", "Stage giant ice buckets", 450, "The harbour is quiet again. Nobody can agree whose tab the monster belongs on."],
	["After Hours Street Festival", "Your whole street is on the programme. The headline guest has dorsal plates.", "Coordinate all venues", 1200, "Anong: You came here to relax. Now look at this place. Same time next year?"]
]
const HOSTS = [
	["Bee", "Likes early shifts; accepts bar-fine requests", true],
	["May", "Prefers hosted drinks; declines bar-fine requests", false],
	["June", "Saving for a cafe; accepts bar-fine requests", true],
	["Lek", "Experienced host; accepts bar-fine requests", true],
	["Fah", "Runs the music; prefers hosted drinks", false],
	["Nan", "Wants predictable hours; accepts bar-fine requests", true]
]

# Economy values use real seconds and baht; day/shift presentation stays compressed.
const STARTING_CASH = 200
const STOCK_COST = 14
const DRINKS = [
	{"id":"lager","name":"House lager","cost":STOCK_COST,"offset":0,"substitute":100},
	{"id":"soda","name":"Lime soda","cost":6,"offset":-10,"substitute":80},
	{"id":"rum","name":"Rum & cola","cost":19,"offset":18,"substitute":90},
	{"id":"mango","name":"Mango cocktail","cost":25,"offset":30,"substitute":75},
]
# The audience order is locals, visitors, and big spenders.
const DRINK_TASTES = [[63,24,11,2],[46,10,32,12],[27,8,38,27]]
const AUDIENCE_AFFINITY = [[1.5,1.0,.5],[.6,1.0,1.6],[.3,1.3,1.5]]
const POOL_FEE = 50
const POOL_SECONDS = 45
const EQUIPMENT = [
	{"id":"sign", "name":"Better frontage", "cost":900, "max":1, "help":"More passersby consider entering; no extra service speed."},
	{"id":"comfort", "name":"Fans & comfortable seats", "cost":900, "max":1, "help":"Guests stay longer and wait more patiently; uses one seat and adds ฿4/min overhead."},
	{"id":"fridge", "name":"Better fridge", "cost":800, "max":2, "help":"Store 40 more drinks; it cannot create customers."},
	{"id":"pool", "name":"Pool table", "cost":2000, "max":2, "help":"฿50 per 45-second game; replaces two seats. Beer bars only."},
	{"id":"seating", "name":"Extra seating", "cost":400, "max":2, "help":"Two more seats; each pool table uses two of them."},
	{"id":"screen", "name":"Sports screen", "cost":1200, "max":1, "help":"Unlocks sports nights; idle screens do not attract a crowd."},
	{"id":"training", "name":"Service training", "cost":800, "max":2, "help":"Bartenders serve faster; does not generate orders."},
	{"id":"menu", "name":"Premium drinks menu", "cost":2200, "max":1, "help":"Lets you stock Mango cocktails. Stage 2+."}
]
const PROMOTIONS = [
	{"name":"Free Pool Night", "fee":0, "boost":6, "requires":"pool", "help":"Free games attract pool groups; drinks stay full price."},
	{"name":"Happy Hour", "fee":80, "boost":4, "requires":"", "help":"20% off newly placed drink orders; more walk-ins, smaller margins."},
	{"name":"Pool Tournament", "fee":150, "boost":7, "requires":"pool", "help":"Paid games and pool groups; the prize budget is an expense."},
	{"name":"Sports Night", "fee":100, "boost":5, "requires":"screen", "help":"The screen and fixture bring sports fans; ordinary drink prices."}
]
const ROLE_NAMES = ["Bartender", "Adult host", "Adult dancer"]
const ROLE_WAGES = [24,20,36] # per minute, including quiet periods
const OVERHEAD = [18,45,90]
const RENOVATIONS = [[4800,50000],[18000,80000],[45000,150000]]
const LEASES = [21000,32000,85000]
const STAGE_GOALS = [
	{"happy":70,"regulars":10,"healthy":8},
	{"happy":600,"regulars":70,"healthy":40}
]

const TRAFFIC_PER_MINUTE = 7.0
const AUDIENCE_TRAFFIC_BONUS = 2.0
const BASE_SEATS = [6,12,20]
const VISIT_SECONDS = 90
const ORDER_SECONDS = 35
const PATIENCE_SECONDS = 25
const REGULAR_CHANCE = 20
const BARTENDER_SERVICE = 10
const TRAINING_SERVICE = 5
const PROMOTION_SECONDS = 120
const PROMOTION_COOLDOWN = 120
const POOL_PATIENCE = 30
const POOL_EXTRA_STAY = 30
