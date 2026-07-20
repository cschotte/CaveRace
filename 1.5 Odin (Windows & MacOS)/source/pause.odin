package caverace

// toggle_game_pause freezes or resumes active gameplay at the Game routing
// layer. Clearing queued input on both edges prevents a key held before pause
// from being replayed after the overlay closes.
toggle_game_pause :: proc(game: ^Game) {
	assert(game.screen == .Playing)
	assert(game.gameplay.state == .Playing)
	game.paused = !game.paused
	game.gameplay.tick_state.input = {}
}
