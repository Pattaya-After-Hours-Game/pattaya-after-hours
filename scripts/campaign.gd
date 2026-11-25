extends RefCounted

const C = preload("res://scripts/content.gd")
const SAVE = "user://campaign.json"
const BACKUP = "user://campaign.backup"
const Street = preload("res://scripts/street.gd")
const HOURS = ["Early close", "Standard", "Late close"]
const PROMOS = ["Regular prices", "Happy hour", "Loyalty night", "Big campaign"]
const SECURITY = ["House team", "Licensed crew", "Shoreline Desk"]
const WEEKDAYS = ["Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue"]
const FIGHT_CARD = 41
const CANCEL_IF_DISRUPTED = 0.38
const SCALE_BACK = {"capacity":-8,"rep":-2,"trust":-1}
const NIGHT_EFFECTS = ["demand","capacity","tour","mine"]
const TEAM_EFFECTS = ["skill","morale","fatigue"]
const LOWER_IS_BETTER = ["heat","fatigue","rival"]
const COMMITMENTS = ["reserve","debt","security","exit"]
var s: Dictionary
var street: RefCounted
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0, practice: bool = false) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	s = {
		"practice": practice, "version": 1, "day": 1, "phase": "plan", "cash": 6400, "reserve": 0, "debt": 0,
		"stock": 62, "rep": 15, "regulars": 4, "trust": 38, "heat": 5, "safety": 65,
		"partner": 63, "visa": 75, "license": 80, "supplier": 58, "rival": 14, "condition": 72,
		"staff": [], "level": 1, "venue": 1, "rig": 0, "market": 100, "contract": 0,
		"route": 0, "food": 0, "exit": 0, "weather": 0, "forecast": 0,
		"hours": 1, "promo": 0, "event": 0, "security": 0, "pay": 1,
		"bookings": {}, "night": {}, "card": -1, "seen": [], "report": [],
		"weekly": {}, "last_week": {}, "total_guests": 0, "wins": 0, "end": "", "rng": 0,
		"log": ["Anong: The pool table can wait. Pay the team first."],
	}
	for i in 3:
		_add_staff(i)
	_reset_week()
	_forecast()
	street = Street.new(s,not practice)
	s.street.economy_seed = maxi(1,seed_value) if seed_value != 0 else rng.randi_range(1,2147483646)

func _add_staff(id: int) -> void:
	s.staff.append({"id":id,"skill":C.STAFF[id][2],"guide":C.STAFF[id][3],"morale":72,"fatigue":12,"work":true,"hurt":0})

func _reset_week() -> void:
	s.weekly = {"revenue":0,"costs":0,"guests":0,"tours":0,"nights":0,"weeks":week()}

func week() -> int:
	return int((s.day - 1) / 7.0) + 1

func weekday() -> String:
	return WEEKDAYS[(int(s.day) - 1) % 7]

func _forecast() -> void:
	s.weather = rng.randi_range(0, C.WEATHER.size() - 1)
	if s.day <= 5:
		s.weather = rng.randi_range(0, 4)
	s.forecast = rng.randi_range(-4, 10) + (10 if weekday() in ["Fri","Sat"] else 0)
	s.market = clampi(int(s.market) + rng.randi_range(-23, 25), 38, 210)

func spend(cost: int) -> bool:
	if s.cash < cost:
		return false
	s.cash -= cost
	s.weekly.costs += cost
	return true

func log_message(message: String) -> void:
	s.log.push_front(message)
	if s.log.size() > 30:
		s.log.pop_back()

func stock_price() -> int:
	return 24 - int(s.supplier / 12.0) + (5 if s.weather == 6 else 0)

func tour_offer(index: int, route_id: int) -> String:
	var staff: Dictionary = s.staff[index]
	var route: Array = C.ROUTES[route_id]
	if not staff.work or staff.hurt > 0:
		return "Off duty."
	if staff.guide == 0:
		return "Doesn't take guide shifts."
	if route[2] == 2 and staff.guide < 4:
		return "Prefers short routes."
	if staff.morale < 44 or staff.fatigue > 72 or (route[2] == 2 and staff.fatigue > 55):
		return "Declines the extra hours."
	if s.weather == 6 and (route_id == 1 or route_id == 3):
		return "Declines an exposed route in monsoon rain."
	return ""

func event_disruption_percent() -> int:
	return 29 if s.weather >= 5 else 9

func tour_disruption_percent(staff: Dictionary, route_id: int) -> int:
	var weather_risk := 20 if s.weather == 6 else 5 if s.weather >= 4 else 0
	return maxi(0,7 + int(C.ROUTES[route_id][3]) + weather_risk - int(staff.guide)*2)

func guide_pay(route_id: int) -> int:
	var duration: int = C.ROUTES[route_id][2]
	return duration * [100, 145, 190][int(s.pay)]

func booking(index: int, route_id: int) -> String:
	if s.phase != "plan":
		return "Bookings are closed."
	var key := str(index)
	if s.bookings.get(key, -1) == route_id:
		s.bookings.erase(key)
		return "Booking removed."
	var declined := tour_offer(index, route_id)
	if not declined.is_empty():
		return "%s %s" % [C.STAFF[s.staff[index].id][0], declined]
	if s.pay == 0 and C.ROUTES[route_id][2] == 2:
		return "The guide asks for standard split or better on long routes."
	if not legacy_mode() and not spend(guide_pay(route_id)): return "The guide needs their agreed pay upfront."
	s.bookings[key] = route_id
	return "Confirmed. Guide pay ฿%d." % guide_pay(route_id)

func action(id: String, index: int = 0) -> String:
	if not legacy_mode() and id in ["buy","hire","rota","train","reno"]:
		return street.action({"buy":"stock","hire":"hire","rota":"rota","train":"equipment","reno":"upgrade"}[id],6 if id=="train" else index)
	if s.phase != "plan":
		return "Finish the current night first."
	match id:
		"buy":
			var amount := mini(30, 105 + int(s.level) * 20 - int(s.stock))
			if amount <= 0: return "Storage is full."
			if not spend(amount * stock_price()): return "The till can't cover the delivery."
			s.stock += amount
			s.supplier = mini(100, s.supplier + 2)
			return "%d stock delivered." % amount
		"rota":
			var staff: Dictionary = s.staff[index]
			if staff.hurt > 0: return "On paid recovery leave for %d more nights." % staff.hurt
			staff.work = not staff.work
			if not staff.work:
				s.bookings.erase(str(index))
			return "%s is %s." % [C.STAFF[staff.id][0], "on the rota" if staff.work else "off tonight"]
		"train":
			var staff: Dictionary = s.staff[index]
			if staff.skill >= 8: return "Already fully trained."
			if staff.hurt > 0: return "Let them recover first."
			if not spend(410): return "Training costs ฿410."
			staff.skill += 1
			if staff.guide > 0: staff.guide = mini(8, int(staff.guide) + 1)
			staff.morale = mini(100, staff.morale + 5)
			return "Session booked and paid."
		"hire":
			if s.staff.size() >= C.STAFF.size(): return "All six posts are filled."
			if not spend(980): return "Recruitment costs ฿980."
			_add_staff(s.staff.size())
			return "%s joined the team." % C.STAFF[s.staff.back().id][0]
		"reno":
			var previous: int = s.street.selected
			s.street.selected = 0
			var result: String = street.action("upgrade")
			s.street.selected = previous
			return result
		"repair":
			if s.condition == 100: return "Everything is working."
			if not spend(500): return "Repairs cost ฿500."
			s.condition = mini(100, s.condition + 20)
			s.safety = mini(100, s.safety + 4)
			return "Repairs complete."
		"food":
			if s.food: return "Nok's small plates are already on the menu."
			if not spend(1050): return "A food counter costs ฿1,050."
			s.food = 1
			return "Small plates increase spend and keep quiet shifts viable."
		"venue":
			return street.action("buy",0)
		"rig":
			if s.rig > 0: return "The rig is already installed."
			if s.day < 12 or s.rep < 25: return "Available from day 12 with 25 reputation."
			if not spend(5600): return "A starter rig costs ฿5,600."
			s.rig = 88
			return "The rig is installed. Watch the power bill and cooling."
		"cool":
			if s.rig == 0: return "Install the rig first."
			if s.rig >= 100: return "Cooling is already at full condition."
			if not spend(680): return "Maintenance costs ฿680."
			s.rig = mini(100, int(s.rig) + 32)
			return "Cooling serviced."
		"mine_switch":
			if s.rig == 0: return "Install the rig first."
			s.contract = (int(s.contract) + 1) % 3
			if s.contract == 2: s.rival = mini(100, int(s.rival) + 4)
			return ["Power offline.","Independent mining enabled.","Lantern syndicate deal enabled."][s.contract]
		"reserve":
			if not spend(500): return "You need ฿500 in the till."
			s.weekly.costs -= 500
			s.reserve += 500
			s.partner = mini(100, int(s.partner) + 1)
			return "฿500 moved into reserve."
		"draw":
			if s.reserve <= 0: return "Reserve is empty."
			var amount := mini(500, int(s.reserve))
			s.reserve -= amount
			s.cash += amount
			return "฿%d released from reserve." % amount
		"paper":
			if not spend(330): return "Admin time costs ฿330."
			s.license = mini(100, int(s.license) + 12)
			s.visa = mini(100, int(s.visa) + 16)
			s.heat = maxi(0, int(s.heat) - 4)
			return "Anong and Dao check the folders."
		"rival":
			if not spend(420): return "The joint neighborhood night costs ฿420."
			s.rival = maxi(0, int(s.rival) - 14)
			s.trust = mini(100, int(s.trust) + 4)
			return "Anton agrees to share festival dates."
	return ""

