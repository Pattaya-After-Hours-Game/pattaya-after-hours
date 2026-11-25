extends RefCounted

const C = preload("res://scripts/street_content.gd")
const Economy = preload("res://scripts/economy.gd")
const OFFLINE_CAP = 8 * 60 * 60
const SHIFT_SECONDS = 120
var s: Dictionary
var economy: RefCounted

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
	economy = Economy.new(s,fresh)
	s.version = 3

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
	if not bar.open or bar.closed > 0: return 0
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
		"serve","stock","hire","welcome","equipment","promotion","rota","role","open","recovery","bar_fine":
			result = economy.action(bar,id,index)
		"restock":
			if bar.restock: return "Bo already handles deliveries."
			if not pay(900): return "The supplier agreement needs ฿900."
			bar.restock = true
			result = "Bo handles restocking while you're here. Stock is still charged to the till."
		"manager":
			if bar.manager: return "This venue already has a manager."
			if bar.stage < 2 or economy.on_duty(bar,0) < 1 or not bar.restock or bar.healthy < 8: return "Needs stage 2, a bartender, deliveries and eight healthy shifts."
			if s.cash < 1800+(economy.operating_rate(bar)+12)*2 or not pay(1800): return "Keep one shift of operating costs after the ฿1,800 training fee."
			bar.manager = true
			result = "Dao takes the Blue Hour keys. Managed earnings continue offline." if s.street.selected == 0 else "%s's team takes the keys. Pim helps plan the music." % bar.name
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
	if not id in ["serve","welcome","stock"]: record(result)
	check_chapters()
	return result

func festival_ready() -> bool:
	var kinds := {}
	for bar in s.street.bars:
		if bar.stage == 3: kinds[int(bar.type)] = true
	return kinds.size() == 3

func check_chapters() -> void:
	var bars: Array = s.street.bars
	var managers := 0
	var has_soi := false
	var showroom := false
	for bar in bars:
		managers += int(bar.manager)
		has_soi = has_soi or bar.type == 1
		showroom = showroom or (bar.type == 2 and bar.stage >= 2)
	var goals := [bars[0].stage >= 2 and bars[0].manager and s.street.served >= 10 and s.street.events_survived > 0,
		bars.size() >= 2, has_soi and managers >= 2, showroom, s.street.festival]
	while s.street.chapter < goals.size() and goals[int(s.street.chapter)]:
		s.street.chapter += 1
		var heading := "STORY COMPLETE" if s.street.chapter == 5 else "CHAPTER %d" % (int(s.street.chapter)+1)
		record("%s · %s" % [heading,C.CHAPTERS[int(s.street.chapter)][0]])

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

# Called for foreground time only. No events or calendar changes during absence.
func tick(seconds: int) -> void:
	if not s.phase in ["plan","guided"]: return
	for _second in clampi(seconds,0,60):
		if not s.phase in ["plan","guided"]: break
		s.street.seconds += 1
		economy.tick()
		s.street.cycle = (int(s.street.cycle)+1) % 4
		for bar in s.street.bars:
			bar.closed = maxi(0,int(bar.closed)-1)
		var event: Dictionary = s.street.event
		if not event.is_empty():
			event.remaining -= 1
			if event.remaining <= 0:
				if event.phase == "warning": start_event()
				else: finish_event(not int(event.id) in [8,9])
		elif s.street.chapter >= 1:
			s.street.event_wait -= 1
			if s.street.event_wait <= 0:
				announce(1 + int(s.street.event_index) % 8)
				s.street.event_index += 1
		if s.street.seconds >= SHIFT_SECONDS:
			end_shift()
			s.weekly.nights += 1
			if int(s.day) % 7 == 0:
				s.last_week = s.weekly.duplicate()
				s.weekly = {"revenue":0,"costs":0,"guests":0,"tours":0,"nights":0,"weeks":int(s.day/7.0)+1}
			s.day += 1
			if not s.street.guided.is_empty():
				s.phase = "guided_report"
		elif not s.street.guided.is_empty() and int(s.street.seconds)%40 == 0:
			s.street.guided.wave = int(s.street.seconds)/40
			s.phase = "guided_choice"
		check_chapters()

func claim_offline(now: int) -> int:
	var earnings: int = economy.offline(now,OFFLINE_CAP)
	if earnings>0: record("Welcome back · managed venues earned an estimated ฿%d net, limited by demand and operating costs." % earnings)
	return earnings

func opening_reserve(kind: int) -> int:
	var amount := int(C.OVERHEAD[kind])*2+600+140
	for bar in s.street.bars:
		if bar.open: amount += economy.operating_rate(bar)*2
	return amount
