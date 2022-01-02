package renderer

import "core:math"
import "core:math/linalg"
import "core:builtin"

Renderer :: struct {
	pixels:          []u32,
	pixels_dim:      [2]int,
	options:         bit_set[DisplayOption],
	faces_to_render: [dynamic]FaceToRender,
}

FaceToRender :: struct {
	avg_z:    f32,
	vertices: [3][3]f32,
	color:    u32,
}

DisplayOption :: enum {
	FilledTriangles,
	Wireframe,
	Vertices,
	Normals,
	Midpoints,
	BackfaceCull,
}

Mesh :: struct {
	vertices:    [dynamic][3]f32,
	faces:       [dynamic]Face,
	rotation:    [3]f32,
	scale:       [3]f32,
	translation: [3]f32,
}

Face :: struct {
	indices: [3]int,
	color:   u32,
}

create_renderer :: proc(width, height: int) -> Renderer {
	renderer: Renderer
	renderer.pixels = make([]u32, width * height)
	renderer.pixels_dim = [2]int{width, height}
	renderer.options = {.BackfaceCull, .FilledTriangles}
	return renderer
}

toggle_option :: proc(renderer: ^Renderer, option: DisplayOption) {
	if option in renderer.options {
		renderer.options ~= {option}
	} else {
		renderer.options |= {option}
	}
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

	back1 := [3]int{5, 4, 6} + first_vertex
	back2 := [3]int{5, 6, 7} + first_vertex

	append(&mesh.vertices, v0)
	append(&mesh.vertices, v1)
	append(&mesh.vertices, v2)
	append(&mesh.vertices, v3)
	append(&mesh.vertices, v4)
	append(&mesh.vertices, v5)
	append(&mesh.vertices, v6)
	append(&mesh.vertices, v7)

	append(&mesh.faces, Face{front1, 0xFFFF0000})
	append(&mesh.faces, Face{front2, 0xFFFF0000})

	append(&mesh.faces, Face{left1, 0xFF00FF00})
	append(&mesh.faces, Face{left2, 0xFF00FF00})

	append(&mesh.faces, Face{right1, 0xFF0000FF})
	append(&mesh.faces, Face{right2, 0xFF0000FF})

	append(&mesh.faces, Face{top1, 0xFFFFFF00})
	append(&mesh.faces, Face{top2, 0xFFFFFF00})

	append(&mesh.faces, Face{bottom1, 0xFFFF00FF})
	append(&mesh.faces, Face{bottom2, 0xFFFF00FF})

	append(&mesh.faces, Face{back1, 0xFF00FFFF})
	append(&mesh.faces, Face{back2, 0xFF00FFFF})
}

