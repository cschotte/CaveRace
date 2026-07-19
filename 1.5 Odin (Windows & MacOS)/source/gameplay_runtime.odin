package caverace

buffer_gameplay_input :: proc(simulation: ^Gameplay_Simulation_State, input: Game_Input) {
	simulation.input.move_down = input.move_down
	simulation.input.move_up = input.move_up
	simulation.input.move_right = input.move_right
	simulation.input.move_left = input.move_left
	if input.space_pressed do simulation.input.bomb_pending = true

	for cheat_index in 0 ..< len(Cheat_Key) {
		cheat := Cheat_Key(cheat_index)
		if input.cheat_pressed[cheat] {
			simulation.input.cheat_pending[cheat] = true
		}
	}
}

// The 1.3 input order is intentional: bomb, down, up, right, then left. This
// returns one action only and is called exclusively at a 16-step boundary.
select_gameplay_action :: proc(input: ^Gameplay_Input_Buffer) -> Gameplay_Action {
	if input.bomb_pending {
		input.bomb_pending = false
		return .Place_Bomb
	}
	if input.move_down  do return .Move_Down
	if input.move_up    do return .Move_Up
	if input.move_right do return .Move_Right
	if input.move_left  do return .Move_Left
	return .None
}

advance_gameplay_simulation :: proc(
	gameplay: ^Gameplay,
	frame_seconds: f64,
	cheats_enabled := false,
) -> Gameplay_Simulation_Result {
	result: Gameplay_Simulation_Result
	simulation := &gameplay.simulation
	clamped_seconds := frame_seconds
	if clamped_seconds < 0 do clamped_seconds = 0
	if clamped_seconds > MAX_FRAME_DELTA_SECONDS {
		clamped_seconds = MAX_FRAME_DELTA_SECONDS
	}
	simulation.accumulator_seconds += clamped_seconds

	for simulation.accumulator_seconds + 1e-12 >= SIMULATION_STEP_SECONDS &&
	    result.steps_run < MAX_SIMULATION_STEPS_PER_FRAME {
		simulation.accumulator_seconds -= SIMULATION_STEP_SECONDS
		if simulation.accumulator_seconds < 0 do simulation.accumulator_seconds = 0
		result.steps_run += 1

		for cheat_index in 0 ..< len(Cheat_Key) {
			cheat := Cheat_Key(cheat_index)
			if simulation.input.cheat_pending[cheat] {
				simulation.input.cheat_pending[cheat] = false
				if cheats_enabled {
					result.cheat_pressed[cheat] = true
					apply_gameplay_cheat(gameplay, cheat)
				}
			}
		}

		if simulation.action_step == 0 {
			simulation.contact_damage_applied = false
			result.last_action = select_gameplay_action(&simulation.input)
			result.action_decisions += 1
			begin_enemy_actions(gameplay)
			begin_player_action(gameplay, result.last_action)
			if result.last_action == .Place_Bomb {
				result.bomb_action_started = true
				result.bomb_placed = try_place_bomb(gameplay)
				result.ticking_requested = result.bomb_placed
			}
			result.bombs_expired += advance_bomb_fuses(gameplay)
			start_ready_explosions(gameplay, &result)
		}

		player_was_alive := gameplay.player.energy > 0
		if !simulation.contact_damage_applied && player_touches_enemy(gameplay) {
			simulation.contact_damage_applied = true
			result.player_damaged = apply_enemy_contact_damage(&gameplay.player)
		}

		apply_active_explosions_to_entities(gameplay, &result)
		if player_was_alive && gameplay.player.energy == 0 {
			result.player_died = true
			advance_explosion_ages(gameplay)
			break
		}

		advance_player_action_step(
			&gameplay.player,
			simulation.action_step + 1,
		)
		advance_enemy_action_steps(gameplay, simulation.action_step + 1)
		advance_explosion_ages(gameplay)

		if simulation.action_step + 1 == MOVEMENT_STEPS_PER_TILE {
			pickup := collect_player_cell(gameplay)
			if pickup.item_collected do result.items_collected += 1
			if pickup.treasure_collected do result.treasures_collected += 1
			if pickup.item_collected || pickup.treasure_collected {
				result.item_sound_requests += 1
			}
			apply_score_event(&gameplay.player, .Action_Floor)
		}

		simulation.action_step =
			(simulation.action_step + 1) % MOVEMENT_STEPS_PER_TILE
	}

	return result
}
