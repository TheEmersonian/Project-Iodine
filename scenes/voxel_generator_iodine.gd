extends VoxelGeneratorScript

#const Structure = preload("./structure.gd")
#const TreeGenerator = preload("./tree_generator.gd")
#const HeightmapCurve = preload("./heightmap_curve.tres")

# TODO Don't hardcode, get by name from library somehow
const AIR = 0
const GRANITE = 1
const SOIL = 2
const DIRT = 3
const GRASS = 4
const SPARSE_GRASS = 5
const MUDDY_SOIL = 6
const ERROR = 7 #block that is supposed to indicate an errror
const BASALT = 8
const RHYOLITE = 9

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

enum GeologicProvence {
	Shield, #plutonic, granite, granodiorite, high grade metemorphic
	Platform, #sedementary should be mostly horizontal and filling in the lower areas
	Oriogen, #
	Basin, #
	LargeIgneousProvence, #lots of igneous rock on the surface, flooding not following heightmap
	ExtendedCrust, #
}


var sea_level := 0
#var _heightmap_max_y := 50
var _heightmap_amp := 43.0
var _heightmap_noise := FastNoiseLite.new()

var _cont_noise := FastNoiseLite.new()
@export var _cont_curve: Curve = preload("res://assets/curves/generation/cont_curve.tres")
var _cont_amp := 123.3

var _erosion_noise := FastNoiseLite.new()
@export var _erosion_curve: Curve = preload("res://assets/curves/generation/erosion_curve.tres")

var _humidity_noise := FastNoiseLite.new()

var _temperature_noise := FastNoiseLite.new()

var _randvalue_noise := FastNoiseLite.new()

var _base_soil_depth_noise := FastNoiseLite.new()
var _base_soil_depth_amp: float = 3.6

var _base_dirt_depth_noise := FastNoiseLite.new()
var _base_dirt_depth_amp: float = 6.4

#determines where the really crazy stuff happens
var _world_amplitude_noise := FastNoiseLite.new()

var _geologic_province_noise := FastNoiseLite.new()




func _init():
	setup_heightmap()
	setup_contnoise()
	setup_erosion()
	setup_humidity()
	setup_temperature()
	setup_randnoise()
	setup_base_soil_depth()
	setup_base_dirt_depth()
	setup_world_amplitude_noise()

func setup_heightmap():  #local heightmap - determines local height variation
	_heightmap_noise.seed = GameManager.seeds[0]
	_heightmap_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_heightmap_noise.fractal_octaves = 13
	_heightmap_noise.frequency = 0.004
	_heightmap_noise.fractal_gain = 0.3
	_heightmap_noise.fractal_weighted_strength = 0.5
	_heightmap_noise.domain_warp_enabled = true
	_heightmap_noise.domain_warp_amplitude = 5
	_heightmap_noise.domain_warp_fractal_gain = 0.5
	_heightmap_noise.domain_warp_fractal_lacunarity = 3.0
	_heightmap_noise.domain_warp_fractal_octaves = 8
	_heightmap_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_heightmap_noise.domain_warp_frequency = 0.1
	_heightmap_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED
func setup_contnoise():  #continentialness - determines where oceans and higher areas are
	_cont_noise.seed = GameManager.seeds[1]
	_cont_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cont_noise.frequency = 0.00014
	_cont_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	_cont_noise.fractal_octaves = 12
	_cont_noise.fractal_lacunarity = 1.920
	_cont_noise.fractal_gain = 0.510
	_cont_noise.fractal_weighted_strength = 0.750
	_cont_noise.fractal_ping_pong_strength = 2.0
	_cont_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_cont_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_cont_noise.cellular_jitter = 1.0
	_cont_noise.domain_warp_enabled = true
	_cont_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
	_cont_noise.domain_warp_amplitude = 25.0
	_cont_noise.domain_warp_frequency = 0.0601
	_cont_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_cont_noise.domain_warp_fractal_octaves = 8
	_cont_noise.domain_warp_fractal_lacunarity = 2.710
	_cont_noise.domain_warp_fractal_gain = 0.460
