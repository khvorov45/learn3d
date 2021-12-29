package main

USE_SDL :: false

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

	for window.is_running {

		wnd.clear_half_transitions(&input)
		wnd.poll_input(&window, &input)

		if input.alt_r.ended_down && wnd.was_pressed(input.enter) {
			wnd.toggle_fullscreen(&window)
		}

		rdr.clear(&pixels)

		rdr.draw_rect(&pixels, pixels_dim, [2]int{50, 50}, [2]int{250, 250}, 0xFFFF0000)

		wnd.display_pixels(&window, pixels, pixels_dim)

	}

}
