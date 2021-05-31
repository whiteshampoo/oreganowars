extends Node

const ID_FILE : String = "user://id.txt"
const LOG_FILE : String = "user://log.txt"
const SETTINGS_FILE : String = "user://log_settings.txt"
const HOME_URL : String = "127.0.0.1"
const HOME_PORT : int = 80
const HOME_DOCUMENT : String = "/send_log.php"
const USER_AGENT : String = "OreganoWars"
const VERSION : String = "1.0"


enum LEVEL {
	INFO,
	WARN,
	ERROR,
	FATAL,
	DEBUG
}
const LEVEL_STRING : Dictionary = {
	LEVEL.INFO:  "INFO",
	LEVEL.WARN:  "WARN",
	LEVEL.ERROR: "ERROR",
	LEVEL.FATAL: "FATAL",
	LEVEL.DEBUG: "DEBUG",
}

enum SEND_RULE {
	AUTO,
	ASK,
	DISABLED
}
const RULE_STRING : Dictionary = {
	SEND_RULE.AUTO: "AUTO",
	SEND_RULE.ASK: "ASK",
	SEND_RULE.DISABLED: "DISABLED"
}

onready var Dialog : WindowDialog = $WindowDialog
onready var DialogLog : TextEdit = $WindowDialog/Container/Text
onready var DialogComments : TextEdit = $WindowDialog/Container/Comments

onready var Http : HTTPClient = HTTPClient.new()
var ID : String = ""
var log_text : String = ""
var log_file : File = File.new()
var send_rule : int = SEND_RULE.DISABLED
var exit_after_dialog : bool = false
var init_after_dialog : bool = false
var send_after_dialog : bool = false

var send_data : PoolByteArray = PoolByteArray()
var send : bool = false
var sended : bool = false

func _ready() -> void:
	ID = create_unique_id()
	if File.new().file_exists(LOG_FILE):
		load_log_file()
		load_settings()
		show_dialog(false, true, true)
		return
	# permanently disable
	send_rule = SEND_RULE.DISABLED
	init_log()
	load_settings()


func _process(_delta: float) -> void:
	if send:
		Http.poll()
		match Http.get_status():
			Http.STATUS_CANT_CONNECT, Http.STATUS_CANT_RESOLVE:
				Http.close()
				send = false
				sended = true
			Http.STATUS_CONNECTED:
				if not sended:
					var boundary : String = "boundary--yradnuob"
					var raw_data :  PoolByteArray = http_disposition("ID", ID.to_ascii(), boundary)
					raw_data += http_disposition("VERSION", VERSION.to_ascii(), boundary)
					raw_data += http_disposition("LOG", send_data, boundary, true)
					print(raw_data.get_string_from_utf8())
					Http.request_raw(HTTPClient.METHOD_POST, HOME_DOCUMENT, 
						["User-Agent: " + USER_AGENT,
						"Content-Type: multipart/form-data; boundary=" + boundary,
						"Content-Length: " + str(raw_data.size()),], 
						raw_data)
					sended = true
		if sended:
			if Http.has_response():
				print(Http.read_response_body_chunk().get_string_from_utf8())
				Http.close()
				send = false
				sended = false
			if not send:
				if File.new().file_exists(LOG_FILE):
					Directory.new().remove(LOG_FILE)
				if exit_after_dialog:
					get_tree().quit()


func move_to_bottom() -> void:
	var root : Node = get_tree().get_root()
	#yield(get_tree(), "idle_frame")
	root.call_deferred("move_child", self, root.get_child_count())


func http_disposition(dispo_name : String, data : PoolByteArray, boundary : String, last : bool = false) -> PoolByteArray:
	var output : PoolByteArray = String("--" + boundary + "\n").to_ascii()
	output += String("Content-Disposition: form-data; name=\"" + dispo_name + "\"\n\n").to_ascii()
	output += data + "\n".to_ascii()
	if last:
		output += String("--" + boundary + "--\n").to_ascii()
	return output

