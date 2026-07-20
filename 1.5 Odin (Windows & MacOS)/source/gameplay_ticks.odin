package caverace

// queue_gameplay_input copies held directions and latches edge-triggered
// actions until a fixed gameplay tick can consume them safely.
queue_gameplay_input :: proc(tick_state: ^Gameplay_Tick_State, input: Game_Input) {
	tick_state.input.move_down = input.move_down
	tick_state.input.move_up = input.move_up
	tick_state.input.move_right = input.move_right
	tick_state.input.move_left = input.move_left
	if input.space_pressed do tick_state.input.bomb_pending = true

	for cheat_index in 0 ..< len(Cheat_Key) {
		cheat := Cheat_Key(cheat_index)
		if input.cheat_pressed[cheat] {
			tick_state.input.cheat_pending[cheat] = true
		}
	}
}

// Movement keeps the legacy down/up/right/left priority. Bomb placement is
// consumed independently at the same boundary and never creates an idle action.
select_gameplay_action :: proc(input: ^Gameplay_Input_Buffer) -> Gameplay_Action {
	if input.move_down  do return .Move_Down
	if input.move_up    do return .Move_Up
	if input.move_right do return .Move_Right
	if input.move_left  do return .Move_Left
	return .None
}

// apply_queued_cheats consumes edge-triggered cheat input on a gameplay tick;
// disabled cheats are discarded so old key presses cannot activate later.
apply_queued_cheats :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Tick_Result,
	cheats_enabled: bool,
) {
	for cheat_index in 0 ..< len(Cheat_Key) {
		cheat := Cheat_Key(cheat_index)
		if !gameplay.tick_state.input.cheat_pending[cheat] do continue

		gameplay.tick_state.input.cheat_pending[cheat] = false
		if cheats_enabled {
			result.cheat_pressed[cheat] = true
			apply_gameplay_cheat(gameplay, cheat)
		}
	}
}

// begin_gameplay_action_interval consumes a queued bomb edge independently,
// then starts actor movement at the selected 12-tick action boundary.
begin_gameplay_action_interval :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Tick_Result,
) {
	if gameplay.tick_state.input.bomb_pending {
		gameplay.tick_state.input.bomb_pending = false
		result.bomb_action_started = true
		result.bomb_placed = try_place_bomb(gameplay)
		if result.bomb_placed do result.ticking_requests += 1
	}
	result.last_action = select_gameplay_action(&gameplay.tick_state.input)
	result.action_decisions += 1
	begin_enemy_actions(gameplay)
	begin_player_action(gameplay, result.last_action)
}

// finish_gameplay_action_interval collects the committed player cell.
finish_gameplay_action_interval :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Tick_Result,
) {
	pickup := collect_player_cell(gameplay)
	if pickup.item_collected do result.items_collected += 1
	if pickup.item_salvaged do result.items_salvaged += 1
	if pickup.treasure_collected do result.treasures_collected += 1
	if pickup.item_collected || pickup.item_salvaged || pickup.treasure_collected {
		result.item_sound_requests += 1
	}
}

// run_gameplay_ticks advances as many fixed gameplay ticks as the render-frame
// accumulator allows, returning the events produced across those ticks.
run_gameplay_ticks :: proc(
	gameplay: ^Gameplay,
	frame_seconds: f64,
	cheats_enabled := false,
) -> Gameplay_Tick_Result {
	result: Gameplay_Tick_Result
	tick_state := &gameplay.tick_state
	clamped_seconds := frame_seconds
	if clamped_seconds < 0 do clamped_seconds = 0
	if clamped_seconds > MAX_FRAME_DELTA_SECONDS {
		clamped_seconds = MAX_FRAME_DELTA_SECONDS
	}
	tick_state.accumulator_seconds += clamped_seconds

	for tick_state.accumulator_seconds + 1e-12 >= GAMEPLAY_TICK_SECONDS &&
	    result.ticks_run < MAX_GAMEPLAY_TICKS_PER_FRAME {
		tick_state.accumulator_seconds -= GAMEPLAY_TICK_SECONDS
		if tick_state.accumulator_seconds < 0 do tick_state.accumulator_seconds = 0
		result.ticks_run += 1

		apply_queued_cheats(gameplay, &result, cheats_enabled)
		result.ticking_requests += advance_bomb_fuses(gameplay)
		start_ready_explosions(gameplay, &result)

		if tick_state.action_step == 0 {
			begin_gameplay_action_interval(gameplay, &result)
		}

		if gameplay.player.contact_grace_ticks > 0 {
			gameplay.player.contact_grace_ticks -= 1
		}
		player_was_alive := gameplay.player.energy > 0
		if gameplay.player.contact_grace_ticks == 0 && player_touches_enemy(gameplay) {
			result.player_damaged = apply_enemy_contact_damage(
				&gameplay.player,
				gameplay.difficulty,
			)
			if result.player_damaged {
				gameplay.player.contact_grace_ticks =
					gameplay_tuning(gameplay.difficulty).contact_grace_ticks
				result.contact_hit_requests += 1
			}
		}

		apply_active_explosions_to_entities(gameplay, &result)
		if player_was_alive && gameplay.player.energy == 0 {
			result.player_died = true
			result.bombs_expired += advance_explosion_ages(gameplay)
			break
		}

		advance_player_action_step(
			&gameplay.player,
			tick_state.action_step + 1,
		)
		advance_enemy_action_steps(gameplay, tick_state.action_step + 1)
		result.bombs_expired += advance_explosion_ages(gameplay)

		if tick_state.action_step + 1 == MOVEMENT_STEPS_PER_TILE {
			finish_gameplay_action_interval(gameplay, &result)
		}

		tick_state.action_step =
			(tick_state.action_step + 1) % MOVEMENT_STEPS_PER_TILE
	}

	return result
}
