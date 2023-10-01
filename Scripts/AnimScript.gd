extends AnimatedSprite

const recoveryTime = 5
const takeOffTime = 7
var takeOffCounter = 0
var recovering = 0

const stretchSpeed = 0.7

var lastVel = 0
var takingOff = false

func _ready():
	animation = "idle";


func _physics_process(delta):
	
	if $"..".isFacingNearWall == true:
		if $"..".lookingDir.x < 0:
			animation = "wallSlidingL"
		elif $"..".lookingDir.x > 0:
			animation = "wallSlidingR"
	
	elif $"..".is_on_floor() == false:
		
		if $"..".wasOnFloor:
			takeOffCounter = 0
			
		
		if $"..".vel.x >= 0:
			if takingOff == true:
				animation = "jumpR"
			elif $"..".vel.y > 0:
				animation = "airUpR"
			elif $"..".vel.y < -stretchSpeed:
				animation = "airDownR"
		elif $"..".vel.x < 0:
			if takingOff == true:
				animation = "jumpL"
			elif $"..".vel.y > 0:
				animation = "airUpL"
			elif $"..".vel.y < -stretchSpeed:
				animation = "airDownL"
			
		lastVel = $"..".vel.y
			
	else:
		
		if $"..".wasOnFloor == false and lastVel < -1.5:
			animation = "landed"
			recovering = 0
						
		elif $"..".vel.x > 0:
			animation = "runR"
		elif $"..".vel.x < 0:
			animation = "runL"
		else:
			animation = "idle"
			
	if recovering < recoveryTime:
		animation = "landed"
		recovering += 1
		
	if takeOffCounter < takeOffTime:
		if $"..".vel.x >= 0:
			animation = "jumpR"
		else:
			animation = "jumpL"
		takeOffCounter += 1
