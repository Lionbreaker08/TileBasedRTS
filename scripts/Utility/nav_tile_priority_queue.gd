class_name NavPriorityQueue
extends RefCounted

var data: Array[NavTileCost] = []

func is_empty() -> bool:
	return data.is_empty()

func insert(nav_tile: NavTile, cost: float):
	var new_element: NavTileCost = NavTileCost.new(nav_tile, cost)
	data.push_back(new_element)

	var new_element_index: int = data.size() - 1
	up_heap(new_element_index)

func pop() -> NavTile:
	if (self.is_empty()):
		return null
	
	var last_element_index: int = data.size() - 1
	swap(0, last_element_index)
	var return_element = data.pop_back().tile
	
	#resorting
	if (not self.is_empty()):
		down_heap(0)
	
	return return_element

func down_heap(current_index: int):
	
	var left_index: int = (current_index * 2) + 1
	var right_index: int = (current_index * 2) + 2
	
	var selected_cost: float = data[current_index].cost
	var selected_index: int = current_index
	
	if (right_index < data.size()):
		if (data[right_index].cost <= selected_cost):
			selected_cost = data[right_index].cost
			selected_index = right_index
	
	if (left_index < data.size()):
		if (data[left_index].cost <= selected_cost):
			selected_cost = data[left_index].cost
			selected_index = left_index
	
	if (selected_index == current_index):
		return
	
	swap(current_index, selected_index)
	down_heap(selected_index)

func up_heap(current_index: int):
	if current_index <= 0:
		return
	
	@warning_ignore("integer_division")
	var parent_index: int = (current_index - 1) / 2
	
	if data[current_index].cost < data[parent_index].cost:
		swap(current_index, parent_index)
		up_heap(parent_index)


func swap(xindex: int, yindex: int):
	var element_x := data[xindex]
	var element_y := data[yindex]

	data[xindex] = element_y
	data[yindex] = element_x


class NavTileCost:
	var tile: NavTile
	var cost: float

	func _init(new_tile: NavTile, new_cost: float) -> void:
		tile = new_tile
		cost = new_cost
