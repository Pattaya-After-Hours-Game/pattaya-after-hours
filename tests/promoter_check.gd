extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Economy = preload("res://scripts/economy.gd")
const City = preload("res://scripts/city.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	for pool in 2:
		for comfort in 2:
			bar.equipment.pool = pool
			bar.equipment.comfort = comfort
			bar.equipment.seating = 3
			test.check(eco.seats(bar)==12,"Compact beer bar holds twelve with every stage-one furniture combination")
	bar.type = 1
	bar.equipment.seating = 2
	m.s.cash = 10000
	m.street.action("equipment",4)
	test.check(bar.equipment.seating==2,"Soi seating retains its two-level limit")
	bar.type = 0
	for item in [[24,84,true],[25,1000,false],[24,83,false],[23,85,true]]:
		bar.stock = item[0]
		m.s.cash = item[1]
		var before := [bar.stock,m.s.cash]
		m.street.action("stock")
		test.check([bar.stock,m.s.cash]==([before[0]+6,before[1]-84] if item[2] else before),"Six-pack purchase is atomic at cash/space boundaries")
	bar.equipment.fridge = 1
	bar.stock = 66
	m.s.cash = 10000
	test.check(not eco.stock_offer(bar).enabled,"Four spare spaces in a seventy-unit fridge cannot fit a pack")
	m = Campaign.new(72)
	bar = m.street.selected()
	eco = m.street.economy
	m.s.cash = 20000
	var original_service: float = eco.service_rate(bar)
	var old_attraction: float = eco.attraction(bar)
	m.street.action("hire",3)
	test.check(m.s.cash==18800 and bar.team[0].role==3 and eco.operating_rate(bar)==18,"Nida has the agreed contract and no hourly wage")
	test.check(eco.service_rate(bar)==original_service and eco.attraction(bar)>old_attraction,"Promoter attracts but never serves")
	test.check(not eco.action_status(bar,"welcome").enabled,"Promoter replaces manual Welcome")
	var money: int = m.s.cash
	m.street.action("hire",3)
	test.check(bar.team.size()==1 and m.s.cash==money,"One frontage slot prevents duplicate promoter purchases")
	m.street.action("hire",0)
	m.street.action("hire",0)
	test.check(eco.floor_staff(bar)==2 and bar.team.size()==3,"Promoter does not consume stage-one bartender positions")
	m.street.action("role",0)
	test.check(bar.team[0].role==3,"Cheap promoter contract cannot become a bartender")
	var snapshot := JSON.stringify(m.s)
	eco.promoter_forecast(bar,true)
	test.check(JSON.stringify(m.s)==snapshot,"Hire forecasts cannot mutate the live campaign or RNG")
	# Hiring commits already-waiting orders; turning off before serving cannot
	# avoid commission. Two beers carry their half-baht into an exact eleven.
	m.street.action("rota",0)
	money = m.s.cash
	eco.serve(bar,1)
	test.check(m.s.cash==money+50 and bar.commission_paid==5 and bar.commission_carry==50,"First beer settles gross receipt and commission with fractional carry")
	m.save_game()
	var loaded = Campaign.new(4)
	test.check(loaded.load_game() and loaded.s.version==11,"Schema eleven reloads promoter commission state")
	loaded.street.economy.serve(loaded.street.selected(),1)
	test.check(loaded.street.selected().commission_paid==11 and loaded.street.selected().commission_carry==0,"Reload cannot erase half-baht carry or pending commission")
	test.check(loaded.street.selected().shift.commission==11,"Commission is visible in the actual shift ledger")
	# A recruited visit retains commission on repeat orders after expiry.
	m.street.action("rota",0)
	bar.equipment.seating = 3
	eco.admit(bar)
	var guest: Dictionary = bar.customers.back()
	test.check(guest.commission_visit,"Visits arriving during promotion retain their entitlement")
	bar.team[0].contract_left = 1
	eco.advance_contracts(1)
	guest.order = false
	eco.order(bar,guest)
	test.check(guest.commission_order and eco.promoter_bonus(bar)==0,"Expired promoter stops attracting without cancelling existing visit commission")
	bar.stage = 2
	m.street.action("rehire",0)
	m.street.action("train_audience",0)
	test.check(bar.team[0].audience_training==1 and eco.promoter_bonus(bar)==6.0,"Stage-two training improves promoter attraction")
	m.street.action("train_audience",0)
	test.check(bar.team[0].audience_training==1,"Second audience training needs stage three")
	eco.advance_contracts(14400)
	m.street.action("rehire",0)
	test.check(bar.team[0].audience_training==1,"Audience training survives expiry and rehire")
	# Test discounted orders and attribution to a running promotion.
	m = Campaign.new(72)
	m.s.cash = 20000
	bar = m.street.selected()
	eco = m.street.economy
	m.street.action("hire",3)
	bar.customers.clear()
	m.street.action("promotion",1)
	eco.admit(bar,true)
	test.check(bar.customers[0].quoted==44,"Happy Hour quotes the discounted price")
	eco.serve(bar,1)
	test.check(bar.commission_paid==4 and bar.commission_carry==40 and bar.promo.commission==4,"Discount commission is based on actual drinks and enters promotion costs")
	bar.customers.clear()
	money = m.s.cash
	eco.serve(bar,1)
	test.check(m.s.cash==money and bar.commission_paid==4,"No order creates neither sale nor commission")
	# Offline consumes complete packs using newly generated cash only.
	m = Campaign.new(72)
	m.s.cash = 20000
	bar = m.street.selected()
	m.street.action("hire",0)
	m.street.action("hire",3)
	bar.manager = true
	bar.restock = true
	bar.equipment.pool = 0
	m.s.street.last_seen = 1000
	money = m.s.cash
	var old_stock: int = bar.stock
	var old_sold: int = bar.sold
	var gain: int = m.street.claim_offline(1120)
	test.check(gain>=0 and m.s.cash==money+gain and bar.sold==old_sold,"Offline credits estimates without changing live sale counters or starting cash")
	test.check(bar.stock<old_stock and bar.commission_paid>0,"Offline consumes owned stock and pays promoter commission")
	var once := [m.s.cash,bar.stock,bar.commission_carry,bar.commission_paid,bar.team.duplicate(true),bar.offline_sales_credit,bar.offline_cost_pending]
	m.street.claim_offline(1120)
	test.check([m.s.cash,bar.stock,bar.commission_carry,bar.commission_paid,bar.team,bar.offline_sales_credit,bar.offline_cost_pending]==once,"Repeated offline claim does not duplicate pack or commission settlement")
	bar.stock = 0
	money = m.s.cash
	m.street.claim_offline(1180)
	test.check(m.s.cash==money and bar.stock==0,"Empty-fridge offline operation cannot spend the opening reserve on a pack")
	# Complete supplier packs preserve the next real-second operating charge.
	m = Campaign.new(72)
	bar = m.street.selected()
	eco = m.street.economy
	bar.stock = 0
	bar.restock = true
	m.s.cash = 84
	test.check(not eco.restock(bar,true) and bar.stock==0 and m.s.cash==84,"Supplier keeps operating reserve rather than buying an unaffordable pack")
	m.s.cash = 85
	test.check(eco.restock(bar,true) and bar.stock==6 and m.s.cash==1,"Supplier buys exactly six once with sufficient working cash")
	# Premium drinks pay commission; paid pool never does.
	m = Campaign.new(72)
	m.s.cash = 100000
	bar = m.street.selected()
	eco = m.street.economy
	m.street.action("hire",3)
	bar.customers[0].quoted = 120
	eco.serve(bar,1)
	test.check(bar.commission_paid==12,"Commission uses the actual premium drink receipt")
	bar.equipment.pool = 1
	for customer in bar.customers: customer.pool = true
	eco.pool_tick(bar)
	test.check(bar.shift.pool_income==50 and bar.commission_paid==12,"A paid pool game charges once and owes no drink commission")
	# Seven-person roster survives saves: six floor workers plus frontage.
	bar.stage = 3
	for i in 6: m.street.action("hire",0)
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().team.size()==7,"Six floor staff and one promoter round-trip together")
	bar.commission_carry = 100
	m.save_game()
	test.check(m._read(Campaign.SAVE)==null,"Corrupt commission carry is rejected for backup recovery")
	bar.commission_carry = 0
	bar.team[0].audience_training = 3
	m.save_game()
	test.check(m._read(Campaign.SAVE)==null,"Out-of-range audience training is rejected")
	# Dancer training improves only that worker's audience contribution.
	m = Campaign.new(72)
	m.s.cash = 100000
	bar = m.street.selected()
	eco = m.street.economy
	bar.type = 2
	m.street.action("hire",2)
	m.street.action("train_audience",0)
	test.check(bar.team[0].audience_training==0,"Stage-one dancers cannot purchase stage-two training")
	bar.stage = 2
	var before_dancer: float = eco.attraction(bar)
	m.street.action("train_audience",0)
	test.check(eco.attraction(bar)>before_dancer and eco.service_rate(bar)==0,"Trained dancers attract but cannot serve")
	bar.stage = 3
	m.street.action("train_audience",0)
	eco.advance_contracts(14400)
	m.street.action("rehire",0)
	test.check(bar.team[0].audience_training==2,"Both dancer training tiers survive contract expiry")
	# Repeated short offline claims retain both fractional sales and their costs.
	var whole = offline_model()
	var split = offline_model()
	whole.street.claim_offline(1120)
	for timestamp in range(1001,1121): split.street.claim_offline(timestamp)
	test.check(whole.s.cash==split.s.cash and whole.street.selected().stock==split.street.selected().stock and whole.street.selected().commission_paid==split.street.selected().commission_paid,"Splitting an offline claim cannot mint drinks or avoid operating/commission costs")
	whole = offline_model()
	bar = whole.street.selected()
	bar.stock = 6
	var initial_cash: int = whole.s.cash
	whole.street.claim_offline(1700)
	var report: Dictionary = whole.s.street.offline_report
	test.check(whole.s.cash>=initial_cash and report.net==report.income-report.costs and bar.stock>=0 and bar.stock<6,"Offline pack purchases preserve cash and reconcile the projected ledger")
	test.check(str(report.notes).contains("deliveries of 6") and bar.commission_paid>0,"Offline report discloses packs and settled commission")
	whole = offline_model()
	split = offline_model()
	whole.street.selected().consignment = 6
	whole.street.claim_offline(1120)
	split.street.claim_offline(1120)
	test.check(split.s.cash-whole.s.cash==(6-int(whole.street.selected().consignment))*14,"Offline recovery drinks repay Bo once on estimated sale")
	# Old v5 saves gain no free hires, seating or fees.
	m = Campaign.new(72)
	m.s.version = 5
	bar = m.street.selected()
	bar.equipment.seating = 2
	for key in Economy.promoter_fields(): bar.erase(key)
	for customer in bar.customers:
		customer.erase("commission_order")
		customer.erase("commission_visit")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().equipment.seating==2 and loaded.s.cash==200 and loaded.street.selected().team.is_empty(),"V5 migration preserves progress without free purchases or fees")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

	# Expired frontage contracts retain their slot; quote the whole cash requirement.
	m = Campaign.new(72)
	m.s.cash = 20000
	bar = m.street.selected()
	eco = m.street.economy
	m.street.action("hire",0)
	m.street.action("hire",0)
	m.street.action("hire",3)
	bar.team[2].audience_training = 1
	bar.team[2].contract_left = 1
	eco.advance_contracts(1)
	var offer: Dictionary = eco.rehire_offer(bar,2)
	m.s.cash = int(offer.required)-1
	var before_rehire := JSON.stringify(m.s)
	var refusal: String = m.street.action("rehire",2)
	test.check(refusal.contains("Need ฿1 more") and not eco.contracted(bar.team[2]),"Nida renewal explains exact shortfall, including stock and payroll reserve")
	test.check(m.s.cash==int(offer.required)-1 and bar.team.size()==3,"Rejected rehire charges nothing and preserves the full roster")
	before_rehire = JSON.stringify(m.s)
	eco.rehire_offer(bar,2)
	test.check(JSON.stringify(m.s)==before_rehire,"Renewal quote is a pure read")
	m.s.cash = offer.required
	m.street.action("rehire",2)
	test.check(m.s.cash==offer.reserve and bar.team[2].on and bar.team[2].audience_training==1 and eco.contracted(bar.team[2]),"Exact renewal threshold rehires Nida even with all floor positions occupied")
	money = m.s.cash
	m.street.action("rehire",2)
	test.check(m.s.cash==money and bar.team.size()==3,"Repeated renew clicks cannot charge twice or create a second Nida")

func offline_model():
	var m = Campaign.new(72)
	m.s.cash = 100000
	var bar: Dictionary = m.street.selected()
	m.street.action("hire",0)
	m.street.action("hire",3)
	bar.manager = true
	bar.restock = true
	bar.equipment.fridge = 1
	bar.stock = 70
	m.s.street.last_seen = 1000
	return m
