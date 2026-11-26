extends RefCounted
const Campaign = preload("res://scripts/campaign.gd")

func closing():
	var m = Campaign.new(72)
	m.s.street.minute = 59
	m.street.selected().dirt = 80
	m.street.tick(1)
	return m

func run(test: SceneTree) -> void:
	var m = closing()
	var b: Dictionary = m.street.selected()
	test.check(m.s.street.night_prep.remaining==15 and b.clean_remaining==15 and not b.manager,"Closure gives every bar a full fifteen-second automatic clean")
	var before := [m.s.cash,b.stock,b.sold,m.s.day]
	m.street.tick(14)
	test.check(m.s.street.minute==74 and b.dirt==80 and m.s.street.night_prep.remaining==1,"The jump cannot fire before the full cancellation window")
	m.street.tick(1)
	test.check(m.s.street.minute==720 and b.dirt==0 and b.clean_remaining==0 and before==[m.s.cash,b.stock,b.sold,m.s.day],"Automatic noon jump cleans without purchases, income or a second date increment")
	m = closing()
	m.street.tick(14)
	m.street.action("stay")
	m.street.tick(30)
	test.check(m.s.street.minute==104 and m.street.selected().dirt==0 and m.s.street.night_prep.cancelled,"Last-second cancellation keeps time in prep while cleaning finishes")
	m.save_game()
	var loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.version==15 and loaded.s.street.night_prep.cancelled,"Cancellation survives reload")
	loaded.street.tick(20)
	test.check(loaded.s.street.minute==124,"Reload cannot restart the cancelled night's jump")
	loaded.street.action("skip")
	test.check(loaded.s.street.minute==720 and not loaded.s.street.night_prep.cancelled,"Manual skip remains available and resets tomorrow's choice")
	m = closing()
	m.street.tick(6)
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.street.night_prep.remaining==9,"Reload retains the remaining cancellation window")
	loaded.street.claim_offline(int(loaded.s.street.last_seen)+100)
	test.check(loaded.s.street.night_prep.remaining==9 and loaded.s.street.minute==66,"Offline estimates cannot consume cleaning or jump the live day")
	loaded.street.night_prep_visible = false
	loaded.street.tick(5)
	test.check(loaded.s.street.night_prep.remaining==9,"Hidden street views do not consume the cancellation opportunity")
	loaded.street.night_prep_visible = true
	loaded.street.tick(9)
	test.check(loaded.s.street.minute==720 and loaded.street.selected().dirt==0,"Visible foreground resumes the saved jump after cleaning")
	m = Campaign.new(72)
	m.s.cash = 100000
	m.s.rep = 100
	m.s.street.chapter = 1
	m.street.action("buy",1)
	m.street.action("late")
	m.s.street.minute = 59
	m.street.tick(1)
	test.check(m.s.street.night_prep.remaining==0,"A late venue delays street-wide clean-up")
	m.street.selected().closed = 20
	m.street.tick(1)
	test.check(m.s.street.night_prep.remaining==0,"A temporarily flooded late venue cannot trigger a night skip")
	m.s.street.minute = 179
	m.street.selected().closed = 0
	m.street.tick(1)
	test.check(m.s.street.night_prep.remaining==15,"The final 3am closure starts the countdown")
	m = Campaign.new(72)
	m.street.action("open")
	m.street.tick(20)
	test.check(m.s.street.night_prep.remaining==0,"Daytime manual closure never skips to another opening")
	m.s.version = 9
	m.s.street.erase("night_prep")
	m.save_game()
	loaded = Campaign.new(1)
	test.check(loaded.load_game() and loaded.s.street.night_prep.remaining==0 and loaded.s.cash==m.s.cash,"V9 migration preserves money without starting a countdown on load")
	loaded.s.street.night_prep.remaining = 16
	var file := FileAccess.open(Campaign.SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(loaded.s))
	file.close()
	test.check(loaded._read(Campaign.SAVE)==null,"Malformed countdown saves are rejected")
	for path in [Campaign.SAVE,Campaign.BACKUP]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
