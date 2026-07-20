package caverace

import "core:strconv"
import rl "vendor:raylib"

// These coordinates are the original CaveRace 1.3 HUD compartments baked into
// border.png. Keep gameplay information inside that lower frame so the
// 19x11 playfield remains completely unobstructed.
HUD_LIVES_X       :: 16
HUD_LIVES_Y       :: 374
HUD_LIVES_SPACING :: 20

HUD_ENERGY_X       :: 106
HUD_ENERGY_Y       :: 366
HUD_ENERGY_SPACING :: 10

HUD_BOMBS_X       :: 196
HUD_BOMBS_Y       :: 366
HUD_BOMBS_SPACING :: 12

HUD_POWER_X       :: 254
HUD_POWER_Y       :: 366
HUD_POWER_SPACING :: 16

HUD_SCORE_RIGHT     :: 446
HUD_SCORE_Y         :: 376
HUD_SCORE_FONT_SIZE :: 10

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

// draw_gameplay_hud deliberately restores the version 1.3 presentation. The
// complete modern HUD snapshot remains available to tests and other screens,
// but active play draws only the original bottom-frame icons and score.
draw_gameplay_hud :: proc(gameplay: ^Gameplay, tools: rl.Texture) {
	hud := gameplay_hud_state(gameplay)
	for icon_index in 0 ..< hud.lives {
		draw_vertical_sprite(
			tools,
			TOOLS_LIFE_SPRITE,
			i32(HUD_LIVES_X + icon_index * HUD_LIVES_SPACING),
			HUD_LIVES_Y,
		)
	}
	for icon_index in 0 ..< hud.energy {
		draw_vertical_sprite(
			tools,
			TOOLS_ENERGY_SPRITE,
			i32(HUD_ENERGY_X + icon_index * HUD_ENERGY_SPACING),
			HUD_ENERGY_Y,
		)
	}

	if gameplay.player.contact_grace_ticks > 0 || gameplay.player.blast_grace_ticks > 0 {
		pulse_ticks := max(
			gameplay.player.contact_grace_ticks,
			gameplay.player.blast_grace_ticks,
		)
		pulse_color := rl.RED
		if (pulse_ticks / 4) % 2 == 0 do pulse_color = rl.YELLOW
		rl.DrawRectangleLines(HUD_ENERGY_X - 3, HUD_ENERGY_Y - 3, 85, 37, pulse_color)
	}
	for icon_index in 0 ..< hud.available_bombs {
		draw_vertical_sprite(
			tools,
			TOOLS_BOMB_SPRITE,
			i32(HUD_BOMBS_X + icon_index * HUD_BOMBS_SPACING),
			HUD_BOMBS_Y,
		)
	}
	for icon_index in 0 ..< hud.bomb_power {
		draw_vertical_sprite(
			tools,
			TOOLS_POWER_SPRITE,
			i32(HUD_POWER_X + icon_index * HUD_POWER_SPACING),
			HUD_POWER_Y,
		)
	}

	// The original fifth compartment is retained for the live score. Using the
	// default font keeps this allocation-free and does not change score logic.
	score_buffer: [32]byte
	score_text := strconv.write_int(score_buffer[:len(score_buffer) - 1], i64(hud.score), 10)
	score_cstring := cstring(raw_data(score_text))
	score_width := rl.MeasureText(score_cstring, HUD_SCORE_FONT_SIZE)
	rl.DrawText(
		score_cstring,
		i32(HUD_SCORE_RIGHT) - score_width,
		HUD_SCORE_Y,
		HUD_SCORE_FONT_SIZE,
		rl.WHITE,
	)
}
