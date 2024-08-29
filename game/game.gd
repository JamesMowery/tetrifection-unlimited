extends Node2D

@onready var tiles_layer: TileMapLayer = %TilesLayer
@onready var debug: CanvasLayer = %Debug
@onready var audio_line_clear: AudioStreamPlayer = %AudioLineClear
@onready var audio_settle: AudioStreamPlayer = %AudioSettle
@onready var audio_level_up: AudioStreamPlayer = %AudioLevelUp
@onready var timer_drop: Timer = %TimerDrop
@onready var bgm: AudioStreamPlayer = %BGM
@onready var score_data: Label = %ScoreData
@onready var game_over_panel: Panel = %GameOverPanel

# Constants
const tile: int = 0
const start_location: Vector2i = Vector2i(4, 0)
const next_location: Vector2i = Vector2i(15, 1)
const steps_required: int = 1000

enum ACTION {
	draw,
	clear
}

# Piece Variables
var z_piece: Dictionary = {
	"grid": [Vector2i(0,0), Vector2i(1,0), Vector2i(1, 1), Vector2i(2, 1)],
	"pivot": Vector2i(1,1)
}
var l_piece: Dictionary = {
	"grid": [Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	"pivot": Vector2i(1,1)
}
var o_piece: Dictionary = {
	"grid": [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	"pivot": Vector2i(-1,-1)
}
var t_piece: Dictionary = {
	"grid": [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	"pivot": Vector2i(1,1)
}
var j_piece: Dictionary = {
	"grid": [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	"pivot": Vector2i(1,1)
}
var s_piece: Dictionary = {
	"grid": [Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	"pivot": Vector2i(1,1)
}
var i_piece: Dictionary = {
	"grid": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3)],
	"pivot": Vector2i(0,2)
}
var pieces: Array = [z_piece,l_piece,o_piece,t_piece,j_piece,s_piece,i_piece]
var pieces_bag: Array = pieces.duplicate()

# Color Variables
var colors: Array = [
	Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),
	Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),
]
var colors_bag: Array = colors.duplicate()

# Current Variables
var active_piece: Dictionary
var next_piece: Dictionary
var ghost_piece: Dictionary
var active_location: Vector2i
var active_color: Vector2i = Vector2i(1, 0)
var next_color: Vector2i = Vector2i(2, 0)
var steps: int = 0
var speed: float
var lines_cleared: int = 0
var drop_complete: bool = false
var danger: bool = false
var danger_playing: bool = false
var score: int = 0

func _ready() -> void:
	pieces_bag.shuffle()
	colors_bag.shuffle()
	pick_color()
	active_location = start_location
	#next_color = pick_color()
	create_piece()
	#print("Active Piece", active_piece)
	#set_piece(ACTION.draw, active_piece, active_location, active_color)
	#set_piece(ACTION.draw, next_piece, next_location, next_color)

func _process(delta: float) -> void:
	speed = 10.0
	steps += speed
	if steps > steps_required:
		active_location = move_piece(active_piece, active_location, Vector2i.DOWN, active_color)
		steps = 0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("left") \
	or Input.is_action_just_pressed("ui_left"):
		active_location = move_piece(
			active_piece, active_location, Vector2i.LEFT, active_color)

	if Input.is_action_just_pressed("right") \
	or Input.is_action_just_pressed("ui_right"):
		active_location = move_piece(
			active_piece, active_location, Vector2i.RIGHT, active_color)

	if Input.is_action_just_pressed("up") \
	or Input.is_action_just_pressed("ui_up"):
		rotate_piece(active_piece, active_location, active_color)

	if Input.is_action_just_pressed("down") \
	or Input.is_action_just_pressed("ui_down"):
		active_location = move_piece(
			active_piece, active_location, Vector2i.DOWN, active_color)
		steps = 0
		timer_drop.start()


	if Input.is_action_just_released("down") \
	or Input.is_action_just_released("ui_down"):
		timer_drop.stop()

	debug.update_active_location(active_location)
	debug.update_grid(active_piece.grid)

func create_piece() -> void:
	pick_color()
	pick_piece()
	set_piece(ACTION.draw, active_piece, active_location, active_color)
	set_piece(ACTION.draw, next_piece, next_location, next_color)

func pick_piece() -> void:
	# Current piece
	if not pieces_bag.is_empty():
		active_piece = pieces_bag.pop_front()
		active_location = start_location

	# Next piece
	if pieces_bag.is_empty():
		pieces_bag = pieces.duplicate()
		pieces_bag.shuffle()

	# Random rotate
	var random = randi_range(0, 4)
	for i in range(0, random):
		rotate_piece(active_piece, active_location, active_color)

	# Next piece
	next_color = colors_bag[0]
	next_piece = pieces_bag[0]

	random = randi_range(0, 4)
	for i in range(0, random):
		rotate_piece(next_piece, next_location, next_color)

func pick_color() -> void:
	if not colors_bag.is_empty():
		active_color = colors_bag.pop_front()

	if colors_bag.is_empty():
		colors_bag = colors.duplicate()
		colors_bag.shuffle()

	next_color = colors_bag[0]

func set_piece(action: ACTION, piece: Dictionary, location: Vector2i, color) -> void:
	for i in piece.grid.size():
		if action == ACTION.draw:
			draw_piece(tiles_layer, piece.grid[i] + location, color)
		else:
			clear_piece(tiles_layer, piece.grid[i] + location)

func draw_piece(layer: TileMapLayer, location: Vector2i, color: Vector2i) -> void:
	layer.set_cell(location, tile, color)

func clear_piece(layer: TileMapLayer, location: Vector2i) -> void:
	layer.erase_cell(location)

func move_piece(piece: Dictionary, location: Vector2i, direction: Vector2i, color: Vector2i) -> Vector2i:
	set_piece(ACTION.clear, piece, location, color)
	if can_move(piece, location, direction):
		location += direction
		set_piece(ACTION.draw, piece, location, color)
	else:
		if direction == Vector2i.DOWN:
			audio_settle.play()
			score += 25
			score_data.text = str(score)
			set_piece(ACTION.clear, next_piece, next_location, next_color)
			set_piece(ACTION.draw, piece, location, color)
			check_game_over()
			drop_complete = true
			check_clear(active_piece, active_location)
			create_piece()
			location = start_location
		else:
			set_piece(ACTION.draw, piece, location, color)

	return location

func can_move(piece: Dictionary, pos: Vector2i, direction: Vector2i) -> bool:
	if direction == Vector2i.DOWN:
		var x_values: Array = []
		var max_y_values: Array = []

		# 1) get all unique x values
		for i in piece.grid.size():
			if not x_values.has(piece.grid[i].x):
				x_values.append(piece.grid[i].x)

		# 2) get the highest y value for each x
		for x_value in x_values:
			var max_y: int = 0
			for j in piece.grid.size():
				if piece.grid[j].x == x_value:
					if max_y < piece.grid[j].y:
						max_y = piece.grid[j].y
			# 3) combine into an array filled with Vector2i
			max_y_values.append(Vector2i(x_value, max_y))

		#print("MAX_Y_VALUES: ", max_y_values)

		for j in max_y_values.size():
			if not is_free(Vector2i(max_y_values[j].x + pos.x, max_y_values[j].y + pos.y), Vector2i.DOWN):
				return false

	if direction == Vector2i.LEFT:
		var y_values: Array = []
		var min_x_values: Array = []

		# 1) get all unique y values
		for i in piece.grid.size():
			if not y_values.has(piece.grid[i].y):
				y_values.append(piece.grid[i].y)

		#print("UNIQUE Y: ", y_values)

		# 2) get the lowest x value for each y
		for y_value in y_values:
			var min_x: int = 3
			for j in piece.grid.size():
				if piece.grid[j].y == y_value:
					if min_x > piece.grid[j].x:
						min_x = piece.grid[j].x
			# 3) combine into an array filled with Vector2i
			min_x_values.append(Vector2i(min_x, y_value))

		#print("MIN_X_VALUES: ", min_x_values)

		for j in min_x_values.size():
			if not is_free(Vector2i(min_x_values[j].x + pos.x, min_x_values[j].y + pos.y), Vector2i.LEFT):
				return false

	if direction == Vector2i.RIGHT:
		var y_values: Array = []
		var max_x_values: Array = []

		# 1) get all unique y values
		for i in piece.grid.size():
			if not y_values.has(piece.grid[i].y):
				y_values.append(piece.grid[i].y)

		#print("UNIQUE Y: ", y_values)

		# 2) get the lowest x value for each y
		for y_value in y_values:
			var max_x: int = -2
			for j in piece.grid.size():
				if piece.grid[j].y == y_value:
					if max_x < piece.grid[j].x:
						max_x = piece.grid[j].x
			# 3) combine into an array filled with Vector2i
			max_x_values.append(Vector2i(max_x, y_value))

		#print("MIN_X_VALUES: ", max_x_values)

		for j in max_x_values.size():
			if not is_free(Vector2i(max_x_values[j].x + pos.x, max_x_values[j].y + pos.y), Vector2i.RIGHT):
				return false

	return true

func is_free(pos: Vector2i, direction: Vector2i) -> bool:
	#print("CHECKING: ", pos + direction)
	return tiles_layer.get_cell_source_id(pos + direction) == -1

func can_rotate(piece: Dictionary, location: Vector2i, color: Vector2i) -> bool:
	var temp_piece: Array = [Vector2i(-1,-1), Vector2i(-1,-1), Vector2i(-1,-1), Vector2i(-1,-1)]
	for i in piece.grid.size():
		temp_piece[i].x = -(piece.grid[i].y - piece.pivot.y) + piece.pivot.x
		temp_piece[i].y = (piece.grid[i].x - piece.pivot.x) + piece.pivot.y

	for j in temp_piece.size():
		if not is_free(Vector2i(temp_piece[j].x + location.x, temp_piece[j].y + location.y), Vector2i.ZERO):
			return false
	return true

func rotate_piece(piece: Dictionary, location: Vector2i, color: Vector2i) -> void:
	set_piece(ACTION.clear, piece, location, color)
	if piece.pivot.x != -1:
		if can_rotate(piece, location, color):
			var temp_piece: Array = [Vector2i(-1,-1), Vector2i(-1,-1), Vector2i(-1,-1), Vector2i(-1,-1)]
			for i in piece.grid.size():
				temp_piece[i].x = -(piece.grid[i].y - piece.pivot.y) + piece.pivot.x
				temp_piece[i].y = (piece.grid[i].x - piece.pivot.x) + piece.pivot.y
				piece.grid[i].x = temp_piece[i].x
				piece.grid[i].y = temp_piece[i].y

	set_piece(ACTION.draw, piece, location, color)

func check_clear(piece: Dictionary, location: Vector2i) -> void:
	# Get y values to check
	var y_values: Array = []
	for i in piece.grid.size():
		if not y_values.has(piece.grid[i].y):
			y_values.append(piece.grid[i].y)

	#print("Y VALUES: ", y_values)
	# Check rows for each y value
	var x_count: int
	var lines_to_drop: Array = []
	for y in y_values:
		x_count = 0
		for x in range(0, 10):
			#print("CHECKING: ", x, "|", y + location.y)
			if tiles_layer.get_cell_source_id(Vector2i(x, y + location.y)) != -1:
				x_count += 1
				#print("X COUNT: ", x_count, "|", y + location.y)
				if x_count == 10:
					audio_line_clear.play()
					clear_line(y + location.y)
					lines_to_drop.append(y + location.y)
					lines_cleared += 1
					score += 100
					score_data.text = str(score)
					if lines_cleared % 10 == 0:
						score += 1000
						score_data.text = str(score)
						audio_level_up.play()
						speed += 20

	#print ("LINES TO DROP: ", lines_to_drop)
	for line in lines_to_drop:
		drop_lines(line)

func clear_line(y_value: int) -> void:
	for i in range(0, 10):
		tiles_layer.erase_cell(Vector2i(i, y_value))

func drop_lines(y_value: int) -> void:
	for y in range(y_value, 0, -1):
		for x in range(0, 10):
			var existing_piece = tiles_layer.get_cell_source_id(Vector2i(x, y))
			var existing_color = tiles_layer.get_cell_atlas_coords(Vector2i(x, y))
			if existing_piece != -1:
				tiles_layer.erase_cell(Vector2i(x, y))
				tiles_layer.set_cell(Vector2i(x, y + 1), existing_piece, existing_color)

func drop_piece(piece: Dictionary) -> void:
	while drop_complete != true:
		active_location = move_piece(active_piece, active_location, Vector2i.DOWN, active_color)
	timer_drop.stop()


func check_game_over() -> void:
	for x in range(0, 10):
		if tiles_layer.get_cell_source_id(Vector2i(x, 6)) != -1:
			danger = true
			if danger == true and danger_playing == false:
				danger_playing = true
				bgm["parameters/switch_to_clip"] = "Danger"

		if tiles_layer.get_cell_source_id(Vector2i(x, 2)) != -1:
			#end_score_data.text = score_data.text
			#ui_overlay.show()
			#ui_pause.hide()
			#ui_game_over.show()
			#button_new_game.grab_focus()
			game_over_panel.show()
			get_tree().paused = true

func _on_timer_drop_timeout() -> void:
	drop_complete = false
	drop_piece(active_piece)


func _on_new_game_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
