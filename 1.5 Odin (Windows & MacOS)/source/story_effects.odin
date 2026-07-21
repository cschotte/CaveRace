package caverace

import rl "vendor:raylib"

// Story_Effect_Kind gives every original panel one small, artwork-specific
// animated accent without modifying the source PNGs or consuming either RNG.
Story_Effect_Kind :: enum {
	Stars,
	Mining_Glints,
	Alien_Eyes,
	TNT_Fuse,
	Torch_And_Treasure,
	Explosion,
	Homecoming,
}

Story_Point :: struct {
	x, y: i32,
}

story_effect_kind :: proc(image_index: int) -> Story_Effect_Kind {
	assert(image_index >= INTRO_FIRST_IMAGE && image_index <= INTRO_LAST_IMAGE)
	return Story_Effect_Kind(image_index - INTRO_FIRST_IMAGE)
}

story_effect_clock :: proc(front_end: Front_End_State) -> f64 {
	clock := front_end.elapsed_seconds
	if front_end.transition_active do clock += front_end.transition_elapsed_seconds
	return clock
}

story_effect_count :: proc(full_count: int, reduced_flashes: bool) -> int {
	if reduced_flashes do return max(1, (full_count + 1) / 2)
	return full_count
}

// A slow triangular pulse suits low-resolution pixel art and remains bounded.
// Reduced Flashes halves its update rate as well as the number of accents.
story_effect_pulse :: proc(
	clock: f64,
	offset, period: int,
	reduced_flashes: bool,
) -> f32 {
	steps_per_second := 8.0
	if reduced_flashes do steps_per_second = 4.0
	cycle := (int(clock * steps_per_second) + offset) % period
	if cycle < 0 do cycle += period
	half := f32(period) / 2
	distance := abs(f32(cycle) - half) / half
	return clamp(1 - distance, 0, 1)
}

draw_story_glint :: proc(
	point: Story_Point,
	size: i32,
	color: rl.Color,
	pulse, transition_alpha: f32,
	reduced_flashes: bool,
) {
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.62
	center_alpha := clamp((0.48 + pulse * 0.52) * transition_alpha * accessibility_alpha, 0, 1)
	rl.DrawRectangle(point.x - 1, point.y - 1, 3, 3, rl.Fade(rl.WHITE, center_alpha))
	ray_alpha := clamp((0.28 + pulse * 0.72) * transition_alpha * accessibility_alpha, 0, 1)
	ray_color := rl.Fade(color, ray_alpha)
	rl.DrawLine(point.x - size, point.y, point.x + size, point.y, ray_color)
	rl.DrawLine(point.x, point.y - size, point.x, point.y + size, ray_color)
	if pulse >= 0.45 {
		diagonal_size := max(size - 1, 1)
		diagonal_color := rl.Fade(color, ray_alpha * 0.65)
		rl.DrawLine(
			point.x - diagonal_size,
			point.y - diagonal_size,
			point.x + diagonal_size,
			point.y + diagonal_size,
			diagonal_color,
		)
		rl.DrawLine(
			point.x + diagonal_size,
			point.y - diagonal_size,
			point.x - diagonal_size,
			point.y + diagonal_size,
			diagonal_color,
		)
	}
}

draw_story_smoke :: proc(
	origin: Story_Point,
	particle_index: int,
	clock: f64,
	transition_alpha: f32,
	reduced_flashes: bool,
) {
	steps_per_second := 12.0
	if reduced_flashes do steps_per_second = 6.0
	cycle := (int(clock * steps_per_second) + particle_index * 23) % 84
	age := f32(cycle) / 84
	drift_direction: i32 = 1
	if particle_index % 2 == 0 do drift_direction = -1
	x := origin.x + drift_direction * i32(age * f32(5 + particle_index))
	y := origin.y - i32(age * 44)
	radius := f32(3) + age * 7
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.72
	alpha := clamp((1 - age) * 0.62 * transition_alpha * accessibility_alpha, 0, 1)
	color := rl.LIGHTGRAY
	if particle_index % 2 == 0 do color = rl.GRAY
	rl.DrawCircle(x, y, radius, rl.Fade(color, alpha))
}

draw_story_ember :: proc(
	origin: Story_Point,
	particle_index: int,
	clock: f64,
	transition_alpha: f32,
	reduced_flashes: bool,
) {
	steps_per_second := 14.0
	if reduced_flashes do steps_per_second = 7.0
	cycle := (int(clock * steps_per_second) + particle_index * 11) % 48
	age := f32(cycle) / 48
	directions := [6]Story_Point {
		{-24, -18}, {20, -25}, {-13, -31}, {28, -9}, {-31, -5}, {11, -36},
	}
	direction := directions[particle_index % len(directions)]
	x := origin.x + i32(f32(direction.x) * age)
	y := origin.y + i32(f32(direction.y) * age)
	alpha := clamp((1 - age) * transition_alpha, 0, 1)
	if reduced_flashes do alpha *= 0.55
	color := rl.ORANGE
	if particle_index % 2 == 0 do color = rl.GOLD
	rl.DrawRectangle(x - 1, y - 1, 3, 3, rl.Fade(color, alpha))
	tail_x := x
	if direction.x > 0 do tail_x -= 2
	if direction.x < 0 do tail_x += 2
	rl.DrawRectangle(tail_x, y + 2, 2, 2, rl.Fade(rl.RED, alpha * 0.72))
}

