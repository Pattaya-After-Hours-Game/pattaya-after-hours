extends RefCounted

const C = preload("res://scripts/street_content.gd")
var s: Dictionary

func _init(state: Dictionary, fresh: bool = false) -> void:
	s = state
	var st: Dictionary = s.street
	if not st.has("economy_seed"): st.economy_seed = 1
	if not st.has("next_group"): st.next_group = 1
	for entry in {"elapsed":0,"next_customer":1,"pass_credit":0,"offered":0,"arrivals":0,"orders":0,"guided":{},"offline_report":{}}:
		if not st.has(entry): st[entry] = {"elapsed":0,"next_customer":1,"pass_credit":0,"offered":0,"arrivals":0,"orders":0,"guided":{},"offline_report":{}}[entry]
	for bar in st.bars:
		var migrated: bool = not bar.has("customers")
		var defaults := new_fields()
		for key in defaults:
			if not bar.has(key): bar[key] = defaults[key]
		for key in ["serve_ready","welcome_ready","welcome_until"]: bar[key] = float(bar[key])
		for customer in bar.customers: customer.merge(customer_action_fields())
		bar.shift.merge({"fines":0,"commission":0})
		if not bar.last_shift.is_empty(): bar.last_shift.merge({"fines":0,"commission":0})
		for report in bar.recent: report.merge({"fines":0,"commission":0})
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
			if person.contract_left<=0: person.on = false
	if fresh:
		s.cash = C.STARTING_CASH
		st.bars[0].stock = 18
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

func close_customers(bar: Dictionary) -> void:
	bar.customers.clear()
	bar.games.clear()
	bar.host_requests.clear()
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

static func customer_action_fields() -> Dictionary:
	return {"chatted":false,"chat_until":0.0,"commission_visit":false,"commission_order":false}

static func new_fields() -> Dictionary:
	var fields := {"customers":[],"team":[],"equipment":{"sign":0,"comfort":0,"fridge":0,"pool":0,"seating":0,"screen":0,"training":0,"menu":0},
		"open":true,"close_reason":"","recovery":0,"consignment":0,"games":[],"promo":{},"promo_report":{},"promo_id":0,"promo_cooldown":0,"last_promo":-1,"promo_repeats":0,"ordinary_seconds":0,
		"welcome":0,"welcome_until":0.0,"welcome_ready":0.0,"serve_ready":0.0,"service_clock":0,"cost_credit":0,
		"regulars":0,"happy":0,"healthy":0,"shift":ledger(),"last_shift":{},"recent":[],"recent_sales":[],"recent_orders":[],
		"pool_games":0,"pool_income":0,"free_games":0,"arrivals":0,"orders":0,"sold":0,"lost_full":0,"lost_service":0,"lost_stock":0,"host_requests":[]}
	fields.merge(promoter_fields())
	fields.merge(clock_fields())
	fields.merge(action_fields())
	return fields

static func promoter_fields() -> Dictionary:
	return {"commission_carry":0,"commission_paid":0,"offline_sales_credit":0.0,"offline_cost_pending":0.0,"offline_pool_pending":0.0}

static func contract_cost(role: int) -> int:
	return C.PROMOTER_CONTRACT_COST if role==3 else C.STAFF_CONTRACT_COST

static func equipment_limit(bar: Dictionary, id: String, default_limit: int) -> int:
	return 2 if id=="seating" and bar.type!=0 else default_limit

func promoter_index(bar: Dictionary) -> int:
	for i in bar.team.size():
		if bar.team[i].role==3: return i
	return -1

func floor_staff(bar: Dictionary) -> int:
	return bar.team.size()-(1 if promoter_index(bar)>=0 else 0)

func promoter_bonus(bar: Dictionary, offset: int = 0) -> float:
	var index := promoter_index(bar)
	if index<0 or not contracted(bar.team[index],offset) or not bar.team[index].on: return 0.0
	return C.PROMOTER_BONUS[int(bar.team[index].get("audience_training",0))]

static func commission_charge(bar: Dictionary, amount: int) -> int:
	var credit := int(bar.commission_carry)+amount*C.COMMISSION_PERCENT
	bar.commission_carry = credit%100
	return credit/100

func commit_orders(bar: Dictionary) -> void:
	if promoter_bonus(bar)<=0: return
	for guest in bar.customers:
		if guest.order: guest.commission_order = true

func stock_offer(bar: Dictionary, automatic: bool = false) -> Dictionary:
	var amount := C.STOCK_PACK*C.STOCK_COST
	var room := stock_capacity(bar)-int(bar.stock)
	var reserve := ceili(operating_rate(bar)/60.0) if automatic else 0
	var reason := ""
	if room<C.STOCK_PACK: reason = "Need 6 free spaces; you have %d." % room
	elif s.cash<amount+reserve: reason = "Need ฿%d%s; you have ฿%d." % [amount+reserve," including next operating charge" if automatic else "",s.cash]
	return {"enabled":reason.is_empty(),"reason":reason,"price":amount,"room":room,"remaining_cash":int(s.cash)-amount}

