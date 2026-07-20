package caverace

import "core:strings"
import rl "vendor:raylib"

// Screen_Assets owns gameplay/outcome/records backgrounds and all nine
// front-end images for the complete application asset lifetime.
Screen_Assets :: struct {
	game:      rl.Texture,
	game_over: rl.Texture,
	you_won:   rl.Texture,
	score:     rl.Texture,
	front_end: [FRONT_END_IMAGE_COUNT]rl.Texture,
}

// Music_Cue names every track used by the intro, menu, gameplay, and terminal
// screens.
Music_Cue :: enum {
	Intro_Space,
	Intro_Eldora,
	Intro_Mining,
	Intro_Aliens,
	Intro_Defense,
	Intro_Hero,
	Intro_Bombs,
	Main_Menu,
	Cave_A,
	Cave_B,
	Cave_C,
	Level_Complete,
	You_Won,
	Game_Over,
}

#assert(len(Music_Cue) == 14)
#assert(int(Music_Cue.Intro_Bombs) - int(Music_Cue.Intro_Space) + 1 == INTRO_LAST_IMAGE - INTRO_FIRST_IMAGE + 1)

// Resource manifests keep array indices and enum values as the single mapping
// between domain-facing asset slots and packaged filenames.
FRONT_END_TEXTURE_PATHS :: [FRONT_END_IMAGE_COUNT]string {
	"intro/01_intro_eldora.png",
	"intro/02_intro_mining.png",
	"intro/03_intro_aliens.png",
	"intro/04_intro_defense.png",
	"intro/05_intro_hero.png",
	"intro/06_intro_bombs.png",
	"intro/07_intro_protect.png",
	"screens/menu.png",
	"screens/controls.png",
}

BOMB_SOUND_PATHS :: [BOMB_SOUND_COUNT]string {
	"sounds/bomb01.wav",
	"sounds/bomb02.wav",
	"sounds/bomb03.wav",
	"sounds/bomb04.wav",
}

MUSIC_PATHS :: [Music_Cue]string {
	.Intro_Space    = "music/01_intro_space.ogg",
	.Intro_Eldora   = "music/02_intro_eldora.ogg",
	.Intro_Mining   = "music/03_intro_mining.ogg",
	.Intro_Aliens   = "music/04_intro_aliens.ogg",
	.Intro_Defense  = "music/05_intro_defense.ogg",
	.Intro_Hero     = "music/06_intro_hero.ogg",
	.Intro_Bombs    = "music/07_intro_bombs.ogg",
	.Main_Menu      = "music/08_main_menu.ogg",
	.Cave_A         = "music/09_gameplay_a.ogg",
	.Cave_B         = "music/10_gameplay_b.ogg",
	.Cave_C         = "music/11_gameplay_c.ogg",
	.Level_Complete = "music/12_level_complete.ogg",
	.You_Won        = "music/13_you_won.ogg",
	.Game_Over      = "music/14_game_over.ogg",
}

// Sound_Assets owns all raylib sound handles used when frame events request
// bomb, pickup, enemy, or ticking audio.
Sound_Assets :: struct {
	bomb:    [BOMB_SOUND_COUNT]rl.Sound,
	item:    rl.Sound,
	hit:     rl.Sound,
	squish:  rl.Sound,
	ticking: rl.Sound,
}

// Sprite_Assets groups the vertical sprite sheets consumed by level, actor,
// explosion, and HUD rendering.
Sprite_Assets :: struct {
	bomb:     rl.Texture,
	enemy:    rl.Texture,
	objects:  rl.Texture,
	player:   rl.Texture,
	tools:    rl.Texture,
	treasure: rl.Texture,
}

// Assets is the application-owned aggregate loaded before the main loop and
// released as one unit during shutdown or failed startup.
Assets :: struct {
	screens: Screen_Assets,
	sounds:  Sound_Assets,
	music:   [Music_Cue]rl.Music,
	sprites: Sprite_Assets,
	tiles:   [Tile_Theme]rl.Texture,
}

// load_resource_texture resolves one media-relative path and converts it to a
// temporary C string for raylib during asset initialization.
load_resource_texture :: proc(root, relative_path: string) -> rl.Texture {
	path, ok := resource_path(root, {RESOURCE_MEDIA_DIRECTORY, relative_path})
	if !ok do return {}
	defer delete(path)
	path_cstring, cstring_error := strings.clone_to_cstring(path)
	if cstring_error != nil do return {}
	defer delete(path_cstring)
	return rl.LoadTexture(path_cstring)
}

// load_resource_sound resolves and loads one sound effect when the audio
// device is available during application startup.
load_resource_sound :: proc(root, relative_path: string) -> rl.Sound {
	path, ok := resource_path(root, {RESOURCE_MEDIA_DIRECTORY, relative_path})
	if !ok do return {}
	defer delete(path)
	path_cstring, cstring_error := strings.clone_to_cstring(path)
	if cstring_error != nil do return {}
	defer delete(path_cstring)
	return rl.LoadSound(path_cstring)
}

// load_resource_music resolves a streamed OGG track without decoding the
// complete song into memory during startup.
load_resource_music :: proc(root, relative_path: string) -> rl.Music {
	path, ok := resource_path(root, {RESOURCE_MEDIA_DIRECTORY, relative_path})
	if !ok do return {}
	defer delete(path)
	path_cstring, cstring_error := strings.clone_to_cstring(path)
	if cstring_error != nil do return {}
	defer delete(path_cstring)
	return rl.LoadMusicStream(path_cstring)
}

