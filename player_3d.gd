extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 1000
var SPEED = WALK_SPEED
const JUMP_VELOCITY = 6.0

const CAM_SENSITIVITY = 0.03
@onready var camera = $Head/Camera3D
@onready var camera_arm = $SpringArm3D
#@onready var camera_tele = $Head/CSGSphere3D #or use CSGSphere3D
@onready var camera_pos = camera.position
@onready var BASE_FOV = camera.fov
#@onready var global_pos = player.position
@onready var player = $"."
var first_person = true

var FOV_CHANGE = 1.0

const BOB_FREQ = 2.4 #how frequent the bobings are
const BOB_AMP = 0.08 #how large the bobings are
var t_bob = 0.0 

var inertia = Vector3.ZERO
#TODO: health stuff
var MAX_HEALTH = 50
var HEALTH = MAX_HEALTH
var damage_lock = 0.0

@onready var HUD = get_tree().get_first_node_in_group("HUD")
var dmg_shader = preload("res://Shader/take_damage.tres")
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.MOUSE_MODE_CAPTURED:
		if first_person == true:
			self.rotate_y(-event.relative.x*(CAM_SENSITIVITY/10.0))
			camera.rotate_x(-event.relative.y*(CAM_SENSITIVITY/10.0))
			camera.rotation.x = clamp(camera.rotation.x,deg_to_rad(-40), deg_to_rad(60))
		else:
			self.rotate_y(-event.relative.x*(CAM_SENSITIVITY/10.0))
			camera_arm.rotate_x(-event.relative.y*(CAM_SENSITIVITY/10.0))
			camera_arm.rotation.x = clamp(camera_arm.rotation.x,deg_to_rad(-75), deg_to_rad(75))
		
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	if Input.is_action_just_pressed("change_camera"): 
		toggle_camera_parent()
	# Add the gravity.
	
	if Input.is_action_pressed("sprint"):
		SPEED = SPRINT_SPEED
		FOV_CHANGE = 9.0
	else:
		SPEED = WALK_SPEED
		FOV_CHANGE = 1.0
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("teleport"):
		$".".position = Vector3(100,0,100) #x,y,z
		var x = $".".x  
		
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	#a true boolen value can = 1 and a false can equal 
	#the number value 0.
	camera.transform.origin = headbob(t_bob)
	
	velocity += inertia
	inertia = inertia.move_toward(Vector3.ZERO,delta*1000)
	damage_lock = max(damage_lock-delta,0.0)
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if $Feet.overlaps_area(enemy.dmg_area):
			enemy.take_damage(0)
	
	HUD.healthbar.max_value = MAX_HEALTH
	HUD.healthbar.value = int(HEALTH)
	if damage_lock == 0.0:
		HUD.dmg_overlay.material = null
		
	if self.global_position.y <= -50:
		take_damage(HEALTH)
	move_and_slide()

func take_damage(dmg):
	if damage_lock == 0.0:
		damage_lock = 0.5
		HEALTH -= dmg
		var d_intensity = clamp(1.0-((HEALTH+0.01)/MAX_HEALTH), 0.1,0.8)
		HUD.dmg_overlay.material = dmg_shader.duplicate()
		HUD.dmg_overlay.material.set_shader_parameter("intensity",d_intensity)
		# TODO: dmg shader 
		if HEALTH <= 0:
			await get_tree().create_timer(0.25).timeout
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			OS.alert("You died!")
			get_tree().reload_current_scene()
	pass

func toggle_camera_parent():
	var parent = "Head"
	if first_person:
		parent = "SpringArm3D"
		#TODO: Model visibel
	var child = camera
	#var sphere = camera_tele
	child.get_parent().remove_child(child)
	get_node(parent).add_child(child)
	camera = child 
	if not first_person:
		camera.position = camera_pos
		#sphere.position = camera_pos
		#TODO: Model invisible
	first_person = not first_person
	
func headbob(time):
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos
