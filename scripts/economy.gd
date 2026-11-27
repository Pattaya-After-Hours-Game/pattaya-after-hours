extends RefCounted

const Finance = preload("res://scripts/finance.gd")
const C = preload("res://scripts/street_content.gd")
signal tour_arrived(guide_index: int, venue_name: String, guests: int)

var s: Dictionary
var last_sale := ""
var walk_in_scale := 1.0
var owner_recharge_scale := 1.0

func _init(state: Dictionary, fresh: bool = false) -> void:
	s = state
	var st: Dictionary = s.street
	st.merge({"celebration":{"day":0,"report":{},"last_report":{}}})
	st.merge({"tip_night":-1})
	if int(s.get("version",1))<11: st.tip_night = -1
	st.merge({"earnings_seconds":0,"earnings_net":0,"net_per_second":0.0})
	if not st.has("economy_seed"): st.economy_seed = 1
	if not st.has("next_group"): st.next_group = 1
	for entry in {"elapsed":0,"next_customer":1,"pass_credit":0,"offered":0,"arrivals":0,"orders":0,"guided":{},"offline_report":{}}:
		if not st.has(entry): st[entry] = {"elapsed":0,"next_customer":1,"pass_credit":0,"offered":0,"arrivals":0,"orders":0,"guided":{},"offline_report":{}}[entry]
	for bar in st.bars:
		var migrated: bool = not bar.has("customers")
		var defaults := new_fields()
		for key in defaults:
			if not bar.has(key): bar[key] = defaults[key]
		if int(s.get("version",1))<11: bar.merge(tip_fields(),true)
		if int(s.get("version",1))<12: bar.club_level = 0
		if int(s.get("version",1))<13: bar.completed = 0
		for key in ["serve_ready","welcome_ready","welcome_until"]: bar[key] = float(bar[key])
		bar.equipment.merge({"music":0})
		if int(s.get("version",1))<7:
			bar.supplier_level = 1 if bar.restock else 0
			bar.manager_level = 1 if bar.manager else 0
			if bar.stock_lots.is_empty() and bar.stock>0:
				bar.stock_lots = [{"units":int(bar.stock),"cost":C.LEGACY_STOCK_COST}]
		ensure_stock_lots(bar)
		# Retain historical payments, but cancel all uncharged promoter commission.
		bar.commission_carry = 0
		for customer in bar.customers:
			customer.merge(customer_action_fields())
			customer.merge({"host_interest":-1,"hosted":false})
			customer.commission_visit = false
			customer.commission_order = false
			customer.merge(visit_fields(),int(s.get("version",1))<13)
		for report in [bar.shift,bar.last_shift]+bar.recent:
			if not report.is_empty(): report.merge({"hosted_drinks":0,"hosted_income":0,"hosted_matches":0,"bar_fine_income":0,"bar_fines":0,"completed":0,"waiting_seconds":0,"drinking_seconds":0,"drink_requests":{},"drink_misses":{},"fines":0,"commission":0,"consumed_stock":int(report.get("sales",0))*C.LEGACY_STOCK_COST,"manager_income":0})
		for table in bar.games.size():
			if not bar.games[table].has("table"): bar.games[table].table = table
		if migrated:
			# Old crew served drinks: keep them as bartenders, never remove a hire.
			for _i in int(bar.crew): bar.team.append({"role":0,"on":true,"host":-1})
			if bar.type == 0 and bar.stage >= 2: bar.equipment.pool = 1
		for person in bar.team:
			if not person.has("contract_left"): person.contract_left = C.STAFF_CONTRACT_MINUTES
			if not person.has("training"): person.training = int(bar.equipment.training)
			if not person.has("service_clock"): person.service_clock = 0
			if not person.has("audience_training"): person.audience_training = 0
			person.merge({"host_training":0,"host_return":0.0})
			ensure_staff_service(person)
			if person.contract_left<=0: person.on = false
	if fresh:
		s.cash = C.STARTING_CASH
		st.bars[0].stock = 12
		ensure_stock_lots(st.bars[0])
		# A small opening rush, not an endlessly replenished tutorial grant.
		for _i in 3: admit(st.bars[0],false,true)

static func clock_fields() -> Dictionary:
	return {"late_open":false,"raided":false,"late_minutes":0,"dirt":0,"clean_remaining":0,"clean_auto_started":false}

# One availability rule shared by simulation, controls, forecasts and artwork.
# Offline forecasts describe a future legal opening window, not the frozen clock.
static func trading(bar: Dictionary, minute: int, offline: bool = false) -> bool:
	if not bar.get("open",true) or bar.get("closed",0)>0: return false
	if offline: return bar.get("manager",false) and bar.get("recovery",0)==0
	return not bar.get("raided",false) and scheduled(bar,minute)

static func scheduled(bar: Dictionary, minute: int) -> bool:
	return minute>=C.OPEN_MINUTE or minute<C.CLOSE_MINUTE or (bar.get("late_open",false) and minute<C.LATE_CLOSE_MINUTE)

static func peak(kind: int, minute: int) -> bool:
	var hours: Dictionary = C.PEAK_HOURS[kind]
	if hours.start<hours.end: return minute>=hours.start and minute<hours.end
	return minute>=hours.start or minute<hours.end

func peak_status(bar: Dictionary) -> String:
	var current := "active now" if peak(int(bar.type),int(s.street.minute)) else "outside peak"
	if not is_trading(bar): current = "venue closed"
	return "Peak %s · %s\n+%d%% attraction · %d× mess per drink" % [C.PEAK_HOURS[int(bar.type)].label,current,roundi((C.PEAK_ATTRACTION-1)*100),C.PEAK_DIRT_PER_DRINK]

func is_trading(bar: Dictionary, offline: bool = false) -> bool:
	return trading(bar,int(s.street.minute),offline)

func status(bar: Dictionary) -> String:
	if bar.raided: return "Raided: closed until 12pm."
	if not bar.open: return str(bar.close_reason)
	if bar.closed>0: return "Event closure: %ds remaining." % bar.closed
	if not scheduled(bar,int(s.street.minute)): return "Closed for prep. Opens at 12pm."
	return "Trading until %s." % ("3am tonight" if bar.late_open else "1am")

func finish_promotion(bar: Dictionary) -> void:
	if bar.promo.is_empty(): return
	bar.promo_report = bar.promo.duplicate(true)
	bar.promo = {}
	bar.promo_cooldown = C.PROMOTION_COOLDOWN

func clear_visits(bar: Dictionary) -> void:
	bar.customers.clear()
	bar.games.clear()
	bar.host_requests.clear()
	bar.get("host_rounds",[]).clear()
	bar.host_buzz_until = 0.0

func close_customers(bar: Dictionary) -> void:
	clear_visits(bar)
	bar.welcome = 0
	bar.service_clock = 0
	for person in bar.team: person.service_clock = 0
	finish_promotion(bar)
	if bar.manager and bar.dirt>0 and bar.clean_remaining==0 and not bar.clean_auto_started:
		bar.clean_remaining = C.CLEAN_SECONDS
		bar.clean_auto_started = true

func prep_tick(bar: Dictionary) -> void:
	if is_trading(bar):
		bar.clean_auto_started = false
		bar.clean_remaining = 0
		return
	if bar.manager and bar.dirt>0 and bar.clean_remaining==0 and not bar.clean_auto_started:
		bar.clean_remaining = C.CLEAN_SECONDS
		bar.clean_auto_started = true
	if bar.clean_remaining>0:
		bar.clean_remaining -= 1
		if bar.clean_remaining==0: bar.dirt = 0

static func action_fields() -> Dictionary:
	return {"action_levels":{"pouring":0,"welcoming":0},"serve_duration":10.0,"welcome_duration":10.0}

static func visit_fields() -> Dictionary:
	return {"planned_rounds":0,"visit_phase":"legacy","visit_complete":false}

static func customer_action_fields() -> Dictionary:
	return {"club":false,"party_patience":0,"chatted":false,"chat_until":0.0,"commission_visit":false,"commission_order":false}

static func new_fields() -> Dictionary:
	var fields := {"customers":[],"team":[],"equipment":{"sign":0,"comfort":0,"fridge":0,"pool":0,"seating":0,"screen":0,"training":0,"menu":0,"music":0},
		"open":true,"close_reason":"","recovery":0,"consignment":0,"games":[],"promo":{},"promo_report":{},"promo_id":0,"promo_cooldown":0,"last_promo":-1,"promo_repeats":0,"ordinary_seconds":0,
		"welcome":0,"welcome_until":0.0,"welcome_ready":0.0,"serve_ready":0.0,"service_clock":0,"cost_credit":0,
		"completed":0,"club_level":0,"regulars":0,"happy":0,"healthy":0,"shift":ledger(),"last_shift":{},"recent":[],"recent_sales":[],"recent_orders":[],
		"pool_games":0,"pool_income":0,"free_games":0,"arrivals":0,"orders":0,"sold":0,"lost_full":0,"lost_service":0,"lost_stock":0,"host_requests":[],"drink_stock":{}}
	fields.merge(Finance.fields())
	fields.merge(hosted_fields())
	fields.merge(bar_fine_fields())
	fields.merge(tip_fields())
	fields.merge(automation_fields())
	fields.merge(promoter_fields())
	fields.merge(clock_fields())
	fields.merge(action_fields())
	return fields

static func hosted_fields() -> Dictionary:
	return {"host_rounds":[],"host_cheers":0,"host_buzz_until":0.0,"host_last_line":"","auto_host_drinks":false,"auto_host_drinks_on":true}

static func bar_fine_fields() -> Dictionary:
	return {"auto_bar_fine":false,"auto_bar_fine_on":true}

static func tip_fields() -> Dictionary:
	return {"tip_visits":0,"bonus_tips":0,"tips_total":0,"last_tips":{}}

func settle_tips() -> Dictionary:
	var report := {"visits":0,"amount":0,"bonus":0}
	if s.phase!="plan" or s.street.minute<C.CLOSE_MINUTE or s.street.minute>=C.OPEN_MINUTE: return report
	for venue in s.street.bars:
		if is_trading(venue): return report
	if int(s.street.tip_night)==int(s.day): return report
	# The street calls this only at a real nightly closure or explicit night skip.
	s.street.tip_night = int(s.day)
	for bar in s.street.bars:
		var counted := count_tips(bar,maxi(1,int(s.day)-1))
		for key in report: report[key] += counted[key]
	return report

func count_tips(bar: Dictionary, day: int) -> Dictionary:
	var report := {"visits":int(bar.tip_visits),"bonus":int(bar.bonus_tips),"amount":int(bar.tip_visits)*C.TIP_PER_VISIT+int(bar.bonus_tips)}
	if report.amount==0: return report
	bar.last_tips = {"day":day,"visits":report.visits,"amount":report.amount,"bonus":report.bonus}
	bar.tip_visits = 0
	bar.bonus_tips = 0
	bar.tips_total += report.amount
	Finance.change(s,report.amount,"Counted tips",str(bar.name))
	s.weekly.revenue += report.amount
	s.street.earned += report.amount
	return report

func tips_text(bar: Dictionary) -> String:
	var text := "Tip jar · ฿%d pending · counted at closing" % (int(bar.tip_visits)*C.TIP_PER_VISIT+int(bar.bonus_tips))
	if bar.bonus_tips>0: text += " (+฿%d in drink bonuses)" % bar.bonus_tips
	if not bar.last_tips.is_empty():
		text += "\nLast count · day %d: %d served visits · ฿%d paid. Total tips ฿%d." % [bar.last_tips.day,bar.last_tips.visits,bar.last_tips.amount,bar.tips_total]
	return text

func emergency_stock_available(bar: Dictionary) -> bool:
	return bar.stock==0 and s.cash<pack_price(bar) and int(bar.recovery)==0 and bar.closed==0 and not bar.raided and scheduled(bar,int(s.street.minute))

static func automation_fields() -> Dictionary:
	return {"auto_serve":false,"auto_serve_on":true,"supplier_level":0,"stock_lots":[],"manager_level":0}

static func stock_unit_cost(bar: Dictionary) -> int:
	return C.SUPPLIER_UNIT_COSTS[int(bar.get("supplier_level",0))]

static func pack_quantity(bar: Dictionary) -> int:
	return 12 if int(bar.get("supplier_level",0))>=2 else C.STOCK_PACK

static func pack_price(bar: Dictionary) -> int:
	return pack_quantity(bar)*stock_unit_cost(bar)

static func ensure_stock_lots(bar: Dictionary) -> void:
	var units := 0
	for lot in bar.stock_lots: units += int(lot.units)
	if units!=int(bar.stock):
		bar.stock_lots = [{"units":int(bar.stock),"cost":stock_unit_cost(bar)}] if bar.stock>0 else []

static func add_stock(bar: Dictionary, drink: int, units: int, unit_cost: int) -> void:
	ensure_stock_lots(bar)
	bar.stock_lots.append({"units":units,"cost":unit_cost,"drink":drink})
	bar.stock += units
	if drink>0: bar.drink_stock[C.DRINKS[drink].id] = true

static func consume_stock(bar: Dictionary, drink: int = 0, last: bool = false) -> int:
	ensure_stock_lots(bar)
	for i in bar.stock_lots.size():
		var index: int = bar.stock_lots.size()-i-1 if last else i
		var lot: Dictionary = bar.stock_lots[index]
		if int(lot.get("drink",0))!=drink: continue
		var unit_cost := int(lot.cost)
		lot.units -= 1
		if lot.units==0: bar.stock_lots.remove_at(index)
		bar.stock -= 1
		return unit_cost
	return 0

static func automatic_service(bar: Dictionary) -> bool:
	return bar.get("auto_serve",false) and bar.get("auto_serve_on",true)

func owner_relief_needed(bar: Dictionary) -> bool:
	# Staff have already taken their turn. Leave a quiet queue to the team;
	# the owner's separate timer handles overflow and otherwise lost orders.
	var workers := on_duty(bar,0)
	if workers==0: return pending(bar)>0
	if pending(bar)>workers: return true
	var next := 1e15
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if contracted(person) and person.on and person.role==0 and not i in bar.away:
			next = minf(next,maxf(0.0,float(person.get("service_ready",0))-action_time()))
	for round in bar.get("host_rounds",[]):
		if round.state=="waiting" and float(round.host_deadline)-action_time()<=C.AUTO_SERVE_URGENT_SECONDS and next>=float(round.host_deadline)-action_time(): return true
	for guest in bar.customers:
		if guest.order and order_seconds_left(bar,guest)<=C.AUTO_SERVE_URGENT_SECONDS and next>=order_seconds_left(bar,guest): return true
	return false

func auto_serve_status(bar: Dictionary) -> String:
	if not automatic_service(bar): return "Owner auto-serve is off."
	if not is_trading(bar): return "Owner auto-serve · venue closed"
	if on_duty(bar,0)==0: return "Owner auto-serve · covering the bar"
	return "Owner auto-serve · helping the rush" if owner_relief_needed(bar) else "Owner auto-serve · leaving quiet orders to staff"

