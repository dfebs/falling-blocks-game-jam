extends Resource
class_name BlockCount

@export_enum("Block 1", "Block 2", "Block 3", "Block 4", "Block 5", "Block 6") var block_type: String = ""
@export var count: int = 10

func _init(type: String = "Block 1", _count: int = 10):
	block_type = type
	count = _count
