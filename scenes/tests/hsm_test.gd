
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


func _on_transitioned(
	previous: HsmState,
	current: HsmState
) -> void:
	print("TRANSITION: ", previous.name, " -> ", current.name)
