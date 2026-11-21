class_name HsmTransition
extends RefCounted


const AUTO_TRIGGER: StringName = &""

var target: HsmState
var trigger: StringName
var priority: int = 0

var guard: Callable = Callable()
var effect: Callable = Callable()



func _init(
	p_target: HsmState,
	p_trigger: StringName,
	p_priority: int = 0,
) -> void:
	target = p_target
	trigger = p_trigger
	priority = p_priority


func can_trigger(
	event: StringName,
	context: HsmContext
) -> bool:

	if event != trigger:
		return false

	# transição automática com guard
	if trigger == AUTO_TRIGGER and guard.is_null():
		return false
	
	# transição sem guard é permitida pelo trigger
	if guard.is_null():
		return true
	
	# guard inválido bloqueia transição
	if not guard.is_valid():
		push_warning("HSM: TransitionGuard inválido.")
		return false

	return guard.call(context) == true
