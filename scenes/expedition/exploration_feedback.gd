extends RefCounted
## Short procedural UI tones; no external audio files or additional mixer system.
static var streams: Dictionary = {}
static var durations: Dictionary = {}

static func seconds(role: String) -> float:
	if durations.is_empty(): durations = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json")).durations_ms
	return float(durations[role])/1000.0

static func play(parent: Node, complete: bool = false) -> void:
	if not streams.has(complete):
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var count := 3308 if complete else 1544
		var bytes := PackedByteArray()
		bytes.resize(count*2)
		for i in range(count):
			var t := float(i)/stream.mix_rate
			var envelope := sin(PI*float(i)/count)*exp(-t*24)
			var frequency := 880.0 if complete else 640.0
			var sample := int(sin(TAU*frequency*t)*envelope*2200)
			bytes.encode_s16(i*2,sample)
		stream.data = bytes
		streams[complete] = stream
	var player := AudioStreamPlayer.new()
	player.stream = streams[complete]
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
