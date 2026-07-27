package caverace

WINDOW_WIDTH  :: 640
WINDOW_HEIGHT :: 400
WINDOW_TITLE  :: "CaveRace"

GAMEPLAY_TICK_HZ             :: 60
GAMEPLAY_TICK_SECONDS        :: 1.0 / f64(GAMEPLAY_TICK_HZ)
MAX_FRAME_DELTA_SECONDS      :: 0.25
MAX_GAMEPLAY_TICKS_PER_FRAME :: 15

TARGET_RENDER_FPS :: 60
SLOW_RENDER_FPS   :: 30

MAP_WIDTH     :: 19
MAP_HEIGHT    :: 11
MAP_TILE_SIZE :: 32
MAP_OFFSET_X  :: 16
MAP_OFFSET_Y  :: 8

// Tile_Theme is game data selected for each loaded level. The renderer maps
// the value to a texture, but simulation state does not depend on raylib.
Tile_Theme :: enum {
	Desert,
	Forest,
	Lava,
	Oil,
	Winter,
}

// Fixed content counts are shared by binary-level validation and startup asset
// validation. They describe the shipped data format rather than renderer state.
TERRAIN_SPRITE_COUNT  :: 50
ITEM_SPRITE_COUNT     :: 13
TREASURE_SPRITE_COUNT :: 7
ENEMY_SPRITE_COUNT    :: 15
PLAYER_SPRITE_COUNT   :: 17
BOMB_SPRITE_COUNT     :: 17
TOOLS_SPRITE_COUNT    :: 4

#assert(MAP_OFFSET_X * 2 + MAP_WIDTH * MAP_TILE_SIZE == WINDOW_WIDTH)
#assert(MAP_OFFSET_Y + MAP_HEIGHT * MAP_TILE_SIZE <= WINDOW_HEIGHT)
