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
	defer image.image_free(load_result)

	image_data := (cast([^]u32)load_result)[:dim.x * dim.y]

	// NOTE(khvorov) Empty extra row and column for bilinear sampling
	dim_expanded := dim + 1
	my_image_data := make([]u32, dim_expanded.x * dim_expanded.y)

	for row in 0 ..< dim.y {
		for col in 0 ..< dim.x {

			px_index := row * dim.x + col
			px := image_data[px_index]

			abgr := u32le(px)
			r := (abgr & 0x000000FF) >> 0
			g := (abgr & 0x0000FF00) >> 8
			b := (abgr & 0x00FF0000) >> 16
			a := (abgr & 0xFF000000) >> 24
			px_converted := u32((a << 24) | (r << 16) | (g << 8) | (b << 0))

			my_px_index := (row + 1) * (dim_expanded.x) + col
			my_image_data[my_px_index] = px_converted
		}
	}

	pitch := -dim_expanded.x

	last_row := my_image_data[(dim_expanded.y - 1) * dim_expanded.x:]

	return Texture{raw_data(last_row), dim, pitch}
}
