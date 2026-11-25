extends "res://tests/economy_balance.gd"

func run() -> void:
	var failures := 0
	for feature in ["promoter-first","service-first","compact-first"]:
		for seed_value in [11,72,291]:
			var result := simulate(seed_value,"balanced",600,"manual",true,feature)
			print(JSON.stringify(result))
			if result.stage3<0 or result.cash<0 or result.sales>result.orders or result.arrivals>result.offered+3:
				printerr("FEATURE PACING FAIL: "+feature)
				failures += 1
			if feature!="compact-first" and result.promoter<0: failures += 1
			if result.compact<0: failures += 1
	# Manual alternatives retain a path without buying attraction automation.
	for seed_value in [11,72,291]:
		var result := simulate(seed_value,"balanced",600,"manual",false)
		print(JSON.stringify(result))
		if result.stage3<0 or result.cash<0: failures += 1
	print("PROMOTER PACING · %d failures across twelve feature/alternative campaigns" % failures)
	quit(1 if failures else 0)
