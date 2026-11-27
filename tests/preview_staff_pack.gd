extends SceneTree
## Isolated authoring preview: no campaign, roster, sales or saved state.

class StaffBoard extends Node2D:
	var entries: Array = []
	var textures: Array[Texture2D] = []
	var portraits: Array[Texture2D] = []
	var pose_index := 0
	var light := false
	var font := ThemeDB.fallback_font

	func _draw() -> void:
		var size := get_viewport_rect().size
		var factor := size / Vector2(960, 540)
		draw_set_transform(Vector2.ZERO, 0, factor)
		draw_rect(Rect2(0, 0, 960, 540), Color("eae1d8") if light else Color("171626"))
		var ink := Color("302a3c") if light else Color("f1cadf")
		draw_string(font, Vector2(18, 26), "STAFF PACK / art preview / " + str(pose_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		for n in range(entries.size()):
			var entry: Dictionary = entries[n]
			var x := float(n % 4) * 240.0
			var y := float(n / 4) * 250.0 + 30.0
			var cell := Vector2(entry.cell[0], entry.cell[1])
			var frame: int = pose_index % entry.frames.size()
			draw_texture_rect_region(textures[n], Rect2(x + 40, y + 204 - cell.y, cell.x, cell.y), Rect2(frame * cell.x, 0, cell.x, cell.y))
			draw_texture_rect(portraits[n], Rect2(x + 183, y + 10, 48, 48), false)
			draw_string(font, Vector2(x + 15, y + 223), entry.name + " / " + entry.frames[frame], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output := OS.get_environment("PATTAYA_PREVIEW_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Use tools/preview-art.sh with a graphical display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var pack := ProjectSettings.globalize_path("res://art/staff-pack-v1/")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pack + "manifest.json"))
	var board := StaffBoard.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.entries = manifest.characters
	for entry in board.entries:
		board.textures.append(ImageTexture.create_from_image(Image.load_from_file(pack + entry.atlas)))
		board.portraits.append(ImageTexture.create_from_image(Image.load_from_file(pack + entry.portrait)))
	root.add_child(board)
	for background in ["dark", "light"]:
		board.light = background == "light"
		for frame in range(6):
			board.pose_index = frame
			board.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("staff-" + background + "-" + str(frame) + ".png"))
	print("Staff pack: captured all 40 poses and eight portraits on light/dark backgrounds.")
	quit()
