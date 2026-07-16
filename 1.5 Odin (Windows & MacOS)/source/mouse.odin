package caverace

import rl "vendor:raylib"

MOUSE_POINTER_TILE_INDEX :: 4

Mouse_State :: struct {
	x: i32,
	y: i32,
}

draw_mouse :: proc(mouse: Mouse_State, texture: rl.Texture) {
	tile_size := f32(texture.width)
	source := rl.Rectangle {
		x      = 0,
		y      = tile_size * MOUSE_POINTER_TILE_INDEX,
		width  = tile_size,
		height = tile_size,
	}
	position := rl.Vector2 {
		f32(mouse.x),
		f32(mouse.y),
	}

	rl.DrawTextureRec(texture, source, position, rl.WHITE)
}
