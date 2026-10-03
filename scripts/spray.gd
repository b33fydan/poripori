class_name Spray
extends Node3D

# Cubes kicked up behind the board, like the snow puffs in the reference:
# they leave the board's tail, arc up and back, fall, and settle on the
# ring as they shrink away. Cube k is born at k / RATE from wherever the
# board was then; its path comes only from k and song time, so any frame
# re-renders exactly. Most are the night's ink; some take the trail's
# rainbow.

const PrintShader := preload("res://shaders/print.gdshader")
const RATE := 45.0
const LIFE := 1.3
const GRAVITY := 9.0

var rig_at: Callable     # func(t) -> Transform3D of the rig
var amount_at: Callable  # func(t) -> 0..1, how hard the board is spraying
var ink_at: Callable     # func(t) -> Color, the current ink
var height_at: Callable  # func(t) -> the ring's height; cubes ride with it as it descends
var tail_point := Vector3.ZERO
var up := Vector3.UP     # the ring's normal: cubes fall back toward it
var multimesh: MultiMesh


func _init(rig: Callable, amount: Callable, ink: Callable, height: Callable, tail: Vector3, ring_up: Vector3) -> void:
	name = "Spray"
	rig_at = rig
	amount_at = amount
	ink_at = ink
	height_at = height
	tail_point = tail
	up = ring_up.normalized()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.16
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = cube
	multimesh.instance_count = int(ceil(RATE * LIFE)) + 2
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


static func _hash(k: int, salt: int) -> float:
	var h := (k * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


func update(t: float) -> void:
	var first := int(ceil((t - LIFE) * RATE))
	var last := int(floor(t * RATE))
	var slot := 0
	# A step darker than the ink: near the lens, light cubes blew out.
	var ink: Color = (ink_at.call(t) as Color).darkened(0.18)
	var ring_now: float = height_at.call(t)
	for k in range(first, last + 1):
		var born := k / RATE
		var age := t - born
		if age < 0.0 or age > LIFE or slot >= multimesh.instance_count:
			continue
		var amount: float = amount_at.call(born)
		# Fewer cubes when the board is gliding: each one's own coin toss.
		if _hash(k, 4) > 0.2 + 0.8 * amount:
			continue
		var xf: Transform3D = rig_at.call(born)
		var a := _hash(k, 1)
		var b := _hash(k, 2)
		var c := _hash(k, 3)
		var across := (a - 0.5) * 2.0
		# Worked in the ring's frame (its height at birth taken off), then put
		# back at the ring's height now.
		var start := xf * (tail_point + Vector3(0.0, 0.05, across * 0.2)) - up * float(height_at.call(born))
		var back := -xf.basis.x.normalized()
		var side := xf.basis.z.normalized()
		var velocity := up * (1.2 + 2.2 * b) * (0.5 + 0.5 * amount) + back * (0.6 + 1.2 * c) + side * across * 1.2
		var p := start + velocity * age - up * (0.5 * GRAVITY * age * age)
		# Landed cubes rest on the ring.
		var height := (p - start).dot(up)
		if height < 0.0:
			p -= up * height
		p += up * ring_now
		var life := age / LIFE
		var size := (0.55 + 0.75 * c) * (0.6 + 0.4 * amount) * (1.0 - smoothstep(0.6, 1.0, life))
		var spin := Basis(Vector3(a - 0.5, b - 0.5, c - 0.5).normalized(), age * (2.0 + 6.0 * c))
		multimesh.set_instance_transform(slot, Transform3D(spin.scaled(Vector3.ONE * size), p))
		var color := ink
		if _hash(k, 5) < 0.35 * amount:
			color = Color.from_hsv(fposmod(born * 0.16 + across * 0.12, 1.0), 0.6, 0.84)
		var linear := color.srgb_to_linear()
		linear.a = 0.0
		multimesh.set_instance_color(slot, linear)
		slot += 1
	for i in range(slot, multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
