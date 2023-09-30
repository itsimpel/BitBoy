extends KinematicBody2D

# abilities
export var canWalk := true
export var canRun := true # also canWalk
export var canJump := true
export var canWallSlide := true
export var canWallJump := true # also canWallSlide
export var canLedgeHang := true # and ledge jump | also canWallSlide, canWallJump
export var canDangle := true

# horizontal movement
export var speed := 1.0
export var runSpeedMultiplier := 2.0
export var accelTime := 0.1
export var decelTime := 0.05
var accel := 0.0
var decel := 0.0

# jump movement
export var maxJumpHeight := 0.3
export var minJumpHeight := 0.08
export var jumpTime := 0.3
export var graceTime := 0.1
export var coyoteTime := 0.08
export var maxFallSpeed := 2.0
export var minPeakVel := 0.4
export var peakGravMultiplier := 0.5
export var peakSpeedMultiplier := 1.1
var normalGrav := 0.0
var cancelGrav := 0.0
var topGrav := 0.0
var jumpPower := 0.0
var wasOnFloor := false
var isAtPeak := false

# wall movement
export var wallJumpTime := 0.2
export var wallJumpVel := Vector2(1.3, 1.0)
export var slidingSpeed := 0.3
export var wallHangTime := 0.1
export var ledgeJumpMultiplier := 0.7
export var pullMoveMultiplier := 1.0
var wallJumpDir := 0
var isWallSliding := false
var isLedgeHanging := false
var isFacingNearWall := false
var notLeftWall := false
var asdf := false
var lastFacing := 0
var lastWallDir := 0

# motion variables
export var outputScaler := 240
var vel := Vector2.ZERO
var lookingDir := Vector2.ZERO

# timers
var graceTimer := Timer.new()
var coyoteTimer := Timer.new()
var wallJumpTimer := Timer.new()
var wallHangTimer := Timer.new()

func _ready():
	_calc_variables()
	_setup_timers()

func _process(delta): #_physics_process(delta):
	_inputs(delta)
	
	if (canWalk):
		_horizontal_motion(delta)
	
	_get_wall_states()
	
	if (canJump):
		_jump_motion(delta)
	else:
		vel.y = max(vel.y + normalGrav * delta, -maxFallSpeed)
	
	_wall_motion_modifiers(delta)
	_newtons_3rd()
	_move(delta)

func _move(delta):
	move_and_slide(vel * outputScaler * Vector2(1, -1), Vector2.UP)

func _horizontal_motion(delta):
	var input := round(lookingDir.x)#round(Input.get_axis("player_left", "player_right"))
	var targetSpeed := input * speed
	var topSpeed := speed
	if ((($RightPull.is_colliding() && input > 0) || ($LeftPull.is_colliding() && input < 0)) && canWallSlide):
		targetSpeed = input * speed * pullMoveMultiplier
		topSpeed = speed * pullMoveMultiplier
	elif (Input.is_action_pressed("player_run") && is_on_floor() && canRun):
		targetSpeed = input * speed * runSpeedMultiplier
		topSpeed = speed * runSpeedMultiplier
	elif (isAtPeak):
		targetSpeed = input * speed * peakSpeedMultiplier
		topSpeed = speed * peakSpeedMultiplier
	
	if ((vel.x < targetSpeed && vel.x >= 0) || (vel.x > targetSpeed && vel.x <= 0)):
		vel.x = clamp(vel.x + accel * delta * input, -topSpeed+0.001, topSpeed-0.001)
	elif (!is_on_floor() && (input * vel.x) > 0): # can keep momentum in air
		pass
	elif (vel.x > 0):
		vel.x = max(vel.x - decel * delta, 0.0)
	elif (vel.x < 0):
		vel.x = min(vel.x + decel * delta, 0.0)