func line(text : String, sender : Node, level : int = LEVEL.INFO, extra : Array = []) -> void:
	var level_text : String = LEVEL_STRING[level]
	var time : String = time_string(OS.get_ticks_msec())
	var node : String = node_string(sender)
	var extra_text : String = extra_string(extra)
	text = "\"" + text + "\""
	var line = level_text + ","
	line += time + ","
	line += str(Engine.get_frames_drawn()) + ","
	line += str(Engine.get_frames_per_second()) + ","
	line += node + ","
	line += text
	line += extra_text + "\n"
	log_text += line
	line = line.replace("\n", "")
	print(line)
	if log_file.is_open():
		log_file.store_line(line)



func time_string(milliseconds : int) -> String:
	var hours : int = int(milliseconds / (1000.0 * 60 * 60))
	var minutes : int = int((milliseconds % (1000 * 60 * 60)) / (1000.0 * 60))
	var seconds : int = int((milliseconds % (1000 * 60)) / 1000.0)
	milliseconds %= 1000
	var time : String = ("0" if hours < 10 else "") + str(hours)
	time += ":" + ("0" if minutes < 10 else "") + str(minutes) 
	time += ":" + ("0" if seconds < 10 else "") + str(seconds)
	time += "." + ("00" if milliseconds < 10 else ("0" if milliseconds < 100 else "")) + str(milliseconds)
	return time


func node_string(node : Node) -> String:
	var output : String = ""
	if node == null:
		output = "null"
	elif is_instance_valid(node):
		output = node.name
		if node.is_queued_for_deletion():
			output += " (deleted)"
	else:
		output = "invalid"
	return "\"" + output + "\""


func extra_string(extra : Array) -> String:
	var output : String = ""
	for x in extra:
		output += ",\"" + str(x) + "\""
	return output


func load_settings() -> void:
	var file : File = File.new()
	if not file.file_exists(SETTINGS_FILE):
		self.line("No settings-file", self)
		if not write_settings(SEND_RULE.ASK):
			return
	file.open(SETTINGS_FILE, File.READ)
	if not file.is_open():
		send_rule = SEND_RULE.ASK
	var line : String = file.get_line().strip_edges()
	file.close()
	if not line in RULE_STRING.values():
		send_rule = SEND_RULE.ASK
		self.line("Unknown setting", self, LEVEL.ERROR, [line])
		return
	send_rule = RULE_STRING.values().find(line)


func load_log_file() -> bool:
	print("Log from file")
	var load_log_file : File = File.new()
	load_log_file.open(LOG_FILE, File.READ)
	if not load_log_file.is_open():
		return false
	log_text = load_log_file.get_as_text()
	load_log_file.close()
	Directory.new().remove(LOG_FILE)
	return true


func write_settings(rule : int) -> bool:
	var file : File = File.new()
	file.open(SETTINGS_FILE, File.WRITE)
	if not file.is_open():
		self.line("Cannot write settings-file", self, LEVEL.ERROR)
		return false
	if not rule in RULE_STRING:
		rule = SEND_RULE.ASK
	file.store_line(RULE_STRING[rule])
	file.close()
	return true


func init_log() -> void:
	if log_file.is_open():
		log_file.close()
		print("Logfile was opened")
	log_file.open(LOG_FILE, File.WRITE)
	if not log_file.is_open():
		print("Logfile opening failed")
		
	log_text = ""
	log_text += "GAME," + USER_AGENT + "\n"
	log_text += "VERSION," + VERSION + "\n"
	log_text += "ID," + ID + "\n"
	log_text += "OS," + OS.get_name() + "\n"
	log_text += "VIDEO," + OS.get_video_driver_name(OS.get_current_video_driver()) + "\n"
	log_text += "\n"
	log_text += "LEVEL,TIME,FRAMES,FPS,NODE,TEXT,EXTRA\n"
	
	if log_file.is_open():
		log_file.store_string(log_text)


