class_name HsmState
extends Node

# subestado inicial, para estados compostos
@export var initial_child: HsmState

# conjunto de transições/arestas
var transitions: Dictionary = {}



func get_parent_state() -> HsmState:
	return get_parent() as HsmState


func add_transition(transition: HsmTransition) -> void:
	var event := transition.trigger

	if not transitions.has(event):
		transitions[event] = []

	transitions[event].append(transition)


func get_transitions(event: StringName) -> Array:
	return transitions.get(event, [])


func enter(_context: HsmContext) -> void:
	pass


func physics_update(_context: HsmContext, _delta: float) -> void:
	pass


func exit(_context: HsmContext) -> void:
	pass