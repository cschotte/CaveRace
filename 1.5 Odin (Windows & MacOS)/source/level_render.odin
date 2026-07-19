package caverace

import rl "vendor:raylib"

// draw_level_tiles draws only persistent map layers. Spawn grids remain part of
// the loaded file data, but runtime entities are rendered separately.
draw_level_tiles :: proc(level: ^Level, terrain: rl.Texture, sprites: ^Sprite_Assets) {
	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			screen_x, screen_y := grid_position_to_screen({grid_x, grid_y})

			draw_vertical_sprite(terrain, level.data.background[grid_x][grid_y], screen_x, screen_y)

			if tile := level.data.treasure[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.treasure, tile, screen_x, screen_y)
			}
			if tile := level.data.item[grid_x][grid_y]; tile != 0 {
				draw_vertical_sprite(sprites.objects, tile, screen_x, screen_y)
			}
		}
	}
}

draw_level_entities :: proc(gameplay: ^Gameplay, sprites: ^Sprite_Assets) {
	for &bomb in gameplay.bombs {
		if !bomb.active do continue
		screen_x, screen_y := grid_position_to_screen(bomb.position)
		draw_vertical_sprite(sprites.bomb, BOMB_TICKING_SPRITE, screen_x, screen_y)
	}

	screen_x, screen_y := player_screen_position(&gameplay.player)
	player_sprite := player_sprite_index(&gameplay.player)
	draw_vertical_sprite(sprites.player, player_sprite, screen_x, screen_y)

	for enemy_index in 0 ..< gameplay.enemy_count {
		enemy := &gameplay.enemies[enemy_index]
		if !enemy.active do continue
		screen_x, screen_y := enemy_screen_position(enemy)
		draw_vertical_sprite(sprites.enemy, enemy.kind, screen_x, screen_y)
	}

	// Explosion sprites overlay bombs and actors, matching the legacy draw order.
	for explosion_index in 0 ..< MAX_BOMBS {
		explosion := &gameplay.explosions[explosion_index]
		if !explosion.active do continue
		for cell_index in 0 ..< explosion.cell_count {
			cell := explosion.cells[cell_index]
			screen_x, screen_y := grid_position_to_screen(cell.position)
			sprite_index := explosion_sprite_index(cell.kind, explosion.age_step)
			draw_vertical_sprite(sprites.bomb, sprite_index, screen_x, screen_y)
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
