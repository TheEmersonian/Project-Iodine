extends VoxelGeneratorScript

#const Structure = preload("./structure.gd")
#const TreeGenerator = preload("./tree_generator.gd")
#const HeightmapCurve = preload("./heightmap_curve.tres")

# TODO Don't hardcode, get by name from library somehow
const AIR = 0
const WHITE_GRANITE = 1
const SOIL = 2
const DIRT = 3
const GRASS = 4
const SPARSE_GRASS = 5
const MUDDY_SOIL = 6
const ERROR = 7 #BUG TEMP SET TO 0 FOR TESTING, should be 7 #block that is supposed to indicate an errror
const BASALT = 8
const RHYOLITE = 9
const BLACK_GRANITE = 10
const PINK_GRANITE = 11
const RED_GRANITE = 12
const GNEISS = 13

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

enum GeologicProvince {
	Shield, #plutonic, granite, granodiorite, high grade metemorphic
	Platform, #sedementary should be mostly horizontal and filling in the lower areas
	Oriogen, #
	Basin, #
	LargeIgneousProvince, #lots of igneous rock on the surface, flooding not following heightmap
	ExtendedCrust, #
}
enum RockType {
	Rhyolite,
	Granite,
	BlackGranite,
	Granodiorite,
	Diorite,
	Basalt,
	Gneiss,
}
#an overly long name but unfortunately this stuff is kinda complex and I don't want a bunch of abbreviations
class RockVariantGenerationDefinition:
	##The threshold the rock type noise must be below for the type to generate, generally will be between -1 and 1
	var threshold: float
	##The type of rock
	var type: int
	func _init(thr: float, typ: int) -> void:
		threshold = thr
		type = typ
#assuming we start at y=0 for now
var ProvinceSettings := {
	"Shield": {
		"Plutonic": {
			"max_depth": 350,
			"variant_frequency": 0.007,
			"types": [
				RockVariantGenerationDefinition.new(-0.75, BLACK_GRANITE),
				RockVariantGenerationDefinition.new(-0.45, BLACK_GRANITE), #CHANGE TO BLUE GRANITE ONCE IT'S ADDED
				RockVariantGenerationDefinition.new(0.05, WHITE_GRANITE),
				RockVariantGenerationDefinition.new(0.55, RED_GRANITE),
				RockVariantGenerationDefinition.new(1.1, PINK_GRANITE),
				]
		},
		"Metamorphic": {
			"max_depth": 70,
			"variant_frequency": 0.002,
			"types": [
				RockVariantGenerationDefinition.new(2.0, GNEISS)
			]
		}
	}
}


var sea_level := 0

#absurd amount of noise, to be honest some of these could probably be re-used but it's fine
var _local_heightmap_amplitude := 43.0
var _local_heightmap_noise := FastNoiseLite.new()

var _general_heightmap_noise := FastNoiseLite.new()
@export var _general_heightmap_curve: Curve = preload("res://assets/curves/generation/general_heightmap_curve.tres")
var _general_heightmap_amplitude := 123.3

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
@export var _world_amplification_curve: Curve = preload("res://assets/curves/generation/amplification_curve.tres")

var _geologic_province_noise := FastNoiseLite.new()

var _plutonic_depth_noise := FastNoiseLite.new()
var _metamorphic_depth_noise := FastNoiseLite.new()
var _sedimentary_depth_noise := FastNoiseLite.new()


var _rock_variant_noise := FastNoiseLite.new()

func _init():
	setup_local_heightmap_noise()
	setup_general_heightmap_noise()
	setup_erosion()
	setup_humidity()
	setup_temperature()
	setup_randnoise()
	setup_base_soil_depth()
	setup_base_dirt_depth()
	setup_world_amplitude_noise()
	setup_geologic_province_noise()
	setup_plutonic_depth_noise()
	setup_metamorphic_depth_noise()
	setup_sedimentary_depth_noise()
	setup_rock_variant_noise()

