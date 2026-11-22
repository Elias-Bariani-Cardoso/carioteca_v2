class_name HsmTransitionResolver
extends RefCounted



func resolve(
	active_path: Array[HsmState],
	event: StringName,
	context: HsmContext,
) -> HsmTransition:


	var selected: HsmTransition = null
	var selected_depth: int = -1


	# percorre da folha ativa até o estado raiz
	for depth in range(active_path.size() -1, -1, -1):
		var state: HsmState = active_path[depth]


		if not is_instance_valid(state):
			continue

		# recupera transições de eventos recebidos
		var candidates: Array = state.get_transitions(event)

		for candidate in candidates:
			var transition: HsmTransition = candidate as HsmTransition

			if transition == null:
				continue

			# confere se transição pertence ao estado consultado
			if transition.source != state:
				continue

			# somente transições internas podem não possuir destino
			if transition.kind != HsmTransition.TransitionKind.INTERNAL:
				if not is_instance_valid(transition.target):
					continue

			# valida trigger e guard
			if not transition.can_trigger(event, context):
				continue

			# primeira transição válida encontrada
			if selected == null:
				selected = transition
				selected_depth = depth
				continue
			
			# prioridade maior vence
			if transition.priority > selected.priority:
				selected = transition
				selected_depth = depth
				continue

			if(
				transition.priority == selected.priority
				and depth > selected_depth
			):
				selected = transition
				selected_depth = depth

	return selected