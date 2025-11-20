@abstract
extends Node3D

class_name TileEntity

var chunk_ref
var blockpos: Vector3i

func _init(current_chunk, current_pos: Vector3i) -> void:
	chunk_ref = current_chunk
	blockpos = current_pos

@abstract
func _place()

@abstract
func _tick()

@abstract
func _broken()

@abstract
func _interacted()
