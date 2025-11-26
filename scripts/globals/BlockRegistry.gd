
extends Node

##Read individually as they may be slightly unintuitive.  
enum GeneratedRotationType {
	##Completely random
	Random,
	##Randomly rotated around the x axis
	XRandom,
	##Randomly rotated around the z axis
	ZRandom,
	##Randomly rotated around the x and z axis's
	HorizontalRandom,
	##Randomly rotated around the y axis
	VerticalRandom,
	##The default that the blocks texture is in
	Fixed,
}

class BlockDef:
	var block_name: String
	var is_solid: bool
	var generated_rotation: GeneratedRotationType
	var function: Script = null
	var default_metadata = null
	func _init(block_name: String, is_block_solid: bool = true, generated_orientation: GeneratedRotationType = GeneratedRotationType.Fixed, block_function: Script = null) -> void:
		block_name = block_name
		is_solid = is_block_solid
		generated_rotation = generated_orientation
		function = block_function


@export var blocks: Dictionary = {}

func register_block(id: int, def: BlockDef):
	blocks[id] = def

func get_block(id: int):
	if blocks.keys().has(id):
		return blocks[id]

func _ready() -> void:
	register_block(0, BlockDef.new("stone"))
	register_block(1, BlockDef.new("deep_stone"))
	register_block(2, BlockDef.new("bedrock"))
	register_block(3, BlockDef.new("dirt", true, GeneratedRotationType.Random))
	register_block(4, BlockDef.new("dirt_with_grass", true, GeneratedRotationType.VerticalRandom))






#end
