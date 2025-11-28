@tool
extends Resource
class_name BlockData

## Block configuration for procedural generation

@export_category("Block Settings")
@export var block_id: int = 1
@export var block_name: String = "Block"

@export_group("Generation Bounds")
@export var min_x: int = -100
@export var max_x: int = 100
@export var min_y: int = 0
@export var max_y: int = 64
@export var min_z: int = -100
@export var max_z: int = 100

@export_group("Ore Settings")
@export var is_rare_ore: bool = false
@export var cluster_size: int = 3:
	set(value):
		cluster_size = clampi(value, 1, 32)
@export var rarity: float = 0.01:
	set(value):
		rarity = clampf(value, 0.0, 1.0)
@export var target_biomes: Array[String] = []

@export_group("Distribution")
@export var use_3d_noise: bool = false
@export var noise_threshold: float = 0.5
@export var noise_frequency: float = 0.05

func _init():
	pass

func is_position_in_bounds(pos: Vector3i) -> bool:
	return (pos.x >= min_x and pos.x <= max_x and
			pos.y >= min_y and pos.y <= max_y and
			pos.z >= min_z and pos.z <= max_z)

func should_generate_ore(pos: Vector3i, noise: FastNoiseLite, biome_name: String = "") -> bool:
	if not is_rare_ore:
		return true
	
	if target_biomes.size() > 0 and biome_name not in target_biomes:
		return false
	
	if use_3d_noise:
		var val = noise.get_noise_3d(
			pos.x * noise_frequency,
			pos.y * noise_frequency,
			pos.z * noise_frequency
		)
		return val > noise_threshold
	
	var rand_val = randf()
	return rand_val < rarity