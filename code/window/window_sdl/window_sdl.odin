package window_sdl

import sdl "vendor:sdl2"

Window :: struct {
	is_running:      bool,
	dim:             [2]int,
	sdl_window:      ^sdl.Window,
	sdl_renderer:    ^sdl.Renderer,
	sdl_texture:     ^sdl.Texture,
	sdl_texture_dim: [2]int,
}

create_window :: proc(title: string, width: int, height: int) -> Window {

	assert(sdl.Init(sdl.INIT_EVERYTHING) == 0)

	window := sdl.CreateWindow(
		cstring(raw_data(title)),
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		i32(width),
		i32(height),
		sdl.WINDOW_HIDDEN,
	)
	assert(window != nil)

	renderer := sdl.CreateRenderer(window, -1, nil)
	assert(renderer != nil)

	assert(sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255) == 0)
	assert(sdl.RenderClear(renderer) == 0)

	sdl.ShowWindow(window)
	sdl.RenderPresent(renderer)

	texture := sdl.CreateTexture(
		renderer,
		u32(sdl.PixelFormatEnum.ARGB8888),
		sdl.TextureAccess.STREAMING,
		i32(width),
		i32(height),
	)
	texture_dim := [2]int{width, height}
	assert(texture != nil)

	result := Window{true, [2]int{width, height}, window, renderer, texture, texture_dim}
	return result
}

poll_input :: proc(window: ^Window) {

	event: sdl.Event
	for sdl.PollEvent(&event) != 0 {
		#partial switch event.type {
		case .QUIT:
			window.is_running = false
		}
	}

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	assert(sdl.RenderClear(window.sdl_renderer) == 0)

	update_texture_result := sdl.UpdateTexture(
		window.sdl_texture,
		nil,
		raw_data(pixels),
		i32(pixels_dim.x) * size_of(pixels[0]),
	)
	assert(update_texture_result == 0)

	render_copy_result := sdl.RenderCopy(window.sdl_renderer, window.sdl_texture, nil, nil)
	assert(render_copy_result == 0)

	sdl.RenderPresent(window.sdl_renderer)

}
