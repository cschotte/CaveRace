package caverace

AUTOPLAY_IDLE_SECONDS          :: 60.0
AUTOPLAY_DURATION_SECONDS      :: 60.0
AUTOPLAY_BOMB_ACTION_INTERVAL  :: 3
AUTOPLAY_ENEMY_SAFE_DISTANCE   :: 2
AUTOPLAY_ESCAPE_MARGIN_ACTIONS :: 1
AUTOPLAY_LEVEL_COUNT           :: 2

// Autoplay_State owns both halves of attract mode: the root-menu inactivity
// clock and the short-lived bot state used after the demo starts.
Autoplay_State :: struct {
	active:             bool,
	menu_idle_seconds:  f64,
	elapsed_seconds:    f64,
	direction:          Direction,
	needs_decision:     bool,
	actions_since_bomb: int,
	start_level_index:  int,
}

// advance_main_menu_autoplay resets on all menu activity and only counts time
// on the root page, so settings and instructional pages are never interrupted.
advance_main_menu_autoplay :: proc(
	autoplay: ^Autoplay_State,
	menu: ^Menu_State,
	input: Game_Input,
	frame_seconds: f64,
) -> bool {
	activity := input.keyboard_activity || input.controller_activity ||
	            pointer_activity(input.pointer)
	if menu.page != .Main || activity {
		autoplay.menu_idle_seconds = 0
		return false
	}
	autoplay.menu_idle_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	return autoplay.menu_idle_seconds >= AUTOPLAY_IDLE_SECONDS
}

// autoplay_exit_requested deliberately ignores mere pointer motion: the user
// can stop the demo with any keyboard/controller action or any mouse button.
autoplay_exit_requested :: proc(input: Game_Input) -> bool {
	return input.keyboard_activity || input.controller_activity ||
	       input.pointer.any_button_pressed
}

start_autoplay :: proc(game: ^Game) {
	level_index := game.next_autoplay_level_index % AUTOPLAY_LEVEL_COUNT
	game.autoplay = Autoplay_State {
		active            = true,
		needs_decision    = true,
		start_level_index = level_index,
	}
	init_gameplay(&game.gameplay, game.settings.difficulty)
	game.gameplay.mode = .Autoplay
	game.gameplay.level_index = level_index
	game.next_autoplay_level_index = (level_index + 1) % AUTOPLAY_LEVEL_COUNT
	game.effects = {}
	game.pause = {}
	game.screen = .Playing
}

// restart_autoplay_run handles a win or unusually short game-over without
// extending the demo's one-minute deadline or leaving caves 1 and 2.
restart_autoplay_run :: proc(game: ^Game) {
	elapsed_seconds := game.autoplay.elapsed_seconds
	level_index := game.autoplay.start_level_index
	init_gameplay(&game.gameplay, game.settings.difficulty)
	game.gameplay.mode = .Autoplay
	game.gameplay.level_index = level_index
	game.effects = {}
	game.pause = {}
	game.autoplay = Autoplay_State {
		active            = true,
		elapsed_seconds   = elapsed_seconds,
		needs_decision    = true,
		start_level_index = level_index,
	}
}

autoplay_position_in_danger :: proc(
	gameplay: ^Gameplay,
	position: Grid_Position,
) -> bool {
	if active_explosion_contains_cell(gameplay, position) do return true
	for bomb_index in 0 ..< MAX_BOMBS {
		bomb := &gameplay.bombs[bomb_index]
		if !bomb.active do continue
		footprint := build_explosion_state(bomb)
		if explosion_contains_cell(&footprint, position) do return true
	}
	return false
}

// autoplay_enemy_clearance measures the nearest live enemy against both ends
// of its current movement. A distance of one is unsafe: on the next action the
// enemy could enter or cross the player's chosen tile.
autoplay_enemy_clearance :: proc(gameplay: ^Gameplay, position: Grid_Position) -> int {
	clearance := MAP_WIDTH + MAP_HEIGHT
	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		clearance = min(clearance, manhattan_distance(position, enemy.position))
		clearance = min(clearance, manhattan_distance(position, enemy.move_to))
	}
	return clearance
}

