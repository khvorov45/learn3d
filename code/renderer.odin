package learn3d

/* Renderer

All angles are in radians

Coordinates in 3d spaces: x+ right; y+ up; z+ inside (left-handed);
Coordinates in pixels: x+ right; y+ down

draw_*_px functions draw directly on the pixel buffer and do not perform
clipping or bounds-checking
*/

import "core:math"
import "core:math/linalg"
import "core:builtin"
import "core:slice"
import "core:os"
import "core:mem"

Renderer :: struct {
	pixels:                    []u32,
	pixels_dim:                [2]int,
	vertices:                  [][3]f32,
	vertex_count:              int,
	vertices_camera_space:     [][4]f32,
	vertex_camera_space_count: int,
	triangles:                 []Triangle,
	triangle_count:            int,
	z_buffer:                  []f32,
	options:                   bit_set[DisplayOption],
	camera_pos:                [3]f32,
	camera_axes:               [3][3]f32,
	fov_horizontal, near, far: f32,
	clip_planes:               [ClipPlane.Count]Plane,
	projection:                matrix[4, 4]f32,
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
	triangles:   []Triangle,
	rotation:    [3]f32,
	scale:       [3]f32,
	translation: [3]f32,
}

Triangle :: struct {
	indices: [3]int, // TODO(sen) What if I make these be vertices?
	color:   [4]f32,
	texture: [3][2]f32,
}

Polygon :: struct {
	vertices:     [9][3]f32,
	texture:      [9][2]f32,
	vertex_count: int,
}

Texture :: struct {
	memory: [^]u32,
	dim:    [2]int,
	pitch:  int,
}

ClipPlane :: enum {
	Left,
	Right,
	Top,
	Bottom,
	Near,
	Far,
	Count,
}

Plane :: struct {
	point:  [3]f32,
	normal: [3]f32,
}

Rect2d :: struct {
	topleft: [2]f32,
	dim:     [2]f32,
}

LineSegment2d :: struct {
	start: [2]f32,
	end:   [2]f32,
}

