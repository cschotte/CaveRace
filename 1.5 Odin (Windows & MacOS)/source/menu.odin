package caverace

import rl "vendor:raylib"

Menu_Item :: enum {
	Start_Game,
	High_Scores,
	Quit,
}

Menu_State :: struct {
	selected:             Menu_Item,
	previous_selected:    Menu_Item,
	transition_elapsed:   f64,
	transition_active:    bool,
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
MENU_SELECTION_TRANSITION_SECONDS :: 0.50

update_menu :: proc(
	menu: ^Menu_State,
	input: Game_Input,
	frame_seconds: f64,
) -> Menu_Update_Result {
	result: Menu_Update_Result
	advance_menu_transition(menu, frame_seconds)
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
	if result.selection_changed {
		menu.previous_selected = previous_selection
		menu.transition_elapsed = 0
		menu.transition_active = true
	}
	return result
}

advance_menu_transition :: proc(menu: ^Menu_State, frame_seconds: f64) {
	if !menu.transition_active do return
	menu.transition_elapsed += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	if menu.transition_elapsed >= MENU_SELECTION_TRANSITION_SECONDS {
		menu.transition_elapsed = MENU_SELECTION_TRANSITION_SECONDS
		menu.transition_active = false
	}
}

menu_selection_visual :: proc(
	menu: Menu_State,
) -> (item: Menu_Item, alpha: f32) {
	if !menu.transition_active do return menu.selected, 1
	progress := clamp(
		menu.transition_elapsed / MENU_SELECTION_TRANSITION_SECONDS,
		0,
		1,
	)
	if progress < 0.5 {
		return menu.previous_selected, f32(1 - progress * 2)
	}
	return menu.selected, f32((progress - 0.5) * 2)
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

	visual_item, visual_alpha := menu_selection_visual(menu)
	menu_selection_y := MENU_SELECTION_Y + i32(visual_item) * MENU_SELECTION_STEP
	rl.DrawTexture(
		selection,
		MENU_SELECTION_X,
		menu_selection_y,
		rl.Fade(rl.WHITE, visual_alpha),
	)
}
