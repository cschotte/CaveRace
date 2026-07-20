package caverace

import "core:fmt"
import rl "vendor:raylib"

DEBUG_OVERLAY_FONT_SIZE :: 10
DEBUG_OVERLAY_LINE_HEIGHT :: 12

draw_debug_line :: proc(y: i32, format: string, args: ..any) {
		buffer: [256]byte
		formatted := fmt.bprintf(buffer[:len(buffer) - 1], format, ..args)
		buffer[len(formatted)] = 0
		rl.DrawText(
			cstring(raw_data(buffer[:])),
			6,
			y,
			DEBUG_OVERLAY_FONT_SIZE,
			rl.WHITE,
		)
}

draw_debug_collision_cells :: proc(gameplay: ^Gameplay) {
		if gameplay.state != .Playing && gameplay.state != .Dead &&
		   gameplay.state != .Won {
			return
		}

		player_x, player_y := player_screen_position(&gameplay.player)
		rl.DrawRectangleLines(player_x, player_y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.YELLOW)
		target_x, target_y := grid_position_to_screen(gameplay.player.move_to)
		rl.DrawRectangleLines(target_x, target_y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.SKYBLUE)

		for bomb in gameplay.bombs {
			if !bomb.active do continue
			x, y := grid_position_to_screen(bomb.position)
			rl.DrawRectangleLines(x, y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.PURPLE)
		}
		for explosion in gameplay.explosions {
			if !explosion.active do continue
			for cell_index in 0 ..< explosion.cell_count {
				x, y := grid_position_to_screen(explosion.cells[cell_index].position)
				rl.DrawRectangleLines(x, y, MAP_TILE_SIZE, MAP_TILE_SIZE, rl.RED)
			}
		}
}

draw_debug_overlay :: proc(game: ^Game) {
		gameplay := &game.gameplay
		player_subtile := player_subtile_position(&gameplay.player)
		metadata := level_metadata(gameplay.level_index)
		tuning := gameplay_tuning(gameplay.difficulty)
		active_bombs := active_bomb_count(gameplay)

		rl.DrawRectangle(0, 0, WINDOW_WIDTH, 112, rl.Fade(rl.BLACK, 0.82))
		draw_debug_line(
			4,
			"F10 DEBUG | FPS %d | frame %.2f ms | fixed %d Hz",
			rl.GetFPS(),
			f64(rl.GetFrameTime()) * 1000,
			GAMEPLAY_TICK_HZ,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT,
			"state %v paused %v | level %d %s | seed %d",
			gameplay.state,
			game_is_paused(game),
			gameplay.level_index + 1,
			metadata.name,
			gameplay.run_seed,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 2,
			"player grid (%d,%d) subtile (%d,%d) target (%d,%d) dir %v",
			gameplay.player.position.x,
			gameplay.player.position.y,
			player_subtile.x,
			player_subtile.y,
			gameplay.player.move_to.x,
			gameplay.player.move_to.y,
			gameplay.player.direction,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 3,
			"action %d/%d accumulator %.4f | grace %d ticks",
			gameplay.tick_state.action_step,
			MOVEMENT_STEPS_PER_TILE,
			gameplay.tick_state.accumulator_seconds,
			gameplay.player.contact_grace_ticks,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 4,
			"tile %d px %.3f sec/tile | energy %d/%d grace %d ticks",
			MAP_TILE_SIZE,
			f64(MOVEMENT_STEPS_PER_TILE) / f64(GAMEPLAY_TICK_HZ),
			gameplay.player.energy,
			tuning.player_max_energy,
			gameplay.player.contact_grace_ticks,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 5,
			"aliens %d/%d | bombs %d/%d | power %d | theme %v band %v",
			active_enemy_count(gameplay),
			gameplay.enemy_count,
			active_bombs,
			gameplay.player.bomb_capacity,
			gameplay.player.bomb_power,
			metadata.theme,
			metadata.music_band,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 6,
			"fuse ticks [%d %d %d %d] | explosion ages [%d %d %d %d]",
			gameplay.bombs[0].fuse_ticks,
			gameplay.bombs[1].fuse_ticks,
			gameplay.bombs[2].fuse_ticks,
			gameplay.bombs[3].fuse_ticks,
			gameplay.explosions[0].age_step,
			gameplay.explosions[1].age_step,
			gameplay.explosions[2].age_step,
			gameplay.explosions[3].age_step,
		)
		draw_debug_line(
			4 + DEBUG_OVERLAY_LINE_HEIGHT * 7,
			"collision yellow=player cyan=target purple=bomb red=blast",
		)
		draw_debug_collision_cells(gameplay)
}
