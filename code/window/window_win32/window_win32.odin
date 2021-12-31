package window_win32

import "core:sys/win32"
import "core:fmt"

import shared "learn3d:window"
import inp "learn3d:input"

GlobalRunning := true

Window :: struct {
	using shared: shared.Window,
	win32:        Win32Window,
}

Win32Window :: struct {
	decorations_dim:    [2]int,
	hwnd:               win32.Hwnd,
	hdc:                win32.Hdc,
	pixel_info:         win32.Bitmap_Info,
	previous_placement: win32.Window_Placement,
}

create_window :: proc(title: string, width: int, height: int) -> Window {

	window_class_name := title
	window_name := window_class_name
	window_dim := [2]int{width, height}

	window_instance := win32.get_module_handle_a(nil)
	assert(window_instance != nil)

	window_class: win32.Wnd_Class_Ex_A
	window_class.size = size_of(window_class)
	window_class.style = win32.CS_HREDRAW | win32.CS_VREDRAW
	window_class.wnd_proc = win32.Wnd_Proc(window_proc)
	window_class.instance = win32.Hinstance(window_instance)
	window_class.class_name = cstring(raw_data(window_class_name))
	window_class.background = win32.COLOR_BACKGROUND
	window_class.cursor = win32.load_cursor_a(nil, win32.IDC_ARROW)

	assert(win32.register_class_ex_a(&window_class) != 0)

	window := win32.create_window_ex_a(
		0,
		cstring(raw_data(window_class_name)),
		cstring(raw_data(window_name)),
		win32.WS_OVERLAPPEDWINDOW,
		win32.CW_USEDEFAULT,
		win32.CW_USEDEFAULT,
		i32(window_dim.x),
		i32(window_dim.y),
		nil,
		nil,
		win32.Hinstance(window_instance),
		nil,
	)
	assert(window != nil)

	// NOTE(sen) Resize so that dim corresponds to the client area
	decorations_dim: [2]int
	{
		client_rect: win32.Rect
		win32.get_client_rect(window, &client_rect)
		window_rect: win32.Rect
		win32.get_window_rect(window, &window_rect)
		client_rect_dim := [2]int{
			int(client_rect.right - client_rect.left),
			int(client_rect.bottom - client_rect.top),
		}
		window_rect_dim := [2]int{
			int(window_rect.right - window_rect.left),
			int(window_rect.bottom - window_rect.top),
		}
		decorations_dim = window_rect_dim - client_rect_dim

		win32.set_window_pos(
			window,
			nil,
			0,
			0,
			i32(width + decorations_dim.x),
			i32(height + decorations_dim.y),
			win32.SWP_NOMOVE,
		)
	}

	SW_SHOWNORMAL :: 1
	SW_SHOWMINIMIZED :: 2

	win32.show_window(window, SW_SHOWMINIMIZED)
	win32.show_window(window, SW_SHOWNORMAL)

	hdc := win32.get_dc(window)
	assert(hdc != nil)

	pixel_info: win32.Bitmap_Info
	pixel_info.header.size = size_of(pixel_info.header)
	pixel_info.header.width = i32(width)
	pixel_info.header.height = -i32(height) // NOTE(sen) Negative means top-down
	pixel_info.header.planes = 1
	pixel_info.header.bit_count = 32
	pixel_info.header.compression = win32.BI_RGB

	previous_placement: win32.Window_Placement
	previous_placement.length = size_of(previous_placement)

	result := Window{
		{true, false, window_dim},
		{decorations_dim, window, hdc, pixel_info, previous_placement},
	}
	return result
}

