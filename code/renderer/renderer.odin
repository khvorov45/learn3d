package renderer

import "core:math"

project :: proc(point: [3]f32, pixels_dim: [2]int, camera: [3]f32, fov: f32) -> [2]f32 {

	point_camera_space := point - camera

	point_screen := point_camera_space.xy
	point_screen /= point_camera_space.z

	screen_width := 2 * math.tan(fov * 0.5)
	aspect_ratio := f32(pixels_dim.y) / f32(pixels_dim.x)
	screen_height := aspect_ratio * screen_width

	pixels_per_world_unit: f32 = 550
	point_pixels := point_screen * pixels_per_world_unit

	half_dim := [2]f32{f32(pixels_dim.x), f32(pixels_dim.y)} * 0.5
	point_pixels_bottomleft := point_pixels + half_dim

	return point_pixels_bottomleft
}

rotate_x :: proc(vec: [3]f32, angle: f32) -> [3]f32 {
	result := vec
	cos_angle := math.cos(angle)
	sin_angle := math.sin(angle)
	result.y = vec.y * cos_angle - vec.z * sin_angle
	result.z = vec.y * sin_angle + vec.z * cos_angle
	return result
}

rotate_y :: proc(vec: [3]f32, angle: f32) -> [3]f32 {
	result := vec
	cos_angle := math.cos(angle)
	sin_angle := math.sin(angle)
	result.x = vec.x * cos_angle - vec.z * sin_angle
	result.z = vec.x * sin_angle + vec.z * cos_angle
	return result
}

rotate_z :: proc(vec: [3]f32, angle: f32) -> [3]f32 {
	result := vec
	cos_angle := math.cos(angle)
	sin_angle := math.sin(angle)
	result.x = vec.x * cos_angle - vec.y * sin_angle
	result.y = vec.x * sin_angle + vec.y * cos_angle
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

color_to_u32argb :: proc(color: [4]f32) -> u32 {
	result := u32(color.a) << 24 | u32(color.r) << 16 | u32(color.g) << 8 | u32(color.b)
	return result
}
