package caverace

TRANSITION_FADE_SECONDS :: 0.40
FEEDBACK_FLASH_SECONDS  :: 0.14
FEEDBACK_FLASH_ALPHA    :: 0.28
SCREEN_SHAKE_SECONDS    :: 0.16

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
	reduced_flashes:      bool,
	shake_remaining:      f64,
	shake_phase:          f64,
	shake_strength:       f32,
}

// contact_grace_player_visible drives a local, non-color-only blink that
// remains available when full-screen flashes are reduced.
contact_grace_player_visible :: proc(contact_grace_ticks: int) -> bool {
	return contact_grace_ticks <= 0 || (contact_grace_ticks / 4) % 2 == 0
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
	if flash != .None && feedback.reduced_flashes {
		flash = .None
	}
	if flash != .None {
		feedback.flash = flash
		feedback.flash_remaining = FEEDBACK_FLASH_SECONDS
	}
	if result.player_damaged || result.explosions_started > 0 {
		feedback.shake_remaining = SCREEN_SHAKE_SECONDS
		feedback.shake_strength = 1
		if result.player_damaged do feedback.shake_strength = 1.35
	}
}

// advance_game_feedback reduces active visual-effect timers once per render
// frame without blocking input or gameplay updates.
advance_game_feedback :: proc(feedback: ^Game_Feedback, frame_seconds: f64) {
	delta := clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	feedback.transition_remaining = max(feedback.transition_remaining - delta, 0)
	feedback.flash_remaining = max(feedback.flash_remaining - delta, 0)
	feedback.shake_remaining = max(feedback.shake_remaining - delta, 0)
	feedback.shake_phase += delta * 60
	if feedback.flash_remaining == 0 do feedback.flash = .None
	if feedback.shake_remaining == 0 do feedback.shake_strength = 0
}

// screen_shake_offset returns at most two presentation pixels at 100% and is
// exactly zero when disabled, inactive, or configured to zero.
screen_shake_offset :: proc(feedback: Game_Feedback, intensity_percent: int) -> (i32, i32) {
	intensity := clamp(intensity_percent, 0, 100)
	if intensity == 0 || feedback.shake_remaining <= 0 do return 0, 0
	amplitude := f32(2) * f32(intensity) / 100 * feedback.shake_strength
	pixels := clamp(i32(amplitude + 0.5), 1, 2)
	phase := int(feedback.shake_phase) % 4
	switch phase {
	case 0: return pixels, 0
	case 1: return 0, -pixels
	case 2: return -pixels, 0
	case 3: return 0, pixels
	}
	return 0, 0
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
