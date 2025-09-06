class_name MouseObstacle extends GenericInteractible

func interact():
	if "cat" in Locomotive.instance.get_properties():
		%AudioSqueak.play()
		%AnimationPlayer.play("flee")
		await %AnimationPlayer.animation_finished
		destroy()
