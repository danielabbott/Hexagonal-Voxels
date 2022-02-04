# I was thinking these tesselated hexagon prisms could make an interesting map
# for a shooter game or a voxel sandbox

extends Node3D

# Chunk size is  55.425625856 x 64 x 48

const CHUNK_SIZE_X = 64;
const CHUNK_SIZE_Y = 128;
const CHUNK_SIZE_Z = 64;

@export var chunk_coord_x: int = 0
@export var chunk_coord_z: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():	
	var voxel_chunk_data = createChunk()
	assert(voxel_chunk_data.size() == CHUNK_SIZE_X*CHUNK_SIZE_Y*CHUNK_SIZE_Z)
	
	var arr_mesh = createMesh(voxel_chunk_data)
	
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.set_surface_override_material(0, get_parent().material)
	add_child(m)
	
#	ResourceSaver.save("res://mesh-" + str(chunk_coord_x) + "-" + str(chunk_coord_z) + ".tres", \
#		arr_mesh, 32)

func createChunk():
	var voxel_chunk_data = PackedColorArray()
	
	var noise = OpenSimplexNoise.new()
	noise.seed = get_parent().world_seed
	noise.octaves = 4
	noise.period = 50.0
	noise.persistence = 1.0
	
	var heightmap = noise.get_image(CHUNK_SIZE_Z, CHUNK_SIZE_X, \
		Vector2(chunk_coord_z*CHUNK_SIZE_Z, chunk_coord_x*CHUNK_SIZE_X))
	
	noise = OpenSimplexNoise.new()
	noise.seed = get_parent().world_seed
	noise.octaves = 1
	noise.period = 10.0
	noise.persistence = 0.2
	
	var colour_map = noise.get_image(CHUNK_SIZE_Z, CHUNK_SIZE_X, \
		Vector2(chunk_coord_z*CHUNK_SIZE_Z, chunk_coord_x*CHUNK_SIZE_X))
	
	
	# water
	for z in range(0, CHUNK_SIZE_Z):
		for x in range(0, CHUNK_SIZE_X):
			var a = colour_map.get_pixel(z,x).r * 0.3 - 0.2
			voxel_chunk_data.push_back(Color(0.5+a*1.5, 0.5+a*1.5, 0.8+a, 1.0))
	
	# Grass / sand / air
	for y in range(11):
		for z in range(0, CHUNK_SIZE_Z):
			for x in range(0, CHUNK_SIZE_X):
				var h = heightmap.get_pixel(z,x).r * 30 - 12
				if h >= y:
					if y == 0: 
						var a = colour_map.get_pixel(z,x).r * 0.4 - 0.3
						voxel_chunk_data.push_back(Color(1.0+a*1.2, 0.9+a, 0.7+a, 1.0))
					else: 
						var a = colour_map.get_pixel(z,x).r * 0.3 - 0.2
						voxel_chunk_data.push_back(Color(0.3+a, 0.8+a, 0.3+a*1.3, 1.0))
				else:
					voxel_chunk_data.push_back(Color(0.0, 0.0, 0.0, 0.0))
				
	
	for y in range(12, CHUNK_SIZE_Y):
		for i in range(CHUNK_SIZE_X*CHUNK_SIZE_Z):
			voxel_chunk_data.push_back(Color(0.0, 0.0, 0.0, 0.0))
	
	return voxel_chunk_data

func coord(x: int, y: int, z: int):
	assert(x >= 0 and x < CHUNK_SIZE_X);
	assert(y >= 0 and y < CHUNK_SIZE_Y);
	assert(z >= 0 and z < CHUNK_SIZE_Z);
	return y*CHUNK_SIZE_X*CHUNK_SIZE_Z + z*CHUNK_SIZE_X + x

