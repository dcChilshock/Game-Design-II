extends CharacterBody3D

@onready var hit_area = $HitArea
@onready var nav_agent = $NavigationAgent3D
@onready var animator = $Sketchfab_Scene/AnimationPlayer
@onready var dmg_area = $DamageArea
@onready var atk_jump = $AttackArea_jump
@onready var atk_stab = $AttackArea_stab
@onready var atk_stomp = $AttackArea_stomp
@onready var timer = $Timer
#var HEALTH = 1
var SPEED = 2.0
var ACCEL = 10
var ATTACK = 10
var KNOCKBACK = 16.0
var WALKSPEED = SPEED
var RUNSPEED = SPEED * 1.5
var anim = "Idle"

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
		if atk_stab.overlaps_body(player):
			animator.play("Attack1")
			anim = "Attack1"
			#if timer.timeout == true:
				#player.take_damage(ATTACK)
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
			anim = "Idle"
		elif SPEED == WALKSPEED:
			animator.play("Walk")
			anim = "Walk"
		elif SPEED == RUNSPEED:
			animator.play("Walk")
			anim = "Walk"
			
	
	
	move_and_slide()


func _ready():
	nav_agent.target_position = global_position


#func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	#if animator.current_animation() == "Walk" and animator.current_animation() == "Idle":
		#pass
	#else:
		#timer.start()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animator.stop()
	if anim == "Attack1":
		
