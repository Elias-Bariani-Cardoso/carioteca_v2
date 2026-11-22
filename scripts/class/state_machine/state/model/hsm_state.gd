class_name HsmState
extends Node

# subestado inicial, para estados compostos
@export var initial_child: HsmState

# conjunto de transições/arestas
var transitions: Dictionary = {}



func get_parent_state() -> HsmState:
	return get_parent() as HsmState



func add_transition(transition: HsmTransition) -> void:
	if transition == null:
		push_warning("HSM: Tentativa de registrar transição nula.")
		return

	# transição não pode pertencer a dois estados
	if transition.source != null and transition.source != self:
		push_error("HSM: Transição já pertence a outro estado.")
		return

	if transition.kind == HsmTransition.TransitionKind.INTERNAL:
		if transition.target != null:
			push_error("HSM: Transição interna não deve ter destino.")
			return

		if transition.trigger == HsmTransition.AUTO_TRIGGER:
			push_error(
				"HSM: Transição interna automática não suportada."
			)
			return
	else:
		if not is_instance_valid(transition.target):
			push_warning("HSM: Transição sem destino válido.")
			return

	# transições locais devem apontar para descendentes
	if transition.kind == HsmTransition.TransitionKind.LOCAL:
		if transition.target == self:
			push_error("HSM: Transição local não pode apontar para si.")
			return

		var ancestor: HsmState = \
		transition.target.get_parent_state()

		var is_descendant: bool = false

		# busca destino local a partir da origem
		while ancestor != null:
			if ancestor == self:
				is_descendant = true
				break

			ancestor = ancestor.get_parent_state()

		if not is_descendant:
			push_error(
				"HSM: Destino local não descende da origem."
			)
			return
	
	transition.source = self

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
