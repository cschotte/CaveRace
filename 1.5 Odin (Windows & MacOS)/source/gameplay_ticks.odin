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

// begin_gameplay_action_interval starts actor movement, optional bomb placement,
// fuse updates, and ready explosions in the original action-boundary order.
begin_gameplay_action_interval :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Tick_Result,
) {
	gameplay.tick_state.contact_damage_applied = false
	result.last_action = select_gameplay_action(&gameplay.tick_state.input)
	result.action_decisions += 1
	begin_enemy_actions(gameplay)
	begin_player_action(gameplay, result.last_action)
	if result.last_action == .Place_Bomb {
		result.bomb_action_started = true
		result.bomb_placed = try_place_bomb(gameplay)
		result.ticking_requested = result.bomb_placed
	}
	result.bombs_expired += advance_bomb_fuses(gameplay)
	start_ready_explosions(gameplay, result)
}

// finish_gameplay_action_interval collects the committed player cell and applies
// the legacy score floor after the sixteenth step of an action.
finish_gameplay_action_interval :: proc(
	gameplay: ^Gameplay,
	result: ^Gameplay_Tick_Result,
) {
	pickup := collect_player_cell(gameplay)
	if pickup.item_collected do result.items_collected += 1
	if pickup.treasure_collected do result.treasures_collected += 1
	if pickup.item_collected || pickup.treasure_collected {
		result.item_sound_requests += 1
	}
	apply_score_event(&gameplay.player, .Action_Floor)
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

		if tick_state.action_step == 0 {
			begin_gameplay_action_interval(gameplay, &result)
		}

		player_was_alive := gameplay.player.energy > 0
		if !tick_state.contact_damage_applied && player_touches_enemy(gameplay) {
			tick_state.contact_damage_applied = true
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
			tick_state.action_step + 1,
		)
		advance_enemy_action_steps(gameplay, tick_state.action_step + 1)
		advance_explosion_ages(gameplay)

		if tick_state.action_step + 1 == MOVEMENT_STEPS_PER_TILE {
			finish_gameplay_action_interval(gameplay, &result)
		}

		tick_state.action_step =
			(tick_state.action_step + 1) % MOVEMENT_STEPS_PER_TILE
	}

	return result
}
