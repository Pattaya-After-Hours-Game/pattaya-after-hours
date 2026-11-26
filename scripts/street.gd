extends RefCounted

const C = preload("res://scripts/street_content.gd")
const Economy = preload("res://scripts/economy.gd")
const OFFLINE_CAP = 8 * 60 * 60
const SHIFT_SECONDS = 120
var s: Dictionary
var economy: RefCounted
signal checkpoint_requested
var raid_checkpoint := false
var night_prep_visible := true

func _init(state: Dictionary, fresh: bool = false) -> void:
	s = state
	if not s.has("street"):
		var first := make_bar(0, 0)
		first.stage = clampi(int(s.get("level",1)),1,3)
		if not fresh and not s.get("practice",false):
			first.crew = mini(6,s.staff.size())
			first.stock = int(s.stock)
		s.street = {"bars":[first], "selected":0, "chapter":0, "served":0, "earned":0,
			"seconds":0, "cycle":0, "event":{}, "event_wait":180, "event_index":0,
			"events_survived":0, "reopening":false, "festival":false, "festivals":0,
			"last_seen":int(Time.get_unix_time_from_system()), "offline":0, "history":[]}
		if int(s.get("venue",1)) > 1:
			s.street.bars.append(make_bar(0,1))
		if first.stage > 1:
			s.street.reopening = true
			announce(0)
		record(C.TYPES[0].stages[0][2])
	# The old shift model now accounts only for the flagship. Street venues
	# settle their own stock, wages and overhead through their live sales.
	s.level = s.street.bars[0].stage
	s.venue = 1
	if int(s.get("version",1))<4:
		s.street.minute = C.OPEN_MINUTE
		s.street.offline_cursor = C.OPEN_MINUTE
		s.street.cool_seconds = 0
		for bar in s.street.bars:
			bar.merge(Economy.clock_fields(),true)
	if not s.street.has("tick_fraction"): s.street.tick_fraction = 0.0
	if not s.street.has("night_prep"): s.street.night_prep = {"night":-1,"remaining":0,"cancelled":false}
	economy = Economy.new(s,fresh)
	s.version = 11

func celebration_info() -> Dictionary:
	var active: bool = economy.celebration_window() and int(s.street.celebration.day)==economy.trading_day() and not s.street.celebration.report.is_empty()
	var day := int(s.street.celebration.day) if active else maxi(7,ceili(float(s.day)/7.0)*7)
	if not active and day==economy.trading_day() and int(s.street.celebration.day)==day: day += 7
	return {"day":day,"active":active,"name":Economy.celebration_name(day),"days_left":maxi(0,day-int(s.day))}

func celebration_tick() -> void:
	var party: Dictionary = s.street.celebration
	if not party.report.is_empty() and not economy.celebration_window():
		party.last_report = party.report.duplicate(true)
		party.report = {}
		record("PARTY REPORT · %s: %d drinks, %d new regulars, ฿%d trading contribution. Full report in Events." % [Economy.celebration_name(int(party.day)),party.last_report.sales,party.last_report.regulars,Economy.celebration_contribution(party.last_report)])
	if economy.celebration_window() and int(party.day)!=economy.trading_day():
		party.day = economy.trading_day()
		party.report = Economy.celebration_report(int(party.day))
		record("TONIGHT AT THE BLUE HOUR · %s · %s" % [Economy.celebration_name(int(party.day)),C.CELEBRATIONS[Economy.celebration_index(int(party.day))][1]])

func make_bar(kind: int, slot: int) -> Dictionary:
	return {"type":kind, "stage":1, "name":C.NAMES[slot], "crew":0,
		"stock":30, "restock":false, "manager":false, "away":[], "closed":0}

func selected() -> Dictionary:
	return s.street.bars[int(s.street.selected)]

func record(line: String) -> void:
	s.log.push_front(line)
	if s.log.size() > 30: s.log.pop_back()
	s.street.history.push_front(line)
	if s.street.history.size() > 60: s.street.history.pop_back()

func pay(cost: int) -> bool:
	if cost < 0 or int(s.cash) < cost: return false
	s.cash -= cost
	s.weekly.costs += cost
	return true

func credit(gross: int, costs: int = 0) -> void:
	s.cash += gross - costs
	s.weekly.revenue += gross
	s.weekly.costs += costs
	s.street.earned += gross - costs

