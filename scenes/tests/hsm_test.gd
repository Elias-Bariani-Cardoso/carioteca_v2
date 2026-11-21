
extends Node

var reached_apex: bool = false

@onready var machine: HsmStateMachine = $StateMachine

@onready var grounded: HsmState = \
	$StateMachine/Locomotion/Grounded

@onready var idle: HsmState = \
	$StateMachine/Locomotion/Grounded/Idle

@onready var running: HsmState = \
	$StateMachine/Locomotion/Grounded/Running

@onready var rising: HsmState = \
	$StateMachine/Locomotion/Airborne/Rising

@onready var falling: HsmState = \
	$StateMachine/Locomotion/Airborne/Falling


func _ready() -> void:
	# Configura transição de movimento.
	idle.add_transition(
		HsmTransition.new(running, &"move_start")
	)

	# Configura pulo no estado-pai.
	var jump := HsmTransition.new(
		rising,
		&"jump_pressed",
		10
	)

	jump.guard = func(_ctx: HsmContext) -> bool:
		return true

	jump.effect = func(_ctx: HsmContext) -> void:
		print("EFFECT: Impulso de pulo solicitado")

	grounded.add_transition(jump)

	machine.transitioned.connect(_on_transitioned)

	var auto_fall := HsmTransition.new(
	falling,
	HsmTransition.AUTO_TRIGGER
	)

	auto_fall.guard = func(_ctx: HsmContext) -> bool:
		return reached_apex

	rising.add_transition(auto_fall)

	# Inicializa depois de configurar as transições.
	var context := HsmContext.new(self)

	# Volta de Falling para Idle.
	var reset_falling := HsmTransition.new(
		idle,
		&"reset"
	)
	falling.add_transition(reset_falling)


	# Volta de Running para Idle.
	var reset_running := HsmTransition.new(
		idle,
		&"reset"
	)
	running.add_transition(reset_running)


	# Transição local: Grounded -> Running.
	var local_run := HsmTransition.new(
		running,
		&"move_local",
		0,
		HsmTransition.TransitionKind.LOCAL
	)
	
	grounded.add_transition(local_run)


	# Transição externa: Grounded -> Running.
	var external_run := HsmTransition.new(
		running,
		&"move_external"
	)
	grounded.add_transition(external_run)


	# Transição interna: apenas um efeito.
	var action := HsmTransition.new(
		null,
		&"action",
		0,
		HsmTransition.TransitionKind.INTERNAL
	)

	action.effect = func(_ctx: HsmContext) -> void:
		print("EFFECT: Ação interna executada")

	running.add_transition(action)


	# Transição externa para o próprio Running.
	var restart := HsmTransition.new(
		running,
		&"restart"
	)
	running.add_transition(restart)


	machine.initialize(context)

	machine.send_event(&"move_start")
	machine.send_event(&"jump_pressed")

	# Condição falsa: permanece em Rising.
	machine.physics_tick(1.0 / 60.0)
	print("ACTIVE: ", machine.get_active_state().name)

	# Condição verdadeira: deve mudar para Falling.
	reached_apex = true
	machine.physics_tick(1.0 / 60.0)
	print("ACTIVE: ", machine.get_active_state().name)

	machine.send_event(&"reset")

	# Local: Grounded permanece ativo.
	machine.send_event(&"move_local")

	# Interna: não muda o estado.
	machine.send_event(&"action")

	# Externa: reinicia Running.
	machine.send_event(&"restart")

	# Volta a Idle.
	machine.send_event(&"reset")

	# Externa de Grounded para Running.
	machine.send_event(&"move_external")


func _on_transitioned(
	previous: HsmState,
	current: HsmState
) -> void:
	print("TRANSITION: ", previous.name, " -> ", current.name)
