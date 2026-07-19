package caverace

TRANSITION_FADE_SECONDS :: 0.40
FEEDBACK_FLASH_SECONDS  :: 0.14
FEEDBACK_FLASH_ALPHA    :: 0.28

// Feedback_Flash identifies the short gameplay overlay requested by the
// highest-priority event in the current frame.
Feedback_Flash :: enum {
	None,
	Damage,
	Item,
	Treasure,
}

// Game_Feedback stores non-blocking transition and flash timers owned by Game
// and advanced once per render frame.
Game_Feedback :: struct {
	transition_remaining: f64,
	flash_remaining:      f64,
	flash:                Feedback_Flash,
}

// start_transition_fade restarts the non-blocking black overlay whenever the
// application changes screens or gameplay lifecycle states.
start_transition_fade :: proc(feedback: ^Game_Feedback) {
	feedback.transition_remaining = TRANSITION_FADE_SECONDS
}

// request_gameplay_feedback selects the highest-priority color flash from the
// events produced by the current frame's gameplay ticks.
request_gameplay_feedback :: proc(
	feedback: ^Game_Feedback,
	result: ^Gameplay_Tick_Result,
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

// advance_game_feedback reduces active visual-effect timers once per render
// frame without blocking input or gameplay updates.
advance_game_feedback :: proc(feedback: ^Game_Feedback, frame_seconds: f64) {
	delta := clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	feedback.transition_remaining = max(feedback.transition_remaining - delta, 0)
	feedback.flash_remaining = max(feedback.flash_remaining - delta, 0)
	if feedback.flash_remaining == 0 do feedback.flash = .None
}

// transition_fade_alpha converts remaining transition time to the normalized
// alpha consumed by the top-level renderer.
transition_fade_alpha :: proc(feedback: Game_Feedback) -> f32 {
	if feedback.transition_remaining <= 0 do return 0
	return f32(clamp(feedback.transition_remaining / TRANSITION_FADE_SECONDS, 0, 1))
}

// feedback_flash_alpha computes the decaying overlay alpha for damage and
// pickup flashes during rendering.
feedback_flash_alpha :: proc(feedback: Game_Feedback) -> f32 {
	if feedback.flash_remaining <= 0 do return 0
	progress := feedback.flash_remaining / FEEDBACK_FLASH_SECONDS
	return f32(clamp(progress * FEEDBACK_FLASH_ALPHA, 0, FEEDBACK_FLASH_ALPHA))
}
