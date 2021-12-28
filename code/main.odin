package main

when ODIN_OS == "windows" do import wnd "window/window_win32"

main :: proc() {

	window := wnd.create_window(1280, 720)

	pixels := make([]u32, window.dim.y * window.dim.x)
	pixels_dim := window.dim

	for pixel, index in &pixels {
		switch {
		case index < pixels_dim.x:
			pixel = 0x00FF0000
		case index % pixels_dim.x == 0:
			pixel = 0x0000FF00
		case index % pixels_dim.x == pixels_dim.x - 1:
			pixel = 0x000000FF
		case index >= (pixels_dim.y - 1) * pixels_dim.x:
			pixel = 0x0000FFFF
		}
	}

	for window.is_running {

		wnd.poll_input(&window)

		wnd.display_pixels(&window, pixels, pixels_dim)

	}

}