static func manager_percent(bar: Dictionary) -> int:
	return C.MANAGER_BONUS_PERCENT[int(bar.get("manager_level",0))] if bar.manager and bar.get("recovery",0)==0 else 0

static func bonus_amount(bar: Dictionary, margin: int) -> int:
	bar.manager_bonus_carry += maxi(0,margin)*manager_percent(bar)
	var amount := int(bar.manager_bonus_carry)/100
	bar.manager_bonus_carry = int(bar.manager_bonus_carry)%100
	return amount

func management_bonus(bar: Dictionary, margin: int) -> void:
	if not is_trading(bar): return
	var amount := bonus_amount(bar,margin)
	if amount<=0: return
	income(bar,amount,"Earned manager bonus")
	bar.shift.manager_income += amount

static func loyalty_rank(bar: Dictionary) -> int:
	var rank := 0
	for goal in C.STAGE_GOALS:
		if bar.happy>=goal.happy and bar.regulars>=goal.regulars and bar.healthy>=goal.healthy: rank += 1
	return rank

func manager_offer(bar: Dictionary) -> Dictionary:
	var level := int(bar.manager_level)
	var required_stage: int = C.MANAGER_STAGES[mini(level,C.MANAGER_STAGES.size()-1)]
	var reason := ""
	var amount := int(C.MANAGER_PRICES[level]) if level<C.MANAGER_PRICES.size() else 0
	var required := amount
	if level>=3: reason = "Manager fully developed."
	else:
		if bar.stage<required_stage: reason = "Needs venue stage %d." % required_stage
		elif level==0 and (on_duty(bar,0)<1 or not bar.restock): reason = "Needs an on-duty bartender and automatic deliveries."
		elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"level":level,"price":amount,"required":required,"required_stage":required_stage,"rate":C.MANAGER_BONUS_PERCENT[mini(level+1,3)]}

func buy_manager(bar: Dictionary) -> String:
	var offer := manager_offer(bar)
	if not offer.enabled: return offer.reason
	Finance.change(s,-int(offer.price),"Manager appointment",str(bar.name))
	s.weekly.costs += offer.price
	bar.manager = true
	bar.manager_level += 1
	return "Manager level %d: +%d%% on earned drink and paid-pool margins, plus managed offline operation." % [bar.manager_level,manager_percent(bar)]

func supplier_offer(bar: Dictionary) -> Dictionary:
	var level := int(bar.supplier_level)
	var required_stage: int = C.SUPPLIER_STAGES[mini(level,C.SUPPLIER_STAGES.size()-1)]
	var reason := ""
	var amount := int(C.SUPPLIER_PRICES[level]) if level<C.SUPPLIER_PRICES.size() else 0
	var required := amount
	if level>=C.SUPPLIER_PRICES.size(): reason = "Best supplier agreement reached."
	else:
		if bar.stage<required_stage: reason = "Needs venue stage %d." % required_stage
		elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"level":level,"price":amount,"required":required,"required_stage":required_stage,"quantity":12 if level>=1 else 6,"pack":(12 if level>=1 else 6)*C.SUPPLIER_UNIT_COSTS[mini(level+1,5)]}

func buy_supplier(bar: Dictionary) -> String:
	ensure_stock_lots(bar)
	var offer := supplier_offer(bar)
	if not offer.enabled: return offer.reason
	Finance.change(s,-int(offer.price),"Supplier agreement",str(bar.name))
	s.weekly.costs += offer.price
	bar.supplier_level += 1
	bar.restock = true
	if offer.level==0: return "Auto-restock unlocked. Bo now reorders drinks you carry."
	return "Supplier level %d: %d drinks cost ฿%d. Existing stock keeps its purchase cost." % [bar.supplier_level,pack_quantity(bar),pack_price(bar)]

func sample_earnings() -> void:
	for bar in s.street.bars:
		bar.earnings_seconds += 1
		if bar.earnings_seconds>=5:
			bar.net_per_second = float(bar.earnings_net)/5.0
			bar.earnings_seconds = 0
			bar.earnings_net = 0
	s.street.earnings_seconds += 1
	if s.street.earnings_seconds>=5:
		s.street.net_per_second = float(s.street.earnings_net)/5.0
		s.street.earnings_seconds = 0
		s.street.earnings_net = 0

static func promoter_fields() -> Dictionary:
	return {"commission_carry":0,"commission_paid":0,"offline_sales_credit":0.0,"offline_cost_pending":0.0,"offline_pool_pending":0.0}

static func contract_cost(role: int) -> int:
	return C.PROMOTER_CONTRACT_COST if role==3 else C.BARTENDER_CONTRACT_COST if role==0 else C.STAFF_CONTRACT_COST

static func equipment_limit(bar: Dictionary, id: String, default_limit: int) -> int:
	if (bar.type==0 or id=="sign") and C.BEER_CAPS.has(id): return int(C.BEER_CAPS[id][-1])
	return 2 if id=="seating" else default_limit

static func equipment_stage(bar: Dictionary, id: String, next_level: int) -> int:
	if id=="pool": return next_level
	if (bar.type==0 or id=="sign") and C.BEER_CAPS.has(id):
		for stage in 3:
			if next_level<=C.BEER_CAPS[id][stage]: return stage+1
	return 2 if id=="menu" or (id=="music" and next_level>1) else 1

static func training_limit(bar: Dictionary) -> int:
	return 6 if bar.type==0 else 4

func promoter_index(bar: Dictionary) -> int:
	for i in bar.team.size():
		if bar.team[i].role==3: return i
	return -1

func gabby_venue() -> String:
	for venue in s.street.bars:
		for person in venue.team:
			if person.get("identity","")=="gabby": return str(venue.name)
	return ""

func daisy_venue() -> String:
	for venue in s.street.bars:
		for person in venue.team:
			if person.role==1 and int(person.host)==C.DAISY_HOST: return str(venue.name)
	return ""

func role_change_fee(bar: Dictionary, index: int) -> int:
	var person: Dictionary = bar.team[index]
	var next_role := int(bar.type) if person.role==0 else 0
	return ceili(maxi(0,contract_cost(next_role)-contract_cost(int(person.role)))*float(person.get("contract_left",C.STAFF_CONTRACT_MINUTES))/C.STAFF_CONTRACT_MINUTES)

func floor_staff(bar: Dictionary) -> int:
	return bar.team.size()-(1 if promoter_index(bar)>=0 else 0)

func promoter_bonus(bar: Dictionary, offset: int = 0) -> float:
	var index := promoter_index(bar)
	if index<0 or not contracted(bar.team[index],offset) or not bar.team[index].on: return 0.0
	return C.PROMOTER_BONUS[int(bar.team[index].get("audience_training",0))]

static func commission_charge(bar: Dictionary, amount: int) -> int:
	if C.COMMISSION_PERCENT==0:
		bar.commission_carry = 0
		return 0
	var credit := int(bar.commission_carry)+amount*C.COMMISSION_PERCENT
	bar.commission_carry = credit%100
	return credit/100

func commit_orders(bar: Dictionary) -> void:
	if C.COMMISSION_PERCENT==0 or promoter_bonus(bar)<=0: return
	for guest in bar.customers:
		if guest.order: guest.commission_order = true

func stock_offer(bar: Dictionary, automatic: bool = false, drink: int = 0) -> Dictionary:
	return stock_quote(bar,pack_quantity(bar),drink_cost(bar,drink),automatic)

func stock_quote(bar: Dictionary, quantity: int, unit_cost: int, _automatic: bool = false) -> Dictionary:
	var amount := quantity*unit_cost
	var room := stock_capacity(bar)-int(bar.stock)
	var required := amount
	var reason := ""
	if cart_delivery_blocked(bar): reason = "Cart Jam: clear Bo’s route in Events."
	elif room<quantity: reason = "Need %d free spaces; you have %d." % [quantity,room]
	elif s.cash<required: reason = "Need ฿%d; you have ฿%d." % [amount,s.cash]
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":amount,"required":required,"quantity":quantity,"room":room,"remaining_cash":int(s.cash)-amount}

static func ledger() -> Dictionary:
	return {"hosted_drinks":0,"hosted_income":0,"hosted_matches":0,"bar_fine_income":0,"bar_fines":0,"completed":0,"waiting_seconds":0,"drinking_seconds":0,"revenue":0,"stock_cost":0,"drink_requests":{},"drink_misses":{},"operating":0,"promo_cost":0,"fines":0,"commission":0,"consumed_stock":0,"manager_income":0,"arrivals":0,"orders":0,"sales":0,"happy":0,"lost_full":0,"lost_service":0,"lost_stock":0,"open_seconds":0,"occupied_seconds":0,"pool_income":0,"free_games":0}

func roll(limit: int) -> int:
	s.street.economy_seed = (int(s.street.economy_seed)*48271) % 2147483647
	return int(s.street.economy_seed) % maxi(1,limit)

func seats(bar: Dictionary) -> int:
	var furniture := int(bar.equipment.pool)*2+int(bar.equipment.comfort)
	var recovered := mini(3,furniture) if bar.type==0 and bar.equipment.seating>=3 else 0
	return maxi(2,C.BASE_SEATS[int(bar.stage)-1]+int(bar.equipment.seating)*2-furniture+recovered)

func stock_capacity(bar: Dictionary) -> int:
	return 30 + int(bar.equipment.fridge)*40 + (int(bar.stage)-1)*20

static func contracted(person: Dictionary, offset: int = 0) -> bool:
	return int(person.get("contract_left",C.STAFF_CONTRACT_MINUTES))>offset

static func service_seconds(person: Dictionary) -> int:
	return C.STAFF_SERVICE_SECONDS[clampi(int(person.get("training",0)),0,C.STAFF_SERVICE_SECONDS.size()-1)]

func advance_contracts(minutes: int) -> void:
	if minutes<=0: return
	for bar in s.street.bars:
		for i in bar.team.size():
			var person: Dictionary = bar.team[i]
			if not contracted(person): continue
			person.contract_left = maxi(0,int(person.get("contract_left",C.STAFF_CONTRACT_MINUTES))-minutes)
			if person.contract_left==0:
				person.on = false
				person.service_clock = 0
				if float(person.get("host_return",0))<=action_time(): bar.away.erase(i)
				var notice := "%s · %s %d finished their ten-day contract. Rehire in Service; training is retained." % [bar.name,C.ROLE_NAMES[int(person.role)],i+1]
				s.log.push_front(notice)
				s.street.history.push_front(notice)
				if s.log.size()>30: s.log.pop_back()
				if s.street.history.size()>60: s.street.history.pop_back()

func on_duty(bar: Dictionary, role: int, offset: int = 0) -> int:
	var total := 0
	for i in bar.team.size():
		if contracted(bar.team[i],offset) and bar.team[i].on and bar.team[i].role == role and not i in bar.away: total += 1
	return total

func service_rate(bar: Dictionary, offset: int = 0) -> float:
	var rate := 0.0
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if contracted(person,offset) and person.on and person.role==0 and not i in bar.away:
			rate += 60.0/service_seconds(person)
	return rate

func ensure_staff_service(person: Dictionary) -> void:
	if not person.has("service_ready"):
		var old_progress := int(person.get("service_clock",0))
		person.service_ready = action_time()+maxi(0,service_seconds(person)-old_progress) if old_progress>0 else 0.0
	person.merge({"last_served":-1.0,"drinks_served":0,"host_training":0,"host_return":0.0})
	person.service_ready = float(person.service_ready)
	person.last_served = float(person.last_served)

func staff_status(bar: Dictionary, person: Dictionary) -> Dictionary:
	var left := maxf(0.0,float(person.get("service_ready",0))-action_time())
	var reason := "Ready · waiting for orders" if pending(bar)==0 else "Ready · serving next order"
	if not contracted(person): reason = "Contract finished"
	elif not person.on: reason = "Off duty"
	elif person.role!=0: reason = "Attracts visitors; does not serve"
	elif bar.team.find(person) in bar.away: reason = "Away for this shift"
	elif not is_trading(bar): reason = "Venue closed"
	elif left>0: reason = "Recovering · %ds" % ceili(left)
	elif bar.stock==0: reason = "Ready · out of stock"
	return {"text":reason,"remaining":left,"served":int(person.get("drinks_served",0)),"recent":float(person.get("last_served",-1))>=0 and action_time()-float(person.last_served)<2.0}

func staff_indicator(bar: Dictionary) -> String:
	var bartenders := 0
	var served := 0
	var available := 0
	var ready := 0
	var next := 1e15
	var recent := false
	for person in bar.team:
		served += int(person.get("drinks_served",0))
		if person.role!=0: continue
		bartenders += 1
		var view := staff_status(bar,person)
		recent = recent or view.recent
		if contracted(person) and person.on and not bar.team.find(person) in bar.away:
			available += 1
			next = minf(next,view.remaining)
			if view.remaining<=0: ready += 1
	if bartenders==0: return "BAR STAFF\nNo bartender · hire in Service"
	var text := "%d ready · next order is automatic" % ready
	if not is_trading(bar): text = "Venue closed"
	elif available==0: text = "Off duty / contract finished"
	elif ready==0: text = "Recovering · next ready in %ds" % ceili(next)
	elif bar.stock==0: text = "%d ready · out of stock" % ready
	elif pending(bar)==0: text = "%d ready · waiting for orders" % ready
	return "BAR STAFF · drinks served: %d\n%s%s" % [served,"Served a drink!\n" if recent and is_trading(bar) else "",text]

func staff_service(bar: Dictionary) -> void:
	if not is_trading(bar): return
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		ensure_staff_service(person)
		if not contracted(person) or not person.on or person.role!=0 or i in bar.away: continue
		if action_time()<float(person.service_ready): continue
		if serve(bar,1)>0:
			if person.get("identity","")=="gabby": bar.bonus_tips += C.GABBY_TIP_PER_DRINK
			person.service_ready = action_time()+service_seconds(person)
			person.last_served = action_time()
			person.drinks_served += 1
			person.service_clock = 0 # Retained only for old-save compatibility.

func rehire_offer(bar: Dictionary, index: int) -> Dictionary:
	if index<0 or index>=bar.team.size(): return {"enabled":false,"reason":"Unknown team member.","price":0,"reserve":0,"required":0}
	var person: Dictionary = bar.team[index]
	var amount := contract_cost(int(person.role))
	var reserve := 0
	var required := amount
	var reason := "Ready to rehire; training is retained."
	if contracted(person): reason = "Contract still active. Use On duty / Off duty to resume work."
	elif s.cash<required: reason = "Need ฿%d more for the contract." % (required-s.cash)
	return {"available":int(s.cash),"enabled":not contracted(person) and s.cash>=required,"reason":reason,"price":amount,"reserve":reserve,"required":required}

