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
		if migrated:
			# Old crew served drinks: keep them as bartenders, never remove a hire.
			for _i in int(bar.crew): bar.team.append({"role":0,"on":true,"host":-1})
			if bar.type == 0 and bar.stage >= 2: bar.equipment.pool = 1
	if fresh:
		s.cash = C.STARTING_CASH
		st.bars[0].stock = 18
		# A small opening rush, not an endlessly replenished tutorial grant.
		for _i in 3: admit(st.bars[0],false,true)

static func new_fields() -> Dictionary:
	return {"customers":[],"team":[],"equipment":{"sign":0,"comfort":0,"fridge":0,"pool":0,"seating":0,"screen":0,"training":0,"menu":0},
		"open":true,"close_reason":"","recovery":0,"consignment":0,"games":[],"promo":{},"promo_report":{},"promo_id":0,"promo_cooldown":0,"last_promo":-1,"promo_repeats":0,"ordinary_seconds":0,
		"welcome":0,"welcome_until":0,"welcome_ready":0,"serve_ready":0,"service_clock":0,"cost_credit":0,
		"regulars":0,"happy":0,"healthy":0,"shift":ledger(),"last_shift":{},"recent":[],"recent_sales":[],"recent_orders":[],
		"pool_games":0,"pool_income":0,"free_games":0,"arrivals":0,"orders":0,"sold":0,"lost_full":0,"lost_service":0,"lost_stock":0,"host_requests":[]}

static func ledger() -> Dictionary:
	return {"revenue":0,"stock_cost":0,"operating":0,"promo_cost":0,"arrivals":0,"orders":0,"sales":0,"happy":0,"lost_full":0,"lost_service":0,"lost_stock":0,"open_seconds":0,"occupied_seconds":0,"pool_income":0,"free_games":0}

func roll(limit: int) -> int:
	s.street.economy_seed = (int(s.street.economy_seed)*48271) % 2147483647
	return int(s.street.economy_seed) % maxi(1,limit)

func seats(bar: Dictionary) -> int:
	return maxi(2,C.BASE_SEATS[int(bar.stage)-1] + int(bar.equipment.seating)*2 - int(bar.equipment.pool)*2 - int(bar.equipment.comfort))

func stock_capacity(bar: Dictionary) -> int:
	return 30 + int(bar.equipment.fridge)*40 + (int(bar.stage)-1)*20

func on_duty(bar: Dictionary, role: int) -> int:
	var total := 0
	for i in bar.team.size():
		if bar.team[i].on and bar.team[i].role == role and not i in bar.away: total += 1
	return total

func service_rate(bar: Dictionary) -> int:
	return on_duty(bar,0) * (C.BARTENDER_SERVICE + int(bar.equipment.training)*C.TRAINING_SERVICE)

func operating_rate(bar: Dictionary) -> int:
	if bar.get("recovery",0)>0: return 0
	var amount := int(C.OVERHEAD[int(bar.type)]) + int(bar.equipment.comfort)*4 + (12 if bar.manager else 0)
	for person in bar.team:
		if person.on: amount += C.ROLE_WAGES[int(person.role)]
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
		if bar.open: kinds[int(bar.type)] = true
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

func attraction(bar: Dictionary, offline: bool = false, audience: int = -1) -> float:
	if not bar.open or bar.closed > 0: return 0.0
	var value := 4.0 + (int(bar.stage)-1)*1.0 + int(bar.equipment.sign)*2 + int(bar.equipment.pool)*1.5
	value += minf(3.0,int(bar.regulars)/15.0) + minf(1.5,int(s.rep)/80.0)
	if not offline: value += s.bookings.size()*.5
	value += on_duty(bar,1)*.6 + on_duty(bar,2)*.9
	if bar.type==2: value += on_duty(bar,2)*(.6 if offline else 1.8 if int(s.street.seconds) in range(40,80) else 0.0)
	if not offline:
		value += int(bar.welcome)*.4
		if not bar.promo.is_empty(): value += float(C.PROMOTIONS[int(bar.promo.kind)].boost)/int(bar.promo.repetition)
		if event_id() == 6: value *= .95 if bar.type == 0 else .55
		if event_id() == 7: value *= 1.2 if s.street.event.prepared else .65
		if event_id() == 4 and bar.type == 0: value *= 1.3
	if audience>=0: value *= [[1.5,1.0,.5],[.6,1.0,1.6],[.3,1.3,1.5]][int(bar.type)][audience]
	return value