# This could be rewritten in C(++) or Zig
func createMesh(voxel_chunk_data: PackedColorArray):	
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var colours = PackedColorArray()
	var indices = PackedInt32Array()
	
	for voxel_y_idx in range(CHUNK_SIZE_Y):
		var voxel_y = voxel_y_idx * 0.5
					
		for voxel_z_idx in range(CHUNK_SIZE_Z):
			var voxel_z = voxel_z_idx * 0.75
			
			var voxel_x_offset = 0
			
			if voxel_z_idx % 2 != 0: voxel_x_offset = 0.433012702
				
			for voxel_x_idx in range(CHUNK_SIZE_X):	
				var colour = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx, voxel_z_idx)]	
					
				if colour.a != 0.0:
					var idx_off = vertices.size()
					
					var voxel_to_neg_x = false
					var voxel_to_pos_x = false
					var voxel_to_neg_y = true
					var voxel_to_pos_y = false
					var voxel_to_neg_z_left = false
					var voxel_to_pos_z_left = false
					var voxel_to_neg_z_right = false
					var voxel_to_pos_z_right = false
					
					if voxel_x_idx > 0: 
						voxel_to_neg_x = voxel_chunk_data[coord(voxel_x_idx-1, voxel_y_idx, voxel_z_idx)].a != 0	
					if voxel_x_idx < 63:
						voxel_to_pos_x = voxel_chunk_data[coord(voxel_x_idx+1, voxel_y_idx, voxel_z_idx)].a != 0	
					
					if voxel_y_idx > 0: 
						voxel_to_neg_y = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx-1, voxel_z_idx)].a != 0	
					if voxel_y_idx < 63: 
						voxel_to_pos_y = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx+1, voxel_z_idx)].a != 0	
										
					
					if voxel_z_idx % 2 == 0:
						if voxel_z_idx > 0: 
							if voxel_x_idx > 0: 
								voxel_to_neg_z_left = voxel_chunk_data[coord(voxel_x_idx-1, voxel_y_idx, voxel_z_idx-1)].a != 0	
							voxel_to_neg_z_right = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx, voxel_z_idx-1)].a != 0
						if voxel_z_idx < 63: 
							if voxel_x_idx > 0: 
								voxel_to_pos_z_left = voxel_chunk_data[coord(voxel_x_idx-1, voxel_y_idx, voxel_z_idx+1)].a != 0	
							voxel_to_pos_z_right = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx, voxel_z_idx+1)].a != 0
					else:
						if voxel_z_idx > 0: 
							voxel_to_neg_z_left = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx, voxel_z_idx-1)].a != 0	
							if voxel_x_idx < 63: voxel_to_neg_z_right = voxel_chunk_data[coord(voxel_x_idx+1, voxel_y_idx, voxel_z_idx-1)].a != 0
						if voxel_z_idx < 63: 
							voxel_to_pos_z_left = voxel_chunk_data[coord(voxel_x_idx, voxel_y_idx, voxel_z_idx+1)].a != 0	
							if voxel_x_idx < 63: voxel_to_pos_z_right = voxel_chunk_data[coord(voxel_x_idx+1, voxel_y_idx, voxel_z_idx+1)].a != 0	
					
					
					if voxel_to_neg_x and voxel_to_pos_x and voxel_to_neg_y and voxel_to_pos_y and voxel_to_neg_z_left \
							and voxel_to_pos_z_left and voxel_to_neg_z_right and voxel_to_pos_z_right:
						continue
					
					var voxel_x = voxel_x_offset + voxel_x_idx * 0.433012702 * 2.0
					
					# Bottom, top	
					# TODO don't add bottom vertices if bottom face and all sides are culled. same for top face.	
					for i in range(2):
						var y = voxel_y
						if i == 1: y += 0.5
						vertices.push_back(Vector3(voxel_x + 0, y, 				voxel_z + 0.5))
						vertices.push_back(Vector3(voxel_x + 0.433012702, y, 	voxel_z + 0.25))
						vertices.push_back(Vector3(voxel_x + 0.433012702, y, 	voxel_z - 0.25))
						vertices.push_back(Vector3(voxel_x + 0, y, 				voxel_z - 0.5))	
						vertices.push_back(Vector3(voxel_x + -0.433012702, y, 	voxel_z - 0.25))
						vertices.push_back(Vector3(voxel_x + -0.433012702, y, 	voxel_z + 0.25))
						
						for j in range(6):
							colours.push_back(colour)
					
					# Top Face (hexagon)
					if not voxel_to_pos_y:
						indices.push_back(idx_off + 6+5)
						indices.push_back(idx_off + 6+1)
						indices.push_back(idx_off + 6+0)
						indices.push_back(idx_off + 6+5)
						indices.push_back(idx_off + 6+4)
						indices.push_back(idx_off + 6+1)
						indices.push_back(idx_off + 6+4)
						indices.push_back(idx_off + 6+2)
						indices.push_back(idx_off + 6+1)
						indices.push_back(idx_off + 6+4)
						indices.push_back(idx_off + 6+3)
						indices.push_back(idx_off + 6+2)
					
					# Bottom Face (hexagon)
					if not voxel_to_neg_y:
						indices.push_back(idx_off + 0)
						indices.push_back(idx_off + 1)
						indices.push_back(idx_off + 5)
						indices.push_back(idx_off + 1)
						indices.push_back(idx_off + 4)
						indices.push_back(idx_off + 5)
						indices.push_back(idx_off + 1)
						indices.push_back(idx_off + 2)
						indices.push_back(idx_off + 4)
						indices.push_back(idx_off + 2)
						indices.push_back(idx_off + 3)
						indices.push_back(idx_off + 4)
					
					# Sides (rectangles)
					for i in range(0, 6):			
						if i == 0 and voxel_to_pos_z_right: continue
						if i == 1 and voxel_to_pos_x: continue
						if i == 2 and voxel_to_neg_z_right: continue
						if i == 3 and voxel_to_neg_z_left: continue
						if i == 4 and voxel_to_neg_x: continue			
						if i == 5 and voxel_to_pos_z_left: continue
						
						var j = (i+1) % 6
						indices.push_back(idx_off + 6+j)		
						indices.push_back(idx_off + j)
						indices.push_back(idx_off + i)
						
						indices.push_back(idx_off + i)
						indices.push_back(idx_off + 6+i)
						indices.push_back(idx_off + 6+j)
					
			
	
	
	arr[Mesh.ARRAY_VERTEX] = vertices
	arr[Mesh.ARRAY_COLOR] = colours
	arr[Mesh.ARRAY_INDEX] = indices
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return arr_mesh