autoplay_position_in_danger_with_bomb :: proc(
	gameplay: ^Gameplay,
	position: Grid_Position,
	extra_bomb: ^Bomb_State,
) -> bool {
	if autoplay_position_in_danger(gameplay, position) do return true
	if extra_bomb != nil {
		footprint := build_explosion_state(extra_bomb)
		if explosion_contains_cell(&footprint, position) do return true
	}
	return false
}

// autoplay_escape_route performs a bounded breadth-first search from the
// player's cell to the nearest tile outside every bomb footprint. It may cross
// a future footprint while the fuse is ticking, but never an already-active
// explosion or an enemy interception tile.
autoplay_escape_route_from :: proc(
	gameplay: ^Gameplay,
	start: Grid_Position,
	extra_bomb: ^Bomb_State = nil,
) -> (first_direction: Direction, distance: int, found: bool) {
	visited: [MAP_WIDTH][MAP_HEIGHT]bool
	first_steps: [MAP_WIDTH][MAP_HEIGHT]Direction
	distances: [MAP_WIDTH][MAP_HEIGHT]int
	queue: [MAP_WIDTH * MAP_HEIGHT]Grid_Position
	queue[0] = start
	queue_read, queue_count := 0, 1
	visited[start.x][start.y] = true
	directions := [4]Direction{.Down, .Up, .Right, .Left}

	for queue_read < queue_count {
		position := queue[queue_read]
		queue_read += 1
		for direction in directions {
			delta := direction_delta(direction)
			target := Grid_Position{position.x + delta.x, position.y + delta.y}
			if !is_in_map(target) || visited[target.x][target.y] do continue
			if !is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
				continue
			}
			if active_explosion_contains_cell(gameplay, target) do continue
			if autoplay_enemy_clearance(gameplay, target) < AUTOPLAY_ENEMY_SAFE_DISTANCE {
				continue
			}

			visited[target.x][target.y] = true
			distances[target.x][target.y] = distances[position.x][position.y] + 1
			first_step := first_steps[position.x][position.y]
			if position == start do first_step = direction
			first_steps[target.x][target.y] = first_step
			if !autoplay_position_in_danger_with_bomb(gameplay, target, extra_bomb) {
				return first_step, distances[target.x][target.y], true
			}
			queue[queue_count] = target
			queue_count += 1
		}
	}
	return .None, 0, false
}

autoplay_escape_route :: proc(
	gameplay: ^Gameplay,
	extra_bomb: ^Bomb_State = nil,
) -> (first_direction: Direction, distance: int, found: bool) {
	return autoplay_escape_route_from(gameplay, gameplay.player.position, extra_bomb)
}

autoplay_candidate_position :: proc(
	position: Grid_Position,
	direction: Direction,
) -> Grid_Position {
	delta := direction_delta(direction)
	return {position.x + delta.x, position.y + delta.y}
}

// autoplay_bomb_value counts targets a hypothetical bomb would affect. The bot
// only spends a bomb to pressure an enemy or clear a destructible object; it no
// longer drops bombs on an arbitrary timer in empty corridors.
autoplay_bomb_value :: proc(gameplay: ^Gameplay, position: Grid_Position) -> int {
	bomb := Bomb_State {
		active   = true,
		position = position,
		power    = gameplay.player.bomb_power,
	}
	footprint := build_explosion_state(&bomb)
	value := 0
	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		if explosion_contains_cell(&footprint, enemy.position) ||
		   explosion_contains_cell(&footprint, enemy.move_to) {
			value += 6
			continue
		}
		// A ticking bomb is a trap, not a hitscan attack. Nearby enemies
		// make a bomb useful even before they enter its final footprint.
		proximity := min(
			manhattan_distance(position, enemy.position),
			manhattan_distance(position, enemy.move_to),
		)
		if proximity <= gameplay.player.bomb_power + 1 do value += 1
	}
	for cell_index in 0 ..< footprint.cell_count {
		cell := footprint.cells[cell_index]
		if cell.kind == .Center do continue
		item := gameplay.level.data.item[cell.position.x][cell.position.y]
		if item > PASSABLE_ITEM_LIMIT && item < INDESTRUCTIBLE_ITEM_FIRST {
			value += 1
		}
	}
	return value
}