func audience_weights(offline: bool = false) -> Array:
	if not offline and event_id()==1: return [15,70,15]
	if not offline and event_id()==6: return [70,20,10]
	return [40,35,25]

func forecast(bar: Dictionary, offline: bool = false, promotion: int = -1) -> Dictionary:
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
		for other in s.street.bars: total += attraction(bar if other==original else other,offline,audience)
		arrivals += traffic_rate(offline)*float(mix[audience])/100.0*attraction(bar,offline,audience)/total
	var space_limit := seats(bar)/1.5 # Typical 90-second stay.
	var demand := minf(arrivals,space_limit)*2.0
	var service := float(service_rate(bar))
	var sales := minf(demand,service)
	if bar.stock == 0 and not bar.restock: sales = 0
	var unit_margin := int(C.TYPES[int(bar.type)].drink)-C.STOCK_COST
	var pool := minf(60.0/C.POOL_SECONDS*int(bar.equipment.pool),minf(arrivals,space_limit)*.2)*C.POOL_FEE
	if not offline and bar.promo.get("kind",-1) == 0: pool = 0
	if not offline and bar.promo.get("kind",-1) == 1: unit_margin = price(bar)-C.STOCK_COST
	var costs := operating_rate(bar)+promotion_cost
	var net := sales*unit_margin+pool-costs
	var reason := "Quiet: attract customers before hiring."
	if not bar.open or bar.closed > 0: reason = "Closed: reopen when the business can cover its costs."
	elif bar.stock <= 0: reason = "Out of stock: order a delivery."
	elif bar.customers.size() >= seats(bar): reason = "Full: more seats or shorter queues would help."
	elif pending(bar) > 0 and service < demand: reason = "Slow service: serve orders or add a bartender."
	return {"arrivals":arrivals,"demand":demand,"service":service,"sales":sales,"costs":costs,"net":net,"break_even":maxf(0,(costs-pool)/maxf(1,unit_margin)),"pool":pool,"reason":reason}

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

func restock(bar: Dictionary, full: bool = false) -> bool:
	var amount := stock_capacity(bar)-int(bar.stock)
	if not full: amount = mini(mini(amount,10),maxi(0,(int(s.cash)-ceili(operating_rate(bar)/60.0))/C.STOCK_COST))
	if amount <= 0: return false
	if not cost(bar,amount*C.STOCK_COST,"stock_cost"): return false
	bar.stock += amount
	return true

func order(bar: Dictionary, customer: Dictionary) -> void:
	if customer.order or customer.drinks >= 2 or customer.missed: return
	var amount := price(bar,customer.premium)
	if customer.budget < amount: return
	customer.order = true
	customer.quoted = amount
	customer.wait = 0
	bar.orders += 1
	bar.shift.orders += 1
	s.street.orders += 1
	bar.recent_orders.append(int(s.street.elapsed))

