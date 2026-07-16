package caverace

import rl "vendor:raylib"

Menu_Item :: enum {
	Start_Game,
	High_Scores,
	Quit,
}

Menu_State :: struct {
	selected: Menu_Item,
}

MENU_ITEM_COUNT     :: len(Menu_Item)
MENU_SELECTION_X    :: 120 // in pixels
MENU_SELECTION_Y    :: 220 // in pixels
MENU_SELECTION_STEP :: 45  // in pixels
MOUSE_POINTER_TILE  :: 4

update_menu :: proc(game: ^Game, input: Game_Input) {
	if selected, ok := input.menu_selection.?; ok {
		game.menu.selected = selected
	}

	if input.menu_next do move_menu_selection(&game.menu, 1)
	if input.menu_previous do move_menu_selection(&game.menu, -1)

	if input.confirm {
		switch game.menu.selected {
		case .Start_Game:
			game.screen = .Playing
		case .High_Scores:
			game.screen = .High_Scores
		case .Quit:
			game.quit_requested = true
		}
	}
}

move_menu_selection :: proc(menu: ^Menu_State, direction: int) {
	current := int(menu.selected)
	next := (current + direction + MENU_ITEM_COUNT) % MENU_ITEM_COUNT
	menu.selected = Menu_Item(next)
}

draw_menu :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.menu, 0, 0, rl.WHITE)

	menu_selection_y := MENU_SELECTION_Y + i32(game.menu.selected) * MENU_SELECTION_STEP
	rl.DrawTexture(
		assets.screens.select,
		MENU_SELECTION_X,
		menu_selection_y,
		rl.WHITE,
	)

	draw_mouse(game, assets)
}

draw_mouse :: proc(game: ^Game, assets: ^Assets) {
	tile_size := f32(assets.sprites.tools.width)
	source := rl.Rectangle {
		x      = 0,
		y      = tile_size * MOUSE_POINTER_TILE,
		width  = tile_size,
		height = tile_size,
	}
	position := rl.Vector2 {
		f32(game.input.mouse_x),
		f32(game.input.mouse_y),
	}

	rl.DrawTextureRec(assets.sprites.tools, source, position, rl.WHITE)
}
