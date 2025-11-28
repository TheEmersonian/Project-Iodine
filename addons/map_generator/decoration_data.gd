@tool
extends Resource
class_name DecorationData

## Surface decorations like trees, rocks, plants

@export_category("Decoration Identity")
@export var decoration_name: String = "Grass Tuft":
	set(value):
		decoration_name = value
		emit_changed()

@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_category("Type")
@export_enum("Single Block", "Vertical Stack", "Tree", "Structure", "Custom Pattern") var decoration_type: int = 0:
	set(value):
		decoration_type = value
		emit_changed()

@export_category("Blocks")
@export_range(1, 255, 1) var primary_block_id: int = 6:
	set(value):
		primary_block_id = value
		emit_changed()

@export_range(1, 255, 1) var secondary_block_id: int = 7:
	set(value):
		secondary_block_id = value
		emit_changed()

@export_category("Size (for trees/structures)")
@export_range(1, 32, 1) var min_height: int = 4:
	set(value):
		min_height = clampi(value, 1, max_height)
		emit_changed()

@export_range(1, 32, 1) var max_height: int = 8:
	set(value):
		max_height = clampi(value, min_height, 32)
		emit_changed()

@export_range(1, 16, 1) var width: int = 3:
	set(value):
		width = maxi(1, value)
		emit_changed()

@export_category("Spawn Conditions")
@export_range(0.0, 1.0, 0.001) var spawn_chance: float = 0.1:
	set(value):
		spawn_chance = clampf(value, 0.0, 1.0)
		emit_changed()

@export_range(1, 64, 1) var min_spacing: int = 2:
	set(value):
		min_spacing = maxi(1, value)
		emit_changed()

@export var require_grass_below: bool = true:
	set(value):
		require_grass_below = value
		emit_changed()

@export var required_surface_blocks: Array[int] = [2]: # Block IDs that must be below
	set(value):
		required_surface_blocks = value
		emit_changed()

@export_range(0.0, 45.0, 1.0) var max_slope: float = 15.0:
	set(value):
		max_slope = value
		emit_changed()

@export_category("Height Range")
@export_range(0, 512, 1) var min_spawn_y: int = 60:
	set(value):
		min_spawn_y = clampi(value, 0, max_spawn_y - 1)
		emit_changed()

@export_range(0, 512, 1) var max_spawn_y: int = 120:
	set(value):
		max_spawn_y = clampi(value, min_spawn_y + 1, 512)
		emit_changed()

@export_category("Distribution")
@export var use_noise_distribution: bool = true:
	set(value):
		use_noise_distribution = value
		emit_changed()

@export_range(0.001, 0.5, 0.001) var noise_frequency: float = 0.05:
	set(value):
		noise_frequency = value
		emit_changed()

@export_range(-1.0, 1.0, 0.01) var noise_threshold: float = 0.3:
	set(value):
		noise_threshold = value
		emit_changed()

func should_spawn_at(world_pos: Vector3i, surface_block: int, noise: FastNoiseLite) -> bool:
	if not enabled:
		return false
	
	if world_pos.y < min_spawn_y or world_pos.y > max_spawn_y:
		return false
	
	if required_surface_blocks.size() > 0:
		if surface_block not in required_surface_blocks:
			return false
	
	if use_noise_distribution:
		var noise_val = noise.get_noise_2d(world_pos.x * noise_frequency, world_pos.z * noise_frequency)
		if noise_val < noise_threshold:
			return false
	
	return randf() < spawn_chance

func generate_blocks(base_pos: Vector3i) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	
	match decoration_type:
		0: # Single Block
			blocks.append({"position": base_pos, "block_id": primary_block_id})
		1: # Vertical Stack
			var height = randi_range(min_height, max_height)
			for y in range(height):
				blocks.append({"position": base_pos + Vector3i(0, y, 0), "block_id": primary_block_id})
		2: # Tree
			blocks = _generate_tree(base_pos)
		3: # Structure
			blocks = _generate_structure(base_pos)
		4: # Custom Pattern
			blocks = _generate_custom_pattern(base_pos)
	
	return blocks

func _generate_tree(base_pos: Vector3i) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var trunk_height = randi_range(min_height, max_height)
	
	# Trunk
	for y in range(trunk_height):
		blocks.append({"position": base_pos + Vector3i(0, y, 0), "block_id": primary_block_id})
	
	# Leaves (simple sphere)
	var leaf_center = base_pos + Vector3i(0, trunk_height, 0)
	var leaf_radius = width
	
	for x in range(-leaf_radius, leaf_radius + 1):
		for y in range(-leaf_radius, leaf_radius + 1):
			for z in range(-leaf_radius, leaf_radius + 1):
				var dist = Vector3(x, y, z).length()
				if dist <= leaf_radius and dist > 0:
					blocks.append({
						"position": leaf_center + Vector3i(x, y, z),
						"block_id": secondary_block_id
					})
	
	return blocks

func _generate_structure(base_pos: Vector3i) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var height = randi_range(min_height, max_height)
	
	# Simple pyramid structure
	for y in range(height):
		var level_width = width - y
		if level_width < 1:
			level_width = 1
		
		for x in range(-level_width, level_width + 1):
			for z in range(-level_width, level_width + 1):
				blocks.append({
					"position": base_pos + Vector3i(x, y, z),
					"block_id": primary_block_id if y < height / 2 else secondary_block_id
				})
	
	return blocks

func _generate_custom_pattern(base_pos: Vector3i) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	
	# Simple cross pattern
	for i in range(-width, width + 1):
		blocks.append({"position": base_pos + Vector3i(i, 0, 0), "block_id": primary_block_id})
		blocks.append({"position": base_pos + Vector3i(0, 0, i), "block_id": primary_block_id})
	
	return blocks