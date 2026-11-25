extends Node

signal update_available
const EXECUTABLE = "PattayaAfterHours.exe"
const ARCHIVE = "PattayaAfterHours-windows-x86_64.zip"
const BASE = "https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/download/"
const LATEST = "https://api.github.com/repos/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest"
const PREFIX = ".pattaya-update-"
const WORKER = "UpdateWorker.exe"
const BACKUP = "PreviousVersion.exe"
const READY = "started"
const LOCK = ".pattaya-update-lock"
const MAX_ARCHIVE = 96 * 1024 * 1024
var tag := ""
var busy := false
var progress: AcceptDialog

static func installed_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version"))

static func version_parts(value: String) -> Array[int]:
	var parts := value.split(".")
	var numbers: Array[int] = []
	if parts.size() != 3: return numbers
	for part in parts:
		if part.is_empty() or part.length() > 6: return []
		for digit in part:
			if digit not in "0123456789": return []
		numbers.append(int(part))
	return numbers

static func latest_tag(data: Variant, installed: String) -> String:
	if not data is Dictionary or data.get("draft",true) or data.get("prerelease",true): return ""
	var candidate := str(data.get("tag_name",""))
	if not candidate.begins_with("v"): return ""
	var offered := version_parts(candidate.substr(1))
	var current := version_parts(installed)
	if offered.size() != 3 or current.size() != 3 or offered <= current: return ""
	var assets: Variant = data.get("assets")
	if not assets is Array: return ""
	var names := PackedStringArray()
	for asset in assets:
		if asset is Dictionary and asset.get("state") == "uploaded":
			names.append(str(asset.get("name","")))
	return candidate if ARCHIVE in names and "SHA256SUMS.txt" in names else ""

static func expected_hash(manifest: String) -> String:
	for line in manifest.split("\n"):
		var fields := line.strip_edges().split(" ",false)
		if fields.size() != 2 or fields[1].trim_prefix("*") != ARCHIVE: continue
		var digest := fields[0].to_lower()
		if digest.length() != 64: continue
		var valid := true
		for digit in digest:
			if digit not in "0123456789abcdef": valid = false
		if valid: return digest
	return ""

static func supported() -> bool:
	return OS.get_name() == "Windows" and OS.get_executable_path().get_file().to_lower() == EXECUTABLE.to_lower()

func check() -> void:
	var reply := await fetch(LATEST,256 * 1024)
	if reply.is_empty(): return
	tag = latest_tag(JSON.parse_string(reply[3].get_string_from_utf8()),installed_version())
	if not tag.is_empty(): update_available.emit()

func ask() -> void:
	if tag.is_empty() or busy: return
	var confirm := ConfirmationDialog.new()
	confirm.title = "Pattaya After Hours update"
	confirm.exclusive = true
	confirm.dialog_text = "%s is ready. Download it and restart the game?" % tag
	confirm.ok_button_text = "Update & restart"
	confirm.cancel_button_text = "Later"
	confirm.confirmed.connect(func():
		confirm.queue_free()
		install_update())
	confirm.canceled.connect(confirm.queue_free)
	add_child(confirm)
	confirm.popup_centered()

func fetch(url: String, limit: int, destination: String = "") -> Array:
	var request := HTTPRequest.new()
	request.use_threads = true
	request.timeout = 20.0 if destination.is_empty() else 180.0
	request.body_size_limit = limit
	request.download_file = destination
	add_child(request)
	if request.request(url,["User-Agent: PattayaAfterHours"]) != OK:
		request.queue_free()
		return []
	var reply: Array = await request.request_completed
	request.queue_free()
	return reply if reply[0] == HTTPRequest.RESULT_SUCCESS and reply[1] == 200 else []

func install_update() -> void:
	if busy: return
	busy = true
	progress = AcceptDialog.new()
	progress.title = "Updating Pattaya After Hours"
	progress.exclusive = true
	progress.dialog_text = "Checking the download…"
	progress.get_ok_button().hide()
	progress.close_requested.connect(func(): progress.popup_centered())
	add_child(progress)
	progress.popup_centered()
	var executable := OS.get_executable_path()
	var staging := executable.get_base_dir().path_join(PREFIX + str(OS.get_process_id()) + "-" + str(Time.get_ticks_msec()))
	if DirAccess.make_dir_absolute(staging) != OK:
		fail_download("Move the extracted game folder to Downloads and try again.")
		return
	var release := BASE + tag + "/"
	var checksum := await fetch(release + "SHA256SUMS.txt",64*1024)
	var digest := "" if checksum.is_empty() else expected_hash(checksum[3].get_string_from_utf8())
	if digest.is_empty():
		fail_download("Could not verify this release. Try again later.",staging)
		return
	progress.dialog_text = "Downloading %s…" % tag
	var download := staging.path_join(ARCHIVE)
	var reply := await fetch(release + ARCHIVE,MAX_ARCHIVE,download)
	if reply.is_empty() or FileAccess.get_sha256(download) != digest:
		fail_download("The download did not verify. Try again later.",staging)
		return
	progress.dialog_text = "Installing and restarting…"
	if stage_executable(download,staging.path_join(EXECUTABLE)) != OK or DirAccess.copy_absolute(executable,staging.path_join(WORKER)) != OK:
		fail_download("Could not prepare the update. Try again later.",staging)
		return
	var pid := OS.create_process(staging.path_join(WORKER),["--headless","--","--pattaya-apply"])
	if pid < 0:
		fail_download("Could not start the update. Try again later.",staging)
		return
	get_tree().quit()

