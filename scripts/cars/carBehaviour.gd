# Suspension travel    50
# Suspension stiffness 30
# Suspension max force 6000
# 
# Damping compression  1.4
# Damping relaxation   1.5 

extends VehicleBody
 ## If true, the car won't detect player inputs.
export var AI : bool = false
## Maximum velocity the car can reach.
## Unit still to be determined (not KM/h or MP/h).
## Keep between 15 and 50 for good stability.
export(float, 5.0, 100.0, 0.5) var max_velocity : float = 20.0
## Acceleration. Keep between 30 and 100 for good stability.
export(float, 75.0, 15000.0, 0.5) var engine_power : float = 75.0
## Affects engine sound when accelerating. A higher pitch will make a stronger engine sound.
export(float, 0.2, 2.0, 0.05) var engine_pitch : float = 0.5
## Affects engine sound when accelerating. A higher pitch will make a stronger engine sound.
export(float, 1.0, 6.0, 0.05) var brake_force : float = 0.75
export(float, 0.15, 3.0, 0.05) var max_steering_angle : float = 0.85
export(float, 0.5, 5.0, 0.05) var drift_force : float = 1.0
export(float, 0.03, 0.2, 0.05) var drift_speed : float = 0.15
export(int, 1, 20, 1) var resistance = 8

const DIRECTION_NONE : int = 100
const DIRECTION_FORWARD : int = 101
const DIRECTION_BACKWARDS : int = 102
const STEERING_NONE : int = 1000
const STEERING_LEFT : int = 1001
const STEERING_RIGHT : int = 1002

#onready var driftTrail : Node = preload("res://MotionTrail/MotionTrail.tscn")

onready var in_control : bool = false
onready var steer : float = 0
onready var reset_max_steering_angle : float = max_steering_angle
onready var accelerating : bool = false
onready var wheels : Array = [$wheelFrontLeft, $wheelFrontRight, $wheelBackLeft, $wheelBackRight]
onready var back_light_sprites : Array = [$backLightSprite1, $backLightSprite2]
onready var back_lights : Array = [$backLight1, $backLight2]
onready var wheel_friction : float = wheels[0].wheel_friction_slip
onready var direction : int = DIRECTION_NONE
onready var current_velocity : float = 0
onready var last_velocity : float = 0
onready var velocity : float = 0
onready var steering_direction : int = STEERING_NONE
onready var trail_effect : PackedScene = preload("res://scenes/effects/driftTrail.tscn")
onready var going_backwards : bool = false
onready var slowing_to_go_backwards : bool = false
onready var last_direction : int = DIRECTION_NONE
onready var health : int = 1000
onready var smoke_effect : PackedScene = preload("res://scenes/effects/smoke.tscn")
onready var deccelerating : bool = false
onready var transition_camera : PackedScene = preload("res://scenes/tools/transitionCarFootCamera.tscn")
# used to detect if the car is moving backwards or breaking
onready var initial_backwards_velocity : float = 0
# Used to detect if player can enter car
onready var player_near : bool = false
onready var player : Node = null
onready var current_path_point : Area = null
onready var current_path_point_index : int = 0
onready var ai_path : PathAI = null
onready var last_origin : Vector3 = Vector3(1, 1, 1)

func _ready():
	setup_drift_effect_raycasts()
	setup_drift_smoke_positions()
	if(!AI):
		in_control = true
		collision_layer = CollisionEnums.COLLISION_NPC_CAR
	else:
		collision_layer = CollisionEnums.COLLISION_PLAYER_CAR
		

func _physics_process(delta : float) -> void:
	reset_values()
	all_inputs()
	stop_car()
	recover_from_flip()
	damage_on_collision()
	engine_sound(engine_pitch)
	join_player_to_car()
	
	if(AI):
		ai_follow_path()
	
