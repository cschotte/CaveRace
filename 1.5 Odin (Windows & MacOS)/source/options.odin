package caverace

import "core:fmt"
import "core:os"

// Launch_Options stores the legacy compatibility switches and the -log
// diagnostic switch parsed once and then mapped by Application to render,
// gameplay, and logging policy.
Launch_Options :: struct {
	cheats_enabled: bool,
	slow_mode:      bool,
	verbose_logging: bool,
}

// parse_launch_options recognizes the command-line switches once at startup
// and reports unknown arguments without failing the launch.
parse_launch_options :: proc() -> Launch_Options {
	options: Launch_Options

	for argument in os.args[1:] {
		switch argument {
		case "-powerblast":
			options.cheats_enabled = true
		case "-slow":
			options.slow_mode = true
		case "-log":
			options.verbose_logging = true
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
		fmt.println("     -log for verbose startup/runtime diagnostics (useful for bug reports).")
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

	if options.verbose_logging {
		fmt.println("Verbose logging enabled: extra startup and runtime detail will be printed below.")
	}
}
