extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
	supplier_special(test)
	supplier_auto_restock(test)
	for kind in 3:
		var m = Campaign.new(72)
		var b: Dictionary = m.street.selected()
		var e = m.street.economy
		b.type = kind
		b.customers.clear()
		e.admit(b,false,true)
		var guest: Dictionary = b.customers[0]
		var quote: int = [80,100,120][kind]
		test.check(guest.quoted==quote,"Venue price ladder quotes each real customer's first order")
		var cash_before: int = m.street.selected().cash
		e.serve(b)
		test.check(m.street.selected().cash==cash_before+quote and b.shift.consumed_stock==38,"Standard sale settles its venue price and actual stock cost")
		b.stage = 3
		test.check(e.price(b)==quote,"Renovation does not multiply the venue's standard drink price")
		b.equipment.menu = 1
		test.check(e.price(b,3)==quote+30,"Premium menu surcharge stays separate from standard prices")
		b.promo = {"kind":1}
		test.check(e.price(b)==[64,80,96][kind],"Happy Hour discounts new quotes across all venue types")
	# Updating prices must neither revalue old inventory nor rewrite waiting tabs.
	var m = Campaign.new(72)
	var b: Dictionary = m.street.selected()
	b.stock_lots = [{"units":5,"cost":6},{"units":7,"cost":14}]
	b.customers[0].quoted = 55
	b.customers[0].budget = 210
	m.street.selected().cash = 987
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.street.selected().cash==987,"Price update preserves the saved cash balance")
	b = loaded.street.selected()
	var e = loaded.street.economy
	test.check(b.stock_lots==[{"units":5,"cost":6},{"units":7,"cost":14}] and b.customers[0].quoted==55,"Old supplier costs and waiting quotes survive reload unchanged")
	e.serve(b)
	test.check(loaded.street.selected().cash==1042 and b.shift.consumed_stock==6,"An old tab settles once at its saved price using its original paid stock cost")
	b.customers[0].next = 0
	e.order(b,b.customers[0])
	test.check(b.customers[0].quoted==e.price(b,int(b.customers[0].drink)) and b.customers[0].budget==155,"Only the next round adopts the new price; old customer budgets are preserved")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func supplier_auto_restock(test: SceneTree) -> void:
	var model := Campaign.new(72)
	var bar: Dictionary = model.street.selected()
	var eco = model.street.economy
	model.street.selected().cash = 5000
	model.street.action("buy_drink",2)
	for unit in 6: eco.consume_stock(bar,2)
	var guest: Dictionary = bar.customers[0]
	guest.drink = 2
	guest.lager_quote = 0
	guest.quoted = eco.price(bar,2)
	var cash_before: int = model.street.selected().cash
	test.check(eco.serve(bar)==1 and guest.order and model.street.selected().cash==cash_before+80,"Before the supplier upgrade, only the other guest can be served")
	model.street.action("restock")
	cash_before = model.street.selected().cash
	test.check(eco.serve(bar)==1 and not guest.order and eco.stock_of(bar,2)==5 and model.street.selected().cash==cash_before-114+int(guest.quoted),"After the upgrade, a real rum order buys a paid pack and uses one drink")

func supplier_special(test: SceneTree) -> void:
	var m := Campaign.new(72)
	var bar: Dictionary = m.street.selected()
	var eco = m.street.economy
	m.s.street.served = 10
	bar.regulars = 1
	m.street.selected().cash = 4900
	m.s.street.minute = 839
	m.street.tick(1)
	var quote: Dictionary = m.street.supplier_deal_offer()
	test.check(quote.drink==2 and quote.quantity==12 and quote.price==168 and quote.normal==228,"Bo offers twelve rums at the actual discounted wholesale price")
	test.check(quote.goal_name=="Blue Hour renovation" and m.street.selected().cash>=quote.target and quote.remaining_cash<quote.target,"The quote reveals when the discount would put a saved-up renovation out of reach")
	var stock: int = bar.stock
	var total: int = m.street.selected().cash
	m.street.action("supplier_deal")
	test.check(m.street.selected().cash==total-quote.price and eco.stock_of(bar,2)==12 and bar.stock==stock+12,"The deal buys real stock for the quoted price")
	test.check(bar.stock_lots.back().cost==quote.unit and bar.shift.stock_cost==quote.price,"The receipt preserves discounted cost for sales and returns")
	m.save_game()
	var loaded := Campaign.new(1)
	test.check(loaded.load_game(),"A bought supplier offer persists across reload")
	loaded.street.supplier_deal_tick()
	var after: int = loaded.street.selected().cash
	loaded.street.action("supplier_deal")
	test.check(loaded.street.selected().cash==after and loaded.street.supplier_deal_offer().is_empty(),"Reloading cannot redeem the pack again")
	loaded.s.day = 4
	loaded.street.selected().equipment.menu = 1
	loaded.street.supplier_deal_tick()
	test.check(loaded.street.supplier_deal_offer().drink==3,"The premium menu unlocks mango specials on future deal days")
	loaded.street.selected().stock = 30
	test.check(not loaded.street.supplier_deal_offer().enabled,"The offer respects fridge capacity")
	loaded.s.street.minute = 915
	test.check(loaded.street.supplier_deal_offer().is_empty(),"The supplier offer expires at 3:15pm")

func run_ui(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	await test.process_frame
	app.set_process(false)
	app.boot_menu = false
	app.model = Campaign.new(72)
	app.model.s.street.minute = 840
	app.model.street.supplier_deal_tick()
	app.render()
	app._process(1)
	test.check(app.supplier_special_open and app.model.s.street.supplier_deal.seen,"The deal pops up once without advancing the clock")
	var cash_before: int = app.model.street.selected().cash
	test.use_button(app,"Not now")
	test.check(not app.supplier_special_open and app.model.street.selected().cash==cash_before,"Passing on the deal spends nothing")
	app.open_fridge()
	test.use_button(app,"Bo’s special · save ฿60")
	test.use_button(app,"Buy pack · ฿168")
	test.check(not app.supplier_special_open and app.model.street.selected().cash==cash_before-168,"The fridge can reopen and redeem a dismissed deal")
	app.queue_free()
	await test.process_frame