func capacity(bar: Dictionary) -> int:
	return economy.stock_capacity(bar)

func staff_limit(bar: Dictionary) -> int:
	return int(bar.stage)*2

func upgrade_cost(bar: Dictionary) -> int:
	return 0 if bar.stage >= 3 else int(C.RENOVATIONS[int(bar.type)][int(bar.stage)-1])

func purchase_cost(kind: int) -> int:
	var owned := 0
	for bar in s.street.bars:
		if bar.type == kind: owned += 1
	return int(C.LEASES[kind])*(2+owned)/2

func drink_value(bar: Dictionary, _offline: bool = false) -> int:
	return economy.price(bar)

func available(bar: Dictionary) -> int:
	var count := 0
	for role in 3: count += economy.on_duty(bar,role)
	return count

func net_rate(bar: Dictionary, offline: bool = false) -> int:
	if offline and not bar.manager: return 0
	if not economy.is_trading(bar,offline): return 0
	return floori(economy.forecast(bar,offline).net)

func total_rate(offline: bool = false) -> int:
	var total := 0
	for bar in s.street.bars: total += net_rate(bar,offline)
	return total

func _sell(bar: Dictionary, count: int) -> int:
	return economy.serve(bar,count)

func action(id: String, index: int = 0) -> String:
	if not s.phase in ["plan","guided"]: return "Finish the current decision first."
	var bar := selected()
	var result := ""
	match id:
		"serve","stock","buy_drink","mixed_drinks","return_drink","hire","welcome","chat","action_upgrade","equipment","promotion","rota","role","open","recovery","bar_fine","clean","emergency_stock","rehire","train_staff","train_audience","auto_serve":
			result = economy.action(bar,id,index)
		"late":
			if bar.late_open:
				bar.late_open = false
				result = "Late opening cancelled. Normal closing is 1am."
			else:
				if not Economy.scheduled({},int(s.street.minute)) or bar.raided:
					return "Choose late opening before 1am."
				bar.late_open = true
				result = "%s can trade until 3am tonight. Heat and raid risk rise after 1am." % bar.name
		"stay":
			if int(s.street.night_prep.remaining)<=0: return "No automatic jump is pending."
			s.street.night_prep.remaining = 0
			s.street.night_prep.cancelled = true
			result = "Staying for prep. Cleaning continues; use Skip to 12pm when ready."
		"skip":
			if not can_skip(): return "Skip is available after 1am when every venue has stopped trading."
			count_tips()
			economy.advance_contracts(C.OPEN_MINUTE-int(s.street.minute))
			s.street.minute = C.OPEN_MINUTE
			reopen_noon()
			s.street.offline_cursor = C.OPEN_MINUTE
			result = "12pm. Check cleanliness, stock and the rota."
		"restock": result = economy.buy_supplier(bar)
		"manager": result = economy.buy_manager(bar)
		"upgrade":
			if bar.stage >= 3: return "This venue is at its final stage."
			var reason: String = economy.upgrade_reason(bar)
			if not reason.is_empty(): return reason
			if not pay(upgrade_cost(bar)): return "Save a little more for the renovation."
			bar.stage += 1
			if s.street.selected == 0:
				s.level = bar.stage
				if not s.street.reopening:
					s.street.reopening = true
					announce(0)
			result = C.TYPES[int(bar.type)].stages[int(bar.stage)-1][2]
		"buy":
			if index < 0 or index >= C.TYPES.size(): return "Unknown venue type."
			if s.street.bars.size() >= C.NAMES.size(): return "You own the whole soi. Keep developing your venues."
			if s.street.chapter < 1: return "Finish the Blue Hour reopening chapter before expanding."
			if s.rep < C.TYPES[index].rep: return "Needs %d reputation." % C.TYPES[index].rep
			if s.cash < purchase_cost(index)+opening_reserve(index): return "The lease needs ฿%d plus ฿%d for opening stock, hiring and the street payroll." % [purchase_cost(index),opening_reserve(index)]
			pay(purchase_cost(index))
			var new_bar := make_bar(index,s.street.bars.size())
			s.street.bars.append(new_bar)
			var defaults: Dictionary = economy.new_fields()
			for key in defaults: new_bar[key] = defaults[key]
			economy.ensure_stock_lots(new_bar)
			s.street.selected = s.street.bars.size()-1
			result = "%s opens. %s" % [new_bar.name,C.TYPES[index].stages[0][2]]
		"prepare":
			var event: Dictionary = s.street.event
			if event.is_empty() or event.phase != "warning": return "Preparation closes when the event starts."
			if event.prepared: return "Already prepared."
			if not pay(C.EVENTS[int(event.id)][3]): return "The preparation needs more cash."
			event.prepared = true
			result = C.EVENTS[int(event.id)][2] + " arranged."
		"festival":
			if s.street.chapter < 4 or not festival_ready(): return "Needs a stage-3 beer bar, Soi bar and gogo."
			if not s.street.event.is_empty(): return "Finish the current street event first."
			announce(9)
			result = "After Hours Street Festival announced. Prepare the street!"
		_:
			return "Unknown street action."
	reconcile_closures()
	settle_overnight()
	if not id in ["serve","welcome","stock","buy_drink","mixed_drinks","return_drink"]: record(result)
	check_chapters()
	return result