func _jump_motion(delta):
	var gracePeriod = !graceTimer.is_stopped() # incase of weird timings
	if (Input.is_action_just_pressed("player_jump") || gracePeriod):
		if (is_on_floor() || !coyoteTimer.is_stopped()):
			vel.y = jumpPower
		elif (canWallJump):
			if (!$RightWall.get_overlapping_bodies().empty()):
				if (isLedgeHanging):
					vel.y = jumpPower * ledgeJumpMultiplier
				else:
					wallJumpTimer.start()
					wallJumpDir = -1
					vel.x = wallJumpDir
			elif (!$LeftWall.get_overlapping_bodies().empty()):
				if (isLedgeHanging):
					vel.y = jumpPower * ledgeJumpMultiplier
				else:
					wallJumpTimer.start()
					wallJumpDir = 1
		elif (!gracePeriod):
			graceTimer.start()
	
	if (vel.y < 0 && !is_on_floor() && wasOnFloor):
		coyoteTimer.start()
	
	if (!wallJumpTimer.is_stopped()):
		vel = lerp(vel, Vector2(wallJumpVel.x * wallJumpDir, wallJumpVel.y), pow(wallJumpTimer.time_left, 3) / pow(wallJumpTime, 3)) # TODO: need to make it impossible to climb walls
	
	isAtPeak = false
	if (!Input.is_action_pressed("player_jump") && vel.y > 0):
		vel.y = max(vel.y + cancelGrav * delta, -maxFallSpeed)
	elif (Input.is_action_pressed("player_jump") && abs(vel.y) <= minPeakVel && !is_on_floor()):
		vel.y = max(vel.y + topGrav * delta, -maxFallSpeed)
		isAtPeak = true
	else:
		vel.y = max(vel.y + normalGrav * delta, -maxFallSpeed)
	
	wasOnFloor = is_on_floor()

func _wall_motion_modifiers(delta):
	if (Input.is_action_pressed("player_jump") && vel.y > 0 && abs(vel.x) > 0.1 && isFacingNearWall):
		if (!notLeftWall):
			vel.y += pow(abs(vel.x), 1.5) / 2
			notLeftWall = true
	elif (notLeftWall && isFacingNearWall):
		notLeftWall = false
	
	if (isLedgeHanging):
		vel.y = max(vel.y, 0)
	elif (isWallSliding):
		vel.y = -slidingSpeed
	
	if ((lastWallDir != round(lookingDir.x) || lastWallDir == 0) && isWallSliding):
		if (wallHangTimer.is_stopped() && !asdf):
			print("hi")
			wallHangTimer.start()
			asdf = true
		elif (!wallHangTimer.is_stopped()):
			vel.y = max(vel.y, 0)
	elif (asdf):
		asdf = false

func _get_wall_states():
	var wasWallSliding = isWallSliding
	isWallSliding = false
	isLedgeHanging = false
	isFacingNearWall = (!$LeftWall.get_overlapping_bodies().empty() && lookingDir.x < 0) || (!$RightWall.get_overlapping_bodies().empty() && lookingDir.x > 0)
	if (isFacingNearWall && is_on_wall() &&  !is_on_floor() && vel.y <= 0 && canWallSlide): # isNearWall && is_on_wall()
		if (((!$LeftLedge.is_colliding() && lookingDir.x < 0) || (!$RightLedge.is_colliding() && lookingDir.x > 0)) && canLedgeHang):
			isLedgeHanging = true
		elif (lookingDir.x != 0): #abs(vel.x) > 0
			isWallSliding = true
			lastFacing = round(lookingDir.x)
	
	if (wasWallSliding && !isWallSliding):
		lastWallDir = lastFacing
	elif (lastWallDir != 0 && is_on_floor()):
		lastWallDir = 0

func _grab(delta):
	if (Input.is_action_pressed("player_grab")):
		pass

func _inputs(delta):
	lookingDir = Vector2(Input.get_axis("player_left", "player_right"), Input.get_axis("player_down", "player_up"))

func _newtons_3rd():
	if (is_on_floor()):
		vel.y = max(vel.y, -0.01)
	if (is_on_ceiling()):
		vel.y = min(vel.y, 0.01)
	if (is_on_wall()):
		if (!$RightWall.get_overlapping_bodies().empty()):
			vel.x = min(vel.x, 0.01)
		elif (!$LeftWall.get_overlapping_bodies().empty()):
			vel.x = max(vel.x, -0.01)

func _calc_variables():
	accel = speed / accelTime
	decel = speed / decelTime
	jumpPower = (2 * maxJumpHeight) / (jumpTime)
	normalGrav = (-2 *maxJumpHeight) / pow(jumpTime, 2)
	cancelGrav = 0 - pow(jumpPower, 2) / (2 * minJumpHeight)
	topGrav = normalGrav * peakGravMultiplier

func _setup_timers():
	graceTimer.one_shot = true
	graceTimer.wait_time = graceTime
	add_child(graceTimer)
	coyoteTimer.one_shot = true
	coyoteTimer.wait_time = coyoteTime
	add_child(coyoteTimer)
	wallJumpTimer.one_shot = true
	wallJumpTimer.wait_time = wallJumpTime
	add_child(wallJumpTimer)
	wallHangTimer.one_shot = true
	wallHangTimer.wait_time = wallHangTime
	add_child(wallHangTimer)
