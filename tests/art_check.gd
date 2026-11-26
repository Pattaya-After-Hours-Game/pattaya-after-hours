extends RefCounted
const Art = preload("res://scripts/art.gd")

func run(test: SceneTree) -> void:
	test.check(Art.worker_id({"type":1,"team":[{"role":0,"host":-1},{"role":1,"host":0}]},1)=="bee","Mixed-team host artwork uses the assigned identity")
	test.check(Art.worker_id({"type":2,"team":[{"role":0,"host":-1}]},0)=="dao","Gogo bartenders use service artwork, not dancer artwork")
	var male_variants := {}
	for variant in Art.CUSTOMER_VARIANTS:
		test.check(Art.atlas_specs().has(variant[0]) and variant[1]>=0 and variant[1]<Art.atlas_specs()[variant[0]][1],"Customer appearance resolves to a valid atlas cell")
		if variant[0]=="patrons-men": male_variants[variant[1]] = true
	test.check(male_variants.size()==9,"All nine male customer sprites, including the supplied-reference guest, are reachable")
	test.check(Art.customer_sprite(9)==["patrons-men",Art.COBALT_IDLE],"The cobalt-shirt customer retains his existing appearance")
	var sunglasses_poses := []
	for time in [0.0,5.1,5.3,7.0,10.1,10.3,11.0,21.1]:
		sunglasses_poses.append(Art.cobalt_frame(time))
	test.check(sunglasses_poses==[6,9,10,11,10,9,6,9],"The cobalt-shirt guest puts his sunglasses on, takes them off and repeats")
	test.check(Art.customer_sprite(2)==["patrons-capybara",0] and Art.customer_sprite(26)==Art.customer_sprite(2),"The capybara regular appears at the opening and on later visits")
	var capybara_poses := []
	for time in [0.0,1.6,3.1,3.5,4.9,6.6,7.0,8.0]:
		capybara_poses.append(Art.capybara_frame(time))
	test.check(capybara_poses==[0,1,2,3,4,2,0,0],"Capybara blinks, lowers, sits, blinks again, stands and repeats")
	test.check(Art.customer_sprite(3)==["patrons-rainbow-duo",0] and Art.customer_sprite(35)==Art.customer_sprite(3),"The rainbow duo appears on opening day and returns on later visits")
	for kind in 3:
		for stage in range(1,4):
			var tex := Art.venue(kind,stage)
			test.check(tex != null,"Venue artwork exists: %d/%d" % [kind,stage])
			if tex: test.check(tex.get_size()==Vector2(960,540),"Venue uses presentation resolution")
			var front := Art.frontage(kind,stage)
			test.check(front != null and front.get_size()==Vector2(320,256),"Matching property frontage: %d/%d" % [kind,stage])
	# Composite variants may change only the equipment region. This protects
	# all surrounding production art, and exercises cache switching both ways.
	for kind in 3:
		for stage in range(1,4):
			var plain := Art.venue(kind,stage,false).get_image()
			var equipped := Art.venue(kind,stage,true).get_image()
			plain.convert(Image.FORMAT_RGBA8)
			equipped.convert(Image.FORMAT_RGBA8)
			var rect := Art.fan_region(kind)
			test.check(plain.get_region(rect).get_data()!=equipped.get_region(rect).get_data(),"Fan purchase visibly changes every venue stage")
			var strips := [Rect2i(0,0,960,rect.position.y),Rect2i(0,rect.end.y,960,540-rect.end.y),Rect2i(0,rect.position.y,rect.position.x,rect.size.y),Rect2i(rect.end.x,rect.position.y,960-rect.end.x,rect.size.y)]
			for strip in strips:
				test.check(plain.get_region(strip).get_data()==equipped.get_region(strip).get_data(),"Fan ownership preserves all pixels outside the equipment region")
			var cached := Art.venue(kind,stage,false).get_image()
			cached.convert(Image.FORMAT_RGBA8)
			test.check(cached.get_data()==plain.get_data(),"Switching fan state cannot mutate the cached unowned room")
			if kind!=1:
				var patch := Art.texture("fan-hidden-%s-%d" % [Art.TYPES[kind],stage])
				test.check(patch!=null and patch.get_size()==Vector2(rect.size),"Fan cover fits the illustrated fixture")
	var fan := Art.texture("wall-fan")
	test.check(fan!=null and fan.get_image().get_pixel(0,0).a==0,"Purchased Soi fan preserves transparent edges")
	for kind in 3:
		for stage in range(1,4):
			for has_fan in [false,true]:
				var plain := Art.venue(kind,stage,has_fan,false).get_image()
				var equipped := Art.venue(kind,stage,has_fan,true).get_image()
				var rect := Art.screen_region(kind,stage)
				test.check(plain.get_region(rect).get_data()!=equipped.get_region(rect).get_data(),"Sports screen purchase changes every room and fan combination")
				for strip in [Rect2i(0,0,960,rect.position.y),Rect2i(0,rect.end.y,960,540-rect.end.y),Rect2i(0,rect.position.y,rect.position.x,rect.size.y),Rect2i(rect.end.x,rect.position.y,960-rect.end.x,rect.size.y)]:
					test.check(plain.get_region(strip).get_data()==equipped.get_region(strip).get_data(),"Sports screen preserves the surrounding production artwork")
				test.check(Art.venue(kind,stage,has_fan,false).get_image().get_data()==plain.get_data(),"Switching properties cannot leak purchased TV artwork to another room")
	var fridge_region := Rect2i(Art.FRIDGE_ORIGIN,Art.FRIDGE_CELL)
	for stage in range(1,4):
		var before := Art.venue(0,stage,false,false,0).get_image().get_region(fridge_region).get_data()
		for tier in range(1,stage+2):
			var after := Art.venue(0,stage,false,false,tier).get_image().get_region(fridge_region).get_data()
			test.check(after!=before,"Each Blue Hour fridge purchase changes the cabinet at the same renovation stage")
			before = after
	for id in ["district","toybox","counter","event-inspection","compact-bench"]:
		test.check(Art.texture(id) != null,"Scene/prop artwork exists: "+id)
	for id in ["anong"]+Art.STAFF+Art.HOSTS+["juno","vega","orchid","nida","gabby","daisy"]:
		var tex := Art.texture("portrait-"+id)
		test.check(tex != null,"Portrait exists: "+id)
		if tex: test.check(tex.get_size()==Vector2(96,96),"Portrait dimensions: "+id)
	for id in Art.atlas_specs():
		var spec: Array = Art.atlas_specs()[id]
		var tex := Art.texture(id)
		test.check(tex != null,"Animated atlas exists: "+id)
		if not tex: continue
		var cell: Vector2 = spec[0]
		var frames: int = int(spec[1])
		test.check(int(tex.get_width())%int(cell.x)==0 and int(tex.get_height())%int(cell.y)==0,"Atlas has integral cells: "+id)
		var cols := int(tex.get_width()/cell.x)
		test.check(cols*int(tex.get_height()/cell.y)==frames,"Required animation frames: "+id)
		var img := tex.get_image()
		for n in frames:
			var frame := img.get_region(Rect2i(Vector2i(n%cols,n/cols)*Vector2i(cell),Vector2i(cell)))
			test.check(frame.get_used_rect().has_area(),"Nonempty pose: %s/%d" % [id,n])
			test.check(frame.get_pixel(0,0).a==0 and frame.get_pixel(int(cell.x)-1,int(cell.y)-1).a==0,"Transparent padded pose: %s/%d" % [id,n])
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/manifest.json"))
	for id in manifest:
		var item: Dictionary = manifest[id]
		test.check(ResourceLoader.exists(item.file),"Manifest texture path: "+id)
		test.check(FileAccess.get_sha256(item.file)==item.sha256,"Manifest checksum: "+id)
		test.check(item.size[0]<=4096 and item.size[1]<=4096,"Mobile texture dimensions: "+id)
	var treatments := {}
	for id in 10: treatments[Art.event_treatment(id)] = true
	test.check(treatments.size()==10,"Distinct treatment for every street event")
	for id in Art.atlas_specs():
		for state in ["idle","walk","carry","serve","dance","jump","guard","anticipation","jab","kick","burst","hit","ko","victory","arrival","drinking","sleep"]:
			for index in Art.animation_frames(id,state):
				test.check(index>=0 and index<int(Art.atlas_specs()[id][1]),"Catalog animation stays in bounds: %s/%s" % [id,state])
	for spec in [["icon",192],["adaptive-foreground",432],["adaptive-background",432]]:
		var tex := Art.texture(spec[0])
		test.check(tex!=null and tex.get_size()==Vector2.ONE*spec[1],"Application icon dimensions: "+spec[0])
