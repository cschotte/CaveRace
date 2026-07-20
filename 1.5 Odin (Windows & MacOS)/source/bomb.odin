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
// slot. Placement is score-neutral and independent from movement in Standard.
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
		fuse_ticks   = gameplay_tuning(gameplay.difficulty).bomb_fuse_ticks,
		power        = gameplay.player.bomb_power,
	}
	gameplay.bomb_occupancy[position.x][position.y] = BOMB_TICKING_SPRITE
	return true
}

// clear_bomb_slot releases bomb occupancy and its paired explosion record when
// an explosion completes or lifecycle cleanup explicitly releases a slot.
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

// bomb_is_in_danger_window selects bombs whose exact blast footprint should be
// previewed. Exploding bombs render their explosion instead of a preview.
bomb_is_in_danger_window :: proc(
	bomb: ^Bomb_State,
	difficulty: Difficulty_Profile = .Standard,
) -> bool {
	if !bomb.active || bomb.fuse_ticks <= 0 do return false
	return bomb.fuse_ticks <= gameplay_tuning(difficulty).bomb_danger_preview_ticks
}

// bomb_danger_footprint reuses the detonation builder so previews cannot drift
// from the cells that explosion damage will consume.
bomb_danger_footprint :: proc(
	bomb: ^Bomb_State,
	difficulty: Difficulty_Profile = .Standard,
) -> (footprint: Explosion_State, visible: bool) {
	if !bomb_is_in_danger_window(bomb, difficulty) do return {}, false
	return build_explosion_state(bomb), true
}

// bomb_tick_interval accelerates the warning cadence during the final second.
bomb_tick_interval :: proc(fuse_ticks: int) -> int {
	if fuse_ticks > GAMEPLAY_TICK_HZ * 2 do return 30
	if fuse_ticks > GAMEPLAY_TICK_HZ do return 15
	return 6
}

// advance_bomb_fuses runs every fixed tick, independent from movement cadence,
// and reports warning clicks. Ready bombs remain owned until their explosion
// animation completes and start_ready_explosions consumes fuse_ticks == 0.
advance_bomb_fuses :: proc(gameplay: ^Gameplay) -> (ticking_requests: int) {
	for bomb_index in 0 ..< MAX_BOMBS {
		bomb := &gameplay.bombs[bomb_index]
		if !bomb.active || gameplay.explosions[bomb_index].active do continue
		if bomb.fuse_ticks > 0 {
			bomb.fuse_ticks -= 1
			interval := bomb_tick_interval(bomb.fuse_ticks)
			if bomb.fuse_ticks > 0 && bomb.fuse_ticks % interval == 0 {
				ticking_requests += 1
			}
		}
	}
	return
}