func festival_ready() -> bool:
	var kinds := {}
	for bar in s.street.bars:
		if bar.stage == 3: kinds[int(bar.type)] = true
	return kinds.size() == 3

func chapter_requirements() -> Array:
	var bars: Array = s.street.bars
	var managers := 0
	var has_soi := false
	var showroom := false
	for bar in bars:
		managers += int(bar.manager)
		has_soi = has_soi or bar.type == 1
		showroom = showroom or (bar.type == 2 and bar.stage >= 2)
	return [bars[0].stage >= 2 and bars[0].manager and s.street.served >= 10 and s.street.events_survived > 0,
		bars.size() >= 2, has_soi and managers >= 2, showroom, s.street.festival]

func check_chapters() -> void:
	var goals := chapter_requirements()
	while s.street.chapter < goals.size() and goals[int(s.street.chapter)]:
		s.street.chapter += 1
		var heading := "STORY COMPLETE" if s.street.chapter == 5 else "CHAPTER %d" % (int(s.street.chapter)+1)
		record("%s · %s" % [heading,C.CHAPTERS[int(s.street.chapter)][0]])

# Read-only guidance: no reward, purchase, chapter advance, RNG or save mutation.
func goal_cash(price: int, reserve: int) -> String:
	return "฿%d purchase + ฿%d kept in reserve; ฿%d still to save." % [price,reserve,maxi(0,price+reserve-int(s.cash))]

