package caverace

// Difficulty_Profile separates the legacy-compatible and assisted rules
// Standard campaign and the more forgiving Assisted campaign.
Difficulty_Profile :: enum {
	Standard,
	Assisted,
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

ENEMY_CONTACT_DAMAGE       :: 2
CONTACT_GRACE_TICKS        :: 45
BOMB_FUSE_TICKS            :: 180
BOMB_DANGER_PREVIEW_TICKS  :: 36

WALKABLE_TERRAIN_LIMIT :: 25
PASSABLE_ITEM_LIMIT     :: 4

// The 12-tick Standard cadence is the selected Milestone 2 response target:
// one tile in 0.20 seconds at the fixed 60 Hz simulation rate.
MOVEMENT_STEPS_PER_TILE :: 12

SCORE_BOMB_COST       :: 0
SCORE_ITEM_PICKUP     :: 50
SCORE_CAPPED_ITEM_SALVAGE :: 25
SCORE_ENEMY_DESTROYED :: 75
SCORE_TREASURE_PICKUP :: 100
SCORE_LEVEL_WON       :: 100
SCORE_ALL_TREASURE    :: 250
SCORE_NO_DAMAGE       :: 200
SCORE_UNDER_PAR       :: 150
SCORE_DEATH_PENALTY   :: 0

Gameplay_Tuning :: struct {
	player_start_lives:         int,
	player_max_lives:           int,
	player_start_energy:        int,
	player_max_energy:          int,
	player_start_bomb_capacity: int,
	player_max_bomb_capacity:   int,
	player_start_bomb_power:    int,
	player_max_bomb_power:      int,
	movement_ticks_per_tile:    int,
	enemy_contact_damage:       int,
	contact_grace_ticks:        int,
	blast_damage:               int,
	blast_grace_ticks:          int,
	bomb_fuse_ticks:            int,
	bomb_danger_preview_ticks:  int,
	score_bomb_cost:            int,
	score_item_pickup:          int,
	score_capped_item_salvage:  int,
	score_enemy_destroyed:      int,
	score_treasure_pickup:      int,
	score_level_won:            int,
	score_all_treasure:         int,
	score_no_damage:            int,
	score_under_par:            int,
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
		movement_ticks_per_tile    = MOVEMENT_STEPS_PER_TILE,
		enemy_contact_damage       = ENEMY_CONTACT_DAMAGE,
		contact_grace_ticks        = CONTACT_GRACE_TICKS,
		blast_damage               = PLAYER_MAX_ENERGY,
		blast_grace_ticks          = 0,
		bomb_fuse_ticks            = BOMB_FUSE_TICKS,
		bomb_danger_preview_ticks  = BOMB_DANGER_PREVIEW_TICKS,
		score_bomb_cost            = SCORE_BOMB_COST,
		score_item_pickup          = SCORE_ITEM_PICKUP,
		score_capped_item_salvage  = SCORE_CAPPED_ITEM_SALVAGE,
		score_enemy_destroyed      = SCORE_ENEMY_DESTROYED,
		score_treasure_pickup      = SCORE_TREASURE_PICKUP,
		score_level_won            = SCORE_LEVEL_WON,
		score_all_treasure         = SCORE_ALL_TREASURE,
		score_no_damage            = SCORE_NO_DAMAGE,
		score_under_par            = SCORE_UNDER_PAR,
		score_death_penalty        = SCORE_DEATH_PENALTY,
	},
	.Assisted = {
		player_start_lives         = PLAYER_START_LIVES,
		player_max_lives           = PLAYER_MAX_LIVES,
		player_start_energy        = PLAYER_START_ENERGY,
		player_max_energy          = PLAYER_MAX_ENERGY,
		player_start_bomb_capacity = PLAYER_START_BOMB_CAPACITY,
		player_max_bomb_capacity   = PLAYER_MAX_BOMB_CAPACITY,
		player_start_bomb_power    = PLAYER_START_BOMB_POWER,
		player_max_bomb_power      = PLAYER_MAX_BOMB_POWER,
		movement_ticks_per_tile    = MOVEMENT_STEPS_PER_TILE,
		enemy_contact_damage       = 1,
		contact_grace_ticks        = 60,
		blast_damage               = 4,
		blast_grace_ticks          = 60,
		bomb_fuse_ticks            = BOMB_FUSE_TICKS,
		bomb_danger_preview_ticks  = BOMB_FUSE_TICKS,
		score_bomb_cost            = SCORE_BOMB_COST,
		score_item_pickup          = SCORE_ITEM_PICKUP,
		score_capped_item_salvage  = SCORE_CAPPED_ITEM_SALVAGE,
		score_enemy_destroyed      = SCORE_ENEMY_DESTROYED,
		score_treasure_pickup      = SCORE_TREASURE_PICKUP,
		score_level_won            = SCORE_LEVEL_WON,
		score_all_treasure         = SCORE_ALL_TREASURE,
		score_no_damage            = SCORE_NO_DAMAGE,
		score_under_par            = SCORE_UNDER_PAR,
		score_death_penalty        = SCORE_DEATH_PENALTY,
	},
}

gameplay_tuning :: proc(difficulty: Difficulty_Profile) -> Gameplay_Tuning {
	profiles := GAMEPLAY_TUNING
	return profiles[difficulty]
}
