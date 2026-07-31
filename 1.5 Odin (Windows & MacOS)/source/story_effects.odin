package caverace

import rl "vendor:raylib"

// Story_Effect_Kind gives every original panel an artwork-specific animated
// treatment without modifying the source PNGs or consuming either RNG.
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

// story_effect_kind maps a story image index to its effect, assuming
// Story_Effect_Kind's declaration order exactly matches the intro panel
// order (index 0 is the first panel, and so on).
story_effect_kind :: proc(image_index: int) -> Story_Effect_Kind {
	assert(image_index >= INTRO_FIRST_IMAGE && image_index <= INTRO_LAST_IMAGE)
	return Story_Effect_Kind(image_index - INTRO_FIRST_IMAGE)
}

// story_effect_clock extends the panel's own elapsed time with the
// transition's elapsed time while one is active, so effects keep animating
// smoothly through a crossfade instead of resetting to zero.
story_effect_clock :: proc(front_end: Front_End_State) -> f64 {
	clock := front_end.elapsed_seconds
	if front_end.transition_active do clock += front_end.transition_elapsed_seconds
	return clock
}

// story_effect_count halves (rounding up, minimum 1) the number of accents
// drawn under Reduced Flashes, so a panel keeps at least one live accent.
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

// draw_story_glint draws one pulsing sparkle: a bright center point, cardinal
// rays that brighten with pulse, and a brief diagonal flare once pulse
// crosses 0.45. Shared by every intro panel's twinkle-style accents.
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

// draw_story_light layers translucent circles over a practical light source.
// The deliberately low opacity preserves the pixel art while making lanterns,
// flames, eyes, and explosions feel as though they illuminate their surrounds.
draw_story_light :: proc(
	point: Story_Point,
	radius: i32,
	color: rl.Color,
	strength, transition_alpha: f32,
	reduced_flashes: bool,
) {
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.66
	alpha := clamp(strength * transition_alpha * accessibility_alpha, 0, 1)
	outer_radius := f32(radius)
	middle_radius := max(outer_radius * 0.62, 1)
	inner_radius := max(outer_radius * 0.28, 1)
	rl.DrawCircle(point.x, point.y, outer_radius, rl.Fade(color, alpha * 0.08))
	rl.DrawCircle(point.x, point.y, middle_radius, rl.Fade(color, alpha * 0.12))
	rl.DrawCircle(point.x, point.y, inner_radius, rl.Fade(color, alpha * 0.18))
}

// draw_story_smoke draws one looping, upward-drifting, fading puff from a
// fixed origin; particle_index offsets its phase and drift side so a group
// of calls reads as one continuous wisp rather than particles in lockstep.
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
	radius := f32(4) + age * 9
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.72
	alpha := clamp((1 - age) * 0.72 * transition_alpha * accessibility_alpha, 0, 1)
	color := rl.LIGHTGRAY
	if particle_index % 2 == 0 do color = rl.GRAY
	rl.DrawCircle(x, y, radius, rl.Fade(color, alpha))
	shoulder_x := x - drift_direction * 2
	rl.DrawCircle(shoulder_x, y + 2, radius * 0.68, rl.Fade(rl.LIGHTGRAY, alpha * 0.36))
}

// draw_story_fuse keeps fuse smoke compact enough for the small illustrated
// bomb cords, then adds a hot spark and a few rising orange flecks.
draw_story_fuse :: proc(
	origin: Story_Point,
	clock: f64,
	phase_offset: int,
	transition_alpha: f32,
	reduced_flashes: bool,
) {
	steps_per_second := 14.0
	if reduced_flashes do steps_per_second = 7.0
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.62
	for particle_index in 0 ..< story_effect_count(4, reduced_flashes) {
		cycle := (int(clock * steps_per_second) + particle_index * 13 + phase_offset) % 44
		age := f32(cycle) / 44
		drift: i32 = 1
		if particle_index % 2 == 0 do drift = -1
		x := origin.x + drift * i32(age * f32(3 + particle_index))
		y := origin.y - i32(age * 20)
		radius := 1.5 + age * 3.2
		alpha := (1 - age) * 0.64 * transition_alpha * accessibility_alpha
		rl.DrawCircle(x, y, radius, rl.Fade(rl.LIGHTGRAY, alpha))
	}
	pulse := story_effect_pulse(clock, phase_offset, 18, reduced_flashes)
	draw_story_light(origin, 13, rl.ORANGE, 0.72 + pulse * 0.28, transition_alpha, reduced_flashes)
	draw_story_glint(origin, 3 + i32(pulse * 2), rl.ORANGE, pulse, transition_alpha, reduced_flashes)
	for ember_index in 0 ..< story_effect_count(3, reduced_flashes) {
		cycle := (int(clock * steps_per_second) + ember_index * 9 + phase_offset) % 24
		age := f32(cycle) / 24
		x_direction: i32 = 1
		if ember_index % 2 == 0 do x_direction = -1
		x := origin.x + x_direction * i32(age * f32(5 + ember_index * 2))
		y := origin.y - i32(age * f32(7 + ember_index * 2))
		rl.DrawRectangle(x, y, 2, 2, rl.Fade(rl.GOLD, (1 - age) * transition_alpha * accessibility_alpha))
	}
}

