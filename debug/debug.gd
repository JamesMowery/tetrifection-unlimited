extends CanvasLayer

@onready var act_pos: Label = %ActPos
@onready var piece_grid: Label = %PieceGrid
@onready var down_check: Label = %DownCheck
@onready var left_check: Label = %LeftCheck
@onready var right_check: Label = %RightCheck

func _ready() -> void:
	if OS.is_debug_build():
		show()
	else:
		hide()

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		if not visible:
			show()
		else:
			hide()

func update_active_location(pos: Vector2i) -> void:
	act_pos.text = str("Position: ", pos)

func update_grid(grid: Array) -> void:
	piece_grid.text = str("PGrid: ", grid)

func update_down_check(grid: Array) -> void:
	down_check.text = str("Down: ", grid)

func update_left_check(grid: Array) -> void:
	left_check.text = str("Left: ", grid)

func update_right_check(grid: Array) -> void:
	right_check.text = str("Right: ", grid)

func _on_button_clear_last_pressed() -> void:
	pass
