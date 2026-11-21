class_name MovementMotor
extends IDomainMotor



@onready var horizontal: HorizontalMovement = \
	$HorizontalMovement

@onready var vertical: VerticalMovement = \
	$VerticalMovement


var body: CharacterBody2D
var sensors: MovementSensors

var horizontal_intent: float = 0.0

var _jump_requested: bool = false



func configure(
	p_body: CharacterBody2D,
	p_sensors: MovementSensors
)-> void:
	body = p_body
	sensors = p_sensors



# recebe intenção contínua do input
func set_horizontal_intent(direction: float)-> void:
	horizontal_intent = clamp(
		direction,
		-1.0,
		 1.0
	)



# recebe política da HSM
func set_airborne(value: bool) -> void:
	horizontal.set_airborne(value)



# recebe comando pontual do TransitionEffect de pulo
func request_jump() -> void:
	_jump_requested = true



# implementação do contrato IDomainMotor
func physics_tick(delta: float) -> void:
	if not is_instance_valid(body):
		return

	if not is_instance_valid(sensors):
		return

	horizontal.calculate(
		body.velocity.x,
		horizontal_intent,
		delta
	)

	vertical.calculate(
		body.velocity.y,
		sensors.is_grounded,
		_jump_requested,
		delta
	)

	_jump_requested = false