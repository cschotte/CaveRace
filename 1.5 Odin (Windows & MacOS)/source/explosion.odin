package caverace

append_explosion_cell :: proc(
	explosion: ^Explosion_State,
	position: Grid_Position,
	kind: Explosion_Cell_Kind,
) {
	if !is_in_map(position) do return
	assert(explosion.cell_count < MAX_EXPLOSION_CELLS)
	explosion.cells[explosion.cell_count] = {position, kind}
	explosion.cell_count += 1
}

build_explosion_state :: proc(bomb: ^Bomb_State) -> Explosion_State {
	explosion := Explosion_State {active = true}
	append_explosion_cell(&explosion, bomb.position, .Center)
	power := clamp(bomb.power, 0, PLAYER_MAX_BOMB_POWER)

	directions := [4]struct {
		delta: Grid_Position,
		kind:  Explosion_Cell_Kind,
	} {
		{{0, 1}, .Down},
		{{-1, 0}, .Left},
		{{0, -1}, .Up},
		{{1, 0}, .Right},
	}
	for direction in directions {
		for distance in 1 ..= power {
			position := Grid_Position {
				bomb.position.x + direction.delta.x * distance,
				bomb.position.y + direction.delta.y * distance,
			}
			append_explosion_cell(&explosion, position, direction.kind)
		}
	}
	return explosion
}

explosion_contains_cell :: proc(
	explosion: ^Explosion_State,
	position: Grid_Position,
) -> bool {
	if !explosion.active do return false
	for cell_index in 0 ..< explosion.cell_count {
		if explosion.cells[cell_index].position == position do return true
	}
	return false
}

active_explosion_contains_cell :: proc(
	gameplay: ^Gameplay,
	position: Grid_Position,
) -> bool {
	for explosion_index in 0 ..< MAX_BOMBS {
		if explosion_contains_cell(&gameplay.explosions[explosion_index], position) {
			return true
		}
	}
	return false
}

apply_explosion_to_level :: proc(gameplay: ^Gameplay, explosion: ^Explosion_State) {
	for cell_index in 0 ..< explosion.cell_count {
		cell := explosion.cells[cell_index]
		if cell.kind == .Center do continue

		item := &gameplay.level.data.item[cell.position.x][cell.position.y]
		treasure := &gameplay.level.data.treasure[cell.position.x][cell.position.y]
		// Preserve the original rule: a treasure makes both layers destructible;
		// otherwise only object sprites below 9 are destroyed.
		if treasure^ != 0 || item^ < INDESTRUCTIBLE_ITEM_FIRST {
			item^ = 0
			treasure^ = 0
		}
	}
}

chain_bombs_in_explosion :: proc(gameplay: ^Gameplay, explosion: ^Explosion_State) {
	for bomb_index in 0 ..< MAX_BOMBS {
		bomb := &gameplay.bombs[bomb_index]
		if !bomb.active || bomb.fuse_actions <= 1 do continue
		if explosion_contains_cell(explosion, bomb.position) {
			bomb.fuse_actions = 1
		}
	}
}

// Settle chains by scanning fixed slots until no newly-ready bomb remains.
// This avoids recursive mutation and makes score, sounds, and tests repeatable.
start_ready_explosions :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Simulation_Result,
) {
	started: [MAX_BOMBS]bool
	for {
		found_ready := false
		for bomb_index in 0 ..< MAX_BOMBS {
			bomb := &gameplay.bombs[bomb_index]
			if !bomb.active || bomb.fuse_actions != 1 do continue
			if gameplay.explosions[bomb_index].active do continue

			gameplay.explosions[bomb_index] = build_explosion_state(bomb)
			explosion := &gameplay.explosions[bomb_index]
			apply_explosion_to_level(gameplay, explosion)
			chain_bombs_in_explosion(gameplay, explosion)
			started[bomb_index] = true
			found_ready = true
		}
		if !found_ready do break
	}

	for bomb_index in 0 ..< MAX_BOMBS {
		if !started[bomb_index] do continue
		result.explosions_started += 1
		assert(result.explosion_sound_count < MAX_BOMBS)
		result.explosion_sound_indices[result.explosion_sound_count] =
			u8(gameplay_random_max(gameplay, BOMB_SOUND_COUNT))
		result.explosion_sound_count += 1
	}
}

apply_active_explosions_to_entities :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Simulation_Result,
) {
	for enemy_index in 0 ..< gameplay.enemy_count {
		enemy := &gameplay.enemies[enemy_index]
		if !enemy.active do continue
		screen_x, screen_y := enemy_screen_position(enemy)
		position, ok := screen_to_grid_position(screen_x, screen_y)
		if ok && active_explosion_contains_cell(gameplay, position) {
			enemy.active = false
			apply_score_event(&gameplay.player, .Enemy_Destroyed)
			result.enemies_destroyed += 1
			result.squish_requests += 1
		}
	}

	if gameplay.player.energy <= 0 do return
	player_x, player_y := player_screen_position(&gameplay.player)
	player_position, ok := screen_to_grid_position(player_x, player_y)
	if ok && active_explosion_contains_cell(gameplay, player_position) {
		gameplay.player.energy = 0
		result.player_damaged = true
	}
}

advance_explosion_ages :: proc(gameplay: ^Gameplay) {
	for explosion_index in 0 ..< MAX_BOMBS {
		explosion := &gameplay.explosions[explosion_index]
		if !explosion.active do continue
		explosion.age_step = min(explosion.age_step + 1, EXPLOSION_STEPS)
	}
}

explosion_animation_set :: proc(age_step: int) -> int {
	step := clamp(age_step, 1, EXPLOSION_STEPS)
	if step <= 3  do return 0
	if step <= 6  do return 1
	if step <= 10 do return 2
	if step <= 13 do return 1
	return 0
}

explosion_sprite_index :: proc(
	kind: Explosion_Cell_Kind,
	age_step: int,
) -> u8 {
	first_sprites := [3]int {
		EXPLOSION_SET_1_FIRST_SPRITE,
		EXPLOSION_SET_2_FIRST_SPRITE,
		EXPLOSION_SET_3_FIRST_SPRITE,
	}
	return u8(first_sprites[explosion_animation_set(age_step)] + int(kind))
}
