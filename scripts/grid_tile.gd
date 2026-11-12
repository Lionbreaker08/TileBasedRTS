class_name GridTile
extends Resource

@export_group("Terrain Details")
@export var terrain: TerrainType = null
@export var height: int = 0    # 0 = Base Level (no height modification)

@export_group("Feature Details")
@export var feature: FeatureType = null
@export var rotation: TileEnums.TileRotation

@export_group("Tile Details")
@export var tile_height_modifier: float = 2.0
@export var tile_thickness: float = 0.2
@export var tile_size: int = 8

@export_group("Tile Location")
@export var tile_vector: Vector2i

var tile_node: Node3D = null #main node to represent the physical object in the world
var terrain_node: Node3D = null
var feature_node: Node3D = null

var group_name: String = "group not set"

func _to_string() -> String:
	return "GridTile %s" % get_vector_string()

##Node attaching and deleting

func create_new_tile_node():
	if (tile_node != null):
		destroy()
	
	tile_node = Node3D.new()
	tile_node.position = Vector3(tile_vector.x * tile_size, 0, tile_vector.y * tile_size)

#for creating the physical terrain node/objects
func create_all() -> bool:
	create_new_tile_node()
	
	# generate any terrain or features
	if (terrain != null):
		create_terrain()
	
	if (feature != null):
		create_feature()
	
	#Set the grouping of the main tile node
	set_group(self.to_string())
	
	return true

func create_terrain() -> bool:
	if (terrain == null):
		push_warning("Tile was attempted to be created with no terrain set")
		return false
	
	if (terrain_node != null):
		delete_terrain()
	
	terrain_node = terrain.get_scene().instantiate()
	
	terrain_node.scale.y += (tile_height_modifier * height)
	
	tile_node.add_child(terrain_node)
	
	return true

func create_feature() -> bool:
	if (feature == null):
		return false
	
	if (feature_node != null):
		delete_feature()
	
	feature_node = feature.get_scene().instantiate()
	tile_node.add_child(feature_node)
	
	#Adjust y value of where the feature spawns
	feature_node.position.y = tile_thickness + (tile_thickness * tile_height_modifier * height)
	
	#Adjusts Rotation
	feature_node.rotate_y(deg_to_rad(rotation))
	
	return true

func attach_auto_portals_to_feature():
	if (feature_node == null):
		feature_node = Node3D.new()
		tile_node.add_child(feature_node)
		feature_node.name = "Blank Feature"
		feature_node.position.y = tile_thickness + (tile_thickness * tile_height_modifier * height)
	
	#Create new container for portals
	var portal_container: Node3D = Node3D.new()
	portal_container.name = "Portal Container"
	feature_node.add_child(portal_container)
	
	var portal_size: Vector3 = Vector3(0.325, 1, tile_size - 0.2)
	@warning_ignore("integer_division")
	var portal_offset: Vector3 = Vector3(tile_size/2, 0, 0)
	
	portal_container.add_child(create_auto_portal(0, portal_size, portal_offset))
	portal_container.add_child(create_auto_portal(90, portal_size, portal_offset))
	portal_container.add_child(create_auto_portal(180, portal_size, portal_offset))
	portal_container.add_child(create_auto_portal(270, portal_size, portal_offset))


func create_auto_portal(portal_rotation: float, size: Vector3, offset: Vector3) -> NavPortal:
	var auto_portal: NavPortal = NavPortal.new()
	var portal_name: String = "NavPortal%d " % portal_rotation
	auto_portal.name = portal_name
	
	# Create collision shape
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	
	box_shape.size = size
	collision.shape = box_shape

	# Attach collision to portal
	auto_portal.add_child(collision)

	# Configure collision detection # 4 is == to layer 3 due to bitmask
	auto_portal.collision_layer = 4 
	auto_portal.collision_mask = 4
	
	auto_portal.position = Vector3(0, 0.5, 0)
	
	collision.position = offset
	
	auto_portal.rotation_degrees = Vector3(0, portal_rotation, 0)
	
	return auto_portal


func destroy():
	if is_instance_valid(tile_node):
		tile_node.queue_free()
	
	tile_node = null

func delete_terrain():
	if is_instance_valid(terrain_node):
		terrain_node.queue_free()
	
	terrain_node = null

func delete_feature():
	if is_instance_valid(feature_node):
		feature_node.queue_free()
	
	feature_node = null

##GETS AND SETS##

func init_node(new_vector: Vector2i, new_height: int, new_height_modifier: float, new_tile_size: int):
	set_vector(new_vector)
	set_height(new_height)
	set_height_modifier(new_height_modifier)
	set_tile_size(new_tile_size)
	create_new_tile_node()

func set_group(name: String):
	if tile_node == null:
		push_warning("Group has attempted to be set, before tile node is created")
		return
	
	group_name = name
	tile_node.add_to_group(group_name)

func get_group() -> String:
	return group_name

func set_node_name(name: String):
	tile_node.name = name

func set_terrain(new_terrain_type: TerrainType):
	terrain = new_terrain_type

func set_height(new_height: int):
	height = new_height

func set_height_modifier(new_height_modifier: float):
	tile_height_modifier = new_height_modifier

func set_tile_size(new_tile_size: int):
	tile_size = new_tile_size

func set_feature(new_feature_type: FeatureType):
	feature = new_feature_type

func set_rotation(new_rotation: TileEnums.TileRotation):
	rotation = new_rotation

func set_vector(new_vector: Vector2i):
	tile_vector = new_vector

func get_terrain() -> TerrainType:
	return terrain

func get_height() -> int:
	return height

func get_feature() -> FeatureType:
	return feature

func get_main_node() -> Node3D:
	return tile_node

func get_terrain_node() -> Node3D:
	return terrain_node

func get_feature_node() -> Node3D:
	return feature_node

func get_vector() -> Vector2i:
	return tile_vector

func get_vector_string() -> String:
	var return_string: String = "[%d,%d]" % [tile_vector.x, tile_vector.y]
	return return_string

func get_worldspace_height() -> float:
	return tile_thickness + (tile_thickness * tile_height_modifier * height)

func get_tile_height_modifier() -> float:
	return tile_height_modifier

func get_tile_thickness() -> float:
	return tile_thickness

func get_tile_size() -> float:
	return tile_size
