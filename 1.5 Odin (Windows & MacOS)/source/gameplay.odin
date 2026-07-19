package caverace

// update_gameplay performs one non-blocking frame update. Playing-state logic
// advances through the fixed-tick accumulator; screen transitions remain
// immediate so menu/back input is responsive at any render rate.
update_gameplay :: proc(
	gameplay: ^Gameplay,
	input: Game_Input,
	frame_seconds: f64,
	cheats_enabled := false,
) -> Gameplay_Frame_Result {
	result: Gameplay_Frame_Result
	if input.back {
		result.back_requested = true
		return result
	}

	switch gameplay.state {
	case .Load_Level:
	case .Playing:
		queue_gameplay_input(&gameplay.tick_state, input)
		result.ticks = run_gameplay_ticks(
			gameplay,
			frame_seconds,
			cheats_enabled,
		)
		resolve_gameplay_outcome(gameplay, result.ticks)

	case .Dead:
		if input.confirm {
			begin_level_retry(gameplay)
		}

	case .Won:
		if input.confirm {
			begin_next_level(gameplay)
		}

	case .Game_Over:

	case .Load_Failed:
		if input.confirm do gameplay.state = .Load_Level
	}

	return result
}
