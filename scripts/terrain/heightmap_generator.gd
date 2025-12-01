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

func generate_heightmap(size: int, seed: int) -> Array:
	var heightmap: Array = []
	
	# --- Noise Setup ---
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	if seed == 0:
		noise.seed = randi()  # optional: remove if you want deterministic results
	else:
		noise.seed = seed
		
	noise.frequency = 0.01  # base frequency

	print("seed:", noise.seed)
	
	# --- Fractal Settings (multiple layers) ---
	var octaves := 4               # number of noise layers
	var persistence := 0.49        # amplitude falloff per layer
	var lacunarity := 2.25         # frequency multiplier per layer

	for x in range(size):
		heightmap.append([])
		for z in range(size):

			var amplitude = 1.0
			var frequency = 1.0
			var total = 0.0
			var max_value = 0.0

			# --- Fractal Noise Accumulation ---
			for o in range(octaves):
				var n = noise.get_noise_2d(x * frequency, z * frequency)
				
				# n is between -1 and +1 → shift to 0-1
				n = (n + 1.0) * 0.5

				total += n * amplitude
				max_value += amplitude

				amplitude *= persistence
				frequency *= lacunarity

			# normalize so heights stay 0–1
			var height = total / max_value
			heightmap[x].append(height)

	return heightmap