func legacy_mode() -> bool:
	return s.get("practice",false) or s.get("legacy_shift",false)

func start() -> String:
	if not legacy_mode():
		if s.phase != "plan": return "Finish the current decision first."
		s.street.guided = {"wave":int(s.street.seconds)/40}
		s.phase = "guided_choice"
		return "The guided shift uses the same customers, stock and clock."
	if s.phase != "plan":
		return ""
	var workers := 0
	for staff in s.staff:
		if staff.work and staff.hurt == 0: workers += 1
	if workers == 0:
		return "Put at least one available team member on the rota."
	var event: Array = C.EVENTS[int(s.event)]
	if not spend(event[1]):
		return "The till can't cover the booking. Try regular service."
	s.night = {"wave":0,"cash":-event[1],"demand":0,"capacity":0,"tour":0,"mine":100,"guests":0,
		"event_live":s.event,"gross":0,"sold":0,"turned":0,"tours":0,"wages":0,"fees":0,"fight":0,"notes":[]}
	if s.event > 0 and rng.randf() < event_disruption_percent() / 100.0:
		if rng.randf() < CANCEL_IF_DISRUPTED:
			s.night.event_live = 0
			s.night.notes.append("%s cancelled · booking deposit lost" % event[0])
		else:
			s.night.notes.append("%s delayed · starts at the rush" % event[0])
			s.night.delayed = true
	s.phase = "incident"
	s.card = _draw_card()
	return ""

func start_street_boss() -> String:
	var event: Dictionary = s.street.event
	if s.phase != "plan" or event.get("phase","") != "active" or not int(event.get("id",-1)) in [8,9]:
		return "Wait for the announced monster event."
	s.night = {"godzilla":"attack", "street_boss":true}
	s.phase = "godzilla"
	return ""

func finish_godzilla(won: bool) -> void:
	if s.phase != "godzilla": return
	if s.night.get("street_boss",false):
		street.finish_event(won)
		s.night.godzilla = "asleep" if won else "scared"
		s.phase = "plan"
		return
	if won:
		s.night.godzilla = "asleep"
		s.night.notes.append("Godzilla passed out on the curb. The bar stayed open.")
		s.phase = "incident"
		s.card = _draw_card()
	else:
		s.night.godzilla = "scared"
		s.night.notes.append("Godzilla scared off the crowd. No bar sales tonight.")
		_close()

func rest() -> void:
	if not legacy_mode():
		if street.selected().open: street.action("open")
		return
	if s.phase != "plan": return
	s.bookings.clear()
	s.event = 0
	s.night = {"cash":0,"event_live":0,"tour":0,"guests":0,"gross":0,"sold":0,
		"turned":0,"tours":0,"wages":0,"fees":0,"mine":100,"rest":true,
		"notes":["Closed for team recovery · utilities and paid leave still due"]}
	_close()

