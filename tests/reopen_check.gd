extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func run(test: SceneTree) -> void:
	var app = load("res://main.tscn").instantiate()
	test.root.add_child(app)
	app.set_process(false)
	app.start_new_game()
	app.model = Campaign.new(72)
	app.model.s.street.minute = 900
	var shut: Dictionary = app.model.street.selected()
	shut.open = false
	shut.close_reason = "Cannot pay rent, electricity or on-duty wages. Close and count tips to restock."
	app.model.s.cash = 0
	app.render()
	test.check(app.skip_to_open.visible and app.skip_to_open.disabled,"Closed venue exposes the exact reopening shortfall on the main screen")
	app.model.s.cash = 500
	var snapshot: Dictionary = app.model.s.duplicate(true)
	app.update_action_controls()
	test.check(app.skip_to_open.visible and not app.skip_to_open.disabled and app.skip_to_open.text=="Reopen bar" and app.model.s==snapshot,"Recovered cash enables the main-screen reopening button without spending or auto-opening")
	test.check(app.City.closure_title(shut,900)=="CLOSED / REOPEN WHEN READY","Cash and owner closures are not presented as timed incident closures")
	test.check(app.model.street.economy.status(shut).contains("Tap Reopen bar"),"Restored cash replaces the stale cash-shortage warning with the next action")
	var remaining_stock := int(shut.stock)
	app.skip_to_open.pressed.emit()
	test.check(shut.open and app.model.street.economy.is_trading(shut) and app.model.s.cash==500 and shut.stock==remaining_stock,"Reopen at 3pm resumes trading without a fee, gifts or lost stock")
	app.queue_free()
	await test.process_frame
