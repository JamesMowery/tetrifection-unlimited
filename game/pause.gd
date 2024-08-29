extends Panel

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused == false:
			show()
			get_tree().paused = true
		else:
			get_tree().paused = false
			hide()
