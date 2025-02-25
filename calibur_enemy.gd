extends CharacterBody3D

@onready var atk_area = $AttackArea_stab
@onready var dmg_area = $DamageArea
@onready var nav_agent = $NavigationAgent3D
@onready var animator = $Sketchfab_Scene/AnimationPlayer
#var HEALTH = 1
var SPEED = 10.0
var ACCEL = 20
var ATTACK = 10
var KNOCKBACK = 16.0
var WALKSPEED = SPEED
var RUNSPEED = SPEED * 1.5


func take_damage(_dmg):
	#animator.play("Death")
	self.queue_free()

func _physics_process(delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if $AttackRange.overlaps_body(player):
			nav_agent.target_position = player.global_position
			SPEED = RUNSPEED
		else:
			SPEED = WALKSPEED
		if atk_area.overlaps_body(player):
			animator.play("Attack1")
			player.take_damage(ATTACK)
			player.inertia = (player.global_position-self.global_position).normalized() * KNOCKBACK
			await animator.animation_finished
	var dir = (nav_agent.target_position-self.global_position)
	dir.y = 0
	if dir.length() > 0.5:
		var rot_angle = atan2(dir.x, dir.z)
		self.rotation.y = lerp_angle(rotation.y, rot_angle, 5 * delta)
	else:
		dir = Vector3.ZERO
	velocity = velocity.lerp(dir.normalized() * SPEED, ACCEL * delta)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if animator.current_animation != "Attack1":
		if velocity.length() <= 1:
			animator.play("Idle")
		elif SPEED == WALKSPEED:
			animator.play("Walk")
		elif SPEED == RUNSPEED:
			animator.play("Walk")
			
		
	
	move_and_slide()


func _ready():
	nav_agent.target_position = global_position