func _draw_card() -> int:
	if s.day == 6 and s.night.wave == 1: return 20
	if s.day == 8 and s.night.wave == 1: return FIGHT_CARD
	if s.day == 13 and s.night.wave == 1: return 42
	var pool: Array[int] = []
	var prefer_good := rng.randf() < (0.54 if s.safety > 60 else 0.41)
	for id in C.GOOD.size() + C.BAD.size():
		if (id < C.GOOD.size()) != prefer_good or id in s.seen: continue
		if id == 8 or id == 24 or id == 34:
			if s.bookings.is_empty(): continue
		if id == 36 and (s.rig <= 0 or s.contract == 0): continue
		if id == 38 and s.security != 2: continue
		if id == FIGHT_CARD and (s.day < 8 or s.rival < 26 or rng.randf() > 0.35): continue
		if id == 42 and s.weather < 5: continue
		pool.append(id)
	if pool.is_empty():
		s.seen.clear()
		return _draw_card()
	return pool[rng.randi_range(0, pool.size() - 1)]

func current_card() -> Array:
	var id: int = s.card
	if id >= 100: return C.STORY[id - 100].slice(1)
	return C.GOOD[id] if id < C.GOOD.size() else C.BAD[id - C.GOOD.size()]

func pick(index: int) -> String:
	if s.phase == "guided_choice":
		if not index in [0,1,2]: return "Unknown response."
		if index == 0: street.economy.serve(street.selected(),1,true)
		elif index == 1: street.economy.action(street.selected(),"welcome",0)
		s.phase = "guided"
		return "Service continues on the live clock."
	if s.phase != "incident": return ""
	var card := current_card()
	var offset := 2 + index * 2
	if offset < 2 or offset + 1 >= card.size(): return ""
	var effects: Dictionary = card[offset + 1]
	if s.cash < -int(effects.get("cash",0)):
		return "The till can't cover that response."
	s.night.notes.append("%s · %s" % [card[0], card[offset]])
	if s.card < 100:
		s.seen.append(s.card)
		if s.seen.size() > 35: s.seen.pop_front()
	if effects.has("fight"):
		s.phase = "fight"
	else:
		_roll_response(card[offset],effects)
	return ""

func response_risk(effects: Dictionary) -> Dictionary:
	var readiness: int = s.trust
	if effects.has("supplier") or effects.has("stock"):
		readiness = s.supplier
	elif effects.has("partner") or effects.has("visa"):
		readiness = s.partner
	elif effects.has("morale") or effects.has("fatigue"):
		var tired := 0
		for staff in s.staff: tired += int(staff.fatigue)
		readiness = 100 - int(tired / float(maxi(1,s.staff.size())))
	elif effects.has("rig") or effects.has("mine"):
		readiness = s.rig
	elif effects.has("demand") or effects.has("capacity") or effects.has("safety"):
		readiness = s.safety
	var crowd_swing := maxi(absi(int(effects.get("demand",0))),absi(int(effects.get("capacity",0))))
	var chance := clampi(68 + roundi((readiness - 50) * 0.35) - int(crowd_swing / 2.0),30,90)
	var setback := effects.duplicate()
	for key in effects:
		var amount: int = effects[key]
		if key in COMMITMENTS or (key == "cash" and (amount <= 0 or effects.has("debt"))) or (key == "mine" and amount <= -100):
			continue
		var direction := -1 if key in LOWER_IS_BETTER else 1
		if amount * direction > 0:
			if key in ["cash","stock","capacity","demand","tour","mine","route","food"]:
				setback[key] = int(amount * 0.35)
			else:
				setback[key] = -direction * maxi(1,ceili(absi(amount) * 0.35))
		else:
			setback[key] = amount - direction * maxi(1,ceili(absi(amount) * 0.55))
	var plan_changes := preview_effects(effects)
	var setback_changes := preview_effects(setback)
	if setback_changes == plan_changes:
		# Even when stats hit their limits, the setback incurs a visible cost.
		setback["debt"] = int(setback.get("debt",0)) + 100
		setback_changes = preview_effects(setback)
		if setback_changes == plan_changes:
			setback["debt"] = 100
			setback_changes = preview_effects(setback)
	return {"chance":chance,"setback":setback,"plan_changes":plan_changes,"setback_changes":setback_changes}

func preview_effects(effects: Dictionary) -> Dictionary:
	return _apply(effects,s.duplicate(true))

func _roll_response(label: String, effects: Dictionary) -> void:
	var risk := response_risk(effects)
	var worked := rng.randi_range(1,100) <= int(risk.chance)
	var changes := _apply(effects if worked else risk.setback,s)
	_record_result(label,"Goes to plan" if worked else "Setback",int(risk.chance) if worked else 100-int(risk.chance),changes,worked)
	_service()

