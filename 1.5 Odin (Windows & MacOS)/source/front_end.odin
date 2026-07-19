package caverace

INTRO_FIRST_IMAGE       :: 0
INTRO_LAST_IMAGE        :: 6
MAIN_MENU_FIRST_IMAGE   :: 7
MAIN_MENU_LAST_IMAGE    :: 8
FRONT_END_IMAGE_COUNT   :: 9
MAIN_MENU_IMAGE_SECONDS :: 5.0
FRONT_END_TRANSITION_SECONDS :: 0.5

// Each story panel remains visible for the length of its matching music track.
INTRO_IMAGE_SECONDS :: [INTRO_LAST_IMAGE - INTRO_FIRST_IMAGE + 1]f64 {
	40.4742916666667,
	31.4547083333333,
	39.962375,
	36.1744583333333,
	32.3661666666667,
	30.8662916666667,
	9.18716666666667,
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

// advance_intro advances each story panel once and reports when the final
// panel has finished its display interval.
advance_intro :: proc(front_end: ^Front_End_State, frame_seconds: f64) -> bool {
	if front_end.transition_active {
		advance_front_end_transition(front_end, frame_seconds)
		return false
	}
	front_end.elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	image_seconds := intro_image_seconds(front_end.image_index)
	if front_end.elapsed_seconds < image_seconds do return false

	front_end.elapsed_seconds -= image_seconds
	if front_end.image_index < INTRO_LAST_IMAGE {
		begin_front_end_transition(front_end, front_end.image_index + 1)
		return false
	}
	return true
}

// advance_main_menu alternates the title and controls screens every five
// seconds for as long as the player remains on the main menu.
advance_main_menu :: proc(front_end: ^Front_End_State, frame_seconds: f64) {
	if front_end.transition_active {
		advance_front_end_transition(front_end, frame_seconds)
		return
	}
	front_end.elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	if front_end.elapsed_seconds < MAIN_MENU_IMAGE_SECONDS do return

	front_end.elapsed_seconds -= MAIN_MENU_IMAGE_SECONDS
	if front_end.image_index == MAIN_MENU_FIRST_IMAGE {
		begin_front_end_transition(front_end, MAIN_MENU_LAST_IMAGE)
	} else {
		begin_front_end_transition(front_end, MAIN_MENU_FIRST_IMAGE)
	}
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

// main_menu_start_requested accepts the title screen's advertised keyboard
// behavior without coupling the front end to specific key bindings.
main_menu_start_requested :: proc(input: Game_Input) -> bool {
	return input.any_key_pressed
}
