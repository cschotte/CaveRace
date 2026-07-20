package caverace

import "core:math/rand"

// Fixed gameplay capacities. Active state is kept inline and bounded so
// ownership and memory use remain visible in Gameplay; tuneables are centralized
// in tuning.odin.
MAX_ENEMIES :: 16
MAX_BOMBS   :: 4
BOMB_SOUND_COUNT     :: 4

MAX_EXPLOSION_CELLS :: 1 + 4 * PLAYER_MAX_BOMB_POWER
EXPLOSION_STEPS     :: 12

INDESTRUCTIBLE_ITEM_FIRST :: 9

EXPLOSION_SET_1_FIRST_SPRITE :: 2
EXPLOSION_SET_2_FIRST_SPRITE :: 7
EXPLOSION_SET_3_FIRST_SPRITE :: 12

ITEM_POWER         :: 1
ITEM_BOMB_CAPACITY :: 2
ITEM_ENERGY        :: 3
ITEM_LIFE          :: 4

PLAYER_SPAWN_MARKER :: 1
PLAYER_IDLE_SPRITE  :: 2
BOMB_TICKING_SPRITE :: 1

PLAYER_DOWN_FIRST_SPRITE     :: 1
PLAYER_UP_FIRST_SPRITE       :: 5
PLAYER_LEFT_FIRST_SPRITE     :: 9
PLAYER_RIGHT_FIRST_SPRITE    :: 13
PLAYER_DIRECTION_FRAME_COUNT :: 4

#assert(MAX_BOMBS == PLAYER_MAX_BOMB_CAPACITY)
#assert(MAX_GAMEPLAY_TICKS_PER_FRAME >= MOVEMENT_STEPS_PER_TILE)
#assert(PLAYER_IDLE_SPRITE < PLAYER_SPRITE_COUNT)
#assert(PLAYER_RIGHT_FIRST_SPRITE + PLAYER_DIRECTION_FRAME_COUNT == PLAYER_SPRITE_COUNT)
#assert(BOMB_TICKING_SPRITE < BOMB_SPRITE_COUNT)
#assert(EXPLOSION_SET_3_FIRST_SPRITE + 4 < BOMB_SPRITE_COUNT)
#assert(MAX_EXPLOSION_CELLS == 41)

// Grid_Position stores integer map coordinates used by level data, movement,
// occupancy, collisions, and rendering conversions.
Grid_Position :: struct {
	x: int,
	y: int,
}

// Direction represents cardinal actor facing and movement, with None used for
// idle or non-movement actions.
Direction :: enum {
	None,
	Down,
	Up,
	Right,
	Left,
}

// Gameplay_Action is the movement command selected at each action boundary.
// Bomb placement is an independent latched edge and never consumes movement.
Gameplay_Action :: enum {
	None,
	Move_Down,
	Move_Up,
	Move_Right,
	Move_Left,
}

// Gameplay_Input_Buffer keeps held directions and latched edge-triggered actions
// until the fixed gameplay clock reaches a safe consumption point.
Gameplay_Input_Buffer :: struct {
	move_down:     bool,
	move_up:       bool,
	move_right:    bool,
	move_left:     bool,
	bomb_pending:  bool,
	cheat_pending: [Cheat_Key]bool,
}

// Gameplay_Tick_State persists the fixed-clock accumulator, current action
// progress and queued input across render frames.
Gameplay_Tick_State :: struct {
	accumulator_seconds:    f64,
	action_step:            int,
	input:                  Gameplay_Input_Buffer,
}

// Gameplay_Tick_Result aggregates diagnostics and transient gameplay events from
// all fixed ticks processed during one render-frame update.
Gameplay_Tick_Result :: struct {
	ticks_run:               int,
	action_decisions:        int,
	last_action:             Gameplay_Action,
	bomb_action_started:     bool,
	bomb_placed:             bool,
	bombs_expired:           int,
	ticking_requests:        int,
	contact_hit_requests:    int,
	player_damaged:          bool,
	player_died:             bool,
	explosions_started:      int,
	explosion_positions:     [MAX_BOMBS]Grid_Position,
	explosion_sound_indices: [MAX_BOMBS]u8,
	explosion_sound_count:   int,
	enemies_destroyed:       int,
	enemy_destroyed_positions: [MAX_ENEMIES]Grid_Position,
	squish_requests:         int,
	items_collected:         int,
	items_salvaged:          int,
	treasures_collected:     int,
	item_sound_requests:     int,
	cheat_pressed:           [Cheat_Key]bool,
}

// Player_State owns run-wide resources together with current level position,
// interpolation, facing, upgrades, and score.
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
	contact_grace_ticks: int,
	blast_grace_ticks:   int,
}

// Enemy_State represents one fixed enemy slot, including activity, sprite kind,
// and the interpolation endpoints for its current movement action.
Enemy_State :: struct {
	active:        bool,
	kind:          u8,
	position:      Grid_Position,
	move_from:     Grid_Position,
	move_to:       Grid_Position,
	movement_step: int,
	direction:     Direction,
}

