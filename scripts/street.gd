extends RefCounted

const C = preload("res://scripts/street_content.gd")
const Crew = preload("res://scripts/content.gd")
const Economy = preload("res://scripts/economy.gd")
const OFFLINE_CAP = 8 * 60 * 60
const SHIFT_SECONDS = 120
const TOUR_UPDATE_SECONDS = 8
var s: Dictionary
var economy: RefCounted
var finance: RefCounted
signal checkpoint_requested
var raid_checkpoint := false
var night_prep_visible := true
var tour_update := ""
var tour_update_until := 0

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
	if not s.street.has("supplier_deal"): s.street.supplier_deal = {}
	if not s.street.has("night_prep"): s.street.night_prep = {"night":-1,"remaining":0,"cancelled":false}
	if not s.street.has("expired_tours"): s.street.expired_tours = {}
	var event: Dictionary = s.street.event
	if event.get("id",-1)==C.RAT_PLAGUE and event.phase=="active":
		event.erase("remaining")
		if not event.has("rats"): event.rats = range(C.RAT_COUNT)
	economy = Economy.new(s,fresh)
	economy.tour_arrived.connect(record_tour_arrival)
	finance = Economy.Finance.new(s)
	finance.migrate(economy,fresh)
	s.street.merge({"marketing_level":0})
	s.version = 17

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

func record_tour_arrival(guide_index: int, venue_name: String, guests: int) -> void:
	var guide_name: String = Crew.STAFF[int(s.staff[guide_index].id)][0]
	var customers := "a new customer" if guests==1 else "%d new customers" % guests
	record_tour_update("Tour guide %s brought %s to %s." % [guide_name,customers,venue_name])

func record_tour_update(line: String) -> void:
	record(line)
	# Give an arrival on the last tick of a shift time to show in the update strip.
	if tour_update_until==int(s.street.elapsed)+TOUR_UPDATE_SECONDS: return
	tour_update = line
	tour_update_until = int(s.street.elapsed)+TOUR_UPDATE_SECONDS

func pay(cost: int, reason: String = "Event preparation") -> bool:
	if cost < 0 or int(s.cash) < cost: return false
	Economy.Finance.change(s,-cost,reason)
	s.weekly.costs += cost
	return true

func venue_pay(bar: Dictionary, amount: int) -> bool:
	if amount<0 or s.cash<amount: return false
	Economy.Finance.change(s,-amount,"Venue renovation",str(bar.name))
	s.weekly.costs += amount
	return true

func purchase_offer(bar: Dictionary, id: String, index: int = 0) -> Dictionary:
	if (id=="equipment" and (index<0 or index>=C.EQUIPMENT.size())) or (id in ["train_staff","train_audience","train_host"] and (index<0 or index>=bar.team.size())) or (id=="action_upgrade" and not index in [0,1]):
		return {"enabled":false,"reason":"Unknown purchase.","price":0,"required":0}
	match id:
		"upgrade":
			var reason: String = economy.upgrade_reason(bar)
			return {"price":upgrade_cost(bar),"required":economy.upgrade_required_cash(bar) if bar.stage<3 else 0,"enabled":reason.is_empty(),"reason":reason}
		"equipment": return economy.equipment_offer(bar,index)
		"restock": return economy.supplier_offer(bar)
		"manager": return economy.manager_offer(bar)
		"regulars_club": return economy.club_offer(bar)
		"auto_serve":
			if bar.auto_serve: return {"enabled":false,"reason":"Already installed.","price":0,"required":0}
			return economy.auto_serve_offer(bar)
		"auto_host_drinks": return economy.auto_hosted_offer(bar)
		"auto_bar_fine": return economy.auto_bar_fine_offer(bar)
		"train_staff","train_audience": return economy.training_offer(bar,index,id=="train_audience")
		"train_host": return economy.host_training_offer(bar,index)
		"action_upgrade":
			var quote: Dictionary = economy.action_upgrade_status(bar,index)
			quote.reason = "Needs venue stage 2." if not quote.stage_ok else "Not enough money for this purchase." if not quote.enabled else ""
			return quote
	return {"enabled":false,"reason":"Unknown purchase.","price":0,"required":0}

func funded_offer(id: String, index: int = 0) -> Dictionary:
	var quote := purchase_offer(selected(),id,index)
	quote.available = int(s.cash)
	return quote

