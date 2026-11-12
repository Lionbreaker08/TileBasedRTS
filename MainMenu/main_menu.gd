extends Control


func _on_enter_main_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_enter_editor_button_pressed() -> void:
	get_tree().change_scene_to_file("res://TerrainEditor/Editor.tscn")


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
