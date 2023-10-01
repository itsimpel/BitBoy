extends KinematicBody2D

const walkSpeed = 20
const gravity = 1

var facingLeft = false
var movement = Vector2(0,0)


func _ready():
	position.x = 671
	position.y = 221
	
func _process(delta):
	
	if (facingLeft == false):
		movement.x = walkSpeed
		$AnimatedSprite.animation = "walkR"
		if $rightDetection.is_colliding() == true:
			facingLeft = true
			
	if (facingLeft == true):
		movement.x = -walkSpeed
		$AnimatedSprite.animation = "walkL"
		if $leftDetection.is_colliding() == true:
			facingLeft = false
			
			
	movement.y += gravity
			
			
	move_and_slide(movement, Vector2.UP)