func _record_result(label: String, outcome: String, chance: int, changes: Dictionary, worked: bool) -> void:
	if not s.night.has("results"): s.night.results = []
	s.night.results.append({"label":label,"outcome":outcome,"chance":chance,"changes":changes,"worked":worked})

func _apply(effects: Dictionary, target: Dictionary) -> Dictionary:
	var changes := {}
	for key in effects:
		var amount: int = effects[key]
		if key in TEAM_EFFECTS:
			var team_changes: Array[int] = []
			for staff in target.staff:
				var before: int = staff[key]
				staff[key] = clampi(before + amount, 0, 8 if key == "skill" else 100)
				team_changes.append(int(staff[key])-before)
			if team_changes.min() != 0 or team_changes.max() != 0:
				changes[key] = team_changes
			continue
		var values: Dictionary = target.night if key in NIGHT_EFFECTS else target
		var before: int = values[key]
		match key:
			"cash":
				values.cash += amount
				target.night.cash += amount
				if amount < 0: target.weekly.costs -= amount
				else: target.weekly.revenue += amount
			"demand","capacity","tour","mine":
				values[key] += amount
			"stock":
				values.stock = clampi(before+amount, 0, 105 + int(target.level) * 20)
			"regulars":
				values.regulars = clampi(before+amount, 0, 45)
			"debt","reserve":
				values[key] = maxi(0,before+amount)
			"security","food","exit","route":
				values[key] = clampi(before+amount, 0, 2)
			_:
				values[key] = clampi(before+amount, 0, 100)
		if int(values[key]) != before:
			changes[key] = int(values[key]) - before
	return changes

func fallback() -> void:
	if s.phase == "guided_choice":
		pick(2)
		return
	if s.phase != "incident": return
	s.night.notes.append("%s · reduced service" % current_card()[0])
	if s.card < 100:
		s.seen.append(s.card)
		if s.seen.size() > 35: s.seen.pop_front()
	_roll_response("Scale back service",SCALE_BACK)

func fight_effects(won: bool) -> Dictionary:
	var repair := mini(maxi(0, int(s.cash)), 240 if won else 740)
	return {"cash":-repair,"debt":(240 if won else 740)-repair,"capacity":-7 if won else -16,
		"heat":6 if won else 12,"safety":-3 if won else -10,"rep":3 if won else -5,
		"rival":-16 if won else 8,"condition":-3 if won else -9,"morale":2 if won else -8}

func finish_fight(won: bool) -> void:
	if s.phase != "fight": return
	if won: s.wins += 1
	var changes := _apply(fight_effects(won),s)
	_record_result("Back Mali in the arcade showdown","Mali won" if won else "Mali lost",0,changes,won)
	if not won:
		s.staff[1].hurt = 3
		s.staff[1].work = false
		s.bookings.erase("1")
	s.night.notes.append("Mali held the floor · repair bill filed" if won else "Mali needs paid recovery leave · room damaged")
	_service()