func next_goal() -> Dictionary:
	var chapter := int(s.street.chapter)
	var first: Dictionary = s.street.bars[0]
	var title := "The soi never sleeps"
	var detail := "Keep your mixed street healthy, try a different promotion or host the festival again. No reset required."
	var focus := ""
	var tab := 1
	if chapter<5 and chapter_requirements()[chapter]:
		return {"title":"Milestone ready","detail":"The business has earned its next chapter. Continue trading to record it.","focus":"","tab":0,"venue":0}
	if chapter==0:
		tab = 0
		if s.street.served<10:
			title = "Ice duty: the first ten drinks"
			detail = "%d/10 real orders served. Anong: Cold drinks first. Empire later. Serve waiting guests; welcome passersby when quiet." % mini(10,int(s.street.served))
			focus = "Buy %d drinks" % economy.pack_quantity(first) if first.stock==0 else "serve"
		elif first.regulars==0:
			title = "Give someone a reason to return"
			detail = "Keep orders moving and stock ready. Happy departures can earn your first regular. Anong: A second visit beats a five-star promise."
			focus = "TEAM & PAYROLL"
		elif first.stage<2:
			var target: Dictionary = C.STAGE_GOALS[0]
			title = "Make the Blue Hour a local favourite"
			detail = "%d/%d happy visits · %d/%d regulars · %d/%d healthy shifts. %s" % [mini(first.happy,target.happy),target.happy,mini(first.regulars,target.regulars),target.regulars,mini(first.healthy,target.healthy),target.healthy,goal_cash(upgrade_cost(first),economy.operating_rate(first)*2)]
			focus = "Upgrade ·"
		elif s.street.events_survived==0:
			title = "The reopening: keep the lights on"
			detail = "The new sign is ready. Check Events for Bo's generator offer and see the reopening through. A setback will not end the business."
			tab = 1
		elif not first.manager:
			if economy.on_duty(first,0)==0:
				title = "A colleague behind the counter"
				detail = "Hire or rehire a bartender for ฿%d and put them on duty. Training stays with them. Dao needs a serving team before taking the keys." % C.BARTENDER_CONTRACT_COST
				focus = "TEAM & PAYROLL"
			elif not first.restock:
				title = "Give Bo a standing order"
				detail = "Supplier level 1 automates paid deliveries when orders need stock. %s" % goal_cash(C.SUPPLIER_PRICES[0],economy.operating_rate(first)*2)
				focus = "SUPPLIER AGREEMENT"
			else:
				title = "Hand Dao the keys"
				var offer: Dictionary = economy.manager_offer(first)
				detail = "%s Dao enables managed offline trading and ฿10 per open second. %s" % [goal_cash(offer.price,(economy.operating_rate(first)+12)*2),"Ready to appoint." if offer.enabled else offer.reason]
				focus = "MANAGEMENT"
	elif chapter==1:
		title = "A second address on the soi"
		detail = "Anong: He's retiring again. This time, get the keys. Soi lease: %s Reputation %d/20. Other venue types remain your choice." % [goal_cash(purchase_cost(1),opening_reserve(1)),mini(20,int(s.rep))]
		tab = 3
	elif chapter==2:
		var managers := 0
		var soi := false
		for bar in s.street.bars:
			managers += int(bar.manager)
			soi = soi or bar.type==1
		title = "Trust the team with two venues"
		detail = "Soi venue: %s · managers %d/2. Each new bar must earn its own customers and healthy shifts. Dao: Two sets of keys. One owner who finally sits down." % ["owned" if soi else "still needed",mini(2,managers)]
		tab = 3
	elif chapter==3:
		title = "Give Anton something to worry about"
		detail = "Open a gogo and earn its second stage. Dancers attract; bartenders serve. Anton has ordered another screen. Pim suggests a better show."
		tab = 3
	elif chapter==4:
		var developed := [false,false,false]
		for bar in s.street.bars:
			if bar.stage==3: developed[int(bar.type)] = true
		title = "Bring the whole street together"
		detail = "Stage-three venues: beer %d/1 · Soi %d/1 · gogo %d/1. Then arrange the After Hours Street Festival in Events. The guest list includes something from the bay." % [int(developed[0]),int(developed[1]),int(developed[2])]
	return {"title":title,"detail":detail,"focus":focus,"tab":tab,"venue":0}

func announce(id: int) -> void:
	s.street.event = {"id":id,"phase":"warning","remaining":60,"prepared":false}
	record("COMING UP · " + C.EVENTS[id][0] + ": " + C.EVENTS[id][1])

func start_event() -> void:
	var event: Dictionary = s.street.event
	event.phase = "active"
	event.remaining = 90
	record("TONIGHT · " + C.EVENTS[int(event.id)][0])
	if event.id in [0,2,3,4] and not event.prepared:
		var protected: bool = (event.id == 2 and s.license >= 75 and s.safety >= 65) or (event.id == 3 and s.trust >= 60)
		if not protected:
			for bar in s.street.bars:
				bar.closed = 20 if event.id in [0,4] else 40
			if event.id == 2:
				var fine := mini(900,int(s.cash) / 5)
				pay(fine)
				record("Inspection: paperwork gaps. ฿%d fine; a short closure for corrections." % fine)

func finish_event(won: bool = true) -> void:
	if s.street.event.is_empty(): return
	var event: Dictionary = s.street.event
	var id := int(event.id)
	if id in [8,9]:
		if won:
			credit(1500 if id == 8 else 8000)
			s.rep = mini(100,int(s.rep)+5)
			record("Godzilla sleeps outside. The photo queue buys another round.")
		else:
			for bar in s.street.bars: bar.closed = 30
			record("Godzilla leaves a repair job. Venues reopen in 30 seconds; the business survives.")
		if id == 9:
			s.street.festival = true
			s.street.festivals += 1
	if id == 3 and event.prepared: s.trust = mini(100,int(s.trust)+8)
	if id == 5: s.rep = clampi(int(s.rep)+(4 if event.prepared else -2),0,100)
	if id == 6 and event.prepared: record("The locals appreciate the invitation. Good visits can earn their loyalty.")
	record(C.EVENTS[id][4])
	s.street.events_survived += 1
	s.street.event = {}
	s.street.event_wait = 180
	check_chapters()

