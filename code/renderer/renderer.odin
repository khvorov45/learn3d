package renderer

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
	for row in topleft.y ..< bottomright.y {
		for col in topleft.x ..< bottomright.x {
			pixels[row * pixels_dim.x + col] = color
		}
	}
}

draw_pixel :: proc(pixels: ^[]u32, pixels_dim: [2]int, pos: [2]int, color: u32) {
	if pos.x >= 0 && pos.x < pixels_dim.x && pos.y >= 0 && pos.y < pixels_dim.y {
		pixels[pos.y * pixels_dim.x + pos.x] = color
	}
}