func admit(bar: Dictionary, promoted: bool = false, opening: bool = false, audience: int = 0) -> bool:
	if not bar.open or bar.closed > 0: return false
	if bar.customers.size() >= seats(bar):
		bar.lost_full += 1
		bar.shift.lost_full += 1
		if promoted and not bar.promo.is_empty(): bar.promo.lost += 1
		return false
	var customer := {"id":int(s.street.next_customer),"life":C.VISIT_SECONDS+(20 if bar.equipment.comfort else 0),"order":false,"wait":0,"quoted":0,"drinks":0,"next":0,
		"audience":audience,"fine_budget":600*int(bar.stage) if audience==2 else 0,"budget":int(C.TYPES[int(bar.type)].drink)*2+100,"premium":roll(100)<[15,50,35][audience],"pool":roll(100)<(85 if bar.promo.get("kind",-1) in [0,2] else 40),
		"pool_wait":0,"played":false,"playing":false,"missed":false,"opening":opening,"promo":int(bar.promo.get("id",0)) if promoted else 0}
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
	if not bar.open or bar.closed > 0: return 0
	if manual and s.street.elapsed < bar.serve_ready: return 0
	var sold := 0
	for customer in bar.customers:
		if sold >= count: break
		if not customer.order: continue
		if bar.stock == 0 and bar.restock: restock(bar)
		if bar.stock == 0: break
		income(bar,int(customer.quoted))
		if bar.get("consignment",0)>0:
			cost(bar,C.STOCK_COST,"stock_cost")
			bar.consignment -= 1
		bar.stock -= 1
		customer.budget -= customer.quoted
		customer.order = false
		customer.drinks += 1
		customer.next = C.ORDER_SECONDS
		bar.sold += 1
		bar.shift.sales += 1
		s.street.served += 1
		bar.recent_sales.append(int(s.street.elapsed))
		var report := promotion_record(bar,int(customer.promo))
		if not report.is_empty():
			report.drink_revenue += int(customer.quoted)
			report.drink_cost += C.STOCK_COST
		if bar.type == 1 and customer.drinks == 2 and on_duty(bar,1)>0 and customer.fine_budget>=300*int(bar.stage) and roll(100)<40:
			bar.host_requests.append(int(customer.id))
		sold += 1
	if manual and sold > 0: bar.serve_ready = int(s.street.elapsed)+1
	return sold

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
		bar.games.append({"players":ids,"remaining":C.POOL_SECONDS,"fee":fee})
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
	if not bar.open or bar.closed>0: return "Reopen the venue first."
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
	if bar.equipment[id]>=item.max: return "Already fully equipped."
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
			if not bar.open or bar.closed>0: return "Temporarily closed."
			if pending(bar)==0: return "No orders waiting. Welcome customers or plan a promotion."
			return "Order served. Stock and income recorded." if serve(bar,1,true)>0 else "Wait a moment, or restock the fridge."
		"welcome":
			if not bar.open or bar.closed>0: return "Reopen before welcoming guests."
			if s.street.elapsed<bar.welcome_ready: return "Give the next passersby a moment."
			bar.welcome = mini(3,int(bar.welcome)+1)
			bar.welcome_until = int(s.street.elapsed)+20
			bar.welcome_ready = int(s.street.elapsed)+10
			return "Welcoming passersby. The street still has a limited crowd."
		"stock":
			return "Stock delivered at ฿14 per drink." if (restock(bar,true) or restock(bar)) else "Fridge full, or insufficient cash for the delivery."
		"equipment": return buy_equipment(bar,index)
		"promotion": return start_promotion(bar,index)
		"open":
			if bar.open:
				bar.open = false
				bar.close_reason = "Closed by owner"
				bar.customers.clear()
				bar.games.clear()
				bar.host_requests.clear()
				return "Closed. Staff and overhead charges pause."
			if s.cash < ceili(operating_rate(bar)/60.0): return "You need enough cash for the next operating charge."
			bar.open = true
			bar.close_reason = ""
			return "Reopened. Welcome the next customers."
		"recovery":
			if bar.open: return "Close the venue before taking an owner-run recovery shift."
			if s.cash>=120: return "You have enough cash to reopen normally; recovery cover is for an empty till."
			if bar.closed>0: return "Wait for the temporary closure to end."
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
			bar.team[index].on = not bar.team[index].on
			return "Rota updated. Off-duty staff do not incur wages."
		"role":
			if bar.type==0 or index<0 or index>=bar.team.size(): return "Choose a team member at a Soi bar or gogo."
			if index in bar.away: return "Wait until this team member returns."
			var person: Dictionary = bar.team[index]
			person.role = int(bar.type) if person.role==0 else 0
			person.host = free_host(bar) if person.role==1 else -1
			return "Role changed to %s. Payroll and service forecasts updated." % C.ROLE_NAMES[int(person.role)]
		"hire":
			if index<0 or index>2: return "Unknown role."
			if index==1 and bar.type!=1: return "Hosts work in Soi venues."
			if index==2 and bar.type!=2: return "Dancers work in gogos."
			if bar.team.size()>=int(bar.stage)*2: return "Upgrade for more team positions."
			var amount: int = 600*(bar.team.size()+1)
			if s.cash<amount+(operating_rate(bar)+int(C.ROLE_WAGES[index]))*2: return "Keep a shift's payroll after hiring."
			s.cash -= amount
			s.weekly.costs += amount
			var host := free_host(bar) if index==1 else -1
			bar.team.append({"role":index,"on":true,"host":host})
			bar.crew = bar.team.size()
			return "%s hired. Wages: ฿%d/min while on duty." % [C.ROLE_NAMES[index],C.ROLE_WAGES[index]]
		"bar_fine":
			if index<0 or index>=bar.team.size() or bar.team[index].role!=1: return "Choose an adult host."
			if not bar.open or bar.closed>0 or not bar.team[index].on or index in bar.away: return "This host is unavailable."
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
	report.net = int(report.revenue)-int(report.stock_cost)-int(report.operating)-int(report.promo_cost)
	report.reason = "Healthy service. Compare demand with capacity before expanding."
	if report.lost_stock>0: report.reason = "Out of stock: more reliable deliveries would recover sales."
	elif report.lost_service>0: report.reason = "Slow service: waiting orders need help or trained bartenders."
	elif report.lost_full>0: report.reason = "Full: improve layout or seating before advertising harder."
	elif report.occupied_seconds<report.open_seconds*seats(bar)*.4: report.reason = "Quiet: try signage, welcoming or a targeted promotion."
	# Inventory purchases are investments in later sales: assess operating margin.
	if report.sales>=4 and report.sales>=report.orders*.8 and int(report.revenue)-int(report.sales)*C.STOCK_COST-int(report.operating)-int(report.promo_cost)>0:
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
			if bar.open and bar.closed==0:
				bar.promo.operating_credit += operating_rate(bar)
				bar.promo.operating += int(bar.promo.operating_credit)/60
				bar.promo.operating_credit = int(bar.promo.operating_credit)%60
			if bar.promo.remaining<=0:
				bar.promo_report = bar.promo.duplicate(true)
				bar.promo = {}
				bar.promo_cooldown = C.PROMOTION_COOLDOWN
		else: bar.ordinary_seconds += 1
		if not bar.open or bar.closed>0: continue
		bar.recovery = maxi(0,int(bar.recovery)-1)
		bar.cost_credit += operating_rate(bar)
		var charge := int(bar.cost_credit)/60
		if not cost(bar,charge,"operating"):
			bar.open = false
			bar.close_reason = "Operating cash ran out"
			bar.customers.clear()
			bar.games.clear()
			bar.host_requests.clear()
			continue
		bar.cost_credit = int(bar.cost_credit)%60
		bar.shift.open_seconds += 1
		bar.shift.occupied_seconds += bar.customers.size()
		for customer in bar.customers.duplicate():
			customer.life -= 1
			if customer.order:
				customer.wait += 1
				if customer.wait > (45 if customer.opening else C.PATIENCE_SECONDS)+(10 if bar.equipment.comfort else 0):
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
		bar.service_clock += service_rate(bar)
		var portions := int(bar.service_clock)/60
		bar.service_clock = int(bar.service_clock)%60
		if portions>0: serve(bar,portions)
		pool_tick(bar)

