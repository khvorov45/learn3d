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