func fund_and_buy(id: String, index: int = 0, expected_price: int = -1) -> String:
	if not s.phase in ["plan","guided"]: return "Finish the current decision first."
	var quote := funded_offer(id,index)
	if expected_price>=0 and quote.price!=expected_price: return "The offer changed. Review the current price."
	if not quote.enabled: return quote.reason
	return action(id,index)

func marketing_offer() -> Dictionary:
	var level := int(s.street.marketing_level)
	var ready := false
	for bar in s.street.bars: ready = ready or bar.stage>=2
	var price := int(C.MARKETING_PRICES[level]) if level<C.MARKETING_PRICES.size() else 0
	var reason := ""
	if level>=C.MARKETING_PRICES.size(): reason = "Street marketing complete."
	elif not ready: reason = "Renovate one venue to stage 2 first."
	elif s.cash<price: reason = "Not enough money for street marketing."
	return {"level":level,"price":price,"required":price,"available":int(s.cash),"enabled":reason.is_empty(),"reason":reason,"traffic":C.MARKETING_TRAFFIC[level] if level<C.MARKETING_TRAFFIC.size() else 0}

func buy_marketing() -> String:
	var quote := marketing_offer()
	if not quote.enabled: return quote.reason
	if not pay(int(quote.price),"Street marketing"): return "Not enough money."
	s.street.marketing_level += 1
	return "Street marketing %d: +%d potential visitors/min. Seats, service and stock still matter." % [s.street.marketing_level,quote.traffic]

func credit(gross: int, costs: int = 0) -> void:
	Economy.Finance.change(s,gross,"Event reward")
	Economy.Finance.change(s,-costs,"Event costs")
	s.weekly.revenue += gross
	s.weekly.costs += costs
	s.street.earned += gross - costs

func capacity(bar: Dictionary) -> int:
	return economy.stock_capacity(bar)

func staff_limit(bar: Dictionary) -> int:
	return int(bar.stage)*2

func upgrade_cost(bar: Dictionary) -> int:
	return 0 if bar.stage >= 3 else int(C.RENOVATIONS[int(bar.type)][int(bar.stage)-1])

func purchased_count(kind: int) -> int:
	var count := 0
	for slot in s.street.bars.size():
		var bar: Dictionary = s.street.bars[slot]
		# The inherited flagship is never a repeat purchase, even after renaming.
		if slot==0 and bar.type==0: continue
		if bar.type==kind: count += 1
	return count

func lease_sale(kind: int) -> bool:
	return int(s.day)>=C.LEASE_SALE_DAYS and int(s.day)%C.LEASE_SALE_DAYS==0 and kind==C.LEASE_SALE_TYPES[(int(s.day)/C.LEASE_SALE_DAYS-1)%C.LEASE_SALE_TYPES.size()]

func purchase_cost(kind: int) -> int:
	var normal := int(C.LEASES[kind])*(100+purchased_count(kind)*C.LEASE_REPEAT_PERCENT)/100
	return normal*(100-C.LEASE_SALE_PERCENT)/100 if lease_sale(kind) else normal

# A read-only lease quote. The listed price is the entire cash requirement.
func lease_quote(kind: int) -> Dictionary:
	var base := int(C.LEASES[kind])
	var repeats := purchased_count(kind)
	var surcharge := base*repeats*C.LEASE_REPEAT_PERCENT/100
	var price_value := purchase_cost(kind)
	var reserve := 0
	var running := int(C.OVERHEAD[kind])+int(C.ROLE_WAGES[0])
	var reason := ""
	if s.street.bars.size()>=C.NAMES.size(): reason = "You own the whole soi."
	elif s.street.chapter<1: reason = "Finish the Blue Hour reopening chapter."
	elif s.rep<C.TYPES[kind].rep: reason = "Needs %d reputation." % C.TYPES[kind].rep
	elif s.cash<price_value+reserve: reason = "Need ฿%d more." % (price_value+reserve-int(s.cash))
	return {"base":base,"repeats":repeats,"surcharge":surcharge,"discount":base+surcharge-price_value,"price":price_value,"reserve":reserve,"required":price_value+reserve,"overhead":C.OVERHEAD[kind],"running":running,"break_even":float(running)/(int(C.TYPES[kind].drink)-C.STOCK_COST),"enabled":reason.is_empty(),"reason":reason}

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

