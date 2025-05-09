extends VehicleBody3D

const MAX_STEER = 0.4
const MAX_RPM = 300
const MAX_TORQUE = 200
const HORSE_POWER = 100
@onready var audio = $AudioStreamPlayer3D
@onready var honker = $honker
var movements = preload("res://Sound/car_sound_effects_pack/Car_Acceleration.ogg")
var honk = preload("res://Sound/car_sound_effects_pack/Car_Horn.ogg")
var engineloop = preload("res://Sound/car_sound_effects_pack/Car_Engine_Loop.ogg")

var laps = 1
var checkpoints = [false,false,false,false]

func reset_checkpoints():
	checkpoints = [false,false,false,false]

func do_laps():
	laps += 1
	reset_checkpoints()
	if laps > 3:
		await get_tree().create_timer(0.25).timeout
		OS.alert("You win!") 
	else:
		$Label2.text = "lap %d/3" % laps
	pass
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
func calc_engine_force(accel,rpm):
	return accel * MAX_TORQUE *(1-rpm/MAX_RPM)
	
func _physics_process(delta:float) -> void:
	steering = lerp(steering, Input.get_axis("ui_right","ui_left")*MAX_STEER, delta *5.0)
	var accel = Input.get_axis("ui_down","ui_up") * HORSE_POWER
	$backLeft.engine_force = calc_engine_force(accel,abs($backRight.get_rpm()))
	$backRight.engine_force = calc_engine_force(accel,abs($backRight.get_rpm()))
	
	var fwd_mps = abs((linear_velocity * transform.basis).z)
	$Label.text = "%d mph" % (fwd_mps *2.23694)
	
	$centermass.global_position = $centermass.global_position.lerp(global_position,delta*20)
	$centermass.transform = $centermass.transform.interpolate_with(transform,delta*5.0)
	$centermass/Camera3D.look_at(global_position.lerp(global_position + linear_velocity,delta *5.0))
	check_and_right()
	if accel > 0:
		audio.set_stream(movements)
	else:
		audio.set_stream(engineloop)
	if Input.is_action_just_pressed("honk"):
		honker.set_stream(honk)
		honker.play()
	else:
		pass
func check_and_right():
	if global_transform.basis.y.dot(Vector3.UP)<0:
		var cur_rotation = self.rotation_degrees
		cur_rotation.x = 0 #reset pitch
		cur_rotation.z = 0 
		self.rotation_degrees = cur_rotation
