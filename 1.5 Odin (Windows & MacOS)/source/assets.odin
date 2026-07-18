package caverace

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
	bomb:    [4]rl.Sound,
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

load_assets :: proc(assets: ^Assets) -> bool {
	assets.screens.game      = rl.LoadTexture(MEDIA_PATH + "/screens/game.png")
	assets.screens.highscore = rl.LoadTexture(MEDIA_PATH + "/screens/highscore.png")
	assets.screens.menu      = rl.LoadTexture(MEDIA_PATH + "/screens/menu.png")
	assets.screens.select    = rl.LoadTexture(MEDIA_PATH + "/screens/select.png")

	assets.sounds.bomb[0] = rl.LoadSound(MEDIA_PATH + "/sounds/bomb01.wav")
	assets.sounds.bomb[1] = rl.LoadSound(MEDIA_PATH + "/sounds/bomb02.wav")
	assets.sounds.bomb[2] = rl.LoadSound(MEDIA_PATH + "/sounds/bomb03.wav")
	assets.sounds.bomb[3] = rl.LoadSound(MEDIA_PATH + "/sounds/bomb04.wav")
	assets.sounds.item    = rl.LoadSound(MEDIA_PATH + "/sounds/item.wav")
	assets.sounds.menu    = rl.LoadSound(MEDIA_PATH + "/sounds/menu.wav")
	assets.sounds.squish  = rl.LoadSound(MEDIA_PATH + "/sounds/squish.wav")
	assets.sounds.ticking = rl.LoadSound(MEDIA_PATH + "/sounds/ticking.wav")

	assets.sprites.bomb     = rl.LoadTexture(MEDIA_PATH + "/sprites/bomb.png")
	assets.sprites.enemy    = rl.LoadTexture(MEDIA_PATH + "/sprites/enemy.png")
	assets.sprites.objects  = rl.LoadTexture(MEDIA_PATH + "/sprites/objects.png")
	assets.sprites.player   = rl.LoadTexture(MEDIA_PATH + "/sprites/player.png")
	assets.sprites.tools    = rl.LoadTexture(MEDIA_PATH + "/sprites/tools.png")
	assets.sprites.treasure = rl.LoadTexture(MEDIA_PATH + "/sprites/treasure.png")

	assets.tiles[.Desert] = rl.LoadTexture(MEDIA_PATH + "/tiles/desert.png")
	assets.tiles[.Forest] = rl.LoadTexture(MEDIA_PATH + "/tiles/forest.png")
	assets.tiles[.Lava]   = rl.LoadTexture(MEDIA_PATH + "/tiles/lava.png")
	assets.tiles[.Oil]    = rl.LoadTexture(MEDIA_PATH + "/tiles/oil.png")
	assets.tiles[.Winter] = rl.LoadTexture(MEDIA_PATH + "/tiles/winter.png")

	return assets_are_valid(assets)
}

assets_are_valid :: proc(assets: ^Assets) -> bool {
	if !rl.IsTextureValid(assets.screens.game)      do return false
	if !rl.IsTextureValid(assets.screens.highscore) do return false
	if !rl.IsTextureValid(assets.screens.menu)      do return false
	if !rl.IsTextureValid(assets.screens.select)    do return false

	for sound in assets.sounds.bomb {
		if !rl.IsSoundValid(sound) do return false
	}
	if !rl.IsSoundValid(assets.sounds.item)    do return false
	if !rl.IsSoundValid(assets.sounds.menu)    do return false
	if !rl.IsSoundValid(assets.sounds.squish)  do return false
	if !rl.IsSoundValid(assets.sounds.ticking) do return false

	if !rl.IsTextureValid(assets.sprites.bomb)     do return false
	if !rl.IsTextureValid(assets.sprites.enemy)    do return false
	if !rl.IsTextureValid(assets.sprites.objects)  do return false
	if !rl.IsTextureValid(assets.sprites.player)   do return false
	if !rl.IsTextureValid(assets.sprites.tools)    do return false
	if !rl.IsTextureValid(assets.sprites.treasure) do return false

	for tile in assets.tiles {
		if !rl.IsTextureValid(tile) do return false
	}

	return true
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
