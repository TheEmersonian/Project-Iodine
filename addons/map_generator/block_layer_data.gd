@tool
extends Resource
class_name BlockLayerData

## Defines a layer of blocks with specific placement rules

@export_category("Layer Identity")
@export var layer_name: String = "New Layer":
	set(value):
		layer_name = value
		emit_changed()

@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_category("Block Type")
@export_range(1, 255, 1) var block_id: int = 1:
	set(value):
		block_id = clampi(value, 1, 255)
		emit_changed()

@export var block_name: String = "Stone":
	set(value):
		block_name = value
		emit_changed()

@export_category("Layer Placement")
@export_enum("Surface", "Below Surface", "Fixed Depth", "Random Height", "Noise Based") var placement_mode: int = 0:
	set(value):
		placement_mode = value
		emit_changed()

@export_subgroup("Depth Settings")
@export_range(0, 256, 1) var depth_from_surface: int = 0:
	set(value):
		depth_from_surface = value
		emit_changed()

@export_range(1, 64, 1) var thickness: int = 1:
	set(value):
		thickness = maxi(1, value)
		emit_changed()

@export_subgroup("Height Range (for Fixed/Random modes)")
@export_range(0, 512, 1) var min_height: int = 0:
	set(value):
		min_height = clampi(value, 0, max_height - 1)
		emit_changed()

@export_range(0, 512, 1) var max_height: int = 64:
	set(value):
		max_height = clampi(value, min_height + 1, 512)
		emit_changed()

@export_category("Distribution")
@export_range(0.0, 1.0, 0.01) var coverage: float = 1.0:
	set(value):
		coverage = clampf(value, 0.0, 1.0)
		emit_changed()

@export var use_noise_distribution: bool = false:
	set(value):
		use_noise_distribution = value
		emit_changed()

@export_range(0.0001, 0.1, 0.0001) var noise_frequency: float = 0.01:
	set(value):
		noise_frequency = value
		emit_changed()

@export_range(-1.0, 1.0, 0.01) var noise_threshold: float = 0.0:
	set(value):
		noise_threshold = value
		emit_changed()

@export_category("Conditions")
@export var requires_solid_below: bool = false:
	set(value):
		requires_solid_below = value
		emit_changed()

@export var requires_air_above: bool = false:
	set(value):
		requires_air_above = value
		emit_changed()

@export_range(0.0, 90.0, 1.0) var max_slope: float = 90.0:
	set(value):
		max_slope = value
		emit_changed()

func should_place_at(world_pos: Vector3i, surface_height: int, noise: FastNoiseLite) -> bool:
	if not enabled:
		return false
	
	match placement_mode:
		0: # Surface
			return world_pos.y >= surface_height - depth_from_surface and world_pos.y < surface_height - depth_from_surface + thickness
		1: # Below Surface
			return world_pos.y >= surface_height - depth_from_surface - thickness and world_pos.y < surface_height - depth_from_surface
		2: # Fixed Depth
			return world_pos.y >= min_height and world_pos.y < min_height + thickness
		3: # Random Height
			if world_pos.y < min_height or world_pos.y > max_height:
				return false
			return randf() < coverage
		4: # Noise Based
			if world_pos.y < min_height or world_pos.y > max_height:
				return false
			if use_noise_distribution:
				var noise_val = noise.get_noise_3d(
					world_pos.x * noise_frequency,
					world_pos.y * noise_frequency,
					world_pos.z * noise_frequency
				)
				return noise_val > noise_threshold
			return true
	
	return false