class_name CubeTrail
extends Node3D

# A rainbow trail of little cubes behind a board flying free of the ring:
# cubes born at k / RATE wherever the board's tail was then, each in the
# next colour of the rainbow, tumbling and shrinking away over LIFE seconds.
# Like the star trail, each cube's place comes only from its index and song
# time.

const PrintShader := preload("res://shaders/print.gdshader")

var source_at: Callable   # func(t) -> Vector3, the board's tail
var active_at: Callable   # func(t) -> 0..1
var rate := 30.0
var life := 1.1
var size := 0.12
var multimesh: MultiMesh
var _max := 0


func _init(source: Callable, active: Callable, cube_size := 0.12, cubes_per_second := 30.0, lifetime := 1.1) -> void:
	name = "CubeTrail"
	source_at = source
	active_at = active
	size = cube_size
	rate = cubes_per_second
	life = lifetime
	_max = int(ceil(rate * life)) + 2
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * size
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = cube
	multimesh.instance_count = _max
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


static func _hash(k: int, salt: int) -> float:
	var h := (k * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


func update(t: float) -> void:
	var slot := 0
	var first := int(ceil((t - life) * rate))
	var last := int(floor(t * rate))
	for k in range(first, last + 1):
		if slot >= _max:
			break
		var born := k / rate
		var age := t - born
		if age < 0.0 or age > life or _hash(k, 1) > float(active_at.call(born)):
			continue
		var start: Vector3 = source_at.call(born)
		var drift := Vector3(_hash(k, 2) - 0.5, _hash(k, 3) - 0.5, _hash(k, 4) - 0.5) * 0.6 * age
		var fade := pow(1.0 - age / life, 0.8)
		var spin := Basis(Vector3(_hash(k, 5) - 0.5, 1.0, _hash(k, 6) - 0.5).normalized(), age * 4.0 + k)
		multimesh.set_instance_transform(slot, Transform3D(spin.scaled(Vector3.ONE * fade), start + drift))
		# The rainbow at the film's toned value, so it doesn't blow out.
		var color := Color.from_hsv(fposmod(k * 0.07, 1.0), 0.6, 0.84).srgb_to_linear()
		color.a = 1.0
		multimesh.set_instance_color(slot, color)
		slot += 1
	for i in range(slot, _max):
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