func setup_erosion(): #determines how exxagerated the local noise is as well as some other factors
	_erosion_noise.seed = GameManager.seeds[2]
	_erosion_noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	_erosion_noise.frequency = 0.0021
	_erosion_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_erosion_noise.fractal_octaves = 8
	_erosion_noise.fractal_lacunarity = 2.0
	_erosion_noise.fractal_gain = 1.1
	_erosion_noise.fractal_weighted_strength = 0.35
	_erosion_noise.fractal_ping_pong_strength = 10.0
	#_erosion_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	#_erosion_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	#_erosion_noise.cellular_jitter = 1.0
	#_erosion_noise.domain_warp_enabled = false
	#_erosion_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
	#_erosion_noise.domain_warp_amplitude = 25.0
	#_erosion_noise.domain_warp_frequency = 0.2
	#_erosion_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_PROGRESSIVE
	#_erosion_noise.domain_warp_fractal_octaves = 8
	#_erosion_noise.domain_warp_fractal_lacunarity = 1.0
	#_erosion_noise.domain_warp_fractal_gain = 2.0
func setup_humidity():
	_humidity_noise.seed = GameManager.seeds[3]
	_humidity_noise.frequency = 0.0035
	_humidity_noise.fractal_octaves = 10
	_humidity_noise.fractal_gain = 0.8
func setup_temperature():
	_temperature_noise.seed = GameManager.seeds[4]
	_temperature_noise.frequency = 0.00025
	_temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	_temperature_noise.fractal_octaves = 7
	_temperature_noise.fractal_lacunarity = 3.0
	_temperature_noise.fractal_gain = 0.75
func setup_randnoise():
	_randvalue_noise.seed = GameManager.seeds[5]
	_randvalue_noise.noise_type = FastNoiseLite.TYPE_VALUE
func setup_base_soil_depth():
	_base_soil_depth_noise.seed = GameManager.seeds[6]
	_base_soil_depth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
func setup_base_dirt_depth():
	_base_dirt_depth_noise.seed = GameManager.seeds[7]
	_base_dirt_depth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
func setup_world_amplitude_noise():
	_world_amplitude_noise.seed = GameManager.seeds[8]
	_world_amplitude_noise.frequency = 0.000006
	_world_amplitude_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_world_amplitude_noise.domain_warp_enabled = true
	_world_amplitude_noise.domain_warp_frequency = 0.0000012
func setup_geologic_province_noise():
	_geologic_province_noise.seed = GameManager.seeds[9]
	_geologic_province_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_geologic_province_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, _unused_lod: int):
	# TODO There is an issue doing this, need to investigate why because it should be supported
	# Saves from this demo used 8-bit, which is no longer the default
	# buffer.set_channel_depth(_CHANNEL, VoxelBuffer.DEPTH_8_BIT)
	# Assuming input is cubic in our use case (it doesn't have to be!)
	var block_size := int(buffer.get_size().x)
	# TODO This hardcodes a cubic block size of 16, find a non-ugly way...
	# Dividing is a false friend because of negative values
	var chunk_pos := Vector3i(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)
	# Ground
	
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(chunk_pos)
	for z in block_size:
		var real_z: int = origin_in_voxels.z + z
		for x in block_size:
			var real_x: int = origin_in_voxels.x + x
			var terrain_values: Dictionary = get_terrain_values(real_x, real_z)
			#used to determine what can grow here.  Soil matters much more than dirt
			var saturation: float = terrain_values.humidity - terrain_values.drainage
			var fertility: float = clamp01(0.3*(terrain_values.true_soil_depth / _base_soil_depth_amp ) + (terrain_values.true_dirt_depth / _base_dirt_depth_amp))
			var rockyness: float = clamp01(terrain_values.general_slope / 35.0)
			var height_in_blocks: int = roundi(terrain_values.height)
			for y in block_size:
				var real_y: int = origin_in_voxels.y + y
				if real_y > height_in_blocks:
					if real_y < sea_level:
						buffer.set_voxel(GRASS, x, y, z) #replace with watter once added
					else:
						buffer.set_voxel(AIR, x, y, z)
						#surface layer
				elif real_y == height_in_blocks:
					if terrain_values.drainage > 0.3: #if the drainage is not super low or super high then do grass
						if terrain_values.drainage < 0.7:
							if fertility < 0.05:
								buffer.set_voxel(DIRT, x, y, z)
							elif fertility < 0.45:
								buffer.set_voxel(SPARSE_GRASS, x, y, z)
							else:
								buffer.set_voxel(GRASS, x, y, z)
						else: #if the drainage is very high then sparse grass is much better at growing, but if it is too rocky it cannot
							if rockyness > 0.35:
								buffer.set_voxel(GRANITE, x, y, z)
							else:
								if fertility < 0.1:
									buffer.set_voxel(DIRT, x, y, z)
								elif fertility < 0.65:
									buffer.set_voxel(SPARSE_GRASS, x, y, z)
								else:
									buffer.set_voxel(GRASS, x, y, z)
					elif saturation > 0.6:
						buffer.set_voxel(MUDDY_SOIL, x, y, z)
					elif saturation > 0.3:
						buffer.set_voxel(GRASS, x, y, z)
					else:
						buffer.set_voxel(SPARSE_GRASS, x, y, z)
				#soil stuff
				else:
					if real_y >= height_in_blocks - terrain_values.true_soil_depth:
						if terrain_values.drainage > 0.3:
							buffer.set_voxel(SOIL, x, y, z)
						else:
							buffer.set_voxel(MUDDY_SOIL, x, y, z)
					elif real_y >= height_in_blocks - terrain_values.true_dirt_depth:
						buffer.set_voxel(DIRT, x, y, z)
					else: #everything below the surface
						buffer.set_voxel(GRANITE, x, y, z)
	buffer.compress_uniform_channels()


