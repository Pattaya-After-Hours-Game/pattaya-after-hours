extends Control
const Art = preload("res://scripts/art.gd")
const Content = preload("res://scripts/street_content.gd")
const INK = Color("#21131e")
const TEAL = Color("#73f5dc")
const PINK = Color("#f37ab0")
const GOLD = Color("#e8ba7b")
var clock := 0.0
var street_state: Dictionary = {}
var arrival_time := 0.0
var night := false
var godzilla := ""
var shot_flash := 0.0
var weather := 0
var guests := 0
var level := 1
var venue := 1
var rig := 0
var bars: Array = []
var selected_bar := 0
var street_event: Dictionary = {}
var service_flash := 0.0
var legacy_staff: Array = []
var font = ThemeDB.fallback_font
signal site(tab: int)
signal select_bar(index: int)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	arrival_time += delta
	service_flash = maxf(0,service_flash-delta)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(960,540))
	var bar: Dictionary = bars[selected_bar] if not bars.is_empty() else {"type":0,"stage":clampi(level,1,3),"crew":legacy_staff.size(),"away":[],"closed":0,"name":"Blue Hour"}
	var kind := int(bar.type)
	var stage := int(bar.stage)
	var backdrop := Art.venue(kind,stage)
	if backdrop: draw_texture_rect(backdrop,Rect2(0,0,960,540),false)
	var closed: bool = bar.closed > 0 or not bar.get("open",true)
	# Reuse the existing illustrated table as an equipment layer at stage one.
	# A second purchased table is another instance; artwork never awards income.
	if kind==0 and bar.has("equipment"):
		for table in int(bar.equipment.pool):
			if stage>1 and table==0: continue
			draw_texture_rect_region(Art.venue(0,2),Rect2(300-table*150,274,155,72),Rect2(300,274,155,72))
	# Background traffic stays outside the open frontage.
	Art.frame(self,"patrons",2,Vector2(fposmod(clock*18,145),355-absf(sin(clock*7))),.38)
	# Venue workers are separate sprites; absence removes them immediately.
	if not closed:
		var dancer_index := 0
		for i in int(bar.crew):
			if i in bar.away or (bar.has("team") and i < bar.team.size() and not bar.team[i].on): continue
			var role: int = int(bar.team[i].role) if bar.has("team") and i < bar.team.size() else (2 if kind==2 else 0)
			var who: String = Art.worker_id(bar,i)
			if bars.is_empty() and i < legacy_staff.size():
				if not legacy_staff[i].work or legacy_staff[i].hurt: continue
				who = Art.STAFF[int(legacy_staff[i].id)]
			var base := Vector2(270+(i%3)*155,345+(i/3)*32)
			var cycle := fposmod(clock+i*1.7,9.0)
			var state := "idle"
			var flip := false
			if role == 2 and dancer_index < stage and (street_state.is_empty() or int(street_state.seconds) in range(40,80)):
				var poles: Array = [[478],[402,545],[400,476,549]][stage-1]
				base = Vector2(poles[dancer_index]-19,303)
				dancer_index += 1
				state = "dance"
			elif cycle<4:
				base.x += (cycle if cycle<2 else 4-cycle)*22
				state = "walk"
				flip = cycle>=2
			elif cycle<7: state = "serve"
			var pose := Art.animation_frame(who,state,clock+i,2 if state=="dance" else 1.6 if state=="walk" else 2)
			Art.frame(self,who,pose,base,.64,flip,Vector2.ZERO,Color.WHITE,Vector2(1,1+.006*sin(clock*3+i)))
		var crowd: int = bar.customers.size() if bar.has("customers") else mini(8,guests)
		for i in crowd:
			var place := Vector2(185+(i%8)*53,365+(i/8)*23)
			if bar.has("customers") and bar.customers[i].playing:
				for game in bar.games:
					var player: int = game.players.find(bar.customers[i].id)
					if player>=0: place = Vector2(315-int(game.get("table",0))*150+player*110,335)
			Art.frame(self,"patrons",i%4,place,.55, i%2 == 1,Vector2.ZERO,Color.WHITE,Vector2(1,1+.008*sin(clock*2+i)))
			if bar.has("customers") and bar.customers[i].order: draw_circle(place+Vector2(0,-53),3,GOLD)
	if bar.has("games") and bar.equipment.pool>0:
		# Status is model-owned; the artwork never creates a pool fee.
		for i in int(bar.equipment.pool):
			var p := Vector2(300-i*150,306)
			draw_style_box(_sign_box(),Rect2(p,Vector2(145,31)))
			var label := "POOL / ฿50"
			for game in bar.games:
				if int(game.get("table",0))==i: label = "%ds / %s" % [game.remaining,"FREE" if game.fee==0 else "PAID"]
			draw_string(font,p+Vector2(7,21),label,HORIZONTAL_ALIGNMENT_LEFT,135,16,GOLD)
	if kind==0 and stage>1 and bar.has("equipment") and bar.equipment.pool==0:
		draw_style_box(_sign_box(),Rect2(300,306,155,31))
		draw_string(font,Vector2(307,327),"POOL / NOT OPEN",HORIZONTAL_ALIGNMENT_LEFT,145,14,GOLD)
	# Anong remains available at the service position even before the first hire.
	var idle := 0 if service_flash <= 0 else 3
	Art.frame(self,"anong-service",idle,Vector2(760,470),1.35,false,Vector2.ZERO,Color.WHITE,Vector2(1,1+.005*sin(clock*2)))
	# Foreground bar layer occludes the bartender's legs, never the interface.
	Art.image(self,"counter",Rect2(560,365,400,118))
	# Exact signage is live text, not lettering baked into generated artwork.
	var sign_name: String = "BLUE HO" if selected_bar == 0 and stage == 1 else str(bar.name).to_upper()
	draw_style_box(_sign_box(),Rect2(665,73,230,40))
	var neon: Color = [TEAL,PINK,GOLD][kind]
	neon = neon.darkened(.025+.025*sin(clock*2.3))
	draw_string(font,Vector2(676,101),sign_name,HORIZONTAL_ALIGNMENT_CENTER,208,24,neon)
	# The fan blades rotate over the centre of the illustrated fan cage.
	if kind != 1:
		var fan := Vector2(502,122) if kind==0 else Vector2(266,92)
		for i in 3:
			var ray := Vector2.from_angle(clock*9+i*TAU/3)*23
			draw_line(fan+ray*.22,fan+ray,Color("#8e5e5670"),5)
	if closed:
		draw_rect(Rect2(0,0,960,540),Color(0.08,0.03,0.09,.55))
		draw_string(font,Vector2(260,275),"TEMPORARILY CLOSED",HORIZONTAL_ALIGNMENT_CENTER,440,30,GOLD)
	_draw_event()
	if weather >= 5:
		for i in 65:
			var p := Vector2(fposmod(i*53-clock*40,180),fposmod(i*71+clock*250,540))
			draw_line(p,p+Vector2(-3,13),Color("#92c7dc70"),1)
	if godzilla in ["attack","asleep"]:
		var state := 3 if godzilla == "asleep" else 2 if shot_flash > .1 else 1 if arrival_time > 1.0 else int(arrival_time*4)%2
		Art.frame(self,"monster",state,Vector2(400-maxf(0,1-arrival_time)*500,460),1.2,false,Vector2(320,320),Color.WHITE,Vector2(1,1+.012*sin(clock*(1.5 if state==3 else 3))))
		if shot_flash > .1: draw_circle(Vector2(445,255),9*shot_flash,Color(1,.8,.3,shot_flash*.6))