func operating_breakdown(bar: Dictionary, offset: int = 0) -> Dictionary:
	if bar.get("recovery",0)>0: return {}
	var overhead := int(C.OVERHEAD[int(bar.type)])
	var bills := {"Rent":overhead*2/3,"Electricity":overhead/3+int(bar.equipment.comfort)*4}
	if bar.manager: bills["Manager wages"] = 12
	for person in bar.team:
		if contracted(person,offset) and person.on:
			var wage := int(C.ROLE_WAGES[int(person.role)])
			if wage>0:
				var label := str(C.ROLE_NAMES[int(person.role)])+" wages"
				bills[label] = int(bills.get(label,0))+wage
	return bills

func operating_rate(bar: Dictionary, offset: int = 0) -> int:
	var amount := 0
	for rate in operating_breakdown(bar,offset).values(): amount += int(rate)
	return amount

func operating_description(bar: Dictionary) -> String:
	var parts: Array[String] = []
	var bills := operating_breakdown(bar)
	for label in bills: parts.append("%s ฿%d" % [label,bills[label]])
	return " + ".join(parts)+" / min"

func price(bar: Dictionary, drink: int = 0, offline: bool = false) -> int:
	var amount := int(C.TYPES[int(bar.type)].drink) + int(C.DRINKS[drink].offset)
	if not offline and bar.promo.get("kind",-1) == 1: amount = int(amount*.8)
	return amount

func drink_count(bar: Dictionary) -> int:
	return C.DRINKS.size() if bar.equipment.menu else C.DRINKS.size()-1

func stock_of(bar: Dictionary, drink: int) -> int:
	var specialty := 0
	var units := 0
	for lot in bar.stock_lots:
		var sku := int(lot.get("drink",0))
		if sku>0: specialty += int(lot.units)
		if sku==drink: units += int(lot.units)
	return maxi(0,int(bar.stock)-specialty) if drink==0 else units

func drink_cost(bar: Dictionary, drink: int) -> int:
	return maxi(1,int(C.DRINKS[drink].cost)+stock_unit_cost(bar)-C.STOCK_COST)

func auto_drink(bar: Dictionary, drink: int) -> bool:
	return bar.restock and carries_drink(bar,drink)

func carries_drink(bar: Dictionary, drink: int) -> bool:
	return drink==0 or bar.drink_stock.has(C.DRINKS[drink].id)

func taste(bar: Dictionary, audience: int, drink: int) -> int:
	var weight := int(C.DRINK_TASTES[audience][drink])
	if drink == 2 and drink_count(bar) == 3: weight += int(C.DRINK_TASTES[audience][3])
	return weight

func affordable_drink(bar: Dictionary, audience: int, wanted: int, budget: int, offline: bool = false) -> int:
	var limit := mini(budget, int(C.TYPES[int(bar.type)].drink)+int(C.DRINK_PRICE_HEADROOM[audience]))
	if price(bar,wanted,offline)<=limit: return wanted
	# Keep the wider house-lager market while allowing guests to trade down on price.
	for drink in [0,1]:
		if price(bar,drink,offline)<=limit: return drink
	return -1

func drink_popularity(bar: Dictionary, offline: bool = false) -> Array[float]:
	return drink_mix(bar,audience_weights(offline),offline)

func drink_mix(bar: Dictionary, crowd: Array, full_price: bool) -> Array[float]:
	var demand: Array[float] = []
	demand.resize(drink_count(bar))
	demand.fill(0.0)
	var total := 0.0
	for audience in 3:
		var affinity: float = C.AUDIENCE_AFFINITY[int(bar.type)][audience]
		for wanted in demand.size():
			var weight := int(crowd[audience])*affinity*taste(bar,audience,wanted)
			var drink := affordable_drink(bar,audience,wanted,1_000_000,full_price)
			demand[drink] += weight
			total += weight
	for drink in demand.size(): demand[drink] /= total
	return demand

func drink_demand_hint(bar: Dictionary, drink: int, popularity: float) -> String:
	var crowd := audience_weights()
	var usual_crowd := audience_weights(true)
	var happy_hour: bool = bar.promo.get("kind",-1)==1
	var discount_lift := popularity-drink_mix(bar,crowd,true)[drink] if happy_hour else 0.0
	var crowd_lift := popularity-drink_mix(bar,usual_crowd,false)[drink] if crowd!=usual_crowd else 0.0
	if discount_lift>=0.01 and discount_lift>=crowd_lift: return "Happy Hour boost"
	if crowd_lift>=0.01: return "Visitor crowd boost" if event_id()==1 else "Local crowd boost"
	return ["","Popular with locals","Visitor pick","Big-spender pick"][drink]


# The opening's date owns the party through midnight, ending at normal 1am close.
func trading_day() -> int:
	return int(s.day)-(1 if int(s.street.minute)<C.OPEN_MINUTE else 0)

func celebration_window() -> bool:
	return trading_day()>0 and trading_day()%C.CELEBRATION_INTERVAL==0 and (s.street.minute>=C.OPEN_MINUTE or s.street.minute<C.CLOSE_MINUTE)

func celebrating(bar: Dictionary, offline: bool = false) -> bool:
	return not offline and celebration_window() and int(s.street.celebration.day)==trading_day() and not s.street.celebration.report.is_empty() and bar.name==s.street.bars[0].name and is_trading(bar)

func party_add(bar: Dictionary, field: String, amount: int = 1) -> void:
	if celebrating(bar): s.street.celebration.report[field] += amount

static func celebration_report(day: int) -> Dictionary:
	return {"day":day,"arrivals":0,"sales":0,"drink_income":0,"drink_cost":0,"commission":0,"pool_income":0,"operating":0,"promo_cost":0,"fines":0,"happy":0,"regulars":0,"lost_full":0,"lost_service":0,"lost_stock":0}

static func celebration_name(day: int) -> String:
	return str(C.CELEBRATIONS[celebration_index(day)][0])

static func celebration_index(day: int) -> int:
	return 0 if day<=7 else 1+(int(day/7)-2)%3

static func celebration_contribution(report: Dictionary) -> int:
	return int(report.drink_income)+int(report.pool_income)-int(report.drink_cost)-int(report.commission)-int(report.operating)-int(report.promo_cost)-int(report.fines)

func repeat_order_seconds(bar: Dictionary) -> int:
	var normal: int = C.MUSIC_INTERVALS[clampi(int(bar.equipment.get("music",0)),0,C.MUSIC_INTERVALS.size()-1)]
	return roundi(normal*C.CELEBRATION_ORDER_FACTOR) if celebrating(bar) else normal

func event_id() -> int:
	return int(s.street.event.get("id",-1)) if s.street.event.get("phase","") == "active" else -1

func base_traffic(replacement: Dictionary = {}) -> float:
	var frontage := 1
	for existing in s.street.bars:
		var bar: Dictionary = replacement.bar if not replacement.is_empty() and existing==replacement.original else existing
		if bar.type==0: frontage = maxi(frontage,int(bar.equipment.sign))
	var marketing := 0.0
	for i in int(s.street.get("marketing_level",0)): marketing += C.MARKETING_TRAFFIC[i]
	return C.TRAFFIC_PER_MINUTE+C.FRONTAGE_TRAFFIC*maxi(0,frontage-1)+marketing

func local_event(bar: Dictionary, id: int) -> bool:
	return event_id()==id and bar.name==s.street.bars[int(s.street.event.venue)].name

func cart_delivery_blocked(bar: Dictionary) -> bool:
	return local_event(bar,C.Local.CART) and not s.street.event.prepared and not s.street.event.get("game_won",false)

func traffic_rate(offline: bool = false, replacement: Dictionary = {}, marketing_extra: float = 0.0) -> float:
	var kinds := {}
	for bar in s.street.bars:
		if is_trading(bar,offline): kinds[int(bar.type)] = true
	var additions := 0
	for i in range(1,s.street.bars.size()):
		if is_trading(s.street.bars[i],offline): additions += 1
	var rate := base_traffic(replacement) + marketing_extra + maxi(0,kinds.size()-1)*C.AUDIENCE_TRAFFIC_BONUS + additions*2.0
	if offline: return rate
	match event_id():
		1: rate *= 2.4
		3: rate *= .5
		4: rate *= 1.7
		5,9: rate *= 2.0
		6: rate *= .7
		C.RAT_PLAGUE: rate *= .55 if s.street.event.prepared else .15
		C.Local.ENCORE:
			var wave := int(s.street.event.remaining)
			if not s.street.event.get("early",false) or s.street.event.prepared or s.street.event.get("solo",false):
				rate *= (2.4 if wave>35 or wave<16 else .75) if s.street.event.encore else 2.0
		C.Local.ZOMBIES, C.Local.BED: rate *= 1.45
		C.Local.DINO: rate *= 1.25
	if celebrating(s.street.bars[0]): rate = minf(rate*C.CELEBRATION_TRAFFIC,(base_traffic(replacement)+marketing_extra+maxi(0,kinds.size()-1)*C.AUDIENCE_TRAFFIC_BONUS)*C.CELEBRATION_TRAFFIC_CAP)
	if s.weather >= 5: rate *= .8
	return rate*walk_in_scale

func attraction(bar: Dictionary, offline: bool = false, audience: int = -1, minute: int = -1, offset: int = 0, include_guides: bool = true) -> float:
	if not is_trading(bar,offline): return 0.0
	var value := 4.0 + (int(bar.stage)-1)*1.0 + int(bar.equipment.sign)*2 + int(bar.equipment.pool)*1.5
	value += minf(3.0,int(bar.regulars)/15.0) + minf(1.5,int(s.rep)/80.0)
	if not offline and include_guides: value += s.bookings.size()*.5
	for i in bar.team.size():
		var host: Dictionary = bar.team[i]
		if host.role==1 and host.on and contracted(host,offset) and not i in bar.away: value += host_appeal(host)
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if person.role==2 and person.on and contracted(person,offset) and not i in bar.away:
			var performance := (.6 if offline else 1.8 if int(s.street.seconds) in range(40,80) else 0.0) if bar.type==2 else 0.0
			value += (.9+performance)*C.DANCER_TRAINING[int(person.get("audience_training",0))]
	value += maxf(0.0 if offline else int(bar.welcome)*.4,promoter_bonus(bar,offset))
	if not offline:
		if float(bar.get("host_buzz_until",0))>action_time(): value += C.HOST_BUZZ_APPEAL
		if celebrating(bar): value += C.CELEBRATION_ATTRACTION
		if not bar.promo.is_empty(): value += float(C.PROMOTIONS[int(bar.promo.kind)].boost)/int(bar.promo.repetition)
		if event_id() == 6: value *= .95 if bar.type == 0 else .55
		if event_id() == 7: value *= 1.2 if s.street.event.prepared else .65
		if event_id() == 4 and bar.type == 0: value *= 1.3
		var event: Dictionary = s.street.event
		if local_event(bar,C.Local.ZOMBIES) and event.prepared: value *= 1.55
		if local_event(bar,C.Local.BED) and event.get("game_won",false): value *= 1.5
		if local_event(bar,C.Local.CART) and (event.prepared or event.get("game_won",false)): value *= 1.15
		if local_event(bar,C.Local.LIZARD) and event.prepared:
			value *= .25 if event.remaining>30 else 1.55 if event.get("lucky",false) else 1.0
		if local_event(bar,C.Local.DINO) and event.prepared: value *= .75 if event.remaining>33 else 1.65 if audience!=0 else 1.0
	if audience>=0: value *= C.AUDIENCE_AFFINITY[int(bar.type)][audience]
	if peak(int(bar.type),int(s.street.minute) if minute<0 else minute): value *= C.PEAK_ATTRACTION
	return value * (1.0 - float(bar.dirt)/C.DIRT_LIMIT*C.DIRT_ATTRACTION_PENALTY) * (1.0+loyalty_rank(bar)*.05)

func audience_weights(offline: bool = false) -> Array:
	if not offline and event_id()==1: return [15,70,15]
	if not offline and event_id()==6: return [70,20,10]
	return [40,35,25]

func sales_mix(bar: Dictionary, offline: bool) -> Array[float]:
	var mix := drink_popularity(bar,offline)
	var has_lager: bool = stock_of(bar,0)>0 or bar.restock
	for drink in mix.size():
		var available := stock_of(bar,drink)>0 or (auto_drink(bar,drink) and (offline or can_supply(bar,drink)))
		if available: continue
		if drink>0 and has_lager:
			var chance := int(C.DRINKS[drink].substitute) if carries_drink(bar,drink) else 100
			mix[0] += mix[drink]*chance/100.0
		mix[drink] = 0.0
	return mix