# need a single to get the value and not update it every frame
func _input(event : InputEvent):
#	when starting the brake/go backwards action, change the velocity to backwardsVelocity
#	if(event.is_action_pressed("S")):
#		initial_backwards_velocity = get_backwards_velocity()*5
#	when starting the brake/go backwards action, change the velocity to backwardsVelocity
#	if(event.is_action_pressed("ui_accept")):
#		initial_backwards_velocity = get_backwards_velocity()
		
	if(event.is_action_pressed("R")):
		translation.y += 3
		rotation_degrees.x = 0
		rotation_degrees.z = 0
		
	get_in_car_inputs(event)
	
func set_ai_path(new_path : PathAI) -> void:
	ai_path = new_path
	current_path_point_index = 0
	current_path_point = ai_path.path_points[0]

func angle_difference(angle1, angle2):
	var diff = angle2 - angle1
	return diff if abs(diff) < 180 else diff + (360 * -sign(diff))

func ai_follow_path() -> void:
	if(current_path_point != null):
		
		var player_2d_position : Vector2 = Vector2(global_transform.origin.x, global_transform.origin.z).normalized()
		var path_2d_position : Vector2 = Vector2(current_path_point.global_transform.origin.x, current_path_point.global_transform.origin.z).normalized()
		
		var facing_direction : Vector2 = Vector2(global_transform.basis.z.x, global_transform.basis.z.z)
		var walling_direction : Vector2 = Vector2(global_transform.basis.x.x, global_transform.basis.x.z)
		var facing_angle : float = rotation_degrees.y
		
		if(facing_angle < 0):
			facing_angle += 360
		
		var go_to_direction : Vector2 = Vector2(global_transform.origin.x - current_path_point.global_transform.origin.x, global_transform.origin.z - current_path_point.global_transform.origin.z).normalized()
		var go_to_angle : float = rad2deg(path_2d_position.angle_to_point(player_2d_position))
		
		var dot : float = facing_direction.dot(go_to_direction)
		var dot_w : float = walling_direction.dot(go_to_direction) # -0.7 = facing path
		var cross : float = facing_direction.cross(go_to_direction)
		
		if(dot_w > 0.1):
			turn_right()
		elif(dot_w < -0.1):
			turn_left()
		
		accelerate()
		
func setup_drift_effect_raycasts() -> void:
	$driftEffectRaycasts/RayCast1.global_transform.origin = $wheelFrontLeft.global_transform.origin
	$driftEffectRaycasts/RayCast2.global_transform.origin = $wheelFrontRight.global_transform.origin
	$driftEffectRaycasts/RayCast3.global_transform.origin = $wheelBackLeft.global_transform.origin
	$driftEffectRaycasts/RayCast4.global_transform.origin = $wheelBackRight.global_transform.origin
	
	$driftEffectRaycasts/RayCast1.set_associated_wheel($wheelFrontLeft)
	$driftEffectRaycasts/RayCast2.set_associated_wheel($wheelFrontRight)
	$driftEffectRaycasts/RayCast3.set_associated_wheel($wheelBackLeft)
	$driftEffectRaycasts/RayCast4.set_associated_wheel($wheelBackRight)
	
func setup_drift_smoke_positions() -> void:
	$driftSmokeLeft.transform.origin = $wheelBackLeft.transform.origin
	$driftSmokeLeft.transform.origin.y -= $wheelBackLeft.wheel_radius/2
	
	$driftSmokeRight.transform.origin = $wheelBackRight.transform.origin
	$driftSmokeRight.transform.origin.y -= $wheelBackRight.wheel_radius/2
		
func all_inputs() -> void:
	control_inputs()
	
func align_character_and_car_cameras() -> void:
	if(in_control):
		player
	
func get_in_car_inputs(event : InputEvent) -> void:
	if(player_near and event.is_action_pressed("ui_action") and !in_control and get_velocity() <= 0.3):
		collision_layer = CollisionEnums.COLLISION_PLAYER_CAR
		var cam = transition_camera.instance()
		add_child(cam)
		cam.setup(self, player.get_node("camPivotY/camPivotX/Camera"), get_parent().get_parent().get_parent().get_node("followCamera"))
		cam.connect("camera_transitioned", self, "get_in_car")
		player.enabled = false
		player.get_node("CollisionShape").disabled = true
		player.get_node("Mesh").rotation_degrees = $seatLeft.rotation_degrees
		player.emit_signal("entered_car")
