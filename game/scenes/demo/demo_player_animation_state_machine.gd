class_name DemoPlayerAnimationStateMachine
extends Node

enum PlayerAnimationState {
	IDLE,
	WALK
}

const MOVEMENT_EPSILON_SQUARED := 0.0001
const STATE_ANIMATION_NAMES := {
	PlayerAnimationState.IDLE: &"idle",
	PlayerAnimationState.WALK: &"walk"
}

@export var animated_sprite: AnimatedSprite2D

var current_state := PlayerAnimationState.IDLE
var current_animation_name: StringName = &"idle"
var animation_play_count := 0


func _ready() -> void:
	if animated_sprite == null:
		push_error("Demo player animation state machine requires an AnimatedSprite2D.")
		return
	_play_current_animation()


func set_movement_vector(movement: Vector2) -> void:
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
	transition_to(PlayerAnimationState.IDLE)


func _play_current_animation() -> void:
	if animated_sprite.sprite_frames == null:
		push_error("Demo player AnimatedSprite2D has no SpriteFrames resource.")
		return
	if not animated_sprite.sprite_frames.has_animation(current_animation_name):
		push_error("Missing demo player animation: %s" % current_animation_name)
		return

	animated_sprite.play(current_animation_name)
	animation_play_count += 1