func forecast(bar: Dictionary, offline: bool = false, promotion: int = -1, minute: int = -1, offset: int = 0, owner_active: bool = false, replacement: Dictionary = {}, traffic_extra: float = 0.0) -> Dictionary:
	var original := bar
	var promotion_cost := 0.0
	if promotion>=0 and promotion<C.PROMOTIONS.size():
		bar = bar.duplicate(true)
		var repetition := int(bar.promo_repeats)+1 if bar.last_promo==promotion and bar.ordinary_seconds<240 else 1
		bar.promo = {"kind":promotion,"repetition":repetition}
		promotion_cost = float(C.PROMOTIONS[promotion].fee)*60.0/C.PROMOTION_SECONDS
	var arrivals := 0.0
	var round_total := 0.0
	var mix := audience_weights(offline)
	for audience in 3:
		var total := 5.0
		for other in s.street.bars: total += attraction(bar if other==original else replacement.get("bar") if not replacement.is_empty() and other==replacement.original else other,offline,audience,minute,offset)
		var audience_arrivals := traffic_rate(offline,replacement,traffic_extra)*float(mix[audience])/100.0*attraction(bar,offline,audience,minute,offset)/total
		arrivals += audience_arrivals
		round_total += audience_arrivals*(2.0-float(C.ONE_ROUND_CHANCE[audience])/100.0)
	var party := celebrating(bar,offline)
	var club_share := float(C.CLUB_CHANCE[int(bar.club_level)])/100.0
	var rounds := round_total/maxf(.001,arrivals)+(1.0 if party else club_share)
	var service := service_rate(bar,offset)+(60.0/action_cooldown(bar,"serve") if automatic_service(bar) or (owner_active and not offline) else 0.0)
	var drinking: float = C.MUSIC_INTERVALS[int(bar.equipment.music)]
	if party: drinking = roundi(drinking*C.CELEBRATION_ORDER_FACTOR)
	# A visit occupies a seat while being served and drinking every round, including its last.
	var duration := rounds*(drinking+60.0/maxf(1.0,service))
	var space_limit := seats(bar)*60.0/maxf(1.0,duration)
	var demand := minf(arrivals,space_limit)*rounds
	var drinks: Array[float] = [1.0]
	var demand_share := 1.0 if bar.stock>0 or bar.restock else 0.0
	var average_price := float(price(bar,0,offline))
	var average_cost := float(stock_unit_cost(bar))
	if not bar.drink_stock.is_empty():
		drinks = sales_mix(bar,offline)
		demand_share = 0.0
		average_price = 0.0
		average_cost = 0.0
		for drink in drinks.size():
			demand_share += drinks[drink]
			average_price += drinks[drink]*price(bar,drink,offline)
			average_cost += drinks[drink]*drink_cost(bar,drink)
		average_price /= maxf(.01,demand_share)
		average_cost /= maxf(.01,demand_share)
	var sales := minf(demand*demand_share,service)
	var unit_margin := average_price-average_cost
	var pool := minf(60.0/C.POOL_SECONDS*int(bar.equipment.pool),minf(arrivals,space_limit)*.2)*C.POOL_FEE
	if not offline and bar.promo.get("kind",-1) == 0: pool = 0
	var costs := operating_rate(bar,offset)+promotion_cost if is_trading(bar,offline) else 0.0
	var commission_per_sale := average_price*C.COMMISSION_PERCENT/100.0 if promoter_bonus(bar,offset)>0 else 0.0
	var commission := sales*commission_per_sale
	unit_margin -= commission_per_sale
	var management := (sales*maxf(0,unit_margin)+pool)*manager_percent(bar)/100.0 if is_trading(bar,offline) else 0.0
	var net := sales*unit_margin+pool+management-costs
	var reason := "Quiet: attract customers before hiring."
	var short_drink := blocking_drink(bar) if not offline else -1
	if not is_trading(bar,offline): reason = status(bar)
	elif not offline and event_id()==C.RAT_PLAGUE: reason = "Rats everywhere! Few guests are coming in."
	elif short_drink>=0: reason = "Waiting orders need %s. Tap Stock." % C.DRINKS[short_drink].name
	elif bar.stock <= 0: reason = "Out of stock: order a delivery."
	elif bar.customers.size() >= seats(bar): reason = "Full: more seats or shorter queues would help."
	elif pending(bar) > 0 and service < demand: reason = "Slow service: serve orders or add a bartender."
	return {"arrivals":arrivals,"rounds":rounds,"visit_seconds":duration,"demand":demand,"service":service,"sales":sales,"costs":costs,"net":net,"break_even":maxf(0,(costs-pool-management)/maxf(1,unit_margin)),"pool":pool,"manager":management,"commission":commission,"margin":unit_margin,"drink_mix":drinks,"reason":reason}

func club_offer(bar: Dictionary) -> Dictionary:
	var required_stage := 2
	var level := int(bar.club_level)
	var amount := 0 if level==3 else int(C.CLUB_PRICES[level])
	var reserve := 0
	var required := amount
	var reason := ""
	if level==3: reason = "Regulars Club fully established."
	elif bar.stage<required_stage: reason = "Needs venue stage %d." % required_stage
	elif bar.regulars<C.CLUB_REGULARS[level]: reason = "Needs %d local regulars; you have %d." % [C.CLUB_REGULARS[level],bar.regulars]
	elif s.cash<required: reason = "Need ฿%d more." % (required-int(s.cash))
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"level":level,"price":amount,"required":required,"required_stage":required_stage,"reserve":reserve,"chance":C.CLUB_CHANCE[mini(3,level+1)]}

func club_forecast(bar: Dictionary) -> Dictionary:
	var proposed := bar.duplicate(true)
	proposed.club_level = mini(3,int(bar.club_level)+1)
	var before := forecast(bar)
	var after := forecast(proposed,false,-1,-1,0,false,{"original":bar,"bar":proposed})
	return {"before":before,"after":after,"delta":(after.net-before.net)/60.0}

func promoter_forecast(bar: Dictionary, owner_active: bool = false) -> Dictionary:
	var proposed := bar.duplicate(true)
	proposed.team.append({"role":3,"on":true,"host":-1,"audience_training":0,"contract_left":C.STAFF_CONTRACT_MINUTES})
	# Match the duplicate to the original property when dividing street traffic.
	var before := forecast(bar,false,-1,-1,0,owner_active)
	var after := forecast(proposed,false,-1,-1,0,owner_active,{"original":bar,"bar":proposed})
	var street_delta: float = after.net-before.net
	for other in s.street.bars:
		if other==bar: continue
		street_delta += forecast(other,false,-1,-1,0,false,{"original":bar,"bar":proposed}).net-forecast(other).net
	return {"before":before,"after":after,"street_delta":street_delta}

func pending(bar: Dictionary) -> int:
	var count := 0
	for customer in bar.customers:
		if customer.order: count += 1
	for round in bar.get("host_rounds",[]):
		if round.state=="waiting": count += 1
	return count

func cost(bar: Dictionary, amount: int, category: String) -> bool:
	if s.cash < amount: return false
	Finance.change(s,-amount,operating_description(bar) if category=="operating" else {"stock_cost":"Stock purchase / consignment repayment","promo_cost":"Promotion fee","fines":"Trading fine","commission":"Sales commission"}.get(category,category),str(bar.name))
	s.weekly.costs += amount
	s.street.earnings_net -= amount
	bar.earnings_net -= amount
	bar.shift[category] += amount
	if category in ["operating","promo_cost","fines"]: party_add(bar,category,amount)
	return true

func income(bar: Dictionary, amount: int, reason: String = "Drink sales") -> void:
	s.street.earnings_net += amount
	bar.earnings_net += amount
	Finance.change(s,amount,reason,str(bar.name))
	s.weekly.revenue += amount
	s.street.earned += amount
	bar.shift.revenue += amount

func restock(bar: Dictionary, automatic: bool = false, drink: int = 0) -> bool:
	var offer := stock_offer(bar,automatic,drink)
	if not offer.enabled or not cost(bar,offer.price,"stock_cost"): return false
	add_stock(bar,drink,offer.quantity,drink_cost(bar,drink))
	return true

func preferred_drink(bar: Dictionary, customer: Dictionary) -> int:
	if customer.opening and customer.drinks==0 or bar.consignment>0: return 0
	# Draw independently of traffic and keep the preference stable for this order.
	var choice := int(customer.get("taste_roll",posmod(hash(int(customer.id)),100)))
	choice = (choice+int(customer.drinks)*39)%100
	var audience := int(customer.get("audience",0))
	for drink in drink_count(bar):
		choice -= taste(bar,audience,drink)
		if choice<0: return drink
	return 0

func order(bar: Dictionary, customer: Dictionary) -> void:
	if not is_trading(bar): return
	var legacy: bool = customer.get("visit_phase","legacy")=="legacy"
	var limit: int = (C.CELEBRATION_DRINK_LIMIT if celebrating(bar) or customer.get("club",false) else 2) if legacy else int(customer.planned_rounds)
	if customer.order or customer.missed: return
	if not legacy and customer.visit_phase=="finished": return
	if not legacy and customer.next>0: return
	if customer.drinks>=limit:
		if not legacy: finish_visit(customer)
		return
	var drink := affordable_drink(bar,int(customer.get("audience",0)),preferred_drink(bar,customer),int(customer.budget))
	if drink<0:
		if not legacy: finish_visit(customer)
		return
	if not legacy: customer.visit_phase = "waiting"
	var amount := price(bar,drink)
	customer.drink = drink
	var accepts_lager := not carries_drink(bar,drink) or posmod(hash(Vector3i(int(customer.id),int(customer.drinks),-1)),100)<int(C.DRINKS[drink].substitute)
	customer.lager_quote = price(bar) if drink>0 and accepts_lager and customer.budget>=price(bar) else 0
	var key: String = C.DRINKS[drink].id
	bar.shift.drink_requests[key] = int(bar.shift.drink_requests.get(key,0))+1
	customer.order = true
	customer.commission_order = C.COMMISSION_PERCENT>0 and (customer.get("commission_visit",false) or promoter_bonus(bar)>0)
	customer.quoted = amount
	customer.wait = 0
	bar.orders += 1
	bar.shift.orders += 1
	s.street.orders += 1
	bar.recent_orders.append(int(s.street.elapsed))

static func finish_visit(customer: Dictionary) -> void:
	customer.visit_phase = "finished"
	customer.visit_complete = customer.drinks>0 and not customer.missed

static func visit_status(customer: Dictionary) -> String:
	if customer.get("visit_phase","legacy")=="legacy": return "Waiting for a drink (saved visit)" if customer.order else "Saved visit · %ds remaining" % maxi(0,int(customer.life))
	if customer.missed: return "Leaving after a missed order"
	if customer.order: return "Waiting for round %d/%d" % [int(customer.drinks)+1,int(customer.get("planned_rounds",0))]
	if customer.get("visit_phase","")=="finished": return "Finishing pool" if customer.playing else "Waiting for pool" if customer.pool and not customer.played else "Leaving"
	return "Drinking round %d/%d · %ds" % [customer.drinks,customer.get("planned_rounds",0),maxi(0,int(customer.next))]

func admit(bar: Dictionary, promoted: bool = false, opening: bool = false, audience: int = 0) -> bool:
	if not is_trading(bar): return false
	if bar.customers.size() >= seats(bar):
		bar.lost_full += 1
		bar.shift.lost_full += 1
		party_add(bar,"lost_full")
		if promoted and not bar.promo.is_empty(): bar.promo.lost += 1
		return false
	var customer := {"id":int(s.street.next_customer),"life":C.VISIT_SECONDS+(20 if bar.equipment.comfort else 0)+(C.CELEBRATION_EXTRA_STAY if celebrating(bar) else 0),"order":false,"wait":0,"quoted":0,"drinks":0,"next":0,
		"audience":audience,"fine_budget":600*int(bar.stage) if audience==2 else 0,"budget":int(C.TYPES[int(bar.type)].drink)*2+100,"taste_roll":roll(100),"pool":roll(100)<(85 if bar.promo.get("kind",-1) in [0,2] else 40),
		"pool_wait":0,"played":false,"playing":false,"missed":false,"opening":opening,"promo":int(bar.promo.get("id",0)) if promoted else 0}
	customer.merge(customer_action_fields())
	customer.hosted = false
	customer.host_interest = -1
	if bar.type==1 and posmod(hash(Vector2i(int(customer.id),-81)),100)<C.HOST_DRINK_CHANCE[audience]:
		customer.host_interest = posmod(hash(Vector2i(int(customer.id),-83)),3)
		if audience!=2: customer.fine_budget = 340 if audience==0 else 380
	customer.club = posmod(hash(Vector2i(int(customer.id),-31)),100)<C.CLUB_CHANCE[int(bar.club_level)]
	customer.merge(visit_fields())
	# Stable per-visitor choice leaves shared arrival RNG alone. Opening rush stays forgiving.
	var rounds := 2 if opening or posmod(hash(Vector2i(int(customer.id),-53)),100)>=C.ONE_ROUND_CHANCE[audience] else 1
	if customer.club or celebrating(bar): rounds += 1
	var in_costume: bool = local_event(bar,C.Local.ZOMBIES) and s.street.event.prepared
	if in_costume:
		rounds = 3
		customer.costume = true
	customer.planned_rounds = mini(3,rounds)
	customer.budget = int(C.TYPES[int(bar.type)].drink)*int(customer.planned_rounds)+100
	customer.visit_phase = "waiting"
	# Cosmetic identity on new admissions only. Saved guests keep their old look;
	# this consumes no RNG and cannot change traffic, orders or visit plans.
	if int(customer.id)%48==24: customer.appearance = "charcoal"
	customer.party_patience = C.CELEBRATION_PATIENCE if celebrating(bar) else 0
	customer.commission_visit = C.COMMISSION_PERCENT>0 and promoter_bonus(bar)>0
	s.street.next_customer += 1
	bar.customers.append(customer)
	bar.arrivals += 1
	party_add(bar,"arrivals")
	bar.shift.arrivals += 1
	s.street.arrivals += 1
	s.total_guests += 1
	s.weekly.guests += 1
	if promoted: bar.promo.customers += 1
	order(bar,customer)
	return true

func can_supply(bar: Dictionary, drink: int) -> bool:
	return stock_of(bar,drink)>0 or (auto_drink(bar,drink) and stock_offer(bar,true,drink).enabled)

func serving_choice(bar: Dictionary, customer: Dictionary) -> int:
	var drink := int(customer.get("drink",0))
	if can_supply(bar,drink): return drink
	if customer.get("lager_quote",0)>0 and can_supply(bar,0): return 0
	return -1

func drink_orders(bar: Dictionary, drink: int) -> int:
	var total := 0
	for customer in bar.customers:
		if customer.order and int(customer.get("drink",0))==drink: total += 1
	if drink==0:
		for round in bar.get("host_rounds",[]):
			if round.state=="waiting": total += 1
	return total

func fridge_needs(bar: Dictionary) -> Array[int]:
	var needs: Array[int] = []
	for drink in drink_count(bar):
		if drink_orders(bar,drink)<=stock_of(bar,drink): continue
		if auto_drink(bar,drink) and stock_offer(bar,true,drink).enabled: continue
		needs.append(drink)
	return needs

func stock_waiting(bar: Dictionary, drink: int = -1) -> int:
	var total := 0
	for customer in bar.customers:
		if customer.order and (drink<0 or customer.drink==drink) and serving_choice(bar,customer)<0: total += 1
	if drink in [-1,0] and not can_supply(bar,0):
		for round in bar.get("host_rounds",[]):
			if round.state=="waiting": total += 1
	return total

# A single sellable order keeps Serve available, including accepted substitutes.
func blocking_drink(bar: Dictionary) -> int:
	var first := -1
	for customer in bar.customers:
		if not customer.order: continue
		if serving_choice(bar,customer)>=0: return -1
		if first<0: first = int(customer.get("drink",0))
	for round in bar.get("host_rounds",[]):
		if round.state=="waiting":
			if can_supply(bar,0): return -1
			if first<0: first = 0
	return first

func record_stock_miss(bar: Dictionary, drink: int) -> void:
	var key: String = C.DRINKS[drink].id
	bar.shift.drink_misses[key] = int(bar.shift.drink_misses.get(key,0))+1

