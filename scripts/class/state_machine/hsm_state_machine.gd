class_name HsmStateMachine
extends Node



signal transitioned(
	previous_state: HsmState,
	current_state: HsmState
)


const MAX_EVENT_PER_DISPATCH: int = 64

@export var root_state : HsmState

var context: HsmContext
var active_state_path: Array[HsmState] = []

var resolver := HsmTransitionResolver.new()

var _pending_events: Array[StringName] = []
var _is_dispatching: bool = false
var _is_updating: bool = false



func _ready() -> void:
	if root_state == null:
		push_error("HSM: Estado raiz não configurado.")
		return

	if root_state.get_parent() != self:
		push_error("HSM: A raiz deve ser filha da StateMachine.")
		return

	context = HsmContext.new(get_parent())

	var initial_path := _build_target_path(root_state)

	if initial_path.is_empty():
		push_error("HSM: Caminho inicial inválido")
		return

	# impede transições reentrantes durante a inicialização
	_is_dispatching = true

	for state in initial_path:
		active_state_path.append(state)
		state.enter(context)

	_is_dispatching = false
	_drain_events()



func get_active_state() -> HsmState:
	if active_state_path.is_empty():
		return null

	return active_state_path.back()



func send_event(event: StringName) -> void:
	if active_state_path.is_empty():
		return

	_pending_events.append(event)
	_drain_events()



func physics_tick(delta: float) -> void:
	if active_state_path.is_empty():
		return

	if _is_dispatching or _is_updating:
		return

	_is_updating = true

	# eventos gerados durante a atualização serão processados após a iteração
	for state in active_state_path:
		state.physics_update(context, delta) 

	_is_updating = false
	_drain_events()



func _drain_events() -> void:
	if _is_dispatching or _is_updating:
		return

	if active_state_path.is_empty():
		return

	_is_dispatching = true
	var processed: int = 0

	while not _pending_events.is_empty():
		if processed >= MAX_EVENT_PER_DISPATCH:
			push_warning("HSM: Limite de eventos atingido")
			_pending_events.clear()
			break

		var event: StringName = _pending_events.pop_front()

		var transition := resolver.resolve(
			active_state_path,
			event,
			context
		)

		if transition != null:
			_perform_transition(transition)

		processed += 1

	_is_dispatching = false



func _perform_transition(
	transition: HsmTransition
) -> void:

	var target_path := _build_target_path(
		transition.target
	)

	if target_path.is_empty():
		push_warning("HSM: Destino inválido")
		return

	var previous_state := get_active_state()

	# encontra ancestral em comum mais próximo a partir da raiz
	var common_count: int = 0

	while(
		common_count < active_state_path.size()
		and common_count < target_path.size()
	):
		
		if(
			active_state_path[common_count]
			!= target_path[common_count]
		):
			break

		common_count += 1

	# sai da folha até o ancestral em comum
	while active_state_path.size() > common_count:
		var state: HsmState = active_state_path.back()
		state.exit(context)
		active_state_path.pop_back()

	# executa efeito de transição
	if transition.effect.is_valid():
		transition.effect.call()

	# vai do ancestral em comum até a nova folha
	for index in range(common_count, target_path.size()):
		var state: HsmState = target_path[index]
		active_state_path.append(state)
		state.enter(context)

	transition.emit(
		previous_state,
		get_active_state()
	)



func _build_target_path(
	target: HsmState
) -> Array[HsmState]:

	var path: Array[HsmState] = []

	if not is_instance_valid(target):
		return path

	# descobre o caminho da raiz até o destino
	var current: HsmState = target

	while current != null:
		path.push_front(current)
		
		if current == root_state:
			break

		current = current.get_parent_state()

	if path.is_empty() or path[0] != root_state:
		path.clear()
		return path

	# em destinos compostos, entra nos filhos iniciais até alcançar uma folha
	current = path.back()

	while current.initial_child != null:
		var child: HsmState = current.initial_child

		if not is_instance_valid(child):
			push_error("HSM: Filho inicial inválido")
			path.clear()
			return path

		if child.get_parent_state() != current:
			push_error("HSM: Filho inicial não pertence ao estado")
			path.clear()
			return path

		path.append(child)
		current = child

	return path