// draw_story_flame reinforces an illustrated torch with a warm pool of light,
// a dancing white-hot core, and deterministic embers.
draw_story_flame :: proc(
	origin: Story_Point,
	clock: f64,
	transition_alpha: f32,
	reduced_flashes: bool,
) {
	pulse := story_effect_pulse(clock, 0, 18, reduced_flashes)
	secondary_pulse := story_effect_pulse(clock, 7, 23, reduced_flashes)
	accessibility_alpha: f32 = 1
	if reduced_flashes do accessibility_alpha = 0.68
	draw_story_light(origin, 36, rl.ORANGE, 0.72 + pulse * 0.28, transition_alpha, reduced_flashes)
	flame_y := origin.y - i32(pulse * 3)
	rl.DrawCircle(
		origin.x,
		flame_y + 2,
		6 + pulse * 2,
		rl.Fade(rl.ORANGE, 0.58 * transition_alpha * accessibility_alpha),
	)
	rl.DrawCircle(
		origin.x,
		flame_y,
		3 + secondary_pulse * 1.5,
		rl.Fade(rl.GOLD, 0.90 * transition_alpha * accessibility_alpha),
	)
	rl.DrawRectangle(origin.x - 1, flame_y, 2, 3, rl.Fade(rl.WHITE, 0.72 * transition_alpha * accessibility_alpha))
	for ember_index in 0 ..< story_effect_count(5, reduced_flashes) {
		cycle := (int(clock * 12) + ember_index * 11) % 42
		age := f32(cycle) / 42
		drift: i32 = 1
		if ember_index % 2 == 0 do drift = -1
		x := origin.x + drift * i32(age * f32(5 + ember_index))
		y := origin.y - 5 - i32(age * f32(25 + ember_index * 2))
		alpha := (1 - age) * transition_alpha * accessibility_alpha
		rl.DrawRectangle(x, y, 2, 2, rl.Fade(rl.ORANGE, alpha))
	}
}

// draw_story_ember draws one looping ember flying outward along a fixed
// direction (chosen by particle_index from a small preset set) and fading as
// it travels, with a trailing red tail opposite its direction of travel.
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

// branding_effect_alpha softly introduces the accents after the branding
// image appears and settles them before its soundtrack hands off to the story.
branding_effect_alpha :: proc(clock: f64) -> f32 {
	fade_in := clamp(clock / 0.38, 0, 1)
	fade_out := clamp((BRANDING_FALLBACK_SECONDS - clock) / 0.32, 0, 1)
	return f32(fade_in * fade_out)
}

