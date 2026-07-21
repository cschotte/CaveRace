package caverace

import rl "vendor:raylib"

MAX_EFFECT_PARTICLES :: 64
MAX_SCORE_POPUPS     :: 8

TREASURE_TOAST_SECONDS      :: 2.2
TREASURE_TOAST_FADE_SECONDS :: 0.35

Effect_Kind :: enum {
	Explosion,
	Damage,
	Pickup,
	Treasure,
	Victory,
}

Effect_Particle :: struct {
	active:            bool,
	x, y:              f32,
	velocity_x:        f32,
	velocity_y:        f32,
	remaining_seconds: f64,
	duration_seconds:  f64,
	kind:              Effect_Kind,
}

Score_Popup :: struct {
	active:            bool,
	x, y:              f32,
	points:            int,
	remaining_seconds: f64,
}

// Game_Effects is fixed-capacity presentation state. It never owns gameplay
// outcomes and may advance or be dropped without changing simulation state.
Game_Effects :: struct {
	particles: [MAX_EFFECT_PARTICLES]Effect_Particle,
	popups:    [MAX_SCORE_POPUPS]Score_Popup,
	// A one-shot "TREASURE x/y" readout so a pickup's progress toward the
	// cave's total is legible without a permanent HUD counter.
	treasure_toast_remaining: f64,
	treasure_toast_collected: int,
	treasure_toast_total:     int,
}

// effect_particle_slot returns a free slot, or the slot nearest expiry if the
// fixed pool is full, so a burst never allocates and never drops the newest
// particle in favor of one about to disappear anyway.
effect_particle_slot :: proc(effects: ^Game_Effects) -> ^Effect_Particle {
	oldest_index := 0
	oldest_remaining := effects.particles[0].remaining_seconds
	for &particle, index in effects.particles {
		if !particle.active do return &particle
		if particle.remaining_seconds < oldest_remaining {
			oldest_index = index
			oldest_remaining = particle.remaining_seconds
		}
	}
	return &effects.particles[oldest_index]
}

// score_popup_slot mirrors effect_particle_slot's recycle-oldest behavior for
// the separate, smaller popup pool.
score_popup_slot :: proc(effects: ^Game_Effects) -> ^Score_Popup {
	oldest_index := 0
	oldest_remaining := effects.popups[0].remaining_seconds
	for &popup, index in effects.popups {
		if !popup.active do return &popup
		if popup.remaining_seconds < oldest_remaining {
			oldest_index = index
			oldest_remaining = popup.remaining_seconds
		}
	}
	return &effects.popups[oldest_index]
}

// spawn_effect_burst fills count particle slots with randomized velocity and
// lifetime, drawing only from the cosmetic RNG stream so purely visual
// variation can never influence deterministic gameplay.
spawn_effect_burst :: proc(
	effects: ^Game_Effects,
	gameplay: ^Gameplay,
	x, y: f32,
	count: int,
	kind: Effect_Kind,
) {
	for _ in 0 ..< count {
		particle := effect_particle_slot(effects)
		direction_x := gameplay_cosmetic_random_max(gameplay, 201) - 100
		direction_y := gameplay_cosmetic_random_max(gameplay, 161) - 120
		duration := 0.35 + f64(gameplay_cosmetic_random_max(gameplay, 31)) / 100
		particle^ = {
			active            = true,
			x                 = x,
			y                 = y,
			velocity_x        = f32(direction_x) * 0.45,
			velocity_y        = f32(direction_y) * 0.45,
			remaining_seconds = duration,
			duration_seconds  = duration,
			kind              = kind,
		}
	}
}

spawn_grid_effect_burst :: proc(
	effects: ^Game_Effects,
	gameplay: ^Gameplay,
	position: Grid_Position,
	count: int,
	kind: Effect_Kind,
) {
	x, y := grid_position_to_screen(position)
	spawn_effect_burst(
		effects,
		gameplay,
		f32(x + MAP_TILE_SIZE / 2),
		f32(y + MAP_TILE_SIZE / 2),
		count,
		kind,
	)
}

spawn_score_popup :: proc(
	effects: ^Game_Effects,
	position: Grid_Position,
	points: int,
) {
	if points <= 0 do return
	x, y := grid_position_to_screen(position)
	popup := score_popup_slot(effects)
	popup^ = {
		active            = true,
		x                 = f32(x + 4),
		y                 = f32(y - 2),
		points            = points,
		remaining_seconds = 0.8,
	}
}