static func ledger() -> Dictionary:
	return {"revenue":0,"stock_cost":0,"operating":0,"promo_cost":0,"fines":0,"commission":0,"arrivals":0,"orders":0,"sales":0,"happy":0,"lost_full":0,"lost_service":0,"lost_stock":0,"open_seconds":0,"occupied_seconds":0,"pool_income":0,"free_games":0}

func roll(limit: int) -> int:
	s.street.economy_seed = (int(s.street.economy_seed)*48271) % 2147483647
	return int(s.street.economy_seed) % maxi(1,limit)

func seats(bar: Dictionary) -> int:
	var furniture := int(bar.equipment.pool)*2+int(bar.equipment.comfort)
	var recovered := mini(3,furniture) if bar.type==0 and bar.equipment.seating==3 else 0
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
				bar.away.erase(i)
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

func staff_service(bar: Dictionary) -> void:
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if not contracted(person) or not person.on or person.role!=0 or i in bar.away or pending(bar)==0 or bar.stock==0:
			person.service_clock = 0
			continue
		person.service_clock = int(person.get("service_clock",0))+1
		if person.service_clock>=service_seconds(person):
			serve(bar,1)
			person.service_clock = 0

func operating_rate(bar: Dictionary, offset: int = 0) -> int:
	if bar.get("recovery",0)>0: return 0
	var amount := int(C.OVERHEAD[int(bar.type)]) + int(bar.equipment.comfort)*4 + (12 if bar.manager else 0)
	for person in bar.team:
		if contracted(person,offset) and person.on: amount += C.ROLE_WAGES[int(person.role)]
	return amount

func price(bar: Dictionary, premium: bool = false) -> int:
	var amount := int(C.TYPES[int(bar.type)].drink) + (30 if premium and bar.equipment.menu else 0)
	if bar.promo.get("kind",-1) == 1: amount = int(amount*.8)
	return amount

func event_id() -> int:
	return int(s.street.event.get("id",-1)) if s.street.event.get("phase","") == "active" else -1

func traffic_rate(offline: bool = false) -> float:
	var kinds := {}
	for bar in s.street.bars:
		if is_trading(bar,offline): kinds[int(bar.type)] = true
	var rate := C.TRAFFIC_PER_MINUTE + maxi(0,kinds.size()-1)*C.AUDIENCE_TRAFFIC_BONUS
	if offline: return rate
	match event_id():
		1: rate *= 2.4
		3: rate *= .5
		4: rate *= 1.7
		5,9: rate *= 2.0
		6: rate *= .7
	if s.weather >= 5: rate *= .8
	return rate

func attraction(bar: Dictionary, offline: bool = false, audience: int = -1, minute: int = -1, offset: int = 0) -> float:
	if not is_trading(bar,offline): return 0.0
	var value := 4.0 + (int(bar.stage)-1)*1.0 + int(bar.equipment.sign)*2 + int(bar.equipment.pool)*1.5
	value += minf(3.0,int(bar.regulars)/15.0) + minf(1.5,int(s.rep)/80.0)
	if not offline: value += s.bookings.size()*.5
	value += on_duty(bar,1,offset)*.6
	for i in bar.team.size():
		var person: Dictionary = bar.team[i]
		if person.role==2 and person.on and contracted(person,offset) and not i in bar.away:
			var performance := (.6 if offline else 1.8 if int(s.street.seconds) in range(40,80) else 0.0) if bar.type==2 else 0.0
			value += (.9+performance)*C.DANCER_TRAINING[int(person.get("audience_training",0))]
	value += maxf(0.0 if offline else int(bar.welcome)*.4,promoter_bonus(bar,offset))
	if not offline:
		if not bar.promo.is_empty(): value += float(C.PROMOTIONS[int(bar.promo.kind)].boost)/int(bar.promo.repetition)
		if event_id() == 6: value *= .95 if bar.type == 0 else .55
		if event_id() == 7: value *= 1.2 if s.street.event.prepared else .65
		if event_id() == 4 and bar.type == 0: value *= 1.3
	if audience>=0: value *= [[1.5,1.0,.5],[.6,1.0,1.6],[.3,1.3,1.5]][int(bar.type)][audience]
	if peak(int(bar.type),int(s.street.minute) if minute<0 else minute): value *= C.PEAK_ATTRACTION
	return value * (1.0 - float(bar.dirt)/C.DIRT_LIMIT*C.DIRT_ATTRACTION_PENALTY)