create_renderer :: proc(
	width,
	height,
	max_vertices,
	max_triangles: int,
	fov_horizontal,
	near,
	far: f32,
) -> Renderer {

	height_over_width := f32(height) / f32(width)

	renderer := Renderer {
		pixels = make([]u32, width * height),
		pixels_dim = [2]int{width, height},
		options = {.BackfaceCull, .FilledTriangles},
		z_buffer = make([]f32, width * height),
		camera_axes = [3][3]f32{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}},
		vertices = make([][3]f32, max_vertices),
		vertices_camera_space = make([][4]f32, max_vertices),
		triangles = make([]Triangle, max_triangles),
		fov_horizontal = fov_horizontal,
		near = near,
		far = far,
		clip_planes = get_clip_planes(fov_horizontal, height_over_width, near, far),
		projection = perspective(fov_horizontal, height_over_width, near, far),
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

clear :: proc(renderer: ^Renderer) {
	for pixel in &renderer.pixels {
		pixel = 0
	}
	for z_val in &renderer.z_buffer {
		z_val = math.inf_f32(1)
	}
	renderer.vertex_camera_space_count = 0
}

draw_mesh :: proc(renderer: ^Renderer, mesh: Mesh, texture: Texture) {

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
	face_offset := renderer.vertex_camera_space_count
	for vertex in mesh.vertices {
		vertex_camera := model_to_camera_transform * [4]f32{vertex.x, vertex.y, vertex.z, 1}
		renderer.vertices_camera_space[renderer.vertex_camera_space_count] = vertex_camera
		renderer.vertex_camera_space_count += 1
	}

	// NOTE(sen) Draw triangles

	light_ray := linalg.normalize([3]f32{0, 0, 1})

	for mesh_triangle in mesh.triangles {

		// NOTE(sen) Back-face culling
		mesh_triangle_vertices: [3][3]f32
		for fi, vi in mesh_triangle.indices {
			vert := renderer.vertices_camera_space[fi + face_offset]
			mesh_triangle_vertices[vi] = vert.xyz
		}
		ab := mesh_triangle_vertices[1].xyz - mesh_triangle_vertices[0].xyz
		ac := mesh_triangle_vertices[2].xyz - mesh_triangle_vertices[0].xyz
		normal := linalg.normalize(linalg.cross(ab, ac))

		camera_ray := -mesh_triangle_vertices[0].xyz

		camera_normal_dot := linalg.dot(normal, camera_ray)

		if camera_normal_dot > 0 || !(.BackfaceCull in renderer.options) {

			// NOTE(sen) Clipping
			polygon: Polygon
			polygon.vertex_count = 3
			for vi in 0 ..< polygon.vertex_count {
				polygon.vertices[vi] = mesh_triangle_vertices[vi]
				polygon.texture[vi] = mesh_triangle.texture[vi]
			}
			for plane_index in 0 ..< int(ClipPlane.Count) {
				polygon = clip_against_plane(polygon, renderer.clip_planes[plane_index])
			}

			// NOTE(sen) Draw clipped
			for clipped_triangle_index in 3 .. polygon.vertex_count {

				vertices: [3][4]f32
				vertices[0].xyz = polygon.vertices[0]
				vertices[0].w = 1
				vertices[1].xyz = polygon.vertices[clipped_triangle_index - 2]
				vertices[1].w = 1
				vertices[2].xyz = polygon.vertices[clipped_triangle_index - 1]
				vertices[2].w = 1

				tex_coords: [3][2]f32
				tex_coords[0] = polygon.texture[0]
				tex_coords[1] = polygon.texture[clipped_triangle_index - 2]
				tex_coords[2] = polygon.texture[clipped_triangle_index - 1]

				light_normal_dot := clamp(linalg.dot(normal, -light_ray), 0, 1)

				get_px :: proc(vertex: [4]f32, proj: matrix[4, 4]f32, pixels_dim: [2]int) -> [2]f32 {
					vertex_projected := proj * vertex
					assert(vertex_projected.w != 0) // NOTE(sen) Because of clipping
					vertex_projected.xyz /= vertex_projected.w
					vertex_pixels := ndc_to_pixels(vertex_projected.xy, pixels_dim)
					return vertex_pixels
				}

				vertices_px: [3][2]f32
				og_zw: [3][2]f32
				for vertex, index in vertices {
					vertex_projected := renderer.projection * vertex
					if vertex_projected.w != 0 {
						vertex_projected.xyz /= vertex_projected.w
					}
					vertices_px[index] = ndc_to_pixels(vertex_projected.xy, renderer.pixels_dim)
					og_zw[index] = vertex_projected.zw
				}

				if .FilledTriangles in renderer.options {
					shaded_color := mesh_triangle.color
					shaded_color.rgb *= light_normal_dot
					draw_triangle_px(renderer, vertices_px, shaded_color, tex_coords, og_zw, texture)
				}

				if .Wireframe in renderer.options {
					draw_line_px(renderer, LineSegment2d{vertices_px[0], vertices_px[1]}, 0xFFFF0000)
					draw_line_px(renderer, LineSegment2d{vertices_px[0], vertices_px[2]}, 0xFFFF0000)
					draw_line_px(renderer, LineSegment2d{vertices_px[1], vertices_px[2]}, 0xFFFF0000)
				}

				if .Vertices in renderer.options {
					for vertex in vertices_px {
						dim := [2]f32{5, 5}
						topleft := vertex - dim * 0.5
						draw_rect_px(
							renderer,
							clip_to_px_buffer_rect(Rect2d{topleft, dim}, renderer.pixels_dim),
							0xFFFFFF00,
						)
					}
				}

				est_center := (vertices[0] + vertices[1] + vertices[2]) / 3
				est_center_px := get_px(est_center, renderer.projection, renderer.pixels_dim)

				if .Midpoints in renderer.options {
					draw_rect_px(
						renderer,
						clip_to_px_buffer_rect(Rect2d{est_center_px, [2]f32{4, 4}}, renderer.pixels_dim),
						0xFFFF00FF,
					)
				}

				if .Normals in renderer.options {
					normal_tip := 0.3 * normal + est_center.xyz
					normal_tip_px := get_px(
						[4]f32{normal_tip.x, normal_tip.y, normal_tip.z, 0},
						renderer.projection,
						renderer.pixels_dim,
					)
					draw_line_px(renderer, LineSegment2d{est_center_px, normal_tip_px}, 0xFFFF00FF)
				}

			}

		}

	}

}

draw_triangle_px :: proc(
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

					point := [2]f32{col, row}
					ap := point - top
					bp := point - mid

					alpha := linalg.cross(bc, bp) * one_over_twice_abc_area
					beta := linalg.cross(ap, ac) * one_over_twice_abc_area
					gamma := 1 - alpha - beta

					one_over_w := alpha * one_over_w_top + beta * one_over_w_mid + gamma * one_over_w_bottom
					this_w := 1 / one_over_w

					px_index := px_coord.y * renderer.pixels_dim.x + px_coord.x
					if renderer.z_buffer[px_index] > this_w {

						renderer.z_buffer[px_index] = this_w

						tex_coord01 := alpha * tex_top + beta * tex_mid + gamma * tex_bottom
						tex_coord01 *= this_w

						tex_coord_px := tex_coord01 * (tex_dim_f32 - 1)
						tex_coord_y := int(math.round(tex_coord_px.y))
						tex_coord_x := int(math.round(tex_coord_px.x))
						texel_index := tex_coord_y * texture.pitch + tex_coord_x

						tex_color32 := texture.memory[texel_index]
						tex_color := color_to_4f32(tex_color32)
						tex_shaded := tex_color * color

						result_color := color_to_u32argb(tex_shaded)
						renderer.pixels[px_index] = result_color

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

					point := [2]f32{col, row}
					ap := point - top
					bp := point - mid

					alpha := linalg.cross(bc, bp) * one_over_twice_abc_area
					beta := linalg.cross(ap, ac) * one_over_twice_abc_area
					gamma := 1 - alpha - beta

					one_over_w := alpha * one_over_w_top + beta * one_over_w_mid + gamma * one_over_w_bottom
					this_w := 1 / one_over_w

					px_index := px_coord.y * renderer.pixels_dim.x + px_coord.x
					if renderer.z_buffer[px_index] > this_w {

						renderer.z_buffer[px_index] = this_w

						tex_coord01 := alpha * tex_top + beta * tex_mid + gamma * tex_bottom
						tex_coord01 *= this_w

						tex_coord_px := tex_coord01 * (tex_dim_f32 - 1)
						tex_coord_y := int(math.round(tex_coord_px.y))
						tex_coord_x := int(math.round(tex_coord_px.x))
						texel_index := tex_coord_y * texture.pitch + tex_coord_x

						tex_color32 := texture.memory[texel_index]
						tex_color := color_to_4f32(tex_color32)
						tex_shaded := tex_color * color

						result_color := color_to_u32argb(tex_shaded)
						renderer.pixels[px_index] = result_color

					}

				}

				y_steps += 1
			}
		}
	}

}

