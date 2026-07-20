package caverace

import "core:math/rand"

// enemy_slots returns the initialized prefix of the fixed enemy storage. The
// slice borrows Gameplay memory and never allocates; centralizing this boundary
// keeps every enemy system on the same checked count invariant.
enemy_slots :: proc(gameplay: ^Gameplay) -> []Enemy_State {
	assert(gameplay.enemy_count >= 0 && gameplay.enemy_count <= len(gameplay.enemies))
	return gameplay.enemies[:gameplay.enemy_count]
}

COSMETIC_RANDOM_SEED_XOR :: u64(0x9e3779b97f4a7c15)

// seed_gameplay_random initializes independent session-owned AI and cosmetic
// streams. Audio/visual variation can advance without changing enemy choices.
seed_gameplay_random :: proc(gameplay: ^Gameplay, seed: u64) {
	gameplay.run_seed = seed
	ai_generator := rand.xoshiro256_random_generator(&gameplay.ai_random_state)
	rand.reset_u64(seed, ai_generator)
	cosmetic_generator := rand.xoshiro256_random_generator(
		&gameplay.cosmetic_random_state,
	)
	rand.reset_u64(seed ~ COSMETIC_RANDOM_SEED_XOR, cosmetic_generator)
}

// gameplay_random_max draws a bounded value from the session generator for
// deterministic gameplay decisions that must not use global random state.
gameplay_random_max :: proc(gameplay: ^Gameplay, upper_bound: int) -> int {
	assert(upper_bound > 0)
	generator := rand.xoshiro256_random_generator(&gameplay.ai_random_state)
	return rand.int_max(upper_bound, generator)
}

// gameplay_cosmetic_random_max is reserved for presentation choices that must
// never influence deterministic enemy movement or future challenge seeds.
gameplay_cosmetic_random_max :: proc(gameplay: ^Gameplay, upper_bound: int) -> int {
	assert(upper_bound > 0)
	generator := rand.xoshiro256_random_generator(&gameplay.cosmetic_random_state)
	return rand.int_max(upper_bound, generator)
}

// active_enemy_count counts surviving enemies when resolving level completion
// and when tests need to inspect the fixed enemy array.
active_enemy_count :: proc(gameplay: ^Gameplay) -> int {
	count := 0
	for enemy in enemy_slots(gameplay) {
		if enemy.active do count += 1
	}
	return count
}

// enemy_direction_from_roll maps the four random outcomes to the legacy
// cardinal direction order used at each action boundary.
enemy_direction_from_roll :: proc(roll: int) -> Direction {
	switch roll {
	case 0: return .Down
	case 1: return .Up
	case 2: return .Right
	case 3: return .Left
	}
	return .None
}

manhattan_distance :: proc(a, b: Grid_Position) -> int {
	return abs(a.x - b.x) + abs(a.y - b.y)
}

opposite_direction :: proc(direction: Direction) -> Direction {
	switch direction {
	case .Down:  return .Up
	case .Up:    return .Down
	case .Right: return .Left
	case .Left:  return .Right
	case .None:  return .None
	}
	return .None
}

enemy_pursuit_chance :: proc(gameplay: ^Gameplay) -> f32 {
	chance := level_metadata(gameplay.level_index).enemy_pursuit_chance
	if gameplay.difficulty == .Assisted do chance *= 0.5
	return clamp(chance, 0, 0.35)
}

// pursuit_direction selects only walkable steps that reduce Manhattan
// distance. It is called after a metadata chance succeeds, so early caves keep
// the original fully random behavior.
pursuit_direction :: proc(gameplay: ^Gameplay, enemy: ^Enemy_State) -> Direction {
	directions := [4]Direction{.Down, .Up, .Right, .Left}
	candidates: [4]Direction
	candidate_count := 0
	reverse_candidate := Direction.None
	reverse := opposite_direction(enemy.direction)
	current_distance := manhattan_distance(enemy.position, gameplay.player.position)
	for direction in directions {
		delta := direction_delta(direction)
		target := Grid_Position{enemy.position.x + delta.x, enemy.position.y + delta.y}
		if is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) &&
		   manhattan_distance(target, gameplay.player.position) < current_distance {
			if direction == reverse {
				reverse_candidate = direction
				continue
			}
			candidates[candidate_count] = direction
			candidate_count += 1
		}
	}
	if candidate_count == 0 do return reverse_candidate
	return candidates[gameplay_random_max(gameplay, candidate_count)]
}

// begin_enemy_action chooses the enemy's target cell for the next movement
// action while preserving its current cell when the destination is blocked.
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

// begin_enemy_actions starts one seeded movement choice for every active enemy
// whenever gameplay reaches a new action boundary.
begin_enemy_actions :: proc(gameplay: ^Gameplay) {
	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		roll := gameplay_random_max(gameplay, 4)
		direction := enemy_direction_from_roll(roll)
		chance := enemy_pursuit_chance(gameplay)
		if chance > 0 && gameplay_random_max(gameplay, 1000) < int(chance * 1000) {
			if pursued := pursuit_direction(gameplay, &enemy); pursued != .None {
				direction = pursued
			}
		}
		begin_enemy_action(gameplay, &enemy, direction)
	}
}

// advance_enemy_action_steps updates interpolation progress for all active
// enemies and commits their target cells when the current action finishes.
advance_enemy_action_steps :: proc(gameplay: ^Gameplay, completed_steps: int) {
	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		enemy.movement_step = clamp(completed_steps, 0, MOVEMENT_STEPS_PER_TILE)
		if enemy.movement_step == MOVEMENT_STEPS_PER_TILE {
			enemy.position = enemy.move_to
		}
	}
}

// enemy_screen_position returns an enemy's interpolated pixel position for
// rendering during an in-progress movement action.
enemy_screen_position :: proc(enemy: ^Enemy_State) -> (x, y: i32) {
	return movement_screen_position(
		enemy.move_from,
		enemy.move_to,
		enemy.movement_step,
	)
}

// enemy_subtile_position exposes an enemy's interpolated simulation coordinate
// for actor contact checks.
enemy_subtile_position :: proc(enemy: ^Enemy_State) -> Subtile_Position {
	return movement_subtile_position(
		enemy.move_from,
		enemy.move_to,
		enemy.movement_step,
	)
}

// player_touches_enemy detects exact sub-tile overlap during each gameplay tick
// so crossing actors can deal contact damage before reaching a tile boundary.
player_touches_enemy :: proc(gameplay: ^Gameplay) -> bool {
	player_position := player_subtile_position(&gameplay.player)
	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		if player_position == enemy_subtile_position(&enemy) do return true
	}
	return false
}

// apply_enemy_contact_damage applies one capped legacy damage event after the
// gameplay clock has ensured contact is charged only once per action.
apply_enemy_contact_damage :: proc(
	player: ^Player_State,
	difficulty: Difficulty_Profile = .Standard,
) -> bool {
	if player.energy <= 0 do return false
	tuning := gameplay_tuning(difficulty)
	player.energy = max(player.energy - tuning.enemy_contact_damage, 0)
	return true
}
