package renderer

import "core:math"

// Returns offset from screen center in world units
project :: proc(point: [3]f32, camera: [3]f32) -> [2]f32 {

	point_camera_space := point - camera

	point_screen := point_camera_space.xy
	point_screen /= point_camera_space.z

	return point_screen
}

// Takes offset from screen center in world units
screen_world_to_pixels :: proc(point_screen_world: [2]f32, world_to_pixels: f32, pixels_dim: [2]int) -> [2]f32 {

	point_pixels := point_screen_world * [2]f32{world_to_pixels, -world_to_pixels}

	half_dim := [2]f32{f32(pixels_dim.x), f32(pixels_dim.y)} * 0.5
	point_pixels_from_corner := point_pixels + half_dim

	return point_pixels_from_corner
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

	clamped_topleft := [2]int{max(topleft.x, 0), max(topleft.y, 0)}
	clamped_bottomright := [2]int{
		min(bottomright.x, pixels_dim.x),
		min(bottomright.y, pixels_dim.y),
	}

	for row in clamped_topleft.y ..< clamped_bottomright.y {
		for col in clamped_topleft.x ..< clamped_bottomright.x {
			pixels[row * pixels_dim.x + col] = color
		}
	}
}

draw_line :: proc(
	pixels: ^[]u32,
	pixels_dim: [2]int,
	start: [2]int,
	end: [2]int,
	color: u32,
) {
	delta := end - start
	run_length := max(abs(delta.x), abs(delta.y))
	inc := [2]f32{f32(delta.x), f32(delta.y)} / f32(run_length)

	cur := [2]f32{f32(start.x), f32(start.y)}
	for _ in 0..<run_length {
		cur_rounded := round(cur)
		if between(cur_rounded, [2]int{0, 0}, pixels_dim - 1) {
			pixels[cur_rounded.y * pixels_dim.x + cur_rounded.x] = color
		}
		cur += inc
	}
}

between_int :: proc(input: int, left: int, right: int) -> bool {
	result := input >= left && input <= right
	return result
}

between_2int :: proc(input: [2]int, left: [2]int, right: [2]int) -> bool {
	result := between(input.x, left.x, right.x) && between(input.y, left.y, right.y)
	return result
}

between :: proc{between_int, between_2int}

round_f32 :: proc(input: f32) -> int {
	result := int(input + 0.5)
	return result
}

round_2f32 :: proc(input: [2]f32) -> [2]int {
	result := [2]int{round(input.x), round(input.y)}
	return result
}

round :: proc{round_f32, round_2f32}

safe_ratio1 :: proc(v1: f32, v2: f32) -> f32 {
	result: f32 = 1
	if v2 != 0 {
		result = v1 / v2
	}
	return result
}

clamp_int :: proc(input: int, from: int, to: int) -> int {
	result := min(to, max(from, input))
	return result
}

clamp_2int :: proc(input: [2]int, min: [2]int, max: [2]int) -> [2]int {
	result := input
	result.x = clamp_int(input.x, min.x, max.x)
	result.y = clamp_int(input.y, min.y, max.y)
	return result
}

clamp :: proc{clamp_int, clamp_2int}

draw_pixel :: proc(pixels: ^[]u32, pixels_dim: [2]int, pos: [2]int, color: u32) {
	if pos.x >= 0 && pos.x < pixels_dim.x && pos.y >= 0 && pos.y < pixels_dim.y {
		pixels[pos.y * pixels_dim.x + pos.x] = color
	}
}

color_to_u32argb :: proc(color: [4]f32) -> u32 {
	result := u32(color.a) << 24 | u32(color.r) << 16 | u32(color.g) << 8 | u32(color.b)
	return result
}
