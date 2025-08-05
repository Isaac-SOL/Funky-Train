extends AudioStreamPlayer

const mute_db := -80.0 # To mute the audio player
const reduced_music_db = -15.0
const default_music_db := 0.0 # This is for normal volume
const fade_time := 2.0 # The time it takes to fade in/out in seconds

const no_filter = 20000
const filter_value = 500

enum Track {
	TRAIN=0,
	GUITAR_RADIO = 1,
	BASS = 2,
	CAT = 3,
	CLAVIER = 4,
	DRUMS = 5,
	SAX = 6,
	TRIANGLE = 7,
	TRUMPET = 8,
	VOCODER = 9
}

enum TrainTrack {
	SLOW = 1,
	FAST = 0
}

var currentTween

func isWeb():
	return false and OS.has_feature("web")

func _ready() -> void:
	#setInstrument(Track.SAX, true)
	await get_tree().process_frame
	Locomotive.instance.speed_mode_changed.connect(changeCarSpeed)
	if not isWeb():
		var filter = AudioEffectFilter.new()
		AudioServer.add_bus_effect(1, filter, 0)
		AudioServer.set_bus_effect_enabled(1,0,true)
	changeCarSpeed(0)
	play()
	
func turn_whistle_on(enabled):
	if enabled:
		if $TrainWhislePlayer.playing:
			var playback = $TrainWhislePlayer.get_stream_playback()
			playback.switch_to_clip_by_name("Train Whistle Start")
		else: 
			$TrainWhislePlayer.play()
	else:
		if $TrainWhislePlayer.playing:
			var playback = $TrainWhislePlayer.get_stream_playback()
			var currentClipName = $TrainWhislePlayer.stream.get_clip_name(playback.get_current_clip_index())
			if currentClipName != "Train Whistle End" :
				playback.switch_to_clip_by_name("Train Whistle End")

func self_fade_music_in(track: Track) -> void:
	fade_music_in(self.stream, currentTween, track)

func fade_music_in(selectedStream:AudioStreamSynchronized, tween:Tween, trackNumber: int):
	var currentVolume = selectedStream.get_sync_stream_volume(trackNumber)
	return tween.tween_method(func(vdb):selectedStream.set_sync_stream_volume(trackNumber,vdb),currentVolume, default_music_db, fade_time)

func self_fade_music_out(track: Track):
	fade_music_out(self.stream, currentTween, track)
	
func fade_music_out(selectedStream:AudioStreamSynchronized, tween: Tween, trackNumber: int):
	var currentVolume = selectedStream.get_sync_stream_volume(trackNumber)
	return tween.tween_method(func(vdb):selectedStream.set_sync_stream_volume(trackNumber,vdb),currentVolume, mute_db, fade_time)
	
func setInstrument(track: Track, enabled: bool):
	var trackStream = self.stream.get_sync_stream(track)
	var tween = create_tween()
	if enabled:
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		fade_music_in(trackStream, tween, 0)
	else:
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		fade_music_out(trackStream, tween, 0)

func soundDown():
	currentTween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	if isWeb():
		var currentDb = AudioServer.get_bus_volume_db(1)
		currentTween.tween_method(func(db):AudioServer.set_bus_volume_db(1,db),currentDb,reduced_music_db,fade_time)
	else:
		var filter = AudioServer.get_bus_effect(1,0)
		currentTween.tween_property(filter, "cutoff_hz", filter_value, fade_time)

func soundUp():
	currentTween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	if isWeb():
		var currentDb = AudioServer.get_bus_volume_db(1)
		currentTween.tween_method(func(db):AudioServer.set_bus_volume_db(1,db),currentDb,default_music_db,fade_time)
	else:
		var filter = AudioServer.get_bus_effect(1,0)
		currentTween.tween_property(filter, "cutoff_hz", no_filter, fade_time)

func changeCarSpeed(speed: Locomotive.SpeedMode):
	if not isWeb():
		var filter = AudioServer.get_bus_effect(1,0)
	if currentTween:
		currentTween.kill()
	currentTween = create_tween()
	match speed:
		Locomotive.SpeedMode.STOP:
			currentTween.set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			var trainTrack = self.stream.get_sync_stream(Track.TRAIN)
			fade_music_out(trainTrack, currentTween, TrainTrack.FAST)
			fade_music_out(trainTrack, currentTween, TrainTrack.SLOW)
			soundDown()
		Locomotive.SpeedMode.NORMAL:
			currentTween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			var trainTrack = self.stream.get_sync_stream(Track.TRAIN)
			fade_music_in(trainTrack, currentTween, TrainTrack.SLOW)
			currentTween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			fade_music_out(trainTrack, currentTween, TrainTrack.FAST)
			soundUp()
		Locomotive.SpeedMode.FAST:
			currentTween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			var trainTrack = self.stream.get_sync_stream(Track.TRAIN)
			fade_music_in(trainTrack, currentTween, TrainTrack.FAST)
			currentTween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			fade_music_out(trainTrack, currentTween, TrainTrack.SLOW)
			soundUp()