render_mesh :: proc(renderer: ^Renderer, mesh: Mesh) {

	builtin.clear(&renderer.faces_to_render)

	scale4 := scale(mesh.scale)

	rotation4 := rotation([3]f32{1, 0, 0}, mesh.rotation.x)
	rotation4 *= rotation([3]f32{0, 1, 0}, mesh.rotation.y)
	rotation4 *= rotation([3]f32{0, 0, 1}, mesh.rotation.z)

	camera_pos := [3]f32{0, 0, -3.5}
	translation4 := translation(mesh.translation - camera_pos)

	transform := translation4 * rotation4 * scale4

	for face in mesh.faces {

		sum_z: f32 = 0
		vertices: [3][3]f32

		for vertex_index, index in face.indices {

			vertex := mesh.vertices[vertex_index]
			vertex_transformed := transform * [4]f32{vertex.x, vertex.y, vertex.z, 1}
			vertices[index] = vertex_transformed.xyz
			sum_z += vertex_transformed.z

		}

		avg_z := sum_z / 3
		face_to_render := FaceToRender{avg_z, vertices, face.color}
		append(&renderer.faces_to_render, face_to_render)

		// NOTE(sen) Keep the faces sorted
		for cur_index := len(renderer.faces_to_render) - 1; cur_index >= 1; cur_index -= 1 {
			this := renderer.faces_to_render[cur_index]
			prev := renderer.faces_to_render[cur_index - 1]
			if this.avg_z > prev.avg_z {
				renderer.faces_to_render[cur_index], renderer.faces_to_render[cur_index - 1] = prev, this
			}
		}

	}

	for face_to_render in renderer.faces_to_render {

		ab := face_to_render.vertices[1] - face_to_render.vertices[0]
		ac := face_to_render.vertices[2] - face_to_render.vertices[0]
		normal := linalg.cross(ab, ac)

		camera_ray := -face_to_render.vertices[0]

		camera_normal_dot := linalg.dot(normal, camera_ray)

		if camera_normal_dot > 0 || !(.BackfaceCull in renderer.options) {

			get_px :: proc(vertex: [3]f32, pixels_dim: [2]int) -> [2]f32 {
				vertex_projected := project(vertex)
				vertex_pixels := screen_world_to_pixels(vertex_projected, 500, pixels_dim)
				return vertex_pixels
			}

			vertices_px: [3][2]f32
			for vertex, index in face_to_render.vertices {
				vertices_px[index] = get_px(vertex, renderer.pixels_dim)
			}

			if .FilledTriangles in renderer.options {
				draw_filled_triangle(renderer, vertices_px, face_to_render.color)
			}

			if .Wireframe in renderer.options {
				draw_line(renderer, vertices_px[0], vertices_px[1], 0xFFFF0000)
				draw_line(renderer, vertices_px[0], vertices_px[2], 0xFFFF0000)
				draw_line(renderer, vertices_px[1], vertices_px[2], 0xFFFF0000)
			}

			if .Vertices in renderer.options {
				for vertex in vertices_px {
					dim := [2]f32{5, 5}
					topleft := vertex - dim * 0.5
					draw_rect(renderer, topleft, dim, 0xFFFFFF00)
				}
			}


			est_center := (face_to_render.vertices[0] + face_to_render.vertices[1] + face_to_render.vertices[2]) /
                 3
			est_center_px := get_px(est_center, renderer.pixels_dim)

			if .Midpoints in renderer.options {
				draw_rect(renderer, est_center_px, [2]f32{4, 4}, 0xFFFF00FF)
			}

			normal_tip := 0.1 * linalg.normalize(normal) + est_center
			normal_tip_px := get_px(normal_tip, renderer.pixels_dim)

			if .Normals in renderer.options {
				draw_line(renderer, est_center_px, normal_tip_px, 0xFFFF00FF)
			}

		}

	}

}

draw_filled_triangle :: proc(renderer: ^Renderer, vertices: [3][2]f32, color: u32) {
	top, mid, bottom := vertices[0], vertices[1], vertices[2]
	if top.y > mid.y {
		top, mid = mid, top
	}
	if mid.y > bottom.y {
		mid, bottom = bottom, mid
	}
	if top.y > mid.y {
		top, mid = mid, top
	}

	midline_x := mid.x
	if top.y != bottom.y {
		midline_x = (mid.y - top.y) / (bottom.y - top.y) * (bottom.x - top.x) + top.x
	}
	midline := [2]f32{midline_x, mid.y}

	// NOTE(sen) Midline
	{
		start := round(mid.x)
		end := round(midline.x)
		if start > end {
			start, end = end, start
		}
		for col in start .. end {
			draw_pixel(renderer, [2]int{col, round(mid.y)}, color)
		}
	}

	// NOTE(sen) Flat bottom
	{
		rise := mid.y - top.y
		if rise != 0 {
			s1 := (mid.x - top.x) / rise
			s2 := (midline.x - top.x) / rise
			if s1 > s2 {
				s1, s2 = s2, s1
			}
			x1_cur := top.x
			x2_cur := top.x
			for row in round(top.y) ..< round(mid.y) {
				for col in round(x1_cur) .. round(x2_cur) {
					draw_pixel(renderer, [2]int{col, row}, color)
				}
				x1_cur += s1
				x2_cur += s2
			}
		}
	}

	// NOTE(sen) Flat top
	{
		rise := bottom.y - mid.y
		if rise != 0 {
			// NOTE(sen) Step from the top to prevent fp-error caused alignment problems
			s1 := (mid.x - bottom.x) / rise
			s2 := (midline.x - bottom.x) / rise
			x1_cur := mid.x
			x2_cur := midline.x
			if x1_cur > x2_cur {
				x1_cur, x2_cur = x2_cur, x1_cur
				s1, s2 = s2, s1
			}
			for row in round(mid.y) .. round(bottom.y) {
				for col in round(x1_cur) .. round(x2_cur) {
					draw_pixel(renderer, [2]int{col, row}, color)
				}
				x1_cur -= s1
				x2_cur -= s2
			}
		}
	}

}

