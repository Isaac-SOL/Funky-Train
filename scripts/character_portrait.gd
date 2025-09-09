class_name CharacterPortrait extends TextureRect

var bounce_tween: Tween
@onready var pos := get_index() + 1
var curr_character: CharacterInfo

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(_on_beat)

func load_character(character: CharacterInfo):
	curr_character = character
	%CharacterSprite.texture = character.sprite
	%CharacterSprite.visible = true
	if character.true_name == "Jojo":
		%CharacterSprite.position.y = -54.0
	else:
		%CharacterSprite.position.y = -33.0
	if character.name == "hub3" and not "tb_powered" in Locomotive.instance.get_properties():
		%AnimationPlayer.play("tb_no_power")
	else:
		%AnimationPlayer.play("RESET")

func reset_character():
	curr_character = null
	%CharacterSprite.visible = false
	%AnimationPlayer.play("RESET")

func power_tb():
	if curr_character and curr_character.name == "hub3":
		%AnimationPlayer.play("RESET")

func _on_beat(beat: int):
	if beat % 4 == pos % 4:
		%CharacterSprite.scale = Vector2(1.0, 0.85)
		if bounce_tween:
			bounce_tween.kill()
		bounce_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		bounce_tween.tween_property(%CharacterSprite, "scale", Vector2.ONE, 0.5)
