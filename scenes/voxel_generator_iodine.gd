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
const ERROR = 7 
const BASALT = 8
const RHYOLITE = 9
const BLACK_GRANITE = 10
const PINK_GRANITE = 11
const RED_GRANITE = 12
const GNEISS = 13
const MAFIC_SANDSTONE = 14

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

##More eras leads to more erosion
const GEOLOGIC_ERAS := 15
##a stronger erosion factor leads to more erosion
const EROSION_FACTOR := 12.5

enum GeologicProvince {
	Shield, #plutonic, granite, granodiorite, high grade metemorphic
	Platform, #sedementary should be mostly horizontal and filling in the lower areas
	Oriogen, #
	Basin, #
	LargeIgneousProvince, #lots of igneous rock on the surface, flooding not following heightmap
	ExtendedCrust, #
}
enum RockType {
	Plutonic,
	Metamorphic,
	Sedimentary,
}

class BiomeSurfaceBlock:
	var block: int
	##Should be a number between 0-1, the chance that the block gets placed
	var chance: float
	##Between -1.0 and 1.0
	var hmid: float
	##Between -1.0 and 1.0
	var temp: float
	##Sediment depth, the value will probably be somewhere between 0 and 10
	var depth: float
	##Where the block is in the sediment columb.  Scale from 0-1 (bottom to top)
	var height: float
	func _init(surface_block: int, place_chance: float, humidity: float, temperature: float, sediment_depth: float, sediment_height: float) -> void:
		block = surface_block
		chance = place_chance
		hmid = humidity
		temp = temperature
		depth = sediment_depth
		height = sediment_height
	func _get_distance(other: BiomeSurfaceBlock) -> float:
		return sqrt(pow(other.temp-temp, 2.0)+pow(other.hmid-hmid, 2.0)+pow(other.depth-depth, 2.0)+pow((other.height-height) * depth, 2.0))
	##Returns a dictionary with the best surface block and dist
	func _get_best_dist(others: Array, use_chance: bool = false):
		var best_dist := INF
		var best_surface: BiomeSurfaceBlock
		if !use_chance:
			for i in others.size():
				var test_surface: BiomeSurfaceBlock = others[i]
				var dist := _get_distance(test_surface)
				if dist < best_dist:
					best_dist = dist
					best_surface = test_surface
		else: #if chance is considered then....... consider the chance
			for i in others.size():
				var test_surface: BiomeSurfaceBlock = others[i]
				if not randf() < test_surface.chance:
					continue
				var dist := _get_distance(test_surface)
				if dist < best_dist:
					best_dist = dist
					best_surface = test_surface
		return {"best_surface": best_surface, "best_dist": best_dist}

class BiomeType:
	var name: String
	var surface_blocks: Array[BiomeSurfaceBlock]
	##Ideal Temperature location
	var temp: float
	##Ideal Humidity location
	var hmid: float
	##Ideal Mana Saturation location
	var msat: float
	##Ideal Mana Density location
	var mden: float
	##Ideal Basin location (tbh idk exactly what this really means yet, I mean I do but what it means for the biome I am somewhat unsure)
	var base: float
	func _init(biome_name: String, surface_block_array: Array[BiomeSurfaceBlock], temperature: float, humidity: float, mana_saturation: float, mana_density: float, basin_value: float) -> void:
		name = biome_name
		surface_blocks = surface_block_array
		temp = temperature
		hmid = humidity
		msat = mana_saturation
		mden = mana_density
		base = basin_value
	func _get_distance(other: BiomeType) -> float:
		return sqrt(pow(other.temp-temp, 2.0)+pow(other.hmid-hmid, 2.0)+pow(other.msat-msat, 2.0)+pow(other.mden-mden, 2.0)+pow(other.base-base, 2.0))
	##Returns a dictionary with the best biome and dist
	func _get_best_dist(others: Array[BiomeType]):
		var best_dist := INF
		var best_biome: BiomeType
		for i in others.size():
			var test_biome: BiomeType = others[i]
			var dist := _get_distance(test_biome)
			if dist < best_dist:
				best_dist = dist
				best_biome = test_biome
		return {"best_biome": best_biome, "best_dist": best_dist}

var biome_tables := {}
var sea_level := 0

