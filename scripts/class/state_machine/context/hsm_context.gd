class_name HsmContext
extends RefCounted


var entity: Node
var intent_provider: Node
var sensors: Node
var motor: Node
var ability_registry: Node



func _init(p_entity: Node = null) -> void:
	entity = p_entity
