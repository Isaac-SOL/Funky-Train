class_name InteractibleSmoke extends GenericInteractible

var interacted = false

func interact():
	if not interacted:
		interacted = true
		%BrokenParticles.emitting = false
		%AudioBzzt.play()
		await %BrokenParticles.finished
		destroy()
