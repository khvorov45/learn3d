package renderer

project :: proc(point: [3]f32, pixels_dim: [2]int) -> [2]f32 {
	result := point.xy
	result.y = -result.y
	result = result.xy * 128.0 + [2]f32{f32(pixels_dim.x - 1), f32(pixels_dim.y - 1)} * 0.5
	return result
}

clear :: proc(pixels: ^[]u32) {
	for pixel in pixels {
		pixel = 0
	}
}

draw_rect :: proc(
	pixels: ^[]u32,
	pixels_dim: [2]int,
	topleft: [2]int,
	dim: [2]int,
	color: u32,
) {
	bottomright := topleft + dim

	clipped_topleft := [2]int{max(topleft.x, 0), max(topleft.y, 0)}
	clipped_bottomright := [2]int{
		min(bottomright.x, pixels_dim.x),
		min(bottomright.y, pixels_dim.y),
	}

	for row in clipped_topleft.y ..< clipped_bottomright.y {
		for col in clipped_topleft.x ..< clipped_bottomright.x {
			pixels[row * pixels_dim.x + col] = color
		}
	}
}

draw_pixel :: proc(pixels: ^[]u32, pixels_dim: [2]int, pos: [2]int, color: u32) {
	if pos.x >= 0 && pos.x < pixels_dim.x && pos.y >= 0 && pos.y < pixels_dim.y {
		pixels[pos.y * pixels_dim.x + pos.x] = color
	}
}