func serve(bar: Dictionary, count: int = 1, manual: bool = false) -> int:
	if count<=0 or not is_trading(bar): return 0
	if manual and not action_status(bar,"serve").enabled: return 0
	if manual: count = 1
	var sold := 0
	# An urgent sponsored order shares the same service slot as ordinary orders.
	for round in bar.get("host_rounds",[]):
		if round.state=="waiting" and float(round.host_deadline)-action_time()<=10:
			sold = serve_hosted(bar,manual)
			break
	for customer in bar.customers:
		if sold >= count: break
		if not customer.order: continue
		var drink := serving_choice(bar,customer)
		if drink<0: continue
		if stock_of(bar,drink)<pack_quantity(bar) and auto_drink(bar,drink): restock(bar,true,drink)
		if stock_of(bar,drink)==0: continue
		var substituted := drink!=int(customer.get("drink",0))
		var quote := int(customer.lager_quote) if substituted else int(customer.quoted)
		if substituted: record_stock_miss(bar,int(customer.drink))
		income(bar,quote)
		var commission := 0
		if promoter_bonus(bar)>0 or customer.get("commission_visit",false) or customer.get("commission_order",false):
			commission = commission_charge(bar,quote)
			cost(bar,commission,"commission")
			bar.commission_paid += commission
		customer.commission_order = false
		var consignment_cost := C.CONSIGNMENT_COST if drink==0 and bar.get("consignment",0)>0 else 0
		if consignment_cost>0:
			cost(bar,C.CONSIGNMENT_COST,"stock_cost")
			bar.consignment -= 1
		var consumed := consume_stock(bar,drink)
		bar.shift.consumed_stock += consumed
		management_bonus(bar,quote-(consignment_cost if consignment_cost>0 else consumed))
		customer.budget -= quote
		customer.order = false
		var tip_bonus := 0
		if customer.drinks==0:
			bar.tip_visits += 1
			var chance := int(C.DRINK_TIP_CHANCE[int(customer.get("audience",0))][drink])
			# Use a stable roll so this does not advance the traffic RNG.
			if not substituted and posmod(hash(Vector3i(int(customer.id),drink,-7)),100)<chance:
				tip_bonus = C.DRINK_TIP_BONUS
				bar.bonus_tips += tip_bonus
		customer.drinks += 1
		customer.next = repeat_order_seconds(bar)
		if customer.get("visit_phase","legacy")!="legacy": customer.visit_phase = "drinking"
		party_add(bar,"sales")
		party_add(bar,"drink_income",quote)
		party_add(bar,"drink_cost",consumed)
		party_add(bar,"commission",commission)
		bar.dirt = mini(C.DIRT_LIMIT,int(bar.dirt)+(C.PEAK_DIRT_PER_DRINK if peak(int(bar.type),int(s.street.minute)) else 1))
		bar.sold += 1
		bar.shift.sales += 1
		s.street.served += 1
		bar.recent_sales.append(int(s.street.elapsed))
		var report := promotion_record(bar,int(customer.promo))
		if not report.is_empty():
			report.drink_revenue += quote
			report.drink_cost += consumed
			report["commission"] = int(report.get("commission",0))+commission
		if bar.type == 1 and customer.drinks == 2 and on_duty(bar,1)>0 and customer.fine_budget>=C.BAR_FINE_FEES[0] and roll(100)<40:
			bar.host_requests.append(int(customer.id))
		sold += 1
		if manual:
			last_sale = "%s sold · ฿%d margin%s" % [C.DRINKS[drink].name,quote-consumed-commission," · substitute" if substituted else ""]
			if tip_bonus>0: last_sale += " · +฿%d tip" % tip_bonus
	while sold<count:
		if serve_hosted(bar,manual)==0: break
		sold += 1
	if manual and sold > 0: start_cooldown(bar,"serve",action_cooldown(bar,"serve"))
	return sold

# Deadlines use the saved foreground clock, never wall-clock or rendered frames.
func action_time() -> float:
	return float(s.street.elapsed)+float(s.street.get("tick_fraction",0.0))

func action_cooldown(bar: Dictionary, id: String) -> float:
	if id=="chat": return C.CHAT_SECONDS*owner_recharge_scale
	var key := "pouring" if id=="serve" else "welcoming"
	return float(C.ACTION_COOLDOWNS[int(bar.action_levels[key])])*owner_recharge_scale

func start_cooldown(bar: Dictionary, id: String, duration: float) -> void:
	bar[id+"_duration"] = duration
	bar[id+"_ready"] = action_time()+duration

static func patience(bar: Dictionary, customer: Dictionary) -> int:
	return (45 if customer.opening else C.PATIENCE_SECONDS)+(10 if bar.equipment.comfort else 0)+(C.CHAT_PATIENCE if customer.get("chatted",false) else 0)+int(customer.get("party_patience",0))

static func order_seconds_left(bar: Dictionary, customer: Dictionary) -> int:
	var remaining := patience(bar,customer)-int(customer.wait)
	return mini(remaining,int(customer.life)) if customer.get("visit_phase","legacy")=="legacy" else remaining

func chat_target(bar: Dictionary) -> Dictionary:
	var target := {}
	var shortest := C.CHAT_THRESHOLD+1
	for customer in bar.customers:
		if not customer.order or customer.missed or customer.get("chatted",false): continue
		var remaining := order_seconds_left(bar,customer)
		if remaining>=0 and remaining<shortest:
			shortest = remaining
			target = customer
	return target

func action_status(bar: Dictionary, id: String) -> Dictionary:
	var timer := "serve" if id=="serve" else "welcome"
	var remaining := maxf(0.0,float(bar[timer+"_ready"])-action_time())
	var duration := maxf(0.001,float(bar[timer+"_duration"]))
	var waiting := pending(bar) if id=="serve" else 0
	var no_orders := id=="serve" and waiting==0
	var no_chat_target := id=="chat" and chat_target(bar).is_empty()
	var trading := is_trading(bar)
	var short_drink := blocking_drink(bar) if id=="serve" and trading and waiting>0 else -1
	var needs_stock := short_drink>=0
	var reason := ""
	if not trading: reason = status(bar)
	elif needs_stock: reason = "Waiting orders need %s." % C.DRINKS[short_drink].name
	elif no_orders: reason = "No orders waiting. Welcome customers or plan a promotion."
	elif remaining>0.000001: reason = "%s ready in %.1fs." % ["Serve" if id=="serve" else "Welcome / Chat",remaining]
	elif id=="welcome" and promoter_bonus(bar)>0: reason = "Nida is welcoming customers."
	elif no_chat_target: reason = "Chat helps an unchatted guest with 10s or less left to wait."
	return {"enabled":reason.is_empty(),"reason":reason,"no_orders":no_orders,"no_chat_target":no_chat_target,"waiting":waiting,"needs_stock":needs_stock,"short_drink":short_drink,"remaining":remaining,"duration":duration,"fill":clampf(1.0-remaining/duration,0.0,1.0)}

func action_upgrade_status(bar: Dictionary, index: int) -> Dictionary:
	var item: Dictionary = C.ACTION_UPGRADES[index]
	var level := int(bar.action_levels[item.id])
	var cap := 4 if index==0 else 3
	var price := 0 if level==cap else int(C.ACTION_UPGRADE_COSTS[level])
	var required_stage := 2 if index==0 and level==3 else 1
	var stage_ok: bool = bar.stage>=required_stage
	var required := price
	var shortfall := maxi(0,required-int(s.cash))
	return {"available":int(s.cash),"level":level,"price":price,"required":required,"shortfall":shortfall,"enabled":level<cap and shortfall==0 and stage_ok,"maxed":level==cap,"stage_ok":stage_ok,"required_stage":required_stage,
		"current":C.ACTION_COOLDOWNS[level],"next":C.ACTION_COOLDOWNS[mini(cap,level+1)]}

func buy_action_upgrade(bar: Dictionary, index: int) -> String:
	if index<0 or index>=C.ACTION_UPGRADES.size(): return "Unknown action upgrade."
	var state := action_upgrade_status(bar,index)
	if state.maxed: return "Already at the fastest cooldown."
	if not state.stage_ok: return "Two-second pouring needs venue stage 2."
	if not state.enabled: return "Need ฿%d more." % state.shortfall
	var item: Dictionary = C.ACTION_UPGRADES[index]
	Finance.change(s,-int(state.price),"Owner action training",str(bar.name))
	s.weekly.costs += state.price
	bar.action_levels[item.id] += 1
	return "%s: %ds → %ds on the next use." % [item.name,state.current,state.next]

func promotion_record(bar: Dictionary, id: int) -> Dictionary:
	if id == 0: return {}
	if bar.promo.get("id",-1) == id: return bar.promo
	if bar.promo_report.get("id",-1) == id: return bar.promo_report
	return {}

func depart(bar: Dictionary, customer: Dictionary) -> void:
	var completed: bool = customer.drinks>=2 and not customer.missed if customer.get("visit_phase","legacy")=="legacy" else customer.get("visit_complete",false) and not customer.missed
	if completed:
		bar.completed += 1
		bar.shift.completed += 1
		bar.happy += 1
		bar.shift.happy += 1
		party_add(bar,"happy")
		if int(bar.happy)%10 == 0: s.rep = mini(100,int(s.rep)+1+int(bar.equipment.fridge))
		if roll(100) < C.REGULAR_CHANCE:
			bar.regulars += 1
			party_add(bar,"regulars")
			s.regulars += 1
			var report := promotion_record(bar,int(customer.promo))
			if not report.is_empty(): report.regulars += 1
	for round in bar.get("host_rounds",[]).duplicate():
		if int(round.guest)==int(customer.id): bar.host_rounds.erase(round)
	bar.host_requests.erase(int(customer.id))
	bar.customers.erase(customer)

func pool_queue(bar: Dictionary) -> Array:
	var waiting := []
	for customer in bar.customers:
		if customer.pool and not customer.played and not customer.playing and customer.pool_wait < C.POOL_PATIENCE and customer.budget >= 25:
			waiting.append(customer)
	return waiting.slice(0,4)

func pool_tick(bar: Dictionary) -> void:
	if not is_trading(bar): return
	for game in bar.games.duplicate():
		game.remaining -= 1
		if game.remaining <= 0:
			for customer in bar.customers:
				if customer.id in game.players: customer.playing = false
			bar.games.erase(game)
	while bar.games.size() < bar.equipment.pool:
		var waiting := pool_queue(bar)
		if waiting.size()<2: break
		var pair: Array = waiting.slice(0,2)
		var fee := 0 if bar.promo.get("kind",-1) == 0 else C.POOL_FEE
		var ids := []
		for customer in pair:
			customer.budget -= fee/2
			customer.playing = true
			customer.played = true
			customer.life = maxi(int(customer.life)+C.POOL_EXTRA_STAY,C.POOL_SECONDS+1)
			ids.append(customer.id)
		var occupied := []
		for game in bar.games: occupied.append(int(game.get("table",0)))
		var table := 0
		while table in occupied: table += 1
		bar.games.append({"table":table,"players":ids,"remaining":C.POOL_SECONDS,"fee":fee})
		bar.pool_games += 1
		bar.pool_income += fee
		party_add(bar,"pool_income",fee)
		bar.shift.pool_income += fee
		income(bar,fee,"Pool game")
		management_bonus(bar,fee)
		if fee == 0:
			bar.free_games += 1
			bar.shift.free_games += 1
		if not bar.promo.is_empty():
			bar.promo.pool_revenue += fee
			if fee == 0: bar.promo.free_games += 1

func promotion_offer(bar: Dictionary, kind: int) -> Dictionary:
	var item: Dictionary = C.PROMOTIONS[kind]
	var required := int(item.fee)
	var reason := ""
	if not is_trading(bar): reason = status(bar)
	elif not bar.promo.is_empty() or bar.promo_cooldown>0: reason = "Finish this promotion and its one-shift cooldown first."
	elif not str(item.requires).is_empty() and bar.equipment[item.requires] == 0: reason = "Buy the %s first." % item.requires
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"required":required}

func start_promotion(bar: Dictionary, kind: int) -> String:
	if kind<0 or kind>=C.PROMOTIONS.size(): return "Unknown promotion."
	var offer := promotion_offer(bar,kind)
	if not offer.enabled: return offer.reason
	var item: Dictionary = C.PROMOTIONS[kind]
	cost(bar,int(item.fee),"promo_cost")
	bar.promo_repeats = int(bar.promo_repeats)+1 if bar.last_promo == kind and bar.ordinary_seconds < 240 else 1
	bar.last_promo = kind
	bar.ordinary_seconds = 0
	bar.promo_id += 1
	bar.promo = {"id":bar.promo_id,"kind":kind,"remaining":C.PROMOTION_SECONDS,"repetition":bar.promo_repeats,"customers":0,"drink_revenue":0,"drink_cost":0,
		"pool_revenue":0,"free_games":0,"regulars":0,"lost":0,"fee":int(item.fee),"operating":0,"operating_credit":0,"baseline":forecast(bar).arrivals*2.0}
	return "%s started. Compare the report after two minutes." % item.name

func equipment_offer(bar: Dictionary,index: int) -> Dictionary:
	var item: Dictionary = C.EQUIPMENT[index]
	var id: String = item.id
	var amount := int(item.cost)*(int(bar.equipment[id])+1)
	var maxed: bool = int(bar.equipment[id])>=equipment_limit(bar,id,int(item.max))
	var required := amount
	var reason := ""
	if id=="training": reason = "Choose an individual team member to train in Service."
	elif maxed: reason = "Already fully equipped."
	elif id=="pool" and bar.type!=0: reason = "Pool tables belong in beer bars."
	elif id=="pool" and bar.equipment.pool>=bar.stage: reason = "Upgrade the venue before adding another table."
	elif bar.stage<equipment_stage(bar,id,int(bar.equipment[id])+1): reason = "Needs venue stage %d." % equipment_stage(bar,id,int(bar.equipment[id])+1)
	elif id=="menu" and bar.stage<2: reason = "Premium menus unlock at stage 2."
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":amount,"required":required,"maxed":maxed,"required_stage":equipment_stage(bar,id,int(bar.equipment[id])+1)}

func buy_equipment(bar: Dictionary, index: int) -> String:
	if index<0 or index>=C.EQUIPMENT.size(): return "Unknown equipment."
	var offer := equipment_offer(bar,index)
	if not offer.enabled: return offer.reason
	var item: Dictionary = C.EQUIPMENT[index]
	Finance.change(s,-int(offer.price),"Equipment: "+str(C.EQUIPMENT[index].name),str(bar.name))
	s.weekly.costs += offer.price
	bar.equipment[item.id] += 1
	return "%s installed. %s" % [item.name,item.help]

func auto_serve_offer(bar: Dictionary) -> Dictionary:
	var required: int = C.AUTO_SERVE_COST
	var enabled: bool = s.cash>=required
	return {"available":int(s.cash),"enabled":enabled,"price":C.AUTO_SERVE_COST,"required":required,"reason":"" if enabled else "Not enough money for this purchase."}