poll_input :: proc(window: ^Window, input: ^inp.Input) {

	hwnd := window.win32.hwnd

	message: win32.Msg
	for win32.peek_message_a(&message, hwnd, 0, 0, 1) {

		switch message.message {
		case win32.WM_KEYDOWN, win32.WM_SYSKEYDOWN, win32.WM_KEYUP, win32.WM_SYSKEYUP:
			ended_down := (message.lparam & (1 << 31)) == 0
			switch message.wparam {
			case win32.VK_RETURN:
				input.enter.ended_down = ended_down
				input.enter.half_transition_count += 1
			case win32.VK_MENU:
				if message.lparam & (1 << 24) != 0 {
					input.alt_r.ended_down = ended_down
					input.alt_r.half_transition_count += 1
				}
			case 'W':
				input.W.ended_down = ended_down
				input.W.half_transition_count += 1
			case 'A':
				input.A.ended_down = ended_down
				input.A.half_transition_count += 1
			case 'S':
				input.S.ended_down = ended_down
				input.S.half_transition_count += 1
			case 'D':
				input.D.ended_down = ended_down
				input.D.half_transition_count += 1
			case 'Q':
				input.Q.ended_down = ended_down
				input.Q.half_transition_count += 1
			case 'E':
				input.E.ended_down = ended_down
				input.E.half_transition_count += 1
			}

		case:
			win32.translate_message(&message)
			win32.dispatch_message_a(&message)
		}

	}

	// NOTE(sen) Update dim
	{
		rect: win32.Rect
		win32.get_client_rect(window.win32.hwnd, &rect)
		window.dim.y = int(rect.bottom - rect.top)
		window.dim.x = int(rect.right - rect.left)
	}

	window.is_running = GlobalRunning

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	if window.is_running {
		result := win32.stretch_dibits(
			window.win32.hdc,
			0,
			0,
			i32(window.dim.x),
			i32(window.dim.y),
			0,
			0,
			i32(pixels_dim.x),
			i32(pixels_dim.y),
			raw_data(pixels),
			&window.win32.pixel_info,
			win32.DIB_RGB_COLORS,
			win32.SRCCOPY,
		)
		assert(
			result == i32(pixels_dim.y),
			fmt.tprintf("expected {}, got {}\n", pixels_dim.y, result),
		)
	}

}

window_proc :: proc(
	window: win32.Hwnd,
	message: u32,
	wparam: win32.Wparam,
	lparam: win32.Lparam,
) -> win32.Lresult {

	result: win32.Lresult

	switch message {
	case win32.WM_DESTROY:
		GlobalRunning = false
	case:
		result = win32.def_window_proc_a(window, message, wparam, lparam)
	}

	return result
}

toggle_fullscreen :: proc(window: ^Window) {

	// NOTE(sen) Taken from https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353

	style := win32.get_window_long_ptr_a(window.win32.hwnd, win32.GWL_STYLE)

	if window.is_fullscreen {

		win32.set_window_long_ptr_a(
			window.win32.hwnd,
			win32.GWL_STYLE,
			win32.Long_Ptr(uint(style) | uint(win32.WS_OVERLAPPEDWINDOW)),
		)

		win32.set_window_placement(window.win32.hwnd, &window.win32.previous_placement)

		win32.set_window_pos(
			window.win32.hwnd,
			nil,
			0,
			0,
			0,
			0,
			win32.SWP_NOMOVE |
			win32.SWP_NOSIZE |
			win32.SWP_NOZORDER |
			win32.SWP_NOOWNERZORDER |
			win32.SWP_FRAMECHANGED,
		)

	} else {

		mi: win32.Monitor_Info
		mi.size = size_of(mi)
		get_monitor_result := win32.get_monitor_info_a(
			win32.monitor_from_window(window.win32.hwnd, win32.MONITOR_DEFAULTTOPRIMARY),
			&mi,
		)
		assert(bool(get_monitor_result))

		get_window_placement_result := win32.get_window_placement(
			window.win32.hwnd,
			&window.win32.previous_placement,
		)
		assert(bool(get_window_placement_result))

		win32.set_window_long_ptr_a(
			window.win32.hwnd,
			win32.GWL_STYLE,
			win32.Long_Ptr(uint(style) & ~uint(win32.WS_OVERLAPPEDWINDOW)),
		)

		HWND_TOP: win32.Hwnd = nil

		win32.set_window_pos(
			window.win32.hwnd,
			HWND_TOP,
			mi.monitor.left,
			mi.monitor.top,
			mi.monitor.right - mi.monitor.left,
			mi.monitor.bottom - mi.monitor.top,
			win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED,
		)

	}

	window.is_fullscreen = !window.is_fullscreen
}