func setup_local_heightmap_noise():  #local heightmap - determines local height variation
	_local_heightmap_noise.seed = 0
	_local_heightmap_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_local_heightmap_noise.fractal_octaves = 13
	_local_heightmap_noise.frequency = 0.004
	_local_heightmap_noise.fractal_gain = 0.3
	_local_heightmap_noise.fractal_weighted_strength = 0.5
	_local_heightmap_noise.domain_warp_enabled = true
	_local_heightmap_noise.domain_warp_amplitude = 5
	_local_heightmap_noise.domain_warp_fractal_gain = 0.5
	_local_heightmap_noise.domain_warp_fractal_lacunarity = 3.0
	_local_heightmap_noise.domain_warp_fractal_octaves = 8
	_local_heightmap_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_local_heightmap_noise.domain_warp_frequency = 0.1
	_local_heightmap_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED
func setup_general_heightmap_noise():  #continentialness - determines where oceans and higher areas are
	_general_heightmap_noise.seed = 0
	_general_heightmap_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_general_heightmap_noise.frequency = 0.00014
	_general_heightmap_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	_general_heightmap_noise.fractal_octaves = 12
	_general_heightmap_noise.fractal_lacunarity = 1.920
	_general_heightmap_noise.fractal_gain = 0.510
	_general_heightmap_noise.fractal_weighted_strength = 0.750
	_general_heightmap_noise.fractal_ping_pong_strength = 2.0
	_general_heightmap_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_general_heightmap_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_general_heightmap_noise.cellular_jitter = 1.0
	_general_heightmap_noise.domain_warp_enabled = true
	_general_heightmap_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
	_general_heightmap_noise.domain_warp_amplitude = 25.0
	_general_heightmap_noise.domain_warp_frequency = 0.0601
	_general_heightmap_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_general_heightmap_noise.domain_warp_fractal_octaves = 8
	_general_heightmap_noise.domain_warp_fractal_lacunarity = 2.710
	_general_heightmap_noise.domain_warp_fractal_gain = 0.460
func setup_erosion(): #determines how exxagerated the local noise is as well as some other factors
	_erosion_noise.seed = 0
	_erosion_noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	_erosion_noise.frequency = 0.00021
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
	_humidity_noise.seed = 0
	_humidity_noise.frequency = 0.0035
	_humidity_noise.fractal_octaves = 10
	_humidity_noise.fractal_gain = 0.8
func setup_temperature():
	_temperature_noise.seed = 0
	_temperature_noise.frequency = 0.00025
	_temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	_temperature_noise.fractal_octaves = 7
	_temperature_noise.fractal_lacunarity = 3.0
	_temperature_noise.fractal_gain = 0.75
func setup_randnoise():
	_randvalue_noise.seed = 0
	_randvalue_noise.noise_type = FastNoiseLite.TYPE_VALUE
func setup_base_soil_depth():
	_base_soil_depth_noise.seed = 0
	_base_soil_depth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
func setup_base_dirt_depth():
	_base_dirt_depth_noise.seed = 0
	_base_dirt_depth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
func setup_world_amplitude_noise():
	_world_amplitude_noise.seed = 0
	_world_amplitude_noise.frequency = 0.000003
	_world_amplitude_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_world_amplitude_noise.domain_warp_enabled = true
	_world_amplitude_noise.domain_warp_frequency = 0.00000125
func setup_geologic_province_noise():
	_geologic_province_noise.seed = 0
	_geologic_province_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_geologic_province_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
func setup_plutonic_depth_noise():
	_plutonic_depth_noise.seed = 0
	_plutonic_depth_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_plutonic_depth_noise.frequency = 0.00084
	_plutonic_depth_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_plutonic_depth_noise.fractal_octaves = 5
	_plutonic_depth_noise.fractal_gain = 0.8
	_plutonic_depth_noise.fractal_weighted_strength = 1.5
func setup_metamorphic_depth_noise():
	_metamorphic_depth_noise.seed = 0
func setup_sedimentary_depth_noise():
	_sedimentary_depth_noise.seed = 0
	_sedimentary_depth_noise.frequency = 0.005
	_sedimentary_depth_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_sedimentary_depth_noise.fractal_octaves = 3
	_sedimentary_depth_noise.fractal_weighted_strength = 1.0
