extends KinematicBody2D

const walkSpeed = 20
const runSpeed = 50
const jumpPower = 150
const gravity = 6
const detectionDistance = 60
const jumpCooldown = 20

onready var player = $"%Player"

var facingLeft = false
var movement = Vector2(0,0)
var jumping = false
var leeching = false

var counter = 0

var lastY = 0

func _ready():
	position.x = 671
	position.y = 221
	
func _process(delta):
	
	if leeching == false:
	
		if is_on_floor(): jumping = false
		
		if not jumping:
		
			if (facingLeft == false):
				movement.x = walkSpeed
				$AnimatedSprite.animation = "walkR"
				if $rightDetection.is_colliding() == true:
					facingLeft = true
			
			else:
				movement.x = -walkSpeed
				$AnimatedSprite.animation = "walkL"
				if $leftDetection.is_colliding() == true:
					facingLeft = false
					
		else:
			if movement.x < 0:
				$AnimatedSprite.animation = "jumpL"
			else:
				$AnimatedSprite.animation = "jumpR"
				
		if abs(player.position.x - position.x) < detectionDistance and not jumping and counter >= jumpCooldown:
			_jump()
		if not jumping and counter < jumpCooldown:
			counter += 1
			
		if abs(player.position.x - position.x) < 3 and abs(player.position.y - position.y) < 5:
			leeching = true

		movement.y += gravity
		move_and_slide(movement, Vector2.UP)
		
	else:
		
		position.x = player.position.x + 5.5
		position.y = player.position.y
		$AnimatedSprite.animation = "leeching"
		player.AIManager.leeched = true
	
func _jump():
	movement.y = -jumpPower
	movement.x = (player.position.x - position.x) * 1.2

	jumping = true
	counter = 0
