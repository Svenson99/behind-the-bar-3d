extends Node

var enabled = true
var music_enabled = true
var effects = {}
var pour: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer

func sound(kind: String, seconds: float, loop: bool = false) -> AudioStreamWAV:
	var rate = 16000
	var data = PackedByteArray()
	data.resize(int(seconds * rate) * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var smooth = 0.0
	for i in range(int(seconds * rate)):
		var t = float(i) / rate
		var noise = rng.randf_range(-1,1)
		smooth = lerpf(smooth, noise, 0.08)
		var v = 0.0
		match kind:
			"pour": v = smooth * 0.6 + sin(t * 1700 + sin(t*70)*9) * 0.025
			"room": v = smooth * 0.12 + sin(t*TAU*60) * 0.012
			"music":
				var notes = [130.81,164.81,196.0,246.94,146.83,174.61,220.0,261.63]
				var beat = int(t * 2) % notes.size()
				var age = fmod(t,0.5)
				v = (sin(t*TAU*notes[beat]) + sin(t*TAU*notes[beat]*2)*0.25) * exp(-age*7) * 0.12
			"glass": v = (sin(t*TAU*2400) + sin(t*TAU*3671)*0.5) * exp(-t*18) * 0.2
			"break": v = noise * exp(-t*12) * 0.5 + sin(t*TAU*3200)*exp(-t*24)*0.2
			"ice": v = noise * exp(-fmod(t,0.07)*60) * exp(-t*5) * 0.3
			"serve": v = sin(t*TAU*(660 if t < 0.12 else 880))*sin(minf(1,t/0.015)*PI/2)*exp(-t*5)*0.15
			_: v = sin(t*TAU*440)*exp(-t*35)*0.12
		if not loop: v *= minf(1.0, (seconds-t)*50)
		data.encode_s16(i*2, int(clampf(v,-1,1)*32767))
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = int(seconds * rate)
	return wav

func player(kind: String, seconds: float, loop: bool = false) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = sound(kind,seconds,loop)
	add_child(p)
	return p

func _ready() -> void:
	for kind in ["glass","break","ice","serve","tap"]:
		effects[kind] = player(kind,0.5)
	pour = player("pour",1.0,true)
	ambience = player("room",2.0,true)
	music = player("music",4.0,true)
	var settings = ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		enabled = settings.get_value("audio","enabled",true)
		music_enabled = settings.get_value("audio","music",true)
	apply_settings()

func apply_settings() -> void:
	if enabled:
		if not ambience.playing: ambience.play()
	else:
		ambience.stop()
		pour.stop()
		for p in effects.values(): p.stop()
	if enabled and music_enabled:
		if not music.playing: music.play()
	else: music.stop()
	var settings = ConfigFile.new()
	settings.set_value("audio","enabled",enabled)
	settings.set_value("audio","music",music_enabled)
	settings.save("user://settings.cfg")

func play(kind: String) -> void:
	if enabled and effects.has(kind): effects[kind].play()

func flow(value: bool) -> void:
	if value and enabled:
		if not pour.playing: pour.play()
	else: pour.stop()
