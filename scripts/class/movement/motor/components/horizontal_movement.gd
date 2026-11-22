class_name HorizontalMovement
extends Node



@export_group("Ground Movement")
@export var ground_speed: float = 220.0
@export var ground_acceleration: float = 1400.0
@export var ground_decelaration: float = 1800.0


@export_group("Air Movement")
@export var air_speed: float = 210.0
@export var air_acceleration: float = 850.0
@export var air_deceleration: float = 500.0


var _is_airborne: bool = false



func set_airborne(value: bool) -> void:
	_is_airborne = value



func calculate(
	current_velocity: float,
	direction: float,
	delta: float
) -> float:

	direction = clampf(direction, -1.0, 1.0)

	var speed: float = ground_speed
	var acceleration: float = ground_acceleration
	var decelration: float = ground_decelaration

	if _is_airborne:
		speed = air_speed
		acceleration = air_acceleration
		decelration = air_deceleration

	var target_velocity: float = direction * speed

	var rate: float = acceleration

	if is_zero_approx(direction):
		rate = decelration

	return move_toward(
		current_velocity,
		target_velocity,
		rate * delta
	)