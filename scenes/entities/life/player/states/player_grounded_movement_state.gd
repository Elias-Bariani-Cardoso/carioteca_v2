extends HsmState



func enter(context: HsmContext) -> void:
	var motor:= context.motor as MovementMotor


	if motor != null:
		motor.set_airborne(false)