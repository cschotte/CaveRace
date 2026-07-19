package caverace

import "core:strings"
import rl "vendor:raylib"

Tile_Theme :: enum {
	Desert,
	Forest,
	Lava,
	Oil,
	Winter,
}

Screen_Assets :: struct {
	game:       rl.Texture,
	highscore:  rl.Texture,
	menu:       rl.Texture,
	select:     rl.Texture,
}

Sound_Assets :: struct {
	bomb:    [BOMB_SOUND_COUNT]rl.Sound,
	item:    rl.Sound,
	menu:    rl.Sound,
	squish:  rl.Sound,
	ticking: rl.Sound,
}

Sprite_Assets :: struct {
	bomb:     rl.Texture,
	enemy:    rl.Texture,
	objects:  rl.Texture,
	player:   rl.Texture,
	tools:    rl.Texture,
	treasure: rl.Texture,
}

Assets :: struct {
	screens: Screen_Assets,
	sounds:  Sound_Assets,
	sprites: Sprite_Assets,
	tiles:   [Tile_Theme]rl.Texture,
}

load_resource_texture :: proc(root, relative_path: string) -> rl.Texture {
	path, ok := resource_path(root, {RESOURCE_MEDIA_DIRECTORY, relative_path})
	if !ok do return {}
	defer delete(path)
	path_cstring, cstring_error := strings.clone_to_cstring(path)
	if cstring_error != nil do return {}
	defer delete(path_cstring)
	return rl.LoadTexture(path_cstring)
}

load_resource_sound :: proc(root, relative_path: string) -> rl.Sound {
	path, ok := resource_path(root, {RESOURCE_MEDIA_DIRECTORY, relative_path})
	if !ok do return {}
	defer delete(path)
	path_cstring, cstring_error := strings.clone_to_cstring(path)
	if cstring_error != nil do return {}
	defer delete(path_cstring)
	return rl.LoadSound(path_cstring)
}

load_assets :: proc(assets: ^Assets, resource_root: string, load_audio := true) -> bool {
	assets^ = {}
	assets.screens.game      = load_resource_texture(resource_root, "screens/game.png")
	assets.screens.highscore = load_resource_texture(resource_root, "screens/highscore.png")
	assets.screens.menu      = load_resource_texture(resource_root, "screens/menu.png")
	assets.screens.select    = load_resource_texture(resource_root, "screens/select.png")

	if load_audio {
		assets.sounds.bomb[0] = load_resource_sound(resource_root, "sounds/bomb01.wav")
		assets.sounds.bomb[1] = load_resource_sound(resource_root, "sounds/bomb02.wav")
		assets.sounds.bomb[2] = load_resource_sound(resource_root, "sounds/bomb03.wav")
		assets.sounds.bomb[3] = load_resource_sound(resource_root, "sounds/bomb04.wav")
		assets.sounds.item    = load_resource_sound(resource_root, "sounds/item.wav")
		assets.sounds.menu    = load_resource_sound(resource_root, "sounds/menu.wav")
		assets.sounds.squish  = load_resource_sound(resource_root, "sounds/squish.wav")
		assets.sounds.ticking = load_resource_sound(resource_root, "sounds/ticking.wav")
	}

	assets.sprites.bomb     = load_resource_texture(resource_root, "sprites/bomb.png")
	assets.sprites.enemy    = load_resource_texture(resource_root, "sprites/enemy.png")
	assets.sprites.objects  = load_resource_texture(resource_root, "sprites/objects.png")
	assets.sprites.player   = load_resource_texture(resource_root, "sprites/player.png")
	assets.sprites.tools    = load_resource_texture(resource_root, "sprites/tools.png")
	assets.sprites.treasure = load_resource_texture(resource_root, "sprites/treasure.png")

	assets.tiles[.Desert] = load_resource_texture(resource_root, "tiles/desert.png")
	assets.tiles[.Forest] = load_resource_texture(resource_root, "tiles/forest.png")
	assets.tiles[.Lava]   = load_resource_texture(resource_root, "tiles/lava.png")
	assets.tiles[.Oil]    = load_resource_texture(resource_root, "tiles/oil.png")
	assets.tiles[.Winter] = load_resource_texture(resource_root, "tiles/winter.png")

	return assets_are_valid(assets, load_audio)
}

