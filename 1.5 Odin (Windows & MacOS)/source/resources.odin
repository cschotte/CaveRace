package caverace

import "core:os"
import "core:path/filepath"

RESOURCE_MEDIA_DIRECTORY  :: "media"
RESOURCE_LEVEL_DIRECTORY  :: "levels"

// resource_path joins a root with a small fixed list of resource components and
// returns an owned path to loaders during startup or level changes.
resource_path :: proc(
	root: string,
	parts: []string,
	allocator := context.allocator,
) -> (path: string, ok: bool) {
	elements: [4]string
	if len(parts) + 1 > len(elements) do return "", false
	elements[0] = root
	copy(elements[1:], parts)
	joined, join_error := filepath.join(elements[:len(parts) + 1], allocator)
	if join_error != nil do return "", false
	return joined, true
}

// resource_root_is_usable checks the required game-screen marker before a
// candidate directory is accepted as a complete resource root.
resource_root_is_usable :: proc(root: string) -> bool {
	marker_path, ok := resource_path(
		root,
		{RESOURCE_MEDIA_DIRECTORY, "screens", "game_border.png"},
		context.temp_allocator,
	)
	return ok && os.is_file(marker_path)
}

// owned_resource_root_if_usable validates and normalizes a candidate while
// making ownership explicit for the caller that keeps the selected path.
owned_resource_root_if_usable :: proc(
	candidate: string,
	allocator := context.allocator,
) -> (root: string, ok: bool) {
	if candidate == "" || !resource_root_is_usable(candidate) do return "", false
	cleaned, clean_error := filepath.clean(candidate, allocator)
	if clean_error != nil do return "", false
	return cleaned, true
}

// find_resource_root_from keeps path selection testable without depending on
// the process that happens to run the tests. The packaged layout is preferred,
// followed by a macOS bundle and the repository development layout.
find_resource_root_from :: proc(
	executable_directory: string,
	working_directory: string,
	allocator := context.allocator,
) -> (root: string, ok: bool) {
	if root, ok = owned_resource_root_if_usable(executable_directory, allocator); ok {
		return
	}

	bundle_root, bundle_error := filepath.join(
		{executable_directory, "..", "Resources"},
		context.temp_allocator,
	)
	if bundle_error == nil {
		if root, ok = owned_resource_root_if_usable(bundle_root, allocator); ok {
			return
		}
	}

	development_root, development_error := filepath.join(
		{executable_directory, "..", "source"},
		context.temp_allocator,
	)
	if development_error == nil {
		if root, ok = owned_resource_root_if_usable(development_root, allocator); ok {
			return
		}
	}

	return owned_resource_root_if_usable(working_directory, allocator)
}

// resolve_resource_root gathers process directories and selects the first
// packaged, bundle, development, or working-directory layout that is usable.
resolve_resource_root :: proc(
	allocator := context.allocator,
) -> (root: string, ok: bool) {
	executable_directory, executable_error := os.get_executable_directory(allocator)
	if executable_error != nil do return "", false
	defer delete(executable_directory, allocator)

	working_directory, working_error := os.get_working_directory(allocator)
	if working_error != nil do return "", false
	defer delete(working_directory, allocator)

	return find_resource_root_from(executable_directory, working_directory, allocator)
}