func show_dialog(exit : bool = false, init : bool = false, ignore_rule : bool = false) -> void:
	exit_after_dialog = exit
	init_after_dialog = init
	send_after_dialog = false
	
	if ignore_rule or send_rule == SEND_RULE.ASK:
		self.line("Show log-dialog", self, LEVEL.INFO)
		DialogLog.text = log_text
		DialogComments.text = ""
		Dialog.popup_centered()
		return
		
	if send_rule == SEND_RULE.AUTO:
		send_log()
	

func send_log() -> void:
	if send or sended:
		return
	if log_file.is_open():
		log_file.close()
	send_data = encrypt_for_post(log_text, ID)
	Http.close()
	if Http.connect_to_host(HOME_URL, HOME_PORT) == OK:
		send = true
		sended = false


func crypt(data : PoolByteArray, password : String) -> PoolByteArray:
	var new_data : PoolByteArray = PoolByteArray()
	var key : PoolByteArray = password.sha256_buffer()
	for i in data.size():
		new_data.append(data[i] ^ key[i % key.size()])
	return new_data


func encrypt_for_post(data : String, password : String) -> PoolByteArray:
	var raw_data : PoolByteArray = data.to_ascii()
	var compressed_data : PoolByteArray = raw_data.compress(File.COMPRESSION_GZIP)
	var encrypt_data : PoolByteArray = crypt(compressed_data, password)
	return encrypt_data
	#return Marshalls.raw_to_base64(encrypt_data).replace("+", "-").replace("/", "_").replace("=", "").to_ascii()


func create_random_id_file() -> String:
	var file : File = File.new()
	var os_id = ""
	file.open(ID_FILE, File.WRITE)
	if file.is_open():
		randomize()
		while os_id.length() < 64:
			os_id += str(randi())
		os_id = os_id.sha256_text()
		file.store_string(os_id)
		file.close()
		return os_id
	return "NO_FILE".sha256_text()


func create_unique_id() -> String:
	var os_id : String = OS.get_unique_id()
	if os_id != "":
		return os_id.sha256_text()

	var file : File = File.new()
	if not file.file_exists(ID_FILE):
		return create_random_id_file()

	file.open(ID_FILE, File.READ)
	if file.is_open():
		if file.get_len() != 64:
			file.close()
			return create_random_id_file()
		os_id = file.get_as_text()
		file.close()
		return os_id
	return "UNKOWN_ERROR".sha256_text()

func add_comment(comment : String) -> String:
	comment = comment.strip_edges()
	if comment:
		return "\n\n" + comment + "\n"
	return ""

#func _on_HTTPRequest_request_completed(_result: int, 
#										_response_code: int, 
#										_headers: PoolStringArray, 
#										_body: PoolByteArray) -> void:
#	Http.close()
#	prints(_result, _response_code)
#	print(_headers)
#	print(_body.get_string_from_utf8())
#	if File.new().file_exists(LOG_FILE):
#		Directory.new().remove(LOG_FILE)
#	if exit_after_dialog:
#		get_tree().quit()


func _on_Send_pressed() -> void:
	log_text += add_comment(DialogComments.text)
	send_after_dialog = true
	Dialog.hide()


func _on_Cancel_pressed() -> void:
	log_text += add_comment(DialogComments.text)
	Dialog.hide()


func _on_Log_tree_exiting() -> void:
	if log_text:
		self.line("Clean Exit", self, LEVEL.INFO)
		if send_rule == SEND_RULE.AUTO:
			send_log()
	if log_file.is_open():
		log_file.close()


func _on_WindowDialog_popup_hide() -> void:
	if send_after_dialog:
		send_log()
		if init_after_dialog:
			init_log()
		return
		
	if exit_after_dialog:
		get_tree().quit()
		return
		
	if init_after_dialog:
		init_log()
