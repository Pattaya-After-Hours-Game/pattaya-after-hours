extends RefCounted
const Fight = preload("res://scripts/fight.gd")

func run(test: SceneTree) -> void:
	var fight := Fight.new()
	test.root.add_child(fight)
	fight.set_physics_process(false)
	# Both directions, real frame ticks, and the spacing at which the CPU waits.
	for facing in [-1,1]:
		fight.reset_round()
		fight.countdown = 0
		fight.ai_timer = 999
		var player: Dictionary = fight.fighters[0]
		var rival: Dictionary = fight.fighters[1]
		player.x = 160.0
		rival.x = player.x + 31*facing
		player.facing = facing
		rival.facing = -facing
		fight._attack(player,"jab")
		for i in 12: fight._physics_process(1.0/60.0)
		test.check(rival.hp == 92 and fight.hitstop >= 0,"Punch lands once at CPU spacing in either direction")
		fight._resolve(player,rival,.3)
		test.check(rival.hp == 92,"Recovery never duplicates a hit")
	fight.reset_round()
	var player: Dictionary = fight.fighters[0]
	var rival: Dictionary = fight.fighters[1]
	rival.x = player.x+30
	fight._attack(player,"jab")
	fight._resolve(player,rival,.24)
	test.check(rival.hp == 92,"A slow frame crossing the entire active window still detects contact")
	fight.reset_round()
	player = fight.fighters[0]
	rival = fight.fighters[1]
	rival.x = player.x+24
	fight._attack(player,"uppercut")
	fight._resolve(player,rival,.17)
	test.check(rival.launched and rival.vy < -190 and fight.hitstop > 0,"Uppercut launches with a real upward impulse and hit pause")
	fight.countdown = 0
	var frozen_y: float = rival.y
	var frozen_time: float = fight.time_left
	fight._physics_process(.016)
	test.check(rival.y == frozen_y and fight.time_left == frozen_time,"Impact pause freezes both fighter motion and the round clock")
	var launch_x: float = rival.x
	fight._resolve(rival,player,.2)
	test.check(rival.y < Fight.FLOOR-30 and rival.x > launch_x+15,"Launched rival travels up and away")
	test.check(not fight._attack(rival,"jab"),"Launched rivals cannot attack during flight")
	for i in 75: fight._resolve(rival,player,1.0/60.0)
	test.check(rival.y == Fight.FLOOR and not rival.launched and rival.down == 0,"Landing and recovery complete without a stuck fighter")
	for blocked in [false,true]:
		fight.reset_round()
		player = fight.fighters[0]
		rival = fight.fighters[1]
		rival.x = player.x+25
		rival.guard = blocked
		rival.crouch = blocked
		fight._attack(player,"lowkick")
		fight._resolve(player,rival,.14)
		test.check(rival.hp == (98 if blocked else 88),"Low kick hits legs; crouch guard reduces its damage")
		test.check((rival.down > 0) == (not blocked),"Only an unblocked sweep knocks down")
	fight.reset_round()
	fight.countdown = 0
	fight.ai_timer = 999
	fight.fighters[1].x = fight.fighters[0].x+44
	fight.held = {KEY_RIGHT:"right",KEY_UP:"jump",KEY_K:"kick"}
	fight._physics_process(.016)
	fight.held.clear()
	test.check(fight.fighters[0].move == "flykick" and fight.fighters[0].vx > 0,"Jump plus kick selects a travelling flying kick")
	for i in 20: fight._physics_process(.016)
	test.check(fight.fighters[1].hp == 81 and fight.fighters[1].launched,"Flying kick connects through live input and launches the rival")
	fight.reset_round()
	fight.countdown = 0
	fight.ai_timer = 999
	fight.held = {KEY_RIGHT:"right",KEY_K:"kick"}
	fight._physics_process(.016)
	fight.held.clear()
	test.check(fight.fighters[0].move == "roundhouse","Forward plus kick retains the roundhouse")
	fight.reset_round()
	player = fight.fighters[0]
	rival = fight.fighters[1]
	rival.x = player.x+70
	fight._attack(player,"jab")
	fight._resolve(player,rival,.12)
	test.check(rival.hp == 100 and fight.hitstop == 0,"Out-of-range punches whiff without impact feedback")
	fight.reset_round()
	player = fight.fighters[0]
	rival = fight.fighters[1]
	rival.x = player.x+24
	rival.guard = true
	rival.crouch = true
	fight._attack(player,"uppercut")
	fight._resolve(player,rival,.17)
	test.check(rival.hp == 97 and not rival.launched,"Guarded uppercut chips without launching")
	fight.reset_round()
	fight.countdown = 0
	fight.ai_timer = 999
	player = fight.fighters[0]
	rival = fight.fighters[1]
	rival.hp = 5
	rival.x = player.x+24
	fight._attack(player,"uppercut")
	for i in 20: fight._physics_process(.016)
	test.check(fight.wins[0] == 1 and rival.launched and rival.y < Fight.FLOOR,"K.O. uppercut continues its airborne reaction after round scoring")
	for i in 70: fight._physics_process(.016)
	test.check(fight.wins[0] == 1 and rival.y == Fight.FLOOR,"K.O. lands without awarding another round")
	fight.queue_free()
	await test.process_frame