func end_shift() -> void:
	s.street.seconds = 0
	for bar in s.street.bars:
		bar.away.clear()
		economy.settle_shift(bar)
	s.bookings.clear()
	s.night.erase("godzilla")

func clock_text() -> String:
	var hour := int(s.street.minute)/60
	return "%d:%02d%s" % [12 if hour%12==0 else hour%12,int(s.street.minute)%60,"am" if hour<12 else "pm"]

func any_trading() -> bool:
	for bar in s.street.bars:
		if economy.is_trading(bar): return true
	return false

func can_skip() -> bool:
	return s.phase=="plan" and s.street.minute>=C.CLOSE_MINUTE and s.street.minute<C.OPEN_MINUTE and not any_trading()

func night_ready() -> bool:
	if not can_skip(): return false
	# A temporary event closure must not end a venue's booked late night.
	for bar in s.street.bars:
		if bar.open and not bar.raided and Economy.scheduled(bar,int(s.street.minute)): return false
	return true

func count_tips() -> void:
	var report: Dictionary = economy.settle_tips()
	if report.amount>0:
		record("Anong counts the tip jars: %d served visits × ฿%d = ฿%d added to the till. Tomorrow's cold beer fund." % [report.visits,C.TIP_PER_VISIT,report.amount])

func night_prep_tick() -> void:
	if not night_ready(): return
	count_tips()
	if not night_prep_visible: return
	var prep: Dictionary = s.street.night_prep
	if int(prep.night)!=int(s.day):
		prep.night = int(s.day)
		prep.cancelled = false
		prep.remaining = C.CLEAN_SECONDS
		for bar in s.street.bars:
			if bar.dirt>0 and bar.clean_remaining==0:
				bar.clean_remaining = C.CLEAN_SECONDS
				bar.clean_auto_started = true
		return
	if prep.cancelled or int(prep.remaining)<=0: return
	prep.remaining -= 1
	if prep.remaining==0:
		action("skip")
		record("Clean-up finished. It's noon: a new opening, with the same stock and team.")
		checkpoint_requested.emit()

func night_prep_text() -> String:
	var tips := 0
	for bar in s.street.bars: tips += int(bar.last_tips.get("amount",0))
	return "Tips ฿%d counted · noon in %ds\nStay here · cancel automatic jump" % [tips,int(s.street.night_prep.remaining)]

func raid_chance() -> float:
	return C.RAID_BASE_CHANCE+C.RAID_HEAT_CHANCE*clampi(int(s.heat),0,100)

func reopen_noon() -> void:
	s.street.night_prep = {"night":-1,"remaining":0,"cancelled":false}
	for bar in s.street.bars:
		bar.late_open = false
		bar.raided = false
		bar.late_minutes = 0
		bar.clean_remaining = 0

func next_calendar_day() -> void:
	s.weekly.nights += 1
	if int(s.day)%7==0:
		s.last_week = s.weekly.duplicate()
		s.weekly = {"revenue":0,"costs":0,"guests":0,"tours":0,"nights":0,"weeks":int(s.day/7.0)+1}
	s.day += 1
	if int(s.day)%C.CELEBRATION_INTERVAL==5:
		var party_day := int(s.day)+2
		record("SAVE THE DATE · Day %d: %s at the Blue Hour. Anong: Two days to fill the fridge and sort the rota. The invitations are on us." % [party_day,Economy.celebration_name(party_day)])

func reconcile_closures() -> void:
	for bar in s.street.bars:
		# Temporary disaster closures preserve their existing queues and timers.
		if not bar.open or bar.raided or not Economy.scheduled(bar,int(s.street.minute)):
			economy.close_customers(bar)

func settle_overnight() -> void:
	if s.street.minute<C.CLOSE_MINUTE or s.street.minute>=C.OPEN_MINUTE or any_trading(): return
	if s.street.seconds>0:
		end_shift()
	if not s.street.guided.is_empty() and s.phase in ["guided","guided_choice"]:
		s.phase = "guided_report"