func preparation_offer() -> Dictionary:
	var event: Dictionary = s.street.event
	if event.is_empty(): return {"required":0,"enabled":false,"reason":"Preparation closes when the event starts."}
	var required := int(C.EVENTS[int(event.id)][3])
	var reason := ""
	if event.phase!="warning" and event.id!=C.RAT_PLAGUE: reason = "Preparation closes when the event starts."
	elif event.prepared: reason = "Already prepared."
	elif event.id==C.RAT_PLAGUE and event.phase=="active" and rat_targets().size()<=C.RAT_STRAGGLERS: reason = "Only stragglers left. Click or tap them to clear the infestation."
	elif event.id==C.Local.BED and race_staff(s.street.bars[int(event.venue)])<0: reason = "Enter with an available bartender."
	elif s.cash<required: reason = "The preparation needs more cash."
	return {"required":required,"reason":reason,"enabled":reason.is_empty()}

func action(id: String, index: int = 0) -> String:
	if not s.phase in ["plan","guided"]: return "Finish the current decision first."
	var bar := selected()
	var result := ""
	match id:
		"serve","regulars_club","stock","buy_drink","return_drink","hire","hire_gabby","hire_daisy","welcome","chat","action_upgrade","equipment","promotion","rota","role","open","close_and_count","recovery","host_drink","auto_host_drinks","bar_fine","train_host","auto_bar_fine","clean","emergency_stock","rehire","train_staff","train_audience","auto_serve":
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
			result = "Staying for prep. Cleaning continues; use Skip to open when ready."
		"skip":
			if not can_skip(): return "Skip is available after 1am when every venue has stopped trading."
			skip_to_noon(C.OPEN_MINUTE-int(s.street.minute))
			result = "12pm. Check cleanliness, stock and the rota."
		"close_for_rats":
			if rat_targets().is_empty(): return "There is no active infestation."
			var minute := int(s.street.minute)
			var to_noon := C.OPEN_MINUTE-minute
			if minute>=C.OPEN_MINUTE:
				to_noon += C.DAY_MINUTES
				next_calendar_day()
			s.street.minute = maxi(C.CLOSE_MINUTE,minute if minute<C.OPEN_MINUTE else 0)
			for venue in s.street.bars: venue.late_open = false
			reconcile_closures()
			settle_overnight()
			celebration_tick()
			finish_event(true,"Bo clears the last of the restaurant's rats overnight.")
			skip_to_noon(to_noon)
			result = "12pm. Bo cleared all the rats. The street is ready to trade."
		"supplier_deal": result = buy_supplier_deal()
		"restock": result = economy.buy_supplier(bar)
		"manager": result = economy.buy_manager(bar)
		"upgrade":
			if bar.stage >= 3: return "This venue is at its final stage."
			var reason: String = economy.upgrade_reason(bar)
			if not reason.is_empty(): return reason
			if not venue_pay(bar,upgrade_cost(bar)): return "Save a little more for the renovation."
			bar.stage += 1
			if s.street.selected == 0:
				s.level = bar.stage
				if not s.street.reopening:
					s.street.reopening = true
					announce(0)
			result = C.TYPES[int(bar.type)].stages[int(bar.stage)-1][2]
		"buy":
			if index < 0 or index >= C.TYPES.size(): return "Unknown venue type."
			var quote := lease_quote(index)
			if not quote.enabled: return quote.reason
			pay(quote.price,"Lease: "+str(C.TYPES[index].name))
			var new_bar := make_bar(index,s.street.bars.size())
			s.street.bars.append(new_bar)
			var defaults: Dictionary = economy.new_fields()
			for key in defaults: new_bar[key] = defaults[key]
			economy.ensure_stock_lots(new_bar)
			s.street.selected = s.street.bars.size()-1
			result = "%s opens. %s" % [new_bar.name,C.TYPES[index].stages[0][2]]
		"encore_solo":
			var event: Dictionary = s.street.event
			if event.get("id",-1)!=C.Local.ENCORE or event.phase!="warning" or event.prepared: return "The setup window has closed."
			event.solo = true
			result = "Anong puts out the sign. Work the crowd yourself."
		"prepare":
			var event: Dictionary = s.street.event
			var offer := preparation_offer()
			if not offer.enabled: return offer.reason
			if not pay(offer.required): return "The preparation needs more cash."
			event.prepared = true
			result = "Bo's rat patrol is on the job." if event.id==C.RAT_PLAGUE else C.EVENTS[int(event.id)][2] + " arranged."
		"festival":
			if s.street.chapter < 4 or not festival_ready(): return "Needs a stage-3 beer bar, Hostess bar and gogo."
			if not s.street.event.is_empty(): return "Finish the current street event first."
			announce(9)
			result = "After Hours Street Festival announced. Prepare the street!"
		_:
			return "Unknown street action."
	reconcile_closures()
	settle_overnight()
	if not id in ["serve","welcome","stock","buy_drink","return_drink"]: record(result)
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
func goal_cash(price: int, _reserve: int = 0, _bank: bool = false) -> String:
	return "฿%d purchase; ฿%d still to save." % [price,maxi(0,price-int(s.cash))]

