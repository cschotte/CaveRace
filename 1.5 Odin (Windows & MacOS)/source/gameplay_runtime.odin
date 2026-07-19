package caverace

// Gameplay limits and values preserved from the 1.3 MainLoop.h constants and
// MainLoop.cpp rules. Keeping them here makes the simulation contract explicit
// as each gameplay system is added.
MAX_ENEMIES :: 16
MAX_BOMBS   :: 4

PLAYER_START_LIVES         :: 4
PLAYER_MAX_LIVES           :: 4
PLAYER_START_ENERGY        :: 8
PLAYER_MAX_ENERGY          :: 8
PLAYER_START_BOMB_CAPACITY :: 1
PLAYER_MAX_BOMB_CAPACITY   :: 4
PLAYER_START_BOMB_POWER    :: 1
PLAYER_MAX_BOMB_POWER      :: 10

ENEMY_CONTACT_DAMAGE :: 2
BOMB_FUSE_ACTIONS    :: 12
BOMB_SOUND_COUNT     :: 4

MAX_EXPLOSION_CELLS :: 1 + 4 * PLAYER_MAX_BOMB_POWER
EXPLOSION_STEPS     :: MOVEMENT_STEPS_PER_TILE

INDESTRUCTIBLE_ITEM_FIRST :: 9

EXPLOSION_SET_1_FIRST_SPRITE :: 2
EXPLOSION_SET_2_FIRST_SPRITE :: 7
EXPLOSION_SET_3_FIRST_SPRITE :: 12

WALKABLE_TERRAIN_LIMIT :: 25
PASSABLE_ITEM_LIMIT     :: 4

MOVEMENT_STEPS_PER_TILE :: 16
MOVEMENT_PIXELS_PER_STEP :: 2

SCORE_BOMB_COST       :: 5
SCORE_ITEM_PICKUP     :: 50
SCORE_ENEMY_DESTROYED :: 75
SCORE_TREASURE_PICKUP :: 100
SCORE_LEVEL_WON       :: 100
SCORE_DEATH_PENALTY   :: 50

ITEM_POWER         :: 1
ITEM_BOMB_CAPACITY :: 2
ITEM_ENERGY        :: 3
ITEM_LIFE          :: 4

TERRAIN_SPRITE_COUNT  :: 50
ITEM_SPRITE_COUNT     :: 13
TREASURE_SPRITE_COUNT :: 7
ENEMY_SPRITE_COUNT    :: 15
PLAYER_SPRITE_COUNT   :: 17
BOMB_SPRITE_COUNT     :: 17
TOOLS_SPRITE_COUNT    :: 5

PLAYER_SPAWN_MARKER :: 1
PLAYER_IDLE_SPRITE  :: 2
BOMB_TICKING_SPRITE :: 1

PLAYER_DOWN_FIRST_SPRITE     :: 1
PLAYER_UP_FIRST_SPRITE       :: 5
PLAYER_LEFT_FIRST_SPRITE     :: 9
PLAYER_RIGHT_FIRST_SPRITE    :: 13
PLAYER_DIRECTION_FRAME_COUNT :: 4

#assert(MAX_BOMBS == PLAYER_MAX_BOMB_CAPACITY)
#assert(MOVEMENT_STEPS_PER_TILE * MOVEMENT_PIXELS_PER_STEP == MAP_TILE_SIZE)
#assert(MAX_SIMULATION_STEPS_PER_FRAME < MOVEMENT_STEPS_PER_TILE)
#assert(PLAYER_IDLE_SPRITE < PLAYER_SPRITE_COUNT)
#assert(PLAYER_RIGHT_FIRST_SPRITE + PLAYER_DIRECTION_FRAME_COUNT == PLAYER_SPRITE_COUNT)
#assert(BOMB_TICKING_SPRITE < BOMB_SPRITE_COUNT)
#assert(EXPLOSION_SET_3_FIRST_SPRITE + 4 < BOMB_SPRITE_COUNT)
#assert(MAX_EXPLOSION_CELLS == 41)

Grid_Position :: struct {
	x: int,
	y: int,
}

Direction :: enum {
	None,
	Down,
	Up,
	Right,
	Left,
}

Gameplay_Action :: enum {
	None,
	Place_Bomb,
	Move_Down,
	Move_Up,
	Move_Right,
	Move_Left,
}