#absurd amount of noise, to be honest some of these could probably be re-used but it's fine
##Controls the general thickness and scale of the crust
var _general_crust_thickness := 500.0
##An extremely low frequency noise that determines the height of the crust before erosion
var _rock_ceiling_depth_noise := FastNoiseLite.new() 
##Controls how extreme positive amplification of the crust gets.  This value is applied exponentially, not linearly
var _amplification_extremeness := 3.0
##An extremely low frequency noise that gives rise to very thick and somewhat thin sections of crust
var _rock_ceiling_amplification_noise := FastNoiseLite.new()
#don't really know what to call these two variables
var _thin_crust_k := 0.4
var _thin_crust_q := 0.95
##Controls where basins want to form, extremely low frequency.  THIS ALSO USES _general_crust_thickness
var _basin_level_noise := FastNoiseLite.new()

##Determines magical saturation.  Saturation is how much magic there is
var _mana_saturation_noise := FastNoiseLite.new()
##Determines magical density.  Density is how strong the magic is
var _mana_density_noise := FastNoiseLite.new()



var _humidity_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()

var _randvalue_noise := FastNoiseLite.new()

#determines where the really crazy stuff happens
var _world_amplitude_noise := FastNoiseLite.new()

var _geologic_province_noise := FastNoiseLite.new()

var _plutonic_depth_noise := FastNoiseLite.new()
var _metamorphic_depth_noise := FastNoiseLite.new()
var _sedimentary_depth_noise := FastNoiseLite.new()


var _rock_variant_noise := FastNoiseLite.new()

func _init():
	create_surface_block_table()
	setup_rock_ceiling_depth_noise()
	setup_rock_ceiling_amplification_noise()
	setup_basin_level_noise()
	setup_mana_saturation_noise()
	setup_mana_density_noise()
	setup_humidity()
	setup_temperature()
	setup_geologic_province_noise()
	setup_rock_variant_noise()

func create_surface_block_table():
	var surface_blocks := []
	surface_blocks.append(BiomeSurfaceBlock.new(GRASS, 0.8, 0.3, 0.3, 5.0, 1.5))
	surface_blocks.append(BiomeSurfaceBlock.new(SPARSE_GRASS, 0.8, -0.3, -0.3, 4.0, 1.5))
	surface_blocks.append(BiomeSurfaceBlock.new(SOIL, 1.0, 0.2, 0.3, 2.8, 0.6))
	surface_blocks.append(BiomeSurfaceBlock.new(DIRT, 1.0, -0.3, 0.4, 1.2, 0.5))
	surface_blocks.append(BiomeSurfaceBlock.new(MUDDY_SOIL, 0.95, 0.8, -0.2, 2.2, 0.8))
	biome_tables["surface_blocks"] = surface_blocks
##Controls the rock ceiling, aka the amount of rock in a place before erosion.  
func setup_rock_ceiling_depth_noise(): 
	_rock_ceiling_depth_noise.seed = 0
	_rock_ceiling_depth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_rock_ceiling_depth_noise.fractal_octaves = 6
	_rock_ceiling_depth_noise.frequency = 0.000084
	_rock_ceiling_depth_noise.fractal_gain = 0.35
	_rock_ceiling_depth_noise.fractal_weighted_strength = 2.0
	_rock_ceiling_depth_noise.domain_warp_enabled = true
	_rock_ceiling_depth_noise.domain_warp_amplitude = 100.0
	_rock_ceiling_depth_noise.domain_warp_frequency = 0.01
	_rock_ceiling_depth_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_rock_ceiling_depth_noise.domain_warp_fractal_octaves = 4
	_rock_ceiling_depth_noise.domain_warp_fractal_lacunarity = 2.0
	_rock_ceiling_depth_noise.domain_warp_fractal_gain = 0.4
func setup_rock_ceiling_amplification_noise():
	_rock_ceiling_amplification_noise.seed = 0
	_rock_ceiling_amplification_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_rock_ceiling_amplification_noise.fractal_octaves = 5
	_rock_ceiling_amplification_noise.frequency = 0.00025
	_rock_ceiling_amplification_noise.fractal_gain = 0.4
	_rock_ceiling_amplification_noise.fractal_weighted_strength = 0.0
