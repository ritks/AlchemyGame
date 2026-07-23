class_name Ingredient
extends RefCounted

enum Type { TRIANGLE, SQUARE, PENTAGON }

const COLORS := {
	Type.TRIANGLE: Color(0.85, 0.25, 0.25),
	Type.SQUARE: Color(0.25, 0.45, 0.85),
	Type.PENTAGON: Color(0.3, 0.75, 0.35),
}

const SIDES := {
	Type.TRIANGLE: 3,
	Type.SQUARE: 4,
	Type.PENTAGON: 5,
}

const ANGLE_OFFSET := {
	Type.TRIANGLE: 0.0,
	Type.SQUARE: PI / 4.0,
	Type.PENTAGON: 0.0,
}


static func polygon_points(type: Type, radius: float) -> PackedVector2Array:
	return _regular_polygon(radius, SIDES[type], ANGLE_OFFSET[type])


static func _regular_polygon(radius: float, sides: int, angle_offset: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var angle: float = TAU * i / sides - PI / 2.0 + angle_offset
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
