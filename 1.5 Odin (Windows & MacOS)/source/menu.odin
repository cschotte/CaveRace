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

Menu_Update_Result :: struct {
	confirmed:         Maybe(Menu_Item),
	selection_changed: bool,
}

MENU_ITEM_COUNT          :: len(Menu_Item)
MENU_SELECTION_X         :: 120 // in pixels
MENU_SELECTION_Y         :: 220 // in pixels
MENU_SELECTION_WIDTH     :: 400 // in pixels
MENU_SELECTION_HEIGHT    :: 40  // in pixels
MENU_SELECTION_STEP      :: 45  // in pixels

update_menu :: proc(menu: ^Menu_State, input: Game_Input) -> Menu_Update_Result {
	result: Menu_Update_Result
	previous_selection := menu.selected

	if selected, ok := input.menu_shortcut.?; ok {
		menu.selected = selected
	}

	if input.menu_next do move_menu_selection(menu, 1)
	if input.menu_previous do move_menu_selection(menu, -1)

	hovered := menu_item_at_mouse(input.mouse)
	if hovered_item, ok := hovered.?; ok {
		if input.mouse.moved || input.mouse.left_pressed {
			menu.selected = hovered_item
		}

		if input.mouse.left_pressed do result.confirmed = hovered_item
	}

	if input.confirm do result.confirmed = menu.selected
	result.selection_changed = menu.selected != previous_selection
	return result
}

menu_item_at_mouse :: proc(mouse: Mouse_State) -> Maybe(Menu_Item) {
	if mouse.x < MENU_SELECTION_X || mouse.x >= MENU_SELECTION_X + MENU_SELECTION_WIDTH {
		return nil
	}

	for item_index in 0 ..< MENU_ITEM_COUNT {
		item_y := MENU_SELECTION_Y + i32(item_index) * MENU_SELECTION_STEP
		if mouse.y >= item_y && mouse.y < item_y + MENU_SELECTION_HEIGHT {
			item: Maybe(Menu_Item) = Menu_Item(item_index)
			return item
		}
	}

	return nil
}

move_menu_selection :: proc(menu: ^Menu_State, direction: int) {
	current := int(menu.selected)
	next := (current + direction + MENU_ITEM_COUNT) % MENU_ITEM_COUNT
	menu.selected = Menu_Item(next)
}

draw_menu :: proc(menu: Menu_State, background, selection: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)

	menu_selection_y := MENU_SELECTION_Y + i32(menu.selected) * MENU_SELECTION_STEP
	rl.DrawTexture(
		selection,
		MENU_SELECTION_X,
		menu_selection_y,
		rl.WHITE,
	)
}
