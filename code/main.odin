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

	pixels := make([]u32, window.dim.y * window.dim.x)
	pixels_dim := window.dim

	input: wnd.Input

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	for window.is_running {

		time_frame_start := time.now()

		wnd.clear_half_transitions(&input)
		wnd.poll_input(&window, &input)

		if input.alt_r.ended_down && wnd.was_pressed(input.enter) {
			wnd.toggle_fullscreen(&window)
		}

		rdr.clear(&pixels)

		rdr.draw_rect(&pixels, pixels_dim, [2]int{50, 50}, [2]int{250, 250}, 0xFFFF0000)

		rdr.draw_pixel(&pixels, pixels_dim, [2]int{300, 700}, 0xFF00FF00)

		wnd.display_pixels(&window, pixels, pixels_dim)

		work_done_duration := time.since(time_frame_start)
		to_sleep_duration := target_frame_duration - work_done_duration
		if to_sleep_duration > 0 {
			time.sleep(to_sleep_duration)
		}

	}

}