// draw_branding_effects animates only features already present in the logo
// artwork: practical cave lights, red energy on the mark, metallic title
// highlights, treasure glints, and a few slow dust motes in the dark recess.
draw_branding_effects :: proc(branding_elapsed_seconds: f64, reduced_flashes: bool) {
	transition_alpha := branding_effect_alpha(branding_elapsed_seconds)
	if transition_alpha <= 0 do return
	clock := branding_elapsed_seconds

	lantern_pulse := story_effect_pulse(clock, 4, 26, reduced_flashes)
	draw_story_light(
		{78, 168},
		27,
		rl.GOLD,
		0.72 + lantern_pulse * 0.28,
		transition_alpha,
		reduced_flashes,
	)
	draw_story_flame({576, 169}, clock, transition_alpha, reduced_flashes)

	mark_pulse := story_effect_pulse(clock, 2, 30, reduced_flashes)
	draw_story_light(
		{320, 134},
		78,
		rl.RED,
		0.28 + mark_pulse * 0.18,
		transition_alpha,
		reduced_flashes,
	)
	mark_points := [6]Story_Point {
		{283, 94}, {360, 101}, {366, 122},
		{339, 179}, {250, 174}, {321, 116},
	}
	mark_count := story_effect_count(len(mark_points), reduced_flashes)
	for point, point_index in mark_points[:mark_count] {
		pulse := story_effect_pulse(clock, point_index * 5, 23, reduced_flashes)
		color := rl.RED
		if point_index % 2 == 0 do color = rl.ORANGE
		draw_story_glint(point, i32(2 + point_index % 2), color, pulse, transition_alpha, reduced_flashes)
	}

	wordmark_points := [5]Story_Point {
		{195, 217}, {254, 217}, {321, 199}, {381, 217}, {450, 217},
	}
	wordmark_count := story_effect_count(len(wordmark_points), reduced_flashes)
	for point, point_index in wordmark_points[:wordmark_count] {
		pulse := story_effect_pulse(clock, point_index * 6 + 3, 29, reduced_flashes)
		draw_story_glint(point, 2, rl.WHITE, pulse, transition_alpha * 0.72, reduced_flashes)
	}

	treasure := [5]Story_Point {{70, 279}, {82, 271}, {95, 278}, {110, 282}, {118, 274}}
	treasure_count := story_effect_count(len(treasure), reduced_flashes)
	for point, point_index in treasure[:treasure_count] {
		pulse := story_effect_pulse(clock, point_index * 6 + 2, 24, reduced_flashes)
		color := rl.SKYBLUE
		if point_index % 2 == 0 do color = rl.GOLD
		draw_story_glint(point, 3, color, pulse, transition_alpha, reduced_flashes)
	}

	crystals := [6]Story_Point {
		{37, 354}, {24, 371}, {50, 371},
		{574, 349}, {592, 365}, {608, 346},
	}
	crystal_count := story_effect_count(len(crystals), reduced_flashes)
	for point, point_index in crystals[:crystal_count] {
		pulse := story_effect_pulse(clock, point_index * 5 + 7, 27, reduced_flashes)
		color := rl.SKYBLUE
		if point_index >= 3 do color = rl.MAGENTA
		draw_story_glint(point, i32(2 + point_index % 2), color, pulse, transition_alpha, reduced_flashes)
	}

	dust := [7]Story_Point {
		{137, 142}, {155, 313}, {478, 143}, {497, 279},
		{226, 69}, {414, 72}, {526, 329},
	}
	dust_count := story_effect_count(len(dust), reduced_flashes)
	for point, point_index in dust[:dust_count] {
		motion := (int(clock * 6) + point_index * 9) % 30
		drift: i32 = 1
		if point_index % 2 == 0 do drift = -1
		mote := Story_Point {point.x + drift * i32(motion / 6), point.y - i32(motion)}
		pulse := story_effect_pulse(clock, point_index * 4, 25, reduced_flashes)
		rl.DrawCircle(
			mote.x,
			mote.y,
			1.5 + pulse,
			rl.Fade(rl.MAGENTA, (0.18 + pulse * 0.30) * transition_alpha),
		)
	}
}

