package caverace

import "core:fmt"
import "core:os"

// Launch_Options stores the two legacy compatibility switches parsed once and
// then mapped by Application to render and gameplay policy.
Launch_Options :: struct {
	cheats_enabled: bool,
	slow_mode:      bool,
}

// parse_launch_options recognizes the two legacy command-line switches once at
// startup and reports unknown arguments without failing the launch.
parse_launch_options :: proc() -> Launch_Options {
	options: Launch_Options

	for argument in os.args[1:] {
		switch argument {
		case "-powerblast":
			options.cheats_enabled = true
		case "-slow":
			options.slow_mode = true
		case:
			fmt.println("Unknown argument: ", argument)
		}
	}

	return options
}

// print_launch_options reports usage and active compatibility modes after
// parsing, before platform initialization begins.
print_launch_options :: proc(options: Launch_Options) {
	if len(os.args) == 1 {
		fmt.println()
		fmt.println("Use: -powerblast for cheats, key F1 to F5, key 1 for a screenshot.")
		fmt.println("     -slow for slow PCs.")
	}

	if options.cheats_enabled {
		fmt.println("Cheats enabled! Press F1 to F5 for powerups, 1 for a screenshot.")
	}

	if options.slow_mode {
		fmt.printf(
			"Slow mode enabled: %d FPS rendering, %d Hz gameplay.\n",
			SLOW_RENDER_FPS,
			GAMEPLAY_TICK_HZ,
		)
	}
}
