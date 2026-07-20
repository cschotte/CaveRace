package caverace

// Difficulty_Profile is explicit from Milestone 1 onward even though the
// shipped rules remain the single legacy-compatible Standard profile.
Difficulty_Profile :: enum {
	Standard,
}

// Compile-time capacities and movement relationships remain named constants
// for fixed arrays and assertions. All player-facing tuneables live together
// in this module and are mirrored by Gameplay_Tuning for profile-driven rules.
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

MOVEMENT_STEPS_PER_TILE  :: 16
MOVEMENT_PIXELS_PER_STEP :: 2

SCORE_BOMB_COST       :: 5
SCORE_ITEM_PICKUP     :: 50
SCORE_ENEMY_DESTROYED :: 75
SCORE_TREASURE_PICKUP :: 100
SCORE_LEVEL_WON       :: 100
SCORE_DEATH_PENALTY   :: 50

Gameplay_Tuning :: struct {
	player_start_lives:         int,
	player_max_lives:           int,
	player_start_energy:        int,
	player_max_energy:          int,
	player_start_bomb_capacity: int,
	player_max_bomb_capacity:   int,
	player_start_bomb_power:    int,
	player_max_bomb_power:      int,
	enemy_contact_damage:       int,
	bomb_fuse_actions:          int,
	score_bomb_cost:            int,
	score_item_pickup:          int,
	score_enemy_destroyed:      int,
	score_treasure_pickup:      int,
	score_level_won:            int,
	score_death_penalty:        int,
}

GAMEPLAY_TUNING :: [Difficulty_Profile]Gameplay_Tuning {
	.Standard = {
		player_start_lives         = PLAYER_START_LIVES,
		player_max_lives           = PLAYER_MAX_LIVES,
		player_start_energy        = PLAYER_START_ENERGY,
		player_max_energy          = PLAYER_MAX_ENERGY,
		player_start_bomb_capacity = PLAYER_START_BOMB_CAPACITY,
		player_max_bomb_capacity   = PLAYER_MAX_BOMB_CAPACITY,
		player_start_bomb_power    = PLAYER_START_BOMB_POWER,
		player_max_bomb_power      = PLAYER_MAX_BOMB_POWER,
		enemy_contact_damage       = ENEMY_CONTACT_DAMAGE,
		bomb_fuse_actions          = BOMB_FUSE_ACTIONS,
		score_bomb_cost            = SCORE_BOMB_COST,
		score_item_pickup          = SCORE_ITEM_PICKUP,
		score_enemy_destroyed      = SCORE_ENEMY_DESTROYED,
		score_treasure_pickup      = SCORE_TREASURE_PICKUP,
		score_level_won            = SCORE_LEVEL_WON,
		score_death_penalty        = SCORE_DEATH_PENALTY,
	},
}

gameplay_tuning :: proc(difficulty: Difficulty_Profile) -> Gameplay_Tuning {
	profiles := GAMEPLAY_TUNING
	return profiles[difficulty]
}