func _service() -> void:
	var n: Dictionary = s.night
	var wave: int = n.wave
	var live_event: int = 0 if wave == 0 and n.get("delayed",false) else n.event_live
	var event: Array = C.EVENTS[live_event]
	var capacity := 0
	var fatigue := 0
	var on_duty := 0
	for i in s.staff.size():
		var staff: Dictionary = s.staff[i]
		if not staff.work or staff.hurt > 0: continue
		on_duty += 1
		fatigue += staff.fatigue
		var role_capacity := 11 + int(staff.skill) * 2 + int(staff.morale / 25.0) - int(staff.fatigue / 13.0)
		if s.bookings.has(str(i)) and wave < C.ROUTES[int(s.bookings[str(i)])][2]: role_capacity /= 3
		capacity += role_capacity
	var seasonal := -7 if int(s.day) % 84 > 63 else 0
	var demand := 23 + int(s.forecast) + int(s.rep / 10.0) + int(s.regulars / 3.0) + seasonal
	demand += [0,6,4,11][int(s.promo)] + [0,2,7][int(s.hours)] + int(event[2]) + int(s.food) * 4
	demand += [0,6,-5][wave] + int(n.demand) + rng.randi_range(-5,6) + (14 if s.venue == 2 else 0)
	demand -= (8 if s.weather == 6 else 2 if s.weather == 5 else 0) + int(s.rival / 13.0)
	var room := 39 + int(s.level) * 4 + (22 if s.venue == 2 else 0)
	if event[3] > 0: room = maxi(room, event[3])
	if live_event > 0 and s.security == 0: room -= 9
	if s.condition < 30: room -= 13
	if s.license < 30: room -= 10
	room += int(n.capacity)
	capacity += int(n.capacity)
	var stock_capacity := int(s.stock) * 2
	var served := maxi(0, mini(mini(demand, room), mini(capacity, stock_capacity)))
	var units := ceili(served / 2.0)
	var refused := maxi(0, demand - served)
	var price: int = [57,47,53,58][int(s.promo)] + int(s.food) * 12 + int(s.level) * 4
	var revenue: int = served * price + (served * (10 if live_event == 1 else 9) if live_event > 0 else 0)
	s.stock -= units
	s.cash += revenue
	n.gross += revenue
	n.cash += revenue
	n.sold += units
	n.guests += served
	n.turned += refused
	s.weekly.revenue += revenue
	var satisfaction := clampi(86 - refused * 2 - maxi(0, int(fatigue / float(maxi(1,on_duty))) - 45) + int(s.safety / 10.0), 0, 100)
	s.rep = clampi(int(s.rep) + (2 if served > 12 and satisfaction >= 76 else -2 if satisfaction < 56 else 0), 0, 100)
	var limit := ""
	if refused > 0:
		limit = "low stock" if stock_capacity <= mini(room,capacity) else "room limit" if room <= capacity else "staff capacity"
	n.last_wave = {"served":served,"missed":refused,"sales":revenue,"limit":limit}
	n.notes.append("%s · %d served / %d missed · ฿%d sales · %d%% satisfaction%s" % [
		["Early","Peak","Last call"][wave],served,refused,revenue,satisfaction," · "+limit if not limit.is_empty() else ""])
	n.demand = 0
	n.capacity = 0
	n.wave += 1
	if n.wave < (2 if s.hours == 0 else 3):
		s.card = _draw_card()
		s.phase = "incident"
	else:
		_close()

func _bill(amount: int) -> void:
	s.cash -= amount
	s.night.cash -= amount
	s.weekly.costs += amount

