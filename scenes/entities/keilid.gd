extends Node3D

#physics bodies and joints
@onready var head: RigidBody3D = $Head
@onready var torso: RigidBody3D = $Torso
@onready var waist: Generic6DOFJoint3D = $Waist
@onready var pelvis: RigidBody3D = $Pelvis
@onready var left_hip: Generic6DOFJoint3D = $LeftHip
@onready var left_thigh: RigidBody3D = $LeftThigh
@onready var left_nee: Generic6DOFJoint3D = $LeftNee
@onready var left_crus: RigidBody3D = $LeftCrus
@onready var left_ankle: Generic6DOFJoint3D = $LeftAnkle
@onready var left_foot: RigidBody3D = $LeftFoot
@onready var right_hip: Generic6DOFJoint3D = $RightHip
@onready var right_thigh: RigidBody3D = $RightThigh
@onready var right_nee: Generic6DOFJoint3D = $RightNee
@onready var right_crus: RigidBody3D = $RightCrus
@onready var right_ankle: Generic6DOFJoint3D = $RightAnkle
@onready var right_foot: RigidBody3D = $RightFoot

#camera
@onready var camera_3d: Camera3D = $Head/Camera3D
##The center of mass of all connected objects
@export var center_of_mass: Vector3
##A projection of the center of mass above the ground
var com_proj: Vector2

var connected_physics_objects := [] #all of these should have Node3D > Transform > Top Level set to true

##THIS DOESNT DO ANYTHing, maybe change that at some point but mostly its a thing to tell me how much I made the body weigh in total
var mass_distribution := { #not up to 100% yet
	"total": 100.0,
	"head": 10.0,
	"torso": 20.0,
	"pelvis": 25.0,
	"legs": 18.0,
	"arms": 12.0,
	"feet": 2.0,
}

#visual stuff


func _ready() -> void: 
	connected_physics_objects.append(head)
	connected_physics_objects.append(torso)
	connected_physics_objects.append(left_thigh)
	connected_physics_objects.append(left_crus)
	connected_physics_objects.append(left_foot)
	connected_physics_objects.append(right_thigh)
	connected_physics_objects.append(right_crus)
	connected_physics_objects.append(right_foot)
	#torso.apply_central_impulse(Vector3(5, 15, 5))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("C"):
		match camera_3d.current:
			true:	camera_3d.current = false
			false:	camera_3d.current = true

func _physics_process(_delta: float) -> void:
	var massdata: Array = get_center_of_mass()
	center_of_mass = massdata[0]
	com_proj = Vector2(center_of_mass.x, center_of_mass.z)
	DebugDraw3D.new_scoped_config().set_no_depth_test(true)
	DebugDraw3D.draw_sphere(center_of_mass, 0.1, Color.RED)
	DebugDraw3D.draw_arrow(center_of_mass, center_of_mass + Vector3(0.0, -1.5, 0.0), Color.RED, 0.1, true)
	var foot_middle: Vector3 = (left_foot.position + right_foot.position) * 0.5
	var support_center := Vector2(foot_middle.x, foot_middle.z)
	DebugDraw3D.draw_box((Vector3(-0.3, -0.1, -0.3) + to_global(foot_middle) * Vector3(1.0, 0.0, 1.0)), Quaternion.IDENTITY, Vector3(0.6, 0.2, 0.6), Color.BLUE)
	var error := support_center - com_proj
	torso.apply_central_force(Vector3(error.x, 0.0, error.y) * 650.0)
	DebugDraw3D.draw_arrow(torso.position, torso.position+Vector3(error.x, 0.0, error.y), Color.BLUE, 0.1, true)
	#for object: RigidBody3D in connected_physics_objects: #all connected parts should try to stay at the center of mass, only the x and z though
	#	var center_mass_diff: Vector3 = center_of_mass - center_of_mass_in_global_space(object)
	#	object.constant_force = (center_mass_diff * Vector3(5.0, 0.0, 5.0))
	

func get_center_of_mass():
	var mass_center: Vector3 = Vector3.ZERO
	var total_mass: float = 0.0
	for object: RigidBody3D in connected_physics_objects: #Assums these are all rigidbody3d's
		var obj_mass := object.mass
		var obj_mass_center := center_of_mass_in_global_space(object) #get the center of mass in global coordinates
		mass_center += obj_mass_center * obj_mass
		total_mass += obj_mass
	return [mass_center/total_mass, total_mass]

func center_of_mass_in_global_space(object: RigidBody3D) -> Vector3:
	return object.global_position + object.global_transform.basis * object.center_of_mass




#end