func _sign_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#1c1828")
	s.border_color = GOLD.darkened(.35)
	s.set_border_width_all(1)
	return s

func _draw_event() -> void:
	if street_event.get("phase","") != "active": return
	var id := int(street_event.get("id",-1))
	match id:
		0:
			if not street_event.get("prepared",false): draw_rect(Rect2(0,0,960,540),Color(0.02,.01,.06,.65))
		1:
			for i in 4: Art.frame(self,"patrons",i,Vector2(90+i*44,395),.52)
			for i in 7:
				var p := Vector2(14+i*25,85+sin(clock*2+i)*2)
				draw_colored_polygon(PackedVector2Array([p,p+Vector2(18,3),p+Vector2(9,24)]),Color("#bcdbe3") if i%2 else Color("#27467a"))
		2:
			Art.image(self,"event-inspection",Rect2(140,290,90,110))
		3:
			draw_rect(Rect2(0,350,960,190),Color(.12,.52,.64,.42))
			for i in 20:
				var x := fposmod(i*71+clock*35,960)
				draw_line(Vector2(x,360+i%9*9),Vector2(x+40,360+i%9*9),Color("#91e4e880"),2)
		4:
			# Songkran water jets and splash rings are separate from flood water.
			for i in 18:
				var t := fposmod(clock*.6+i*.17,1.0)
				var p := Vector2(30+t*300,380-sin(t*PI)*140+i%3*14)
				draw_circle(p,2+i%2,Color("#a0eaffb0"))
			for i in 9:
				var t := fposmod(clock+i*.23,1.0)
				draw_arc(Vector2(80+i*79,380+i%3*12),5+t*18,0,TAU,18,Color(.4,.85,1,(1-t)*.6),1)
		5:
			for i in 4:
				var p := Vector2(90+i*44,395)
				Art.frame(self,"patrons",i,p,.52)
				var burst := maxf(0,sin(clock*3+i*7)-.92)*12
				if burst>0:
					p += Vector2(14,-60)
					draw_line(p-Vector2(8,0),p+Vector2(8,0),Color(1,1,1,burst),2)
					draw_line(p-Vector2(0,8),p+Vector2(0,8),Color(1,1,1,burst),2)
		6:
			draw_rect(Rect2(0,0,960,540),Color(.16,.13,.24,.18))
		7:
			draw_rect(Rect2(0,0,100,540),Color(.8,.15,.45,.1+.07*sin(clock*4)))
		8:
			draw_rect(Rect2(0,0,180,540),Color(.08,.12,.2,.2))
		9:
			for i in 32:
				var p := Vector2(fposmod(i*59+sin(clock+i)*13,960),fposmod(i*83+clock*38,540))
				draw_rect(Rect2(p,Vector2(3,7)),[TEAL,PINK,GOLD][i%3])
