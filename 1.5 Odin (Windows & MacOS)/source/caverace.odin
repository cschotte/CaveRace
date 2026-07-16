package caverace

import "core:fmt"

main :: proc() {
	fmt.println("CaveRace (1.5) Copyright 1997-2026 NavaTron B.V.")

	options := parse_launch_options()
	print_launch_options(options)

	if !run_application(options) do return

	fmt.println("\nThanks for playing CaveRace!")
	fmt.println("Visit www.caverace.com for more information.")
}