func next_goal() -> Dictionary:
	var chapter := int(s.street.chapter)
	var first: Dictionary = s.street.bars[0]
	var title := "The soi never sleeps"
	var detail := "Keep your mixed street healthy, try a different promotion or host the festival again. No reset required."
	var focus := ""
	var summary := "Manage your venues or host another festival."
	var tab := 1
	var cash_target := 0
	var cash_goal := ""
	if chapter<5 and chapter_requirements()[chapter]:
		return {"title":"Milestone ready","summary":"Keep trading to record it.","detail":"The business has earned its next chapter. Continue trading to record it.","focus":"","tab":0,"venue":0}
	if chapter==0:
		tab = 0
		if s.street.served<10:
			title = "Serve your first ten drinks"
			summary = "%d / 10 served" % mini(10,int(s.street.served))
			detail = "%d/10 real orders served. Anong: Cold drinks first. Empire later. Serve waiting guests; welcome passersby when quiet." % mini(10,int(s.street.served))
			focus = "Buy %d drinks" % economy.pack_quantity(first) if first.stock==0 else "serve"
		elif first.regulars==0:
			title = "Earn your first regular"
			summary = "Serve guests before their orders expire."
			detail = "Keep orders moving and stock ready. Happy departures can earn your first regular. Anong: A second visit beats a five-star promise."
			focus = "TEAM & PAYROLL"
		elif first.stage<2:
			title = "Renovate the Blue Hour"
			summary = "Save for the renovation price."
			detail = goal_cash(upgrade_cost(first),economy.operating_rate(first)*2)+" Local milestones earn loyalty, not building permission."
			cash_target = upgrade_cost(first)
			cash_goal = "Blue Hour renovation"
			focus = "Upgrade ·"
		elif s.street.events_survived==0:
			title = "Get through the reopening"
			summary = "Open Events for Bo’s generator."
			detail = "The new sign is ready. Check Events for Bo's generator offer and see the reopening through. A setback will not end the business."
			tab = 1
		elif not first.manager:
			if economy.on_duty(first,0)==0:
				title = "Get a bartender on duty"
				summary = "Hire or rehire in Team."
				detail = "Hire or rehire a bartender for ฿%d and put them on duty. Training stays with them. Dao needs a serving team before taking the keys." % C.BARTENDER_CONTRACT_COST
				cash_target = C.BARTENDER_CONTRACT_COST
				cash_goal = "a bartender"
				focus = "TEAM & PAYROLL"
			elif not first.restock:
				title = "Automate deliveries"
				summary = "Set up a supplier agreement."
				detail = "Supplier level 1 automates paid deliveries when orders need stock. %s" % goal_cash(C.SUPPLIER_PRICES[0],economy.operating_rate(first)*2)
				cash_target = int(C.SUPPLIER_PRICES[0])
				cash_goal = "supplier agreement"
				focus = "SUPPLIER AGREEMENT"
			else:
				title = "Hand Dao the keys"
				var offer: Dictionary = economy.manager_offer(first)
				summary = "Manager ready" if offer.enabled else "Save for a manager · ฿%d" % offer.price
				detail = "%s Dao enables managed offline trading and a 25%% bonus on earned drink/pool margins. %s" % [goal_cash(offer.price,(economy.operating_rate(first)+12)*2),"Ready to appoint." if offer.enabled else offer.reason]
				cash_target = int(offer.price)
				cash_goal = "a manager"
				focus = "MANAGEMENT"
	elif chapter==1:
		title = "Open a second bar"
		summary = "Reputation %d / 20 · Check the lease" % mini(20,int(s.rep))
		detail = "Anong: He's retiring again. This time, get the keys. Hostess lease: %s Reputation %d/20. Other venue types remain your choice." % [goal_cash(purchase_cost(1),opening_reserve(1),true),mini(20,int(s.rep))]
		cash_target = int(lease_quote(1).required)
		cash_goal = "second bar lease"
		tab = 3
	elif chapter==2:
		var managers := 0
		var soi := false
		for bar in s.street.bars:
			managers += int(bar.manager)
			soi = soi or bar.type==1
		title = "Run two managed bars"
		summary = "%d / 2 managers · Hostess bar %s" % [mini(2,managers),"owned" if soi else "needed"]
		detail = "Hostess bar: %s · managers %d/2. Each new bar builds its own loyalty. Fund its till from the company bank. Dao: Two sets of keys. One owner who finally sits down." % ["owned" if soi else "still needed",mini(2,managers)]
		tab = 3
	elif chapter==3:
		title = "Open a gogo and reach stage 2"
		summary = "Lease a gogo or develop the one you own."
		detail = "Open a gogo and earn its second stage. Dancers attract; bartenders serve. Anton has ordered another screen. Pim suggests a better show."
		tab = 3
	elif chapter==4:
		var developed := [false,false,false]
		for bar in s.street.bars:
			if bar.stage==3: developed[int(bar.type)] = true
		title = "Host the street festival"
		summary = "%d / 3 venue types at stage 3" % developed.count(true)
		detail = "Stage-three venues: beer %d/1 · Soi %d/1 · gogo %d/1. Then arrange the After Hours Street Festival in Events. The guest list includes something from the bay." % [int(developed[0]),int(developed[1]),int(developed[2])]
	return {"title":title,"summary":summary,"detail":detail,"focus":focus,"tab":tab,"venue":0,"cash_target":cash_target,"cash_goal":cash_goal}

