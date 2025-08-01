class_name CharacterSignalisation extends TextureRect

func load_character(character: CharacterInfo):
	%CharacterTexture.texture = character.sprite

func set_forbidden(forbidden: bool):
	%ForbiddenTexture.visible = forbidden