autoplay_position_has_collectible :: proc(
	gameplay: ^Gameplay,
	position: Grid_Position,
) -> bool {
	item := gameplay.level.data.item[position.x][position.y]
	return (item > 0 && item <= PASSABLE_ITEM_LIMIT) ||
	       gameplay.level.data.treasure[position.x][position.y] != 0
}

autoplay_bomb_plan_at :: proc(
	gameplay: ^Gameplay,
	position: Grid_Position,
) -> (Direction, bool) {
	if cell_has_bomb(&gameplay.bomb_occupancy, position) do return .None, false
	if autoplay_position_in_danger(gameplay, position) do return .None, false
	if autoplay_enemy_clearance(gameplay, position) < AUTOPLAY_ENEMY_SAFE_DISTANCE {
		return .None, false
	}
	if autoplay_bomb_value(gameplay, position) == 0 do return .None, false

	bomb := Bomb_State {
		active       = true,
		position     = position,
		fuse_ticks   = gameplay_tuning(gameplay.difficulty).bomb_fuse_ticks,
		power        = gameplay.player.bomb_power,
	}
	direction, distance, found := autoplay_escape_route_from(gameplay, position, &bomb)
	actions_available := bomb.fuse_ticks / MOVEMENT_STEPS_PER_TILE -
	                     AUTOPLAY_ESCAPE_MARGIN_ACTIONS
	return direction, found && distance <= actions_available
}

// autoplay_plan_bomb proves that the bot has enough fuse time to reach a safe
// cell before allowing placement, and returns the first escape step so movement
// begins on the same action as the bomb placement.
autoplay_plan_bomb :: proc(gameplay: ^Gameplay) -> (Direction, bool) {
	position := gameplay.player.position
	if available_bomb_count(gameplay) == 0 do return .None, false
	return autoplay_bomb_plan_at(gameplay, position)
}

// autoplay_objective_direction searches the reachable safe map for a
// collectible before falling back to the nearest useful bomb position. Power
// and capacity pickups are especially important when playing by normal rules;
// without this priority, a nearby destructible object can distract the bot
// forever from a reachable upgrade.
autoplay_objective_direction :: proc(gameplay: ^Gameplay) -> (Direction, bool) {
	start := gameplay.player.position
	visited: [MAP_WIDTH][MAP_HEIGHT]bool
	first_steps: [MAP_WIDTH][MAP_HEIGHT]Direction
	queue: [MAP_WIDTH * MAP_HEIGHT]Grid_Position
	queue[0] = start
	queue_read, queue_count := 0, 1
	visited[start.x][start.y] = true
	directions := [4]Direction{.Down, .Up, .Right, .Left}
	bomb_direction := Direction.None
	has_bomb_direction := false

	for queue_read < queue_count {
		position := queue[queue_read]
		queue_read += 1
		for direction in directions {
			target := autoplay_candidate_position(position, direction)
			if !is_in_map(target) || visited[target.x][target.y] do continue
			if !is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
				continue
			}
			if autoplay_position_in_danger(gameplay, target) do continue
			if autoplay_enemy_clearance(gameplay, target) < AUTOPLAY_ENEMY_SAFE_DISTANCE {
				continue
			}

			visited[target.x][target.y] = true
			first_step := first_steps[position.x][position.y]
			if position == start do first_step = direction
			first_steps[target.x][target.y] = first_step
			if autoplay_position_has_collectible(gameplay, target) {
				return first_step, true
			}
			if !has_bomb_direction {
				_, can_bomb := autoplay_bomb_plan_at(gameplay, target)
				if can_bomb {
					bomb_direction = first_step
					has_bomb_direction = true
				}
			}
			queue[queue_count] = target
			queue_count += 1
		}
	}
	return bomb_direction, has_bomb_direction
}