static func stage_executable(archive: String, path: String) -> Error:
	var reader := ZIPReader.new()
	if reader.open(archive) != OK: return ERR_FILE_CORRUPT
	var bytes := reader.read_file(EXECUTABLE)
	reader.close()
	if bytes.size() < 2 or bytes.size() > 256*1024*1024 or bytes[0] != 77 or bytes[1] != 90: return ERR_FILE_CORRUPT
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

func fail_download(message: String, staging: String = "") -> void:
	if not staging.is_empty(): remove_staging(staging)
	progress.queue_free()
	busy = false
	var notice := AcceptDialog.new()
	notice.title = "Update unavailable"
	notice.exclusive = true
	notice.dialog_text = message
	notice.confirmed.connect(notice.queue_free)
	notice.canceled.connect(notice.queue_free)
	add_child(notice)
	notice.popup_centered()

static func valid_folder(folder: String) -> bool:
	if not folder.begins_with(PREFIX): return false
	var suffix := folder.trim_prefix(PREFIX).split("-")
	if suffix.size() != 2: return false
	for part in suffix:
		if not part.is_valid_int() or int(part) <= 0: return false
	return true

static func remove_staging(staging: String) -> void:
	for name in [ARCHIVE,EXECUTABLE,WORKER,BACKUP,READY]:
		var path := staging.path_join(name)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(staging)

static func is_worker() -> bool:
	var executable := OS.get_executable_path()
	var args := OS.get_cmdline_user_args()
	return OS.get_name() == "Windows" and executable.get_file() == WORKER and valid_folder(executable.get_base_dir().get_file()) and args == PackedStringArray(["--pattaya-apply"])

static func apply_update(tree: SceneTree) -> void:
	var staging := OS.get_executable_path().get_base_dir()
	var original := staging.get_base_dir().path_join(EXECUTABLE)
	var backup := staging.path_join(BACKUP)
	var staged := staging.path_join(EXECUTABLE)
	var lock := staging.get_base_dir().path_join(LOCK)
	if not FileAccess.file_exists(staged) or not FileAccess.file_exists(original):
		worker_error(tree,"Couldn't find the game or the downloaded update.")
		return
	if DirAccess.make_dir_absolute(lock) != OK:
		worker_error(tree,"Another update is pending. Open the game again in a moment.")
		return
	# Windows can hold the executable open briefly while the game shuts down.
	var deadline := Time.get_ticks_msec() + 15000
	while DirAccess.rename_absolute(original,backup) != OK:
		if Time.get_ticks_msec() >= deadline:
			worker_error(tree,"Couldn't replace the game. Close other copies and try again.",lock)
			return
		await tree.create_timer(0.1).timeout
	if DirAccess.rename_absolute(staged,original) == OK:
		var pid := OS.create_process(original,["--","--pattaya-updated",staging.get_file()])
		if pid >= 0:
			deadline = Time.get_ticks_msec() + 30000
			while OS.is_process_running(pid) and not FileAccess.file_exists(staging.path_join(READY)) and Time.get_ticks_msec() < deadline:
				await tree.create_timer(0.1).timeout
			if FileAccess.file_exists(staging.path_join(READY)) or OS.is_process_running(pid):
				DirAccess.remove_absolute(lock)
				tree.quit()
				return
	if FileAccess.file_exists(original): DirAccess.rename_absolute(original,staged)
	if DirAccess.rename_absolute(backup,original) == OK:
		OS.create_process(original,[])
		worker_error(tree,"The update couldn't start. Your previous version was restored.",lock)
	else:
		worker_error(tree,"The previous game is at " + backup,lock)

static func worker_error(tree: SceneTree, message: String, lock: String = "") -> void:
	if not lock.is_empty(): DirAccess.remove_absolute(lock)
	OS.alert(message,"Pattaya After Hours")
	tree.quit(1)

func confirm_restart() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--pattaya-updated" or not valid_folder(args[1]): return
	var directory := OS.get_executable_path().get_base_dir()
	var staging := directory.path_join(args[1])
	var worker := staging.path_join(WORKER)
	if not FileAccess.file_exists(worker) or not FileAccess.file_exists(staging.path_join(BACKUP)): return
	var marker := FileAccess.open(staging.path_join(READY),FileAccess.WRITE)
	if marker == null: return
	marker.close()
	var lock := directory.path_join(LOCK)
	var deadline := Time.get_ticks_msec() + 5000
	# Godot only tracks child processes on Windows. Wait for the worker's lock
	# and executable to be released before removing the restart marker.
	while Time.get_ticks_msec() < deadline:
		if not DirAccess.dir_exists_absolute(lock) and DirAccess.remove_absolute(worker) == OK:
			remove_staging(staging)
			return
		await get_tree().create_timer(0.1).timeout