// request_game_effects translates committed gameplay events into bounded
// cosmetic state using only the separate cosmetic RNG stream.
request_game_effects :: proc(
	effects: ^Game_Effects,
	gameplay: ^Gameplay,
	ticks: ^Gameplay_Tick_Result,
	victory_started: bool,
	reduced_flashes: bool,
) {
	burst_scale := 1
	if reduced_flashes do burst_scale = 2
	for index in 0 ..< ticks.explosions_started {
		spawn_grid_effect_burst(
			effects,
			gameplay,
			ticks.explosion_positions[index],
			8 / burst_scale,
			.Explosion,
		)
	}
	for index in 0 ..< ticks.enemies_destroyed {
		spawn_grid_effect_burst(
			effects,
			gameplay,
			ticks.enemy_destroyed_positions[index],
			5 / burst_scale,
			.Explosion,
		)
	}
	if ticks.player_damaged {
		spawn_grid_effect_burst(
			effects,
			gameplay,
			gameplay.player.position,
			10 / burst_scale,
			.Damage,
		)
	}
	if ticks.items_collected > 0 || ticks.items_salvaged > 0 {
		spawn_grid_effect_burst(
			effects,
			gameplay,
			gameplay.player.position,
			6 / burst_scale,
			.Pickup,
		)
	}
	if ticks.treasures_collected > 0 {
		spawn_grid_effect_burst(
			effects,
			gameplay,
			gameplay.player.position,
			8 / burst_scale,
			.Treasure,
		)
		effects.treasure_toast_remaining = TREASURE_TOAST_SECONDS
		effects.treasure_toast_collected = gameplay.treasure_collected
		effects.treasure_toast_total = gameplay.treasure_total
	}

	tuning := gameplay_tuning(gameplay.difficulty)
	spawn_score_popup(
		effects,
		gameplay.player.position,
		ticks.items_collected * tuning.score_item_pickup +
			ticks.items_salvaged * tuning.score_capped_item_salvage,
	)
	spawn_score_popup(
		effects,
		gameplay.player.position,
		ticks.treasures_collected * tuning.score_treasure_pickup,
	)
	for index in 0 ..< ticks.enemies_destroyed {
		spawn_score_popup(
			effects,
			ticks.enemy_destroyed_positions[index],
			tuning.score_enemy_destroyed,
		)
	}

	if victory_started {
		victory_count := 48
		if reduced_flashes do victory_count = 24
		for _ in 0 ..< victory_count {
			x := f32(32 + gameplay_cosmetic_random_max(gameplay, WINDOW_WIDTH - 64))
			y := f32(48 + gameplay_cosmetic_random_max(gameplay, 180))
			spawn_effect_burst(effects, gameplay, x, y, 1, .Victory)
		}
	}
}

advance_game_effects :: proc(effects: ^Game_Effects, frame_seconds: f64) {
	delta := clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	for &particle in effects.particles {
		if !particle.active do continue
		particle.x += particle.velocity_x * f32(delta)
		particle.y += particle.velocity_y * f32(delta)
		particle.velocity_y += 42 * f32(delta)
		particle.remaining_seconds = max(particle.remaining_seconds - delta, 0)
		if particle.remaining_seconds == 0 do particle.active = false
	}
	for &popup in effects.popups {
		if !popup.active do continue
		popup.y -= 18 * f32(delta)
		popup.remaining_seconds = max(popup.remaining_seconds - delta, 0)
		if popup.remaining_seconds == 0 do popup.active = false
	}
	effects.treasure_toast_remaining = max(effects.treasure_toast_remaining - delta, 0)
}

// treasure_toast_alpha eases the readout in, holds it, then eases it back out
// over its fixed lifetime.
treasure_toast_alpha :: proc(remaining_seconds: f64) -> f32 {
	if remaining_seconds <= 0 do return 0
	if remaining_seconds > TREASURE_TOAST_SECONDS - TREASURE_TOAST_FADE_SECONDS {
		return f32((TREASURE_TOAST_SECONDS - remaining_seconds) / TREASURE_TOAST_FADE_SECONDS)
	}
	if remaining_seconds < TREASURE_TOAST_FADE_SECONDS {
		return f32(remaining_seconds / TREASURE_TOAST_FADE_SECONDS)
	}
	return 1
}

// draw_treasure_toast draws the "TREASURE x/y" readout only while its timer
// is active, using treasure_toast_alpha's fade-in/hold/fade-out envelope.
draw_treasure_toast :: proc(effects: ^Game_Effects) {
	alpha := treasure_toast_alpha(effects.treasure_toast_remaining)
	if alpha <= 0 do return
	buffer: [32]byte
	text := format_cstring(buffer[:], "TREASURE  %d/%d", effects.treasure_toast_collected, effects.treasure_toast_total)
	width := rl.MeasureText(text, 15)
	x := (WINDOW_WIDTH - width) / 2
	rl.DrawRectangle(x - 10, 6, width + 20, 20, rl.Fade(rl.BLACK, 0.55 * alpha))
	rl.DrawText(text, x, 9, 15, rl.Fade(rl.SKYBLUE, alpha))
}

effect_color :: proc(kind: Effect_Kind) -> rl.Color {
	switch kind {
	case .Explosion: return rl.ORANGE
	case .Damage:    return rl.RED
	case .Pickup:    return rl.GREEN
	case .Treasure:  return rl.SKYBLUE
	case .Victory:   return rl.GOLD
	}
	return rl.WHITE
}

draw_game_effects :: proc(effects: ^Game_Effects) {
	for particle in effects.particles {
		if !particle.active do continue
		alpha := f32(clamp(
			particle.remaining_seconds / particle.duration_seconds,
			0,
			1,
		))
		size: i32 = 3
		if particle.kind == .Victory do size = 2
		rl.DrawRectangle(
			i32(particle.x),
			i32(particle.y),
			size,
			size,
			rl.Fade(effect_color(particle.kind), alpha),
		)
	}
	for popup in effects.popups {
		if !popup.active do continue
		alpha := f32(clamp(popup.remaining_seconds / 0.8, 0, 1))
		draw_ui_format(i32(popup.x), i32(popup.y), 14, rl.Fade(rl.GOLD, alpha), "+%d", popup.points)
	}
	draw_treasure_toast(effects)
}