// autoplay_choose_direction prioritizes bomb escape first, then maximizes
// enemy clearance. Small continuity and useful-bomb-location bonuses break
// otherwise equivalent choices without overriding survival.
autoplay_choose_direction :: proc(
	autoplay: ^Autoplay_State,
	gameplay: ^Gameplay,
) -> Direction {
	if autoplay_position_in_danger(gameplay, gameplay.player.position) {
		if direction, _, found := autoplay_escape_route(gameplay); found {
			return direction
		}
	}

	options := [5]Direction{.None, .Down, .Up, .Right, .Left}
	objective_direction, has_objective := autoplay_objective_direction(gameplay)
	best: [5]Direction
	best_count := 0
	best_score := -1_000_000
	for direction in options {
		target := autoplay_candidate_position(gameplay.player.position, direction)
		if direction != .None &&
		   !is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
			continue
		}
		if active_explosion_contains_cell(gameplay, target) do continue

		// Once a tile has a two-cell enemy buffer, useful bomb positions matter
		// more than endlessly retreating toward a corner. The hard penalties below
		// still reject interception cells and all known blast paths.
		score := min(autoplay_enemy_clearance(gameplay, target), 4) * 12
		if autoplay_position_in_danger(gameplay, target) do score -= 10_000
		if autoplay_enemy_clearance(gameplay, target) < AUTOPLAY_ENEMY_SAFE_DISTANCE {
			score -= 10_000
		}
		score += autoplay_bomb_value(gameplay, target) * 40
		if has_objective && direction == objective_direction do score += 250
		if direction == autoplay.direction do score += 3
		if direction == opposite_direction(autoplay.direction) do score -= 2
		if direction == .None do score -= 1

		if score > best_score {
			best_score = score
			best[0] = direction
			best_count = 1
		} else if score == best_score {
			best[best_count] = direction
			best_count += 1
		}
	}
	if best_count == 0 do return .None
	return best[gameplay_random_max(gameplay, best_count)]
}

set_autoplay_direction_input :: proc(input: ^Game_Input, direction: Direction) {
	switch direction {
	case .Down:  input.move_down = true
	case .Up:    input.move_up = true
	case .Right: input.move_right = true
	case .Left:  input.move_left = true
	case .None:
	}
}

// build_autoplay_input supplies held movement every frame and makes decisions
// exactly once per 12-tick action interval. Outcome screens are advanced so a
// death or cave completion does not consume the rest of the demo standing still.
build_autoplay_input :: proc(
	autoplay: ^Autoplay_State,
	gameplay: ^Gameplay,
) -> Game_Input {
	input: Game_Input
	switch gameplay.state {
	case .Dead, .Won:
		input.confirm = true
		return input
	case .Load_Level, .Game_Won, .Game_Over, .Load_Failed:
		return input
	case .Playing:
	}

	if gameplay.tick_state.action_step != 0 {
		autoplay.needs_decision = true
	} else if autoplay.needs_decision {
		autoplay.direction = autoplay_choose_direction(autoplay, gameplay)
		autoplay.actions_since_bomb += 1
		if autoplay.actions_since_bomb >= AUTOPLAY_BOMB_ACTION_INTERVAL {
			if escape_direction, place_bomb := autoplay_plan_bomb(gameplay); place_bomb {
				autoplay.direction = escape_direction
				input.space_pressed = true
				autoplay.actions_since_bomb = 0
			}
		}
		autoplay.needs_decision = false
	}
	set_autoplay_direction_input(&input, autoplay.direction)
	return input
}
