extends Node

# Solid layers
const WORLD   := 1 << 0
const PLAYER  := 1 << 1
const NPC     := 1 << 2
const HITBOX  := 1 << 3
const SOLID_NO_NAV := 1 << 5

# Non-solid layers
const TRIGGER := 1 << 4

# Ease-of-use layers
## Anything that CAN be hit.
const SOLID := WORLD | PLAYER | NPC | HITBOX | SOLID_NO_NAV

## Anything that an attack the player initiates can hit
const SOLID_FOR_PLAYER := WORLD | HITBOX | SOLID_NO_NAV

## Anything that an attack an NPC initiates can hit
const SOLID_FOR_NPC := WORLD | SOLID_NO_NAV

func is_body_on_tracemask(body: Node3D, layer: int):
	if body is CollisionObject3D:
		return (body.collision_layer & layer) == layer
	return false
