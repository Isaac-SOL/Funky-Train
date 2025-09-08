class_name InteractibleSmoke extends GenericInteractible

func interact():
	%BrokenParticles.emitting = false
	%AudioBzzt.play()
	await %BrokenParticles.finished
	queue_free()
