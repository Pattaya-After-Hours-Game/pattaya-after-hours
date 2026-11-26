extends "res://tests/economy_balance.gd"

func run() -> void:
	var failures := 0
	for feature in ["music-first","auto-serve","supplier-first","automation-bundle","early-bartender","regulars-club","stage-two-bundle"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,"balanced",600,"manual",true,feature)
			print(JSON.stringify(result))
			if result.stage3<0 or result.cash<0 or result.sales>result.orders or result.arrivals>result.offered+3:
				printerr("AUTOMATION PACING FAIL: "+feature)
				failures += 1
			if feature in ["auto-serve","automation-bundle"] and (not result.auto_serve or result.pouring!=4): failures += 1
			if feature in ["music-first","automation-bundle"] and not result.music: failures += 1
			if feature in ["supplier-first","automation-bundle"] and result.supplier<3: failures += 1
			if feature=="regulars-club" and result.club!=3: failures += 1
			if feature=="stage-two-bundle" and (result.club!=3 or result.music!=2 or result.staff_training!=4): failures += 1
			if feature=="early-bartender" and (result.hire<0 or result.hire>600): failures += 1
	print("AUTOMATION PACING · %d failures across twenty-one feature campaigns" % failures)
	quit(1 if failures else 0)
