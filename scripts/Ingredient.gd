class_name Ingredient
extends RefCounted

enum Type { YELLOW, ORANGE, BLUE,
			GRIND_YELLOW, GRIND_ORANGE, GRIND_BLUE,
			COOK_YELLOW, COOK_ORANGE, COOK_BLUE,
			SUN_TEA, MINT_SODA, EARTH_BREW, SUS_CONCOC,
			TRASH}

const COLORS := {
	Type.YELLOW: Color(1, 1, 0),
	Type.ORANGE: Color(1, 0.54901963, 0, 1),
	Type.BLUE: Color(0.5294118, 0.80784315, 0.92156863, 1),
}

const SIDES := {
	Type.YELLOW: 3,
	Type.ORANGE: 4,
	Type.BLUE: 5,
}

const ANGLE_OFFSET := {
	Type.YELLOW: 0.0,
	Type.ORANGE: PI / 4.0,
	Type.BLUE: 0.0,
}


static func polygon_points(type: Type, radius: float) -> PackedVector2Array:
	return _regular_polygon(radius, 3, 0.0)


static func _regular_polygon(radius: float, sides: int, angle_offset: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var angle: float = TAU * i / sides - PI / 2.0 + angle_offset
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