draw_rect_px :: proc(renderer: ^Renderer, rect: Rect2d, color: u32) {
	bottomright := rect.topleft + rect.dim
	for row in int(math.ceil(rect.topleft.y)) ..< int(math.ceil(bottomright.y)) {
		for col in int(math.ceil(rect.topleft.x)) ..< int(math.ceil(bottomright.x)) {
			renderer.pixels[row * renderer.pixels_dim.x + col] = color
		}
	}
}

draw_line_px :: proc(renderer: ^Renderer, line: LineSegment2d, color: u32) {
	delta := line.end - line.start
	run_length := max(abs(delta.x), abs(delta.y))
	inc := delta / run_length

	cur := line.start
	for _ in 0 ..< int(run_length) {
		cur_rounded_x := int(math.round(cur.x))
		cur_rounded_y := int(math.round(cur.y))
		renderer.pixels[cur_rounded_y * renderer.pixels_dim.x + cur_rounded_x] = color
		cur += inc
	}
}

get_clip_planes :: proc(
	fov_horizontal,
	height_over_width,
	near,
	far: f32,
) -> [ClipPlane.Count]Plane {

	half_fov_horizontal := fov_horizontal * 0.5

	tan_vertical := height_over_width * math.tan(half_fov_horizontal)

	half_fov_vertical := math.atan(tan_vertical)

	cos_h := math.cos(half_fov_horizontal)
	sin_h := math.sin(half_fov_horizontal)

	cos_v := math.cos(half_fov_vertical)
	sin_v := math.sin(half_fov_vertical)

	planes: [ClipPlane.Count]Plane

	planes[ClipPlane.Left] = Plane{{0, 0, 0}, {cos_h, 0, sin_h}}
	planes[ClipPlane.Right] = Plane{{0, 0, 0}, {-cos_h, 0, sin_h}}

	planes[ClipPlane.Top] = Plane{{0, 0, 0}, {0, -cos_v, sin_v}}
	planes[ClipPlane.Bottom] = Plane{{0, 0, 0}, {0, cos_v, sin_v}}

	planes[ClipPlane.Near] = Plane{{0, 0, near}, {0, 0, 1}}
	planes[ClipPlane.Far] = Plane{{0, 0, far}, {0, 0, -1}}

	return planes
}

