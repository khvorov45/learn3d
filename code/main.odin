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

	points: [9 * 9 * 9][3]f32
	point_count := 0
	for x: f32 = -1.0; x <= 1.0; x += 0.25 {
		for y: f32 = -1.0; y <= 1.0; y += 0.25 {
			for z: f32 = -1.0; z <= 1.0; z += 0.25 {
				points[point_count] = [3]f32{x, y, z}
				point_count += 1
			}
		}
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

		//
		// SECTION Render
		//

		rdr.clear(&pixels)

		rotation.y += 0.01
		rotation.z += 0.01
		rotation.x += 0.01

		for point in points {

			point_rotated := rdr.rotate_y(point, rotation.y)
			point_rotated = rdr.rotate_z(point_rotated, rotation.z)
			point_rotated = rdr.rotate_x(point_rotated, rotation.x)

			point_projected := rdr.project(point_rotated, pixels_dim, [3]f32{0, 0, -5}, 1.4)

			color := [4]f32{1, 0, 0, 1}
			if point.y < 0 {
				color.g = 1
			}
			depth01 := (f32(point.z) + 1) / 2
			color *= depth01 * -0.8 + 1

			color *= 255.0

			color32 := rdr.color_to_u32argb(color)

			if point.x == -1 || point.x == 1 || point.y == -1 || point.y == 1 || point.z == 1 {
				rdr.draw_rect(
					&pixels,
					pixels_dim,
					[2]int{int(point_projected.x), int(point_projected.y)},
					[2]int{5, 5},
					color32,
				)
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
