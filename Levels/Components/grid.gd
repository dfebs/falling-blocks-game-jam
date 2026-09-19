extends TileMapLayer

func _ready() -> void:
	$Ticker.timeout.connect(_on_tick)
	pass # Replace with function body.


func _process(_delta: float) -> void:
	pass

func _on_tick():
	for cell in get_used_cells():
		print(cell)
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