// Returns offset from screen center in world units
project :: proc(point_camera_space: [3]f32) -> [2]f32 {

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

clear :: proc(renderer: ^Renderer) {
	for pixel in &renderer.pixels {
		pixel = 0
	}
}

draw_rect :: proc(renderer: ^Renderer, topleft: [2]f32, dim: [2]f32, color: u32) {
	bottomright := topleft + dim

	clamped_topleft := clamp_2f32(
		topleft,
		[2]f32{0, 0},
		linalg.to_f32(renderer.pixels_dim - 1),
	)
	clamped_bottomright := clamp_2f32(
		bottomright,
		[2]f32{0, 0},
		linalg.to_f32(renderer.pixels_dim),
	)

	for row in round(clamped_topleft.y) ..< round(clamped_bottomright.y) {
		for col in round(clamped_topleft.x) ..< round(clamped_bottomright.x) {
			renderer.pixels[row * renderer.pixels_dim.x + col] = color
		}
	}
}

draw_line :: proc(renderer: ^Renderer, start: [2]f32, end: [2]f32, color: u32) {
	delta := end - start
	run_length := max(abs(delta.x), abs(delta.y))
	inc := delta / run_length

	cur := start
	for _ in 0 ..< int(run_length) {
		cur_rounded := round(cur)
		draw_pixel(renderer, cur_rounded, color)
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

clamp_f32 :: proc(input: f32, min: f32, max: f32) -> f32 {
	result := builtin.clamp(input, min, max)
	return result
}

clamp_2int :: proc(input: [2]int, min: [2]int, max: [2]int) -> [2]int {
	result := input
	result.x = clamp_int(input.x, min.x, max.x)
	result.y = clamp_int(input.y, min.y, max.y)
	return result
}

clamp_2f32 :: proc(input: [2]f32, min: [2]f32, max: [2]f32) -> [2]f32 {
	result := input
	result.x = clamp_f32(input.x, min.x, max.x)
	result.y = clamp_f32(input.y, min.y, max.y)
	return result
}

clamp :: proc {
	clamp_int,
	clamp_2int,
	clamp_f32,
	clamp_2f32,
}

draw_pixel :: proc(renderer: ^Renderer, pos: [2]int, color: u32) {
	if pos.x >= 0 && pos.x < renderer.pixels_dim.x && pos.y >= 0 && pos.y < renderer.pixels_dim.y {
		renderer.pixels[pos.y * renderer.pixels_dim.x + pos.x] = color
	}
}

color_to_u32argb :: proc(color: [4]f32) -> u32 {
	result := u32(color.a) << 24 | u32(color.r) << 16 | u32(color.g) << 8 | u32(color.b)
	return result
}

identity :: proc() -> matrix[4, 4]f32 {
	result: matrix[4, 4]f32
	result[0, 0] = 1
	result[1, 1] = 1
	result[2, 2] = 1
	result[3, 3] = 1
	return result
}

scale :: proc(axes: [3]f32) -> matrix[4, 4]f32 {
	result: matrix[4, 4]f32
	result[0, 0] = axes.x
	result[1, 1] = axes.y
	result[2, 2] = axes.z
	result[3, 3] = 1
	return result
}

translation :: proc(axes: [3]f32) -> matrix[4, 4]f32 {
	result := identity()
	result[0, 3] = axes.x
	result[1, 3] = axes.y
	result[2, 3] = axes.z
	return result
}

rotation :: proc(axis: [3]f32, angle: f32) -> matrix[4, 4]f32 {
	cos := math.cos(angle)
	sin := math.sin(angle)
	icos := 1 - cos
	isin := 1 - sin

	result: matrix[4, 4]f32

	result[0, 0] = cos + axis.x * axis.x * icos
	result[0, 1] = axis.x * axis.y * icos - axis.z * sin
	result[0, 2] = axis.x * axis.z * icos + axis.y * sin
	result[0, 3] = 0

	result[1, 0] = axis.y * axis.x * icos + axis.z * sin
	result[1, 1] = cos + axis.y * axis.y * icos
	result[1, 2] = axis.y * axis.z * icos - axis.x * sin
	result[1, 3] = 0

	result[2, 0] = axis.z * axis.x * icos - axis.y * sin
	result[2, 1] = axis.z * axis.y * icos + axis.x * sin
	result[2, 2] = cos + axis.z * axis.z * icos
	result[2, 3] = 0

	result[3, 3] = 1

	return result
}

to_radians :: proc(degrees: f32) -> f32 {
	return math.RAD_PER_DEG * degrees
}

to_degrees :: proc(radians: f32) -> f32 {
	return math.DEG_PER_RAD * radians
}