// load_assets fills the application-owned asset bundle and validates every
// required handle before the main loop is allowed to start. Failure releases
// partial resources and leaves the bundle empty.
load_assets :: proc(assets: ^Assets, resource_root: string, load_audio := true) -> bool {
	assets^ = {}
	assets.screens.game         = load_resource_texture(resource_root, "screens/game_border.png")
	assets.screens.game_over    = load_resource_texture(resource_root, "screens/game_over.png")
	assets.screens.you_won      = load_resource_texture(resource_root, "screens/you_won.png")
	assets.screens.score        = load_resource_texture(resource_root, "screens/Score.png")
	for relative_path, image_index in FRONT_END_TEXTURE_PATHS {
		assets.screens.front_end[image_index] =
			load_resource_texture(resource_root, relative_path)
	}

	if load_audio {
		for relative_path, sound_index in BOMB_SOUND_PATHS {
			assets.sounds.bomb[sound_index] =
				load_resource_sound(resource_root, relative_path)
		}
		assets.sounds.item    = load_resource_sound(resource_root, "sounds/item.wav")
		assets.sounds.hit     = load_resource_sound(resource_root, "sounds/item.wav")
		assets.sounds.squish  = load_resource_sound(resource_root, "sounds/squish.wav")
		assets.sounds.ticking = load_resource_sound(resource_root, "sounds/ticking.wav")
		if rl.IsSoundValid(assets.sounds.hit) {
			rl.SetSoundPitch(assets.sounds.hit, 0.55)
		}

		for relative_path, cue in MUSIC_PATHS {
			assets.music[cue] = load_resource_music(resource_root, relative_path)
		}
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

	if !assets_are_valid(assets, load_audio) {
		unload_assets(assets)
		return false
	}
	return true
}

// assets_are_valid checks dimensions and raylib handles after loading so bad
// packages fail early instead of producing invalid texture accesses later.
assets_are_valid :: proc(assets: ^Assets, require_audio := true) -> bool {
	if !texture_has_size(assets.screens.game, WINDOW_WIDTH, WINDOW_HEIGHT)      do return false
	if !texture_has_size(assets.screens.game_over, WINDOW_WIDTH, WINDOW_HEIGHT) do return false
	if !texture_has_size(assets.screens.you_won, WINDOW_WIDTH, WINDOW_HEIGHT)   do return false
	if !texture_has_size(assets.screens.score, WINDOW_WIDTH, WINDOW_HEIGHT)     do return false
	for texture in assets.screens.front_end {
		if !texture_has_size(texture, WINDOW_WIDTH, WINDOW_HEIGHT) do return false
	}

	if require_audio {
		for sound in assets.sounds.bomb {
			if !rl.IsSoundValid(sound) do return false
		}
		if !rl.IsSoundValid(assets.sounds.item)    do return false
		if !rl.IsSoundValid(assets.sounds.hit)     do return false
		if !rl.IsSoundValid(assets.sounds.squish)  do return false
		if !rl.IsSoundValid(assets.sounds.ticking) do return false
		for music in assets.music {
			if !rl.IsMusicValid(music) do return false
		}
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

// texture_has_size validates full-screen images whose exact dimensions are
// part of the fixed CaveRace presentation contract.
texture_has_size :: proc(texture: rl.Texture, width, height: int) -> bool {
	return rl.IsTextureValid(texture) &&
	       texture.width == i32(width) && texture.height == i32(height)
}

// vertical_sheet_is_valid checks a loaded sprite sheet before rendering begins
// and delegates the dimension-only rule for testability.
vertical_sheet_is_valid :: proc(texture: rl.Texture, sprite_count: int) -> bool {
	return rl.IsTextureValid(texture) && vertical_sheet_dimensions_are_valid(
		int(texture.width),
		int(texture.height),
		sprite_count,
	)
}

// vertical_sheet_dimensions_are_valid enforces the one-tile-wide, row-based
// sprite layout used by every converted legacy sheet.
vertical_sheet_dimensions_are_valid :: proc(width, height, sprite_count: int) -> bool {
	return sprite_count > 0 && width == MAP_TILE_SIZE &&
	       height >= sprite_count * MAP_TILE_SIZE && height % MAP_TILE_SIZE == 0
}

// unload_assets releases every application-owned raylib resource during
// shutdown or failed startup, then clears the handles to make cleanup idempotent.
unload_assets :: proc(assets: ^Assets) {
	unload_texture(assets.screens.game)
	unload_texture(assets.screens.game_over)
	unload_texture(assets.screens.you_won)
	unload_texture(assets.screens.score)
	for texture in assets.screens.front_end {
		unload_texture(texture)
	}

	for sound in assets.sounds.bomb {
		unload_sound(sound)
	}
	unload_sound(assets.sounds.item)
	unload_sound(assets.sounds.hit)
	unload_sound(assets.sounds.squish)
	unload_sound(assets.sounds.ticking)
	for music in assets.music {
		unload_music(music)
	}

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

// unload_texture safely releases one optional texture while walking the asset
// bundle during cleanup.
unload_texture :: proc(texture: rl.Texture) {
	if rl.IsTextureValid(texture) do rl.UnloadTexture(texture)
}

// unload_sound safely releases one optional sound; invalid handles occur when
// audio is unavailable or startup stops after a partial load.
unload_sound :: proc(sound: rl.Sound) {
	if rl.IsSoundValid(sound) do rl.UnloadSound(sound)
}

// unload_music safely releases one optional streaming track.
unload_music :: proc(music: rl.Music) {
	if rl.IsMusicValid(music) do rl.UnloadMusicStream(music)
}
