class_name HsmStateMachine
extends Node



signal transitioned(
	previous_state: HsmState,
	current_state: HsmState
)


const MAX_EVENT_PER_DISPATCH: int = 64
const MAX_AUTOMATIC_TRANSITIONS_PER_TICK: int = 16

@export var root_state : HsmState

var context: HsmContext
var active_state_path: Array[HsmState] = []

var resolver := HsmTransitionResolver.new()

var _pending_events: Array[StringName] = []

var _is_initialized: bool = false
var _is_dispatching: bool = false
var _is_updating: bool = false



func  initialize(p_context: HsmContext) -> void:
	if _is_initialized:
		push_warning("HSM: Máquina já inicializada.")
		return

	if p_context == null:
		push_error("HSM: contexto não configurado.")
		return

	if not is_instance_valid(root_state):
		push_error("HSM: Estado raiz é inválido.")
		return

	if root_state.get_parent() != self:
		push_error("HSM: A raiz deve ser filha da máquina.")
		return

	var initial_path := _build_target_path(root_state)

	if initial_path.is_empty():
		push_error("HSM: Caminho inicial inválido.")
		return

	context = p_context

	_is_initialized = true
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
	if not _is_initialized:
		return

	if event == HsmTransition.AUTO_TRIGGER:
		push_warning(
			"HSM: Gatilho automático reservado"
		)
		return

	_pending_events.append(event)
	_drain_events()



func physics_tick(delta: float) -> void:
	if not _is_initialized:
		return

	if _is_dispatching or _is_updating:
		return

	# avalia condições com as informações dos sensores desse ciclo
	_evaluate_automatic_transitions()

	_is_updating = true

	# eventos gerados durante a atualização serão processados após a iteração
	for state in active_state_path:
		state.physics_update(context, delta) 

	_is_updating = false

	_drain_events()



func _drain_events() -> void:
	if not _is_initialized:
		return

	if _is_dispatching or _is_updating:
		return

	if active_state_path.is_empty():
		push_error("HSM: Máquina inicializada sem estados ativos")
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
	if transition == null:
		return

	if not is_instance_valid(transition.source):
		push_warning("HSM: Origem da transição inválida")
		return

	if not active_state_path.has(transition.source):
		push_warning("HSM: Origem não está ativa")
		return

	# TRANSIÇÃO INTERNA: somente efeito
	if transition.kind == HsmTransition.TransitionKind.INTERNAL:
		if transition.effect.is_valid():
			transition.effect.call(context)
		return

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

	# TRANSIÇÃO LOCAL: preserva o estado da origem
	if transition.kind == HsmTransition.TransitionKind.LOCAL:
		if(
			transition.target == transition.source
			or not target_path.has(transition.source)
		):
			push_warning("HSM: Destino local inválido.")
			return

	#TRANSIÇÃO EXTERNA: reentra nos estados necessários
	elif transition.kind == HsmTransition.TransitionKind.EXTERNAL:
		var source_index: int = active_state_path.find(
			transition.source
		)

		var target_index: int = active_state_path.find(
			transition.target
		)

		# se origem e destino possuem relação ancestral
		# precisamos reentrar no estado correspondente
		if (
			target_path.has(transition.source)
			or target_index >= 0
		):
			var reentry_index: int = source_index

			if target_index >= 0:
				reentry_index = mini(
					reentry_index,
					target_index
				)

			common_count = mini(
				common_count,
				reentry_index
			)
		
	else:
		push_warning("HSM: Tipo de transição desconhecido.")
		return

	var has_lifecycle_change: bool = (
		common_count < active_state_path.size()
		or common_count < target_path.size()
	)

	# EXIT: da folha até o ancestral/limite compartilhado
	while active_state_path.size() > common_count:
		var state: HsmState = active_state_path.back()

		state.exit(context)
		active_state_path.pop_back()

	# EFFECT: executa efeito de transição
	if transition.effect.is_valid():
		transition.effect.call(context)

	# ENTER: vai do ancestral/limite compartilhado até a nova folha
	for index in range(common_count, target_path.size()):
		var state: HsmState = target_path[index]

		active_state_path.append(state)
		state.enter(context)

	# valida se o caminho mudou
	if has_lifecycle_change:
		transitioned.emit(
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



func _evaluate_automatic_transitions() -> void:
	if not _is_initialized:
		return

	if _is_dispatching or _is_updating:
		return

	_is_dispatching = true

	var processed: int = 0

	while processed < MAX_AUTOMATIC_TRANSITIONS_PER_TICK:
		var transition := resolver.resolve(
			active_state_path,
			HsmTransition.AUTO_TRIGGER,
			context
		)

		# nenhuma condição automática foi satisfeita
		if transition == null:
			break

		# proteção contra transição interna automática
		if transition.kind == HsmTransition.TransitionKind.INTERNAL:
			push_warning(
				"HSM: Transição interna automática não suportada"
			)
			break

		var target_path := _build_target_path(
			transition.target
		)

		if target_path.is_empty():
			push_warning(
				"HSM: Destino automático inválido"
			)
			break

		# impedir transição automática de repetir o mesmo efeito
		if target_path == active_state_path:
			push_warning(
				"HSM: Transição automática sem mudança de estado"
			)
			break

		_perform_transition(transition)
		processed += 1

	if processed >= MAX_AUTOMATIC_TRANSITIONS_PER_TICK:
		push_warning(
			"HSM: Limite de transições automáticas atingido"
		)

	_is_dispatching = false

	# processa eventos enviados durante os Enter/Exit/Effect
	_drain_events()