func supplier_deal_tick() -> void:
	if s.get("practice",false) or (int(s.day)-1)%C.SUPPLIER_DEAL_INTERVAL!=0: return
	if not supplier_deal_hours() or s.street.supplier_deal.get("day",0)==s.day: return
	var bar := selected()
	if not economy.is_trading(bar): return
	var drink := 3 if bar.equipment.menu else 2
	s.street.supplier_deal = {"day":s.day,"venue":s.street.selected,"drink":drink,"seen":false,"bought":false}

func supplier_deal_hours() -> bool:
	return int(s.street.minute)>=C.SUPPLIER_DEAL_START and int(s.street.minute)<C.SUPPLIER_DEAL_END

func supplier_deal_offer() -> Dictionary:
	var deal: Dictionary = s.street.supplier_deal
	if deal.is_empty() or deal.bought or deal.day!=s.day or not supplier_deal_hours(): return {}
	var bar: Dictionary = s.street.bars[int(deal.venue)]
	var drink := int(deal.drink)
	if not economy.is_trading(bar) or drink>=economy.drink_count(bar): return {}
	var normal_unit: int = economy.drink_cost(bar,drink)
	var unit := maxi(1,int(normal_unit*3/4.0))
	var quote: Dictionary = economy.stock_quote(bar,C.SUPPLIER_DEAL_UNITS,unit)
	var goal := next_goal()
	quote.merge({"bar":bar,"drink":drink,"unit":unit,"normal":normal_unit*C.SUPPLIER_DEAL_UNITS,
		"seen":deal.seen,"goal_name":goal.cash_goal if goal.get("cash_target",0)>0 else "next lager delivery",
		"target":int(goal.cash_target) if goal.get("cash_target",0)>0 else economy.pack_price(bar)})
	return quote

func buy_supplier_deal() -> String:
	var quote := supplier_deal_offer()
	if quote.is_empty(): return "Bo’s deal has ended."
	if not quote.enabled: return quote.reason
	if not economy.cost(quote.bar,quote.price,"stock_cost"): return "The till is short."
	economy.add_stock(quote.bar,quote.drink,quote.quantity,quote.unit)
	s.street.supplier_deal.bought = true
	return "%d %s delivered · saved ฿%d." % [quote.quantity,C.DRINKS[quote.drink].name,quote.normal-quote.price]