func setup_basin_level_noise():
	_basin_level_noise.seed = 1 #make sure it's different than rock_ceiling_depth
	_basin_level_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_basin_level_noise.fractal_octaves = 5
	_basin_level_noise.frequency = 0.00002
	_basin_level_noise.fractal_gain = 0.5
func setup_mana_saturation_noise():
	_mana_saturation_noise.seed = 0
	_mana_saturation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_mana_saturation_noise.frequency = 0.0001
	_mana_saturation_noise.fractal_octaves = 4
	_mana_saturation_noise.fractal_lacunarity = 2.0
	_mana_saturation_noise.fractal_gain = 0.6
	_mana_saturation_noise.fractal_weighted_strength = 2.5
func setup_mana_density_noise():
	_mana_density_noise.seed = 1 #make sure it's different than mana saturation
	_mana_density_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_mana_density_noise.frequency = 0.0001
	_mana_density_noise.fractal_octaves = 4
	_mana_density_noise.fractal_lacunarity = 2.0
	_mana_density_noise.fractal_gain = 0.6
	_mana_density_noise.fractal_weighted_strength = 2.5
func setup_humidity():
	_humidity_noise.seed = 0
	_humidity_noise.frequency = 0.00000625
	_humidity_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_humidity_noise.fractal_octaves = 10
	_humidity_noise.fractal_gain = 0.8
func setup_temperature():
	_temperature_noise.seed = 0
	_temperature_noise.frequency = 0.00000425
	_temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	_temperature_noise.fractal_octaves = 7
	_temperature_noise.fractal_lacunarity = 3.0
	_temperature_noise.fractal_gain = 0.75
func setup_randnoise():
	_randvalue_noise.seed = 0
	_randvalue_noise.noise_type = FastNoiseLite.TYPE_VALUE
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
	_rock_variant_noise.domain_warp_frequency = 0.005
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
	#calculate biome
	#var biomespace_pos: BiomeType = BiomeType.new("local", [],
	#_temperature_noise.get_noise_3dv(origin_in_voxels), 
	#_humidity_noise.get_noise_3dv(origin_in_voxels),
	#_mana_saturation_noise.get_noise_3dv(origin_in_voxels),
	#_mana_density_noise.get_noise_3dv(origin_in_voxels),
	#_basin_level_noise.get_noise_3dv(origin_in_voxels)
	#)
	
	
	for z in block_size:
		var real_z: int = origin_in_voxels.z + z
		for x in block_size:
			var real_x: int = origin_in_voxels.x + x
			##Do not use this for anything based on the actual surface
			var raw_crust_depth := _rock_ceiling_depth_noise.get_noise_2d(x, z)
			var crust_depth := rock_ceiling(real_x, real_z)
			var top_plutonic_layer := crust_depth
			var sediment_deposite := 0.0
			var loose_sediment := 0.0
			for g in range(GEOLOGIC_ERAS):
				#temp and humidity form the basis of erosion
				var era_temp: float = 1.0 + _temperature_noise.get_noise_3d(real_x, 0-((g*5.0)**1.5), real_z)
				var era_humid: float = 1.0 + _humidity_noise.get_noise_3d(real_x, 0-((g*5.0)**2), real_z)
				#the basin level determines how much sediment stays
				var basin_level := _basin_level_noise.get_noise_3d(real_x, 0-((g*50.0)**1.5), real_z)
				var basin_bias: float = clamp(basin_level - raw_crust_depth, 0.0, 100.0)
				var flatness := (basin_bias / (basin_bias + 1.5))
				var roughness := 1.0 - flatness
				var era_erosion: float = ((era_temp + era_humid + (g/float(GEOLOGIC_ERAS)))) * EROSION_FACTOR * roughness
				var erosion_power := era_erosion
				var erosion_remaining := erosion_power * 1.5
				var sediment_eroded: float = min(loose_sediment, erosion_remaining)
				loose_sediment -= sediment_eroded
				erosion_remaining -= sediment_eroded
				if erosion_power > 0.0:
					top_plutonic_layer -= (erosion_remaining * 0.65)
				var sediment_potential := era_erosion * 5.5 * (1.0 + flatness)
				
				var loose_sediment_generated := (sediment_potential * flatness)
				loose_sediment += loose_sediment_generated
				var sediment_deposited_this_era := 0.35 * (loose_sediment)
				sediment_deposite += (sediment_deposited_this_era / 2.5)
				loose_sediment -= sediment_deposited_this_era
				#loose_sediment *= 0.9
			#var crust_height_in_blocks: int = roundi(crust_depth)
			var sediment_deposite_in_blocks: int = ceil(sediment_deposite)
			var surface_height := top_plutonic_layer + sediment_deposite + loose_sediment
			var surface_height_in_blocks := roundi(surface_height)
			
			for y in block_size:
				var real_y: int = origin_in_voxels.y + y
				#only do more logic if the blocks can even be there, in the future we could also only do more logic on uneroded blocks
				if real_y <= surface_height:
					if real_y > surface_height_in_blocks - loose_sediment:
						var rock_start: float = surface_height_in_blocks - loose_sediment
						var position_in_sediment: float = (real_y-rock_start)/loose_sediment
						buffer.set_voxel(get_surface_block_at_pos(Vector3i(real_x, real_y, real_z), loose_sediment, position_in_sediment), x, y, z)
						continue
					var rock_type: RockType = RockType.Plutonic
					var overburden := crust_depth - real_y
					var mana_factor := (1.0 + _mana_saturation_noise.get_noise_3d(real_x, real_y, real_z)) * (1.0 + _mana_density_noise.get_noise_3d(real_x, real_y, real_z))
					var stress = overburden * (1.0 - mana_factor ) #eventually this will be a bit more complicated
					var metamorphic_threshold := 40.0
					if stress > metamorphic_threshold:
						rock_type = RockType.Metamorphic
					if real_y > surface_height_in_blocks - sediment_deposite_in_blocks:
						rock_type = RockType.Sedimentary
					if real_y <= surface_height_in_blocks:
						match rock_type:
							RockType.Plutonic: buffer.set_voxel(WHITE_GRANITE, x, y, z)
							RockType.Metamorphic: buffer.set_voxel(GNEISS, x, y, z)
							RockType.Sedimentary: buffer.set_voxel(MAFIC_SANDSTONE, x, y, z)
	buffer.compress_uniform_channels()