// draw_story_effects draws the current story panel's hand-placed accent
// (twinkles, glints, smoke, or embers, chosen by story_effect_kind) at its
// fixed screen coordinates, fading with the panel's own crossfade alpha.
draw_story_effects :: proc(front_end: Front_End_State, reduced_flashes: bool) {
	visual_image, transition_alpha := front_end_visual(front_end)
	if visual_image < INTRO_FIRST_IMAGE || visual_image > INTRO_LAST_IMAGE || transition_alpha <= 0 do return
	clock := story_effect_clock(front_end)
	effect := story_effect_kind(visual_image)

	switch effect {
	case .Stars:
		planet_pulse := story_effect_pulse(clock, 3, 32, reduced_flashes)
		draw_story_light({500, 187}, 110, rl.SKYBLUE, 0.32 + planet_pulse * 0.18, transition_alpha, reduced_flashes)
		draw_story_light({548, 21}, 38, rl.MAGENTA, 0.26, transition_alpha, reduced_flashes)
		points := [16]Story_Point {
			{406, 23}, {501, 31}, {575, 68}, {616, 128},
			{389, 319}, {531, 343}, {603, 367}, {334, 371},
			{6, 213}, {468, 52}, {575, 249}, {418, 361},
			{91, 385}, {267, 390}, {352, 7}, {608, 4},
		}
		count := story_effect_count(len(points), reduced_flashes)
		for point, point_index in points[:count] {
			pulse := story_effect_pulse(clock, point_index * 5, 24, reduced_flashes)
			color := rl.SKYBLUE
			if point_index % 4 == 0 do color = rl.MAGENTA
			draw_story_glint(point, i32(3 + point_index % 2), color, pulse, transition_alpha, reduced_flashes)
		}

	case .Mining_Glints:
		lanterns := [4]Story_Point {{484, 99}, {542, 80}, {49, 383}, {399, 268}}
		lantern_count := story_effect_count(len(lanterns), reduced_flashes)
		for lantern, lantern_index in lanterns[:lantern_count] {
			pulse := story_effect_pulse(clock, lantern_index * 7, 25, reduced_flashes)
			radius: i32 = 24
			if lantern_index >= 2 do radius = 17
			draw_story_light(lantern, radius, rl.GOLD, 0.72 + pulse * 0.28, transition_alpha, reduced_flashes)
		}
		gold := [8]Story_Point {
			{138, 285}, {166, 277}, {195, 287}, {220, 278},
			{245, 287}, {184, 298}, {224, 301}, {209, 270},
		}
		count := story_effect_count(len(gold), reduced_flashes)
		for point, point_index in gold[:count] {
			pulse := story_effect_pulse(clock, point_index * 7, 28, reduced_flashes)
			draw_story_glint(point, i32(3 + point_index % 2), rl.GOLD, pulse, transition_alpha, reduced_flashes)
		}
		crystals := [4]Story_Point {{576, 242}, {587, 228}, {565, 257}, {596, 254}}
		crystal_count := story_effect_count(len(crystals), reduced_flashes)
		for crystal, crystal_index in crystals[:crystal_count] {
			pulse := story_effect_pulse(clock, crystal_index * 6 + 3, 26, reduced_flashes)
			draw_story_glint(crystal, 3, rl.SKYBLUE, pulse, transition_alpha, reduced_flashes)
		}

	case .Alien_Eyes:
		eyes := [3]Story_Point {{333, 252}, {487, 155}, {528, 320}}
		count := story_effect_count(len(eyes), reduced_flashes)
		for eye, eye_index in eyes[:count] {
			pulse := story_effect_pulse(clock, eye_index * 6, 26, reduced_flashes)
			draw_story_light(eye, 20, rl.RED, 0.62 + pulse * 0.38, transition_alpha, reduced_flashes)
			glow_alpha := (0.22 + pulse * 0.38) * transition_alpha
			if reduced_flashes do glow_alpha *= 0.58
			rl.DrawCircle(eye.x, eye.y, 5 + pulse * 2, rl.Fade(rl.RED, glow_alpha))
			rl.DrawLine(eye.x - 3, eye.y, eye.x + 3, eye.y, rl.Fade(rl.ORANGE, glow_alpha * 0.75))
			rl.DrawRectangle(eye.x - 1, eye.y - 2, 2, 3, rl.Fade(rl.WHITE, (0.68 + pulse * 0.32) * transition_alpha))
		}
		crystals := [6]Story_Point {{34, 317}, {23, 339}, {50, 337}, {601, 211}, {586, 236}, {613, 224}}
		crystal_count := story_effect_count(len(crystals), reduced_flashes)
		for crystal, crystal_index in crystals[:crystal_count] {
			pulse := story_effect_pulse(clock, crystal_index * 5 + 2, 24, reduced_flashes)
			color := rl.SKYBLUE
			if crystal_index >= 3 do color = rl.MAGENTA
			draw_story_glint(crystal, i32(2 + crystal_index % 2), color, pulse, transition_alpha, reduced_flashes)
		}

	case .TNT_Fuse:
		lights := [3]Story_Point {{61, 277}, {468, 262}, {158, 241}}
		light_count := story_effect_count(len(lights), reduced_flashes)
		for light, light_index in lights[:light_count] {
			pulse := story_effect_pulse(clock, light_index * 8, 25, reduced_flashes)
			draw_story_light(light, 19, rl.GOLD, 0.66 + pulse * 0.24, transition_alpha, reduced_flashes)
		}
		draw_story_fuse({337, 257}, clock, 0, transition_alpha, reduced_flashes)
		draw_story_fuse({421, 294}, clock, 9, transition_alpha, reduced_flashes)

	case .Torch_And_Treasure:
		draw_story_flame({198, 273}, clock, transition_alpha, reduced_flashes)
		helmet_pulse := story_effect_pulse(clock, 9, 25, reduced_flashes)
		draw_story_light({488, 263}, 15, rl.GOLD, 0.62 + helmet_pulse * 0.24, transition_alpha, reduced_flashes)
		gold := [7]Story_Point {{380, 322}, {418, 302}, {450, 314}, {489, 319}, {436, 329}, {466, 298}, {405, 311}}
		count := story_effect_count(len(gold), reduced_flashes)
		for point, point_index in gold[:count] {
			glint := story_effect_pulse(clock, point_index * 6, 25, reduced_flashes)
			draw_story_glint(point, 3, rl.GOLD, glint, transition_alpha, reduced_flashes)
		}
		diamond_pulse := story_effect_pulse(clock, 4, 24, reduced_flashes)
		draw_story_glint({406, 352}, 5, rl.SKYBLUE, diamond_pulse, transition_alpha, reduced_flashes)
		potion_pulse := story_effect_pulse(clock, 13, 24, reduced_flashes)
		draw_story_glint({580, 352}, 4, rl.SKYBLUE, potion_pulse, transition_alpha, reduced_flashes)

	case .Explosion:
		blast_pulse := story_effect_pulse(clock, 0, 20, reduced_flashes)
		draw_story_light({462, 192}, 62, rl.ORANGE, 0.70 + blast_pulse * 0.30, transition_alpha, reduced_flashes)
		draw_story_light({462, 192}, 27, rl.GOLD, 0.80 + blast_pulse * 0.20, transition_alpha, reduced_flashes)
		rays := [6]Story_Point {{435, 133}, {501, 135}, {412, 172}, {517, 205}, {438, 231}, {493, 232}}
		ray_count := story_effect_count(len(rays), reduced_flashes)
		for ray in rays[:ray_count] {
			ray_alpha := (0.10 + blast_pulse * 0.16) * transition_alpha
			if reduced_flashes do ray_alpha *= 0.60
			rl.DrawLine(462, 192, ray.x, ray.y, rl.Fade(rl.GOLD, ray_alpha))
		}
		smoke_origin := Story_Point {462, 151}
		for particle_index in 0 ..< story_effect_count(9, reduced_flashes) {
			draw_story_smoke(smoke_origin, particle_index, clock, transition_alpha, reduced_flashes)
		}
		ember_origin := Story_Point {462, 198}
		for particle_index in 0 ..< story_effect_count(13, reduced_flashes) {
			draw_story_ember(ember_origin, particle_index, clock, transition_alpha, reduced_flashes)
		}
		draw_story_fuse({244, 309}, clock, 5, transition_alpha, reduced_flashes)
		diamond_pulse := story_effect_pulse(clock, 3, 24, reduced_flashes)
		draw_story_glint({412, 359}, 5, rl.SKYBLUE, diamond_pulse, transition_alpha, reduced_flashes)
		potion_pulse := story_effect_pulse(clock, 12, 24, reduced_flashes)
		draw_story_glint({523, 358}, 4, rl.GREEN, potion_pulse, transition_alpha, reduced_flashes)

	case .Homecoming:
		exit_pulse := story_effect_pulse(clock, 5, 34, reduced_flashes)
		draw_story_light({521, 111}, 58, rl.SKYBLUE, 0.28 + exit_pulse * 0.16, transition_alpha, reduced_flashes)
		gold := [8]Story_Point {
			{390, 257}, {414, 251}, {454, 246}, {480, 255},
			{444, 269}, {504, 264}, {428, 261}, {468, 265},
		}
		count := story_effect_count(len(gold), reduced_flashes)
		for point, point_index in gold[:count] {
			pulse := story_effect_pulse(clock, point_index * 5, 27, reduced_flashes)
			draw_story_glint(point, i32(3 + point_index % 2), rl.GOLD, pulse, transition_alpha, reduced_flashes)
		}
		motes := [7]Story_Point {
			{446, 112}, {480, 137}, {520, 101}, {560, 153},
			{596, 126}, {503, 185}, {574, 194},
		}
		mote_count := story_effect_count(len(motes), reduced_flashes)
		for point, point_index in motes[:mote_count] {
			motion := (int(clock * 6) + point_index * 11) % 34
			mote := Story_Point {point.x - i32(motion / 6), point.y + i32(motion)}
			pulse := story_effect_pulse(clock, point_index * 4, 22, reduced_flashes)
			color := rl.SKYBLUE
			if point_index % 2 == 0 do color = rl.GOLD
			draw_story_glint(mote, 2, color, pulse, transition_alpha, reduced_flashes)
		}
	}
}
