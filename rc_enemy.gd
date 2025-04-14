extends VehicleBody3D

const MAX_STEER = 0.4
const MAX_RPM = 200
const MAX_TORQUE = 200
const HORSE_POWER = 100
const REVERSE_POWER = -HORSE_POWER * 2
const STUCK_TIME_THRESHOLD = 0.5

var stuck_timer = 0.0
var is_stuck = false

@onready var rayFw = $rayForward
@onready var rayFwL = $rayForwardLeft
@onready var rayFwR = $rayForwardRight
@onready var raySL = $rayLeft
@onready var raySR = $rayRight

func calc_engine_force(accel, rpm):
	return accel * MAX_TORQUE * (1 - rpm / MAX_RPM)

func check_and_right():
	if global_transform.basis.y.dot(Vector3.UP) < 0:
		var cur_rotation = self.rotation_degrees
		cur_rotation.x = 0 # reset pitch
		cur_rotation.z = 0 # reset roll
		self.rotation_degrees = cur_rotation

func check_stuck_condition(delta):
	if linear_velocity.length() < 1.0:
		stuck_timer += delta
	else:
		stuck_timer = 0
		is_stuck = stuck_timer > STUCK_TIME_THRESHOLD

func update_raycasts():
	rayFw.force_raycast_update()
	rayFwL.force_raycast_update()
	rayFwR.force_raycast_update()
	raySL.force_raycast_update()
	raySR.force_raycast_update()

func is_ray_colliding(raycast: RayCast3D) -> bool:
	return raycast.is_colliding() and raycast.get_collider() is not VehicleBody3D


func _physics_process(delta: float) -> void:
	check_stuck_condition(delta)

	var target_steering = 0.0
	update_raycasts()

	var acceleration = HORSE_POWER
	if is_ray_colliding(rayFw):
		var dist_to_obstacle = rayFw.get_collision_point().distance_to(global_transform.origin)
		acceleration *= max(0.1, dist_to_obstacle / 10.0)
	if is_ray_colliding(rayFwL) or is_ray_colliding(raySL):
		target_steering -= MAX_STEER
	if is_ray_colliding(rayFwR) or is_ray_colliding(raySR):
		target_steering += MAX_STEER
	# NOTE might want to switch += & -=
	target_steering = clamp(target_steering, -MAX_STEER, MAX_STEER)
	if is_stuck:
		acceleration = REVERSE_POWER
		steering = -sign(target_steering) * MAX_STEER
	# else:
	# steering = target_steering
	$backLeft.engine_force = calc_engine_force(acceleration, abs($backLeft.get_rpm()))
	$backRight.engine_force = calc_engine_force(acceleration, abs($backLeft.get_rpm()))
	check_and_right()
