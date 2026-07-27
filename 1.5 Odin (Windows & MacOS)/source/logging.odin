package caverace

import "core:fmt"

// log_step prints one diagnostic line when verbose logging (-log) is enabled.
// Every call site is unbuffered (core:fmt flushes by default), so the last
// line printed before an unexpected termination reliably marks the last
// completed step, which is the whole point of this switch: pinpointing where
// a silent startup crash on another machine actually happens.
log_step :: proc(enabled: bool, format: string, args: ..any) {
	if !enabled do return
	fmt.print("[LOG] ")
	fmt.printfln(format, ..args)
}
