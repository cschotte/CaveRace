package caverace

import rl "vendor:raylib"

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
	tiles:   [5]rl.Texture,
}

load_assets :: proc(assets: ^Assets) {
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

	assets.tiles[0] = rl.LoadTexture(MEDIA_PATH + "/tiles/desert.png")
	assets.tiles[1] = rl.LoadTexture(MEDIA_PATH + "/tiles/forest.png")
	assets.tiles[2] = rl.LoadTexture(MEDIA_PATH + "/tiles/lava.png")
	assets.tiles[3] = rl.LoadTexture(MEDIA_PATH + "/tiles/oil.png")
	assets.tiles[4] = rl.LoadTexture(MEDIA_PATH + "/tiles/winter.png")
}

unload_assets :: proc(assets: ^Assets) {
	rl.UnloadTexture(assets.screens.game)
	rl.UnloadTexture(assets.screens.highscore)
	rl.UnloadTexture(assets.screens.menu)
	rl.UnloadTexture(assets.screens.select)

	for sound in assets.sounds.bomb {
		rl.UnloadSound(sound)
	}
	rl.UnloadSound(assets.sounds.item)
	rl.UnloadSound(assets.sounds.menu)
	rl.UnloadSound(assets.sounds.squish)
	rl.UnloadSound(assets.sounds.ticking)

	rl.UnloadTexture(assets.sprites.bomb)
	rl.UnloadTexture(assets.sprites.enemy)
	rl.UnloadTexture(assets.sprites.objects)
	rl.UnloadTexture(assets.sprites.player)
	rl.UnloadTexture(assets.sprites.tools)
	rl.UnloadTexture(assets.sprites.treasure)

	for tile in assets.tiles {
		rl.UnloadTexture(tile)
	}
}