func announce(id: int) -> void:
	s.street.event = {"id":id,"phase":"warning","remaining":C.RAT_WARNING_SECONDS if id==C.RAT_PLAGUE else 30 if id>=C.Local.ENCORE else 60,"prepared":false,"serial":s.street.get("elapsed",0)}
	if id>=C.Local.ENCORE: s.street.event.venue = s.street.selected
	record("COMING UP · " + C.EVENTS[id][0] + ": " + C.EVENTS[id][1])

func rat_targets() -> Array:
	var event: Dictionary = s.street.event
	if event.get("id",-1)!=C.RAT_PLAGUE or event.phase!="active": return []
	return event.rats

func catch_rat(index: int) -> bool:
	if not s.phase in ["plan","guided"]: return false
	var targets := rat_targets()
	if not targets.has(index): return false
	targets.erase(index)
	if targets.is_empty(): finish_event()
	return true

func start_event() -> void:
	var event: Dictionary = s.street.event
	event.phase = "active"
	record("TONIGHT · " + C.EVENTS[int(event.id)][0])
	if event.id==C.RAT_PLAGUE:
		event.erase("remaining")
		event.rats = range(C.RAT_COUNT)
		var fled := 0
		for bar in s.street.bars:
			fled += bar.customers.size()
			economy.clear_visits(bar)
		record("RAT PLAGUE · Rats from the restaurant send %d guests running." % fled)
	else:
		event.remaining = 45 if event.id>=C.Local.ENCORE else 90
	if int(event.id)>=C.Local.ENCORE:
		var target: Dictionary = s.street.bars[int(event.venue)]
		match int(event.id):
			C.Local.ENCORE:
				event.encore = posmod(hash(Vector2i(int(s.street.economy_seed),int(event.serial))),2)==0
				if not event.get("early",false) or event.prepared or event.get("solo",false):
					record("The band plays an encore. Expect two waves." if event.encore else "The final song ends. Here comes the crowd.")
			C.Local.CART:
				if event.prepared:
					var units := mini(4,economy.stock_capacity(target)-int(target.stock))
					if units>0: economy.add_stock(target,0,units,economy.drink_cost(target,0))
					record("Bo gets through on foot with %d cold lagers." % units)
			C.Local.BED:
				var runner := race_staff(target) if event.prepared else -1
				event.prepared = runner>=0
				if runner>=0:
					event.runner = runner
					target.away.append(runner)
			C.Local.LIZARD:
				if event.prepared:
					event.lucky = posmod(hash(Vector2i(int(s.street.economy_seed),int(event.serial))),4)!=0
					record("Locals are already talking about a lucky round." if event.lucky else "The locals leave the rescuers some space.")
	if event.id in [0,2,3,4] and not event.prepared:
		var protected: bool = (event.id == 2 and s.license >= 75 and s.safety >= 65) or (event.id == 3 and s.trust >= 60)
		if not protected:
			for bar in s.street.bars:
				bar.closed = 20 if event.id in [0,4] else 40
			if event.id == 2:
				var fine := mini(900,int(s.cash) / 5)
				pay(fine,"Inspection fine")
				record("Inspection: paperwork gaps. ฿%d fine; a short closure for corrections." % fine)

func race_staff(bar: Dictionary) -> int:
	for i in bar.team.size():
		var worker: Dictionary = bar.team[i]
		if worker.role==0 and worker.on and economy.contracted(worker) and i not in bar.away: return i
	return -1

func available_event_game() -> int:
	var event: Dictionary = s.street.event
	var id := int(event.get("id",-1))
	if s.phase!="plan" or event.get("phase","")!="active" or event.get("attempted",false): return -1
	if not ((id==C.Local.CART and not event.prepared) or (id==C.Local.BED and event.prepared)): return -1
	return id

func begin_event_game() -> int:
	var id := available_event_game()
	if id>=0: s.street.event.attempted = true
	return id

func settle_event_game(id: int, won: bool) -> String:
	var event: Dictionary = s.street.event
	if id!=int(event.get("id",-1)) or not event.get("attempted",false) or event.has("game_won"): return ""
	event.game_won = won
	if id==C.Local.CART:
		return "Traffic cleared. Bo can deliver again." if won else "Bo will wait out the jam."
	if won:
		s.street.bars[int(event.venue)].bed_trophy = true
		s.rep = mini(100,int(s.rep)+3)
		return "You won the bed race! The trophy is on the wall."
	return "Bo’s bed finished. Eventually."

