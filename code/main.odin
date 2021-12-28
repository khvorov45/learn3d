package main

USE_SDL :: true

when USE_SDL {
	import wnd "window/window_sdl"
} else {
	when ODIN_OS == "windows" do import wnd "window/window_win32"
}

main :: proc() {

	window := wnd.create_window("learn3d", 1280, 720)

	pixels := make([]u32, window.dim.y * window.dim.x)
	pixels_dim := window.dim

	for row in 0 ..< pixels_dim.y {
		for col in 0 ..< pixels_dim.x {
			pixel := &pixels[row * pixels_dim.x + col]
			switch {
			case row == 0:
				pixel^ = 0x00FF0000
			case row == pixels_dim.y - 1:
				pixel^ = 0x0000FF00
			case col == 0:
				pixel^ = 0x000000FF
			case col == pixels_dim.x - 1:
				pixel^ = 0x0000FFFF
			case col % 100 == 0:
				pixel^ = 0x00222222
			case row % 100 == 0:
				pixel^ = 0x00222222
			}
		}
	}

	for window.is_running {

		wnd.poll_input(&window)

		wnd.display_pixels(&window, pixels, pixels_dim)

	}

}
