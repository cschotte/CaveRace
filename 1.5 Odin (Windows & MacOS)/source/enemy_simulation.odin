package caverace

import "core:math/rand"

seed_gameplay_random :: proc(gameplay: ^Gameplay, seed: u64) {
	generator := rand.xoshiro256_random_generator(&gameplay.random_state)
	rand.reset_u64(seed, generator)
}

gameplay_random_max :: proc(gameplay: ^Gameplay, upper_bound: int) -> int {
	assert(upper_bound > 0)
	generator := rand.xoshiro256_random_generator(&gameplay.random_state)
	return rand.int_max(upper_bound, generator)
}

enemy_direction_from_roll :: proc(roll: int) -> Direction {
	switch roll {
	case 0: return .Down
	case 1: return .Up
	case 2: return .Right
	case 3: return .Left
	}
	return .None
}

begin_enemy_action :: proc(
	gameplay: ^Gameplay,
	enemy: ^Enemy_State,
	direction: Direction,
) {
	enemy.move_from = enemy.position
	enemy.move_to = enemy.position
	enemy.movement_step = 0
	enemy.direction = direction

	if direction == .None do return
	delta := direction_delta(direction)
	target := Grid_Position {
		enemy.position.x + delta.x,
		enemy.position.y + delta.y,
	}
	if is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
		enemy.move_to = target
	}
}

begin_enemy_actions :: proc(gameplay: ^Gameplay) {
	for enemy_index in 0 ..< gameplay.enemy_count {
		enemy := &gameplay.enemies[enemy_index]
		if !enemy.active do continue
		roll := gameplay_random_max(gameplay, 4)
		begin_enemy_action(gameplay, enemy, enemy_direction_from_roll(roll))
	}
}

advance_enemy_action_steps :: proc(gameplay: ^Gameplay, completed_steps: int) {
	for enemy_index in 0 ..< gameplay.enemy_count {
		enemy := &gameplay.enemies[enemy_index]
		if !enemy.active do continue
		enemy.movement_step = clamp(completed_steps, 0, MOVEMENT_STEPS_PER_TILE)
		if enemy.movement_step == MOVEMENT_STEPS_PER_TILE {
			enemy.position = enemy.move_to
		}
	}
}

enemy_screen_position :: proc(enemy: ^Enemy_State) -> (x, y: i32) {
	return movement_screen_position(
		enemy.move_from,
		enemy.move_to,
		enemy.movement_step,
	)
}

player_touches_enemy :: proc(gameplay: ^Gameplay) -> bool {
	player_x, player_y := player_screen_position(&gameplay.player)
	for enemy_index in 0 ..< gameplay.enemy_count {
		enemy := &gameplay.enemies[enemy_index]
		if !enemy.active do continue
		enemy_x, enemy_y := enemy_screen_position(enemy)
		if player_x == enemy_x && player_y == enemy_y do return true
	}
	return false
}

apply_enemy_contact_damage :: proc(player: ^Player_State) -> bool {
	if player.energy <= 0 do return false
	player.energy = max(player.energy - ENEMY_CONTACT_DAMAGE, 0)
	return true
}