func audience_weights(offline: bool = false) -> Array:
	if not offline and event_id()==1: return [15,70,15]
	if not offline and event_id()==6: return [70,20,10]
	return [40,35,25]

func forecast(bar: Dictionary, offline: bool = false, promotion: int = -1, minute: int = -1, offset: int = 0, owner_active: bool = false, replacement: Dictionary = {}) -> Dictionary:
	var original := bar
	var promotion_cost := 0.0
	if promotion>=0 and promotion<C.PROMOTIONS.size():
		bar = bar.duplicate(true)
		var repetition := int(bar.promo_repeats)+1 if bar.last_promo==promotion and bar.ordinary_seconds<240 else 1
		bar.promo = {"kind":promotion,"repetition":repetition}
		promotion_cost = float(C.PROMOTIONS[promotion].fee)*60.0/C.PROMOTION_SECONDS
	var arrivals := 0.0
	var mix := audience_weights(offline)
	for audience in 3:
		var total := 5.0
		for other in s.street.bars: total += attraction(bar if other==original else replacement.get("bar") if not replacement.is_empty() and other==replacement.original else other,offline,audience,minute,offset)
		arrivals += traffic_rate(offline)*float(mix[audience])/100.0*attraction(bar,offline,audience,minute,offset)/total
	var space_limit := seats(bar)/1.5 # Typical 90-second stay.
	var demand := minf(arrivals,space_limit)*2.0
	var service := service_rate(bar,offset)+(60.0/action_cooldown(bar,"serve") if owner_active and not offline else 0.0)
	var sales := minf(demand,service)
	if bar.stock == 0 and not bar.restock: sales = 0
	var unit_margin := float(int(C.TYPES[int(bar.type)].drink)-C.STOCK_COST)
	var pool := minf(60.0/C.POOL_SECONDS*int(bar.equipment.pool),minf(arrivals,space_limit)*.2)*C.POOL_FEE
	if not offline and bar.promo.get("kind",-1) == 0: pool = 0
	if not offline and bar.promo.get("kind",-1) == 1: unit_margin = price(bar)-C.STOCK_COST
	var costs := operating_rate(bar,offset)+promotion_cost if is_trading(bar,offline) else 0.0
	var commission := sales*(int(C.TYPES[int(bar.type)].drink) if offline else price(bar))*C.COMMISSION_PERCENT/100.0 if promoter_bonus(bar,offset)>0 else 0.0
	if promoter_bonus(bar,offset)>0: unit_margin -= (int(C.TYPES[int(bar.type)].drink) if offline else price(bar))*C.COMMISSION_PERCENT/100.0
	var net := sales*unit_margin+pool-costs
	var reason := "Quiet: attract customers before hiring."
	if not is_trading(bar,offline): reason = status(bar)
	elif bar.stock <= 0: reason = "Out of stock: order a delivery."
	elif bar.customers.size() >= seats(bar): reason = "Full: more seats or shorter queues would help."
	elif pending(bar) > 0 and service < demand: reason = "Slow service: serve orders or add a bartender."
	return {"arrivals":arrivals,"demand":demand,"service":service,"sales":sales,"costs":costs,"net":net,"break_even":maxf(0,(costs-pool)/maxf(1,unit_margin)),"pool":pool,"commission":commission,"reason":reason}

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
	return count

func cost(bar: Dictionary, amount: int, category: String) -> bool:
	if s.cash < amount: return false
	s.cash -= amount
	s.weekly.costs += amount
	bar.shift[category] += amount
	return true

func income(bar: Dictionary, amount: int) -> void:
	s.cash += amount
	s.weekly.revenue += amount
	s.street.earned += amount
	bar.shift.revenue += amount

func restock(bar: Dictionary, automatic: bool = false) -> bool:
	if not stock_offer(bar,automatic).enabled: return false
	if not cost(bar,C.STOCK_PACK*C.STOCK_COST,"stock_cost"): return false
	bar.stock += C.STOCK_PACK
	return true


func order(bar: Dictionary, customer: Dictionary) -> void:
	if not is_trading(bar): return
	if customer.order or customer.drinks >= 2 or customer.missed: return
	var amount := price(bar,customer.premium)
	if customer.budget < amount: return
	customer.order = true
	customer.commission_order = customer.get("commission_visit",false) or promoter_bonus(bar)>0
	customer.quoted = amount
	customer.wait = 0
	bar.orders += 1
	bar.shift.orders += 1
	s.street.orders += 1
	bar.recent_orders.append(int(s.street.elapsed))

