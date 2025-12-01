@tool
extends MeshInstance3D

var tex_rect:TextureRect

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

@export var seed:int = randi():
	set(value):
		seed = value
		_generate_mesh()
		notify_property_list_changed()


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
	var d = _generate_mesh()
	tex_rect = $"../TextureRect"
	var img = heightmap_to_image(d)
	var tex = ImageTexture.create_from_image(img)
	tex_rect.texture = tex

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _generate_mesh():
	var m := mesh as ArrayMesh
	if m:
		m.clear_surfaces()
	
	var numTilesPerLine:int = int(ceil(worldSize));
	var minStart:float = -numTilesPerLine / 2.0 if centralize else 0.0
	var heightmapGen = HeightMapGenerator.new()
	var map = heightmapGen.generate_heightmap(numTilesPerLine, seed)
	
	var tempVerts:PackedVector3Array
	var tempIndices: PackedInt32Array
	var tempNormals: PackedVector3Array
	var tempColours: PackedColorArray
	var tempUvs: PackedVector2Array
	var biomes:Array = [water, sand, grass]
	
	var nswe:Array[Vector2] = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(-1, 0),
		Vector2(1, 0)
	]
	
	var sideVertIndexByDir = [
		[0, 1],
		[3, 2],
		[2, 0],
		[1, 3]
	]
	
	var sideNormalsByDir = [
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3.LEFT,
		Vector3.RIGHT
	]
	
	var terrainData = TerrainData.new()
	
	for y in range(0, numTilesPerLine):
		for x in range(0, numTilesPerLine):
			var uv:Vector2 = _getBiomeInfo(map[x][y], biomes);
			tempUvs.append(uv);
			tempUvs.append(uv);
			tempUvs.append(uv);
			tempUvs.append(uv);
			
			var isWaterTile:bool = uv.x == 0
			var isLandTile:bool = !isWaterTile
			var tileHeight:float = -waterDepth if isWaterTile else 0.0
			
			var tilePos:Vector3 = Vector3(minStart + x, tileHeight, minStart + y + 1)
			var ind = tempVerts.size()
			
			var nw = Vector3(-0.5, 0, -0.5) + tilePos
			tempVerts.append(nw)
			var ne = Vector3(0.5, 0, -0.5) + tilePos
			tempVerts.append(ne)
			var sw = Vector3(-0.5, 0, 0.5) + tilePos
			tempVerts.append(sw)
			var se = Vector3(0.5, 0, 0.5) + tilePos
			tempVerts.append(se)
			var tileVertices = [nw, ne, sw, se]
			
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

			var biome:Biome = biomes[uv.x]
			var color = biome.startCol.lerp(biome.endCol, uv.y)
			tempColours.append(color)
			tempColours.append(color)
			tempColours.append(color)
			tempColours.append(color)
			
			var isEdgeTile: bool = x == 0 || x == numTilesPerLine - 1 || y == 0 || y == numTilesPerLine - 1;
			if isWaterTile || isEdgeTile:
				for i in range(0, nswe.size()):
					var neighbourX:int = x + nswe[i].x
					var neighbourY:int = y + nswe[i].y
					var neighbourIsOutOfBounds:bool = neighbourX < 0 || neighbourX >= numTilesPerLine || neighbourY < 0 || neighbourY >= numTilesPerLine;
					var neighbourIsWater:bool = false;
					
					if !neighbourIsOutOfBounds:
						var neighbourHeight = map[neighbourX][neighbourY]
						neighbourIsWater = neighbourHeight <= biomes[0].height
						#if neighbourIsWater:
						#	terrainData.shore[neighbourX][neighbourY] = true
					
					if neighbourIsOutOfBounds || (isLandTile && neighbourIsWater):
						var depth = waterDepth
						if neighbourIsOutOfBounds:
							depth = edgeDepth if (isWaterTile == true) else edgeDepth + waterDepth
						ind = tempVerts.size()
						var edgeVertIndexA = sideVertIndexByDir[i][0];
						var edgeVertIndexB = sideVertIndexByDir[i][1];
						tempVerts.append(tileVertices[edgeVertIndexA])
						tempVerts.append(tileVertices[edgeVertIndexA] + Vector3.DOWN * depth)
						tempVerts.append(tileVertices[edgeVertIndexB])
						tempVerts.append(tileVertices[edgeVertIndexB] + Vector3.DOWN * depth)
						
						tempIndices.append(ind + 0)
						tempIndices.append(ind + 1)
						tempIndices.append(ind + 2)
						tempIndices.append(ind + 2)
						tempIndices.append(ind + 1)
						tempIndices.append(ind + 3)
						
						tempNormals.append(sideNormalsByDir[i])
						tempNormals.append(sideNormalsByDir[i])
						tempNormals.append(sideNormalsByDir[i])
						tempNormals.append(sideNormalsByDir[i])
						
						tempColours.append(color)
						tempColours.append(color)
						tempColours.append(color)
						tempColours.append(color)
						
	# Build the mesh arrays
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tempVerts
	arrays[Mesh.ARRAY_INDEX] = tempIndices
	arrays[Mesh.ARRAY_NORMAL] = tempNormals
	arrays[Mesh.ARRAY_COLOR] = tempColours
	#arrays[Mesh.ARRAY_TEX_UV] = tempUvs

	# Create and assign the mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	material_override = mat

	return map

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
	return uv

func heightmap_to_image(heightmap: Array) -> Image:
	var size_x = heightmap.size()
	var size_y = heightmap[0].size()

	var img := Image.create(size_x, size_y, false, Image.FORMAT_RGB8)

	for x in size_x:
		for y in size_y:
			var v: float = heightmap[x][y]   # 0.0 → 1.0
			var col := Color(v, v, v)
			img.set_pixel(x, y, col)

	return img
