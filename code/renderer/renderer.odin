package renderer

import "core:math"
import "core:math/linalg"
import "core:builtin"

Mesh :: struct {
	vertices: [dynamic][3]f32,
	faces:    [dynamic][3]int,
	rotation: [3]f32,
}

append_box :: proc(mesh: ^Mesh, bottomleft: [3]f32, dim: [3]f32) {

	v0 := bottomleft + [3]f32{0, dim.y, 0}
	v1 := bottomleft + [3]f32{dim.x, dim.y, 0}
	v2 := bottomleft + [3]f32{0, 0, 0}
	v3 := bottomleft + [3]f32{dim.x, 0, 0}
	v4 := v0 + [3]f32{0, 0, dim.z}
	v5 := v1 + [3]f32{0, 0, dim.z}
	v6 := v2 + [3]f32{0, 0, dim.z}
	v7 := v3 + [3]f32{0, 0, dim.z}

	first_vertex := len(mesh.vertices)

	front1 := [3]int{0, 1, 2} + first_vertex
	front2 := [3]int{2, 1, 3} + first_vertex

	left1 := [3]int{0, 6, 4} + first_vertex
	left2 := [3]int{0, 2, 6} + first_vertex

	right1 := [3]int{1, 5, 7} + first_vertex
	right2 := [3]int{3, 1, 7} + first_vertex

	top1 := [3]int{0, 4, 1} + first_vertex
	top2 := [3]int{1, 4, 5} + first_vertex

	bottom1 := [3]int{2, 3, 6} + first_vertex
	bottom2 := [3]int{3, 7, 6} + first_vertex

	back1 := [3]int{4, 5, 6} + first_vertex
	back2 := [3]int{6, 5, 7} + first_vertex

	append(&mesh.vertices, v0)
	append(&mesh.vertices, v1)
	append(&mesh.vertices, v2)
	append(&mesh.vertices, v3)
	append(&mesh.vertices, v4)
	append(&mesh.vertices, v5)
	append(&mesh.vertices, v6)
	append(&mesh.vertices, v7)

	append(&mesh.faces, front1)
	append(&mesh.faces, front2)

	append(&mesh.faces, left1)
	append(&mesh.faces, left2)

	append(&mesh.faces, right1)
	append(&mesh.faces, right2)

	append(&mesh.faces, top1)
	append(&mesh.faces, top2)

	append(&mesh.faces, bottom1)
	append(&mesh.faces, bottom2)

	append(&mesh.faces, back1)
	append(&mesh.faces, back2)
}

render_mesh :: proc(pixels: ^[]u32, pixels_dim: [2]int, mesh: Mesh) {

	for face in mesh.faces {

		vertices: [3][3]f32
		for vertex_index, index in face {
			vertices[index] = rotate_axis_aligned(mesh.vertices[vertex_index], mesh.rotation)
		}

		ab := vertices[1] - vertices[0]
		ac := vertices[2] - vertices[0]
		normal := linalg.cross(ab, ac)

		camera_pos := [3]f32{0, 0, -4.5}
		camera_ray := camera_pos - vertices[0]

		camera_normal_dot := linalg.dot(normal, camera_ray)

		if camera_normal_dot > 0 {

			get_px :: proc(vertex: [3]f32, camera_pos: [3]f32, pixels_dim: [2]int) -> [2]int {
				vertex_projected := project(vertex, camera_pos)
				vertex_pixels := screen_world_to_pixels(vertex_projected, 500, pixels_dim)
				px := [2]int{int(vertex_pixels.x), int(vertex_pixels.y)}
				return px
			}

			when true {
				est_center := (vertices[0] + vertices[1] + vertices[2]) / 3
				est_center_px := get_px(est_center, camera_pos, pixels_dim)
				//draw_rect(pixels, pixels_dim, est_center_px, [2]int{4, 4}, 0xFFFF00FF)

				normal_tip := 0.1 * linalg.normalize(normal) + est_center
				normal_tip_px := get_px(normal_tip, camera_pos, pixels_dim)
				draw_line(pixels, pixels_dim, est_center_px, normal_tip_px, 0xFFFF00FF)
			}

			vertices_px: [3][2]int
			for vertex, index in vertices {
				vertices_px[index] = get_px(vertex, camera_pos, pixels_dim)
				//draw_rect(pixels, pixels_dim, vertices_px[index], [2]int{4, 4}, 0xFFFFFF00)
			}

			draw_line(pixels, pixels_dim, vertices_px[0], vertices_px[1], 0xFFFF0000)
			draw_line(pixels, pixels_dim, vertices_px[0], vertices_px[2], 0xFFFF0000)
			draw_line(pixels, pixels_dim, vertices_px[1], vertices_px[2], 0xFFFF0000)

		}

	}

}

// Returns offset from screen center in world units
project :: proc(point: [3]f32, camera: [3]f32) -> [2]f32 {

	point_camera_space := point - camera

	point_screen := point_camera_space.xy
	point_screen /= point_camera_space.z

	return point_screen
}

// Takes offset from screen center in world units
screen_world_to_pixels :: proc(
	point_screen_world: [2]f32,
	world_to_pixels: f32,
	pixels_dim: [2]int,
) -> [2]f32 {

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

rotate_axis_aligned :: proc(vec: [3]f32, angles: [3]f32) -> [3]f32 {
	result := vec
	result = rotate_x(result, angles.x)
	result = rotate_y(result, angles.y)
	result = rotate_z(result, angles.z)
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

	clamped_topleft := clamp_2int(topleft, [2]int{0, 0}, pixels_dim)
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
	for _ in 0 ..< run_length {
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

between :: proc {
	between_int,
	between_2int,
}

round_f32 :: proc(input: f32) -> int {
	result := int(math.round(input))
	return result
}

round_2f32 :: proc(input: [2]f32) -> [2]int {
	result := [2]int{round(input.x), round(input.y)}
	return result
}

round :: proc {
	round_f32,
	round_2f32,
}

safe_ratio1 :: proc(v1: f32, v2: f32) -> f32 {
	result: f32 = 1
	if v2 != 0 {
		result = v1 / v2
	}
	return result
}

clamp_int :: proc(input: int, min: int, max: int) -> int {
	result := builtin.clamp(input, min, max)
	return result
}

clamp_2int :: proc(input: [2]int, min: [2]int, max: [2]int) -> [2]int {
	result := input
	result.x = clamp_int(input.x, min.x, max.x)
	result.y = clamp_int(input.y, min.y, max.y)
	return result
}

clamp :: proc {
	clamp_int,
	clamp_2int,
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
