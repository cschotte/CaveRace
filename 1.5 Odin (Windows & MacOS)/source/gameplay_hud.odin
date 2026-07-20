package caverace

import "core:fmt"
import rl "vendor:raylib"

TOOLS_LIFE_SPRITE   :: 0
TOOLS_ENERGY_SPRITE :: 1
TOOLS_POWER_SPRITE  :: 2
TOOLS_BOMB_SPRITE   :: 3

#assert(TOOLS_LIFE_SPRITE < TOOLS_SPRITE_COUNT)
#assert(TOOLS_ENERGY_SPRITE < TOOLS_SPRITE_COUNT)
#assert(TOOLS_POWER_SPRITE < TOOLS_SPRITE_COUNT)
#assert(TOOLS_BOMB_SPRITE < TOOLS_SPRITE_COUNT)

Gameplay_Hud_State :: struct {
	level:            int,
	aliens_remaining: int,
	treasure_collected: int,
	treasure_total:     int,
	lives:              int,
	energy:             int,
	max_energy:         int,
	available_bombs:    int,
	bomb_capacity:      int,
	bomb_power:         int,
	score:              int,
}

gameplay_hud_state :: proc(gameplay: ^Gameplay) -> Gameplay_Hud_State {
	tuning := gameplay_tuning(gameplay.difficulty)
	return {
		level              = gameplay.level_index + 1,
		aliens_remaining   = active_enemy_count(gameplay),
		treasure_collected = gameplay.treasure_collected,
		treasure_total     = gameplay.treasure_total,
		lives              = gameplay.player.lives,
		energy             = gameplay.player.energy,
		max_energy         = tuning.player_max_energy,
		available_bombs    = available_bomb_count(gameplay),
		bomb_capacity      = gameplay.player.bomb_capacity,
		bomb_power         = gameplay.player.bomb_power,
		score              = gameplay.player.score,
	}
}

draw_hud_text :: proc(x, y, size: i32, format: string, args: ..any) {
	buffer: [128]byte
	formatted := fmt.bprintf(buffer[:len(buffer) - 1], format, ..args)
	buffer[len(formatted)] = 0
	rl.DrawText(cstring(raw_data(buffer[:])), x, y, size, rl.WHITE)
}

draw_gameplay_hud :: proc(gameplay: ^Gameplay, tools: rl.Texture) {
	hud := gameplay_hud_state(gameplay)
	rl.DrawRectangle(8, 5, 624, 25, rl.Fade(rl.BLACK, 0.78))
	rl.DrawRectangleLines(8, 5, 624, 25, rl.Fade(rl.GOLD, 0.85))
	draw_hud_text(
		18,
		9,
		16,
		"CAVE %d     ALIENS %d     TREASURE %d/%d",
		hud.level,
		hud.aliens_remaining,
		hud.treasure_collected,
		hud.treasure_total,
	)

	box_y: i32 = 362
	rl.DrawRectangle(8, box_y, 624, 34, rl.Fade(rl.BLACK, 0.9))
	draw_vertical_sprite(tools, TOOLS_LIFE_SPRITE, 12, box_y + 1)
	draw_hud_text(44, box_y + 9, 16, "x%d", hud.lives)
	draw_vertical_sprite(tools, TOOLS_ENERGY_SPRITE, 84, box_y + 1)
	draw_hud_text(116, box_y + 9, 16, "%d/%d", hud.energy, hud.max_energy)
	draw_vertical_sprite(tools, TOOLS_BOMB_SPRITE, 178, box_y + 1)
	draw_hud_text(210, box_y + 9, 16, "%d/%d", hud.available_bombs, hud.bomb_capacity)
	draw_vertical_sprite(tools, TOOLS_POWER_SPRITE, 276, box_y + 1)
	draw_hud_text(308, box_y + 9, 16, "x%d", hud.bomb_power)
	draw_hud_text(378, box_y + 9, 16, "SCORE %06d", hud.score)

	if gameplay.player.contact_grace_ticks > 0 || gameplay.player.blast_grace_ticks > 0 {
		pulse_ticks := max(
			gameplay.player.contact_grace_ticks,
			gameplay.player.blast_grace_ticks,
		)
		pulse_color := rl.RED
		if (pulse_ticks / 4) % 2 == 0 do pulse_color = rl.YELLOW
		rl.DrawRectangleLines(81, box_y, 94, 34, pulse_color)
	}
}
