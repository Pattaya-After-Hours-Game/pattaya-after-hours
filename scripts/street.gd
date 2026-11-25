extends RefCounted

const C = preload("res://scripts/street_content.gd")
const OFFLINE_CAP = 8 * 60 * 60
const SHIFT_SECONDS = 120
var s: Dictionary

func _init(state: Dictionary) -> void:
	s = state
	if not s.has("street"):
		var first := make_bar(0, 0)
		first.stage = clampi(int(s.get("level",1)),1,3)
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
	s.version = 2

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
	return 30 + int(bar.stage) * 20

func staff_limit(bar: Dictionary) -> int:
	return int(bar.stage) * 2

func upgrade_cost(bar: Dictionary) -> int:
	return 0 if bar.stage >= 3 else int(C.UPGRADE_COSTS[int(bar.type)][int(bar.stage)-1])

func purchase_cost(kind: int) -> int:
	var owned := 0
	for bar in s.street.bars:
		if bar.type == kind: owned += 1
	return int(C.TYPES[kind].price) * (2 + owned) / 2

func drink_value(bar: Dictionary, offline: bool = false) -> int:
	var value := int(C.TYPES[int(bar.type)].drink) + (int(bar.stage)-1) * 25
	if offline: return value
	var event: Dictionary = s.street.event
	if event.get("phase","") != "active": return value
	match int(event.id):
		1: value = int(value * (2.0 if event.prepared else 1.4))
		4: value = int(value * (1.8 if bar.type == 0 else 1.2))
		5: value = int(value * (1.7 if event.prepared else 1.1))
		6: value = int(value * (0.95 if bar.type == 0 else 0.55))
		7: value = int(value * (1.4 if event.prepared else 0.8))
		9: value *= 2
	return value

func available(bar: Dictionary) -> int:
	return maxi(0,int(bar.crew) - bar.away.size())

func net_rate(bar: Dictionary, offline: bool = false) -> int:
	if offline and not bar.manager: return 0
	if bar.closed > 0 or (bar.stock <= 0 and not bar.restock): return 0
	var workers := available(bar)
	# 15 service rounds per minute. Quote profit after stock, wages and overhead.
	return 15 * workers * maxi(0,drink_value(bar,offline)-14-int(C.TYPES[int(bar.type)].wage))

func total_rate(offline: bool = false) -> int:
	var total := 0
	for bar in s.street.bars: total += net_rate(bar,offline)
	return total

func _sell(bar: Dictionary, count: int) -> int:
	if bar.closed > 0: return 0
	if bar.restock and bar.stock < count:
		var delivery := capacity(bar) - int(bar.stock)
		if pay(delivery * 14): bar.stock += delivery
	var sold := mini(count,int(bar.stock))
	if sold <= 0: return 0
	bar.stock -= sold
	credit(drink_value(bar) * sold, int(C.TYPES[int(bar.type)].wage) * sold)
	var before := int(s.street.served)
	s.street.served += sold
	s.total_guests += sold
	s.weekly.guests += sold
	# Reputation comes from reliable service, including automated service.
	s.rep = mini(100,int(s.rep) + int(s.street.served / 20.0) - int(before / 20.0))
	if before < 10 and s.street.served >= 10:
		s.regulars += 1
		record("Your first new regular: Lek buys a round and declares himself a founding investor.")
	return sold

func action(id: String, index: int = 0) -> String:
	if s.phase != "plan": return "Finish the current shift first."
	var bar := selected()
	var result := ""
	match id:
		"serve":
			if _sell(bar,1) == 0: return "Temporarily closed." if bar.closed > 0 else "Out of drinks. Order a delivery."
			result = "Served at %s · +฿%d after wages" % [bar.name,drink_value(bar)-int(C.TYPES[int(bar.type)].wage)]
		"stock":
			var amount := capacity(bar)-int(bar.stock)
			if amount == 0: return "The fridge is full."
			if not pay(amount*14): return "Delivery needs ฿%d." % (amount*14)
			bar.stock += amount
			result = "Bo found the right bar. %d drinks delivered." % amount
		"hire":
			if bar.crew >= staff_limit(bar): return "Upgrade for more team positions."
			var cost := 600 * (int(bar.crew)+1)
			if not pay(cost): return "Hiring needs ฿%d." % cost
			bar.crew += 1
			result = "An adult %s joins %s. Service now runs automatically." % [["server","host","dancer"][int(bar.type)],bar.name]
		"restock":
			if bar.restock: return "Bo already handles deliveries."
			if not pay(900): return "The supplier agreement needs ฿900."
			bar.restock = true
			result = "Bo handles restocking while you're here. Stock is still charged to the till."
		"manager":
			if bar.manager: return "This venue already has a manager."
			if bar.stage < 2 or bar.crew < 1 or not bar.restock: return "Needs stage 2, a server and automatic deliveries."
			if not pay(1800): return "Management training needs ฿1,800."
			bar.manager = true
			result = "Dao takes the Blue Hour keys. Managed earnings continue offline." if s.street.selected == 0 else "%s's team takes the keys. Pim helps plan the music." % bar.name
		"upgrade":
			if bar.stage >= 3: return "This venue is at its final stage."
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
			if not pay(purchase_cost(index)): return "The lease needs ฿%d." % purchase_cost(index)
			var new_bar := make_bar(index,s.street.bars.size())
			s.street.bars.append(new_bar)
			s.street.selected = s.street.bars.size()-1
			result = "%s opens. %s" % [new_bar.name,C.TYPES[index].stages[0][2]]
		"bar_fine":
			if bar.type != 1 or bar.closed > 0: return "Available at an open Soi bar."
			if index < 0 or index >= bar.crew: return "This host isn't on the team."
			if not C.HOSTS[index][2]: return "%s declines. Hosted drinks are their preference." % C.HOSTS[index][0]
			if index in bar.away: return "Already away for this shift."
			if bar.away.size() >= bar.stage: return "Upstairs bookings are full this shift."
			bar.away.append(index)
			credit(300 * int(bar.stage),100 * int(bar.stage))
			result = "%s accepts. Bar fee recorded; host unavailable until next shift. Private activity stays off-screen." % C.HOSTS[index][0]
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
	if id != "serve": record(result)
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
	if id == 6 and event.prepared: s.regulars = mini(45,int(s.regulars)+3)
	record(C.EVENTS[id][4])
	s.street.events_survived += 1
	s.street.event = {}
	s.street.event_wait = 180
	check_chapters()

func end_shift() -> void:
	s.street.seconds = 0
	for bar in s.street.bars: bar.away.clear()
	s.night.erase("godzilla")

# Called for foreground time only. No events or calendar changes during absence.
func tick(seconds: int) -> void:
	if s.phase != "plan": return
	for _second in clampi(seconds,0,60):
		s.street.seconds += 1
		s.street.cycle = (int(s.street.cycle)+1) % 4
		for bar in s.street.bars:
			bar.closed = maxi(0,int(bar.closed)-1)
			if s.street.cycle == 0: _sell(bar,available(bar))
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
		check_chapters()

func claim_offline(now: int) -> int:
	var last := int(s.street.last_seen)
	var elapsed := clampi(now-last,0,OFFLINE_CAP)
	# A future timestamp never grants a windfall or moves the watermark backwards.
	s.street.last_seen = maxi(last,now)
	var earnings := int(total_rate(true) * elapsed / 60.0)
	s.street.offline = earnings
	if earnings > 0:
		credit(earnings)
		record("Welcome back · managed venues earned ฿%d net. No disasters ran while you were away." % earnings)
	return earnings
