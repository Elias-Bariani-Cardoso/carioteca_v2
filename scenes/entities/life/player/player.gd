extends CharacterBody2D

@onready var movement_intent_provider: PlayerIntentProvider = \
	$MovementPlayerIntentProvider

@onready var movement_sensors: MovementSensors = \
	$MovementSensors

@onready var movement_motor: MovementMotor = \
	$MovementMotor

@onready var movement_machine: HsmStateMachine = \
	$MovementStateMachine


# STATES DA MÁQUINA DE ESTADOS DE - MOVIMENTO:
@onready var grounded: HsmState = \
	$MovementStateMachine/Locomotion/Grounded
@onready var airborne: HsmState = \
	$MovementStateMachine/Locomotion/Airborne
@onready var idle: HsmState = \
	$MovementStateMachine/Locomotion/Grounded/Idle
@onready var running: HsmState = \
	$MovementStateMachine/Locomotion/Grounded/Running
@onready var rising: HsmState = \
	$MovementStateMachine/Locomotion/Airborne/Rising
@onready var falling: HsmState = \
	$MovementStateMachine/Locomotion/Airborne/Falling	



func _ready() -> void:
	# configuração de movimento
	movement_sensors.configure(self)
	movement_motor.configure(self, movement_sensors)
	movement_intent_provider.configure(movement_motor, movement_machine)

	var movement_context := HsmContext.new(self)

	movement_context.intent_provider = movement_intent_provider
	movement_context.sensors = movement_sensors
	movement_context.motor = movement_motor

	# registrar transições de movimento antes dessa chamada:
	_register_movement_transitions()
	# iniciar máquina
	movement_machine.initialize(movement_context)



func _physics_process(delta: float) -> void:
	# 1 - captura input de movimento e encaminha ao motor ou máquina de movimento
	movement_intent_provider.capture()

	# 2 - resolve transições e políticas de estados de movimento
	movement_machine.physics_tick(delta)

	# 3 - calcula a velocidade de movimento pelos dois componentes (horizontal e vertical)
	movement_motor.physics_tick(delta)

	# 4 - executa movimento físico uma única vez
	move_and_slide()

	# 5 - captura resultado das colisões de movimento
	movement_sensors.refresh()



func _register_movement_transitions() -> void:
	# IDLE -> RUNNING: muda estado quando existe direção solicitada
	var move_start := HsmTransition.new(
		running,
		HsmTransition.AUTO_TRIGGER
	)

	move_start.guard = func(ctx: HsmContext) -> bool:
		var provider := ctx.intent_provider as PlayerIntentProvider
		return(
			provider != null
			and absf(provider.horizontal_axis) > 0.05
		)

	idle.add_transition(move_start)


	# RUNNING -> IDLE: muda estado quando não há mais direção solicitada
	var move_stop:= HsmTransition.new(
		idle,
		HsmTransition.AUTO_TRIGGER
	)

	move_stop.guard = func(ctx: HsmContext) -> bool:
		var provider := ctx.intent_provider as PlayerIntentProvider
		return(
			provider != null
			and absf(provider.horizontal_axis) <= 0.05
		)

	running.add_transition(move_stop)

	
	# GROUNDED -> RISING: muda estado quando pula
	var jump := HsmTransition.new(
		rising,
		&"jump_pressed",
		10
	)

	jump.guard = func(ctx: HsmContext) -> bool:
		var feedback := ctx.sensors as MovementSensors
		return(
			feedback != null
			and feedback.has_feedback
			and feedback.is_grounded
		)

	jump.effect = func(ctx: HsmContext) -> void:
		var movement:= ctx.motor as MovementMotor

		if movement != null:
			movement.request_jump()
	
	grounded.add_transition(jump)

	
	# RISING -> FALLING: muda estado quando chega no final do pulo
	var apex := HsmTransition.new(
		falling,
		HsmTransition.AUTO_TRIGGER
	)

	apex.guard = func(ctx: HsmContext) -> bool:
		var feedback := ctx.sensors as MovementSensors
		return feedback != null and feedback.is_falling()

	rising.add_transition(apex)


	# AIRBORNE -> GROUNDED: muda estado ao tocar no chão
	var landing := HsmTransition.new(
		grounded,
		HsmTransition.AUTO_TRIGGER,
		10
	)

	landing.guard = func(ctx: HsmContext) -> bool:
		var feedback := ctx.sensors as MovementSensors
		var movement := ctx.motor as MovementMotor

		return(
			feedback != null
			and movement != null
			and feedback.has_feedback
			and feedback.is_grounded
			and not movement.has_pending_jump()
		)

	airborne.add_transition(landing)


	#GROUNDED -> FALLING: muda de estado ao cair de plataforma
	var walk_off := HsmTransition.new(
		falling,
		HsmTransition.AUTO_TRIGGER,
		10
	)

	walk_off.guard = func(ctx: HsmContext) -> bool:
		var feedback := ctx.sensors as MovementSensors
		return(
			feedback != null
			and feedback.has_feedback
			and not feedback.is_grounded
		)

	grounded.add_transition(walk_off)