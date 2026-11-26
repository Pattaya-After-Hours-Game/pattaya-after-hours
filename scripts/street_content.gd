extends RefCounted

# Fictional venues; adult nightlife remains off-screen.
const TYPES = [
	{"name":"Beer bar", "rep":0, "drink":80, "stages":[
		["Plastic Chairs & Big Dreams", "Bottled beers, basic spirits, six stools and a secondhand fridge.", "Anong: The last owner said this place practically runs itself. He's at the airport. You're on ice duty."],
		["The Local Favourite", "More floor space for pool, cocktails and sports screens. Equipment is purchased separately.", "The new sign works. The reopening party trips the power. Bo offers a generator with only one previous flood."],
		["Soi Institution", "Live music and a packed terrace. Regulars keep this bar earning in low season.", "Mali's fight night finally pays. A regular asks for his own stool. Anong suggests he start by paying his tab."]]},
	{"name":"Hostess bar", "rep":20, "drink":100, "stages":[
		["Something Upstairs", "Lady drinks, bar fines and one upstairs room. Adult hosts choose their own bookings.", "The previous owner retires for the fourth time. Dao checks the stairs before anyone checks the till."],
		["The Busy Staircase", "Two rooms, a larger team and better music. Room for more hosted-drink customers.", "Pim has a music programme. Bo has delivered a karaoke machine. Neither considers this the same thing."],
		["Soi Royalty", "Three rooms, experienced hosts and a recognisable neon frontage.", "Dao can now run both floors without you. Your new job is to stop offering advice during the rush."]]},
	{"name":"Gogo bar", "rep":45, "drink":120, "stages":[
		["First Spotlight", "One pole stage, an adult dance team and a very enthusiastic DJ.", "Anton sends flowers from Lantern House. The card includes the dimensions of his bigger LED screen."],
		["Neon Showroom", "Multiple poles, coordinated shows and bottle-service booths.", "Pim books the headline set. Anton announces a grand re-reopening on exactly the same night."],
		["Walking Street Headliner", "A spectacular three-pole stage, VIP service and queues around the block.", "The opening crowd blocks the street. Anong buys another fridge. Anton orders a screen visible from the moon."]]}
]
const NAMES = ["Blue Hour", "High Tide", "Neon Mango", "Lucky Gecko", "Last Baht", "Velvet Tuk Tuk", "Moonlight", "After Eight"]
const CHAPTERS = [
	["Rent Is Due on Tuesday", "Establish a loyal customer base, renovate to stage 2, hire a bartender, appoint Dao and survive the reopening."],
	["Everybody Knows Your Bar", "Buy a second property. Hostess bars unlock at 20 reputation. Anong wants a street worth staying for."],
	["Upstairs, Downstairs, Everywhere", "Own a Hostess bar and give two venues managers. Dao runs the floor; Pim builds the music programme."],
	["The Neon Arms Race", "Open a gogo and raise it to stage 2. Anton's LED budget is becoming a public nuisance."],
	["The Whole Soi Knows Your Name", "Own all three bar types, bring each to stage 3, then host the After Hours Street Festival."],
	["The Soi Never Sleeps", "The first festival is in the books. Keep growing, weather new seasons and host it again."]
]
const Local = preload("res://scripts/local_events.gd")
const RAT_PLAGUE = 10
const RAT_WARNING_SECONDS = 20
const RAT_PLAGUE_SECONDS = 45
const RAT_EVENT_ODDS = 50
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
	["After Hours Street Festival", "Your whole street is on the programme. The headline guest has dorsal plates.", "Coordinate all venues", 1200, "Anong: You came here to relax. Now look at this place. Same time next year?"],
	["Rat Plague", "Anong heard scratching. The beer crates are moving.", "Call Bo's rat patrol", 120, "Bo saw the last rat leave with a cocktail umbrella. Word gets out that the coast is clear."],
	["Encore Rush", "The band at the end of the soi is about to finish. Keep an ear out for an encore.", "Book a relief bartender", 100, "The last concertgoers drift down to the beach."],
	["Cart Jam", "Bo’s delivery van is boxed in by a convoy of snack carts.", "Book a hand delivery", 90, "The last cart rolls away. Bo can finally get through."],
	["Last Call of the Dead", "A Halloween parade is shuffling towards Soi 6.", "Host the costume contest", 90, "The zombies go home. The glitter stays."],
	["Bo’s Bed Race", "A charity bed race needs one more crew. Bo has already borrowed wheels.", "Enter the bed race", 0, "The beds have crossed the finish line. Bo wants his wheels back."],
	["Lucky Lizard", "A monitor lizard has settled in by the planters.", "Clear a path for rescuers", 0, "The lizard is safely on its way. The neighbours are talking about lucky numbers."],
	["Definitely Not Godzilla", "Something enormous is rolling down the soi on a flatbed.", "Set up a photo stop", 80, "The robot dinosaur rolls off. It hasn’t touched a single shot."]
]
const HOSTS = [
	["Bee", "Likes early shifts; accepts bar-fine requests", true],
	["May", "Prefers hosted drinks; declines bar-fine requests", false],
	["June", "Saving for a cafe; accepts bar-fine requests", true],
	["Lek", "Experienced host; accepts bar-fine requests", true],
	["Fah", "Runs the music; prefers hosted drinks", false],
	["Nan", "Wants predictable hours; accepts bar-fine requests", true]
]