#		in_control = true
	elif(player != null and event.is_action_pressed("ui_action") and in_control and get_velocity() <= 0.3):
		collision_layer = CollisionEnums.COLLISION_NPC_CAR
		var cam = transition_camera.instance()
		add_child(cam)
		cam.setup(player, get_parent().get_parent().get_parent().get_node("followCamera"), player.get_node("camPivotY/camPivotX/Camera"))
		in_control = false
#		player.transform.origin.x += 2
		var walling_direction : Vector2 = Vector2(global_transform.basis.x.x, global_transform.basis.x.z)
		player.transform.origin.x += walling_direction.x * 2
		player.transform.origin.z += walling_direction.y * 2
		player.enabled = true
		player.get_node("Mesh").rotation_degrees = Vector3(0, 0, 0)
		player.get_node("CollisionShape").disabled = false
		player.emit_signal("exited_car")
		
func get_in_car() -> void:
	in_control = true
	
func control_inputs() -> void:
	if(in_control):
		#	direction inputs
		#	using lerp to make the steering smooth
		
	#	forward and backward inputs
		if(Input.is_action_pressed("ui_up")):
			acceleration_actions()
		elif(Input.is_action_pressed("ui_down")):
			decceleration_actions()
			
		if(Input.is_action_pressed("ui_right")):
			turn_right()
		elif(Input.is_action_pressed("ui_left")):
			turn_left()
			
		if(Input.is_action_pressed("ui_drift")):
			drift()
				
		
func reset_values() -> void:
	last_velocity = current_velocity
	deccelerating = false
	accelerating = false
#	going_backwards = false
	current_velocity = get_velocity()
	if(direction != DIRECTION_NONE):
		last_direction = direction
	max_steering_angle = reset_max_steering_angle
	accelerating = false
	engine_force = 0
	brake = 0
#	set_wheels_friction_lerp(10.5, 0.01)
	set_wheels_roll_influence_lerp(0.1, 0.05)
	set_back_lights_color(Color(0, 0, 0))
	set_back_lights_sprite_color(Color(0.5, 0.1, 0.1, 1))
	set_left_wheels_suspension_force(5000)
	set_right_wheels_suspension_force(5000)
	steering = lerp(steering, 0, 0.1)
	direction = DIRECTION_NONE
	steering_direction = STEERING_NONE
	$drift.unit_db = -80
	$driftSmokeLeft.emitting = false
	$driftSmokeRight.emitting = false
#	instance_drift_effects(false)

func join_player_to_car() -> void:
	if(in_control and player != null):
		player.global_transform.origin = lerp(player.global_transform.origin, $seatLeft.global_transform.origin, 0.5)
		player.get_node("Mesh").global_transform.basis = $seatLeft.global_transform.basis
#		player.rotation_degrees.y += 90
	
func update_camera_position() -> void:
	if(is_moving_backwards()):
		$camPos.translation.z = 6.0
	else:
		$camPos.translation.z = -6.0

func update_initial_backwards_velocity() -> void:
	if(int(current_velocity) == 0):
		initial_backwards_velocity = 0

func activate_car_back_lights() -> void:
	if(is_moving_backwards()):
		set_back_lights_color(Color(1, 0, 0))
		set_back_lights_sprite_color(Color(1, 0, 0, 1))
	else:
		set_back_lights_color(Color(1, 1, 1))
		set_back_lights_sprite_color(Color(1, 1, 1, 1))

func drift() -> void:
	if(current_velocity > max_velocity/6):
#		set_front_wheels_friction_lerp(5-drift_force, 0.15)
#		set_back_wheels_friction_lerp(2-drift_force, 0.075)
#		max_steering_angle *= 1.2
		set_wheels_roll_influence_lerp(drift_force, 0.03)
		instance_drift_effects()
		if(accelerating):
			engine_force = 60
		
func get_wheel_associated_drift_effect_raycast(wheel : VehicleWheel) -> RayCast:
	for raycast in $driftEffectRaycasts.get_children():
		if(raycast.get_associated_wheel() == wheel):
			return raycast
			
	return RayCast.new()
		
