class_name HsmState
extends Node

# subestado inicial, para estados compostos
@export var initial_child: HsmState

# conjunto de transições/arestas
var transitions: Array[HsmTransition] = []



func get_parent_state() -> HsmState:
	return get_parent() as HsmState


func add_transition(transition: HsmTransition) -> void:
	if transition == null:
		return

	transitions.append(transition)


func enter(_context: HsmContext, _delta: float) -> void:
	pass


func physics_update(_context: HsmContext, _delta: float) -> void:
	pass


func exit(_context: HsmContext) -> void:
	pass