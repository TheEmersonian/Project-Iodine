@tool
extends Resource
class_name CaveSettings

## Cave generation configuration with 3D noise

@export_category("Cave Settings")
@export var enabled: bool = true

@export_group("Size Settings")
@export var min_size: float = 0.3:
	set(value):
		min_size = clampf(value, 0.1, 2.0)
@export var max_size: float = 1.0:
	set(value):
		max_size = clampf(value, 0.1, 2.0)
@export var size_variation_frequency: float = 0.01

@export_group("Y Limits")
@export var min_y: int = 0
@export var max_y: int = 64

@export_group("Noise Settings")
@export var frequency: float = 0.02
@export var threshold: float = 0.6:
	set(value):
		threshold = clampf(value, 0.0, 1.0)
@export var octaves: int = 3
@export var lacunarity: float = 2.0
@export var gain: float = 0.5

@export_group("Advanced")
@export var use_worm_caves: bool = false
@export var worm_frequency: float = 0.005
@export var worm_threshold: float = 0.85

var _noise: FastNoiseLite
var _size_noise: FastNoiseLite

func _init():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = frequency
	_noise.fractal_octaves = octaves
	_noise.fractal_lacunarity = lacunarity
	_noise.fractal_gain = gain
	
	_size_noise = FastNoiseLite.new()
	_size_noise.frequency = size_variation_frequency

func setup(seed_value: int):
	_noise.seed = seed_value
	_size_noise.seed = seed_value + 12345
	_noise.frequency = frequency
	_noise.fractal_octaves = octaves
	_noise.fractal_lacunarity = lacunarity
	_noise.fractal_gain = gain
	_size_noise.frequency = size_variation_frequency

func is_cave(pos: Vector3i) -> bool:
	if not enabled:
		return false
	
	if pos.y < min_y or pos.y > max_y:
		return false
	
	var size = get_cave_size(pos)
	var noise_val = _noise.get_noise_3d(pos.x, pos.y, pos.z)
	noise_val = (noise_val + 1.0) * 0.5
	
	var adjusted_threshold = threshold * (2.0 - size)
	
	if use_worm_caves:
		var worm_val = _noise.get_noise_3d(
			pos.x * worm_frequency,
			pos.y * worm_frequency,
			pos.z * worm_frequency
		)
		worm_val = (worm_val + 1.0) * 0.5
		if worm_val > worm_threshold:
			return noise_val > adjusted_threshold * 0.8
	
	return noise_val > adjusted_threshold

func get_cave_size(pos: Vector3i) -> float:
	var size_noise_val = _size_noise.get_noise_2d(pos.x, pos.z)
	size_noise_val = (size_noise_val + 1.0) * 0.5
	return lerp(min_size, max_size, size_noise_val)