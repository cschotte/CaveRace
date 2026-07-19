package caverace

import "core:math/rand"

// Fixed gameplay capacities and legacy rule values. Runtime storage is kept
// inline and bounded so ownership and memory use remain visible in Gameplay.
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

MOVEMENT_STEPS_PER_TILE  :: 16
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
	accumulator_seconds:    f64,
	action_step:            int,
	contact_damage_applied: bool,
	input:                  Gameplay_Input_Buffer,
}

Gameplay_Simulation_Result :: struct {
	steps_run:               int,
	action_decisions:        int,
	last_action:             Gameplay_Action,
	bomb_action_started:     bool,
	bomb_placed:             bool,
	bombs_expired:           int,
	ticking_requested:       bool,
	player_damaged:          bool,
	player_died:             bool,
	explosions_started:      int,
	explosion_sound_indices: [MAX_BOMBS]u8,
	explosion_sound_count:   int,
	enemies_destroyed:       int,
	squish_requests:         int,
	items_collected:         int,
	treasures_collected:     int,
	item_sound_requests:     int,
	cheat_pressed:           [Cheat_Key]bool,
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

// Gameplay_State describes the lifecycle within the Playing screen.
Gameplay_State :: enum {
	Load_Level,
	Playing,
	Dead,
	Won,
	Game_Over,
	Load_Failed,
}

Gameplay :: struct {
	state:                    Gameplay_State,
	level:                    Level,
	level_index:              int,
	theme:                    Tile_Theme,
	player:                   Player_State,
	enemies:                  [MAX_ENEMIES]Enemy_State,
	enemy_count:              int,
	bombs:                    [MAX_BOMBS]Bomb_State,
	explosions:               [MAX_BOMBS]Explosion_State,
	bomb_occupancy:           Map_Grid,
	simulation:               Gameplay_Simulation_State,
	random_state:             rand.Xoshiro256_Random_State,
	// Enabled only after a validated level has supplied its enemy objective.
	level_completion_enabled: bool,
}

Completed_Run :: struct {
	score: int,
}

Gameplay_Frame_Result :: struct {
	back_requested: bool,
	simulation:     Gameplay_Simulation_Result,
	completed_run:  Maybe(Completed_Run),
}

init_gameplay :: proc(gameplay: ^Gameplay) {
	gameplay^ = Gameplay {
		state  = .Load_Level,
		player = new_player_state(),
	}
	seed_gameplay_random(gameplay, rand.uint64())
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
