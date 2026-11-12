class_name NavPortal
extends Area3D
#Purpose: used to detect entry points between different terrain structures and buildings
#How: Through collision detection with other portal areas

@export var nav_tile: NavTile = null

var neighbouring_portals: Array[NavPortal] = []

func is_colliding_with(neighbouring_nav_tile: NavTile) -> bool:
	if neighbouring_portals.is_empty():
		#print("portal neighbour check")
		neighbouring_portals = get_neighbouring_portals()
	
	#print("comparing nav tile to detected collisions")
	
	for portal in neighbouring_portals:
		if portal.get_nav_tile() == neighbouring_nav_tile:
			return true
	
	return false

func get_neighbouring_portals() -> Array[NavPortal]:
	var colliding_portals: Array[NavPortal] = []
	
	#print("overlapping areas: ", get_overlapping_areas())
	
	for area in get_overlapping_areas():
		if area is NavPortal:
			if area.get_nav_tile() == nav_tile:
				#print("internal overlap")
				continue #because this portal is from the same tile
			
			colliding_portals.append(area)
			
			##DEBUG
			for child in area.get_children():
				if child is CollisionShape3D:
					child.debug_color = Color.GREEN
	
	return colliding_portals

func get_nav_tile() -> NavTile:
	return nav_tile

func set_nav_tile(new_nav_tile: NavTile):
	nav_tile = new_nav_tile
