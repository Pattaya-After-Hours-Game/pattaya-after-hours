extends RefCounted

# Fictional venues; adult nightlife remains off-screen.
const TYPES = [
	{"name":"Beer bar", "price":6000, "rep":0, "drink":55, "wage":10, "stages":[
		["Plastic Chairs & Big Dreams", "Bottled beers, basic spirits, six stools and a secondhand fridge.", "Anong: The last owner said this place practically runs itself. He's at the airport. You're on ice duty."],
		["The Local Favourite", "Cold drinks, a pool table, cocktails and sports screens. Better margins and more regulars.", "The new sign works. The reopening party trips the power. Bo offers a generator with only one previous flood."],
		["Soi Institution", "Live music and a packed terrace. Regulars keep this bar earning in low season.", "Mali's fight night finally pays. A regular asks for his own stool. Anong suggests he start by paying his tab."]]},
	{"name":"Soi 6-style bar", "price":12000, "rep":20, "drink":85, "wage":20, "stages":[
		["Something Upstairs", "Lady drinks, bar fines and one upstairs room. Adult hosts choose their own bookings.", "The previous owner retires for the fourth time. Dao checks the stairs before anyone checks the till."],
		["The Busy Staircase", "Two rooms, a larger team and better music. Hosted drinks earn more.", "Pim has a music programme. Bo has delivered a karaoke machine. Neither considers this the same thing."],
		["Soi Royalty", "Three rooms, experienced hosts and a recognisable neon frontage.", "Dao can now run both floors without you. Your new job is to stop offering advice during the rush."]]},
	{"name":"Gogo bar", "price":45000, "rep":45, "drink":140, "wage":45, "stages":[
		["First Spotlight", "One pole stage, an adult dance team and a very enthusiastic DJ.", "Anton sends flowers from Lantern House. The card includes the dimensions of his bigger LED screen."],
		["Neon Showroom", "Multiple poles, coordinated shows and bottle-service booths.", "Pim books the headline set. Anton announces a grand re-reopening on exactly the same night."],
		["Walking Street Headliner", "A spectacular three-pole stage, VIP service and queues around the block.", "The opening crowd blocks the street. Anong buys another fridge. Anton orders a screen visible from the moon."]]}
]
const UPGRADE_COSTS = [[1800,6500],[12000,30000],[40000,90000]]
const NAMES = ["Blue Hour", "High Tide", "Neon Mango", "Lucky Gecko", "Last Baht", "Velvet Tuk Tuk", "Moonlight", "After Eight"]
const CHAPTERS = [
	["Rent Is Due on Tuesday", "Fix the fridge (stage 2), serve 10 drinks, hire a server, appoint Dao and survive the reopening."],
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