func _close() -> void:
	var n: Dictionary = s.night
	var rest_night: bool = n.get("rest",false)
	var wage := 0
	var tour_net := int(n.tour)
	for i in s.staff.size():
		var staff: Dictionary = s.staff[i]
		if (staff.work and not rest_night) or staff.hurt > 0:
			wage += C.STAFF[int(staff.id)][4] + (100 if s.hours == 2 and staff.hurt == 0 else 0)
		if staff.work and staff.hurt == 0 and not rest_night:
			staff.fatigue = mini(100, int(staff.fatigue) + [2,6,12][int(s.hours)] + (4 if n.turned > 30 else 0))
			staff.morale = clampi(int(staff.morale) + (2 if n.turned < 24 else -3) - (5 if staff.fatigue > 72 else 0),0,100)
		else:
			staff.fatigue = maxi(0, int(staff.fatigue) - 25)
			staff.morale = mini(100, int(staff.morale) + 4)
		if staff.hurt > 0: staff.hurt -= 1
		if s.bookings.has(str(i)):
			var route_id := int(s.bookings[str(i)])
			var route: Array = C.ROUTES[route_id]
			var pay := guide_pay(route_id)
			wage += pay
			var groups := clampi(3 + int(staff.guide / 2.0) + rng.randi_range(-2,1) - (2 if s.weather >= 5 else 0) - (1 if s.weather == 4 else 0),1,7)
			var ticket := int(route[1]) + int(s.route) * 35
			if rng.randi_range(0,99) < tour_disruption_percent(staff,route_id):
				groups = maxi(0, groups - 3)
				n.notes.append("%s · disrupted, guide still paid" % route[0])
			tour_net += groups * ticket
			n.tours += groups
			staff.fatigue = mini(100, int(staff.fatigue) + int(route[2]) * 6)
			staff.morale = mini(100, int(staff.morale) + int(s.pay) * 2)
	tour_net = maxi(0,tour_net)
	s.cash += tour_net
	n.cash += tour_net
	s.weekly.revenue += tour_net
	n.wages = wage
	_bill(wage)
	var security_fee: int = 0 if rest_night else [0,480,255][int(s.security)]
	s.safety = clampi(int(s.safety) + [0,4,2][int(s.security)] - int(n.turned / 25.0),0,100)
	s.heat = clampi(int(s.heat) + int(C.EVENTS[int(n.event_live)][4]) + (2 if s.hours == 2 else -2) + (3 if s.security == 2 else -1 if s.security == 1 else 0) - int(s.license / 45.0),0,100)
	n.fees = security_fee + 380 + 260 * (int(s.venue) - 1)
	_bill(n.fees)
	if s.rig > 0 and s.contract > 0:
		var output := maxi(0, int((int(s.market) * 9 + rng.randi_range(-170,220)) * int(s.rig) * maxi(0,int(n.mine)) / 10000.0))
		var power := 560 + (150 if s.weather == 6 else 0)
		if s.contract == 2:
			output = int(output * 1.38)
			power += 110
			s.heat = mini(100, int(s.heat) + 4)
			s.rival = mini(100, int(s.rival) + 3)
		s.cash += output
		n.cash += output
		s.weekly.revenue += output
		_bill(power)
		s.rig = maxi(1, int(s.rig) - rng.randi_range(2,5))
		n.notes.append("Rig output ฿%d · power ฿%d" % [output,power])
	if not rest_night: s.condition = maxi(5, int(s.condition) - (2 if n.guests > 110 else 1))
	s.license = maxi(0, int(s.license) - (2 if s.heat >= 65 else 0))
	if s.heat >= 74 and rng.randf() < 0.45:
		_bill(900)
		n.notes.append("Surprise compliance visit · ฿900 fine")
	s.rival = clampi(int(s.rival) + (2 if n.guests > 105 else -1),0,100)
	s.weekly.guests += n.guests
	s.weekly.tours += n.tours
	s.weekly.nights += 1
	s.total_guests += n.guests
	if int(s.day) % 7 == 0:
		var recurring := 2850 * int(s.venue) + 640 + mini(1200,int(s.debt))
		s.debt = maxi(0, int(s.debt) - 1200)
		_bill(recurring)
		s.license = maxi(0, int(s.license) - 7)
		s.visa = maxi(0, int(s.visa) - 9)
		n.notes.append("Tuesday rent, permits and installments · ฿%d" % recurring)
		if s.cash < 0 and s.reserve > 0:
			var covered := mini(-int(s.cash),int(s.reserve))
			s.reserve -= covered
			s.cash += covered
			n.notes.append("Reserve covered ฿%d" % covered)
	if s.cash < 0:
		s.debt -= s.cash
		n.notes.append("Unpaid balance carried forward · ฿%d" % -int(s.cash))
		s.cash = 0
	if s.visa == 0:
		_bill(450)
		if s.cash < 0:
			s.debt -= s.cash
			s.cash = 0
		n.notes.append("Paperwork lapsed · Dao covered the floor")
	if int(s.day) % 7 == 0: s.last_week = s.weekly.duplicate()
	s.report = n.notes.duplicate()
	s.phase = "report"
	if s.debt >= 11500:
		n.notes.append("Anong arranges a repayment plan. The street remains open; idle profits can fund recovery.")
	s.end = ""
	street.check_chapters()
	log_message("Day %d · %+d net · %d guests" % [s.day,n.cash,n.guests])

func next_day() -> void:
	if s.phase == "guided_report":
		s.street.guided = {}
		s.phase = "plan"
		return
	if s.phase != "report": return
	if not s.end.is_empty():
		s.phase = "end"
		return
	var reset := int(s.day) % 7 == 0
	s.day += 1
	street.end_shift()
	if reset: _reset_week()
	s.phase = "plan"
	s.bookings.clear()
	s.event = 0
	s.card = -1
	s.legacy_shift = false
	_forecast()

func save_game() -> int:
	s.street.last_seen = maxi(int(s.street.last_seen),int(Time.get_unix_time_from_system()))
	s.rng = str(rng.state)
	var temporary := SAVE + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(s))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return error
	if FileAccess.file_exists(SAVE) and _read(SAVE) is Dictionary:
		error = DirAccess.copy_absolute(SAVE, BACKUP)
		if error != OK: return error
	return DirAccess.rename_absolute(temporary,SAVE)

