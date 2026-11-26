extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
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
		var cash_before: int = m.s.cash
		e.serve(b)
		test.check(m.s.cash==cash_before+quote and b.shift.consumed_stock==38,"Standard sale settles its venue price and actual stock cost")
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
	m.s.cash = 987
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.cash==987,"Price update preserves the saved cash balance")
	b = loaded.street.selected()
	var e = loaded.street.economy
	test.check(b.stock_lots==[{"units":5,"cost":6},{"units":7,"cost":14}] and b.customers[0].quoted==55,"Old supplier costs and waiting quotes survive reload unchanged")
	e.serve(b)
	test.check(loaded.s.cash==1042 and b.shift.consumed_stock==6,"An old tab settles once at its saved price using its original paid stock cost")
	b.customers[0].next = 0
	e.order(b,b.customers[0])
	test.check(b.customers[0].quoted==e.price(b,int(b.customers[0].drink)) and b.customers[0].budget==155,"Only the next round adopts the new price; old customer budgets are preserved")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
