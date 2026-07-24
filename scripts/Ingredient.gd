class_name Ingredient
extends RefCounted

enum Type { YELLOW, ORANGE, BLUE,
			GRIND_YELLOW, GRIND_ORANGE, GRIND_BLUE,
			COOK_YELLOW, COOK_ORANGE, COOK_BLUE,
			SUN_TEA, MINT_SODA, EARTH_BREW, SUS_CONCOC,
			TRASH}

const SPRITE_PATHS := {
	Type.YELLOW: "res://sprites/yellow.png",
	Type.ORANGE: "res://sprites/orange.png",
	Type.BLUE: "res://sprites/blue.png",
	Type.GRIND_YELLOW: "res://sprites/grind_yellow.png",
	Type.GRIND_ORANGE: "res://sprites/grind_orange.png",
	Type.GRIND_BLUE: "res://sprites/grind_blue.png",
	Type.COOK_YELLOW: "res://sprites/cook_yellow.png",
	Type.COOK_ORANGE: "res://sprites/cook_orange.png",
	Type.COOK_BLUE: "res://sprites/cook_blue.png",
	Type.SUN_TEA: "res://sprites/sun_tea.png",
	Type.MINT_SODA: "res://sprites/mint_soda.png",
	Type.EARTH_BREW: "res://sprites/earth_brew.png",
	Type.SUS_CONCOC: "res://sprites/sus_concoc.png",
	Type.TRASH: "res://sprites/trash.png",
}


static func sprite_texture(type: Type) -> Texture2D:
	return load(SPRITE_PATHS[type])
