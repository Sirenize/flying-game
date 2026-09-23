extends RigidBody3D

const LIFESPAN = 50
var tick = 0

func _enter_tree() -> void:
	apply_impulse(Vector3.ONE * 1000)

func _process(delta: float) -> void:
	if tick != LIFESPAN:
		tick += 1
	else:
		queue_free()