func raid(bar: Dictionary) -> void:
	if bar.raided or not economy.is_trading(bar) or s.street.minute<C.CLOSE_MINUTE or s.street.minute>=C.LATE_CLOSE_MINUTE: return
	var fine := mini(maxi(0,int(s.cash)),C.RAID_FINE_PER_STAGE*int(bar.stage))
	economy.cost(bar,fine,"fines")
	bar.raided = true
	economy.close_customers(bar)
	record("LATE RAID · %s fined ฿%d and closed until 12pm. Anong: That extra round came with paperwork." % [bar.name,fine])
	raid_checkpoint = true

func tick_heat() -> void:
	var late := false
	if s.street.minute>=C.CLOSE_MINUTE and s.street.minute<C.LATE_CLOSE_MINUTE:
		for bar in s.street.bars:
			if not economy.is_trading(bar): continue
			late = true
			bar.late_minutes += 1
			if int(bar.late_minutes)%C.HEAT_INTERVAL==0: s.heat = mini(100,int(s.heat)+1)
			if int(bar.late_minutes)%C.RAID_INTERVAL==0 and economy.roll(1000)<roundi(raid_chance()*10): raid(bar)
	if late:
		s.street.cool_seconds = 0
	else:
		s.street.cool_seconds += 1
		if s.street.cool_seconds>=C.COOL_SECONDS:
			s.heat = maxi(0,int(s.heat)-1)
			s.street.cool_seconds = 0

# Foreground only: the clock shares the live economy's decision/pause rules.
# Accumulate fractional foreground time without changing the fixed economy step.
func advance(delta: float) -> void:
	var remaining := clampf(delta,0.0,60.0)
	while remaining>0.0000001 and s.phase in ["plan","guided"]:
		var step := minf(remaining,1.0-float(s.street.tick_fraction))
		s.street.tick_fraction += step
		remaining -= step
		if s.street.tick_fraction>=0.9999999:
			s.street.tick_fraction = 0.0
			tick(1)

func tick(seconds: int) -> void:
	if not s.phase in ["plan","guided"]: return
	for _second in clampi(seconds,0,60):
		if not s.phase in ["plan","guided"]: break
		celebration_tick()
		reconcile_closures()
		var trading_now := any_trading()
		if trading_now: s.street.seconds += 1
		for bar in s.street.bars: economy.prep_tick(bar)
		tick_heat()
		economy.tick()
		economy.sample_earnings()
		s.street.cycle = (int(s.street.cycle)+1)%4
		for bar in s.street.bars: bar.closed = maxi(0,int(bar.closed)-1)
		var event: Dictionary = s.street.event
		if trading_now:
			if not event.is_empty():
				event.remaining -= 1
				if event.remaining<=0:
					if event.phase=="warning": start_event()
					else: finish_event(not int(event.id) in [8,9])
			elif s.street.chapter>=1 and not economy.celebration_window():
				s.street.event_wait -= 1
				if s.street.event_wait<=0:
					announce(1+int(s.street.event_index)%8)
					s.street.event_index += 1
		economy.advance_contracts(1)
		s.street.minute = (int(s.street.minute)+1)%C.DAY_MINUTES
		if s.street.minute==0: next_calendar_day()
		if s.street.minute==C.OPEN_MINUTE: reopen_noon()
		celebration_tick()
		s.street.offline_cursor = s.street.minute
		reconcile_closures()
		if s.street.seconds>=SHIFT_SECONDS:
			end_shift()
			if not s.street.guided.is_empty(): s.phase = "guided_report"
		elif trading_now and not s.street.guided.is_empty() and int(s.street.seconds)%40==0:
			s.street.guided.wave = int(s.street.seconds)/40
			s.phase = "guided_choice"
		settle_overnight()
		night_prep_tick()
		check_chapters()
		if raid_checkpoint:
			raid_checkpoint = false
			checkpoint_requested.emit()

func claim_offline(now: int) -> int:
	var earnings: int = economy.offline(now,OFFLINE_CAP)
	if earnings>0: record("Welcome back · managed venues earned an estimated ฿%d net, limited by demand and operating costs." % earnings)
	return earnings

func opening_reserve(kind: int) -> int:
	var amount := int(C.OVERHEAD[kind])*2+C.BARTENDER_CONTRACT_COST+140
	for bar in s.street.bars:
		if bar.open: amount += economy.operating_rate(bar)*2
	return amount
