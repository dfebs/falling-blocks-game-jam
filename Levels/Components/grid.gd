extends TileMapLayer

const BLOCKS = {
	"sand": {
		"id": 0,
		"variations": 3
	},

	"stone": {
		"id": 1,
		"variations": 3
	},

	"dirt": {
		"id": 2,
		"variations": 3
	},
#
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
	"Block 1": "sand",
	"Block 2": "stone",
	"Block 3": "dirt",
	"Block 4": "grass",
	"Block 5": "boost",
	"Block 6": "water"
}

var selected_block = "sand"

@onready var block_preview = $Control
@export var sprite_2d: Sprite2D
@export var blocks: Array[Texture] = []
@export var blocks_ui: Control
@export var block_type_ui: PackedScene
@export var actions: Array[String] = ["Block 1", "Block 2", "Block 3", "Block 4", "Block 5", "Block 6"]

func _ready() -> void:
	if len(actions) > 0:
		selected_block = inventory[actions[0]]
	else:
		selected_block = ""
	$Ticker.timeout.connect(_on_tick)
	update_block_preview_sprite()
	for child in blocks_ui.get_children():
		child.queue_free()
	for action in actions:
		var block_name = inventory[action]
		var ui_thing: BlockTypeUI = block_type_ui.instantiate()
		blocks_ui.add_child(ui_thing)
		var new_tex = blocks[BLOCKS[block_name]["id"]]
		ui_thing.texture = ui_thing.texture.duplicate()
		ui_thing.texture.atlas = new_tex
		ui_thing.text = "{0} - {1}".format([block_name.capitalize(), str(BLOCKS[block_name]["id"] + 1)])
		ui_thing.position += Vector2(24, 24 + BLOCKS[block_name]["id"] * 24)
	update_block_preview_sprite()
	update_block_preview_position()

func _process(_delta: float) -> void:
	for action in actions:
		if Input.is_action_pressed(action):
			selected_block = inventory[action]
			update_block_preview_sprite()
	update_block_preview_position()

func update_block_preview_sprite():
	if sprite_2d.texture is AtlasTexture:
		sprite_2d.texture.atlas = blocks[BLOCKS[selected_block]["id"]]

func update_block_preview_position():
	if !block_preview: return
	var local_pos = get_global_mouse_position()
	block_preview.global_position = local_pos

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