func finish_event(won: bool = true, outcome: String = "") -> void:
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
	if id==C.Local.BED and event.has("runner"):
		s.street.bars[int(event.venue)].away.erase(int(event.runner))
	if id == 3 and event.prepared: s.trust = mini(100,int(s.trust)+8)
	if id == 5: s.rep = clampi(int(s.rep)+(4 if event.prepared else -2),0,100)
	if id == 6 and event.prepared: record("The locals appreciate the invitation. Good visits can earn their loyalty.")
	record(C.EVENTS[id][4] if outcome.is_empty() else outcome)
	s.street.events_survived += 1
	s.street.event = {}
	s.street.event_wait = 180
	check_chapters()

func end_shift() -> void:
	s.street.seconds = 0
	for bar in s.street.bars:
		# Legacy absences keep their shift boundary; timed bookings keep their deadline.
		for i in bar.away.duplicate():
			if float(bar.team[int(i)].get("host_return",0))<=economy.action_time(): bar.away.erase(i)
		var event: Dictionary = s.street.event
		if event.get("id",-1)==C.Local.BED and event.has("runner") and s.street.bars[int(event.venue)]==bar:
			if not int(event.runner) in bar.away: bar.away.append(event.runner)
		economy.settle_shift(bar)
	if not s.bookings.is_empty():
		s.street.expired_tours.merge(s.bookings,true)
		var count: int = s.bookings.size()
		s.bookings.clear()
		record_tour_update("Tour agreement expired." if count==1 else "%d tour agreements expired." % count)
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
		record("Anong counts the tip jars: ฿%d from %d served visits%s. Tomorrow's cold beer fund." % [report.amount,report.visits," (฿%d in drink bonuses)" % report.bonus if report.bonus>0 else ""])

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

func skip_to_noon(minutes: int) -> void:
	count_tips()
	economy.advance_contracts(minutes)
	s.street.minute = C.OPEN_MINUTE
	reopen_noon()
	celebration_tick()
	s.street.offline_cursor = C.OPEN_MINUTE

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
	if int(s.day)%C.CELEBRATION_INTERVAL==C.CELEBRATION_INTERVAL-1:
		record("Tomorrow: %s at the Blue Hour." % Economy.celebration_name(int(s.day)+1))

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

	if s.phase in ["plan","guided"]:
		for bar in s.street.bars:
			economy.return_hosts(bar)
			economy.hosted_tick(bar)

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
		if event.get("id",-1)==C.RAT_PLAGUE and event.phase=="active":
			if event.prepared and event.rats.size()>C.RAT_STRAGGLERS:
				var catches := mini(C.RAT_PATROL_CATCHES,event.rats.size()-C.RAT_STRAGGLERS)
				event.rats = event.rats.slice(catches)
		elif trading_now:
			if not event.is_empty():
				event.remaining -= 1
				if event.remaining<=0:
					if event.phase=="warning": start_event()
					else: finish_event(not int(event.id) in [8,9])
			elif s.street.chapter==0 and s.day==1 and int(s.street.elapsed)>=180 and not s.street.get("early_encore",false):
				s.street.early_encore = true
				announce(C.Local.ENCORE)
				s.street.event.early = true
			elif s.street.chapter>=1 and not economy.celebration_window():
				s.street.event_wait -= 1
				if s.street.event_wait<=0:
					var slot := int(s.street.event_index)
					# Keep the rare roll independent of the customer RNG and regular event rotation.
					if posmod(hash(Vector3i(int(s.street.economy_seed),int(s.street.elapsed),slot)),C.RAT_EVENT_ODDS)==0:
						announce(C.RAT_PLAGUE)
					else:
						announce(C.Local.ROTATION[slot%C.Local.ROTATION.size()])
						s.street.event_index += 1
		economy.advance_contracts(1)
		s.street.minute = (int(s.street.minute)+1)%C.DAY_MINUTES
		if s.street.minute==0: next_calendar_day()
		if s.street.minute==C.OPEN_MINUTE: reopen_noon()
		if s.phase=="plan": supplier_deal_tick()
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

func opening_reserve(_kind: int) -> int:
	return 0 # Compatibility for older quote consumers; there is no reserve.
