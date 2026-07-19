package caverace

active_bomb_count :: proc(gameplay: ^Gameplay) -> int {
	count := 0
	for bomb in gameplay.bombs {
		if bomb.active do count += 1
	}
	return count
}

available_bomb_count :: proc(gameplay: ^Gameplay) -> int {
	capacity := clamp(gameplay.player.bomb_capacity, 0, MAX_BOMBS)
	return max(capacity - active_bomb_count(gameplay), 0)
}

find_free_bomb_slot :: proc(gameplay: ^Gameplay) -> (slot: int, ok: bool) {
	for bomb_index in 0 ..< MAX_BOMBS {
		if !gameplay.bombs[bomb_index].active do return bomb_index, true
	}
	return 0, false
}

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
	if gameplay.player.score >= SCORE_BOMB_COST {
		gameplay.player.score -= SCORE_BOMB_COST
	}
	return true
}

clear_bomb_slot :: proc(gameplay: ^Gameplay, bomb_index: int) {
	if bomb_index < 0 || bomb_index >= MAX_BOMBS do return
	bomb := &gameplay.bombs[bomb_index]
	if !bomb.active do return
	if is_in_map(bomb.position) {
		gameplay.bomb_occupancy[bomb.position.x][bomb.position.y] = 0
	}
	bomb^ = {}
}

// Fuses use legacy action time, not render frames. Placement occurs before
// this procedure, so a new BOMBTIME=12 bomb finishes its placement action at
// 11, matching the original GetPlayerMove -> CheckBombs ordering.
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