func instance_drift_effect(wheel : VehicleWheel) -> void:
	if(wheel.is_in_contact()):
		var trail : Sprite3D = trail_effect.instance()
		var associated_drift_effect_raycast = get_wheel_associated_drift_effect_raycast(wheel)
		trail.transform.origin = wheel.global_transform.origin
#		trail.transform.origin = wheel.get_node("RayCast").get_collision_point()
#		trail.transform.origin.y += wheel.scale.y/2 + 0.2
		trail.transform.origin.y = associated_drift_effect_raycast.get_collision_point().y + 0.05
		trail.rotation_degrees = rotation_degrees
		trail.rotation_degrees.y = rad2deg(wheel.global_transform.basis.get_euler().y)
		trail.rotation.x = associated_drift_effect_raycast.global_transform.basis.get_euler().x
		trail.rotation_degrees.x -= 90
		get_parent().get_parent().add_child(trail)
		$drift.unit_db = 0
		if(wheel == $wheelBackLeft):
			$driftSmokeLeft.emitting = true
		elif(wheel == $wheelBackRight):
			$driftSmokeRight.emitting = true
		
func instance_drift_effects() -> void:
	instance_drift_effect($wheelFrontLeft)
	instance_drift_effect($wheelFrontRight)
	instance_drift_effect($wheelBackLeft)
	instance_drift_effect($wheelBackRight)
	
func stop_car() -> void:
	if(get_velocity() > 0 and !accelerating and !deccelerating):
		brake = brake_force * 0.37
		
func brake_car() -> void:
	if(get_velocity() > 0):
		brake = brake_force
		
func get_velocity() -> float:
#	var return_velocity : float = abs(linear_velocity.x) + abs(linear_velocity.z)
	var return_velocity : float = abs(linear_velocity.length())
	return return_velocity
	
func get_backwards_velocity() -> float:
#	leave get_velocity() instead of current_velocity for better result
	return -get_velocity()

func turn_left() -> void:
	steering = lerp(steering, max_steering_angle, 0.08)
	steering_direction = STEERING_LEFT
	set_right_wheels_suspension_force(4050)
		
func turn_right() -> void:
	steering = lerp(steering, -max_steering_angle, 0.08)
	steering_direction = STEERING_RIGHT
	set_left_wheels_suspension_force(4050)

func accelerate() -> void:
	var accel_modifier : float = 1.0
	if(rotation_degrees.x <= -20 and rotation_degrees.x >= -50 and $hasFloorInFront.get_collider() == null):
		accel_modifier = abs(rotation_degrees.x * 3)
	elif(rotation_degrees.x <= -20 and rotation_degrees.x >= -50 and current_velocity < max_velocity):
		accel_modifier = abs(rotation_degrees.x)

	going_backwards = false
	accelerating = true
	deccelerating = false
	if((current_velocity < max_velocity) or going_backwards):
		engine_force = engine_power
		current_velocity = get_velocity()
		last_origin = global_transform.origin
	if(accel_modifier != 1.0):
		engine_force = engine_power + (accel_modifier * 2.7)
		current_velocity = get_velocity()
		last_origin = global_transform.origin
		
func deccelerate() -> void:
	accelerating = false
	deccelerating = true
	if(!going_backwards):
		brake_car()
		if(get_velocity() < 0.2):
			going_backwards = true
	elif(current_velocity < max_velocity):
			engine_force = -engine_power
			current_velocity = get_velocity()
		
func acceleration_actions() -> void:
	accelerate()
	direction = DIRECTION_FORWARD
	
func decceleration_actions() -> void:
	deccelerate()
	if(going_backwards):
		max_steering_angle = 1.5
	direction = DIRECTION_BACKWARDS
	activate_car_back_lights()
	update_initial_backwards_velocity()

# extra_pitch is to make it extra noisy
func engine_sound(extra_pitch : float) -> void:
	var pitch : float = (current_velocity / (max_velocity * 0.8)) + extra_pitch
#	if(pitch > 1 + extra_pitch):
#		pitch = 1 + extra_pitch
	$engine.pitch_scale = pitch
		
