package caverace

INTRO_FIRST_IMAGE       :: 0
INTRO_LAST_IMAGE        :: 6
MAIN_MENU_FIRST_IMAGE   :: 7
MAIN_MENU_LAST_IMAGE    :: 8
FRONT_END_IMAGE_COUNT   :: 9
FRONT_END_TRANSITION_SECONDS :: 0.5
BRANDING_FALLBACK_SECONDS    :: 3.84

// Each story panel remains visible for the length of its matching music track.
INTRO_IMAGE_SECONDS :: [INTRO_LAST_IMAGE - INTRO_FIRST_IMAGE + 1]f64 {
	8.222063,
	10.444218,
	11.110884,
	7.481315,
	10.221995,
	14.81449,
	10.370159,
}

// skip_intro_image advances immediately to the next story panel. Skipping the
// last panel reports completion so Game can enter the main menu.
skip_intro_image :: proc(front_end: ^Front_End_State) -> bool {
	if front_end.image_index >= INTRO_LAST_IMAGE do return true
	begin_front_end_transition(front_end, front_end.image_index + 1)
	return false
}

intro_image_seconds :: proc(image_index: int) -> f64 {
	assert(image_index >= INTRO_FIRST_IMAGE && image_index <= INTRO_LAST_IMAGE)
	durations := INTRO_IMAGE_SECONDS
	return durations[image_index - INTRO_FIRST_IMAGE]
}

#assert(INTRO_FIRST_IMAGE == 0)
#assert(INTRO_LAST_IMAGE + 1 == MAIN_MENU_FIRST_IMAGE)
#assert(MAIN_MENU_LAST_IMAGE + 1 == FRONT_END_IMAGE_COUNT)

// Front_End_State owns the current story/title image and its presentation
// timer. Game chooses whether the bounded index represents Intro or Main_Menu.
Front_End_State :: struct {
	image_index:                int,
	previous_image_index:       int,
	elapsed_seconds:            f64,
	transition_elapsed_seconds: f64,
	transition_active:          bool,
}

begin_intro :: proc(front_end: ^Front_End_State) {
	front_end^ = Front_End_State {
		image_index          = INTRO_FIRST_IMAGE,
		previous_image_index = INTRO_FIRST_IMAGE,
	}
}

begin_main_menu :: proc(front_end: ^Front_End_State) {
	front_end^ = Front_End_State {
		image_index          = MAIN_MENU_FIRST_IMAGE,
		previous_image_index = MAIN_MENU_FIRST_IMAGE,
	}
}

// begin_front_end_transition selects the next image immediately while retaining
// the previous index for the renderer's fade-out half.
begin_front_end_transition :: proc(front_end: ^Front_End_State, next_image: int) {
	assert(next_image >= 0 && next_image < FRONT_END_IMAGE_COUNT)
	front_end.previous_image_index = front_end.image_index
	front_end.image_index = next_image
	front_end.elapsed_seconds = 0
	front_end.transition_elapsed_seconds = 0
	front_end.transition_active = true
}

// advance_front_end_transition updates a non-blocking fade-out/fade-in without
// consuming start or skip input at the Game routing layer.
advance_front_end_transition :: proc(
	front_end: ^Front_End_State,
	frame_seconds: f64,
) {
	assert(front_end.transition_active)
	front_end.transition_elapsed_seconds += clamp(
		frame_seconds,
		0,
		MAX_FRAME_DELTA_SECONDS,
	)
	if front_end.transition_elapsed_seconds >= FRONT_END_TRANSITION_SECONDS {
		front_end.transition_elapsed_seconds = FRONT_END_TRANSITION_SECONDS
		front_end.transition_active = false
	}
}

// advance_intro advances a story panel when its real music stream finishes.
// The exact packaged duration remains a fallback for silent/no-audio startup
// and keeps the platform-independent story flow deterministic in tests.
advance_intro :: proc(
	front_end: ^Front_End_State,
	frame_seconds: f64,
	music_finished := false,
	music_controls_timing := false,
) -> bool {
	if front_end.transition_active {
		advance_front_end_transition(front_end, frame_seconds)
		return false
	}
	front_end.elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	image_seconds := intro_image_seconds(front_end.image_index)
	if !music_finished {
		if music_controls_timing || front_end.elapsed_seconds < image_seconds do return false
	}

	front_end.elapsed_seconds = 0
	if front_end.image_index < INTRO_LAST_IMAGE {
		begin_front_end_transition(front_end, front_end.image_index + 1)
		return false
	}
	return true
}


// front_end_visual returns the texture and opacity for the current transition
// phase: old image to black, then black to the new image.
front_end_visual :: proc(front_end: Front_End_State) -> (image_index: int, alpha: f32) {
	if !front_end.transition_active do return front_end.image_index, 1
	progress := clamp(
		front_end.transition_elapsed_seconds / FRONT_END_TRANSITION_SECONDS,
		0,
		1,
	)
	if progress < 0.5 {
		return front_end.previous_image_index, f32(1 - progress * 2)
	}
	return front_end.image_index, f32((progress - 0.5) * 2)
}
