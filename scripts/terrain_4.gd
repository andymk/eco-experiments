@tool
extends MeshInstance3D

@export var regenerate: bool = false:
	set(value):
		regenerate = value
		_generate_mesh()
		notify_property_list_changed()  # forces editor refresh

@export var worldSize: int = 20:   # Number of squares along X and Z
	set(value):
		worldSize = value
		_generate_mesh()
		notify_property_list_changed()  # forces editor refresh

var centralize:bool = true;
var waterDepth:float = 0.2;
var edgeDepth:float = 0.2;

# UVs for texture mapping (optional)
var uvs := PackedVector2Array([
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1)
])


		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generate_mesh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _generate_mesh() -> void:
	var m := mesh as ArrayMesh
	if m:
		m.clear_surfaces()
	
	var numTilesPerLine:int = int(ceil(worldSize));
	var minStart:float = -numTilesPerLine / 2.0 if centralize else 0.0
	
	print("numTilesPerLine: ", numTilesPerLine)
	print("minStart: ", minStart)
	
	var tempVerts:PackedVector3Array
	var tempIndices: PackedInt32Array
	var tempNormals: PackedVector3Array
	var tempColours: PackedColorArray
	
	for y in range(0, numTilesPerLine):
		for x in range(0, numTilesPerLine):
			var isWaterTile:bool = false
			var tileHeight:float = -waterDepth if isWaterTile else 0.0
			
			var tilePos:Vector3 = Vector3(minStart + x, tileHeight, minStart + y + 1)
			var ind = tempVerts.size()
			print ("tilePose: ", tilePos)
			
			tempVerts.append(Vector3(-0.5, 0, -0.5) + tilePos)
			tempVerts.append(Vector3(0.5, 0, -0.5) + tilePos)
			tempVerts.append(Vector3(-0.5, 0, 0.5) + tilePos)
			tempVerts.append(Vector3(0.5, 0, 0.5) + tilePos)
			
			# Two triangles: (0,1,2) and (0,2,3)
			tempIndices.append(ind + 0)
			tempIndices.append(ind + 1)
			tempIndices.append(ind + 2)
			tempIndices.append(ind + 2)
			tempIndices.append(ind + 1)
			tempIndices.append(ind + 3)

			# All normals pointing up
			tempNormals.append(Vector3.UP)
			tempNormals.append(Vector3.UP)
			tempNormals.append(Vector3.UP)
			tempNormals.append(Vector3.UP)

			# Vertex colours — all green (r,g,b,a)
			tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
			tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
			tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
			tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))

	print("vertices:", tempVerts.size())
	print("indices", tempIndices.size())

	# Build the mesh arrays
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tempVerts
	arrays[Mesh.ARRAY_INDEX] = tempIndices
	arrays[Mesh.ARRAY_NORMAL] = tempNormals
	arrays[Mesh.ARRAY_COLOR] = tempColours

	# Create and assign the mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	material_override = mat
