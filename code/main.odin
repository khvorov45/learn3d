package learn3d

import "core:time"
import "core:os"
import "core:fmt"

main :: proc() {

	window := create_window("learn3d", 1280, 720)

	mesh: Mesh
	mesh.scale = 1
	{
		mesh_file, ok := os.read_entire_file("assets/f22.obj")
		assert(ok)
		//read_mesh(mesh_file, &mesh)
		append_box(&mesh, [3]f32{-1, -1, -1}, [3]f32{2, 2, 2})
	}

	renderer := create_renderer(window.dim.x, window.dim.y)

	input: Input

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	for window.is_running {

		time_frame_start := time.now()

		//
		// SECTION Input
		//

		clear_half_transitions(&input)
		poll_input(&window, &input)

		//
		// SECTION Update
		//

		if input.alt_r.ended_down && was_pressed(input.enter) {
			toggle_fullscreen(&window)
		}

		if input.A.ended_down {
			mesh.rotation += [3]f32{0.0, 0.02, 0.0}
		}
		if input.D.ended_down {
			mesh.rotation -= [3]f32{0.0, 0.02, 0.0}
		}
		if input.W.ended_down {
			mesh.rotation += [3]f32{0.02, 0.0, 0.0}
		}
		if input.S.ended_down {
			mesh.rotation -= [3]f32{0.02, 0.0, 0.0}
		}
		if input.Q.ended_down {
			mesh.rotation += [3]f32{0.0, 0.0, 0.02}
		}
		if input.E.ended_down {
			mesh.rotation -= [3]f32{0.0, 0.0, 0.02}
		}

		if was_pressed(input.digit1) {
			toggle_option(&renderer, .FilledTriangles)
		}
		if was_pressed(input.digit2) {
			toggle_option(&renderer, .Wireframe)
		}
		if was_pressed(input.digit3) {
			toggle_option(&renderer, .Vertices)
		}
		if was_pressed(input.digit4) {
			toggle_option(&renderer, .Normals)
		}
		if was_pressed(input.digit5) {
			toggle_option(&renderer, .Midpoints)
		}
		if was_pressed(input.digit6) {
			toggle_option(&renderer, .BackfaceCull)
		}

		//
		// SECTION Render
		//

		clear(&renderer)

		render_mesh(&renderer, mesh)

		display_pixels(&window, renderer.pixels, renderer.pixels_dim)

		//
		// SECTION Frame time
		//

		work_done_duration := time.since(time_frame_start)
		to_sleep_duration := target_frame_duration - work_done_duration
		if to_sleep_duration > 0 {
			time.sleep(to_sleep_duration)
		}

	}

}
