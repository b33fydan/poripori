class_name VoxelEarth
extends Node3D

# Earth, made of cubes: a shell of ocean cells with the continents raised one
# cell above it, white polar ice, and a sparse shell of cloud cubes that turns
# on its own. The coastlines come from Natural Earth's public-domain land
# polygons (data/earth/land-mask.png; data/earth/SOURCES.md).
#
# Earth space: +Y is the north pole; longitude 0 faces +Z and east is toward
# +X. face_longitude() turns a longitude toward a direction.

const PrintShader := preload("res://shaders/print.gdshader")
const MASK_PATH := "res://data/earth/land-mask.png"
const OCEAN := Color("#2c63a8")
const OCEAN_DEEP := Color("#25579a")
const LAND := Color("#4f9b4c")
const LAND_DARK := Color("#3f8545")
const ICE := Color("#d3dae5")      # soft, not pure white: big white areas blew out
const CLOUD := Color("#cfd6e2")

var radius_cells := 56
var cell := 8.0
var clouds: Node3D
var _mask: Image


func _init(cells := 56, cell_size := 8.0) -> void:
	name = "VoxelEarth"
	radius_cells = cells
	cell = cell_size
	_mask = Image.load_from_file(ProjectSettings.globalize_path(MASK_PATH))
	var ground: Array = []  # [cell, colour]
	var sky: Array = []
	var r := float(radius_cells)
	var reach := radius_cells + 4
	var outer := (r + 3.0) * (r + 3.0)
	var inner := (r - 1.75) * (r - 1.75)
	for x in range(-reach, reach):
		for z in range(-reach, reach):
			var flat := pow(x + 0.5, 2.0) + pow(z + 0.5, 2.0)
			if flat >= outer:
				continue
			# Only the cells in the shell, above and below the equator.
			var top := sqrt(outer - flat)
			var bottom := sqrt(maxf(inner - flat, 0.0))
			var ys: Array = []
			for y in range(maxi(0, int(floor(bottom - 0.5))), int(ceil(top - 0.5)) + 1):
				ys.append(y)
				ys.append(-y - 1)
			for y in ys:
				var p := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var d := p.length()
				if d >= r + 3.0 or d < r - 1.75:
					continue
				var lat := rad_to_deg(asin(clampf(p.y / d, -1.0, 1.0)))
				var lon := rad_to_deg(atan2(p.x, p.z))
				var land := _is_land(lat, lon)
				var ice := absf(lat) > 66.5 or lat < -60.0
				var h := _hash(x, y, z)
				if d < r:
					var color := (LAND if h > 0.5 else LAND_DARK) if land else (OCEAN if h > 0.35 else OCEAN_DEEP)
					if ice and (land or absf(lat) > 74.0):
						color = ICE
					ground.append([Vector3i(x, y, z), color])
				elif d < r + 1.0 and land:
					# Continents stand one cell proud of the sea.
					ground.append([Vector3i(x, y, z), ICE if ice else (LAND if h > 0.4 else LAND_DARK)])
				elif d >= r + 2.0 and _cloudy(p / d) and h > 0.25:
					sky.append([Vector3i(x, y, z), CLOUD])
	add_child(_cubes(ground))
	clouds = Node3D.new()
	clouds.add_child(_cubes(sky))
	add_child(clouds)
	print("[Earth] %d ground cubes, %d cloud cubes, radius %.0f units" % [ground.size(), sky.size(), r * cell])


func _is_land(lat: float, lon: float) -> bool:
	var col := clampi(int(floor(lon + 180.0)), 0, _mask.get_width() - 1)
	var row := clampi(int(floor(90.0 - lat)), 0, _mask.get_height() - 1)
	return _mask.get_pixel(col, row).r > 0.5


static func _hash(x: int, y: int, z: int) -> float:
	var h := (x * 73856093 ^ y * 19349663 ^ z * 83492791) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10000) / 10000.0


# Cloud cover: bands of fractal noise over the sphere, thicker in the
# mid-latitudes, as weather systems are.
func _cloudy(n: Vector3) -> bool:
	var v := 0.0
	var a := 0.5
	var q := n * 3.1
	for i in range(4):
		v += a * (sin(q.x * 1.7 + q.y * 2.3) * sin(q.y * 1.3 - q.z * 2.1) * sin(q.z * 1.9 + q.x * 1.1) * 0.5 + 0.5)
		q = q * 2.07 + Vector3(1.3, 4.7, 2.9)
		a *= 0.5
	var band := 0.55 + 0.25 * cos(deg_to_rad(asin(n.y) * 57.2958 * 3.0 - 135.0))
	return v * band > 0.4


func _cubes(cells: Array) -> MultiMeshInstance3D:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * cell
	var material := ShaderMaterial.new()
	material.shader = PrintShader
	cube.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cube
	mm.instance_count = cells.size()
	for i in range(cells.size()):
		var c: Vector3i = cells[i][0]
		mm.set_instance_transform(i, Transform3D(Basis(), (Vector3(c) + Vector3.ONE * 0.5) * cell))
		var color := (cells[i][1] as Color).srgb_to_linear()
		color.a = 0.0
		mm.set_instance_color(i, color)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func radius() -> float:
	return radius_cells * cell


# Spin so `longitude` (degrees east) faces `direction` (in the parent's
# space, horizontal), plus the clouds' own slow drift.
func face_longitude(longitude: float, direction: Vector3, cloud_turn := 0.0) -> void:
	var facing := atan2(direction.x, direction.z)
	rotation.y = facing - deg_to_rad(longitude)
	clouds.rotation.y = cloud_turn
