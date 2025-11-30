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

@export var grass:Biome = Biome.new():
	set(value):
		grass = value
		_generate_mesh()
		notify_property_list_changed()

@export var sand:Biome = Biome.new():
	set(value):
		sand = value
		_generate_mesh()
		notify_property_list_changed()

@export var water:Biome = Biome.new():
	set(value):
		water = value
		_generate_mesh()
		notify_property_list_changed()

		
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
	var heightmapGen = HeightMapGenerator.new()
	var map = heightmapGen._generateHeightmap(numTilesPerLine)
	print("map", map)
	print("numTilesPerLine: ", numTilesPerLine)
	print("minStart: ", minStart)
	
	var tempVerts:PackedVector3Array
	var tempIndices: PackedInt32Array
	var tempNormals: PackedVector3Array
	var tempColours: PackedColorArray
	var tempUvs: PackedVector2Array
	var biomes:Array = [water, sand, grass]
		
	for y in range(0, numTilesPerLine):
		for x in range(0, numTilesPerLine):
			var uv:Vector2 = _getBiomeInfo(map[x][y], biomes);
			tempUvs.append(uv);
			tempUvs.append(uv);
			tempUvs.append(uv);
			tempUvs.append(uv);
			
			var isWaterTile:bool = false
			var tileHeight:float = -waterDepth if isWaterTile else 0.0
			
			var tilePos:Vector3 = Vector3(minStart + x, tileHeight, minStart + y + 1)
			var ind = tempVerts.size()
			
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
			if y == (numTilesPerLine /2) && x == (numTilesPerLine /2):
				tempColours.append(Color( 0.105882324, 0.5422884, 0.81960785, 1))
				tempColours.append(Color( 0.105882324, 0.5422884, 0.81960785, 1))
				tempColours.append(Color( 0.105882324, 0.5422884, 0.81960785, 1))
				tempColours.append(Color( 0.105882324, 0.5422884, 0.81960785, 1))
			else:
				tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
				tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
				tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))
				tempColours.append(Color(0.07008723, 0.3301887, 0.118246295, 1))

	# Build the mesh arrays
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tempVerts
	arrays[Mesh.ARRAY_INDEX] = tempIndices
	arrays[Mesh.ARRAY_NORMAL] = tempNormals
	#arrays[Mesh.ARRAY_COLOR] = tempColours
	arrays[Mesh.ARRAY_TEX_UV] = tempUvs

	# Create and assign the mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	material_override = mat

func _getBiomeInfo(height:float, biomes:Array):
	var biomeIndex: int = 0
	var biomeStartHeight: float = 0
	
	for i in range(0, biomes.size()):
		if (height <= biomes[i].height):
			biomeIndex = i
			break;
		biomeStartHeight = biomes[i].height
	
	var biome:Biome = biomes[biomeIndex]
	var sampleT = inverse_lerp(biomeStartHeight, biome.height, height)
	sampleT = int(sampleT * biome.numSteps) / float(max(biome.numSteps, 1))

	var uv = Vector2(biomeIndex, sampleT)
	print ("uv:", uv)
	return uv
