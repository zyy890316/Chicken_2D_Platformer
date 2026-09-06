extends CharacterBody2D

const TARGET_HEIGHT := 56.0
const MOVE_SPEED := 220.0
const JUMP_VELOCITY := -820.0
const DOUBLE_JUMP_VELOCITY := -700.0
const COYOTE_TIME := 0.09
const JUMP_BUFFER := 0.12

var facing := 1
var extra_jumps_left := 1
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var base_scale := Vector2.ONE
var squash_tween: Tween
var control_enabled := true
var hazard_cooldown := 0.0
var kill_y := 100000.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	_fit_sprite()


func _fit_sprite() -> void:
	if sprite.texture == null:
		return
	var scale_factor := TARGET_HEIGHT / float(sprite.texture.get_height())
	base_scale = Vector2(scale_factor, scale_factor)
	sprite.scale = base_scale
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16.0
	capsule.height = 46.0
	collision_shape.shape = capsule
	collision_shape.position = Vector2(0, 4)


func can_take_hazard() -> bool:
	return control_enabled and hazard_cooldown <= 0.0 and not GameState.is_won


func begin_death() -> void:
	control_enabled = false
	velocity = Vector2.ZERO


func respawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	extra_jumps_left = 1
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	control_enabled = true
	hazard_cooldown = 0.9
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	await get_tree().physics_frame
	camera.reset_smoothing()
	camera.position_smoothing_enabled = true


func _physics_process(delta: float) -> void:
	if hazard_cooldown > 0.0:
		hazard_cooldown = maxf(0.0, hazard_cooldown - delta)
		sprite.modulate.a = 0.4 if int(hazard_cooldown * 18.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	if not control_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var on_floor := is_on_floor()
	if on_floor:
		extra_jumps_left = 1
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += gravity * delta
		if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
			velocity.y += gravity * 1.6 * delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	if jump_buffer_timer > 0.0:
		if on_floor or coyote_timer > 0.0:
			_jump(JUMP_VELOCITY, false)
		elif extra_jumps_left > 0:
			_jump(DOUBLE_JUMP_VELOCITY, true)

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * MOVE_SPEED
		facing = 1 if direction > 0.0 else -1
		sprite.flip_h = facing < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)

	var tilt := clampf(velocity.x / MOVE_SPEED, -1.0, 1.0) * 0.12
	sprite.rotation = lerp_angle(sprite.rotation, tilt, 0.25)

	var was_on_floor := on_floor
	move_and_slide()
	if is_on_floor() and not was_on_floor:
		_play_squash(1.22, 0.78, 0.14)

	if global_position.y > kill_y:
		GameState.kill_player()


func _jump(jump_velocity: float, is_double: bool) -> void:
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	if is_double:
		extra_jumps_left -= 1
		_play_squash(0.86, 1.28, 0.16)
	else:
		_play_squash(0.82, 1.22, 0.14)


func _play_squash(x: float, y: float, duration: float) -> void:
	if squash_tween != null:
		squash_tween.kill()
	squash_tween = create_tween()
	squash_tween.tween_property(
		sprite, "scale", Vector2(base_scale.x * x, base_scale.y * y), duration * 0.35
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(
		sprite, "scale", base_scale, duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