func offline(now: int, cap_seconds: int) -> int:
	var elapsed := clampi(now-int(s.street.last_seen),0,cap_seconds)
	s.street.last_seen = maxi(now,int(s.street.last_seen))
	var net := 0
	var visits := 0
	var gross := 0
	var expenses := 0
	var notes := []
	for bar in s.street.bars:
		if not bar.manager or not bar.open or bar.closed>0 or bar.recovery>0: continue
		var view := forecast(bar,true)
		if view.net<=0 or (bar.stock<=0 and not bar.restock) or s.cash<operating_rate(bar)*2+(140 if bar.stock==0 else 0):
			notes.append(str(bar.name)+": operation paused; projected trading is unviable.")
			continue
		var duration := float(elapsed)/60.0
		if not bar.restock: duration = minf(duration,int(bar.stock)/maxf(.01,view.sales))
		if not bar.restock: bar.stock = maxi(0,int(bar.stock)-floori(view.sales*duration))
		var gain := floori(view.net*duration)
		net += gain
		visits += floori(minf(view.arrivals,view.sales/2.0)*duration)
		var venue_gross := floori((view.sales*int(C.TYPES[int(bar.type)].drink)+view.pool)*duration)
		gross += venue_gross
		expenses += venue_gross-gain
		notes.append("%s: estimated ฿%d net; %.1f orders/min, %.1f service/min; limited by %s." % [bar.name,gain,view.demand,view.service,"stock" if duration<float(elapsed)/60.0 else "service" if view.service<view.demand else "customer demand / space"])
	# A conservative net projection; it never debits opening cash or progresses
	# queues, promotions, events, local milestones or calendar time.
	s.cash += net
	s.weekly.revenue += gross
	s.weekly.costs += expenses
	s.street.earned += net
	s.street.offline = net
	s.street.offline_report = {"seconds":elapsed,"net":net,"income":gross,"costs":expenses,"customers":visits,"notes":notes}
	return net

func actual_rate(bar: Dictionary) -> int:
	var net := 0
	var seconds := int(bar.shift.open_seconds)
	net += int(bar.shift.revenue)-int(bar.shift.stock_cost)-int(bar.shift.operating)-int(bar.shift.promo_cost)
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
