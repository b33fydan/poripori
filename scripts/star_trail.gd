class_name StarTrail
extends Node3D

# Little stars the mascot leaves as it flies: each a tiny three-armed cross
# of light, born at k / RATE from wherever the mascot was then, drifting,
# twinkling and shrinking away over LIFE seconds. burst() adds a ring of
# stars thrown out from one point at one moment (the touch). Like the spray,
# every star's place comes only from its index and song time.

const PrintShader := preload("res://shaders/print.gdshader")
const RATE := 28.0
const LIFE := 1.5
const COLORS := [Color("#ffe08a"), Color("#fff6d8"), Color("#ffb86b"), Color("#ffd36b")]
const MAX := 160

var source_at: Callable  # func(t) -> Vector3, where stars are born
var active_at: Callable  # func(t) -> 0..1, how many are born
var _bursts: Array = []  # [time, origin, count, speed]
var multimesh: MultiMesh


func _init(source: Callable, active: Callable) -> void:
	name = "StarTrail"
	source_at = source
	active_at = active
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for size in [Vector3(0.2, 0.045, 0.045), Vector3(0.045, 0.2, 0.045), Vector3(0.045, 0.045, 0.2)]:
		var arm := BoxMesh.new()
		arm.size = size
		tool.append_from(arm, 0, Transform3D.IDENTITY)
	var mesh := tool.commit()
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	mesh.surface_set_material(0, material)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = MAX
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func burst(time: float, origin: Vector3, count := 36, speed := 1.6) -> void:
	_bursts.append([time, origin, count, speed])


static func _hash(k: int, salt: int) -> float:
	var h := (k * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


func _place(slot: int, position: Vector3, k: int, age: float, life_span: float) -> void:
	var life := age / life_span
	var twinkle := 0.75 + 0.25 * sin(age * 18.0 + k)
	var size := (0.6 + 0.8 * _hash(k, 3)) * twinkle * pow(maxf(1.0 - life, 0.0), 0.7)
	var spin := Basis(Vector3(_hash(k, 4) - 0.5, 1.0, _hash(k, 5) - 0.5).normalized(), age * 2.0 + k)
	multimesh.set_instance_transform(slot, Transform3D(spin.scaled(Vector3.ONE * size), position))
	var color := (COLORS[k % COLORS.size()] as Color).srgb_to_linear()
	color.a = 1.0  # stars print flat and bright
	multimesh.set_instance_color(slot, color)


func update(t: float) -> void:
	var slot := 0
	var first := int(ceil((t - LIFE) * RATE))
	var last := int(floor(t * RATE))
	for k in range(first, last + 1):
		var born := k / RATE
		var age := t - born
		if age < 0.0 or age > LIFE or slot >= MAX:
			continue
		if _hash(k, 1) > float(active_at.call(born)):
			continue
		var start: Vector3 = source_at.call(born)
		var drift := Vector3(_hash(k, 6) - 0.5, _hash(k, 7) - 0.3, _hash(k, 8) - 0.5) * 0.5 * age
		var jitter := Vector3(_hash(k, 9) - 0.5, _hash(k, 10) - 0.5, _hash(k, 11) - 0.5) * 0.18
		_place(slot, start + jitter + drift, k, age, LIFE)
		slot += 1
	for b in _bursts:
		var time: float = b[0]
		var age := t - time
		if age < 0.0 or age > LIFE * 1.4:
			continue
		var count: int = b[2]
		for i in range(count):
			if slot >= MAX:
				break
			var k := 100000 + i
			var dir := Vector3(_hash(k, 12) - 0.5, _hash(k, 13) - 0.5, _hash(k, 14) - 0.5).normalized()
			var travel := float(b[3]) * (1.0 - exp(-age * 3.0)) / 3.0 * (0.6 + 0.8 * _hash(k, 15))
			_place(slot, (b[1] as Vector3) + dir * travel * 1.6, k, age, LIFE * 1.4)
			slot += 1
	for i in range(slot, MAX):
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