# Host development changes future booking quotes, never an already-paid booking.
const BAR_FINE_SECONDS = 30
const BAR_FINE_FEES = [500,750,1000]
const HOST_APPEAL = [0.6,1.2,1.8]
const HOST_TRAINING_PRICES = [1500,3000]
const AUTO_BAR_FINE_COST = 3000

# Game minutes advance once per foreground second. Economy timers use real seconds.
const OPEN_MINUTE = 12 * 60
const CLOSE_MINUTE = 60
const LATE_CLOSE_MINUTE = 3 * 60
const DAY_MINUTES = 24 * 60
const CLEAN_SECONDS = 15
const PEAK_HOURS = [
	{"start":17*60,"end":21*60,"label":"5–9pm"},
	{"start":19*60,"end":23*60,"label":"7–11pm"},
	{"start":22*60,"end":2*60,"label":"10pm–2am"}
]
const PEAK_ATTRACTION = 1.5
const PEAK_DIRT_PER_DRINK = 2
const DIRT_LIMIT = 100
const DIRT_ATTRACTION_PENALTY = 0.25
const HEAT_INTERVAL = 10
const COOL_SECONDS = 120
const RAID_INTERVAL = 15
const RAID_BASE_CHANCE = 2.0
const RAID_HEAT_CHANCE = 0.2
const RAID_FINE_PER_STAGE = 300
const STARTING_CASH = 228
const STOCK_COST = 38
const CONSIGNMENT_COST = 14
const LEGACY_STOCK_COST = 14 # Backfill only for saves predating paid inventory lots.
const DRINKS = [
	{"id":"lager","name":"House lager","tier":"House","cost":STOCK_COST,"offset":0,"substitute":100},
	{"id":"soda","name":"Lime soda","tier":"Value","cost":6,"offset":-10,"substitute":80},
	{"id":"rum","name":"Rum & cola","tier":"Select","cost":19,"offset":18,"substitute":90},
	{"id":"mango","name":"Mango cocktail","tier":"Premium","cost":25,"offset":30,"substitute":75},
]
# The audience order is locals, visitors, and big spenders.
const DRINK_TASTES = [[63,24,11,2],[46,10,32,12],[27,8,38,27]]
const DRINK_PRICE_HEADROOM = [8,22,50]
const DRINK_TIP_CHANCE = [[0,60,20,8],[0,22,50,20],[0,10,42,75]]
const AUDIENCE_AFFINITY = [[1.5,1.0,.5],[.6,1.0,1.6],[.3,1.3,1.5]]
const TIP_PER_VISIT = 10
const DRINK_TIP_BONUS = 5
const POOL_FEE = 50
const POOL_SECONDS = 30
const ACTION_COOLDOWNS = [10,8,6,4,2]
const ACTION_UPGRADE_COSTS = [900,1400,2800,5600]
const ACTION_UPGRADES = [
	{"id":"pouring","name":"Faster pouring","action":"serve"},
	{"id":"welcoming","name":"Better welcoming","action":"welcome"}
]
const CHAT_SECONDS = 20
const CHAT_PATIENCE = 10
const CHAT_THRESHOLD = 10
const EQUIPMENT = [
	{"id":"sign", "name":"Better frontage", "cost":900, "max":1, "help":"+2 venue attraction per tier. Beer-bar tiers beyond one also expand the shared street audience; no extra service speed."},
	{"id":"comfort", "name":"Fans & comfortable seats", "cost":900, "max":1, "help":"Guests wait more patiently; uses one seat and adds ฿4/min overhead."},
	{"id":"fridge", "name":"Better fridge", "cost":800, "max":2, "help":"Store 40 more drinks. Each fridge tier adds +1 reputation per ten satisfied visits: colder beer, happier regulars."},
	{"id":"pool", "name":"Pool table", "cost":2000, "max":2, "help":"฿50 per 30-second game; replaces two seats. Beer bars only."},
	{"id":"seating", "name":"Extra seating", "cost":400, "max":3, "help":"Two more seats. Beer bars gain a third compact layout, recovering up to three furniture places."},
	{"id":"screen", "name":"Sports screen", "cost":1200, "max":1, "help":"Unlocks sports nights; idle screens do not attract a crowd."},
	# Legacy slot retained for save/action indices; training is now per person.
	{"id":"training", "name":"Service training", "cost":800, "max":2, "help":"Bartenders serve faster; does not generate orders."},
	{"id":"menu", "name":"Premium drinks menu", "cost":2200, "max":1, "help":"Lets you stock Mango cocktails. Stage 2+."},
	{"id":"music", "name":"Music system", "cost":1200, "max":2, "help":"Drinking time: 35 → 25 → 18 → 14 → 11 seconds. Beer-bar stages unlock later tiers. Faster final drinks free seats; budgets and service still apply."}
]
const PROMOTIONS = [
	{"name":"Free Pool Night", "fee":0, "boost":6, "requires":"pool", "help":"Free games attract pool groups; drinks stay full price."},
	{"name":"Happy Hour", "fee":80, "boost":4, "requires":"", "help":"20% off newly placed drink orders; more walk-ins, smaller margins."},
	{"name":"Pool Tournament", "fee":150, "boost":7, "requires":"pool", "help":"Paid games and pool groups; the prize budget is an expense."},
	{"name":"Sports Night", "fee":100, "boost":5, "requires":"screen", "help":"The screen and fixture bring sports fans; ordinary drink prices."}
]
const ROLE_NAMES = ["Bartender", "Adult host", "Adult dancer", "Adult promoter"]
const ROLE_WAGES = [24,20,36,0] # per minute, including quiet periods
const OVERHEAD = [18,45,90]
const RENOVATIONS = [[4800,40000],[18000,65000],[45000,120000]]
const LEASES = [12000,24000,60000] # Beer / hostess / gogo; paid leases never revalue.
const LEASE_REPEAT_PERCENT = 25
const LEASE_SALE_DAYS = 14
const LEASE_SALE_PERCENT = 10
const LEASE_SALE_TYPES = [1,0,2]
const STAGE_GOALS = [
	{"happy":70,"regulars":10,"healthy":8},
	{"happy":450,"regulars":70,"healthy":40}
]

