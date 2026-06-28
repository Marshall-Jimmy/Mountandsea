class_name DemoPlayerAnimationStateMachine
extends Node

enum PlayerAnimationState {
	IDLE,
	WALK
}

enum PlayerFacingDirection {
	LEFT = -1,
	RIGHT = 1
}

const MOVEMENT_EPSILON_SQUARED := 0.0001
const HORIZONTAL_MOVEMENT_EPSILON := 0.01
const DEFAULT_FACING_DIRECTION := PlayerFacingDirection.RIGHT
const STATE_ANIMATION_NAMES := {
	PlayerAnimationState.IDLE: &"idle",
	PlayerAnimationState.WALK: &"walk"
}

@export var animated_sprite: AnimatedSprite2D

var current_state := PlayerAnimationState.IDLE
var current_animation_name: StringName = &"idle"
var animation_play_count := 0
var last_facing_direction := DEFAULT_FACING_DIRECTION


func _ready() -> void:
	if animated_sprite == null:
		push_error("Demo player animation state machine requires an AnimatedSprite2D.")
		return
	_apply_facing_direction()
	_play_current_animation()


func set_movement_vector(movement: Vector2) -> void:
	_update_facing_direction(movement.x)
	set_moving(movement.length_squared() > MOVEMENT_EPSILON_SQUARED)


func set_moving(is_moving: bool) -> void:
	transition_to(PlayerAnimationState.WALK if is_moving else PlayerAnimationState.IDLE)


func transition_to(next_state: int) -> void:
	if not STATE_ANIMATION_NAMES.has(next_state):
		push_error("Unknown demo player animation state: %s" % next_state)
		return
	if next_state == current_state:
		return

	current_state = next_state
	current_animation_name = STATE_ANIMATION_NAMES[current_state]
	_play_current_animation()


func reset_to_idle() -> void:
	_set_facing_direction(DEFAULT_FACING_DIRECTION)
	transition_to(PlayerAnimationState.IDLE)


func _update_facing_direction(horizontal_movement: float) -> void:
	if horizontal_movement < -HORIZONTAL_MOVEMENT_EPSILON:
		_set_facing_direction(PlayerFacingDirection.LEFT)
	elif horizontal_movement > HORIZONTAL_MOVEMENT_EPSILON:
		_set_facing_direction(PlayerFacingDirection.RIGHT)


func _set_facing_direction(next_direction: int) -> void:
	if next_direction != PlayerFacingDirection.LEFT and next_direction != PlayerFacingDirection.RIGHT:
		push_error("Unknown demo player facing direction: %s" % next_direction)
		return
	last_facing_direction = next_direction
	_apply_facing_direction()


func _apply_facing_direction() -> void:
	if animated_sprite == null:
		return
	# The source artwork faces left, so right-facing movement uses a horizontal flip.
	animated_sprite.flip_h = last_facing_direction == PlayerFacingDirection.RIGHT


func _play_current_animation() -> void:
	if animated_sprite.sprite_frames == null:
		push_error("Demo player AnimatedSprite2D has no SpriteFrames resource.")
		return
	if not animated_sprite.sprite_frames.has_animation(current_animation_name):
		push_error("Missing demo player animation: %s" % current_animation_name)
		return

	animated_sprite.play(current_animation_name)
	animation_play_count += 1
