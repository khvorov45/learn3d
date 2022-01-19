package learn3d

import "core:sys/win32"
import "core:fmt"
import "core:runtime"

foreign import my_win32 "system:User32.lib"

foreign my_win32 {
	@(link_name = "ClipCursor")
	clip_cursor :: proc(confine_rect: ^win32.Rect) -> win32.Bool ---
	@(link_name = "ShowCursor")
	show_cursor :: proc(show: win32.Bool) -> i32 ---
}

PlatformWindow :: struct {
	decorations_dim:    [2]int,
	hwnd:               win32.Hwnd,
	hdc:                win32.Hdc,
	pixel_info:         win32.Bitmap_Info,
	previous_placement: win32.Window_Placement,
	context_creation:   runtime.Context,
}

init_window :: proc(window: ^Window, title: string, width: int, height: int) {

	window_class_name := title
	window_name := window_class_name
	window_dim := [2]int{width, height}

	window_instance := win32.get_module_handle_a(nil)
	assert(window_instance != nil)

	COLOR_WINDOW :: 5

	window_class: win32.Wnd_Class_Ex_A
	window_class.size = size_of(window_class)
	window_class.style = win32.CS_HREDRAW | win32.CS_VREDRAW
	window_class.wnd_proc = window_proc
	window_class.instance = win32.Hinstance(window_instance)
	window_class.class_name = cstring(raw_data(window_class_name))
	window_class.background = nil
	window_class.cursor = win32.load_cursor_a(nil, win32.IDC_ARROW)

	assert(win32.register_class_ex_a(&window_class) != 0)

	hwnd := win32.create_window_ex_a(
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
	assert(hwnd != nil)

	win32.set_window_long_ptr_a(hwnd, win32.GWLP_USERDATA, win32.Long_Ptr(uintptr(window)))

	// NOTE(khvorov) Resize so that dim corresponds to the client area
	decorations_dim: [2]int
	{
		client_rect: win32.Rect
		win32.get_client_rect(hwnd, &client_rect)
		window_rect: win32.Rect
		win32.get_window_rect(hwnd, &window_rect)
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
			hwnd,
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

	win32.show_window(hwnd, SW_SHOWMINIMIZED)
	win32.show_window(hwnd, SW_SHOWNORMAL)

	hdc := win32.get_dc(hwnd)
	assert(hdc != nil)

	pixel_info: win32.Bitmap_Info
	pixel_info.header.size = size_of(pixel_info.header)
	pixel_info.header.width = i32(width)
	pixel_info.header.height = -i32(height) // NOTE(khvorov) Negative means top-down
	pixel_info.header.planes = 1
	pixel_info.header.bit_count = 32
	pixel_info.header.compression = win32.BI_RGB

	previous_placement: win32.Window_Placement
	previous_placement.length = size_of(previous_placement)

	// NOTE(khvorov) Register raw input mouse
	{
		HID_USAGE_PAGE_GENERIC :: 0x01
		HID_USAGE_GENERIC_MOUSE :: 0x02
		RIDEV_INPUTSINK :: 0x00000100

		rid: win32.Raw_Input_Device
		rid.usage_page = HID_USAGE_PAGE_GENERIC
		rid.usage = HID_USAGE_GENERIC_MOUSE
		rid.flags = RIDEV_INPUTSINK
		rid.wnd_target = hwnd
		win32.register_raw_input_devices(&rid, 1, size_of(rid))
	}

	window^ = Window{
		true,
		false,
		false,
		window_dim,
		{decorations_dim, hwnd, hdc, pixel_info, previous_placement, context},
	}
}

toggle_camera_control :: proc(window: ^Window) {

	hwnd := window.platform.hwnd

	if window.camera_control {

		clip_cursor(nil)
		show_cursor(true)

	} else {

		client_topleft := win32.Point{0, 0}
		win32.client_to_screen(hwnd, &client_topleft)
		client_bottomright := win32.Point{i32(window.dim.x), i32(window.dim.y)}
		win32.client_to_screen(hwnd, &client_bottomright)

		confine: win32.Rect
		confine.left = client_topleft.x
		confine.top = client_topleft.y
		confine.right = client_bottomright.x
		confine.bottom = client_bottomright.y
		clip_cursor(&confine)
		show_cursor(false)

	}

	window.camera_control = !window.camera_control

}

poll_input :: proc(window: ^Window, input: ^Input) {

	hwnd := window.platform.hwnd

	input.cursor_delta = 0

	message: win32.Msg
	for win32.peek_message_a(&message, hwnd, 0, 0, 1) {

		switch message.message {

		case win32.WM_KEYDOWN, win32.WM_SYSKEYDOWN, win32.WM_KEYUP, win32.WM_SYSKEYUP:
			ended_down := (message.lparam & (1 << 31)) == 0
			switch message.wparam {
			case win32.VK_RETURN:
				record_key(input, .Enter, ended_down)
			case win32.VK_MENU:
				if message.lparam & (1 << 24) != 0 {
					record_key(input, .AltR, ended_down)
				}
			case win32.VK_SPACE:
				record_key(input, .Space, ended_down)
			case win32.VK_CONTROL:
				record_key(input, .Ctrl, ended_down)
			case win32.VK_SHIFT:
				record_key(input, .Shift, ended_down)
			case 'W':
				record_key(input, .W, ended_down)
			case 'A':
				record_key(input, .A, ended_down)
			case 'S':
				record_key(input, .S, ended_down)
			case 'D':
				record_key(input, .D, ended_down)
			case 'Q':
				record_key(input, .Q, ended_down)
			case 'E':
				record_key(input, .E, ended_down)
			case '1':
				record_key(input, .Digit1, ended_down)
			case '2':
				record_key(input, .Digit2, ended_down)
			case '3':
				record_key(input, .Digit3, ended_down)
			case '4':
				record_key(input, .Digit4, ended_down)
			case '5':
				record_key(input, .Digit5, ended_down)
			case '6':
				record_key(input, .Digit6, ended_down)
			case '7':
				record_key(input, .Digit7, ended_down)
			case '8':
				record_key(input, .Digit8, ended_down)
			case '9':
				record_key(input, .Digit9, ended_down)
			case '0':
				record_key(input, .Digit0, ended_down)
			case win32.VK_F1:
				record_key(input, .F1, ended_down)
			}

		// NOTE(khvorov) Update mouse delta
		case win32.WM_INPUT:
			if window.camera_control {
				raw: win32.Raw_Input
				size := u32(size_of(raw))

				win32.get_raw_input_data(
					(cast(^win32.Hrawinput)&message.lparam)^,
					win32.RID_INPUT,
					&raw,
					&size,
					size_of(win32.Raw_Input_Header),
				)
				if raw.header.kind == win32.RIM_TYPEMOUSE {
					x_pos := raw.data.mouse.last_x
					y_pos := raw.data.mouse.last_y
					input.cursor_delta = [2]f32{f32(x_pos), f32(y_pos)}
				}
			}

		case:
			win32.translate_message(&message)
			win32.dispatch_message_a(&message)
		}

	}

	// NOTE(khvorov) Update dim
	{
		rect: win32.Rect
		win32.get_client_rect(window.platform.hwnd, &rect)
		window.dim.y = int(rect.bottom - rect.top)
		window.dim.x = int(rect.right - rect.left)
	}

	// NOTE(khvorov) Update mouse position
	{
		cursor_screen: win32.Point
		win32.get_cursor_pos(&cursor_screen)
		win32.screen_to_client(window.platform.hwnd, &cursor_screen)
		cursor_client := [2]f32{f32(cursor_screen.x), f32(cursor_screen.y)}
		input.cursor_pos = cursor_client
	}

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	if window.is_running {
		result := win32.stretch_dibits(
			window.platform.hdc,
			0,
			0,
			i32(window.dim.x),
			i32(window.dim.y),
			0,
			0,
			i32(pixels_dim.x),
			i32(pixels_dim.y),
			raw_data(pixels),
			&window.platform.pixel_info,
			win32.DIB_RGB_COLORS,
			win32.SRCCOPY,
		)
		assert(
			result == i32(pixels_dim.y),
			fmt.tprintf("expected {}, got {}\n", pixels_dim.y, result),
		)
	}

}

window_proc :: proc "std" (
	hwnd: win32.Hwnd,
	message: u32,
	wparam: win32.Wparam,
	lparam: win32.Lparam,
) -> win32.Lresult {

	result: win32.Lresult

	window := cast(^Window)uintptr(win32.get_window_long_ptr_a(hwnd, win32.GWLP_USERDATA))

	if (window != nil) {
		context = window.platform.context_creation

		switch message {

		case win32.WM_DESTROY:
			window.is_running = false

		case:
			result = win32.def_window_proc_a(hwnd, message, wparam, lparam)

		}

	} else {
		result = win32.def_window_proc_a(hwnd, message, wparam, lparam)
	}

	return result
}

toggle_fullscreen :: proc(window: ^Window) {

	// NOTE(khvorov) Taken from https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353

	style := win32.get_window_long_ptr_a(window.platform.hwnd, win32.GWL_STYLE)

	if window.is_fullscreen {

		win32.set_window_long_ptr_a(
			window.platform.hwnd,
			win32.GWL_STYLE,
			win32.Long_Ptr(uint(style) | uint(win32.WS_OVERLAPPEDWINDOW)),
		)

		win32.set_window_placement(window.platform.hwnd, &window.platform.previous_placement)

		win32.set_window_pos(
			window.platform.hwnd,
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
			win32.monitor_from_window(window.platform.hwnd, win32.MONITOR_DEFAULTTOPRIMARY),
			&mi,
		)
		assert(bool(get_monitor_result))

		get_window_placement_result := win32.get_window_placement(
			window.platform.hwnd,
			&window.platform.previous_placement,
		)
		assert(bool(get_window_placement_result))

		win32.set_window_long_ptr_a(
			window.platform.hwnd,
			win32.GWL_STYLE,
			win32.Long_Ptr(uint(style) & ~uint(win32.WS_OVERLAPPEDWINDOW)),
		)

		HWND_TOP: win32.Hwnd = nil

		win32.set_window_pos(
			window.platform.hwnd,
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
