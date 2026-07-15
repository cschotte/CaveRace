package caverace

import "core:os"
import "core:fmt"

import rl "vendor:raylib"

/*
index := rl.GetRandomValue(0, 3)
rl.PlaySound(assets.sounds.bomb[index])
*/

cheat_enabled := false
slow_enabled := false

screens : struct {
	game:       rl.Texture,
	highscore:  rl.Texture,
	menu:       rl.Texture,
	select:     rl.Texture,
}

sounds : struct {
	bomb:       [4]rl.Sound,
	item:	    rl.Sound,
	menu:	    rl.Sound,
	squish:	    rl.Sound,
	ticking:    rl.Sound,
}

sprites : struct {
	bomb:       rl.Texture,
	enemy:      rl.Texture,
	objects:    rl.Texture,
	player:     rl.Texture,
	tools:      rl.Texture,
	treasure:   rl.Texture,
}

// backround tiles, we have 5 different tiles: desert, forest, lava, oil and winter
tiles : [5]rl.Texture

// The game map is a 19x11 grid, where each cell can contain different types of objects,
// such as background tiles, items, treasures, enemies, and the player. The original level
// files store this information in a specific format, which we will represent using a struct.
MAP_WIDTH	:: 19
MAP_HEIGHT	:: 11
MAP_GRID	:: [MAP_WIDTH][MAP_HEIGHT]u8

// This is the exact layout stored in the original 1,045-byte level files.
MAP_DATA	:: struct {
	background: MAP_GRID,
	item:       MAP_GRID,
	treasure:   MAP_GRID,
	enemy:      MAP_GRID,
	player:     MAP_GRID,
}

// Ensure that the size of MAP_DATA matches the expected size of 1,045 bytes.
#assert(size_of(MAP_DATA) == 1045)

// Bombs are runtime state and were not included in the original level files.
MAP			:: struct {
	using data: MAP_DATA,
	bomb:       MAP_GRID,
}

// 
game_map: MAP

// The main entry point of the program. This function initializes the game, loads resources, and enters the main game loop.
main :: proc() {
	// Print copyright and usage information
	fmt.println("CaveRace (1.5) Copyright 1997-2026 NavaTron B.V.")

	// Check for command line arguments and display usage information if none are provided
	if len(os.args) <= 1 {
		fmt.println("Use: -powerblast for cheats, key F1 to F5.")
  		fmt.println("     -slow for slow PC's.")
	}

	// Parse command line arguments
	for arg in os.args[1:] {
		switch arg {
			case "-powerblast":
				cheat_enabled = true
				fmt.println("Cheats enabled! Press F1 to F5 for powerups.")
			case "-slow":
				slow_enabled = true
				fmt.println("Slow mode enabled! Game will run faster.")
			case:
				fmt.println("Unknown argument: ", arg)
		}
	}

	// Initialization
	rl.InitWindow(640, 400, "CaveRace")
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	// Set our game to run at 60 frames-per-second
	rl.SetTargetFPS(60)

	// Load game resources
	loadResources()
	defer unloadResources()

	// Main game loop
	for !rl.WindowShouldClose() {
		// Update

		// Draw
		rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
        	drawMenu()
		rl.EndDrawing()
	}

	// Exit message
	fmt.println("\nThanks for playing CaveRace!")
	fmt.println("visit www.caverace.com for more information.");
}

// Load game resources
loadResources :: proc() {
	screens.game		= rl.LoadTexture("media/screens/game.png")
	screens.highscore	= rl.LoadTexture("media/screens/highscore.png")
	screens.menu		= rl.LoadTexture("media/screens/menu.png")
	screens.select		= rl.LoadTexture("media/screens/select.png")

	sounds.bomb[0]		= rl.LoadSound("media/sounds/bomb01.wav")
	sounds.bomb[1]		= rl.LoadSound("media/sounds/bomb02.wav")
	sounds.bomb[2]		= rl.LoadSound("media/sounds/bomb03.wav")
	sounds.bomb[3]		= rl.LoadSound("media/sounds/bomb04.wav")
	sounds.item			= rl.LoadSound("media/sounds/item.wav")
	sounds.menu			= rl.LoadSound("media/sounds/menu.wav")
	sounds.squish		= rl.LoadSound("media/sounds/squish.wav")
	sounds.ticking		= rl.LoadSound("media/sounds/ticking.wav")

	sprites.bomb		= rl.LoadTexture("media/sprites/bomb.png")
	sprites.enemy		= rl.LoadTexture("media/sprites/enemy.png")
	sprites.objects		= rl.LoadTexture("media/sprites/objects.png")
	sprites.player      = rl.LoadTexture("media/sprites/player.png")
	sprites.tools       = rl.LoadTexture("media/sprites/tools.png")
	sprites.treasure    = rl.LoadTexture("media/sprites/treasure.png")
	
	tiles[0]			= rl.LoadTexture("media/tiles/desert.png")
	tiles[1]			= rl.LoadTexture("media/tiles/forest.png")
	tiles[2]			= rl.LoadTexture("media/tiles/lava.png")
	tiles[3]			= rl.LoadTexture("media/tiles/oil.png")
	tiles[4]			= rl.LoadTexture("media/tiles/winter.png")
}

// Unload game resources
unloadResources :: proc() {
	rl.UnloadTexture(screens.game)
	rl.UnloadTexture(screens.highscore)
	rl.UnloadTexture(screens.menu)
	rl.UnloadTexture(screens.select)

	rl.UnloadSound(sounds.bomb[0])
	rl.UnloadSound(sounds.bomb[1])
	rl.UnloadSound(sounds.bomb[2])
	rl.UnloadSound(sounds.bomb[3])
	rl.UnloadSound(sounds.item)
	rl.UnloadSound(sounds.menu)
	rl.UnloadSound(sounds.squish)
	rl.UnloadSound(sounds.ticking)

	rl.UnloadTexture(sprites.bomb)
	rl.UnloadTexture(sprites.enemy)
	rl.UnloadTexture(sprites.objects)
	rl.UnloadTexture(sprites.player)
	rl.UnloadTexture(sprites.tools)
	rl.UnloadTexture(sprites.treasure)

	rl.UnloadTexture(tiles[0])
	rl.UnloadTexture(tiles[1])
	rl.UnloadTexture(tiles[2])
	rl.UnloadTexture(tiles[3])
	rl.UnloadTexture(tiles[4])
}

// Draw the main menu
drawMenu :: proc() {
	rl.DrawTexture(screens.menu, 0, 0, rl.WHITE)
}
