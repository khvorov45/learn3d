package learn3d

import "core:os"

read_file :: proc(path: string) -> []u8 {
	content, ok := os.read_entire_file(path)
	assert(ok)
	return content
}
