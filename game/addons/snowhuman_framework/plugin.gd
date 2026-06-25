@tool
extends EditorPlugin

const AUTOLOADS := {
	"GameCore": "res://addons/snowhuman_framework/autoload/game_core.gd",
	"DataRegistry": "res://addons/snowhuman_framework/autoload/data_registry.gd",
	"EventBus": "res://addons/snowhuman_framework/autoload/event_bus.gd",
	"SaveService": "res://addons/snowhuman_framework/autoload/save_service.gd",
}

func _enter_tree() -> void:
	for singleton_name in AUTOLOADS.keys():
		add_autoload_singleton(singleton_name, AUTOLOADS[singleton_name])


func _exit_tree() -> void:
	for singleton_name in AUTOLOADS.keys():
		remove_autoload_singleton(singleton_name)
