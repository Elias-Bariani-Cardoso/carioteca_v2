class_name MovementSensors
extends ISensors



var body: CharacterBody2D

var has_feedback: bool = false
var is_grounded: bool = false
var is_touching_wall: bool = false
var is_touching_ceiling: bool = false


var horizontal_velocity: float = 0.0
var vertical_velocity: float = 0.0



func configure(p_body: CharacterBody2D) -> void:
	body = p_body
	has_feedback = false



func refresh() -> void:
	if not is_instance_valid(body):
		return

	is_grounded = body.is_on_floor()
	is_touching_wall = body.is_on_wall()
	is_touching_ceiling = body.is_on_ceiling()

	horizontal_velocity = body.velocity.x
	vertical_velocity = body.velocity.y

	has_feedback = true



func is_rising() -> bool:
	return(
		has_feedback
		and not is_grounded
		and vertical_velocity < 0.0
	)



func is_falling() -> bool:
	return(
		has_feedback
		and not is_grounded
		and vertical_velocity >= 0.0
	)