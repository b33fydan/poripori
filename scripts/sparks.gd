class_name Sparks
extends Node3D

# Sparks thrown from one point at one moment (the touch): thin bright
# streaks that fly out fast, drawn out along their way, slow down and burn
# out. Like the star trail, every spark's path comes only from its index and
# song time, so any frame can be rendered on its own.

const PrintShader := preload("res://shaders/print.gdshader")
const COLORS := [Color("#fff6d8"), Color("#ffe08a"), Color("#ffb86b"), Color("#ffd36b"), Color("#ffffff")]
const MAX := 120
const DRAG := 4.0

var _bursts: Array = []  # [time, origin, count, speed, life]
var multimesh: MultiMesh


func _init() -> void:
	name = "Sparks"
	var streak := BoxMesh.new()
	streak.size = Vector3(0.022, 0.022, 1.0)  # along +Z, stretched per spark
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	streak.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = streak
	multimesh.instance_count = MAX
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func burst(time: float, origin: Vector3, count := 70, speed := 3.2, life := 0.8) -> void:
	_bursts.append([time, origin, count, speed, life])


static func _hash(k: int, salt: int) -> float:
	var h := (k * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


# How far a spark launched at `speed` has gone after `age` seconds of drag.
static func _travel(speed: float, age: float) -> float:
	return speed * (1.0 - exp(-age * DRAG)) / DRAG


func update(t: float) -> void:
	var slot := 0
	for b in _bursts:
		var age := t - float(b[0])
		var count: int = b[2]
		for i in range(count):
			if slot >= MAX:
				break
			var life: float = float(b[4]) * (0.5 + 0.7 * _hash(i, 21))
			if age < 0.0 or age > life:
				continue
			var dir := Vector3(_hash(i, 22) - 0.5, _hash(i, 23) - 0.5, _hash(i, 24) - 0.5).normalized()
			var speed: float = float(b[3]) * (0.45 + 0.9 * _hash(i, 25))
			var head := _travel(speed, age)
			# The streak runs from where the spark was a moment ago to where
			# it is: long while fast, a dot as it slows.
			var tail := _travel(speed, maxf(age - 0.06, 0.0))
			var length := maxf(head - tail, 0.015)
			var fade := pow(1.0 - age / life, 0.6)
			var middle: Vector3 = (b[1] as Vector3) + dir * (head + tail) * 0.5
			var basis := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
			basis = basis * Basis.from_scale(Vector3(fade, fade, length))
			multimesh.set_instance_transform(slot, Transform3D(basis, middle))
			var color := (COLORS[i % COLORS.size()] as Color).srgb_to_linear()
			color.a = 1.0
			multimesh.set_instance_color(slot, color)
			slot += 1
	for i in range(slot, MAX):
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