func get_terrain_values(x: int, z: int):
	var terrain_values := {}
	#primary values
	terrain_values.continental_height = _cont_curve.sample(_cont_noise.get_noise_2d(x, z)) * _cont_amp
	terrain_values.local_height = _heightmap_noise.get_noise_2d(x, z) * _heightmap_amp
	terrain_values.erosion = _erosion_curve.sample(_erosion_noise.get_noise_2d(x, z))
	terrain_values.height = get_terrain_height(x, z)
	terrain_values.temperature = _temperature_noise.get_noise_2d(x, z)
	terrain_values.humidity = 1.0 + _humidity_noise.get_noise_2d(x, z)
	terrain_values.base_soil_depth = 1.0 + abs(1.0 + _base_dirt_depth_noise.get_noise_2d(x, z)) * _base_soil_depth_amp
	terrain_values.base_dirt_depth = 1.0 + abs(1.0 + _base_dirt_depth_noise.get_noise_2d(x, z)) * _base_dirt_depth_amp
	terrain_values.geologic_province_value = _geologic_province_noise.get_noise_2d(x, z)
	#secondary values
	if terrain_values.geologic_province_value < -0.65:
		terrain_values.geologic_province = GeologicProvence.Oriogen
	elif terrain_values.geologic_province_value < -0.15:
		terrain_values.geologic_province = GeologicProvence.Platform
	elif terrain_values.geologic_province_value < 0.15:
		terrain_values.geologic_province = GeologicProvence.Basin
	elif terrain_values.geologic_province_value < 0.85:
		terrain_values.geologic_province = GeologicProvence.ExtendedCrust
	else:
		terrain_values.geologic_province = GeologicProvence.LargeIgneousProvence
	
	terrain_values.local_steepness = get_terrain_steepness(x, z, 1.0)
	terrain_values.general_slope = get_terrain_steepness(x, z, 13.0)
	#tertiary values
	terrain_values.actual_steepness = terrain_values.local_steepness + (terrain_values.general_slope / 13.0)
	terrain_values.true_soil_depth = terrain_values.base_soil_depth - (2.75 * lerp(terrain_values.local_steepness, terrain_values.general_slope, 0.3))
	terrain_values.true_dirt_depth = terrain_values.base_dirt_depth - (2.25 * lerp(terrain_values.local_steepness, terrain_values.general_slope, 0.3))
	terrain_values.drainage = clamp01(abs(terrain_values.humidity - terrain_values.actual_steepness))
	
	return terrain_values

func get_terrain_height(x: float, z: float):
	var cont: float = _cont_curve.sample(_cont_noise.get_noise_2d(x, z)) * _cont_amp
	var erosion: float = _erosion_curve.sample(_erosion_noise.get_noise_2d(x, z))
	var local: float = _heightmap_noise.get_noise_2d(x, z) * _heightmap_amp
	var amp: float = get_terrain_amplitude(x, z)
	return (cont * amp) + (local * max(erosion-(amp-1.0), 0.0))

func get_terrain_amplitude(x: float, z: float):
	var S: float = _world_amplitude_noise.get_noise_2d(x, z)
	S = (S + 1.0) * 0.5
	var a: float = 1.0
	var A: float = (0.01 + S)**(-a)
	return A

func get_terrain_steepness(x: float, z: float, scale: float):
	var hN = (get_terrain_height(x+scale, z))
	var hS = (get_terrain_height(x-scale, z))
	var hE = (get_terrain_height(x, z+scale))
	var hW = (get_terrain_height(x, z-scale))
	var dx = (hN - hS)
	var dz = (hE - hW)
	return sqrt(dx*dx + dz*dz)

func clamp01(value: float) -> float:
	return clamp(value, 0, 1)

#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3i) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))
