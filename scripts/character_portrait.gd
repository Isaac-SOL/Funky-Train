class_name CharacterPortrait extends TextureRect

var bounce_tween: Tween
@onready var pos := get_index() + 1

func _ready() -> void:
	await get_tree().process_frame
	Main.instance.rhythm_sync.beat.connect(_on_beat)

func load_character(character: CharacterInfo):
	%CharacterSprite.texture = character.sprite
	%CharacterSprite.visible = true

func reset_character():
	%CharacterSprite.visible = false

func _on_beat(beat: int):
	if beat % 4 == pos % 4:
		%CharacterSprite.scale = Vector2(1.0, 0.85)
		if bounce_tween:
			bounce_tween.kill()
		bounce_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		bounce_tween.tween_property(%CharacterSprite, "scale", Vector2.ONE, 0.5)
