package main

USE_SDL :: false

import "core:time"

when USE_SDL {
	import wnd "window/window_sdl"
} else {
	when ODIN_OS == "windows" do import wnd "window/window_win32"
}

import rdr "renderer"

main :: proc() {

	window := wnd.create_window("learn3d", 1280, 720)

	mesh_vertices := [?][3]f32{
		[3]f32{-1, -1, -1},
		[3]f32{-1, 1, -1},
		[3]f32{1, 1, -1},
		[3]f32{1, -1, -1},
		[3]f32{1, 1, 1},
		[3]f32{1, -1, 1},
		[3]f32{-1, 1, 1},
		[3]f32{-1, -1, 1},
	}

	mesh_faces := [?][3]int{
		[3]int{1, 2, 3},
		[3]int{1, 3, 4},
		[3]int{4, 3, 5},
		[3]int{4, 5, 6},
		[3]int{6, 5, 7},
		[3]int{6, 7, 8},
		[3]int{8, 7, 2},
		[3]int{8, 2, 1},
		[3]int{2, 7, 5},
		[3]int{2, 5, 3},
		[3]int{6, 8, 1},
		[3]int{6, 1, 4},
	}

	pixels := make([]u32, window.dim.y * window.dim.x)
	pixels_dim := window.dim

	input: wnd.Input

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	rotation := [3]f32{0, 0, 0}

	for window.is_running {

		time_frame_start := time.now()

		//
		// SECTION Input
		//

		wnd.clear_half_transitions(&input)
		wnd.poll_input(&window, &input)

		//
		// SECTION Update
		//

		if input.alt_r.ended_down && wnd.was_pressed(input.enter) {
			wnd.toggle_fullscreen(&window)
		}

		rotation += [3]f32{0.01, 0.01, 0.01}

		//
		// SECTION Render
		//

		rdr.clear(&pixels)

		for face, face_index in mesh_faces {

			vertices_px: [3][2]int

			for vertex_index, index in face {
				vertex := mesh_vertices[vertex_index - 1]
				vertex_rotated := rdr.rotate_x(vertex, rotation.x)
				vertex_rotated = rdr.rotate_y(vertex_rotated, rotation.y)
				vertex_rotated = rdr.rotate_z(vertex_rotated, rotation.z)
				vertex_projected := rdr.project(vertex_rotated, [3]f32{0, 0, -2.5})
				vertex_pixels := rdr.screen_world_to_pixels(vertex_projected, 500, pixels_dim)
				vertices_px[index] = [2]int{int(vertex_pixels.x), int(vertex_pixels.y)}
				rdr.draw_rect(
					&pixels,
					pixels_dim,
					vertices_px[index],
					[2]int{4, 4},
					0xFFFFFF00,
				)
			}

			if face_index == 3 || true {
				rdr.draw_line(&pixels, pixels_dim, vertices_px[0], vertices_px[1], 0xFFFF0000)
				rdr.draw_line(&pixels, pixels_dim, vertices_px[0], vertices_px[2], 0xFFFF0000)
				rdr.draw_line(&pixels, pixels_dim, vertices_px[1], vertices_px[2], 0xFFFF0000)
			}
		}



		wnd.display_pixels(&window, pixels, pixels_dim)

		work_done_duration := time.since(time_frame_start)
		to_sleep_duration := target_frame_duration - work_done_duration
		if to_sleep_duration > 0 {
			time.sleep(to_sleep_duration)
		}

	}

}
