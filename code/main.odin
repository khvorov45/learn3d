package main

USE_SDL :: false

import "core:time"
import "core:os"

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
	{
		mesh_file, ok := os.read_entire_file("assets/cube.obj")
		assert(ok)
		obj.read_mesh(mesh_file, &mesh)
	}

	pixels := make([]u32, window.dim.y * window.dim.x)
	pixels_dim := window.dim

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

		//
		// SECTION Render
		//

		rdr.clear(&pixels)

		rdr.render_mesh(&pixels, pixels_dim, mesh)

		wnd.display_pixels(&window, pixels, pixels_dim)

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
