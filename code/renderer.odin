package learn3d

import "core:math"
import "core:math/linalg"
import "core:builtin"
import "core:slice"
import "core:os"

Renderer :: struct {
	pixels:                []u32,
	pixels_dim:            [2]int,
	options:               bit_set[DisplayOption],
	vertices_camera_space: [dynamic][4]f32,
	z_buffer:              []f32,
	camera_pos:            [3]f32,
	camera_axes:           [3][3]f32,
}

FaceDepth :: struct {
	face:  int,
	depth: f32,
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
	vertices:    [][3]f32,
	faces:       []Face,
	rotation:    [3]f32,
	scale:       [3]f32,
	translation: [3]f32,
}

Face :: struct {
	indices: [3]int,
	color:   [4]f32,
	texture: [3][2]f32,
}

Texture :: struct {
	memory: [^]u32,
	dim:    [2]int,
	pitch:  int,
}

create_renderer :: proc(width, height: int) -> Renderer {
	renderer := Renderer {
		pixels = make([]u32, width * height),
		pixels_dim = [2]int{width, height},
		options = {.BackfaceCull, .FilledTriangles},
		z_buffer = make([]f32, width * height),
		camera_axes = [3][3]f32{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}},
	}
	clear(&renderer)
	return renderer
}

toggle_option :: proc(renderer: ^Renderer, option: DisplayOption) {
	if option in renderer.options {
		renderer.options ~= {option}
	} else {
		renderer.options |= {option}
	}
}