clip_against_plane :: proc(polygon: Polygon, plane: Plane) -> Polygon {

	result: Polygon

	if polygon.vertex_count > 0 {

		assert(polygon.vertex_count >= 3)

		prev_vertex := polygon.vertices[polygon.vertex_count - 1]
		prev_tex := polygon.texture[polygon.vertex_count - 1]
		prev_dot := linalg.dot(prev_vertex - plane.point, plane.normal)

		for vertex_index in 0 ..< polygon.vertex_count {

			this_vertex := polygon.vertices[vertex_index]
			this_tex := polygon.texture[vertex_index]
			this_dot := linalg.dot(this_vertex - plane.point, plane.normal)

			if prev_dot * this_dot < 0 {

				range := prev_dot - this_dot
				from_prev := prev_dot / range

				intersection := (1 - from_prev) * prev_vertex + from_prev * this_vertex
				tex_intersection := (1 - from_prev) * prev_tex + from_prev * this_tex

				result.vertices[result.vertex_count] = intersection
				result.texture[result.vertex_count] = tex_intersection
				result.vertex_count += 1

			}

			if this_dot >= 0 {

				result.vertices[result.vertex_count] = this_vertex
				result.texture[result.vertex_count] = this_tex
				result.vertex_count += 1

			}

			prev_vertex = this_vertex
			prev_tex = this_tex
			prev_dot = this_dot

		}

	}

	return result
}

clip_to_px_buffer_rect :: proc(rect: Rect2d, px_dim: [2]int) -> Rect2d {

	dim_f32 := [2]f32{f32(px_dim.x), f32(px_dim.y)}
	result: Rect2d

	topleft := rect.topleft
	bottomright := topleft + rect.dim

	x_overlaps := topleft.x < dim_f32.x && bottomright.x > 0
	y_overlaps := topleft.y < dim_f32.y && bottomright.y > 0

	if x_overlaps && y_overlaps {

		topleft.x = max(topleft.x, 0)
		topleft.y = max(topleft.y, 0)

		bottomright.x = min(bottomright.x, dim_f32.x)
		bottomright.y = min(bottomright.y, dim_f32.y)

		result.topleft = topleft
		result.dim = bottomright - topleft

	}

	return result
}