func get_surface_block_at_pos(pos: Vector3i, sediment_depth: float, sediment_height: float):
	var local := BiomeSurfaceBlock.new(7, 1.0, _humidity_noise.get_noise_3dv(pos), _temperature_noise.get_noise_3dv(pos), sediment_depth, sediment_height)
	var best_dict: Dictionary = local._get_best_dist(biome_tables.surface_blocks, true)
	var chosen_surface: BiomeSurfaceBlock = best_dict.best_surface
	return chosen_surface.block

func rock_ceiling(x, z) -> float:
	var crust_thickness: float = 1.0 + (_rock_ceiling_depth_noise.get_noise_2d(x, z) * 0.5)
	crust_thickness *= _general_crust_thickness
	var amplification_value: float = clamp(_rock_ceiling_amplification_noise.get_noise_2d(x, z), -1.0, 1.0)
	if amplification_value >= 0:
		amplification_value **= _amplification_extremeness
	else:
		amplification_value = -_thin_crust_k * (abs(amplification_value)**_thin_crust_q)
	amplification_value *= crust_thickness
	return crust_thickness

func decide_province(x: float, z: float) -> GeologicProvince:
	var geologic_province_value = _geologic_province_noise.get_noise_2d(x, z)
	var geologic_province_type: GeologicProvince = GeologicProvince.Shield
	#secondary values
	if geologic_province_value < 0.75:
		geologic_province_type = GeologicProvince.Shield
	elif geologic_province_value < -0.65:
		geologic_province_type = GeologicProvince.Platform
	elif geologic_province_value < -0.15:
		geologic_province_type = GeologicProvince.Oriogen
	elif geologic_province_value < 0.15:
		geologic_province_type = GeologicProvince.Basin
	elif geologic_province_value < 0.85:
		geologic_province_type = GeologicProvince.ExtendedCrust
	else:
		geologic_province_type = GeologicProvince.LargeIgneousProvince
	return geologic_province_type


func get_terrain_amplitude(x: float, z: float):
	var S: float = _world_amplitude_noise.get_noise_2d(x, z)
	S = (S + 1.0) * 0.5
	var a: float = 0.75
	var A: float = (0.01 + S)**(-a)
	return A


func clamp01(value: float) -> float:
	return clamp(value, 0, 1)

#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3i) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))
