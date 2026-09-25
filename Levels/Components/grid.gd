extends TileMapLayer

const BLOCKS = {
	"stone": {
		"id": 1,
		"variations": 3
	},

	"sand": {
		"id": 0,
		"variations": 3
	},
	"dirt": {
		"id": 2,
		"variations": 3
	},

	"grass": {
		"id": 3,
		"variations": 3
	},

	"boost": {
		"id": 4,
		"variations": 2
	},

	"water": {
		"id": 5,
		"variations": 1
	}
}

var inventory = {
	"Block 1": "stone",
	"Block 2": "sand",
	"Block 3": "dirt",
	"Block 4": "grass",
	"Block 5": "boost",
	"Block 6": "water"
}

var selected_block = "sand"
var nourished_cells: Array[Vector2i] = []

@onready var block_preview = $Control
@export var sprite_2d: Sprite2D
@export var blocks: Array[Texture] = []
@export var blocks_ui: Control
@export var block_type_ui: PackedScene
@export var actions: Array[String] = ["Block 1", "Block 2", "Block 3", "Block 4", "Block 5", "Block 6"]
var left_mouse_held = false

func _ready() -> void:
	if len(actions) > 0:
		selected_block = inventory[actions[0]]
	else:
		selected_block = ""
	$Ticker.timeout.connect(_on_tick)
	$NourishmentTicker.timeout.connect(_on_nourishment_tick)
	update_block_preview_sprite()
	refresh_blocks_ui()
	update_block_preview_position()

func _process(_delta: float) -> void:
	for action in actions:
		if Input.is_action_pressed(action):
			selected_block = inventory[action]
			update_block_preview_sprite()
	update_block_preview_position()
	place_block_if_mouse_held()
	
func refresh_blocks_ui():
	for child in blocks_ui.get_children():
		child.queue_free()
	var index = 0
	for action in actions:
		var block_name = inventory[action]
		var ui_thing: BlockTypeUI = block_type_ui.instantiate().duplicate()
		blocks_ui.add_child(ui_thing)
		var new_tex = blocks[BLOCKS[block_name]["id"]]
		ui_thing.texture = ui_thing.texture.duplicate()
		ui_thing.texture.atlas = new_tex
		ui_thing.text = "{0}".format([block_name.capitalize()])
		ui_thing.hotkey.text = str(index + 1)
		ui_thing.position += Vector2(24, 24 + index * 24)
		index += 1

func _unhandled_input(event):
	# Moved this here so it doesn't trigger when clicking on UI buttons
	if event.is_action_pressed("MouseLeft"):
		left_mouse_held = true
	if event.is_action_released("MouseLeft"):
		left_mouse_held = false

func place_block_if_mouse_held():
	if left_mouse_held and $AddBlockCooldown.is_stopped():
		_place_selected_block(get_global_mouse_position())
		$AddBlockCooldown.start()

func update_block_preview_sprite():
	if sprite_2d.texture is AtlasTexture:
		sprite_2d.texture.atlas = blocks[BLOCKS[selected_block]["id"]]

func update_block_preview_position():
	if !block_preview: return
	var local_pos = get_global_mouse_position()
	var local = to_local(local_pos)
	var map_pos = local_to_map(local_pos)
	var local_center = map_to_local(map_pos)
	block_preview.global_position = to_global(local_center)

func _on_tick():
	for cell in get_used_cells():
		var tile_data = get_cell_tile_data(cell)
		var type = tile_data.get_custom_data("type")

		match type:
			"sand":
				_process_grainy_cell(cell)
			"water":
				_process_liquid_cell(cell)
			"dirt":
				_nourish_neighbors(cell, ["grass"])
				_process_grainy_cell(cell)
			"grass":
				_nourish_neighbors(cell, ["grass"])
				_assimilate_neighbors(cell, ["water"])
				_process_cohesive_solid_cell(cell)
			"boost":
				_process_pure_solid_cell(cell)

func _on_nourishment_tick():
	for cell in get_used_cells().filter(func(cell): return !nourished_cells.has(cell) && _get_cell_type(cell) == "grass"):
		set_cell(cell, -1)
	nourished_cells = []

func _get_neighbors_below(cell):
	# All downward directions in relation to the current cell
	var directions = [
		Vector2i.DOWN, Vector2i(-1, 1), Vector2i(1, 1)
	]

	var neighbors = []
	for direction in directions:
		neighbors.append(cell + direction)
	return neighbors

