package learn3d

import "vendor:stb/image"

read_image :: proc(file_data: []u8) -> Texture {

	dim: [2]int
	channels_in_file: i32
	load_result := image.load_from_memory(
		raw_data(file_data),
		i32(len(file_data)),
		cast(^i32)&dim.x,
		cast(^i32)&dim.y,
		&channels_in_file,
		4,
	)
	assert(load_result != nil)

	image_data := (cast([^]u32)load_result)[:dim.x * dim.y]

	for px in &image_data {
		abgr := u32le(px)
		r := (abgr & 0x000000FF) >> 0
		g := (abgr & 0x0000FF00) >> 8
		b := (abgr & 0x00FF0000) >> 16
		a := (abgr & 0xFF000000) >> 24
		px = u32((a << 24) | (r << 16) | (g << 8) | (b << 0))
	}

	pitch := -dim.x

	last_row := image_data[(dim.y - 1) * dim.x:]

	return Texture{raw_data(last_row), dim, pitch}
}
