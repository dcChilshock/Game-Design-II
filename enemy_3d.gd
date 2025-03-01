extends CharacterBody3D

@onready var atk_area: Area3D = $AttackArea
@onready var dmg_area: Area3D = $DamageArea
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var HEALTH = 200
var SPEED = 3.0
var ACCEL = 20
var ATTACK = 10
var KNOCKBACK = 16.0
var WALKSPEED = SPEED
var RUNSPEED = SPEED * 1.5

func take_damage(_dmg):
	self.queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	for player in get_tree().get_nodes_in_group("player"):
		if $AttackRange.overlaps_body(player):
			nav_agent.target_position = player.global_position
			SPEED = RUNSPEED
		if atk_area.overlaps_body(player):
			player.take_damage(ATTACK)
			player.inertia = (player.global_position-global_position).normalized()*KNOCKBACK
	var dir = (nav_agent.target_position-self.global_position).normalized()
	velocity = velocity.lerp(dir * SPEED, ACCEL * delta)
	
	move_and_slide()
	
func _ready():
	nav_agent.target_position = global_position
	
	