func _get_all_neighbors(cell):
	var directions = [
		Vector2i.DOWN,
		Vector2i.UP,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i(-1, 1),
		Vector2i(-1, -1),
		Vector2i(1, 1),
		Vector2i(1, -1),
	]

	var neighbors = []
	for direction in directions:
		neighbors.append(cell + direction)
	return neighbors

func _get_cell_type(cell):
	var cell_tile_data = get_cell_tile_data(cell)
	return cell_tile_data.get_custom_data("type")

func _nourish_neighbors(cell, types):
	var neighbors = _get_all_neighbors(cell)
	var cell_type = _get_cell_type(cell)

	for neighbor in neighbors:
		if _cell_is_empty(neighbor):
			continue
	
		var neighbor_tile_data = get_cell_tile_data(neighbor)
		var neighbor_type = neighbor_tile_data.get_custom_data("type")
		
		if types.has(neighbor_type) && (cell_type == "dirt" || nourished_cells.has(cell)):
			nourished_cells.append(neighbor)

func _assimilate_neighbors(cell, types):
	var neighbors = _get_all_neighbors(cell)
	var cell_type = _get_cell_type(cell)

	for neighbor in neighbors:
		if _cell_is_empty(neighbor):
			continue
	
		var neighbor_tile_data = get_cell_tile_data(neighbor)
		var neighbor_type = neighbor_tile_data.get_custom_data("type")
		
		if types.has(neighbor_type):
			_set_block(neighbor, cell_type)

func _get_neighbor_below(cell):
	return cell + Vector2i.DOWN

func _get_neighbors_beside(cell):
	var directions = [
		Vector2i.LEFT, Vector2i.RIGHT
	]

	var neighbors = []
	for direction in directions:
		neighbors.append(cell + direction)
	return neighbors

func _process_grainy_cell(cell):
	_attempt_downward_movement(cell)

func _process_pure_solid_cell(cell):
	_attempt_straight_down_movement(cell)

func _process_cohesive_solid_cell(cell):
	_attempt_straight_down_movement(cell, true, true)

func _process_liquid_cell(cell):
	if _attempt_downward_movement(cell, false):
		return
	_attempt_sideways_movement(cell)

func _attempt_straight_down_movement(cell, sink=true, cohesive=false):
	var neighbor = _get_neighbor_below(cell)
	if _attempt_cell_move_to(cell, neighbor, sink, cohesive):
		return true
	return false

func _attempt_downward_movement(cell, sink=true, cohesive=false):
	for neighbor in _get_neighbors_below(cell):
		if _attempt_cell_move_to(cell, neighbor, sink, cohesive):
			return true
	return false

func _attempt_sideways_movement(cell):
	var neighbors = _get_neighbors_beside(cell)
	neighbors.shuffle()
	for neighbor in neighbors:
		if _attempt_cell_move_to(cell, neighbor, false):
			return true
	return false

func _cell_is_empty(cell):
	return get_cell_source_id(cell) == -1

func _attempt_cell_move_to(cell, location, sink=true, cohesive=false):
	if (cohesive):
		var neighbors = _get_all_neighbors(cell)
		for neighbor in neighbors:
			if !_cell_is_empty(neighbor) && _get_cell_type(neighbor) == _get_cell_type(cell):
				return true
	if (sink && !_cell_is_empty(location) && _get_cell_type(location) == "water"):
		set_cell(location, get_cell_source_id(cell), get_cell_atlas_coords(cell))
		set_cell(cell, BLOCKS.water.id, Vector2i(0,0))
		return true
	if _cell_is_empty(location):
		set_cell(location, get_cell_source_id(cell), get_cell_atlas_coords(cell))
		erase_cell(cell)
		return true
	return false

func _place_selected_block(pos):
	var local_pos = to_local(pos)
	var map_pos = local_to_map(local_pos)

	var block_to_set = BLOCKS[selected_block]
	var atlas_coords = Vector2i(randi() % block_to_set.variations, 0)
	
	if _cell_is_empty(map_pos):
		set_cell(map_pos, block_to_set.id, atlas_coords)

func _set_block(pos, block_type):
	var block_to_set = BLOCKS[block_type]
	var atlas_coords = Vector2i(randi() % block_to_set.variations, 0)
	
	set_cell(pos, block_to_set.id, atlas_coords)
