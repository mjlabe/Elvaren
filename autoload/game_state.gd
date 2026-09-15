extends Node

var flags: Dictionary = {}
var current_dungeon: int = 0

signal flag_changed(flag_name: String, value: bool)
signal crystal_collected(crystal_name: String)


func set_flag(name: String, value: bool) -> void:
	flags[name] = value
	flag_changed.emit(name, value)


func get_flag(name: String) -> bool:
	return flags.get(name, false)


func collect_crystal(crystal_name: String) -> void:
	set_flag("crystal_" + crystal_name + "_collected", true)
	crystal_collected.emit(crystal_name)
