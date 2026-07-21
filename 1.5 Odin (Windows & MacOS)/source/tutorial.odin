package caverace

Tutorial_Step :: enum {
	Move,
	Place_Bomb,
	Avoid_Blast,
	Collect,
	Defeat_Alien,
	Complete,
}

Tutorial_State :: struct {
	step:              Tutorial_Step,
	start_position:    Grid_Position,
	item_collected:    bool,
	treasure_collected: bool,
}

// setup_tutorial_level authors a compact single-corridor cave in memory. It
// deliberately uses the production movement, bomb, pickup, enemy and damage
// systems while remaining independent of packaged campaign files.
setup_tutorial_level :: proc(gameplay: ^Gameplay, tutorial: ^Tutorial_State) {
	init_gameplay(gameplay, gameplay.difficulty)
	gameplay.level = {}
	for y in 0 ..< MAP_HEIGHT {
		for x in 0 ..< MAP_WIDTH {
			gameplay.level.data.background[x][y] = 0
			gameplay.level.data.item[x][y] = 9
		}
	}
	for x in 1 ..< MAP_WIDTH - 1 {
		gameplay.level.data.item[x][5] = 0
	}
	gameplay.level.data.player[2][5] = PLAYER_SPAWN_MARKER
	gameplay.level.data.item[5][5] = 5
	gameplay.level.data.item[8][5] = ITEM_POWER
	gameplay.level.data.treasure[10][5] = 1
	gameplay.level.data.enemy[15][5] = 1
	setup_error := setup_level_state(gameplay)
	assert(setup_error == .None)
	gameplay.theme = .Desert
	gameplay.state = .Playing
	tutorial^ = {
		step           = .Move,
		start_position = gameplay.player.position,
	}
}

// advance_tutorial checks the current step's completion condition against
// this frame's gameplay ticks and moves to the next step once satisfied.
// Collect requires both an item and treasure before advancing; every other
// step needs only its one triggering event.
advance_tutorial :: proc(
	tutorial: ^Tutorial_State,
	gameplay: ^Gameplay,
	ticks: Gameplay_Tick_Result,
) {
	switch tutorial.step {
	case .Move:
		if gameplay.player.position != tutorial.start_position {
			tutorial.step = .Place_Bomb
		}
	case .Place_Bomb:
		if ticks.bomb_placed do tutorial.step = .Avoid_Blast
	case .Avoid_Blast:
		if ticks.explosions_started > 0 && !ticks.player_died {
			tutorial.step = .Collect
		}
	case .Collect:
		if ticks.items_collected > 0 || ticks.items_salvaged > 0 {
			tutorial.item_collected = true
		}
		if ticks.treasures_collected > 0 {
			tutorial.treasure_collected = true
		}
		if tutorial.item_collected && tutorial.treasure_collected {
			tutorial.step = .Defeat_Alien
		}
	case .Defeat_Alien:
		if ticks.enemies_destroyed > 0 do tutorial.step = .Complete
	case .Complete:
	}
}

tutorial_instruction :: proc(step: Tutorial_Step) -> cstring {
	switch step {
	case .Move:         return "MOVE ALONG THE TUNNEL"
	case .Place_Bomb:   return "PLACE A BOMB BESIDE THE SOFT STONE"
	case .Avoid_Blast:  return "STEP OUT OF THE MARKED BLAST"
	case .Collect:      return "COLLECT THE UPGRADE AND TREASURE"
	case .Defeat_Alien: return "USE A BOMB TO DRIVE OUT THE ALIEN"
	case .Complete:     return "TRAINING COMPLETE"
	}
	return ""
}
