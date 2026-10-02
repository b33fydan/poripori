class_name CubeTrail
extends Node3D

# The trail of coloured cubes behind the board. Cube k leaves the board's
# tail at time k / RATE, from wherever the board was then, and drifts, spins
# and shrinks away over LIFE seconds. Its place, colour and spin come only
# from k and song time, so any frame can be re-rendered exactly.
#
# The shot supplies two functions of time: where the rig is, and how lit the
# trail is (0 a faint silver wisp, 1 the full rainbow), plus a beat pulse.

const VoxelShader := preload("res://shaders/voxel.gdshader")
const RATE := 80.0
const LIFE := 2.4
const SIZE := 0.09
# How much of the board's own speed a cube keeps as it leaves, so the trail
# stays near the board where the camera can see it.
const INHERIT := 0.62

var rig_at: Callable      # func(t) -> Transform3D
var energy_at: Callable   # func(t) -> float, 0..1
var pulse_at: Callable    # func(t) -> float, 0..1 on the beat
var tail_point := Vector3.ZERO
var multimesh: MultiMesh
var light: OmniLight3D


func _init(rig: Callable, energy: Callable, pulse: Callable, tail: Vector3) -> void:
	name = "CubeTrail"
	rig_at = rig
	energy_at = energy
	pulse_at = pulse
	tail_point = tail
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * SIZE
	var material := ShaderMaterial.new()
	material.shader = VoxelShader
	material.set_shader_parameter("glow_energy", 1.0)
	material.set_shader_parameter("unshaded_mix", 0.35)
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
	# The trail's colour spills a little light back onto the board and rider.
	light = OmniLight3D.new()
	light.omni_range = 2.6
	light.shadow_enabled = false
	add_child(light)


static func _hash(k: int, salt: int) -> float:
	var h := (k * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 100000) / 100000.0


func update(t: float) -> void:
	var first := int(ceil((t - LIFE) * RATE))
	var last := int(floor(t * RATE))
	var slot := 0
	for k in range(first, last + 1):
		var born := k / RATE
		var age := t - born
		if age < 0.0 or age > LIFE or slot >= multimesh.instance_count:
			continue
		var energy: float = energy_at.call(born)
		var pulse: float = pulse_at.call(born)
		var xf: Transform3D = rig_at.call(born)
		var a := _hash(k, 1)
		var b := _hash(k, 2)
		var c := _hash(k, 3)
		var life := age / LIFE
		# Out of the tail, scattered a little across the board's width.
		var local := tail_point + Vector3(0.0, (b - 0.5) * 0.08, (a - 0.5) * 0.28 * (0.4 + energy))
		var start := xf * local
		# Drift: backward from the board and outward, slowing as it goes.
		var back := -xf.basis.x.normalized()
		var spread := xf.basis.z.normalized() * (a - 0.5) + xf.basis.y.normalized() * (b - 0.5)
		var travel := (1.0 - pow(1.0 - minf(life * 1.4, 1.0), 2.0))
		var drift := back * (0.6 + 0.6 * energy) * travel + spread * (0.5 + 1.1 * energy) * travel
		var velocity: Vector3 = (rig_at.call(born + 0.02).origin - rig_at.call(born - 0.02).origin) / 0.04
		var carried := velocity * INHERIT * LIFE * 0.5 * (1.0 - pow(1.0 - life, 2.0))
		var position := start + drift + carried
		var size := (0.45 + 0.75 * energy + 0.9 * pulse * energy) * pow(1.0 - life, 0.8) * (0.6 + 0.8 * c)
		var spin := Basis(Vector3(a - 0.5, b - 0.5, c - 0.5).normalized(), age * (3.0 + 5.0 * c))
		multimesh.set_instance_transform(slot, Transform3D(spin.scaled(Vector3.ONE * size), position))
		multimesh.set_instance_color(slot, _color(born, a, energy, pulse, life))
		slot += 1
	for i in range(slot, multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	var now: float = energy_at.call(t)
	light.position = rig_at.call(t) * (tail_point + Vector3(0.6, 0.25, 0.0))
	light.light_color = Color.from_hsv(fposmod(t * 0.18, 1.0), 0.55, 1.0)
	light.light_energy = 0.15 + 1.6 * now


# Each cube's colour follows where it left across the board's width, so the
# trail streams back as rainbow bands, which turn slowly with time.
func _color(born: float, a: float, energy: float, pulse: float, life: float) -> Color:
	var hue := fposmod(a * 0.82 + born * 0.08, 1.0)
	var rainbow := Color.from_hsv(hue, 0.62, 1.0)
	var silver := Color(0.72, 0.82, 1.0)
	var color := silver.lerp(rainbow, energy).srgb_to_linear()
	color.a = (0.35 + 1.3 * energy + 1.5 * pulse * energy) * (1.0 - life * 0.6)
	return color
