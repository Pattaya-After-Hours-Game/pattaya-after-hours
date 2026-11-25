extends RefCounted
const Art = preload("res://scripts/art.gd")

func run(test: SceneTree) -> void:
	for kind in 3:
		for stage in range(1,4):
			var tex := Art.venue(kind,stage)
			test.check(tex != null,"Venue artwork exists: %d/%d" % [kind,stage])
			if tex: test.check(tex.get_size()==Vector2(960,540),"Venue uses presentation resolution")
	for id in ["district","toybox","counter","event-inspection"]:
		test.check(Art.texture(id) != null,"Scene/prop artwork exists: "+id)
	for id in ["anong"]+Art.STAFF+Art.HOSTS+["juno","vega","orchid"]:
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
