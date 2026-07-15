package caverace

import rl "vendor:raylib"

Main_Menu_Item :: enum {
	Start_Game,
	High_Scores,
	Quit,
}

Main_Menu_State :: struct {
	selected: Main_Menu_Item,
}

MAIN_MENU_ITEM_COUNT     :: len(Main_Menu_Item)
MAIN_MENU_SELECTION_X    :: 120 // in pixels
MAIN_MENU_SELECTION_Y    :: 220 // in pixels
MAIN_MENU_SELECTION_STEP :: 45  // in pixels

update_main_menu :: proc(game: ^Game) {
	if rl.IsKeyPressed(.DOWN) {
		move_main_menu_selection(&game.main_menu, 1)
	}

	if rl.IsKeyPressed(.UP) {
		move_main_menu_selection(&game.main_menu, -1)
	}
}

move_main_menu_selection :: proc(menu: ^Main_Menu_State, direction: int) {
	current := int(menu.selected)
	next := (current + direction + MAIN_MENU_ITEM_COUNT) % MAIN_MENU_ITEM_COUNT
	menu.selected = Main_Menu_Item(next)
}

draw_main_menu :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.menu, 0, 0, rl.WHITE)

	selection_y := MAIN_MENU_SELECTION_Y + i32(game.main_menu.selected) * MAIN_MENU_SELECTION_STEP
	rl.DrawTexture(
		assets.screens.select,
		MAIN_MENU_SELECTION_X,
		selection_y,
		rl.WHITE,
	)
}
