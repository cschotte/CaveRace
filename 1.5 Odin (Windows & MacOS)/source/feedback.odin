package caverace

import rl "vendor:raylib"

TRANSITION_FADE_SECONDS :: 0.40
FEEDBACK_FLASH_SECONDS  :: 0.14
FEEDBACK_FLASH_ALPHA    :: 0.28

Feedback_Flash :: enum {
	None,
	Damage,
	Item,
	Treasure,
}

Game_Feedback :: struct {
	transition_remaining: f64,
	flash_remaining:      f64,
	flash:                Feedback_Flash,
}

start_transition_fade :: proc(feedback: ^Game_Feedback) {
	feedback.transition_remaining = TRANSITION_FADE_SECONDS
}

request_simulation_feedback :: proc(
	feedback: ^Game_Feedback,
	result: ^Gameplay_Simulation_Result,
) {
	// Damage wins when events share a frame; otherwise treasure keeps its
	// distinct legacy blue feedback instead of being folded into item green.
	flash := Feedback_Flash.None
	if result.player_damaged {
		flash = .Damage
	} else if result.treasures_collected > 0 {
		flash = .Treasure
	} else if result.items_collected > 0 {
		flash = .Item
	}
	if flash != .None {
		feedback.flash = flash
		feedback.flash_remaining = FEEDBACK_FLASH_SECONDS
	}
}

advance_game_feedback :: proc(feedback: ^Game_Feedback, frame_seconds: f64) {
	delta := clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	feedback.transition_remaining = max(feedback.transition_remaining - delta, 0)
	feedback.flash_remaining = max(feedback.flash_remaining - delta, 0)
	if feedback.flash_remaining == 0 do feedback.flash = .None
}

transition_fade_alpha :: proc(feedback: ^Game_Feedback) -> f32 {
	if feedback.transition_remaining <= 0 do return 0
	return f32(clamp(feedback.transition_remaining / TRANSITION_FADE_SECONDS, 0, 1))
}

feedback_flash_alpha :: proc(feedback: ^Game_Feedback) -> f32 {
	if feedback.flash_remaining <= 0 do return 0
	progress := feedback.flash_remaining / FEEDBACK_FLASH_SECONDS
	return f32(clamp(progress * FEEDBACK_FLASH_ALPHA, 0, FEEDBACK_FLASH_ALPHA))
}

feedback_flash_color :: proc(flash: Feedback_Flash) -> rl.Color {
	switch flash {
	case .Damage:   return rl.RED
	case .Item:     return rl.GREEN
	case .Treasure: return rl.BLUE
	case .None:     return rl.BLANK
	}
	return rl.BLANK
}

draw_game_feedback :: proc(feedback: ^Game_Feedback) {
	if fade_alpha := transition_fade_alpha(feedback); fade_alpha > 0 {
		rl.DrawRectangle(
			0,
			0,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			rl.Fade(rl.BLACK, fade_alpha),
		)
	}
	if flash_alpha := feedback_flash_alpha(feedback); flash_alpha > 0 {
		rl.DrawRectangle(
			0,
			0,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			rl.Fade(feedback_flash_color(feedback.flash), flash_alpha),
		)
	}
}
