extends "res://tests/economy_balance.gd"

func run() -> void:
	var failures := 0
	for seed_value in [11,72,291]:
		var opening_times := []
		for kind in 3:
			var result := simulate(seed_value,"balanced",600,"manual",true,"",kind)
			result.expansion_type = C.TYPES[kind].name
			print(JSON.stringify(result))
			opening_times.append(result.second)
			if result.stage3<0 or result.cash<0 or result.sales>result.orders or result.arrivals>result.offered+3: failures += 1
		if not (opening_times[0]<opening_times[1] and opening_times[1]<opening_times[2]): failures += 1
	print("LEASE ROUTES · %d failures across nine fresh expansion campaigns" % failures)
	quit(1 if failures else 0)