func fix_car_rotation_degrees_in_air() -> void:
#	Used to fix when the car exceeds these degrees in any direction (X or Z)
	var rot_fix : int = 2
	if(rotation_degrees.x >= rot_fix and !is_on_floor()):
		angular_velocity.x = 0
	elif(rotation_degrees.x <= -rot_fix and !is_on_floor()):
		angular_velocity.x = -0
	if(rotation_degrees.z >= rot_fix and !is_on_floor()):
		angular_velocity.z = 0
	elif(rotation_degrees.z <= -rot_fix and !is_on_floor()):
		angular_velocity.z = -0
		
func fix_car_rotation_degrees_on_floor() -> void:
#	Used to fix when the car exceeds these degrees in any direction (X or Z)
	var rot_fix : int = 15
	if(rotation_degrees.x >= rot_fix):
		angular_velocity.x = lerp(angular_velocity.x, 0, 0.025)
	elif(rotation_degrees.x <= -rot_fix):
		angular_velocity.x = lerp(angular_velocity.x, -0, 0.025)
	if(rotation_degrees.z >= rot_fix):
		angular_velocity.z = lerp(angular_velocity.z, 0, 0.025)
	elif(rotation_degrees.z <= -rot_fix):
		angular_velocity.z = lerp(angular_velocity.z, -0, 0.025)

# when a car is in air, it will turn infinitely as its angular_velocity.y is not updated
func stop_car_infinite_turning_in_air() -> void:
	if(!is_on_floor()):
		angular_velocity.y = lerp(angular_velocity.y, 0, 1)
		
func recover_from_flip() -> void:
#	maximum degrees before fixing rotation
	var max_degrees_lateral : int = 75
	var max_degrees_frontal : int = 45
#	lateral flips aka doors touching the floor
	if(rotation_degrees.z > max_degrees_lateral and !is_on_floor()):
#		negative
		angular_velocity.z = lerp(angular_velocity.z, -1.68, 0.025)
	elif(rotation_degrees.z < -max_degrees_lateral and !is_on_floor()):
#		positive
		angular_velocity.z = lerp(angular_velocity.z, 1.68, 0.025)
#	if Z rotation is low, return car to stability (no angular velocity applied)
	elif((rotation_degrees.z < 15 and rotation_degrees.z > 5 or rotation_degrees.z < -5 and rotation_degrees.z > -15) and !is_on_floor()):
#		return car to lateral stability
		angular_velocity.z = lerp(angular_velocity.z, 0, 0.025)
		
#	frontal flips aka front or back of the car touching the floor
	if(rotation_degrees.x > max_degrees_frontal and !is_on_floor()):
#		negative
		angular_velocity.x = lerp(angular_velocity.x, -0.84, 0.025)
	elif(rotation_degrees.x < -max_degrees_frontal and !is_on_floor()):
#		positive
		angular_velocity.x = lerp(angular_velocity.x, 0.84, 0.025)
#	if X rotation is low, return car to stability (no angular velocity applied)
	elif((rotation_degrees.x < 15 and rotation_degrees.x > 5 or rotation_degrees.x < -5 and rotation_degrees.x > -15) and !is_on_floor()):
		angular_velocity.x = lerp(angular_velocity.x, 0, 0.025)
		
func is_on_floor() -> bool:
	var toReturn : bool = false
	if(wheels[0].is_in_contact()
	or wheels[1].is_in_contact()
	or wheels[2].is_in_contact()
	or wheels[3].is_in_contact()):
		toReturn = true
		
	return toReturn
	
func is_lateral_flipped() -> bool:
	var toReturn : bool = false
	if((wheels[0].is_in_contact() and wheels[2].is_in_contact() and !wheels[1].is_in_contact() and !wheels[3].is_in_contact())
	or (!wheels[0].is_in_contact() and !wheels[2].is_in_contact() and wheels[1].is_in_contact() and wheels[3].is_in_contact())):
		toReturn = true
	
	return toReturn
	
func damage_on_collision() -> void:
	if(last_velocity - current_velocity >= 2):
		$crash.play(0.0)
		var damage : float = (get_velocity() * 90)/(resistance*1.5)
		health -= damage
		car_smoke_status()
			