draw_story_effects :: proc(front_end: Front_End_State, reduced_flashes: bool) {
	visual_image, transition_alpha := front_end_visual(front_end)
	if visual_image < INTRO_FIRST_IMAGE || visual_image > INTRO_LAST_IMAGE || transition_alpha <= 0 do return
	clock := story_effect_clock(front_end)
	effect := story_effect_kind(visual_image)

	switch effect {
	case .Stars:
		points := [12]Story_Point {
			{406, 23}, {501, 31}, {575, 68}, {616, 128},
			{389, 319}, {531, 343}, {603, 367}, {95, 326},
			{19, 213}, {483, 103}, {575, 249}, {418, 361},
		}
		count := story_effect_count(len(points), reduced_flashes)
		for point, point_index in points[:count] {
			pulse := story_effect_pulse(clock, point_index * 5, 24, reduced_flashes)
			color := rl.SKYBLUE
			if point_index % 3 == 0 do color = rl.MAGENTA
			draw_story_glint(point, 3, color, pulse, transition_alpha, reduced_flashes)
		}

	case .Mining_Glints:
		points := [7]Story_Point {
			{134, 279}, {167, 267}, {204, 287}, {239, 279},
			{503, 99}, {533, 101}, {225, 263},
		}
		count := story_effect_count(len(points), reduced_flashes)
		for point, point_index in points[:count] {
			pulse := story_effect_pulse(clock, point_index * 7, 28, reduced_flashes)
			draw_story_glint(point, 4, rl.GOLD, pulse, transition_alpha, reduced_flashes)
		}

	case .Alien_Eyes:
		eyes := [3]Story_Point {{357, 284}, {484, 219}, {547, 325}}
		count := story_effect_count(len(eyes), reduced_flashes)
		for eye, eye_index in eyes[:count] {
			pulse := story_effect_pulse(clock, eye_index * 6, 26, reduced_flashes)
			glow_alpha := (0.16 + pulse * 0.30) * transition_alpha
			if reduced_flashes do glow_alpha *= 0.58
			rl.DrawCircle(eye.x, eye.y, 6 + pulse * 3, rl.Fade(rl.RED, glow_alpha))
			rl.DrawRectangle(eye.x - 1, eye.y - 1, 2, 3, rl.Fade(rl.WHITE, (0.60 + pulse * 0.40) * transition_alpha))
		}

	case .TNT_Fuse:
		origin := Story_Point {310, 271}
		for particle_index in 0 ..< story_effect_count(4, reduced_flashes) {
			draw_story_smoke(origin, particle_index, clock, transition_alpha, reduced_flashes)
		}
		pulse := story_effect_pulse(clock, 0, 18, reduced_flashes)
		draw_story_glint({310, 273}, 4, rl.ORANGE, pulse, transition_alpha, reduced_flashes)

	case .Torch_And_Treasure:
		pulse := story_effect_pulse(clock, 0, 18, reduced_flashes)
		flame_alpha := transition_alpha
		if reduced_flashes do flame_alpha *= 0.70
		flame_y := i32(263 - pulse * 2)
		rl.DrawCircle(182, flame_y, 5 + pulse * 2, rl.Fade(rl.ORANGE, 0.72 * flame_alpha))
		rl.DrawCircle(182, flame_y + 1, 2.5 + pulse, rl.Fade(rl.GOLD, flame_alpha))
		points := [5]Story_Point {{419, 342}, {444, 367}, {486, 365}, {575, 350}, {465, 348}}
		count := story_effect_count(len(points), reduced_flashes)
		for point, point_index in points[:count] {
			glint := story_effect_pulse(clock, point_index * 6, 25, reduced_flashes)
			draw_story_glint(point, 3, rl.GOLD, glint, transition_alpha, reduced_flashes)
		}

	case .Explosion:
		smoke_origin := Story_Point {469, 180}
		for particle_index in 0 ..< story_effect_count(7, reduced_flashes) {
			draw_story_smoke(smoke_origin, particle_index, clock, transition_alpha, reduced_flashes)
		}
		ember_origin := Story_Point {469, 213}
		for particle_index in 0 ..< story_effect_count(9, reduced_flashes) {
			draw_story_ember(ember_origin, particle_index, clock, transition_alpha, reduced_flashes)
		}
		diamond_pulse := story_effect_pulse(clock, 3, 24, reduced_flashes)
		draw_story_glint({408, 309}, 5, rl.SKYBLUE, diamond_pulse, transition_alpha, reduced_flashes)
		potion_pulse := story_effect_pulse(clock, 12, 24, reduced_flashes)
		draw_story_glint({559, 302}, 4, rl.GREEN, potion_pulse, transition_alpha, reduced_flashes)

	case .Homecoming:
		gold := [6]Story_Point {{401, 235}, {421, 226}, {443, 235}, {465, 229}, {478, 241}, {433, 216}}
		count := story_effect_count(len(gold), reduced_flashes)
		for point, point_index in gold[:count] {
			pulse := story_effect_pulse(clock, point_index * 5, 27, reduced_flashes)
			draw_story_glint(point, 3, rl.GOLD, pulse, transition_alpha, reduced_flashes)
		}
		motes := [4]Story_Point {{511, 103}, {548, 134}, {584, 92}, {603, 172}}
		mote_count := story_effect_count(len(motes), reduced_flashes)
		for point, point_index in motes[:mote_count] {
			motion := (int(clock * 5) + point_index * 9) % 22
			mote := Story_Point {point.x + i32(motion / 5), point.y - i32(motion)}
			pulse := story_effect_pulse(clock, point_index * 4, 22, reduced_flashes)
			draw_story_glint(mote, 2, rl.SKYBLUE, pulse, transition_alpha, reduced_flashes)
		}
	}
}