// Bomb_State represents one fixed bomb slot from placement through fuse expiry;
// its array index also owns the corresponding explosion slot.
Bomb_State :: struct {
	active:       bool,
	position:     Grid_Position,
	fuse_ticks:   int,
	power:        int,
}

// Explosion_Cell_Kind selects the directional sprite variant used for one cell
// of a precomputed blast footprint.
Explosion_Cell_Kind :: enum u8 {
	Center,
	Down,
	Left,
	Up,
	Right,
}

// Explosion_Cell pairs one affected map position with its directional rendering
// role inside an Explosion_State footprint.
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

// Level_Setup_Error describes spawn-data failures detected before loaded map
// data may become active mutable gameplay state.
Level_Setup_Error :: enum {
	None,
	Missing_Player,
	Multiple_Players,
	Too_Many_Enemies,
}

// Gameplay_State describes the lifecycle within the Playing screen and selects
// the update, loading, message, and transition behavior used each frame.
Gameplay_State :: enum {
	Load_Level,
	Playing,
	Dead,
	Won,
	Game_Won,
	Game_Over,
	Load_Failed,
}

// Gameplay owns one complete run: lifecycle state, loaded level, player progress,
// bounded active entities, fixed clock, and session random generator.
Gameplay :: struct {
	state:                    Gameplay_State,
	mode:                     Run_Mode,
	difficulty:               Difficulty_Profile,
	level:                    Level,
	level_index:              int,
	theme:                    Tile_Theme,
	player:                   Player_State,
	enemies:                  [MAX_ENEMIES]Enemy_State,
	enemy_count:              int,
	initial_enemy_count:      int,
	treasure_total:           int,
	treasure_collected:       int,
	run_stats:                Run_Stats,
	level_stats:              Level_Stats,
	level_result:             Level_Result,
	level_tracking_active:    bool,
	run_record_submitted:     bool,
	bombs:                    [MAX_BOMBS]Bomb_State,
	explosions:               [MAX_BOMBS]Explosion_State,
	bomb_occupancy:           Map_Grid,
	tick_state:               Gameplay_Tick_State,
	run_seed:                 u64,
	ai_random_state:          rand.Xoshiro256_Random_State,
	cosmetic_random_state:    rand.Xoshiro256_Random_State,
	// Enabled only after a validated level has supplied its enemy objective.
	level_completion_enabled: bool,
}

// Gameplay_Frame_Result returns screen-routing requests and fixed-tick events
// from update_gameplay.
Gameplay_Frame_Result :: struct {
	back_requested: bool,
	practice_exit_requested: bool,
	ticks:          Gameplay_Tick_Result,
}

// init_gameplay creates a fresh run with default player resources and a new
// random seed; Game calls it at application startup and for Start Game.
init_gameplay :: proc(
	gameplay: ^Gameplay,
	difficulty: Difficulty_Profile = .Standard,
) {
	gameplay^ = Gameplay {
		state      = .Load_Level,
		mode       = .Campaign,
		difficulty = difficulty,
		player     = new_player_state(difficulty),
	}
	seed_gameplay_random(gameplay, rand.uint64())
}

// is_in_map validates grid coordinates before any fixed map array is indexed.
is_in_map :: proc(position: Grid_Position) -> bool {
	return position.x >= 0 && position.x < MAP_WIDTH &&
	       position.y >= 0 && position.y < MAP_HEIGHT
}

// grid_position_to_screen converts a valid map cell origin to its fixed pixel
// position for movement interpolation and rendering.
grid_position_to_screen :: proc(position: Grid_Position) -> (x, y: i32) {
	return i32(MAP_OFFSET_X + position.x * MAP_TILE_SIZE),
	       i32(MAP_OFFSET_Y + position.y * MAP_TILE_SIZE)
}

// new_player_state returns the run-wide defaults used whenever a new game is
// initialized before the first level is loaded.
new_player_state :: proc(
	difficulty: Difficulty_Profile = .Standard,
) -> Player_State {
	tuning := gameplay_tuning(difficulty)
	return Player_State {
		lives         = tuning.player_start_lives,
		energy        = tuning.player_start_energy,
		bomb_capacity = tuning.player_start_bomb_capacity,
		bomb_power    = tuning.player_start_bomb_power,
	}
}

// reset_player_for_level_start preserves run-wide lives and score while
// restoring energy and base upgrades for Standard's death retry rule.
reset_player_for_level_start :: proc(
	player: ^Player_State,
	difficulty: Difficulty_Profile = .Standard,
) {
	tuning := gameplay_tuning(difficulty)
	player.move_from = player.position
	player.move_to = player.position
	player.movement_step = 0
	player.direction = .None
	player.contact_grace_ticks = 0
	player.blast_grace_ticks = 0
	player.energy = tuning.player_start_energy
	player.bomb_capacity = tuning.player_start_bomb_capacity
	player.bomb_power = tuning.player_start_bomb_power
}
