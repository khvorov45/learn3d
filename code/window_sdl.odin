//+build !windows

package learn3d

import sdl "vendor:sdl2"

PlatformWindow :: struct {
	window:      ^sdl.Window,
	renderer:    ^sdl.Renderer,
	texture:     ^sdl.Texture,
	texture_dim: [2]int,
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

	result := Window{
		true,
		false,
		[2]int{width, height},
		{window, renderer, texture, texture_dim},
	}
	return result
}

poll_input :: proc(window: ^Window, input: ^Input) {

	event: sdl.Event
	for sdl.PollEvent(&event) != 0 {

		#partial switch event.type {

		case .QUIT:
			window.is_running = false

		case .KEYDOWN, .KEYUP:
			ended_down := event.type == .KEYDOWN
			#partial switch event.key.keysym.sym {
			case .RETURN:
				record_key(input, .Enter, ended_down)
			case .RALT:
				record_key(input, .AltR, ended_down)
			case .W:
				record_key(input, .W, ended_down)
			case .A:
				record_key(input, .A, ended_down)
			case .S:
				record_key(input, .S, ended_down)
			case .D:
				record_key(input, .D, ended_down)
			case .Q:
				record_key(input, .Q, ended_down)
			case .E:
				record_key(input, .E, ended_down)
			case .NUM1:
				record_key(input, .Digit1, ended_down)
			case .NUM2:
				record_key(input, .Digit2, ended_down)
			case .NUM3:
				record_key(input, .Digit3, ended_down)
			case .NUM4:
				record_key(input, .Digit4, ended_down)
			case .NUM5:
				record_key(input, .Digit5, ended_down)
			case .NUM6:
				record_key(input, .Digit6, ended_down)
			case .NUM7:
				record_key(input, .Digit7, ended_down)
			case .NUM8:
				record_key(input, .Digit8, ended_down)
			case .NUM9:
				record_key(input, .Digit9, ended_down)
			case .NUM0:
				record_key(input, .Digit0, ended_down)
			case .LSHIFT, .RSHIFT:
				record_key(input, .Shift, ended_down)
			case .SPACE:
				record_key(input, .Space, ended_down)
			case .LCTRL, .RCTRL:
				record_key(input, .Ctrl, ended_down)
			}


		}

	}

	sdl.GetWindowSize(
		window.platform.window,
		cast(^i32)&window.dim.x,
		cast(^i32)&window.dim.y,
	)

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	assert(sdl.RenderClear(window.platform.renderer) == 0)

	update_texture_result := sdl.UpdateTexture(
		window.platform.texture,
		nil,
		raw_data(pixels),
		i32(pixels_dim.x) * size_of(pixels[0]),
	)
	assert(update_texture_result == 0)

	render_copy_result := sdl.RenderCopy(
		window.platform.renderer,
		window.platform.texture,
		nil,
		nil,
	)
	assert(render_copy_result == 0)

	sdl.RenderPresent(window.platform.renderer)

}

toggle_fullscreen :: proc(window: ^Window) {
	if window.is_fullscreen {
		sdl.SetWindowFullscreen(window.platform.window, nil)
	} else {
		sdl.SetWindowFullscreen(window.platform.window, sdl.WINDOW_FULLSCREEN_DESKTOP)
	}
	window.is_fullscreen = !window.is_fullscreen
}