func admit(bar: Dictionary, promoted: bool = false, opening: bool = false, audience: int = 0) -> bool:
	if not is_trading(bar): return false
	if bar.customers.size() >= seats(bar):
		bar.lost_full += 1
		bar.shift.lost_full += 1
		if promoted and not bar.promo.is_empty(): bar.promo.lost += 1
		return false
	var customer := {"id":int(s.street.next_customer),"life":C.VISIT_SECONDS+(20 if bar.equipment.comfort else 0),"order":false,"wait":0,"quoted":0,"drinks":0,"next":0,
		"audience":audience,"fine_budget":600*int(bar.stage) if audience==2 else 0,"budget":int(C.TYPES[int(bar.type)].drink)*2+100,"premium":roll(100)<[15,50,35][audience],"pool":roll(100)<(85 if bar.promo.get("kind",-1) in [0,2] else 40),
		"pool_wait":0,"played":false,"playing":false,"missed":false,"opening":opening,"promo":int(bar.promo.get("id",0)) if promoted else 0}
	customer.merge(customer_action_fields())
	customer.commission_visit = promoter_bonus(bar)>0
	s.street.next_customer += 1
	bar.customers.append(customer)
	bar.arrivals += 1
	bar.shift.arrivals += 1
	s.street.arrivals += 1
	s.total_guests += 1
	s.weekly.guests += 1
	if promoted: bar.promo.customers += 1
	order(bar,customer)
	return true

func serve(bar: Dictionary, count: int = 1, manual: bool = false) -> int:
	if not is_trading(bar): return 0
	if manual and not action_status(bar,"serve").enabled: return 0
	if manual: count = 1
	var sold := 0
	for customer in bar.customers:
		if sold >= count: break
		if not customer.order: continue
		if bar.stock < C.STOCK_PACK and bar.restock: restock(bar,true)
		if bar.stock == 0: break
		income(bar,int(customer.quoted))
		var commission := 0
		if promoter_bonus(bar)>0 or customer.get("commission_visit",false) or customer.get("commission_order",false):
			commission = commission_charge(bar,int(customer.quoted))
			cost(bar,commission,"commission")
			bar.commission_paid += commission
		customer.commission_order = false
		if bar.get("consignment",0)>0:
			cost(bar,C.STOCK_COST,"stock_cost")
			bar.consignment -= 1
		bar.stock -= 1
		customer.budget -= customer.quoted
		customer.order = false
		customer.drinks += 1
		customer.next = C.ORDER_SECONDS
		bar.dirt = mini(C.DIRT_LIMIT,int(bar.dirt)+(C.PEAK_DIRT_PER_DRINK if peak(int(bar.type),int(s.street.minute)) else 1))
		bar.sold += 1
		bar.shift.sales += 1
		s.street.served += 1
		bar.recent_sales.append(int(s.street.elapsed))
		var report := promotion_record(bar,int(customer.promo))
		if not report.is_empty():
			report.drink_revenue += int(customer.quoted)
			report.drink_cost += C.STOCK_COST
			report["commission"] = int(report.get("commission",0))+commission
		if bar.type == 1 and customer.drinks == 2 and on_duty(bar,1)>0 and customer.fine_budget>=300*int(bar.stage) and roll(100)<40:
			bar.host_requests.append(int(customer.id))
		sold += 1
	if manual and sold > 0: start_cooldown(bar,"serve",action_cooldown(bar,"serve"))
	return sold

# Deadlines use the saved foreground clock, never wall-clock or rendered frames.
func action_time() -> float:
	return float(s.street.elapsed)+float(s.street.get("tick_fraction",0.0))

func action_cooldown(bar: Dictionary, id: String) -> float:
	if id=="chat": return C.CHAT_SECONDS
	var key := "pouring" if id=="serve" else "welcoming"
	return float(C.ACTION_COOLDOWNS[int(bar.action_levels[key])])

func start_cooldown(bar: Dictionary, id: String, duration: float) -> void:
	bar[id+"_duration"] = duration
	bar[id+"_ready"] = action_time()+duration

static func patience(bar: Dictionary, customer: Dictionary) -> int:
	return (45 if customer.opening else C.PATIENCE_SECONDS)+(10 if bar.equipment.comfort else 0)+(C.CHAT_PATIENCE if customer.get("chatted",false) else 0)

static func order_seconds_left(bar: Dictionary, customer: Dictionary) -> int:
	return mini(patience(bar,customer)-int(customer.wait),int(customer.life))

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
	var reason := ""
	if not is_trading(bar): reason = status(bar)
	elif remaining>0.000001: reason = "%s ready in %.1fs." % ["Serve" if id=="serve" else "Welcome / Chat",remaining]
	elif id=="welcome" and promoter_bonus(bar)>0: reason = "Nida is welcoming customers."
	elif id=="serve" and pending(bar)==0: reason = "No orders waiting. Welcome customers or plan a promotion."
	elif id=="serve" and bar.stock==0 and not (bar.restock and stock_offer(bar,true).enabled): reason = "Restock the fridge."
	elif id=="chat" and chat_target(bar).is_empty(): reason = "Chat helps an unchatted guest with 10s or less left to wait."
	return {"enabled":reason.is_empty(),"reason":reason,"remaining":remaining,"duration":duration,"fill":clampf(1.0-remaining/duration,0.0,1.0)}

