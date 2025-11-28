extends Resource
class_name WorldSaveData

## Persistent world data for save/load

@export var world_name: String = "New World"
@export var seed_value: int = 0
@export var creation_timestamp: int = 0
@export var last_modified: int = 0

@export var world_limits_xz: Vector2i = Vector2i(-512, 512)
@export var world_limits_y: Vector2i = Vector2i(0, 128)

@export var noise_amplitude: float = 32.0
@export var noise_frequency: float = 0.005

@export var biome_blend_enabled: bool = true
@export var blend_transition_radius: float = 16.0
@export var blend_noise_intensity: float = 0.3
@export var blend_noise_frequency: float = 0.02

@export var generated_chunks: Dictionary = {}

@export var biomes_data: Array = []
@export var cave_settings_data: Dictionary = {}

func _init():
	creation_timestamp = Time.get_unix_time_from_system()
	last_modified = creation_timestamp

func update_timestamp():
	last_modified = Time.get_unix_time_from_system()

func mark_chunk_generated(chunk_pos: Vector3i):
	var key = _chunk_key(chunk_pos)
	generated_chunks[key] = true
	update_timestamp()

func is_chunk_generated(chunk_pos: Vector3i) -> bool:
	var key = _chunk_key(chunk_pos)
	return generated_chunks.has(key)

func _chunk_key(chunk_pos: Vector3i) -> String:
	return "%d_%d_%d" % [chunk_pos.x, chunk_pos.y, chunk_pos.z]

func to_dict() -> Dictionary:
	return {
		"world_name": world_name,
		"seed_value": seed_value,
		"creation_timestamp": creation_timestamp,
		"last_modified": last_modified,
		"world_limits_xz": [world_limits_xz.x, world_limits_xz.y],
		"world_limits_y": [world_limits_y.x, world_limits_y.y],
		"noise_amplitude": noise_amplitude,
		"noise_frequency": noise_frequency,
		"biome_blend_enabled": biome_blend_enabled,
		"blend_transition_radius": blend_transition_radius,
		"blend_noise_intensity": blend_noise_intensity,
		"blend_noise_frequency": blend_noise_frequency,
		"generated_chunks": generated_chunks,
		"biomes_data": biomes_data,
		"cave_settings_data": cave_settings_data
	}

static func from_dict(data: Dictionary) -> WorldSaveData:
	var world_data = WorldSaveData.new()
	world_data.world_name = data.get("world_name", "Unknown")
	world_data.seed_value = data.get("seed_value", 0)
	world_data.creation_timestamp = data.get("creation_timestamp", 0)
	world_data.last_modified = data.get("last_modified", 0)
	
	var limits_xz = data.get("world_limits_xz", [-512, 512])
	world_data.world_limits_xz = Vector2i(limits_xz[0], limits_xz[1])
	
	var limits_y = data.get("world_limits_y", [0, 128])
	world_data.world_limits_y = Vector2i(limits_y[0], limits_y[1])
	
	world_data.noise_amplitude = data.get("noise_amplitude", 32.0)
	world_data.noise_frequency = data.get("noise_frequency", 0.005)
	world_data.biome_blend_enabled = data.get("biome_blend_enabled", true)
	world_data.blend_transition_radius = data.get("blend_transition_radius", 16.0)
	world_data.blend_noise_intensity = data.get("blend_noise_intensity", 0.3)
	world_data.blend_noise_frequency = data.get("blend_noise_frequency", 0.02)
	world_data.generated_chunks = data.get("generated_chunks", {})
	world_data.biomes_data = data.get("biomes_data", [])
	world_data.cave_settings_data = data.get("cave_settings_data", {})
	
	return world_data