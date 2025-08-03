extends Node

var pause = false

#Music

#Menu

#Ambiant


@onready var audio_stream_player_1 = $AudioStreamPlayer
@onready var audio_stream_player_2 = $AudioStreamPlayer2
@onready var audio_stream_player_3 = $AudioStreamPlayer3
var interactive_stream1
var interactive_stream2
var interactive_stream3


@export var transition_duration = 5.0

const VOLUME_AUDIO_STREAM_PLAYER_2 = -10
const INIT_RAND_TIME = 1.0 #60

var dict_rand_music = {
}


var alternative_is_playing = false
var rand_time = INIT_RAND_TIME
var init_volume_db
var tween




func playAudio_stream1(music_name: String):
	if !interactive_stream1:
		audio_stream_player_1.volume_db = -80
		audio_stream_player_1.play()
		await get_tree().process_frame  # Let audio backend catch up
		interactive_stream1 = audio_stream_player_1.get_stream_playback() as AudioStreamPlaybackInteractive
		if interactive_stream1:
			interactive_stream1.switch_to_clip_by_name(music_name)
			audio_stream_player_1.volume_db = 0
	elif !pause:
		interactive_stream1.switch_to_clip_by_name(music_name)
		
		
func playAudio_stream2(music_name: String):
	if !interactive_stream2:
		audio_stream_player_2.volume_db = -80
		audio_stream_player_2.play()
		await get_tree().process_frame  # Let audio backend catch up
		interactive_stream2 = audio_stream_player_2.get_stream_playback() as AudioStreamPlaybackInteractive
		if interactive_stream2:
			interactive_stream2.switch_to_clip_by_name(music_name)
			audio_stream_player_2.volume_db = 0
		
	elif !pause:
		interactive_stream2.switch_to_clip_by_name(music_name)
		
func playAudio_stream3(music_name: String):
	if !interactive_stream3:
		audio_stream_player_3.volume_db = -80
		audio_stream_player_3.play()
		await get_tree().process_frame  # Let audio backend catch up
		interactive_stream3 = audio_stream_player_3.get_stream_playback() as AudioStreamPlaybackInteractive
		if interactive_stream3:
			interactive_stream3.switch_to_clip_by_name(music_name)
			audio_stream_player_3.volume_db = 0
		
	elif !pause:
		interactive_stream3.switch_to_clip_by_name(music_name)
		
		
func stopAudio_stream(audio_stream_player):
	if audio_stream_player.playing:
		audio_stream_player.stop()
		
		
func play_last_catle_track():
	if true:
		interactive_stream1.switch_to_clip_by_name(&"Ambiant main castle")
	elif false:
		interactive_stream1.switch_to_clip_by_name(&"Ambiant main castle")
		
		
func pauseAudio():
	if audio_stream_player_1.playing == true:
		audio_stream_player_1.stop()
	if audio_stream_player_2.playing == true:
		audio_stream_player_2.stop()
	pause = !pause
	
func unpauseAudio():
	if audio_stream_player_1.playing == false:
		play_last_catle_track()
	pause = !pause



			
func play_random_dungeon_sound():
	if !alternative_is_playing:
		var rand = randi_range(0,10000)
		if rand < 1:
			audio_stream_player_2.play()
			alternative_is_playing = true
			await get_tree().create_timer(10.0).timeout
			alternative_is_playing = false
		
		
#Vérifier si l'interactive stream est entrain de jouer (true) ou est fini (false)
#func check_interactive_playing(interacive : AudioStreamPlaybackInteractive):
	#var stream = audio_stream_player_2.stream
	#if !interacive:
		#print("1")
		#return false
	#elif interacive and interacive.get_playback_position() >= stream.get_length():
		#print ("interacive.get_playback_position() = "+str(interacive.get_playback_position()))
		#print("stream.get_length() = "+str(stream.get_length()))
		#print("2")
		#return false
	#else:
		#print("3")
		#return true

func fade_out(audio_stream_player):
	# tween music volume down to -60
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	init_volume_db = audio_stream_player.volume_db
	# Wait for the tween to complete
	tween.tween_property(audio_stream_player, "volume_db", -60, transition_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# when the tween ends, the music will be stopped
	await tween.finished
	#Stop audio_stream_player and reset volume
	audio_stream_player.stop()
	audio_stream_player.volume_db = init_volume_db
