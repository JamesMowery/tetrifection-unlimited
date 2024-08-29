extends Control

@export var game_scene: PackedScene

@onready var button_new: Button = %ButtonNew

func _ready() -> void:
	button_new.grab_focus()

func _on_button_new_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_button_exit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