func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK: return null
	var parsed: Variant = json.data
	if parsed is Dictionary and int(parsed.get("version",0)) in [1,2,3] and parsed.has("staff") and parsed.has("phase"):
		for key in ["cash","level","venue","day","weekly","night","log","rng"]:
			if not parsed.has(key): return null
		if parsed.version >= 2:
			if not parsed.get("street") is Dictionary: return null
			var data: Dictionary = parsed.street
			for key in ["bars","selected","chapter","served","earned","seconds","cycle","event","event_wait","event_index","events_survived","reopening","festival","festivals","last_seen","offline","history"]:
				if not data.has(key): return null
			if not data.bars is Array or data.bars.is_empty() or data.bars.size() > Street.C.NAMES.size(): return null
			if int(data.selected) < 0 or int(data.selected) >= data.bars.size(): return null
			if int(data.chapter) < 0 or int(data.chapter) >= Street.C.CHAPTERS.size(): return null
			for bar in data.bars:
				if not bar is Dictionary: return null
				for key in ["type","stage","name","crew","stock","restock","manager","away","closed"]:
					if not bar.has(key): return null
				if not int(bar.type) in [0,1,2] or not int(bar.stage) in [1,2,3]: return null
				if int(bar.crew) < 0 or int(bar.crew) > 6 or not bar.away is Array: return null
			if not data.event is Dictionary: return null
			if not data.event.is_empty():
				for key in ["id","phase","remaining","prepared"]:
					if not data.event.has(key): return null
				if int(data.event.id) < 0 or int(data.event.id) >= Street.C.EVENTS.size(): return null
		if int(parsed.version) == 3:
			for key in ["elapsed","economy_seed","next_customer","pass_credit","offered","arrivals","orders","guided","offline_report"]:
				if not parsed.street.has(key): return null
			for bar in parsed.street.bars:
				var defaults := Street.Economy.new_fields()
				for key in defaults:
					if key=="drink_stock" and not bar.has(key): continue
					if not bar.has(key): return null
					if defaults[key] is Array and not bar[key] is Array: return null
					if defaults[key] is Dictionary and not bar[key] is Dictionary: return null
				for key in defaults.equipment:
					if not bar.equipment.get(key) is float and not bar.equipment.get(key) is int: return null
				for key in ["drink_requests","drink_misses"]:
					if bar.shift.has(key) and not bar.shift[key] is Dictionary: return null
				for person in bar.team:
					if not person is Dictionary or not person.has("role") or not person.has("on") or not person.has("host"): return null
					if not int(person.role) in [0,1,2] or (int(person.role)==1 and not int(person.host) in range(Street.C.HOSTS.size())): return null
				for customer in bar.customers:
					if not customer is Dictionary: return null
					for key in ["id","life","order","wait","quoted","drinks","next","budget","pool","pool_wait","played","playing","missed","opening","promo","fine_budget"]:
						if not customer.has(key): return null
					if customer.has("drink") and not int(customer.drink) in range(Street.C.DRINKS.size()): return null
				var specialty_units := 0
				for sku in bar.get("drink_stock",{}):
					var units = bar.drink_stock[sku]
					if not (units is float or units is int) or units<0: return null
					var known := false
					for drink in range(1,Street.C.DRINKS.size()):
						if Street.C.DRINKS[drink].id==sku: known = true
					if not known: return null
					specialty_units += int(units)
				if specialty_units>int(bar.stock): return null
				for game in bar.games:
					if not game is Dictionary or not game.get("players") is Array or not game.has("remaining") or not game.has("fee"): return null
		return parsed
	return null

func load_game() -> bool:
	var parsed: Variant = _read(SAVE)
	if parsed == null: parsed = _read(BACKUP)
	if parsed == null: return false
	s = _restore_numbers(parsed)
	if int(s.version)<3 and s.phase in ["incident","fight","report","godzilla"] and not s.night.get("street_boss",false): s.legacy_shift = true
	rng.state = int(str(s.rng))
	street = Street.new(s)
	if s.phase == "end":
		s.phase = "plan"
		s.end = ""
		street.record("Anong reopens the books. Your street's story continues beyond the first year.")
	return true


func _restore_numbers(value: Variant) -> Variant:
	# The save schema contains whole numbers, while JSON restores numbers as floats.
	match typeof(value):
		TYPE_FLOAT:
			return int(value)
		TYPE_ARRAY:
			for i in value.size(): value[i] = _restore_numbers(value[i])
		TYPE_DICTIONARY:
			for key in value: value[key] = _restore_numbers(value[key])
	return value