func training_offer(bar: Dictionary,index: int,audience: bool) -> Dictionary:
	var person: Dictionary = bar.team[index]
	var level := int(person.get("audience_training" if audience else "training",0))
	var amount := (C.AUDIENCE_TRAINING_COST if audience else C.STAFF_TRAINING_COST)*(level+1)
	var maxed := level>=(2 if audience else training_limit(bar))
	var required := amount
	var reason := ""
	if not contracted(person): reason = "Rehire this team member before training."
	elif audience and not int(person.role) in [2,3]: reason = "Audience training is for promoters and dancers."
	elif not audience and person.role!=0: reason = "Service training is for bartenders. Reassign their role first."
	elif maxed: reason = "Already fully trained."
	elif not audience and level>=4 and bar.stage<3: reason = "Advanced service training needs venue stage 3."
	elif not audience and level>=2 and bar.stage<2: reason = "Advanced service training needs venue stage 2."
	elif audience and bar.stage<level+2: reason = "Needs venue stage %d." % (level+2)
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":amount,"required":required,"maxed":maxed,"level":level,"required_stage":level+2 if audience else 1 if level<2 else 2 if level<4 else 3}

func upgrade_required_cash(bar: Dictionary) -> int:
	return int(C.RENOVATIONS[int(bar.type)][int(bar.stage)-1])

func upgrade_reason(bar: Dictionary) -> String:
	if bar.stage>=3: return "Final stage reached."
	if s.cash<upgrade_required_cash(bar): return "Not enough money for this purchase."
	return ""

func hire_offer(bar: Dictionary, role: int) -> Dictionary:
	var amount := contract_cost(role)
	var required := amount
	var reason := ""
	if role==1 and bar.type!=1: reason = "Hosts work in Hostess bars."
	elif role==2 and bar.type!=2: reason = "Dancers work in gogos."
	elif role==3 and promoter_index(bar)>=0: reason = "Rehire your existing promoter instead."
	elif role!=3 and floor_staff(bar)>=int(bar.stage)*2: reason = "Upgrade for more team positions."
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":amount,"required":required}

func role_change_required_cash(bar: Dictionary, index: int) -> int:
	var fee := role_change_fee(bar,index)
	if fee==0: return 0
	return fee

func action(bar: Dictionary, id: String, index: int) -> String:
	match id:
		"regulars_club":
			var offer := club_offer(bar)
			if not offer.enabled: return offer.reason
			Finance.change(s,-int(offer.price),"Regulars club",str(bar.name))
			s.weekly.costs += offer.price
			bar.club_level += 1
			return "Regulars Club %d: %d%% of new visitors stay for up to three drinks. Stock and service still matter." % [bar.club_level,offer.chance]
		"auto_serve":
			if bar.auto_serve:
				bar.auto_serve_on = not bar.auto_serve_on
				return "Auto-serve %s. The existing Serve cooldown is unchanged." % ("on" if bar.auto_serve_on else "off")
			var offer := auto_serve_offer(bar)
			if not offer.enabled: return offer.reason
			Finance.change(s,-int(C.AUTO_SERVE_COST),"Owner auto-serve",str(bar.name))
			s.weekly.costs += C.AUTO_SERVE_COST
			bar.auto_serve = true
			bar.auto_serve_on = true
			return "Auto-serve purchased. It uses real orders, stock and your existing Serve cooldown."
		"serve":
			var state := action_status(bar,id)
			if not state.enabled: return state.reason
			return last_sale if serve(bar,1,true)>0 else "Restock the fridge."
		"welcome":
			var state := action_status(bar,id)
			if not state.enabled: return state.reason
			bar.welcome = mini(3,int(bar.welcome)+1)
			bar.welcome_until = action_time()+20
			start_cooldown(bar,"welcome",action_cooldown(bar,"welcome"))
			return "Welcoming passersby. The street still has a limited crowd."
		"chat":
			var state := action_status(bar,id)
			if not state.enabled: return state.reason
			var customer := chat_target(bar)
			customer.chatted = true
			customer.life += C.CHAT_PATIENCE
			customer.chat_until = action_time()+3.0
			start_cooldown(bar,"welcome",action_cooldown(bar,"chat"))
			return "A little reassurance: 10 extra seconds to fulfil that order."
		"action_upgrade": return buy_action_upgrade(bar,index)
		"stock":
			var offer := stock_offer(bar)
			if not offer.enabled: return offer.reason
			return "%d drinks delivered for ฿%d." % [offer.quantity,offer.price] if restock(bar) else "Delivery unavailable."
		"buy_drink":
			if index<0 or index>=drink_count(bar): return "This drink is not on your menu yet."
			var offer := stock_offer(bar,false,index)
			return "%d %s delivered for ฿%d." % [offer.quantity,C.DRINKS[index].name,offer.price] if restock(bar,false,index) else offer.reason
		"return_drink":
			if index<0 or index>=drink_count(bar): return "This drink is not on your menu yet."
			var units := mini(3,stock_of(bar,index)-(int(bar.consignment) if index==0 else 0))
			if units<=0: return "No paid stock to return."
			var refunded_cost := 0
			for _i in units: refunded_cost += consume_stock(bar,index,true)
			var refund := refunded_cost/2
			Finance.change(s,refund,"Stock return",str(bar.name))
			s.weekly.costs -= refund
			s.street.earnings_net += refund
			bar.earnings_net += refund
			bar.shift.stock_cost -= refund
			return "Returned %d %s · ฿%d back" % [units,C.DRINKS[index].name,refund]
		"equipment": return buy_equipment(bar,index)
		"promotion": return start_promotion(bar,index)
		"clean":
			if is_trading(bar): return "Close the venue before cleaning."
			if bar.dirt==0: return "Already clean."
			if bar.clean_remaining>0: return "Cleaning is already underway."
			bar.clean_remaining = C.CLEAN_SECONDS
			bar.clean_auto_started = true
			return "Cleaning started: 15 seconds. Skipping leaves unfinished work."
		"close_and_count":
			bar.open = false
			bar.close_reason = "Closed by owner"
			close_customers(bar)
			var counted := count_tips(bar,trading_day())
			return "Closed. Counted ฿%d in tips. Buy stock when affordable, then enable opening." % counted.amount
		"open":
			if bar.open:
				bar.open = false
				bar.close_reason = "Closed by owner"
				var counted := count_tips(bar,trading_day())
				close_customers(bar)
				return "Closed. Counted ฿%d in tips. Rent, electricity and wages pause; you can buy stock now." % counted.amount
			if s.cash < ceili(operating_rate(bar)/60.0): return "You need enough cash for the next operating charge."
			bar.open = true
			bar.close_reason = ""
			if is_trading(bar): bar.clean_remaining = 0
			return status(bar)
		"recovery", "emergency_stock":
			if id=="emergency_stock" and not emergency_stock_available(bar): return "Recovery delivery needs an empty fridge, insufficient pack cash and a legal opening; existing recovery must finish first."
			if id=="recovery" and bar.open: return "Close the venue before taking an owner-run recovery shift."
			if s.cash>=maxi(120,pack_price(bar)): return "You have enough cash to reopen normally; recovery cover is for an empty till."
			if bar.recovery>0: return "Recovery cover is already running."
			if bar.closed>0 or bar.raided or not scheduled(bar,int(s.street.minute)): return "Wait until the venue is allowed to open."
			for member in bar.team: member.on = false
			bar.recovery = 120
			bar.open = true
			bar.close_reason = ""
			if bar.stock==0:
				bar.stock = 6
				bar.consignment = 6
				bar.stock_lots = [{"units":6,"cost":C.CONSIGNMENT_COST}]
			return "Anong covers two minutes of overhead. Staff are off duty; Bo's six recovery drinks cost ฿14 only when sold. Serve and welcome manually."
		"rota":
			if index<0 or index>=bar.team.size(): return "Unknown team member."
			if not contracted(bar.team[index]): return "Rehire this team member first."
			bar.team[index].service_clock = 0
			bar.team[index].on = not bar.team[index].on
			commit_orders(bar)
			return "Rota updated. Nida earns no commission or hourly wages." if bar.team[index].role==3 else "Rota updated. Off-duty staff do not incur wages."
		"role":
			if bar.type==0 or index<0 or index>=bar.team.size(): return "Choose a team member at a Hostess bar or gogo."
			if index in bar.away or not hosted_round(bar,index).is_empty(): return "Wait until this team member returns or finishes hosting."
			var person: Dictionary = bar.team[index]
			if person.get("identity","")=="gabby": return "Gabby works as a bartender."
			if person.role==1 and int(person.host)==C.DAISY_HOST: return "Daisy works as a Hostess bar entertainer."
			if not contracted(person): return "Rehire this team member first."
			if person.role==3: return "Promoters have their own frontage contract and cannot change role."
			var fee := role_change_fee(bar,index)
			if fee>0 and s.cash<role_change_required_cash(bar,index): return "Role change costs ฿%d." % fee
			Finance.change(s,-int(fee),"Staff contract role adjustment",str(bar.name))
			s.weekly.costs += fee
			person.service_clock = 0
			person.role = int(bar.type) if person.role==0 else 0
			person.host = free_host(bar) if person.role==1 else -1
			return "Role changed to %s. Contract adjustment ฿%d; remaining term and training retained." % [C.ROLE_NAMES[int(person.role)],fee]
		"hire_daisy":
			if bar.type!=1: return "Daisy works in Hostess bars."
			var venue := daisy_venue()
			if not venue.is_empty(): return "Daisy already has a roster place at %s. Renew her existing contract there." % venue
			var before: int = bar.team.size()
			var result := action(bar,"hire",1)
			if bar.team.size()==before: return result
			bar.team.back().host = C.DAISY_HOST
			return "Daisy hired for ten days (฿4,500). She attracts visitors; bartenders serve their orders."
		"hire_gabby":
			var venue := gabby_venue()
			if not venue.is_empty(): return "Gabby already has a roster place at %s. Renew her existing contract there." % venue
			var before: int = bar.team.size()
			var result := action(bar,"hire",0)
			if bar.team.size()==before: return result
			bar.team.back()["identity"] = "gabby"
			return "Gabby hired for ten days (฿1,200). Each drink she serves adds ฿5 to the nightly tip jar."
		"hire":
			if index<0 or index>3: return "Unknown role."
			var hire := hire_offer(bar,index)
			if not hire.enabled: return hire.reason
			var amount: int = hire.price
			Finance.change(s,-int(amount),"New "+str(C.ROLE_NAMES[index])+" contract",str(bar.name))
			s.weekly.costs += amount
			var host := free_host(bar) if index==1 else -1
			bar.team.append({"role":index,"on":true,"host":host,"training":0,"audience_training":0,"host_training":0,"host_return":0.0,"service_clock":0,"contract_left":C.STAFF_CONTRACT_MINUTES})
			ensure_staff_service(bar.team.back())
			bar.crew = bar.team.size()
			commit_orders(bar)
			return "Nida hired: ten days, ฿1,200, no commission. She welcomes; you serve." if index==3 else "%s hired for ten game days (฿%d). Wages: ฿%d/real min while trading on duty." % [C.ROLE_NAMES[index],amount,C.ROLE_WAGES[index]]
		"rehire":
			if index<0 or index>=bar.team.size(): return "Unknown team member."
			var person: Dictionary = bar.team[index]
			if contracted(person): return "This contract is still active."
			var offer := rehire_offer(bar,index)
			if not offer.enabled: return offer.reason
			var amount: int = offer.price
			Finance.change(s,-int(amount),"Renew "+str(C.ROLE_NAMES[int(person.role)])+" contract",str(bar.name))
			s.weekly.costs += amount
			person.contract_left = C.STAFF_CONTRACT_MINUTES
			person.on = true
			person.service_clock = 0
			commit_orders(bar)
			return "Rehired for ten game days. Their training is unchanged."
		"train_audience","train_staff":
			if index<0 or index>=bar.team.size(): return "Choose a team member."
			var audience := id=="train_audience"
			var offer := training_offer(bar,index,audience)
			if not offer.enabled: return offer.reason
			var person: Dictionary = bar.team[index]
			Finance.change(s,-int(offer.price),"Audience training" if audience else "Bartender training",str(bar.name))
			s.weekly.costs += offer.price
			if audience:
				person.audience_training = int(offer.level)+1
				return "Audience training improved. Skills stay with the person after rehiring."
			person.training = int(offer.level)+1
			return "Training retained for future contracts. Now serves one drink every %ds." % service_seconds(person)
		"train_host":
			var offer := host_training_offer(bar,index)
			if not offer.enabled: return offer.reason
			Finance.change(s,-int(offer.price),"Host training",str(bar.name))
			s.weekly.costs += offer.price
			bar.team[index].host_training = int(offer.level)+1
			return "Host training improved appeal and future bar-fine fees. Skills stay after rehire."
		"auto_bar_fine":
			if bar.get("auto_bar_fine",false):
				bar.auto_bar_fine_on = not bar.auto_bar_fine_on
				return "Automatic bar fines " + ("on." if bar.auto_bar_fine_on else "off.")
			var offer := auto_bar_fine_offer(bar)
			if not offer.enabled: return offer.reason
			Finance.change(s,-int(offer.price),"Automatic host bookings",str(bar.name))
			s.weekly.costs += offer.price
			bar.auto_bar_fine = true
			bar.auto_bar_fine_on = true
			return "Auto-accept installed. Willing, available hosts accept affordable requests on live ticks."
		"host_drink":
			return invite_hosted(bar,index)
		"auto_host_drinks":
			if bar.get("auto_host_drinks",false):
				bar.auto_host_drinks_on = not bar.auto_host_drinks_on
				return "Auto-host rounds " + ("on." if bar.auto_host_drinks_on else "off.")
			var offer := auto_hosted_offer(bar)
			if not offer.enabled: return offer.reason
			Finance.change(s,-int(offer.price),"Automatic hosted rounds",str(bar.name))
			s.weekly.costs += offer.price
			bar.auto_host_drinks = true
			bar.auto_host_drinks_on = true
			return "Auto-host rounds installed. Hosts find guests; bartenders still pour."
		"bar_fine":
			return accept_bar_fine(bar,index)
	return ""

static func host_appeal(person: Dictionary) -> float:
	return C.HOST_APPEAL[int(person.get("host_training",0))]

static func host_fee(person: Dictionary) -> int:
	return C.BAR_FINE_FEES[int(person.get("host_training",0))]

func host_training_offer(bar: Dictionary, index: int) -> Dictionary:
	var person: Dictionary = bar.team[index] if index>=0 and index<bar.team.size() else {}
	var level := int(person.get("host_training",0))
	var maxed := level>=C.HOST_TRAINING_PRICES.size()
	var amount := 0 if maxed else int(C.HOST_TRAINING_PRICES[level])
	var required := amount
	var reason := ""
	if person.get("role",-1)!=1 or bar.type!=1: reason = "Choose an adult Soi host."
	elif not contracted(person): reason = "Rehire this host before training."
	elif maxed: reason = "Already fully trained."
	elif bar.stage<level+2: reason = "Needs venue stage %d." % (level+2)
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":amount,"required":required,"level":level,"maxed":maxed,"required_stage":level+2}

