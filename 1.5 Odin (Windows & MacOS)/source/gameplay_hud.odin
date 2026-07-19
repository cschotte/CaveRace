package caverace

import "core:strconv"
import rl "vendor:raylib"

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

// Gameplay_Hud_State is a render-only snapshot derived from player and bomb
// state so HUD layout code cannot mutate gameplay.
Gameplay_Hud_State :: struct {
	lives:           int,
	energy:          int,
	available_bombs: int,
	bomb_power:      int,
	score:           int,
}

// gameplay_hud_state takes a read-only snapshot of the player values needed by
// the HUD, keeping layout code independent of gameplay mutation.
gameplay_hud_state :: proc(gameplay: ^Gameplay) -> Gameplay_Hud_State {
	return {
		lives           = gameplay.player.lives,
		energy          = gameplay.player.energy,
		available_bombs = available_bomb_count(gameplay),
		bomb_power      = gameplay.player.bomb_power,
		score           = gameplay.player.score,
	}
}

// draw_gameplay_hud renders legacy status icons and score after the level and
// actors have been drawn for an active gameplay screen.
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

	// The target uses raylib's allocation-free default font in the original
	// score box; the final byte stays zero for the C API.
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