Gameplay_Input_Buffer :: struct {
	move_down:     bool,
	move_up:       bool,
	move_right:    bool,
	move_left:     bool,
	bomb_pending:  bool,
	cheat_pending: [Cheat_Key]bool,
}

Gameplay_Simulation_State :: struct {
	accumulator_seconds:   f64,
	action_step:           int,
	contact_damage_applied: bool,
	input:                 Gameplay_Input_Buffer,
}

Gameplay_Simulation_Result :: struct {
	steps_run:              int,
	action_decisions:       int,
	last_action:            Gameplay_Action,
	bomb_action_started:    bool,
	bomb_placed:            bool,
	bombs_expired:          int,
	ticking_requested:      bool,
	player_damaged:         bool,
	player_died:            bool,
	explosions_started:     int,
	explosion_sound_indices: [MAX_BOMBS]u8,
	explosion_sound_count:   int,
	enemies_destroyed:      int,
	squish_requests:        int,
	items_collected:        int,
	treasures_collected:    int,
	item_sound_requests:    int,
	cheat_pressed:          [Cheat_Key]bool,
}

Player_State :: struct {
	position:      Grid_Position,
	move_from:     Grid_Position,
	move_to:       Grid_Position,
	movement_step: int,
	direction:     Direction,
	lives:         int,
	energy:        int,
	bomb_capacity: int,
	bomb_power:    int,
	score:         int,
}

Enemy_State :: struct {
	active:        bool,
	kind:          u8,
	position:      Grid_Position,
	move_from:     Grid_Position,
	move_to:       Grid_Position,
	movement_step: int,
	direction:     Direction,
}

Bomb_State :: struct {
	active:       bool,
	position:     Grid_Position,
	fuse_actions: int,
	power:        int,
}

Explosion_Cell_Kind :: enum u8 {
	Center,
	Down,
	Left,
	Up,
	Right,
}

Explosion_Cell :: struct {
	position: Grid_Position,
	kind:     Explosion_Cell_Kind,
}

// One fixed explosion record belongs to each fixed bomb slot. Cells are
// computed once at detonation and then shared by effects and rendering.
Explosion_State :: struct {
	active:     bool,
	age_step:   int,
	cells:      [MAX_EXPLOSION_CELLS]Explosion_Cell,
	cell_count: int,
}

Level_Runtime_Error :: enum {
	None,
	Missing_Player,
	Multiple_Players,
	Too_Many_Enemies,
}

is_in_map :: proc(position: Grid_Position) -> bool {
	return position.x >= 0 && position.x < MAP_WIDTH &&
	       position.y >= 0 && position.y < MAP_HEIGHT
}

grid_position_to_screen :: proc(position: Grid_Position) -> (x, y: i32) {
	return i32(MAP_OFFSET_X + position.x * MAP_TILE_SIZE),
	       i32(MAP_OFFSET_Y + position.y * MAP_TILE_SIZE)
}

new_player_state :: proc() -> Player_State {
	return Player_State {
		lives         = PLAYER_START_LIVES,
		energy        = PLAYER_START_ENERGY,
		bomb_capacity = PLAYER_START_BOMB_CAPACITY,
		bomb_power    = PLAYER_START_BOMB_POWER,
	}
}

// The legacy game keeps lives and score between attempts/levels, but restores
// the per-level energy and bomb upgrades whenever the map is reloaded.
reset_player_for_level_start :: proc(player: ^Player_State) {
	player.move_from = player.position
	player.move_to = player.position
	player.movement_step = 0
	player.direction = .None
	player.energy = PLAYER_START_ENERGY
	player.bomb_capacity = PLAYER_START_BOMB_CAPACITY
	player.bomb_power = PLAYER_START_BOMB_POWER
}