func auto_bar_fine_offer(bar: Dictionary) -> Dictionary:
	var required: int = C.AUTO_BAR_FINE_COST
	var reason := ""
	var willing := false
	for person in bar.team:
		if person.role==1 and C.HOSTS[int(person.host)][2] and contracted(person): willing = true
	if bar.type!=1: reason = "Bar fines belong to Hostess bars."
	elif bar.get("auto_bar_fine",false): reason = "Already installed."
	elif not willing: reason = "Hire a host who accepts bar-fine requests first."
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":C.AUTO_BAR_FINE_COST,"required":required}

func bar_fine_offer(bar: Dictionary, index: int) -> Dictionary:
	var person: Dictionary = bar.team[index] if index>=0 and index<bar.team.size() else {}
	var fee := host_fee(person)
	var remaining := maxf(0.0,float(person.get("host_return",0))-action_time())
	var request := -1
	# Inspect real, still-present customers without consuming requests or RNG.
	for id in bar.host_requests:
		for customer in bar.customers:
			if int(customer.id)==int(id) and customer.fine_budget>=fee and not hosted_guest_busy(bar,int(id)):
				request = int(id)
				break
		if request>=0: break
	var occupied := 0
	for i in bar.away:
		if int(i)>=0 and int(i)<bar.team.size() and bar.team[int(i)].role==1: occupied += 1
	var reason := ""
	if bar.type!=1 or person.get("role",-1)!=1: reason = "Choose an adult Soi host."
	elif not C.HOSTS[int(person.host)][2]: reason = "Declines bookings · hosted drinks only"
	elif not hosted_round(bar,index).is_empty(): reason = "Finishing a hosted round"
	elif remaining>0: reason = "Away · back in %ds" % ceili(remaining)
	elif not contracted(person): reason = "Contract finished"
	elif not person.on: reason = "Off duty"
	elif index in bar.away: reason = "Returning" if float(person.get("host_return",0))>0 else "Away · back next shift"
	elif not is_trading(bar): reason = "Venue closed"
	elif occupied>=int(bar.stage): reason = "Booking spaces full"
	elif request<0: reason = "No affordable customer request"
	return {"enabled":reason.is_empty(),"reason":reason,"fee":fee,"appeal":host_appeal(person),"remaining":remaining,"request":request}

func accept_bar_fine(bar: Dictionary, index: int) -> String:
	var offer := bar_fine_offer(bar,index)
	if not offer.enabled: return "This host is unavailable. " + str(offer.reason)
	for customer in bar.customers:
		if int(customer.id)!=int(offer.request): continue
		customer.fine_budget -= int(offer.fee)
		while int(offer.request) in bar.host_requests: bar.host_requests.erase(int(offer.request))
		bar.away.append(index)
		bar.team[index].host_return = action_time()+C.BAR_FINE_SECONDS
		income(bar,int(offer.fee),"Host booking")
		bar.shift.bar_fine_income += int(offer.fee)
		bar.shift.bar_fines += 1
		return "%s accepted · ฿%d received · back in %ds. Appeal is lower while away." % [C.HOSTS[int(bar.team[index].host)][0],offer.fee,C.BAR_FINE_SECONDS]
	return "The customer has left."

func return_hosts(bar: Dictionary) -> void:
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		var deadline := float(person.get("host_return",0))
		if deadline>0 and action_time()>=deadline:
			person.host_return = 0.0
			bar.away.erase(i)

func auto_bar_fines(bar: Dictionary) -> void:
	if not bar.get("auto_bar_fine",false) or not bar.get("auto_bar_fine_on",true) or not is_trading(bar): return
	for i in bar.team.size():
		if bar.team[i].role==1 and bar_fine_offer(bar,i).enabled: accept_bar_fine(bar,i)

static func customer_profit(report: Dictionary) -> int:
	return int(report.get("revenue",0))-int(report.get("manager_income",0))-int(report.get("consumed_stock",0))-int(report.get("operating",0))-int(report.get("promo_cost",0))-int(report.get("fines",0))-int(report.get("commission",0))

func business_summary(bar: Dictionary) -> Dictionary:
	var report: Dictionary = bar.last_shift if not bar.last_shift.is_empty() else bar.shift
	var seconds := int(report.get("open_seconds",0))
	var reason := "Demand: attract more visitors before adding service."
	var bottleneck := "appeal"
	if report.get("lost_stock",0)>0:
		bottleneck = "stock"
		reason = "Supply: missed orders need stock or more reliable deliveries."
	elif report.get("lost_service",0)>0:
		bottleneck = "service"
		reason = "Service: train or add a bartender, or help with the queue."
	elif report.get("lost_full",0)>0:
		bottleneck = "seating"
		reason = "Space: customers were turned away. More seats can absorb demand."
	elif float(report.get("occupied_seconds",0))>=seconds*seats(bar)*.4 and report.get("drinking_seconds",0)>report.get("waiting_seconds",0):
		bottleneck = "music"
		reason = "Turnover: guests are drinking. Better music can free seats sooner."
	if report.get("open_seconds",0)==0: reason = "Trade a shift to measure the next bottleneck."
	var drinking := 0
	var finishing := 0
	for guest in bar.customers:
		if guest.get("visit_phase","")=="drinking": drinking += 1
		if guest.get("visit_phase","")=="finished": finishing += 1
	return {"bottleneck":bottleneck,"reason":reason,"profit_per_minute":customer_profit(report)*60.0/seconds if seconds>0 else 0.0,"manager_per_minute":float(report.get("manager_income",0))*60.0/seconds if seconds>0 else 0.0,"arrivals":report.get("arrivals",0),"orders":report.get("orders",0),"sales":report.get("sales",0),"completed":report.get("completed",0),"waiting":pending(bar),"drinking":drinking,"finishing":finishing,"sample_seconds":seconds,"sample":"Last shift" if not bar.last_shift.is_empty() else "Current shift"}

func visit_lines(bar: Dictionary) -> String:
	var lines: Array[String] = []
	for guest in bar.customers: lines.append("Guest %d · %s" % [guest.id,visit_status(guest)])
	return "No visitors yet." if lines.is_empty() else "\n".join(lines)

func settle_shift(bar: Dictionary) -> void:
	var report: Dictionary = bar.shift.duplicate(true)
	report.net = int(report.revenue)-int(report.stock_cost)-int(report.operating)-int(report.promo_cost)-int(report.get("fines",0))-int(report.get("commission",0))
	report.reason = "Healthy service. Compare demand with capacity before expanding."
	if report.lost_stock>0: report.reason = "Out of stock: more reliable deliveries would recover sales."
	elif report.lost_service>0: report.reason = "Slow service: waiting orders need help or trained bartenders."
	elif report.lost_full>0: report.reason = "Full: improve layout or seating before advertising harder."
	elif report.occupied_seconds<report.open_seconds*seats(bar)*.4: report.reason = "Quiet: try signage, welcoming or a targeted promotion."
	# Inventory purchases are investments in later sales: assess operating margin.
	if report.sales>=4 and report.sales>=report.orders*.8 and int(report.revenue)-int(report.get("manager_income",0))-int(report.consumed_stock)-int(report.operating)-int(report.promo_cost)-int(report.get("fines",0))-int(report.get("commission",0))>0:
		bar.healthy += 1
	bar.last_shift = report
	bar.recent.append(report)
	if bar.recent.size()>5: bar.recent.pop_front()
	bar.shift = ledger()

func tick() -> void:
	s.street.elapsed += 1
	for bar in s.street.bars:
		return_hosts(bar)
		hosted_tick(bar)
	# Create a bounded supply of potential visitors shared by every property.
	s.street.pass_credit += roundi(traffic_rate()*1000)
	while s.street.pass_credit>=int(s.street.next_group)*60000:
		var group := int(s.street.next_group)
		s.street.pass_credit -= group*60000
		s.street.offered += group
		s.street.next_group = 2 if roll(100)<(60 if event_id()==1 else 25) else 1
		var mix := audience_weights()
		var segment := roll(100)
		var audience := 0 if segment<int(mix[0]) else 1 if segment<int(mix[0])+int(mix[1]) else 2
		var total := 5000
		for bar in s.street.bars: total += roundi(attraction(bar,false,audience)*1000)
		var choice := roll(total)
		for bar in s.street.bars:
			var weight := roundi(attraction(bar,false,audience)*1000)
			if choice<weight:
				var bonus := 0 if bar.promo.is_empty() else roundi(weight*(float(C.PROMOTIONS[int(bar.promo.kind)].boost)/int(bar.promo.repetition))/maxf(.01,attraction(bar)))
				var promoted: bool = not bar.promo.is_empty() and choice<bonus
				var admitted := 0
				for _guest in group:
					if admit(bar,promoted,false,audience): admitted += 1
				if admitted>0 and not s.bookings.is_empty():
					# Attribute only the part of the existing draw supplied by guide appeal.
					var without_guides := roundi(attraction(bar,false,audience,-1,0,false)*1000)
					if choice>=without_guides:
						var guides: Array = s.bookings.keys()
						guides.sort()
						var guide_slot := (choice-without_guides)*guides.size()/(weight-without_guides)
						tour_arrived.emit(int(guides[guide_slot]),str(bar.name),admitted)
				break
			choice -= weight
	for bar in s.street.bars:
		bar.promo_cooldown = maxi(0,int(bar.promo_cooldown)-1)
		if s.street.elapsed>=bar.welcome_until: bar.welcome = 0
		for key in ["recent_orders","recent_sales"]:
			while not bar[key].is_empty() and bar[key][0]<int(s.street.elapsed)-60: bar[key].pop_front()
		if not bar.promo.is_empty():
			bar.promo.remaining -= 1
			if is_trading(bar):
				bar.promo.operating_credit += operating_rate(bar)
				bar.promo.operating += int(bar.promo.operating_credit)/60
				bar.promo.operating_credit = int(bar.promo.operating_credit)%60
			if bar.promo.remaining<=0:
				finish_promotion(bar)
		else: bar.ordinary_seconds += 1
		if not is_trading(bar): continue
		bar.recovery = maxi(0,int(bar.recovery)-1)
		bar.cost_credit += operating_rate(bar)
		# Recovery suspends collection as well as accrual. Retain an unpaid
		# fractional bill until trading has earned cash, rather than reclosing at zero.
		var charge := 0 if bar.recovery>0 else int(bar.cost_credit)/60
		if not cost(bar,charge,"operating"):
			bar.open = false
			bar.close_reason = "Cannot pay rent, electricity or on-duty wages. Close and count tips to restock."
			close_customers(bar)
			continue
		if bar.recovery==0: bar.cost_credit = int(bar.cost_credit)%60
		bar.shift.open_seconds += 1
		bar.shift.occupied_seconds += bar.customers.size()
		for customer in bar.customers.duplicate():
			var legacy: bool = customer.get("visit_phase","legacy")=="legacy"
			if legacy or customer.missed: customer.life -= 1
			if customer.order:
				bar.shift.waiting_seconds += 1
				customer.wait += 1
				if customer.wait > patience(bar,customer):
					customer.order = false
					customer.missed = true
					var reason := "lost_stock" if serving_choice(bar,customer)<0 else "lost_service"
					if reason=="lost_stock": record_stock_miss(bar,int(customer.get("drink",0)))
					bar[reason] += 1
					bar.shift[reason] += 1
					party_add(bar,reason)
					var report := promotion_record(bar,int(customer.promo))
					if not report.is_empty(): report.lost += 1
					customer.life = mini(int(customer.life),5)
			else:
				if customer.next>0: bar.shift.drinking_seconds += 1
				customer.next = maxi(0,int(customer.next)-1)
				if customer.next<=0 and customer.get("visit_phase","")!="finished": order(bar,customer)
			if customer.pool and not customer.playing and not customer.played and bar.equipment.pool>0:
				customer.pool_wait += 1
				if customer.pool_wait>=C.POOL_PATIENCE:
					customer.pool = false
					var pool_report := promotion_record(bar,int(customer.promo))
					if not pool_report.is_empty(): pool_report.lost += 1
			var pool_waiting: bool = customer.pool and not customer.played and bar.equipment.pool>0 and customer.pool_wait<C.POOL_PATIENCE and customer.budget>=25
			if not customer.playing and not hosted_guest_busy(bar,int(customer.id)) and (((legacy or customer.missed) and customer.life<=0) or (not legacy and customer.visit_phase=="finished" and not pool_waiting)): depart(bar,customer)
		if bar.restock and bar.drink_stock.is_empty() and bar.stock<pack_quantity(bar) and pending(bar)>0: restock(bar,true)
		staff_service(bar)
		if local_event(bar,C.Local.ENCORE) and s.street.event.prepared and int(s.street.event.remaining)%8==0:
			serve(bar)
		if automatic_service(bar) and owner_relief_needed(bar): serve(bar,1,true)
		auto_bar_fines(bar)
		auto_hosted(bar)
		pool_tick(bar)

func offline_drink(bar: Dictionary, mix: Array, sample: int) -> int:
	if bar.drink_stock.is_empty(): return 0
	var weight := 0.0
	for drink in mix.size():
		if stock_of(bar,drink)>0 or (bar.stock==0 and auto_drink(bar,drink)):
			weight += float(mix[drink])
	var roll_value := float(posmod(sample*61,100))/100.0*weight
	for drink in mix.size():
		if stock_of(bar,drink)>0 or (bar.stock==0 and auto_drink(bar,drink)):
			roll_value -= float(mix[drink])
			if roll_value<0: return drink
	return int(bar.stock_lots[0].get("drink",0)) if not bar.stock_lots.is_empty() else 0

