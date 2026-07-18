package caverace

import rl "vendor:raylib"

PLAYER_IDLE_SPRITE :: 2

// draw_level follows the 1.3 renderer's layer order. Player and enemy map
// values are spawn data; they can be replaced by runtime entity rendering once
// movement is implemented.
draw_level :: proc(level: ^Level, terrain: rl.Texture, sprites: ^Sprite_Assets) {
	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			screen_x := i32(MAP_OFFSET_X + grid_x * MAP_TILE_SIZE)
			screen_y := i32(MAP_OFFSET_Y + grid_y * MAP_TILE_SIZE)

			draw_vertical_sprite(terrain, level.data.background[grid_x][grid_y], screen_x, screen_y)

			if tile := level.data.treasure[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.treasure, tile, screen_x, screen_y)
			}
			if tile := level.data.item[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.objects, tile, screen_x, screen_y)
			}
			if tile := level.bombs[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.bomb, tile, screen_x, screen_y)
			}

			if level.data.player[grid_x][grid_y] != 0 {
				draw_vertical_sprite(sprites.player, PLAYER_IDLE_SPRITE, screen_x, screen_y)
			}
			if tile := level.data.enemy[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.enemy, tile, screen_x, screen_y)
			}
		}
	}
}

// The converted CaveRace sprite sheets contain one 32x32 sprite per row.
draw_vertical_sprite :: proc(texture: rl.Texture, sprite_index: u8, x, y: i32) {
	index := i32(sprite_index)
	sprite_count := texture.height / MAP_TILE_SIZE
	if texture.width != MAP_TILE_SIZE || index >= sprite_count do return

	source := rl.Rectangle {
		x      = 0,
		y      = f32(index * MAP_TILE_SIZE),
		width  = MAP_TILE_SIZE,
		height = MAP_TILE_SIZE,
	}
	position := rl.Vector2 {f32(x), f32(y)}
	rl.DrawTextureRec(texture, source, position, rl.WHITE)
}
