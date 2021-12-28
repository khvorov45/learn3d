package window_win32

import "core:sys/win32"

GlobalRunning := true

Window :: struct {
	is_running:            bool,
	dim:                   [2]int,
	win32_decorations_dim: [2]int,
	win32_hwnd:            win32.Hwnd,
	win32_hdc:             win32.Hdc,
	win32_pixel_info:      win32.Bitmap_Info,
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

	result := Window{true, window_dim, decorations_dim, window, hdc, pixel_info}
	return result
}

poll_input :: proc(window: ^Window) {

	hwnd := window.win32_hwnd

	message: win32.Msg
	for win32.peek_message_a(&message, hwnd, 0, 0, 1) {

		switch message.message {
		case:
			win32.translate_message(&message)
			win32.dispatch_message_a(&message)
		}

	}

	// NOTE(sen) Update dim
	{
		rect: win32.Rect
		win32.get_client_rect(window.win32_hwnd, &rect)
		window.dim.y = int(rect.top - rect.bottom)
		window.dim.x = int(rect.right - rect.left)
	}

	window.is_running = GlobalRunning

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	if window.is_running {
		result := win32.stretch_dibits(
			window.win32_hdc,
			0,
			0,
			i32(pixels_dim.x),
			i32(pixels_dim.y),
			0,
			0,
			i32(pixels_dim.x),
			i32(pixels_dim.y),
			raw_data(pixels),
			&window.win32_pixel_info,
			win32.DIB_RGB_COLORS,
			win32.SRCCOPY,
		)
		assert(result == i32(pixels_dim.y))
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
