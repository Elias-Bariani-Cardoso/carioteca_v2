class_name PlayerIntentProvider
extends Node



var motor: MovementMotor
var machine: HsmStateMachine

var horizontal_axis: float = 0.0



func configure(
	p_motor: MovementMotor,
	p_machine: HsmStateMachine
)-> void:
	motor = p_motor
	machine = p_machine



func capture()-> void:
	horizontal_axis = Input.get_axis(
		&"move_left",
		&"move_right"
	)

	# comunicação direta: input -> motor
	if is_instance_valid(motor):
		motor.set_horizontal_intent(horizontal_axis)

	# comando discreto: input -> HSM
	if Input.is_action_just_pressed(&"jump"):
		print("INPUT: Pulo pressionado!")
		if is_instance_valid(machine):
			machine.send_event(&"jump_pressed") 