package caverace

// active_bomb_count reports occupied bomb slots when enforcing the player's
// current capacity and when building the HUD snapshot.
active_bomb_count :: proc(gameplay: ^Gameplay) -> int {
	count := 0
	for bomb in gameplay.bombs {
		if bomb.active do count += 1
	}
	return count
}

// available_bomb_count derives how many more bombs the player may place from
// their capped capacity and the fixed active slots.
available_bomb_count :: proc(gameplay: ^Gameplay) -> int {
	capacity := clamp(gameplay.player.bomb_capacity, 0, MAX_BOMBS)
	return max(capacity - active_bomb_count(gameplay), 0)
}

// find_free_bomb_slot locates storage for a new bomb after capacity and map
// occupancy checks have succeeded.
find_free_bomb_slot :: proc(gameplay: ^Gameplay) -> (slot: int, ok: bool) {
	for bomb_index in 0 ..< MAX_BOMBS {
		if !gameplay.bombs[bomb_index].active do return bomb_index, true
	}
	return 0, false
}

// try_place_bomb captures the player's current position and power into a fixed
// slot when a Place_Bomb action begins, applying the legacy score cost once.
try_place_bomb :: proc(gameplay: ^Gameplay) -> bool {
	position := gameplay.player.position
	if !is_in_map(position) do return false
	if available_bomb_count(gameplay) == 0 do return false
	if cell_has_bomb(&gameplay.bomb_occupancy, position) do return false

	slot, slot_available := find_free_bomb_slot(gameplay)
	if !slot_available do return false

	gameplay.bombs[slot] = Bomb_State {
		active       = true,
		position     = position,
		fuse_actions = BOMB_FUSE_ACTIONS,
		power        = gameplay.player.bomb_power,
	}
	gameplay.bomb_occupancy[position.x][position.y] = BOMB_TICKING_SPRITE
	apply_score_event(&gameplay.player, .Bomb_Placed)
	return true
}

// clear_bomb_slot releases bomb occupancy and its paired explosion record when
// a fuse finishes or an explosion completes.
clear_bomb_slot :: proc(gameplay: ^Gameplay, bomb_index: int) {
	if bomb_index < 0 || bomb_index >= MAX_BOMBS do return
	bomb := &gameplay.bombs[bomb_index]
	if !bomb.active do return
	if is_in_map(bomb.position) {
		gameplay.bomb_occupancy[bomb.position.x][bomb.position.y] = 0
	}
	bomb^ = {}
	gameplay.explosions[bomb_index] = {}
}

// advance_bomb_fuses decrements every active fuse at an action boundary and
// releases expired slots. Placement runs first, so a new BOMBTIME=12 bomb ends
// its placement action at 11, matching GetPlayerMove -> CheckBombs ordering.
advance_bomb_fuses :: proc(gameplay: ^Gameplay) -> (expired_count: int) {
	for bomb_index in 0 ..< MAX_BOMBS {
		bomb := &gameplay.bombs[bomb_index]
		if !bomb.active do continue
		if bomb.fuse_actions > 0 do bomb.fuse_actions -= 1
		if bomb.fuse_actions == 0 {
			clear_bomb_slot(gameplay, bomb_index)
			expired_count += 1
		}
	}
	return
}
