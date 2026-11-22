class_name VerticalMovement
extends Node



@export_group("Jump")
@export var jump_speed: float = 350.0


@export_group("Gravity")
@export var gravity: float = 1100.0
@export var max_fall_speed: = 700.0



func calculate(
	current_velocity: float,
	is_grounded: bool,
	jump_requested: bool,
	delta: float,
) -> float:

	# impulso tem prioridade sobre gravidade
	if jump_requested:
		return -jump_speed

	# personagem apoiado no chão
	if is_grounded:
		return 0.0

	# personagem no ar: aplica gravidade
	return minf(
		current_velocity + gravity * delta,
		max_fall_speed
	)