func set_health(new_health : int) -> void:
	health = new_health
	car_smoke_status()
	
func car_smoke_status() -> void:
	if(health <= 600):
		get_node("smoke").emitting = true
	else:
		get_node("smoke").emitting = false
		get_node("fire").emitting = false
	if(health < 600 and health >= 450):
		get_node("smoke").init(Color(1, 1, 1, 1))
	if(health < 450 and health >= 300):
		get_node("smoke").init(Color(0.3, 0.3, 0.3, 1))
	elif(health < 300 and health >= 150):
		get_node("smoke").init(Color(0.1, 0.1, 0.1, 1))
	elif(health < 150 and health >= 1):
		get_node("smoke").init(Color(0.01, 0.01, 0.01, 1))
	elif(health < 1):
		get_node("smoke").emitting = false
		get_node("fire").emitting = true
		
func is_moving_backwards() -> bool:
	if(current_velocity + initial_backwards_velocity <= 0):
		return true
	else:
		return false
			
func set_left_wheels_suspension_force(new_force : float) -> void:
	$wheelFrontLeft.suspension_max_force = new_force
	$wheelBackLeft.suspension_max_force = new_force
	
func set_right_wheels_suspension_force(new_force : float) -> void:
	$wheelFrontRight.suspension_max_force = new_force
	$wheelBackRight.suspension_max_force = new_force
			
func setWheelsRollInfluence(new_roll : float) -> void:
	for wheel in wheels:
		wheel.wheel_roll_influence = new_roll
		
func set_wheels_roll_influence_lerp(new_roll : float, step : float) -> void:
	for wheel in wheels:
		wheel.wheel_roll_influence = lerp(wheel.wheel_roll_influence, new_roll, step)
			
func set_wheels_friction_lerp(new_friction : float, step : float) -> void:
	for wheel in wheels:
		wheel.wheel_friction_slip = lerp(wheel.wheel_friction_slip, new_friction, step)

func set_front_wheels_friction_lerp(new_friction : float, step : float) -> void:
#	for wheel in wheels:
#		wheel.wheel_friction_slip = lerp(wheel.wheel_friction_slip, new_friction, step)
	wheels[0].wheel_friction_slip = lerp(wheels[2].wheel_friction_slip, new_friction, step)
	wheels[1].wheel_friction_slip = lerp(wheels[3].wheel_friction_slip, new_friction, step)
	
func set_back_wheels_friction_lerp(new_friction : float, step : float) -> void:
#	for wheel in wheels:
#		wheel.wheel_friction_slip = lerp(wheel.wheel_friction_slip, new_friction, step)
	wheels[2].wheel_friction_slip = lerp(wheels[2].wheel_friction_slip, new_friction, step)
	wheels[3].wheel_friction_slip = lerp(wheels[3].wheel_friction_slip, new_friction, step)
		
func set_front_wheels_friction(new_friction : float) -> void:
#	for wheel in wheels:
#		wheel.wheel_friction_slip = new_friction
	wheels[0].wheel_friction_slip = new_friction
	wheels[1].wheel_friction_slip = new_friction
	
func setBackWheelsFriction(new_friction : float) -> void:
#	for wheel in wheels:
#		wheel.wheel_friction_slip = new_friction
	wheels[2].wheel_friction_slip = new_friction
	wheels[3].wheel_friction_slip = new_friction
		
func set_back_lights_sprite_color(new_color : Color) -> void:
	for light in back_light_sprites:
		light.modulate = new_color
		
func set_back_lights_color(new_color : Color) -> void:
	for light in back_lights:
		light.light_color = new_color

func _on_getInCar_body_entered(body: Node) -> void:
	if(body.name == "player"):
		get_parent().get_parent().get_parent().get_node("ui/generalUI/action").visible = true
		player_near = true
		player = body

func _on_getInCar_body_exited(body: Node) -> void:
	if(body.name == "player"):
		get_parent().get_parent().get_parent().get_node("ui/generalUI/action").visible = false
		player_near = false
#		player = null
		