buffer_gameplay_input :: proc(simulation: ^Gameplay_Simulation_State, input: Game_Input) {
	simulation.input.move_down = input.move_down
	simulation.input.move_up = input.move_up
	simulation.input.move_right = input.move_right
	simulation.input.move_left = input.move_left
	if input.space_pressed do simulation.input.bomb_pending = true

	for cheat_index in 0 ..< len(Cheat_Key) {
		cheat := Cheat_Key(cheat_index)
		if input.cheat_pressed[cheat] {
			simulation.input.cheat_pending[cheat] = true
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

advance_gameplay_simulation :: proc(
	gameplay: ^Gameplay,
	frame_seconds: f64,
	cheats_enabled := false,
) -> Gameplay_Simulation_Result {
	result: Gameplay_Simulation_Result
	simulation := &gameplay.simulation
	clamped_seconds := frame_seconds
	if clamped_seconds < 0 do clamped_seconds = 0
	if clamped_seconds > MAX_FRAME_DELTA_SECONDS {
		clamped_seconds = MAX_FRAME_DELTA_SECONDS
	}
	simulation.accumulator_seconds += clamped_seconds

	for simulation.accumulator_seconds + 1e-12 >= SIMULATION_STEP_SECONDS &&
	    result.steps_run < MAX_SIMULATION_STEPS_PER_FRAME {
		simulation.accumulator_seconds -= SIMULATION_STEP_SECONDS
		if simulation.accumulator_seconds < 0 do simulation.accumulator_seconds = 0
		result.steps_run += 1

		for cheat_index in 0 ..< len(Cheat_Key) {
			cheat := Cheat_Key(cheat_index)
			if simulation.input.cheat_pending[cheat] {
				simulation.input.cheat_pending[cheat] = false
				if cheats_enabled {
					result.cheat_pressed[cheat] = true
					apply_gameplay_cheat(gameplay, cheat)
				}
			}
		}

		if simulation.action_step == 0 {
			simulation.contact_damage_applied = false
			result.last_action = select_gameplay_action(&simulation.input)
			result.action_decisions += 1
			begin_enemy_actions(gameplay)
			begin_player_action(gameplay, result.last_action)
			if result.last_action == .Place_Bomb {
				result.bomb_action_started = true
				result.bomb_placed = try_place_bomb(gameplay)
				result.ticking_requested = result.bomb_placed
			}
			result.bombs_expired += advance_bomb_fuses(gameplay)
			start_ready_explosions(gameplay, &result)
		}

		player_was_alive := gameplay.player.energy > 0
		if !simulation.contact_damage_applied && player_touches_enemy(gameplay) {
			simulation.contact_damage_applied = true
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
			simulation.action_step + 1,
		)
		advance_enemy_action_steps(gameplay, simulation.action_step + 1)
		advance_explosion_ages(gameplay)

		if simulation.action_step + 1 == MOVEMENT_STEPS_PER_TILE {
			pickup := collect_player_cell(gameplay)
			if pickup.item_collected do result.items_collected += 1
			if pickup.treasure_collected do result.treasures_collected += 1
			if pickup.item_collected || pickup.treasure_collected {
				result.item_sound_requests += 1
			}
			apply_score_event(&gameplay.player, .Action_Floor)
		}

		simulation.action_step =
			(simulation.action_step + 1) % MOVEMENT_STEPS_PER_TILE
	}

	return result
}

// initialize_level_runtime converts immutable map spawn markers into mutable,
// fixed-capacity gameplay state. It validates into locals first, so failure
// never leaves a partly initialized session behind.
initialize_level_runtime :: proc(gameplay: ^Gameplay) -> Level_Runtime_Error {
	player_position: Grid_Position
	player_count := 0
	enemies: [MAX_ENEMIES]Enemy_State
	enemy_count := 0

	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			if gameplay.level.data.player[grid_x][grid_y] == PLAYER_SPAWN_MARKER {
				player_count += 1
				if player_count > 1 do return .Multiple_Players
				player_position = {grid_x, grid_y}
			}

			if kind := gameplay.level.data.enemy[grid_x][grid_y]; kind != 0 {
				if enemy_count >= MAX_ENEMIES do return .Too_Many_Enemies
				enemies[enemy_count] = Enemy_State {
					active    = true,
					kind      = kind,
					position  = {grid_x, grid_y},
					move_from = {grid_x, grid_y},
					move_to   = {grid_x, grid_y},
				}
				enemy_count += 1
			}
		}
	}

	if player_count == 0 do return .Missing_Player

	gameplay.player.position = player_position
	gameplay.player.move_from = player_position
	gameplay.player.move_to = player_position
	gameplay.player.movement_step = 0
	gameplay.player.direction = .None
	gameplay.enemies = enemies
	gameplay.enemy_count = enemy_count
	gameplay.bombs = {}
	gameplay.explosions = {}
	gameplay.bomb_occupancy = {}
	gameplay.simulation = {}
	gameplay.runtime_initialized = true
	return .None
}
