package window_sdl

import sdl "vendor:sdl2"
import shared ".."

Window :: struct {
	using shared: shared.Window,
	sdl:          SdlWindow,
}

SdlWindow :: struct {
	window:      ^sdl.Window,
	renderer:    ^sdl.Renderer,
	texture:     ^sdl.Texture,
	texture_dim: [2]int,
}

Input :: shared.Input

clear_half_transitions :: shared.clear_half_transitions

was_pressed :: shared.was_pressed

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
		{true, false, [2]int{width, height}},
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
				input.enter.ended_down = ended_down
				input.enter.half_transition_count += 1
			case .RALT:
				input.alt_r.ended_down = ended_down
				input.alt_r.half_transition_count += 1
			case .W:
				input.W.ended_down = ended_down
				input.W.half_transition_count += 1
			case .A:
				input.A.ended_down = ended_down
				input.A.half_transition_count += 1
			case .S:
				input.S.ended_down = ended_down
				input.S.half_transition_count += 1
			case .D:
				input.D.ended_down = ended_down
				input.D.half_transition_count += 1
			case .Q:
				input.Q.ended_down = ended_down
				input.Q.half_transition_count += 1
			case .E:
				input.E.ended_down = ended_down
				input.E.half_transition_count += 1
			}
		}
	}

	sdl.GetWindowSize(window.sdl.window, cast(^i32)&window.dim.x, cast(^i32)&window.dim.y)

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	assert(sdl.RenderClear(window.sdl.renderer) == 0)

	update_texture_result := sdl.UpdateTexture(
		window.sdl.texture,
		nil,
		raw_data(pixels),
		i32(pixels_dim.x) * size_of(pixels[0]),
	)
	assert(update_texture_result == 0)

	render_copy_result := sdl.RenderCopy(window.sdl.renderer, window.sdl.texture, nil, nil)
	assert(render_copy_result == 0)

	sdl.RenderPresent(window.sdl.renderer)

}

toggle_fullscreen :: proc(window: ^Window) {
	if window.is_fullscreen {
		sdl.SetWindowFullscreen(window.sdl.window, nil)
	} else {
		sdl.SetWindowFullscreen(window.sdl.window, sdl.WINDOW_FULLSCREEN_DESKTOP)
	}
	window.is_fullscreen = !window.is_fullscreen
}