assets_are_valid :: proc(assets: ^Assets, require_audio := true) -> bool {
	if !texture_has_size(assets.screens.game, WINDOW_WIDTH, WINDOW_HEIGHT)      do return false
	if !texture_has_size(assets.screens.highscore, WINDOW_WIDTH, WINDOW_HEIGHT) do return false
	if !texture_has_size(assets.screens.menu, WINDOW_WIDTH, WINDOW_HEIGHT)      do return false
	if !texture_has_size(assets.screens.select, MENU_SELECTION_WIDTH, MENU_SELECTION_HEIGHT) do return false

	if require_audio {
		for sound in assets.sounds.bomb {
			if !rl.IsSoundValid(sound) do return false
		}
		if !rl.IsSoundValid(assets.sounds.item)    do return false
		if !rl.IsSoundValid(assets.sounds.menu)    do return false
		if !rl.IsSoundValid(assets.sounds.squish)  do return false
		if !rl.IsSoundValid(assets.sounds.ticking) do return false
	}

	if !vertical_sheet_is_valid(assets.sprites.bomb, BOMB_SPRITE_COUNT) do return false
	if !vertical_sheet_is_valid(assets.sprites.enemy, ENEMY_SPRITE_COUNT) do return false
	if !vertical_sheet_is_valid(assets.sprites.objects, ITEM_SPRITE_COUNT) do return false
	if !vertical_sheet_is_valid(assets.sprites.player, PLAYER_SPRITE_COUNT) do return false
	if !vertical_sheet_is_valid(assets.sprites.tools, TOOLS_SPRITE_COUNT) do return false
	if !vertical_sheet_is_valid(assets.sprites.treasure, TREASURE_SPRITE_COUNT) do return false

	for tile in assets.tiles {
		if !vertical_sheet_is_valid(tile, TERRAIN_SPRITE_COUNT) do return false
	}

	return true
}

texture_has_size :: proc(texture: rl.Texture, width, height: int) -> bool {
	return rl.IsTextureValid(texture) &&
	       texture.width == i32(width) && texture.height == i32(height)
}

vertical_sheet_is_valid :: proc(texture: rl.Texture, sprite_count: int) -> bool {
	return rl.IsTextureValid(texture) && vertical_sheet_dimensions_are_valid(
		int(texture.width),
		int(texture.height),
		sprite_count,
	)
}

vertical_sheet_dimensions_are_valid :: proc(width, height, sprite_count: int) -> bool {
	return sprite_count > 0 && width == MAP_TILE_SIZE &&
	       height >= sprite_count * MAP_TILE_SIZE && height % MAP_TILE_SIZE == 0
}

unload_assets :: proc(assets: ^Assets) {
	unload_texture(assets.screens.game)
	unload_texture(assets.screens.highscore)
	unload_texture(assets.screens.menu)
	unload_texture(assets.screens.select)

	for sound in assets.sounds.bomb {
		unload_sound(sound)
	}
	unload_sound(assets.sounds.item)
	unload_sound(assets.sounds.menu)
	unload_sound(assets.sounds.squish)
	unload_sound(assets.sounds.ticking)

	unload_texture(assets.sprites.bomb)
	unload_texture(assets.sprites.enemy)
	unload_texture(assets.sprites.objects)
	unload_texture(assets.sprites.player)
	unload_texture(assets.sprites.tools)
	unload_texture(assets.sprites.treasure)

	for tile in assets.tiles {
		unload_texture(tile)
	}

	// Clear resource handles so ownership has visibly ended and an accidental
	// second cleanup remains harmless.
	assets^ = {}
}

unload_texture :: proc(texture: rl.Texture) {
	if rl.IsTextureValid(texture) do rl.UnloadTexture(texture)
}

unload_sound :: proc(sound: rl.Sound) {
	if rl.IsSoundValid(sound) do rl.UnloadSound(sound)
}