func setup_rock_variant_noise():
	_rock_variant_noise.seed = 0
	_rock_variant_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_rock_variant_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_rock_variant_noise.fractal_octaves = 5
	_rock_variant_noise.cellular_distance_function = FastNoiseLite.DISTANCE_MANHATTAN
	_rock_variant_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_rock_variant_noise.cellular_jitter = 2.0
	_rock_variant_noise.domain_warp_enabled = true
	_rock_variant_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
	_rock_variant_noise.domain_warp_amplitude = 50.0
	_rock_variant_noise.domain_warp_frequency = 0.02
	_rock_variant_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_rock_variant_noise.domain_warp_fractal_octaves = 5

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
			#geology
			var geology_values: Dictionary = compute_geology(terrain_values, real_x, real_z)
			#used to determine what can grow here.  Soil matters much more than dirt
			var saturation: float = terrain_values.humidity - terrain_values.drainage
			var fertility: float = clamp01(0.3*(terrain_values.true_soil_depth / _base_soil_depth_amp ) + (terrain_values.true_dirt_depth / _base_dirt_depth_amp))
			var rockyness: float = clamp01(terrain_values.general_slope / 35.0)
			var height_in_blocks: int = roundi(terrain_values.height)
			for y in block_size:
				var real_y: int = origin_in_voxels.y + y
				if real_y > height_in_blocks:
					#continue #BUG: CURRENTLY WORKING ON GEOLOGY, skipping surface blocks for now
					if real_y < sea_level:
						buffer.set_voxel(GRASS, x, y, z) #replace with watter once added
					else:
						buffer.set_voxel(AIR, x, y, z)
						#surface layer
				elif real_y == height_in_blocks:
					#continue #BUG: CURRENTLY WORKING ON GEOLOGY, skipping surface blocks for now
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
								buffer.set_voxel(rock_type_at_point(real_x, real_y, real_z, geology_values, terrain_values.geologic_province), x, y, z)
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
					buffer.set_voxel(rock_type_at_point(real_x, real_y, real_z, geology_values, terrain_values.geologic_province), x, y, z)
					#continue #BUG: CURRENTLY WORKING ON GEOLOGY, skipping surface blocks for now
					if real_y >= height_in_blocks - terrain_values.true_soil_depth:
						if terrain_values.drainage > 0.3:
							buffer.set_voxel(SOIL, x, y, z)
						else:
							buffer.set_voxel(MUDDY_SOIL, x, y, z)
					elif real_y >= height_in_blocks - terrain_values.true_dirt_depth:
						buffer.set_voxel(DIRT, x, y, z)
					else: #everything below the surface is in it's own function
						buffer.set_voxel(rock_type_at_point(real_x, real_y, real_z, geology_values, terrain_values.geologic_province), x, y, z)
	buffer.compress_uniform_channels()

func rock_type_at_point(x: float, y: float, z: float, geology_values: Dictionary, province: GeologicProvince):
	var rock_type: int = AIR
	match province:
		GeologicProvince.Shield:
			var ShieldSettings: Dictionary = ProvinceSettings.Shield
			if y > geology_values.plutonic_layer_range[0] and y < geology_values.plutonic_layer_range[1]:
				var PlutonicSettings: Dictionary = ShieldSettings.Plutonic
				_rock_variant_noise.frequency = PlutonicSettings.variant_frequency
				var plutonic_variant_value: float = _rock_variant_noise.get_noise_3d(x, y, z)
				var plutonic_variant_type: int = ERROR
				for t in PlutonicSettings.types:
					if plutonic_variant_value < t.threshold:
						plutonic_variant_type = t.type
						break
				rock_type = plutonic_variant_type
			elif y > geology_values.metamorphic_layer_range[0] and y < geology_values.metamorphic_layer_range[1]:
				var MetamorphicSettings: Dictionary = ShieldSettings.Metamorphic
				_rock_variant_noise.frequency = MetamorphicSettings.variant_frequency
				var metamorphic_variant_value: float = _rock_variant_noise.get_noise_3d(x, y, z)
				var metamorphic_variant_type: int = ERROR
				for t in MetamorphicSettings.types:
					if metamorphic_variant_value < t.threshold:
						metamorphic_variant_type = t.type
						break
				rock_type = metamorphic_variant_type
	return rock_type
	