func action_upgrade_status(bar: Dictionary, index: int) -> Dictionary:
	var item: Dictionary = C.ACTION_UPGRADES[index]
	var level := int(bar.action_levels[item.id])
	var price := 0 if level==3 else int(C.ACTION_UPGRADE_COSTS[level])
	var shortfall := maxi(0,price+operating_rate(bar)*2-int(s.cash))
	return {"level":level,"price":price,"shortfall":shortfall,"enabled":level<3 and shortfall==0,
		"current":C.ACTION_COOLDOWNS[level],"next":C.ACTION_COOLDOWNS[mini(3,level+1)]}

func buy_action_upgrade(bar: Dictionary, index: int) -> String:
	if index<0 or index>=C.ACTION_UPGRADES.size(): return "Unknown action upgrade."
	var state := action_upgrade_status(bar,index)
	if state.level==3: return "Already at the fastest cooldown."
	if not state.enabled: return "Need ฿%d more, including next shift's operating reserve." % state.shortfall
	var item: Dictionary = C.ACTION_UPGRADES[index]
	s.cash -= state.price
	s.weekly.costs += state.price
	bar.action_levels[item.id] += 1
	return "%s: %ds → %ds on the next use." % [item.name,state.current,state.next]

func promotion_record(bar: Dictionary, id: int) -> Dictionary:
	if id == 0: return {}
	if bar.promo.get("id",-1) == id: return bar.promo
	if bar.promo_report.get("id",-1) == id: return bar.promo_report
	return {}

func depart(bar: Dictionary, customer: Dictionary) -> void:
	if customer.drinks >= 2 and not customer.missed:
		bar.happy += 1
		bar.shift.happy += 1
		if int(bar.happy)%10 == 0: s.rep = mini(100,int(s.rep)+1)
		if roll(100) < C.REGULAR_CHANCE:
			bar.regulars += 1
			s.regulars += 1
			var report := promotion_record(bar,int(customer.promo))
			if not report.is_empty(): report.regulars += 1
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
		bar.shift.pool_income += fee
		income(bar,fee)
		if fee == 0:
			bar.free_games += 1
			bar.shift.free_games += 1
		if not bar.promo.is_empty():
			bar.promo.pool_revenue += fee
			if fee == 0: bar.promo.free_games += 1

func start_promotion(bar: Dictionary, kind: int) -> String:
	if kind<0 or kind>=C.PROMOTIONS.size(): return "Unknown promotion."
	if not is_trading(bar): return status(bar)
	if not bar.promo.is_empty() or bar.promo_cooldown>0: return "Finish this promotion and its one-shift cooldown first."
	var item: Dictionary = C.PROMOTIONS[kind]
	if not str(item.requires).is_empty() and bar.equipment[item.requires] == 0: return "Buy the %s first." % item.requires
	if s.cash < int(item.fee)+operating_rate(bar)*2: return "Keep a shift's operating reserve after the promotion fee."
	cost(bar,int(item.fee),"promo_cost")
	bar.promo_repeats = int(bar.promo_repeats)+1 if bar.last_promo == kind and bar.ordinary_seconds < 240 else 1
	bar.last_promo = kind
	bar.ordinary_seconds = 0
	bar.promo_id += 1
	bar.promo = {"id":bar.promo_id,"kind":kind,"remaining":C.PROMOTION_SECONDS,"repetition":bar.promo_repeats,"customers":0,"drink_revenue":0,"drink_cost":0,
		"pool_revenue":0,"free_games":0,"regulars":0,"lost":0,"fee":int(item.fee),"operating":0,"operating_credit":0,"baseline":forecast(bar).arrivals*2.0}
	return "%s started. Compare the report after two minutes." % item.name

func buy_equipment(bar: Dictionary, index: int) -> String:
	if index<0 or index>=C.EQUIPMENT.size(): return "Unknown equipment."
	var item: Dictionary = C.EQUIPMENT[index]
	var id: String = item.id
	if id=="training": return "Choose an individual team member to train in Service."
	if bar.equipment[id]>=equipment_limit(bar,id,int(item.max)): return "Already fully equipped."
	if id=="pool" and bar.type!=0: return "Pool tables belong in beer bars."
	if id=="pool" and bar.equipment.pool>=bar.stage: return "Upgrade the venue before adding another table."
	if id=="menu" and bar.stage<2: return "Premium menus unlock at stage 2."
	var amount := int(item.cost)*(int(bar.equipment[id])+1)
	if s.cash<amount+operating_rate(bar)*2: return "Keep the next shift's operating reserve after this purchase."
	s.cash -= amount
	s.weekly.costs += amount
	bar.equipment[id] += 1
	return "%s installed. %s" % [item.name,item.help]

