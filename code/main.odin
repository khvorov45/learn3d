package main

USE_SDL :: false

import "core:time"
import "core:os"
import "core:fmt"

when USE_SDL {
	import wnd "window/window_sdl"
} else {
	when ODIN_OS == "windows" do import wnd "window/window_win32"
}

import rdr "learn3d:renderer"
import "learn3d:obj"
import inp "learn3d:input"

main :: proc() {

	window := wnd.create_window("learn3d", 1280, 720)

	mesh: rdr.Mesh
	mesh.scale = 1
	{
		mesh_file, ok := os.read_entire_file("assets/f22.obj")
		assert(ok)
		//obj.read_mesh(mesh_file, &mesh)
		rdr.append_box(&mesh, [3]f32{-1, -1, -1}, [3]f32{2, 2, 2})
	}

	renderer := rdr.create_renderer(window.dim.x, window.dim.y)

	input: inp.Input

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	for window.is_running {

		time_frame_start := time.now()

		//
		// SECTION Input
		//

		inp.clear_half_transitions(&input)
		wnd.poll_input(&window, &input)

		//
		// SECTION Update
		//

		if input.alt_r.ended_down && inp.was_pressed(input.enter) {
			wnd.toggle_fullscreen(&window)
		}

		if input.A.ended_down {
			mesh.rotation += [3]f32{0.0, 0.1, 0.0}
		}
		if input.D.ended_down {
			mesh.rotation -= [3]f32{0.0, 0.1, 0.0}
		}
		if input.W.ended_down {
			mesh.rotation += [3]f32{0.1, 0.0, 0.0}
		}
		if input.S.ended_down {
			mesh.rotation -= [3]f32{0.1, 0.0, 0.0}
		}
		if input.Q.ended_down {
			mesh.rotation += [3]f32{0.0, 0.0, 0.1}
		}
		if input.E.ended_down {
			mesh.rotation -= [3]f32{0.0, 0.0, 0.1}
		}

		if inp.was_pressed(input.digit1) {
			rdr.toggle_option(&renderer, .FilledTriangles)
		}
		if inp.was_pressed(input.digit2) {
			rdr.toggle_option(&renderer, .Wireframe)
		}
		if inp.was_pressed(input.digit3) {
			rdr.toggle_option(&renderer, .Vertices)
		}
		if inp.was_pressed(input.digit4) {
			rdr.toggle_option(&renderer, .Normals)
		}
		if inp.was_pressed(input.digit5) {
			rdr.toggle_option(&renderer, .Midpoints)
		}
		if inp.was_pressed(input.digit6) {
			rdr.toggle_option(&renderer, .BackfaceCull)
		}

		//
		// SECTION Render
		//

		rdr.clear(&renderer)

		rdr.render_mesh(&renderer, mesh)

		wnd.display_pixels(&window, renderer.pixels, renderer.pixels_dim)

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