// Liang–Barsky algorithm
// https://en.wikipedia.org/wiki/Liang%E2%80%93Barsky_algorithm
clip_to_px_buffer_line :: proc(line: LineSegment2d, px_dim: [2]int) -> LineSegment2d {

	dim_f32 := [2]f32{f32(px_dim.x), f32(px_dim.y)}

	p1 := -(line.end.x - line.start.x)
	p2 := -p1
	p3 := -(line.end.y - line.start.y)
	p4 := -p3

	q1 := line.start.x
	q2 := dim_f32.x - line.start.x
	q3 := line.start.y
	q4 := dim_f32.y - line.start.y

	posarr, negarr: [5]f32
	posarr[0] = 1
	negarr[0] = 0
	posind := 1
	negind := 1

	result: LineSegment2d

	// NOTE(sen) Line parallel to clipping window
	if (p1 == 0 && q1 < 0) || (p2 == 0 && q2 < 0) || (p3 == 0 && q3 < 0) || (p4 == 0 && q4 <
	   0) {
		return result
	}

	if p1 != 0 {
		r1 := q1 / p1
		r2 := q2 / p2
		if p1 < 0 {
			negarr[negind] = r1
			posarr[posind] = r2
		} else {
			negarr[negind] = r2
			posarr[posind] = r1
		}
		negind += 1
		posind += 1
	}

	if p3 != 0 {
		r3 := q3 / p3
		r4 := q4 / p4
		if (p3 < 0) {
			negarr[negind] = r3
			posarr[posind] = r4
		} else {
			negarr[negind] = r4
			posarr[posind] = r3
		}
		negind += 1
		posind += 1
	}

	rn1 := negarr[0]
	for neg in negarr[1:negind] {
		rn1 = max(rn1, neg)
	}
	rn2 := posarr[0]
	for pos in posarr[1:posind] {
		rn2 = min(rn2, pos)
	}

	// NOTE(sen) Line outside clipping window
	if rn1 > rn2 {
		return result
	}

	result.start.x = line.start.x + p2 * rn1
	result.start.y = line.start.y + p4 * rn1

	result.end.x = line.start.x + p2 * rn2
	result.end.y = line.start.y + p4 * rn2

	return result
}

ndc_to_pixels :: proc(point_ndc: [2]f32, pixels_dim: [2]int) -> [2]f32 {
	point_01 := point_ndc * [2]f32{0.5, -0.5} + 0.5
	point_px := point_01 * [2]f32{f32(pixels_dim.x - 1), f32(pixels_dim.y - 1)}
	return point_px
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

get_rotation3 :: proc(axis: [3]f32, angle: f32) -> matrix[3, 3]f32 {
	cos := math.cos(angle)
	sin := math.sin(angle)
	icos := 1 - cos
	isin := 1 - sin

	result: matrix[3, 3]f32

	result[0, 0] = cos + axis.x * axis.x * icos
	result[0, 1] = axis.x * axis.y * icos - axis.z * sin
	result[0, 2] = axis.x * axis.z * icos + axis.y * sin

	result[1, 0] = axis.y * axis.x * icos + axis.z * sin
	result[1, 1] = cos + axis.y * axis.y * icos
	result[1, 2] = axis.y * axis.z * icos - axis.x * sin

	result[2, 0] = axis.z * axis.x * icos - axis.y * sin
	result[2, 1] = axis.z * axis.y * icos + axis.x * sin
	result[2, 2] = cos + axis.z * axis.z * icos

	return result
}


perspective :: proc(
	fov_horizontal,
	height_over_width,
	z_near,
	z_far: f32,
) -> matrix[4, 4]f32 {

	tan_h := math.tan(fov_horizontal / 2)
	tan_v := height_over_width * tan_h

	itan_h := 1 / tan_h
	itan_v := 1 / tan_v

	z_coef := z_far / (z_far - z_near)

	result: matrix[4, 4]f32

	result[0, 0] = itan_h
	result[1, 1] = itan_v
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
