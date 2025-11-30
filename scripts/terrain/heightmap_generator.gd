class_name HeightMapGenerator

func _generateHeightmap(size:int, normalize:bool = true):
	var grid: Array = []
	for x in range(size):
		var row := []
		for y in range(size):
			var r = randf_range(0.0, 1.0)
			row.append(r)
		grid.append(row)

	return grid
