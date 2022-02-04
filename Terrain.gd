extends Node3D

@export var speed = 1.0
@export var material: ShaderMaterial
@export var world_seed: int = 0

var r = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	r += delta * speed
	rotation = Vector3(0, r, 0)
	
	if world_seed == 0:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		world_seed = rng.randi()
