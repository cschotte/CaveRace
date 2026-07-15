package caverace

import "core:fmt"
import "core:os"

Launch_Options :: struct {
	cheats_enabled: bool,
	slow_mode:      bool,
}

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

print_launch_options :: proc(options: Launch_Options) {
	if len(os.args) <= 1 {
		fmt.println("Use: -powerblast for cheats, key F1 to F5.")
		fmt.println("     -slow for slow PCs.")
	}

	if options.cheats_enabled {
		fmt.println("Cheats enabled! Press F1 to F5 for powerups.")
	}

	if options.slow_mode {
		fmt.println("Slow mode enabled! Game will run faster.")
	}
}
