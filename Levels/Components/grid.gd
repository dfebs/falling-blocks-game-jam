extends TileMapLayer

const BLOCKS = {
	"sand": {
		"id": 0,
		"variations": 3
	},

	"stone": {
		"id": 1,
		"variations": 3
	}
}

var inventory = {
	"Block 1": "sand",
	"Block 2": "stone"
}

var selected_block = "sand"

func _ready() -> void:
	$Ticker.timeout.connect(_on_tick)
	pass # Replace with function body.

func _process(_delta: float) -> void:
	var actions = ["Block 1", "Block 2"]
	for action in actions:
		if Input.is_action_pressed(action):
			selected_block = inventory[action]

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and $AddBlockCooldown.is_stopped():
		_place_new_block(get_global_mouse_position())
		$AddBlockCooldown.start()

func _on_tick():
	for cell in get_used_cells():
		var tile_data = get_cell_tile_data(cell)
		var type = tile_data.get_custom_data("type")
		var form = tile_data.get_custom_data("form")

		if (type == "sand" || type == "dirt"):
			_process_cell(cell)

func _get_neighbors_below(cell):
	# All downward directions in relation to the current cell
	var directions = [
		Vector2i.DOWN, Vector2i(-1, 1), Vector2i(1, 1)
	]

	var neighbors = []
	for direction in directions:
		neighbors.append(cell + direction)
	return neighbors

func _process_cell(cell):
	for neighbor in _get_neighbors_below(cell):
		if get_cell_source_id(neighbor) == -1:
			set_cell(neighbor, get_cell_source_id(cell), get_cell_atlas_coords(cell))
			erase_cell(cell)
			break

func _place_new_block(pos):
	# var local_pos = get_global_transform_with_canvas().affine_inverse() * pos
	var local_pos = to_local(pos)
	var map_pos = local_to_map(local_pos)

	var block_to_place = BLOCKS[selected_block]
	var atlas_coords = Vector2i(randi() % block_to_place.variations, 0)
	
	if get_cell_source_id(map_pos) == -1:
		set_cell(map_pos, block_to_place.id, atlas_coords)
