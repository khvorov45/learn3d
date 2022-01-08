package learn3d

import "core:time"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:math/linalg"

main :: proc() {

	vertex_storage: [dynamic][3]f32
	face_storage: [dynamic]Face

	window := create_window("learn3d", 1280, 720)

	mesh: Mesh
	mesh.scale = 1
	//mesh.rotation = [3]f32{-0.440000027, -1.71999907, 0.0399999991}
	mesh.vertices, mesh.faces = read_obj(
		read_file("assets/f22.obj"),
		&vertex_storage,
		&face_storage,
	)
	mesh.translation.z += 3.5
	texture := read_image(read_file("assets/f22.png"))

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

		speed: f32 = 0.02
		if input.shift.ended_down {
			speed *= 5
		}
		if input.A.ended_down {
			renderer.camera_pos -= speed * renderer.camera_axes.x
			//mesh.rotation += [3]f32{0.0, rotate_speed, 0.0}
		}
		if input.D.ended_down {
			renderer.camera_pos += speed * renderer.camera_axes.x
			//mesh.rotation -= [3]f32{0.0, rotate_speed, 0.0}
		}
		if input.W.ended_down {
			renderer.camera_pos += speed * renderer.camera_axes.z
			//mesh.rotation += [3]f32{rotate_speed, 0.0, 0.0}
		}
		if input.S.ended_down {
			renderer.camera_pos -= speed * renderer.camera_axes.z
			//mesh.rotation -= [3]f32{rotate_speed, 0.0, 0.0}
		}
		if input.Q.ended_down {
			//mesh.rotation += [3]f32{0.0, 0.0, rotate_speed}
		}
		if input.E.ended_down {
			//mesh.rotation -= [3]f32{0.0, 0.0, rotate_speed}
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

		render_mesh(&renderer, mesh, texture)

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
