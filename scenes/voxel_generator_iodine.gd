extends VoxelGeneratorScript

#const Structure = preload("./structure.gd")
#const TreeGenerator = preload("./tree_generator.gd")
#const HeightmapCurve = preload("./heightmap_curve.tres")

# TODO Don't hardcode, get by name from library somehow
const AIR = 0
const GRANITE = 1
const SOIL = 2
const DIRT = 3
const WATER_FULL = 14
const WATER_TOP = 13
const LOG = 4
const LEAVES = 25
const TALL_GRASS = 8
const DEAD_SHRUB = 26
#const STONE = 8

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

const _moore_dirs: Array[Vector3i] = [
	Vector3i(-1, 0, -1),
	Vector3i(0, 0, -1),
	Vector3i(1, 0, -1),
	Vector3i(-1, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 1),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1)
]



var _heightmap_min_y := 0
var _heightmap_max_y := 50
var _heightmap_range := 0
var _heightmap_noise := FastNoiseLite.new()

func _init():
	_heightmap_noise.seed = 1
	_heightmap_noise.fractal_octaves = 13
	_heightmap_noise.frequency = 0.01
	_heightmap_noise.fractal_gain = 0.03
	_heightmap_noise.domain_warp_enabled = true
	_heightmap_noise.domain_warp_amplitude = 15
	_heightmap_noise.domain_warp_fractal_gain = 0.5
	_heightmap_noise.domain_warp_fractal_lacunarity = 3.0
	_heightmap_noise.domain_warp_fractal_octaves = 8
	_heightmap_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_INDEPENDENT
	_heightmap_noise.domain_warp_frequency = 0.01
	_heightmap_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX_REDUCED


func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, _unused_lod: int):
	# TODO There is an issue doing this, need to investigate why because it should be supported
	# Saves from this demo used 8-bit, which is no longer the default
	# buffer.set_channel_depth(_CHANNEL, VoxelBuffer.DEPTH_8_BIT)
	# Assuming input is cubic in our use case (it doesn't have to be!)
	var block_size := int(buffer.get_size().x)
	var oy := origin_in_voxels.y
	# TODO This hardcodes a cubic block size of 16, find a non-ugly way...
	# Dividing is a false friend because of negative values
	var chunk_pos := Vector3i(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)

	_heightmap_range = _heightmap_max_y - _heightmap_min_y

	# Ground

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(AIR, _CHANNEL)

	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(DIRT, _CHANNEL)

	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _get_chunk_seed_2d(chunk_pos)
		
		var gx: int
		var gz := origin_in_voxels.z

		for z in block_size:
			gx = origin_in_voxels.x

			for x in block_size:
				var real_x: int = origin_in_voxels.x + x
				var real_z: int = origin_in_voxels.z + z
				var height := _heightmap_noise.get_noise_2d(real_x, real_z) * 24.0
				var relative_height := height - oy
				
				# Dirt and grass
				if relative_height > block_size:
					buffer.fill_area(DIRT,
						Vector3i(x, 0, z), Vector3i(x + 1, block_size, z + 1), _CHANNEL)
				elif relative_height > 0:
					buffer.fill_area(DIRT,
						Vector3i(x, 0, z), Vector3i(x + 1, relative_height, z + 1), _CHANNEL)
					if height >= 0:
						buffer.set_voxel(SOIL, x, relative_height - 1, z, _CHANNEL)
						if relative_height < block_size and rng.randf() < 0.2:
							var foliage = TALL_GRASS
							if rng.randf() < 0.1:
								foliage = DEAD_SHRUB
							buffer.set_voxel(DIRT, x, relative_height, z, _CHANNEL)
				
				# Water
				if height < 0 and oy < 0:
					var start_relative_height := 0
					if relative_height > 0:
						start_relative_height = relative_height
					buffer.fill_area(WATER_FULL,
						Vector3i(x, start_relative_height, z),
						Vector3i(x + 1, block_size, z + 1), _CHANNEL)
					if oy + block_size == 0:
						# Surface block
						buffer.set_voxel(WATER_TOP, x, block_size - 1, z, _CHANNEL)
						
				gx += 1
			gz += 1

	buffer.compress_uniform_channels()



#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3i) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))
