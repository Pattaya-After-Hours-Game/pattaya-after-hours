extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")
const Fixture = preload("res://tests/recruit_fixture.gd")

func run(test: SceneTree) -> void:
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	var e = m.street.economy
	m.s.cash = 20000
	var before := JSON.stringify(m.s)
	e.end_contract_offer(b,0)
	e.upgrade_impact(b,"equipment",0)
	test.check(JSON.stringify(m.s)==before,"Contract and upgrade forecasts never spend, simulate or roll")
	m.street.action("hire_gabby")
	test.check(b.team.is_empty() and not m.s.street.has("hiring_seed"),"Direct named hiring cannot bypass the random pool")
	Fixture.named(m.street,"gabby")
	var person: Dictionary = b.team[0]
	e.staff_service(b)
	person.training = 2
	person.contract_left = 11520
	person.service_ready = 24.75
	var cash_before: int = m.s.cash
	var jar: int = e.pending_tips(b)
	var sample: int = m.s.street.earnings_net
	var quote: Dictionary = e.end_contract_offer(b,0)
	test.check(quote.refund==768 and quote.remaining==11520,"Twenty percent elapsed refunds 64 percent of the paid contract")
	e.end_contract(b,0,person)
	test.check(b.team.is_empty() and m.s.cash==cash_before+768 and e.pending_tips(b)==jar and m.s.street.earnings_net==sample,"Exit frees the slot, refunds once and leaves tips and trading sample untouched")
	before = JSON.stringify(m.s)
	e.end_contract(b,0,person)
	test.check(JSON.stringify(m.s)==before,"Repeated exit input cannot refund twice")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game(),"Dismissed Gabby's earned tips and training archive remain valid after reload")
	b = loaded.street.selected()
	Fixture.named(loaded.street,"gabby")
	test.check(b.team[0].training==2 and b.team[0].service_ready==24.75 and b.team[0].contract_paid==1200,"Rediscovery restores personal training and cooldown but charges a fresh full contract")
	test.check(loaded.street.economy.end_contract_offer(b,0).refund==960,"Immediate rerolls always lose at least twenty percent of the contract price")
	# Old callback points at the old worker, not the next person occupying that slot.
	cash_before = loaded.s.cash
	loaded.street.economy.end_contract(b,0,person)
	test.check(loaded.s.cash==cash_before and b.team.size()==1,"Stale UI callbacks cannot dismiss replacement staff")
	b.team[0].contract_left = 0
	test.check(loaded.street.economy.end_contract_offer(b,0).refund==0,"An expired contract has no unused refund")
	# Ending an earlier slot must preserve bookings/away indices belonging to others.
	m = Campaign.new(72)
	b = m.street.selected()
	e = m.street.economy
	m.s.cash = 20000
	b.stage = 3
	e.hire_staff(b,0)
	e.hire_staff(b,0)
	b.away = [1]
	b.host_rounds = [{"host":1}]
	m.s.street.event = {"runner":1,"venue":0}
	before = JSON.stringify(m.s)
	e.end_contract(b,1)
	test.check(JSON.stringify(m.s)==before,"Busy workers cannot be dismissed mid-booking or while away")
	e.end_contract(b,0)
	test.check(b.team.size()==1 and b.away==[0] and b.host_rounds[0].host==0 and m.s.street.event.runner==0,"Roster removal preserves other workers' live booking and event references")
	m = Campaign.new(72)
	b = m.street.selected()
	e = m.street.economy
	m.s.cash = 20000
	Fixture.named(m.street,"gabby")
	e.end_contract(b,0)
	m.s.street.afk = true
	cash_before = m.s.cash
	m.street.afk_tick()
	test.check(b.team.is_empty() and m.s.cash==cash_before,"AFK cannot renew a deliberately ended contract")
	e.hire_staff(b,3)
	before = JSON.stringify(m.s)
	e.end_contract(b,0)
	test.check(JSON.stringify(m.s)==before,"Nida retains her separate frontage slot and off-duty control")
	m.s.street.former_staff.gabby.training = 1.5
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded._read(Campaign.SAVE)==null,"Fractional archived training is rejected instead of silently rerolled")
	for day in [3,5]:
		m = Campaign.new(72)
		b = m.street.selected()
		e = m.street.economy
		m.s.day = day
		m.s.street.minute = 1079
		m.street.celebration_tick()
		test.check(not e.celebrating(b),"Opening-week nights wait until 6pm")
		m.s.street.minute = 1080
		cash_before = m.s.cash
		m.street.celebration_tick()
		test.check(e.celebrating(b) and m.s.cash==cash_before and m.s.street.celebration.report.sales==0,"Opening-week events create opportunity, never free income")
		before = JSON.stringify(m.s)
		m.street.celebration_info()
		e.forecast(b)
		test.check(JSON.stringify(m.s)==before,"Opening-week forecasts remain read-only")
		test.check(e.repeat_order_seconds(b)<35 and e.repeat_order_seconds(b)>26,"Opening-week drinking is livelier but less boosted than day seven")
		m.save_game()
		loaded = Campaign.new(2)
		test.check(loaded.load_game() and loaded.street.economy.celebrating(loaded.street.selected()),"Opening-week report and timing survive reload")
		m.s.street.minute = 1320
		m.street.celebration_tick()
		test.check(not e.celebrating(b) and m.s.street.celebration.last_report.day==day,"The four-hour opening night ends without a repeat payout")
