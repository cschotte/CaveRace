package caverace

import rl "vendor:raylib"

// draw_level_tiles draws only persistent map layers. Spawn grids remain part of
// the loaded file data, while active entities are rendered separately.
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

// draw_level_entities renders bombs, player, enemies, and explosion overlays in
// the legacy layer order after persistent map tiles are drawn.
draw_level_entities :: proc(gameplay: ^Gameplay, sprites: ^Sprite_Assets) {
	for &bomb in gameplay.bombs {
		preview, visible := bomb_danger_footprint(&bomb, gameplay.difficulty)
		if !visible do continue
		for cell_index in 0 ..< preview.cell_count {
			x, y := grid_position_to_screen(preview.cells[cell_index].position)
			rl.DrawRectangle(x, y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.Fade(rl.RED, 0.20))
			rl.DrawRectangleLines(x, y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.GOLD)
		}
	}

	for &bomb in gameplay.bombs {
		if !bomb.active do continue
		screen_x, screen_y := grid_position_to_screen(bomb.position)
		draw_vertical_sprite(sprites.bomb, BOMB_TICKING_SPRITE, screen_x, screen_y)
		if bomb.fuse_ticks > 0 {
			interval := bomb_tick_interval(bomb.fuse_ticks)
			if bomb.fuse_ticks % interval < interval / 2 {
				rl.DrawRectangleLines(
					screen_x + 2,
					screen_y + 2,
					MAP_TILE_SIZE - 4,
					MAP_TILE_SIZE - 4,
					rl.YELLOW,
				)
			}
		}
	}

	player_screen_x, player_screen_y := player_screen_position(&gameplay.player)
	player_sprite := player_sprite_index(&gameplay.player)
	player_visible := contact_grace_player_visible(gameplay.player.contact_grace_ticks)
	if player_visible {
		draw_vertical_sprite(sprites.player, player_sprite, player_screen_x, player_screen_y)
	}

	for &enemy in enemy_slots(gameplay) {
		if !enemy.active do continue
		enemy_screen_x, enemy_screen_y := enemy_screen_position(&enemy)
		draw_vertical_sprite(sprites.enemy, enemy.kind, enemy_screen_x, enemy_screen_y)
	}

	// Explosion sprites overlay bombs and actors, matching the legacy draw order.
	for explosion_index in 0 ..< MAX_BOMBS {
		explosion := &gameplay.explosions[explosion_index]
		if !explosion.active do continue
		for cell_index in 0 ..< explosion.cell_count {
			cell := explosion.cells[cell_index]
			explosion_screen_x, explosion_screen_y := grid_position_to_screen(cell.position)
			sprite_index := explosion_sprite_index(cell.kind, explosion.age_step)
			draw_vertical_sprite(
				sprites.bomb,
				sprite_index,
				explosion_screen_x,
				explosion_screen_y,
			)
		}
	}
}

// draw_vertical_sprite renders one row from the converted 32x32 vertical sheets;
// all level, actor, explosion, and HUD drawing shares this bounds-checked helper.
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