func offline(now: int, cap_seconds: int) -> int:
	var gap := maxi(0,now-int(s.street.last_seen))
	var elapsed := mini(gap,cap_seconds)
	var legal_seconds := legal_open_minutes(int(s.street.offline_cursor),elapsed)
	var windows := contract_windows(int(s.street.offline_cursor),elapsed)
	# Even capped-away time advances the projection cursor, never the live clock.
	s.street.offline_cursor = (int(s.street.offline_cursor)+gap)%C.DAY_MINUTES
	s.street.last_seen = maxi(now,int(s.street.last_seen))
	var net := 0
	var visits := 0
	var gross := 0
	var expenses := 0
	var notes := []
	for bar in s.street.bars:
		if not is_trading(bar,true): continue
		var bank := 0
		var venue_gross := 0
		var venue_cost := 0
		var sales := 0
		var estimated_visits := 0.0
		var commission_total := 0
		var packs := 0
		var traded := 0
		var management_total := 0
		var limit := "customer demand / space"
		var projection: Dictionary = bar.duplicate(true)
		ensure_stock_lots(projection)
		for window in windows:
			var view := forecast(bar,true,-1,int(window.minute),int(window.offset))
			if view.net<=0 or view.sales<=0:
				limit = "unviable trading windows"
				continue
			if view.service<view.demand: limit = "service"
			for _second in int(window.seconds):
				# Each claim protects the cash present when it starts. Only its
				# newly generated surplus funds complete supplier packs.
				var drink := offline_drink(projection,view.drink_mix,now+traded)
				if projection.stock==0:
					var wholesale := drink_cost(bar,drink)*pack_quantity(bar)
					if not bar.restock or bank<wholesale:
						limit = "stock / whole-delivery working capital"
						break
					bank -= wholesale
					venue_cost += wholesale
					add_stock(projection,drink,pack_quantity(bar),drink_cost(bar,drink))
					packs += 1
				projection.offline_sales_credit += view.sales/60.0
				projection.offline_cost_pending += view.costs/60.0
				projection.offline_pool_pending += view.pool/60.0
				traded += 1
				if projection.offline_sales_credit<1.0: continue
				var price_value := price(bar,drink,true)
				var operating := floori(projection.offline_cost_pending)
				var consignment_cost := C.CONSIGNMENT_COST if drink==0 and projection.consignment>0 else 0
				var pool := floori(projection.offline_pool_pending)
				var old_carry := int(projection.commission_carry)
				var commission := commission_charge(projection,price_value) if promoter_bonus(bar,int(window.offset))>0 else 0
				if bank+price_value+pool<operating+commission+consignment_cost:
					projection.commission_carry = old_carry
					# Discard this unviable candidate, not a real cash debt.
					projection.offline_sales_credit = 0.0
					projection.offline_cost_pending = 0.0
					projection.offline_pool_pending = 0.0
					limit = "unviable trading windows"
					break
				var consumed := consume_stock(projection,drink)
				var management := bonus_amount(projection,maxi(0,price_value-(consignment_cost if consignment_cost>0 else consumed))+pool)
				management_total += management
				projection.offline_sales_credit -= 1.0
				projection.offline_cost_pending -= operating
				if consignment_cost>0: projection.consignment -= 1
				projection.offline_pool_pending -= pool
				bank += price_value+pool+management-operating-commission-consignment_cost
				venue_gross += price_value+pool+management
				venue_cost += operating+commission+consignment_cost
				commission_total += commission
				sales += 1
				estimated_visits += 1.0/maxf(1.0,view.rounds)
		# Pending sub-sale time/costs are estimate credits, not live debts.
		# Persist both sides so repeated short claims cannot avoid costs.
		for key in ["stock","stock_lots","consignment","commission_carry","offline_sales_credit","offline_cost_pending","offline_pool_pending","manager_bonus_carry"]:
			bar[key] = projection[key]
		bar.commission_paid += commission_total
		Finance.change(s,bank,"Offline trade estimate (after stock, premises and wages)",str(bar.name))
		net += bank
		gross += venue_gross
		expenses += venue_cost
		visits += floori(estimated_visits)
		notes.append("%s: estimated ฿%d net, %d drinks / %.1f legal trading minutes; %d deliveries of %d, ฿%d commission, ฿%d manager income; limited by %s." % [bar.name,bank,sales,traded/60.0,packs,pack_quantity(bar),commission_total,management_total,limit])

	# A conservative net projection; it never debits opening cash or progresses
	# queues, promotions, events, local milestones or calendar time.
	for bar in s.street.bars:
		for person in bar.team:
			if contracted(person) and int(person.get("contract_left",C.STAFF_CONTRACT_MINUTES))<=gap:
				notes.append(str(bar.name)+": a staff contract expired; rehire in Service. Training retained.")
	advance_contracts(gap)
	s.weekly.revenue += gross
	s.weekly.costs += expenses
	s.street.earned += net
	s.street.offline = net
	s.street.offline_report = {"seconds":elapsed,"legal_seconds":legal_seconds,"net":net,"income":gross,"costs":expenses,"customers":visits,"notes":notes}
	return net

func actual_rate(bar: Dictionary) -> int:
	var net := 0
	var seconds := int(bar.shift.open_seconds)
	net += int(bar.shift.revenue)-int(bar.shift.stock_cost)-int(bar.shift.operating)-int(bar.shift.promo_cost)-int(bar.shift.get("fines",0))-int(bar.shift.get("commission",0))
	for report in bar.recent:
		net += int(report.net)
		seconds += int(report.open_seconds)
	return roundi(net*60.0/maxi(1,seconds))

func free_host(bar: Dictionary) -> int:
	var used := []
	for person in bar.team:
		if person.role==1 and person.host>=0: used.append(int(person.host))
	for id in C.HOSTS.size():
		if not id in used: return id
	return 0

# Pure projection: every real second represents one game minute.
static func legal_open_minutes(start: int, duration: int) -> int:
	var total := int(duration/C.DAY_MINUTES)*(C.DAY_MINUTES-C.OPEN_MINUTE+C.CLOSE_MINUTE)
	for offset in duration%C.DAY_MINUTES:
		var minute := (start+offset)%C.DAY_MINUTES
		if minute>=C.OPEN_MINUTE or minute<C.CLOSE_MINUTE: total += 1
	return total

# Split at clock and peak boundaries instead of simulating unseen customers.
# The eight-hour cap bounds this to a few hundred small projection segments.
static func offline_windows(start: int, duration: int) -> Array:
	var boundaries := [0,C.CLOSE_MINUTE,C.OPEN_MINUTE,C.DAY_MINUTES]
	for hours in C.PEAK_HOURS:
		boundaries.append(int(hours.start))
		boundaries.append(int(hours.end))
	boundaries.sort()
	var windows := []
	var minute := start
	var remaining := duration
	while remaining>0:
		var boundary := C.DAY_MINUTES
		for candidate in boundaries:
			if candidate>minute:
				boundary = candidate
				break
		var span := mini(remaining,boundary-minute)
		if minute>=C.OPEN_MINUTE or minute<C.CLOSE_MINUTE:
			windows.append({"minute":minute,"seconds":span,"offset":duration-remaining})
		remaining -= span
		minute = (minute+span)%C.DAY_MINUTES
	return windows

# Split every legal offline window at all staff expiries, including competitors.
func contract_windows(start: int, duration: int) -> Array:
	var expiries: Array[int] = []
	for bar in s.street.bars:
		for person in bar.team:
			expiries.append(int(person.get("contract_left",C.STAFF_CONTRACT_MINUTES)))
	expiries.sort()
	var windows := []
	for window in offline_windows(start,duration):
		var cursor := int(window.offset)
		var finish := cursor+int(window.seconds)
		for expiry in expiries+[finish]:
			if expiry<=cursor or expiry>finish: continue
			windows.append({"minute":(start+cursor)%C.DAY_MINUTES,"seconds":expiry-cursor,"offset":cursor})
			cursor = expiry
	return windows

# Sponsored rounds are real orders, paid from the guest's entertainment budget.
# They share stock and service with the rest of the bar, never create a visitor.
func hosted_round(bar: Dictionary, index: int) -> Dictionary:
	for round in bar.get("host_rounds",[]):
		if int(round.host)==index: return round
	return {}

func hosted_guest_busy(bar: Dictionary, guest: int) -> bool:
	for round in bar.get("host_rounds",[]):
		if int(round.guest)==guest: return true
	return false

func hosted_guest(bar: Dictionary, id: int) -> Dictionary:
	for guest in bar.customers:
		if int(guest.id)==id: return guest
	return {}

static func hosted_price(person: Dictionary) -> int:
	return C.HOST_DRINK_PRICES[int(person.get("host_training",0))]

func hosted_offer(bar: Dictionary, index: int) -> Dictionary:
	var person: Dictionary = bar.team[index] if index>=0 and index<bar.team.size() else {}
	var round := hosted_round(bar,index)
	var candidate: Dictionary = {}
	var matched := false
	var price := int(round.quote) if not round.is_empty() else hosted_price(person)
	if not round.is_empty(): matched = bool(round.matched)
	var reason := ""
	if bar.type!=1 or person.get("role",-1)!=1: reason = "Choose an adult host."
	elif not contracted(person): reason = "Contract finished"
	elif not person.on: reason = "Off duty"
	elif index in bar.away: reason = "Away on a booking"
	elif not is_trading(bar): reason = "Venue closed"
	elif not round.is_empty(): reason = "%s · %ds" % ["Pour the host's drink" if round.state=="waiting" else "Good company",ceili(maxf(0,float(round.host_deadline)-action_time()))]
	else:
		for guest in bar.customers:
			if guest.get("host_interest",-1)<0 or guest.get("hosted",false) or guest.drinks<1 or guest.missed or hosted_guest_busy(bar,int(guest.id)): continue
			if guest.get("visit_phase","") in ["legacy","finished"]: continue
			var match_topic: bool = int(guest.host_interest)==int(C.HOST_TOPICS[int(person.host)])
			var quote := hosted_price(person)+(C.HOST_DRINK_MATCH_BONUS if match_topic else 0)
			if guest.fine_budget<quote: continue
			if candidate.is_empty() or (match_topic and not matched):
				candidate = guest
				matched = match_topic
				price = quote
		if candidate.is_empty(): reason = "No hosted-drink request"
	return {"enabled":reason.is_empty(),"reason":reason,"price":price,"guest":int(candidate.get("id",-1)),"matched":matched,"topic":int(candidate.get("host_interest",-1)),"busy":not round.is_empty()}

func invite_hosted(bar: Dictionary, index: int) -> String:
	var offer := hosted_offer(bar,index)
	if not offer.enabled: return offer.reason
	var guest := hosted_guest(bar,int(offer.guest))
	guest.hosted = true
	bar.host_rounds.append({"host":index,"guest":int(guest.id),"quote":int(offer.price),"matched":bool(offer.matched),"state":"waiting","host_deadline":action_time()+C.HOST_DRINK_WAIT})
	bar.orders += 1
	bar.shift.orders += 1
	s.street.orders += 1
	bar.recent_orders.append(int(s.street.elapsed))
	return "%s joins guest %d. Pour her drink to earn ฿%d%s." % [C.HOSTS[int(bar.team[index].host)][0],guest.id,offer.price," · perfect topic match" if offer.matched else ""]

func serve_hosted(bar: Dictionary, manual: bool = false) -> int:
	if not is_trading(bar): return 0
	for round in bar.get("host_rounds",[]):
		if round.state!="waiting" or float(round.host_deadline)<=action_time(): continue
		var person: Dictionary = bar.team[int(round.host)]
		var guest := hosted_guest(bar,int(round.guest))
		if guest.is_empty() or guest.fine_budget<int(round.quote) or not contracted(person) or not person.on or int(round.host) in bar.away: continue
		if not can_supply(bar,0): continue
		if stock_of(bar,0)<pack_quantity(bar) and auto_drink(bar,0): restock(bar,true,0)
		if stock_of(bar,0)<=0: continue
		var quote := int(round.quote)
		income(bar,quote)
		guest.fine_budget -= quote
		var consignment_cost := C.CONSIGNMENT_COST if int(bar.get("consignment",0))>0 else 0
		if consignment_cost>0:
			cost(bar,C.CONSIGNMENT_COST,"stock_cost")
			bar.consignment -= 1
		var consumed := consume_stock(bar,0)
		bar.shift.consumed_stock += consumed
		management_bonus(bar,quote-(consignment_cost if consignment_cost>0 else consumed))
		bar.shift.hosted_drinks += 1
		bar.shift.hosted_income += quote
		if round.matched: bar.shift.hosted_matches += 1
		bar.sold += 1
		bar.shift.sales += 1
		s.street.served += 1
		bar.recent_sales.append(int(s.street.elapsed))
		bar.dirt = mini(C.DIRT_LIMIT,int(bar.dirt)+(C.PEAK_DIRT_PER_DRINK if peak(int(bar.type),int(s.street.minute)) else 1))
		party_add(bar,"sales")
		party_add(bar,"drink_income",quote)
		party_add(bar,"drink_cost",consumed)
		round.state = "drinking"
		round.host_deadline = action_time()+C.HOST_DRINK_SECONDS
		bar.host_last_line = "%s · ฿%d%s" % [C.HOSTS[int(person.host)][0],quote," · topic matched!" if round.matched else " · cheers!"]
		if manual: last_sale = "%s · ฿%d margin" % [bar.host_last_line,quote-consumed]
		return 1
	return 0

func hosted_tick(bar: Dictionary) -> void:
	for round in bar.get("host_rounds",[]).duplicate():
		var guest := hosted_guest(bar,int(round.guest))
		var person: Dictionary = bar.team[int(round.host)]
		var valid: bool = not guest.is_empty() and is_trading(bar) and contracted(person) and person.on and not int(round.host) in bar.away
		if not valid:
			bar.host_rounds.erase(round)
			continue
		if float(round.host_deadline)>action_time(): continue
		if round.state=="drinking":
			bar.host_cheers += 1
			bar.host_last_line = C.HOST_ROUND_LINES[int(C.HOST_TOPICS[int(person.host)])]
			if bar.host_cheers>=3:
				bar.host_cheers = 0
				bar.host_buzz_until = action_time()+C.HOST_BUZZ_SECONDS
				bar.host_last_line = "Room Buzz! The next table wants in. +2 appeal for 30s."
		else:
			bar.host_last_line = "The toast waited too long. Serve the next round before it goes flat."
			var lost := "lost_stock" if not can_supply(bar,0) else "lost_service"
			bar[lost] += 1
			bar.shift[lost] += 1
		bar.host_rounds.erase(round)

func auto_hosted_offer(bar: Dictionary) -> Dictionary:
	var required: int = C.AUTO_HOST_DRINK_COST
	var reason := ""
	if bar.type!=1: reason = "Hosted rounds belong to hostess bars."
	elif bar.get("auto_host_drinks",false): reason = "Already installed."
	elif on_duty(bar,1)==0: reason = "Put a contracted host on duty first."
	elif s.cash<required: reason = "Not enough money for this purchase."
	return {"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"price":C.AUTO_HOST_DRINK_COST,"required":required}

func auto_hosted(bar: Dictionary) -> void:
	if not bar.get("auto_host_drinks",false) or not bar.get("auto_host_drinks_on",true) or not is_trading(bar): return
	# Prefer matches; give hosted-drinks-only colleagues first choice in a tie.
	for matched_only in [true,false]:
		for drinks_only in [true,false]:
			for i in bar.team.size():
				var person: Dictionary = bar.team[i]
				if person.role!=1 or bool(C.HOSTS[int(person.host)][2])==drinks_only: continue
				var offer := hosted_offer(bar,i)
				if offer.enabled and (not matched_only or offer.matched): invite_hosted(bar,i)

func hosted_buzz_text(bar: Dictionary) -> String:
	var left := maxf(0,float(bar.get("host_buzz_until",0))-action_time())
	return "ROOM BUZZ · +2 appeal · %ds" % ceili(left) if left>0 and is_trading(bar) else "Room Buzz · %d/3 rounds finished" % int(bar.get("host_cheers",0))
