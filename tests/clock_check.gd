extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Economy = preload("res://scripts/economy.gd")
const C = preload("res://scripts/street_content.gd")

func advance(m: RefCounted, seconds: int) -> void:
	for _i in seconds: m.street.tick(1)

func managed() -> RefCounted:
	var m = Campaign.new(72)
	m.s.cash = 10000
	var bar: Dictionary = m.street.selected()
	bar.manager = true
	bar.restock = true
	bar.team = [{"role":0,"on":true,"host":-1,"training":2,"audience_training":0,"service_clock":0,"contract_left":C.STAFF_CONTRACT_MINUTES},{"role":0,"on":true,"host":-1,"training":2,"audience_training":0,"service_clock":0,"contract_left":C.STAFF_CONTRACT_MINUTES}]
	for person in bar.team: m.street.economy.ensure_staff_service(person)
	bar.crew = 2
	return m

func run(test: SceneTree) -> void:
	clock_and_closures(test)
	cleaning(test)
	raids(test)
	offline(test)
	peaks(test)
	saves(test)
	DirAccess.remove_absolute(Campaign.SAVE)
	DirAccess.remove_absolute(Campaign.BACKUP)

func clock_and_closures(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	test.check(m.street.clock_text()=="12:00pm" and m.s.day==1,"Fresh campaign starts at noon")
	advance(m,120)
	test.check(m.street.clock_text()=="2:00pm" and m.s.day==1 and not bar.last_shift.is_empty(),"Business reports do not advance calendar days")
	m.s.day = 7
	m.s.street.minute = 1439
	m.street.tick(1)
	test.check(m.s.day==8 and m.street.clock_text()=="12:00am" and not m.s.last_week.is_empty(),"Midnight advances the day and closes weekly accounts once")
	m.s.cash = 200000
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("buy",1)
	var second: Dictionary = m.street.selected()
	m.s.street.minute = 59
	m.street.action("late")
	m.street.tick(1)
	test.check(not m.street.economy.is_trading(bar) and m.street.economy.is_trading(second),"1am closes ordinary venues but preserves a venue's nightly extension")
	test.check(not m.street.can_skip(),"An operating late venue prevents skipping")
	var before := [m.s.cash,bar.stock,bar.sold,bar.pool_income]
	m.s.street.selected = 0
	m.street.action("serve")
	m.street.action("welcome")
	m.street.action("promotion",1)
	m.street.action("late")
	m.street.economy.pool_tick(bar)
	test.check(before==[m.s.cash,bar.stock,bar.sold,bar.pool_income] and not bar.late_open and bar.promo.is_empty(),"Closed venues cannot serve, promote, charge pool or opt in after 1am")
	var forecast: Dictionary = m.street.economy.forecast(bar)
	test.check(forecast.arrivals==0 and forecast.sales==0 and forecast.costs==0 and forecast.net==0,"Closed forecast has no trading revenue or payroll")
	m.s.street.minute = 179
	m.street.tick(1)
	test.check(not m.street.any_trading() and m.street.can_skip(),"3am closes every venue")
	m.street.announce(3)
	var event: Dictionary = m.s.street.event.duplicate(true)
	var day := int(m.s.day)
	before = [m.s.cash,m.s.heat,m.s.street.elapsed,m.s.street.served,bar.healthy]
	m.street.action("skip")
	test.check(before==[m.s.cash,m.s.heat,m.s.street.elapsed,m.s.street.served,bar.healthy] and m.s.street.event==event and m.s.day==day,"Skip changes no economy, heat, event, milestone or extra day")
	test.check(m.s.street.minute==720 and not second.late_open and m.street.any_trading(),"Skip opens at noon and clears nightly permission")
	m.street.action("open")
	second.open = false
	second.close_reason = "Operating cash ran out"
	m.s.street.minute = 719
	m.street.tick(1)
	test.check(not bar.open and not second.open and not m.street.any_trading(),"Noon does not undo owner or insolvency closures")
	# Closing discards outstanding orders/games without another fee or service loss.
	m = Campaign.new(4)
	bar = m.street.selected()
	m.s.cash = 10000
	bar.equipment.pool = 1
	bar.customers.clear()
	for _i in 2:
		m.street.economy.admit(bar)
		bar.customers.back().pool = true
	m.street.action("promotion",0)
	m.street.economy.pool_tick(bar)
	m.s.street.minute = 59
	m.s.street.seconds = 17
	before = [bar.pool_income,bar.free_games,bar.lost_service,bar.lost_stock]
	m.street.tick(1)
	test.check(bar.games.is_empty() and bar.customers.is_empty() and bar.host_requests.is_empty() and bar.promo.is_empty(),"Nightly close clears guests and finalises the promotion")
	test.check(before==[bar.pool_income,bar.free_games,bar.lost_service,bar.lost_stock] and bar.promo_report.free_games==1,"Closing never bills free pool or penalises unserved orders")
	var report: Dictionary = bar.last_shift.duplicate(true)
	var cooldown := int(bar.promo_cooldown)
	advance(m,3)
	test.check(bar.last_shift==report and bar.promo_cooldown==cooldown-3,"Partial closing report and promotion finish only once")
	# Guided sessions end cleanly even if closing interrupts a 40-second wave.
	m = Campaign.new(72)
	m.s.street.minute = 59
	m.start()
	m.pick(2)
	m.street.tick(1)
	test.check(m.s.phase=="guided_report" and m.s.street.seconds==0,"Closing settles a partial guided shift")
	m.next_day()
	test.check(m.street.can_skip(),"Dismissed closing report permits prep and skipping")
	m.start()
	test.check(m.s.phase=="plan","Closed street cannot enter stuck guided decisions")

func cleaning(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	m.street.action("serve")
	test.check(bar.dirt==1,"Only an actual drink sale adds dirt")
	bar.customers.clear()
	m.street.action("serve")
	test.check(bar.dirt==1,"Empty service clicks do not add dirt")
	bar.dirt = 0
	var attraction := float(eco.attraction(bar))
	bar.dirt = 100
	test.check(is_equal_approx(eco.attraction(bar),attraction*.75),"Dirt reduces attraction by at most 25 percent")
	m.street.action("clean")
	test.check(bar.clean_remaining==0,"Cleaning cannot run while trading")
	m.s.street.minute = 60
	m.street.reconcile_closures()
	m.street.action("clean")
	advance(m,14)
	test.check(bar.clean_remaining==1 and bar.dirt==100,"Cleaning requires fifteen real foreground seconds")
	m.street.tick(1)
	test.check(bar.dirt==0 and bar.clean_remaining==0,"Completed cleaning restores cleanliness")
	m.street.action("stay") # This fixture continues manual prep after the automatic clean.
	bar.dirt = 80
	m.street.action("clean")
	advance(m,5)
	m.street.action("skip")
	test.check(bar.dirt==80 and bar.clean_remaining==0,"Skip cancels incomplete cleaning without clearing dirt")
	bar.manager = true
	m.s.street.minute = 59
	m.street.tick(1)
	test.check(bar.clean_remaining==15,"Manager automatically starts cleaning on closure")
	m.street.announce(3)
	var remaining := int(m.s.street.event.remaining)
	bar.closed = 5
	advance(m,5)
	test.check(bar.closed==0 and bar.clean_remaining==10 and m.s.street.event.remaining==remaining,"Prep and closure timers advance while street events pause")
	m.s.street.minute = 719
	m.street.tick(1)
	test.check(bar.clean_remaining==0 and bar.dirt==80,"Natural noon opening also cancels unfinished cleaning")
	m.street.action("open")
	var stock := int(bar.stock)
	m.s.cash = 10000
	m.street.action("stock")
	test.check(bar.stock==stock+6 and m.s.cash==10000-84,"Closed-hour restocking pays the real stock cost")

func raids(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	m.s.cash = 10000
	m.street.action("late")
	m.s.street.minute = 60
	m.s.heat = 5
	advance(m,10)
	test.check(m.s.heat==6 and bar.late_minutes==10,"Ten actual late minutes add one heat point")
	m.street.action("late")
	advance(m,10)
	test.check(m.s.heat==6 and bar.late_minutes==10 and not m.street.any_trading(),"Cancelling late opening stops risk accumulation")
	advance(m,110)
	test.check(m.s.heat==5,"Two safe foreground minutes cool one heat point")
	# Find a known hit without consuming the simulation RNG.
	var seed_value := 1
	while (seed_value*48271)%2147483647%1000>=220: seed_value += 1
	m = Campaign.new(72)
	bar = m.street.selected()
	m.s.cash = 450
	bar.stage = 2
	m.street.action("late")
	m.s.street.minute = 74
	bar.late_minutes = 14
	m.s.heat = 100
	m.s.street.economy_seed = seed_value
	var costs := int(m.s.weekly.costs)
	m.street.tick(1)
	test.check(bar.raided and m.s.cash==0 and m.s.debt==0,"A raid caps its fine at available cash without debt")
	test.check(m.s.weekly.costs==costs+450 and bar.last_shift.fines==450 and bar.last_shift.net==-450,"Raid fine appears once in venue and weekly books")
	var loaded = Campaign.new(9)
	test.check(loaded.load_game() and loaded.street.selected().raided and loaded.s.cash==0 and loaded.s.street.minute==75,"Raid outcome is saved immediately at the completed tick")
	loaded.street.action("open")
	loaded.street.action("open")
	loaded.street.action("recovery")
	test.check(not loaded.street.any_trading() and loaded.s.cash==0,"Reopening and recovery cannot bypass a raid closure")
	advance(loaded,5)
	test.check(loaded.s.cash==0 and loaded.s.weekly.costs==costs+450,"Reloading and waiting cannot repeat a raid fine")
	loaded.street.action("skip")
	loaded.street.action("open") # Close the empty-till venue, then recover.
	loaded.street.action("recovery")
	test.check(not loaded.street.selected().raided and loaded.street.selected().recovery==120,"Raid victims retain owner-run recovery after noon")
	# Two late venues contribute independently; owner/event closures do not.
	m = managed()
	m.s.cash = 200000
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("late")
	m.street.action("buy",2)
	m.street.action("late")
	bar = m.street.selected()
	m.s.heat = 20
	m.s.street.minute = 60
	advance(m,10)
	test.check(m.s.heat==22,"Each actually trading late venue adds heat")
	bar.closed = 30
	var prior := int(bar.late_minutes)
	advance(m,3)
	test.check(bar.late_minutes==prior,"Event-closed venues do not accumulate late risk")
	# Same saved risk counters and RNG produce the same next check.
	m = managed()
	bar = m.street.selected()
	m.street.action("late")
	m.s.street.minute = 74
	bar.late_minutes = 14
	m.s.street.economy_seed = seed_value
	m.s.heat = 100
	m.save_game()
	loaded = Campaign.new(3)
	loaded.load_game()
	m.street.tick(1)
	loaded.street.tick(1)
	test.check(m.s.street==loaded.s.street and m.s.cash==loaded.s.cash,"Raid decision is deterministic across a pre-check save/reload")

func offline(test: SceneTree) -> void:
	test.check(Economy.legal_open_minutes(720,780)==780 and Economy.legal_open_minutes(60,660)==0,"Offline legal window is noon through 1am")
	test.check(Economy.legal_open_minutes(50,20)==10 and Economy.legal_open_minutes(710,20)==10,"Offline projection clips both opening and closing boundaries")
	test.check(Economy.legal_open_minutes(720,28800)==15600,"Eight real hours include twenty legal thirteen-hour trading windows")
	var m = managed()
	var bar: Dictionary = m.street.selected()
	m.s.street.minute = 50
	m.s.street.offline_cursor = 50
	m.s.street.last_seen = 1000
	bar.dirt = 40
	bar.clean_remaining = 7
	bar.late_open = true
	var snapshot := [m.s.day,m.s.street.minute,bar.dirt,bar.clean_remaining,m.s.heat]
	m.street.claim_offline(1020)
	test.check(m.s.street.offline_report.legal_seconds==10 and m.s.street.offline_cursor==70,"Offline claim advances its private cursor")
	m.street.claim_offline(1040)
	test.check(m.s.street.offline_report.legal_seconds==0 and m.s.street.offline_report.net==0,"Repeated claims do not reuse the same legal window")
	test.check(snapshot==[m.s.day,m.s.street.minute,bar.dirt,bar.clean_remaining,m.s.heat],"Offline estimation does not clean, cool, raid or advance the live clock")
	var cursor := int(m.s.street.offline_cursor)
	m.street.claim_offline(900)
	test.check(m.s.street.offline_cursor==cursor and m.s.street.last_seen==1040,"Backward wall clocks cannot rewind the projection")
	m.save_game()
	var loaded = Campaign.new(3)
	test.check(loaded.load_game() and loaded.s.street.offline_cursor==cursor,"Projection cursor persists across saves")
	bar.dirt = 0
	var clean_net := float(m.street.economy.forecast(bar,true).net)
	bar.dirt = 100
	test.check(m.street.economy.forecast(bar,true).net<clean_net,"Offline forecasts respect saved dirt")

func saves(test: SceneTree) -> void:
	var m = managed()
	var bar: Dictionary = m.street.selected()
	bar.dirt = 52
	bar.clean_remaining = 7
	bar.late_open = true
	bar.late_minutes = 14
	for minute in [0,59,60,179,180,719,720,1439]:
		m.s.street.minute = minute
		m.save_game()
		var loaded = Campaign.new(9)
		test.check(loaded.load_game() and loaded.s.street==m.s.street,"Clock and prep state round-trip at minute %d" % minute)
	# Genuine old field shape, including a paid pool game and active promotion.
	m = Campaign.new(72)
	bar = m.street.selected()
	m.s.cash = 9876
	m.s.day = 47
	bar.equipment.pool = 1
	for customer in bar.customers: customer.pool = true
	m.street.economy.pool_tick(bar)
	m.street.action("promotion",0)
	bar.closed = 9
	var customers: Array = bar.customers.duplicate(true)
	var games: Array = bar.games.duplicate(true)
	m.s.version = 3
	for key in ["minute","offline_cursor","cool_seconds"]: m.s.street.erase(key)
	for key in Economy.clock_fields(): bar.erase(key)
	bar.shift.erase("fines")
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(m.s))
	file.close()
	var migrated = Campaign.new(9)
	test.check(migrated.load_game(),"Version-three save without new fields loads")
	var restored: Dictionary = migrated.street.selected()
	test.check(migrated.s.version==10 and migrated.s.day==47 and migrated.s.cash==9926 and migrated.s.street.minute==720,"Migration preserves day and money and introduces noon")
	test.check(restored.customers==customers and restored.games==games and restored.closed==9 and not restored.promo.is_empty() and restored.dirt==0,"Migration preserves queues, paid games, promotions and event closures")
	migrated.save_game()
	migrated.save_game()
	migrated.s.street.minute = 1440
	file = FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(migrated.s))
	file.close()
	var recovered = Campaign.new(9)
	test.check(recovered.load_game() and recovered.s.street.minute==720,"Invalid clock data falls back to a valid backup")

func peaks(test: SceneTree) -> void:
	for kind in 3:
		var hours: Dictionary = C.PEAK_HOURS[kind]
		test.check(not Economy.peak(kind,(int(hours.start)+1439)%1440) and Economy.peak(kind,int(hours.start)),"Peak starts exactly on its venue's hour")
		test.check(Economy.peak(kind,(int(hours.end)+1439)%1440) and not Economy.peak(kind,int(hours.end)),"Peak ends exactly on its venue's hour")
	test.check(Economy.peak(2,0) and Economy.peak(2,119) and not Economy.peak(2,120),"Gogo peak crosses midnight and ends at 2am")
	var m = managed()
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	var noon := float(eco.forecast(bar).arrivals)
	m.s.street.minute = 1020
	test.check(eco.forecast(bar).arrivals>noon,"Beer-bar peak increases arrivals with the same shared street supply")
	var supply := float(eco.traffic_rate())
	eco.serve(bar,1,true)
	test.check(bar.dirt==2 and eco.traffic_rate()==supply,"A peak drink creates twice the dirt without creating extra street supply")
	bar.customers.clear()
	advance(m,30)
	m.street.action("open")
	var dirt := int(bar.dirt)
	advance(m,20)
	test.check(bar.dirt<=dirt,"A closed peak-hour venue does not accumulate mess")
	m = managed()
	m.s.cash = 200000
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("buy",2)
	bar = m.street.selected()
	m.s.street.minute = 0
	bar.late_open = true
	m.s.street.selected = 0
	var first: Dictionary = m.street.selected()
	var total := float(m.street.economy.forecast(first).arrivals)+float(m.street.economy.forecast(bar).arrivals)
	test.check(total<=m.street.economy.traffic_rate(),"Peak venues still compete for bounded shared demand")
	m.s.street.minute = 60
	bar.late_open = false
	test.check(not m.street.economy.is_trading(bar) and m.street.economy.forecast(bar).arrivals==0,"A peak window never overrides closing permission")
	var early = managed()
	early.s.street.last_seen = 1000
	early.s.street.offline_cursor = 720
	var quiet := int(early.street.claim_offline(1060))
	var busy = managed()
	busy.s.street.last_seen = 1000
	busy.s.street.offline_cursor = 1020
	var peak_gain := int(busy.street.claim_offline(1060))
	test.check(peak_gain>quiet and busy.street.selected().dirt==0,"Offline legal peak windows affect demand without unseen dirt changes")
	var windows := Economy.offline_windows(1260,240)
	var seconds := 0
	for window in windows: seconds += int(window.seconds)
	test.check(seconds==240 and windows.size()==4,"Offline projection splits at venue peak boundaries and midnight")