render_mesh :: proc(renderer: ^Renderer, mesh: Mesh, texture: Texture) {

	builtin.clear(&renderer.vertices_camera_space)

	scale4 := scale(mesh.scale)

	rotation4 := rotation([3]f32{1, 0, 0}, mesh.rotation.x)
	rotation4 *= rotation([3]f32{0, 1, 0}, mesh.rotation.y)
	rotation4 *= rotation([3]f32{0, 0, 1}, mesh.rotation.z)

	translation4 := translation(mesh.translation)

	world_transform := translation4 * rotation4 * scale4

	camera_transform := look_direction(
		renderer.camera_pos,
		renderer.camera_axes.z,
		renderer.camera_axes.y,
	)

	model_to_camera_transform := camera_transform * world_transform

	// NOTE(sen) Transfrom from model to camera
	for vertex in mesh.vertices {
		vertex_camera := model_to_camera_transform * [4]f32{vertex.x, vertex.y, vertex.z, 1}
		append(&renderer.vertices_camera_space, vertex_camera)
	}

	// NOTE(sen) Draw triangles

	width_over_height := f32(renderer.pixels_dim.x) / f32(renderer.pixels_dim.y)
	projection4 := perspective(width_over_height, to_radians(80), 100, 0.1)

	light_ray := linalg.normalize([3]f32{0, 0, 1})

	for face in mesh.faces {

		vertices: [3][4]f32
		for fi, vi in face.indices {
			vert := renderer.vertices_camera_space[fi]
			vertices[vi] = [4]f32{vert.x, vert.y, vert.z, 1}
		}

		ab := vertices[1].xyz - vertices[0].xyz
		ac := vertices[2].xyz - vertices[0].xyz
		normal := linalg.normalize(linalg.cross(ab, ac))

		camera_ray := -vertices[0].xyz

		camera_normal_dot := linalg.dot(normal, camera_ray)
		light_normal_dot := clamp(linalg.dot(normal, -light_ray), 0, 1)

		if camera_normal_dot > 0 || !(.BackfaceCull in renderer.options) {

			get_px :: proc(vertex: [4]f32, proj: matrix[4, 4]f32, pixels_dim: [2]int) -> [2]f32 {
				vertex_projected := proj * vertex
				if vertex_projected.w != 0 {
					vertex_projected.xyz /= vertex_projected.w
				}
				vertex_pixels := ndc_to_pixels(vertex_projected.xy, pixels_dim)
				return vertex_pixels
			}

			vertices_px: [3][2]f32
			og_zw: [3][2]f32
			for vertex, index in vertices {
				vertex_projected := projection4 * vertex
				if vertex_projected.w != 0 {
					vertex_projected.xyz /= vertex_projected.w
				}
				vertices_px[index] = ndc_to_pixels(vertex_projected.xy, renderer.pixels_dim)
				og_zw[index] = vertex_projected.zw
			}

			if .FilledTriangles in renderer.options {
				shaded_color := face.color
				shaded_color.rgb *= light_normal_dot
				draw_triangle(renderer, vertices_px, shaded_color, face.texture, og_zw, texture)
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


			est_center := (vertices[0] + vertices[1] + vertices[2]) / 3
			est_center_px := get_px(est_center, projection4, renderer.pixels_dim)

			if .Midpoints in renderer.options {
				draw_rect(renderer, est_center_px, [2]f32{4, 4}, 0xFFFF00FF)
			}

			if .Normals in renderer.options {
				normal_tip := 0.3 * normal + est_center.xyz
				normal_tip_px := get_px(
					[4]f32{normal_tip.x, normal_tip.y, normal_tip.z, 0},
					projection4,
					renderer.pixels_dim,
				)
				draw_line(renderer, est_center_px, normal_tip_px, 0xFFFF00FF)
			}

		}

	}

}

draw_triangle :: proc(
	renderer: ^Renderer,
	vertices: [3][2]f32,
	color: [4]f32,
	tex_coords: [3][2]f32,
	zw: [3][2]f32,
	texture: Texture,
) {

	color := color

	// NOTE(sen) Sort (y+ down)
	top, mid, bottom := vertices[0], vertices[1], vertices[2]
	tex_top, tex_mid, tex_bottom := tex_coords[0], tex_coords[1], tex_coords[2]
	zw_top, zw_mid, zw_bottom := zw[0], zw[1], zw[2]
	if top.y > mid.y {
		top, mid = mid, top
		tex_top, tex_mid = tex_mid, tex_top
		zw_top, zw_mid = zw_mid, zw_top
	}
	if mid.y > bottom.y {
		mid, bottom = bottom, mid
		tex_mid, tex_bottom = tex_bottom, tex_mid
		zw_mid, zw_bottom = zw_bottom, zw_mid
	}
	if top.y > mid.y {
		top, mid = mid, top
		tex_top, tex_mid = tex_mid, tex_top
		zw_top, zw_mid = zw_mid, zw_top
	}

	// NOTE(sen) Midline
	midline_x := mid.x
	if top.y != bottom.y {
		midline_x = (mid.y - top.y) / (bottom.y - top.y) * (bottom.x - top.x) + top.x
	}
	midline := [2]f32{midline_x, mid.y}

	// NOTE(sen) Triangle vectors
	ab := mid - top
	ac := bottom - top
	bc := bottom - mid
	one_over_twice_abc_area := 1 / linalg.cross(ab, ac)
	tex_dim_f32 := [2]f32{f32(texture.dim.x), f32(texture.dim.y)}
	one_over_w_top := 1 / zw_top[1]
	one_over_w_mid := 1 / zw_mid[1]
	one_over_w_bottom := 1 / zw_bottom[1]
	tex_top *= one_over_w_top
	tex_mid *= one_over_w_mid
	tex_bottom *= one_over_w_bottom

	px_count := renderer.pixels_dim.y * renderer.pixels_dim.x

	// NOTE(sen) Flat bottom
	{
		rise := mid.y - top.y
		if rise != 0 {

			s1 := (mid.x - top.x) / rise
			s2 := (midline.x - top.x) / rise
			if s1 > s2 {
				s1, s2 = s2, s1
			}

			y_start := math.ceil(top.y)
			y_end := math.ceil(mid.y)

			x1_start := top.x + s1 * (y_start - top.y)
			x2_start := top.x + s2 * (y_start - top.y)

			y_steps: f32 = 0
			for row := y_start; row < y_end; row += 1 {

				x1_cur := x1_start + s1 * y_steps
				x2_cur := x2_start + s2 * y_steps

				for col := x1_cur; col < x2_cur; col += 1 {

					px_coord := [2]int{int(math.ceil(col)), int(math.ceil(row))}
					px_index := px_coord.y * renderer.pixels_dim.x + px_coord.x

					if px_index >= 0 && px_index < px_count {

						point := [2]f32{col, row}
						ap := point - top
						bp := point - mid

						alpha := linalg.cross(bc, bp) * one_over_twice_abc_area
						beta := linalg.cross(ap, ac) * one_over_twice_abc_area
						gamma := 1 - alpha - beta

						one_over_w := alpha * one_over_w_top + beta * one_over_w_mid + gamma * one_over_w_bottom
						this_w := 1 / one_over_w

						if renderer.z_buffer[px_index] > this_w {

							renderer.z_buffer[px_index] = this_w

							tex_coord01 := alpha * tex_top + beta * tex_mid + gamma * tex_bottom
							tex_coord01 *= this_w

							tex_coord_px := tex_coord01 * (tex_dim_f32 - 1)
							texel_index := round(tex_coord_px.y) * texture.pitch + round(tex_coord_px.x)

							tex_color32 := texture.memory[texel_index]
							tex_color := color_to_4f32(tex_color32)
							tex_shaded := tex_color * color

							result_color := color_to_u32argb(tex_shaded)
							renderer.pixels[px_index] = result_color

						}

					}

				}

				y_steps += 1
			}
		}
	}

	// NOTE(sen) Flat top
	{
		rise := bottom.y - mid.y
		if rise != 0 {

			s1 := (bottom.x - mid.x) / rise
			s2 := (bottom.x - midline.x) / rise

			x1_start := mid.x
			x2_start := midline.x

			if x1_start > x2_start {
				x1_start, x2_start = x2_start, x1_start
				s1, s2 = s2, s1
			}

			y_start := math.ceil(mid.y)
			y_end := math.ceil(bottom.y)

			x1_start += s1 * (y_start - mid.y)
			x2_start += s2 * (y_start - mid.y)

			y_steps: f32 = 0
			for row := y_start; row < y_end; row += 1 {

				x1_cur := x1_start + s1 * y_steps
				x2_cur := x2_start + s2 * y_steps

				for col := x1_cur; col < x2_cur; col += 1 {

					px_coord := [2]int{int(math.ceil(col)), int(math.ceil(row))}
					px_index := px_coord.y * renderer.pixels_dim.x + px_coord.x

					if px_index >= 0 && px_index < px_count {

						point := [2]f32{col, row}
						ap := point - top
						bp := point - mid

						alpha := linalg.cross(bc, bp) * one_over_twice_abc_area
						beta := linalg.cross(ap, ac) * one_over_twice_abc_area
						gamma := 1 - alpha - beta

						one_over_w := alpha * one_over_w_top + beta * one_over_w_mid + gamma * one_over_w_bottom
						this_w := 1 / one_over_w

						if renderer.z_buffer[px_index] > this_w {

							renderer.z_buffer[px_index] = this_w

							tex_coord01 := alpha * tex_top + beta * tex_mid + gamma * tex_bottom
							tex_coord01 *= this_w

							tex_coord_px := tex_coord01 * (tex_dim_f32 - 1)
							texel_index := round(tex_coord_px.y) * texture.pitch + round(tex_coord_px.x)

							tex_color32 := texture.memory[texel_index]
							tex_color := color_to_4f32(tex_color32)
							tex_shaded := tex_color * color

							result_color := color_to_u32argb(tex_shaded)
							renderer.pixels[px_index] = result_color

						}

					}

				}

				y_steps += 1
			}
		}
	}

}

ndc_to_pixels :: proc(point_ndc: [2]f32, pixels_dim: [2]int) -> [2]f32 {
	point_01 := point_ndc * [2]f32{0.5, -0.5} + 0.5
	point_px := point_01 * [2]f32{f32(pixels_dim.x), f32(pixels_dim.y)}
	return point_px
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
	for z_val in &renderer.z_buffer {
		z_val = math.inf_f32(1)
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

color_to_u32argb :: proc(color01: [4]f32) -> u32 {
	color := color01 * 255
	result := u32(color.a) << 24 | u32(color.r) << 16 | u32(color.g) << 8 | u32(color.b)
	return result
}

color_to_4f32 :: proc(argb: u32) -> [4]f32 {
	a := (argb & 0xFF000000) >> 24
	r := (argb & 0x00FF0000) >> 16
	g := (argb & 0x0000FF00) >> 8
	b := (argb & 0x000000FF) >> 0
	color := [4]f32{f32(r), f32(g), f32(b), f32(a)}
	color /= 255
	return color
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

perspective :: proc(width_over_height, fov, z_far, z_near: f32) -> matrix[4, 4]f32 {
	tan := math.tan(fov / 2)
	itan := 1 / tan

	z_coef := z_far / (z_far - z_near)

	result: matrix[4, 4]f32

	result[0, 0] = itan
	result[1, 1] = width_over_height * itan
	result[2, 2] = z_coef
	result[2, 3] = -z_coef * z_near
	result[3, 2] = 1

	return result
}

look_at :: proc(eye, target, up: [3]f32) -> matrix[4, 4]f32 {

	eye_z := linalg.normalize(target - eye)
	eye_x := linalg.normalize(linalg.cross(up, eye_z))
	eye_y := linalg.cross(eye_z, eye_x)

	//odinfmt: disable
	view := matrix[4, 4]f32{
		eye_x.x, eye_x.y, eye_x.z, -linalg.dot(eye_x, eye),
		eye_y.x, eye_y.y, eye_y.z, -linalg.dot(eye_y, eye),
		eye_z.x, eye_z.y, eye_z.z, -linalg.dot(eye_z, eye),
		0, 0, 0, 1,
	}
	//odinfmt: enable

	return view
}

look_direction :: proc(eye, forward, up: [3]f32) -> matrix[4, 4]f32 {
	eye_z := linalg.normalize(forward)
	eye_x := linalg.normalize(linalg.cross(up, eye_z))
	eye_y := linalg.cross(eye_z, eye_x)

	//odinfmt: disable
	view := matrix[4, 4]f32{
		eye_x.x, eye_x.y, eye_x.z, -linalg.dot(eye_x, eye),
		eye_y.x, eye_y.y, eye_y.z, -linalg.dot(eye_y, eye),
		eye_z.x, eye_z.y, eye_z.z, -linalg.dot(eye_z, eye),
		0, 0, 0, 1,
	}
	//odinfmt: enable

	return view
}

to_radians :: proc(degrees: f32) -> f32 {
	return math.RAD_PER_DEG * degrees
}

to_degrees :: proc(radians: f32) -> f32 {
	return math.DEG_PER_RAD * radians
}
