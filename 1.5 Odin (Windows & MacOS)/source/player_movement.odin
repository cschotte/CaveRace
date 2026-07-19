package caverace

// direction_delta maps a cardinal direction to its grid offset whenever player
// or enemy movement selects a target cell.
direction_delta :: proc(direction: Direction) -> Grid_Position {
	switch direction {
	case .Down:  return {0, 1}
	case .Up:    return {0, -1}
	case .Right: return {1, 0}
	case .Left:  return {-1, 0}
	case .None:  return {}
	}
	return {}
}

// action_direction converts only movement actions to directions; non-movement
// actions keep the player idle for the current action interval.
action_direction :: proc(action: Gameplay_Action) -> Direction {
	switch action {
	case .Move_Down:  return .Down
	case .Move_Up:    return .Up
	case .Move_Right: return .Right
	case .Move_Left:  return .Left
	case .None, .Place_Bomb: return .None
	}
	return .None
}

// screen_to_grid_position maps an interpolated pixel origin back to a valid map
// cell for explosion collision checks.
screen_to_grid_position :: proc(screen_x, screen_y: i32) -> (
	position: Grid_Position,
	ok: bool,
) {
	relative_x := int(screen_x) - MAP_OFFSET_X
	relative_y := int(screen_y) - MAP_OFFSET_Y
	if relative_x < 0 || relative_y < 0 do return {}, false

	position = {
		relative_x / MAP_TILE_SIZE,
		relative_y / MAP_TILE_SIZE,
	}
	return position, is_in_map(position)
}

// cell_has_bomb safely queries the separate occupancy grid used by movement
// rules without indexing an out-of-bounds position.
cell_has_bomb :: proc(occupancy: ^Map_Grid, position: Grid_Position) -> bool {
	return is_in_map(position) && occupancy[position.x][position.y] != 0
}

// is_walkable applies map bounds, terrain, item, and bomb rules before either a
// player or enemy begins moving to a neighboring cell.
is_walkable :: proc(
	data: ^Map_Data,
	bomb_occupancy: ^Map_Grid,
	position: Grid_Position,
) -> bool {
	if !is_in_map(position) do return false
	if data.background[position.x][position.y] >= WALKABLE_TERRAIN_LIMIT do return false
	if data.item[position.x][position.y] > PASSABLE_ITEM_LIMIT do return false
	return !cell_has_bomb(bomb_occupancy, position)
}

// begin_player_action captures the player's interpolation endpoints at an
// action boundary, leaving the target unchanged when movement is blocked.
begin_player_action :: proc(gameplay: ^Gameplay, action: Gameplay_Action) {
	player := &gameplay.player
	player.move_from = player.position
	player.move_to = player.position
	player.movement_step = 0
	player.direction = action_direction(action)

	if player.direction == .None do return
	delta := direction_delta(player.direction)
	target := Grid_Position {
		player.position.x + delta.x,
		player.position.y + delta.y,
	}
	if is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
		player.move_to = target
	}
}

// advance_player_action_step updates interpolation progress for the current
// action and commits the target grid cell on its final step.
advance_player_action_step :: proc(player: ^Player_State, completed_steps: int) {
	player.movement_step = clamp(completed_steps, 0, MOVEMENT_STEPS_PER_TILE)
	if player.movement_step == MOVEMENT_STEPS_PER_TILE {
		player.position = player.move_to
	}
}

// movement_screen_position interpolates between two grid cells for actor
// rendering and pixel-precise collision checks during movement.
movement_screen_position :: proc(
	move_from, move_to: Grid_Position,
	movement_step: int,
) -> (x, y: i32) {
	x, y = grid_position_to_screen(move_from)
	delta_x := move_to.x - move_from.x
	delta_y := move_to.y - move_from.y
	x += i32(delta_x * movement_step * MOVEMENT_PIXELS_PER_STEP)
	y += i32(delta_y * movement_step * MOVEMENT_PIXELS_PER_STEP)
	return
}

// player_screen_position exposes the player's current interpolated position to
// rendering and enemy/explosion collision rules.
player_screen_position :: proc(player: ^Player_State) -> (x, y: i32) {
	return movement_screen_position(
		player.move_from,
		player.move_to,
		player.movement_step,
	)
}

// player_sprite_index selects the direction-specific legacy animation row from
// the player's movement progress during rendering.
player_sprite_index :: proc(player: ^Player_State) -> u8 {
	if player.direction == .None do return PLAYER_IDLE_SPRITE

	animation_step := max(player.movement_step - 1, 0)
	switch player.direction {
	case .Down:
		return u8(PLAYER_DOWN_FIRST_SPRITE +
			(animation_step / 2) % PLAYER_DIRECTION_FRAME_COUNT)
	case .Up:
		return u8(PLAYER_UP_FIRST_SPRITE +
			(animation_step / 2) % PLAYER_DIRECTION_FRAME_COUNT)
	case .Left:
		return u8(PLAYER_LEFT_FIRST_SPRITE +
			(animation_step / 4) % PLAYER_DIRECTION_FRAME_COUNT)
	case .Right:
		return u8(PLAYER_RIGHT_FIRST_SPRITE +
			(animation_step / 4) % PLAYER_DIRECTION_FRAME_COUNT)
	case .None:
		return PLAYER_IDLE_SPRITE
	}
	return PLAYER_IDLE_SPRITE
}
