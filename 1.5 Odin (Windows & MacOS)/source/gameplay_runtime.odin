package caverace

// Gameplay limits and values preserved from the 1.3 MainLoop.h constants and
// MainLoop.cpp rules. Keeping them here makes the simulation contract explicit
// before movement and bombs are added.
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

#assert(MAX_BOMBS == PLAYER_MAX_BOMB_CAPACITY)
#assert(MOVEMENT_STEPS_PER_TILE * MOVEMENT_PIXELS_PER_STEP == MAP_TILE_SIZE)
#assert(PLAYER_IDLE_SPRITE < PLAYER_SPRITE_COUNT)
#assert(BOMB_TICKING_SPRITE < BOMB_SPRITE_COUNT)

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

Player_State :: struct {
	position:      Grid_Position,
	direction:     Direction,
	lives:         int,
	energy:        int,
	bomb_capacity: int,
	bomb_power:    int,
	score:         int,
}

Enemy_State :: struct {
	active:    bool,
	kind:      u8,
	position:  Grid_Position,
	direction: Direction,
}

Bomb_State :: struct {
	active:       bool,
	position:     Grid_Position,
	fuse_actions: int,
	power:        int,
}

Level_Runtime_Error :: enum {
	None,
	Missing_Player,
	Multiple_Players,
	Too_Many_Enemies,
}

grid_position_is_valid :: proc(position: Grid_Position) -> bool {
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
	player.direction = .None
	player.energy = PLAYER_START_ENERGY
	player.bomb_capacity = PLAYER_START_BOMB_CAPACITY
	player.bomb_power = PLAYER_START_BOMB_POWER
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
					active   = true,
					kind     = kind,
					position = {grid_x, grid_y},
				}
				enemy_count += 1
			}
		}
	}

	if player_count == 0 do return .Missing_Player

	gameplay.player.position = player_position
	gameplay.player.direction = .None
	gameplay.enemies = enemies
	gameplay.enemy_count = enemy_count
	gameplay.bombs = {}
	gameplay.bomb_occupancy = {}
	return .None
}