const TRAFFIC_PER_MINUTE = 7.3 # Maintains fresh-campaign pacing with nightly prep and dirt.
const AUDIENCE_TRAFFIC_BONUS = 2.0
const BASE_SEATS = [6,12,20]
const BEER_CAPS = {"seating":[3,5,7],"sign":[1,3,5],"fridge":[2,3,4],"music":[1,2,4],"training":[2,4,6]}
const ONE_ROUND_CHANCE = [20,40,10] # Local / tourist / nightlife; appearance never changes plans.
const FRONTAGE_TRAFFIC = 2.0
const VISIT_SECONDS = 90 # Legacy visitors only.
const ORDER_SECONDS = 35
const PATIENCE_SECONDS = 25
const REGULAR_CHANCE = 20
const STAFF_CONTRACT_COST = 4500
const BARTENDER_CONTRACT_COST = 1200
const GABBY_TIP_PER_DRINK = 5
const STAFF_CONTRACT_DAYS = 10
const STAFF_CONTRACT_MINUTES = STAFF_CONTRACT_DAYS * DAY_MINUTES
const STAFF_SERVICE_SECONDS = [25,20,15,12,10,8,6] # One drink, per bartender; training stays with the person.
const STAFF_TRAINING_COST = 400
const ORDER_ALERT_SECONDS = 10.0
const PROMOTION_SECONDS = 120
const PROMOTION_COOLDOWN = 120
const POOL_PATIENCE = 30
const POOL_EXTRA_STAY = 30

const STOCK_PACK = 6
const PROMOTER_CONTRACT_COST = 1200
const PROMOTER_BONUS = [4.8,6.0,7.2]
const AUDIENCE_TRAINING_COST = 800
const DANCER_TRAINING = [1.0,1.25,1.5]
const COMMISSION_PERCENT = 0 # Nida is paid by contract only; legacy ledgers stay readable.

const AUTO_SERVE_URGENT_SECONDS = 10
const AUTO_SERVE_COST = 3000
const MUSIC_ORDER_SECONDS = 25 # Legacy first-tier reference.
const MUSIC_INTERVALS = [35,25,18,14,11]
const SUPPLIER_PRICES = [900,1200,2400,4800,9600]
const SUPPLIER_UNIT_COSTS = [38,38,36,34,32,30]
const SUPPLIER_STAGES = [1,1,2,2,3]
const MANAGER_PRICES = [8000,36000,72000]
const CLUB_PRICES = [600,1200,2400]
const CLUB_REGULARS = [10,20,35]
const CLUB_CHANCE = [0,35,65,100]
const CLUB_EXTRA_STAY = 20
const MANAGER_INCOME = [0,10,20,40]
const MANAGER_STAGES = [2,3,3]

# Foreground calendar celebrations, not real-world login rewards.
const CELEBRATION_INTERVAL = 7
const CELEBRATION_TRAFFIC = 1.4
const CELEBRATION_TRAFFIC_CAP = 2.4
const CELEBRATION_ATTRACTION = 2.0
const CELEBRATION_ORDER_FACTOR = 0.75
const CELEBRATION_DRINK_LIMIT = 3
const CELEBRATION_EXTRA_STAY = 15
const CELEBRATION_PATIENCE = 10
const CELEBRATIONS = [
	["Anong's Birthday", "Anong: No presents. Bring your friends. And please, this year, cold beer."],
	["The Regulars' Reunion", "Mali: The regulars have invited their regulars. Apparently that's a thing."],
	["Pim's Mixtape Party", "Pim: One night, no requests for the same song six times. Five is negotiable."],
	["Bo's Thank-You Night", "Bo: The drinks arrived on time. We thought that deserved a party."]]
