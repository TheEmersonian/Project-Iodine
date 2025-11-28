@tool
extends Resource
class_name BiomeData

## Advanced biome configuration with visual editor support

signal blocks_changed()

@export_category("Biome Identity")
@export var biome_name: String = "New Biome":
	set(value):
		biome_name = value
		emit_changed()

@export var biome_id: int = 0:
	set(value):
		biome_id = value
		emit_changed()

@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()

@export_category("Biome Boundaries")
@export_subgroup("Horizontal Bounds")
@export var min_x: float = -1000.0:
	set(value):
		min_x = value
		emit_changed()

@export var max_x: float = 1000.0:
	set(value):
		max_x = value
		emit_changed()

@export var min_z: float = -1000.0:
	set(value):
		min_z = value
		emit_changed()

@export var max_z: float = 1000.0:
	set(value):
		max_z = value
		emit_changed()

@export_subgroup("Vertical Bounds")
@export_range(0, 512, 1) var min_y: int = 0:
	set(value):
		min_y = clampi(value, 0, max_y - 1)
		emit_changed()

@export_range(0, 512, 1) var max_y: int = 128:
	set(value):
		max_y = clampi(value, min_y + 1, 512)
		emit_changed()

@export_category("Terrain Generation")
@export_subgroup("Height Modifiers")
@export var base_height_offset: float = 0.0:
	set(value):
		base_height_offset = value
		emit_changed()

@export_range(0.0, 100.0, 0.1) var height_amplitude: float = 10.0:
	set(value):
		height_amplitude = value
		emit_changed()

@export_range(0.0001, 0.1, 0.0001) var height_frequency: float = 0.01:
	set(value):
		height_frequency = value
		emit_changed()

@export_range(1, 8, 1) var height_octaves: int = 3:
	set(value):
		height_octaves = value
		emit_changed()

@export_subgroup("Terrain Shape")
@export_enum("Perlin", "Simplex", "Cellular", "Value") var noise_type: int = 0:
	set(value):
		noise_type = value
		emit_changed()

@export_range(0.0, 10.0, 0.1) var terrain_roughness: float = 2.0:
	set(value):
		terrain_roughness = value
		emit_changed()

@export_range(0.0, 1.0, 0.01) var terrain_persistence: float = 0.5:
	set(value):
		terrain_persistence = value
		emit_changed()

@export_category("Biome Blending")
@export var blend_color: Color = Color.WHITE:
	set(value):
		blend_color = value
		emit_changed()

@export_range(0.0, 10.0, 0.1) var priority_factor: float = 1.0:
	set(value):
		priority_factor = value
		emit_changed()

@export_range(0.0, 100.0, 1.0) var blend_radius: float = 32.0:
	set(value):
		blend_radius = value
		emit_changed()

@export_subgroup("Advanced Masking")
@export var use_noise_mask: bool = false:
	set(value):
		use_noise_mask = value
		emit_changed()

@export_range(0.0001, 0.1, 0.0001) var mask_frequency: float = 0.01:
	set(value):
		mask_frequency = value
		emit_changed()

@export_range(0.0, 2.0, 0.01) var mask_amplitude: float = 1.0:
	set(value):
		mask_amplitude = value
		emit_changed()

@export_range(-1.0, 1.0, 0.01) var mask_threshold: float = 0.0:
	set(value):
		mask_threshold = value
		emit_changed()

@export_category("Temperature & Humidity")
@export_range(-50.0, 50.0, 0.1) var temperature: float = 20.0:
	set(value):
		temperature = value
		emit_changed()

@export_range(0.0, 100.0, 1.0) var humidity: float = 50.0:
	set(value):
		humidity = value
		emit_changed()

@export_category("Block Layers")
@export var surface_blocks: Array[BlockLayerData] = []:
	set(value):
		surface_blocks = value
		blocks_changed.emit()
		emit_changed()

@export var subsurface_blocks: Array[BlockLayerData] = []:
	set(value):
		subsurface_blocks = value
		blocks_changed.emit()
		emit_changed()

@export var underground_blocks: Array[BlockLayerData] = []:
	set(value):
		underground_blocks = value
		blocks_changed.emit()
		emit_changed()

@export_category("Ore Deposits")
@export var ore_deposits: Array[OreDepositData] = []:
	set(value):
		ore_deposits = value
		blocks_changed.emit()
		emit_changed()

@export_category("Decorations")
@export var decorations: Array[DecorationData] = []:
	set(value):
		decorations = value
		emit_changed()

var _noise: FastNoiseLite
var _mask_noise: FastNoiseLite

func _init():
	_setup_noise()

func _setup_noise():
	_noise = FastNoiseLite.new()
	_noise.frequency = height_frequency
	_noise.fractal_octaves = height_octaves
	_noise.fractal_lacunarity = terrain_roughness
	_noise.fractal_gain = terrain_persistence
	
	_mask_noise = FastNoiseLite.new()
	_mask_noise.frequency = mask_frequency

func setup_with_seed(seed_value: int):
	_noise.seed = seed_value + biome_id * 1000
	_mask_noise.seed = seed_value + biome_id * 1000 + 999
	_noise.noise_type = noise_type
	_noise.frequency = height_frequency
	_noise.fractal_octaves = height_octaves
	_noise.fractal_lacunarity = terrain_roughness
	_noise.fractal_gain = terrain_persistence
	_mask_noise.frequency = mask_frequency

func is_position_in_bounds(pos: Vector3) -> bool:
	return (pos.x >= min_x and pos.x <= max_x and
			pos.y >= min_y and pos.y <= max_y and
			pos.z >= min_z and pos.z <= max_z)

func get_height_at_position(world_x: float, world_z: float) -> float:
	var noise_val = _noise.get_noise_2d(world_x, world_z)
	return base_height_offset + (noise_val * height_amplitude)

func get_noise_mask_value(pos: Vector3) -> float:
	if not use_noise_mask:
		return 1.0
	
	var val = _mask_noise.get_noise_2d(pos.x, pos.z)
	val = (val + 1.0) * 0.5 * mask_amplitude
	return clampf(val - mask_threshold, 0.0, 1.0)

func get_distance_from_center(pos: Vector3) -> float:
	var center_x = (min_x + max_x) * 0.5
	var center_z = (min_z + max_z) * 0.5
	return Vector2(pos.x - center_x, pos.z - center_z).length()

func get_distance_from_bounds(pos: Vector3) -> float:
	var dx = 0.0
	var dz = 0.0
	
	if pos.x < min_x:
		dx = min_x - pos.x
	elif pos.x > max_x:
		dx = pos.x - max_x
	
	if pos.z < min_z:
		dz = min_z - pos.z
	elif pos.z > max_z:
		dz = pos.z - max_z
	
	return Vector2(dx, dz).length()