func upgrade_reason(bar: Dictionary) -> String:
	if bar.stage>=3: return "Final stage reached."
	var goal: Dictionary = C.STAGE_GOALS[int(bar.stage)-1]
	if bar.happy<goal.happy or bar.regulars<goal.regulars or bar.healthy<goal.healthy:
		return "Needs %d/%d happy visits, %d/%d regulars and %d/%d healthy shifts." % [bar.happy,goal.happy,bar.regulars,goal.regulars,bar.healthy,goal.healthy]
	if s.cash<int(C.RENOVATIONS[int(bar.type)][int(bar.stage)-1])+operating_rate(bar)*2: return "Save the renovation price plus one shift of operating costs."
	return ""

func action(bar: Dictionary, id: String, index: int) -> String:
	match id:
		"serve":
			var state := action_status(bar,id)
			if not state.enabled: return state.reason
			return "Order served. Stock and income recorded." if serve(bar,1,true)>0 else "Restock the fridge."
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
			start_cooldown(bar,"welcome",C.CHAT_SECONDS)
			return "A little reassurance: 10 extra seconds to fulfil that order."
		"action_upgrade": return buy_action_upgrade(bar,index)
		"stock":
			var offer := stock_offer(bar)
			if not offer.enabled: return offer.reason
			return "Six drinks delivered for ฿84." if restock(bar) else "Delivery unavailable."
		"equipment": return buy_equipment(bar,index)
		"promotion": return start_promotion(bar,index)
		"clean":
			if is_trading(bar): return "Close the venue before cleaning."
			if bar.dirt==0: return "Already clean."
			if bar.clean_remaining>0: return "Cleaning is already underway."
			bar.clean_remaining = C.CLEAN_SECONDS
			bar.clean_auto_started = true
			return "Cleaning started: 15 seconds. Skipping leaves unfinished work."
		"open":
			if bar.open:
				bar.open = false
				bar.close_reason = "Closed by owner"
				close_customers(bar)
				return "Closed. Staff and overhead charges pause."
			if s.cash < ceili(operating_rate(bar)/60.0): return "You need enough cash for the next operating charge."
			bar.open = true
			bar.close_reason = ""
			if is_trading(bar): bar.clean_remaining = 0
			return status(bar)
		"recovery":
			if bar.open: return "Close the venue before taking an owner-run recovery shift."
			if s.cash>=120: return "You have enough cash to reopen normally; recovery cover is for an empty till."
			if bar.closed>0 or bar.raided or not scheduled(bar,int(s.street.minute)): return "Wait until the venue is allowed to open."
			for member in bar.team: member.on = false
			bar.recovery = 120
			bar.open = true
			bar.close_reason = ""
			if bar.stock==0:
				bar.stock = 6
				bar.consignment = 6
			return "Anong covers two minutes of overhead. Staff are off duty; Bo's six recovery drinks cost ฿14 only when sold. Serve and welcome manually."
		"rota":
			if index<0 or index>=bar.team.size(): return "Unknown team member."
			if not contracted(bar.team[index]): return "Rehire this team member first."
			bar.team[index].service_clock = 0
			bar.team[index].on = not bar.team[index].on
			commit_orders(bar)
			return "Rota updated. Existing visits/orders retain commission commitments." if bar.team[index].role==3 else "Rota updated. Off-duty staff do not incur wages."
		"role":
			if bar.type==0 or index<0 or index>=bar.team.size(): return "Choose a team member at a Soi bar or gogo."
			if index in bar.away: return "Wait until this team member returns."
			var person: Dictionary = bar.team[index]
			if not contracted(person): return "Rehire this team member first."
			if person.role==3: return "Promoters have their own frontage contract and cannot change role."
			person.service_clock = 0
			person.role = int(bar.type) if person.role==0 else 0
			person.host = free_host(bar) if person.role==1 else -1
			return "Role changed to %s. Payroll and service forecasts updated." % C.ROLE_NAMES[int(person.role)]
		"hire":
			if index<0 or index>3: return "Unknown role."
			if index==1 and bar.type!=1: return "Hosts work in Soi venues."
			if index==2 and bar.type!=2: return "Dancers work in gogos."
			if index==3 and promoter_index(bar)>=0: return "Rehire your existing promoter instead."
			if index!=3 and floor_staff(bar)>=int(bar.stage)*2: return "Upgrade for more team positions."
			var amount := contract_cost(index)
			if s.cash<amount+(operating_rate(bar)+int(C.ROLE_WAGES[index]))*2+(84 if index==3 else 0): return "Keep a shift's payroll after hiring."
			s.cash -= amount
			s.weekly.costs += amount
			var host := free_host(bar) if index==1 else -1
			bar.team.append({"role":index,"on":true,"host":host,"training":0,"audience_training":0,"service_clock":0,"contract_left":C.STAFF_CONTRACT_MINUTES})
			bar.crew = bar.team.size()
			commit_orders(bar)
			return "Nida hired: ten days, ฿1,200 plus 10% drink commission. She welcomes; you serve." if index==3 else "%s hired for ten game days (฿4,500). Wages: ฿%d/real min while trading on duty." % [C.ROLE_NAMES[index],C.ROLE_WAGES[index]]
		"rehire":
			if index<0 or index>=bar.team.size(): return "Unknown team member."
			var person: Dictionary = bar.team[index]
			if contracted(person): return "This contract is still active."
			var amount := contract_cost(int(person.role))
			if s.cash<amount+(operating_rate(bar)+int(C.ROLE_WAGES[int(person.role)]))*2+(84 if person.role==3 else 0): return "Keep a shift's payroll and the required stock reserve after rehiring."
			s.cash -= amount
			s.weekly.costs += amount
			person.contract_left = C.STAFF_CONTRACT_MINUTES
			person.on = true
			person.service_clock = 0
			commit_orders(bar)
			return "Rehired for ten game days. Their training is unchanged."
		"train_audience":
			if index<0 or index>=bar.team.size(): return "Choose a promoter or dancer."
			var person: Dictionary = bar.team[index]
			if not int(person.role) in [2,3]: return "Audience training is for promoters and dancers."
			if not contracted(person): return "Rehire before training."
			var level := int(person.get("audience_training",0))
			if level>=2: return "Already fully trained."
			if bar.stage<level+2: return "Needs venue stage %d." % (level+2)
			var amount := C.AUDIENCE_TRAINING_COST*(level+1)
			if s.cash<amount+operating_rate(bar)*2: return "Keep the next shift's operating reserve."
			s.cash -= amount
			s.weekly.costs += amount
			person.audience_training = level+1
			return "Audience training improved. Skills stay with the person after rehiring."
		"train_staff":
			if index<0 or index>=bar.team.size(): return "Choose a team member."
			var person: Dictionary = bar.team[index]
			if not contracted(person): return "Rehire this team member before training."
			if person.role!=0: return "Service training is for bartenders. Reassign their role first."
			var level := int(person.get("training",0))
			if level>=C.STAFF_SERVICE_SECONDS.size()-1: return "Already fully trained."
			var amount := C.STAFF_TRAINING_COST*(level+1)
			if s.cash<amount+operating_rate(bar)*2: return "Keep a shift's operating reserve after training."
			s.cash -= amount
			s.weekly.costs += amount
			person.training = level+1
			return "Training retained for future contracts. Now serves one drink every %ds." % service_seconds(person)
		"bar_fine":
			if index<0 or index>=bar.team.size() or bar.team[index].role!=1: return "Choose an adult host."
			if not is_trading(bar) or not contracted(bar.team[index]) or not bar.team[index].on or index in bar.away: return "This host is unavailable."
			if not C.HOSTS[int(bar.team[index].host)][2]: return "The host declines; hosted drinks are their preference."
			if bar.host_requests.is_empty(): return "No customer has requested a bar fine."
			if bar.away.size()>=bar.stage: return "Upstairs bookings are full this shift."
			var request := int(bar.host_requests.pop_front())
			var requester: Dictionary = {}
			for customer in bar.customers:
				if customer.id==request: requester = customer
			if requester.is_empty() or requester.fine_budget<300*int(bar.stage): return "The customer has left or cannot cover the request."
			requester.fine_budget -= 300*int(bar.stage)
			bar.away.append(index)
			income(bar,200*int(bar.stage))
			return "Accepted. The host is unavailable until the next shift; private activity stays off-screen."
	return ""