func compute_geology(terrain_values: Dictionary, x: int, z: int):
	var geology_values := {}
	match terrain_values.geologic_province:
		GeologicProvince.Shield:
			var ShieldSettings: Dictionary = ProvinceSettings.Shield
			#plutonic Layer
			var plutonic_depth_max: float = ShieldSettings.Plutonic.max_depth
			var normalized_pdepth: float = 1.0 + _plutonic_depth_noise.get_noise_2d(x, z) #eventually we will want to generate a second heightmap for these
			var actual_pdepth: float = normalized_pdepth * plutonic_depth_max
			geology_values.plutonic_layer_range = [0, actual_pdepth]
			#metemorphic layer
			var metamorphic_depth_max: float = ShieldSettings.Metamorphic.max_depth
			var normalized_mdepth: float = 1.0 + _metamorphic_depth_noise.get_noise_2d(x, z)
			var actual_mdepth: float = normalized_mdepth * metamorphic_depth_max
			geology_values.metamorphic_layer_range = [actual_pdepth, actual_pdepth+actual_mdepth]
			#actual sections
			
	return geology_values

func get_terrain_values(x: int, z: int):
	var terrain_values := {}
	#primary values
	terrain_values.continental_height = _general_heightmap_curve.sample(_general_heightmap_noise.get_noise_2d(x, z)) * _general_heightmap_amplitude
	terrain_values.local_height = _local_heightmap_noise.get_noise_2d(x, z) * _local_heightmap_amplitude
	terrain_values.erosion = _erosion_curve.sample(_erosion_noise.get_noise_2d(x, z))
	terrain_values.height = get_terrain_height(x, z)
	terrain_values.temperature = _temperature_noise.get_noise_2d(x, z)
	terrain_values.humidity = 1.0 + _humidity_noise.get_noise_2d(x, z)
	terrain_values.base_soil_depth = 1.0 + abs(1.0 + _base_dirt_depth_noise.get_noise_2d(x, z)) * _base_soil_depth_amp
	terrain_values.base_dirt_depth = 1.0 + abs(1.0 + _base_dirt_depth_noise.get_noise_2d(x, z)) * _base_dirt_depth_amp
	terrain_values.geologic_province_value = _geologic_province_noise.get_noise_2d(x, z)
	#secondary values
	if terrain_values.geologic_province_value < 0.75:
		terrain_values.geologic_province = GeologicProvince.Shield
	elif terrain_values.geologic_province_value < -0.65:
		terrain_values.geologic_province = GeologicProvince.Platform
	elif terrain_values.geologic_province_value < -0.15:
		terrain_values.geologic_province = GeologicProvince.Oriogen
	elif terrain_values.geologic_province_value < 0.15:
		terrain_values.geologic_province = GeologicProvince.Basin
	elif terrain_values.geologic_province_value < 0.85:
		terrain_values.geologic_province = GeologicProvince.ExtendedCrust
	else:
		terrain_values.geologic_province = GeologicProvince.LargeIgneousProvince
	#BUG: not actually a bug just remember to disable this ovveride later
	terrain_values.geologic_province = GeologicProvince.Shield
	
	terrain_values.local_steepness = get_terrain_steepness(x, z, 1.0)
	terrain_values.general_slope = get_terrain_steepness(x, z, 13.0)
	#tertiary values
	terrain_values.actual_steepness = terrain_values.local_steepness + (terrain_values.general_slope / 13.0)
	terrain_values.true_soil_depth = terrain_values.base_soil_depth - (2.75 * lerp(terrain_values.local_steepness, terrain_values.general_slope, 0.3))
	terrain_values.true_dirt_depth = terrain_values.base_dirt_depth - (2.25 * lerp(terrain_values.local_steepness, terrain_values.general_slope, 0.3))
	terrain_values.drainage = clamp01(abs(terrain_values.humidity - terrain_values.actual_steepness))
	
	return terrain_values

func get_terrain_height(x: float, z: float):
	var general: float = _general_heightmap_curve.sample(_general_heightmap_noise.get_noise_2d(x, z)) * _general_heightmap_amplitude
	var erosion: float = _erosion_curve.sample(_erosion_noise.get_noise_2d(x, z))
	var local: float = _local_heightmap_noise.get_noise_2d(x, z) * _local_heightmap_amplitude
	var amp: float = _world_amplification_curve.sample(get_terrain_amplitude(x, z))
	return (general * amp) + (local * max(erosion-(amp-1.0), 0.0))

func get_terrain_amplitude(x: float, z: float):
	var S: float = _world_amplitude_noise.get_noise_2d(x, z)
	S = (S + 1.0) * 0.5
	var a: float = 0.75
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