func settle_shift(bar: Dictionary) -> void:
	var report: Dictionary = bar.shift.duplicate(true)
	report.net = int(report.revenue)-int(report.stock_cost)-int(report.operating)-int(report.promo_cost)-int(report.get("fines",0))-int(report.get("commission",0))
	report.reason = "Healthy service. Compare demand with capacity before expanding."
	if report.lost_stock>0: report.reason = "Out of stock: more reliable deliveries would recover sales."
	elif report.lost_service>0: report.reason = "Slow service: waiting orders need help or trained bartenders."
	elif report.lost_full>0: report.reason = "Full: improve layout or seating before advertising harder."
	elif report.occupied_seconds<report.open_seconds*seats(bar)*.4: report.reason = "Quiet: try signage, welcoming or a targeted promotion."
	# Inventory purchases are investments in later sales: assess operating margin.
	if report.sales>=4 and report.sales>=report.orders*.8 and int(report.revenue)-int(report.sales)*C.STOCK_COST-int(report.operating)-int(report.promo_cost)-int(report.get("fines",0))-int(report.get("commission",0))>0:
		bar.healthy += 1
	bar.last_shift = report
	bar.recent.append(report)
	if bar.recent.size()>5: bar.recent.pop_front()
	bar.shift = ledger()

func tick() -> void:
	s.street.elapsed += 1
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
				for _guest in group: admit(bar,promoted,false,audience)
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
		var charge := int(bar.cost_credit)/60
		if not cost(bar,charge,"operating"):
			bar.open = false
			bar.close_reason = "Operating cash ran out"
			close_customers(bar)
			continue
		bar.cost_credit = int(bar.cost_credit)%60
		bar.shift.open_seconds += 1
		bar.shift.occupied_seconds += bar.customers.size()
		for customer in bar.customers.duplicate():
			customer.life -= 1
			if customer.order:
				customer.wait += 1
				if customer.wait > patience(bar,customer):
					customer.order = false
					customer.missed = true
					var reason := "lost_stock" if bar.stock==0 else "lost_service"
					bar[reason] += 1
					bar.shift[reason] += 1
					var report := promotion_record(bar,int(customer.promo))
					if not report.is_empty(): report.lost += 1
					customer.life = mini(int(customer.life),5)
			else:
				customer.next -= 1
				if customer.next<=0: order(bar,customer)
			if customer.pool and not customer.playing and not customer.played and bar.equipment.pool>0:
				customer.pool_wait += 1
				if customer.pool_wait>=C.POOL_PATIENCE:
					customer.pool = false
					var pool_report := promotion_record(bar,int(customer.promo))
					if not pool_report.is_empty(): pool_report.lost += 1
			if customer.life<=0 and not customer.playing: depart(bar,customer)
		if bar.restock and bar.stock<C.STOCK_PACK and pending(bar)>0: restock(bar,true)
		staff_service(bar)
		pool_tick(bar)

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
		var commission_total := 0
		var packs := 0
		var traded := 0
		var limit := "customer demand / space"
		var projection: Dictionary = bar.duplicate(true)
		for window in windows:
			var view := forecast(bar,true,-1,int(window.minute),int(window.offset))
			if view.net<=0 or view.sales<=0:
				limit = "unviable trading windows"
				continue
			if view.service<view.demand: limit = "service"
			for _second in int(window.seconds):
				# Each claim protects the cash present when it starts. Only its
				# newly generated surplus funds complete supplier packs.
				if projection.stock==0:
					if not bar.restock or bank<C.STOCK_PACK*C.STOCK_COST:
						limit = "stock / six-pack working capital"
						break
					bank -= C.STOCK_PACK*C.STOCK_COST
					venue_cost += C.STOCK_PACK*C.STOCK_COST
					projection.stock += C.STOCK_PACK
					packs += 1
				projection.offline_sales_credit += view.sales/60.0
				projection.offline_cost_pending += view.costs/60.0
				projection.offline_pool_pending += view.pool/60.0
				traded += 1
				if projection.offline_sales_credit<1.0: continue
				var price_value := int(C.TYPES[int(bar.type)].drink)
				var operating := floori(projection.offline_cost_pending)
				var consignment_cost := C.STOCK_COST if projection.consignment>0 else 0
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
				projection.stock -= 1
				projection.offline_sales_credit -= 1.0
				projection.offline_cost_pending -= operating
				if consignment_cost>0: projection.consignment -= 1
				projection.offline_pool_pending -= pool
				bank += price_value+pool-operating-commission-consignment_cost
				venue_gross += price_value+pool
				venue_cost += operating+commission+consignment_cost
				commission_total += commission
				sales += 1
		# Pending sub-sale time/costs are estimate credits, not live debts.
		# Persist both sides so repeated short claims cannot avoid costs.
		for key in ["stock","consignment","commission_carry","offline_sales_credit","offline_cost_pending","offline_pool_pending"]:
			bar[key] = projection[key]
		bar.commission_paid += commission_total
		net += bank
		gross += venue_gross
		expenses += venue_cost
		visits += sales/2
		notes.append("%s: estimated ฿%d net, %d drinks / %.1f legal trading minutes; %d six-packs, ฿%d commission; limited by %s." % [bar.name,bank,sales,traded/60.0,packs,commission_total,limit])

	# A conservative net projection; it never debits opening cash or progresses
	# queues, promotions, events, local milestones or calendar time.
	for bar in s.street.bars:
		for person in bar.team:
			if contracted(person) and int(person.get("contract_left",C.STAFF_CONTRACT_MINUTES))<=gap:
				notes.append(str(bar.name)+": a staff contract expired; rehire in Service. Training retained.")
	advance_contracts(gap)
	s.cash += net
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
