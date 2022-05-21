package learn3d

import "core:fmt"
import "core:runtime"

import win "windows"

PlatformWindow :: struct {
	decorations_dim:    [2]int,
	hwnd:               win.HWND,
	hdc:                win.HDC,
	pixel_info:         win.BITMAPINFO,
	previous_placement: win.WINDOWPLACEMENT,
	context_creation:   runtime.Context,
}

init_window :: proc(window: ^Window, title: string, width: int, height: int) {

	window_class_name := title
	window_name := window_class_name
	window_dim := [2]int{width, height}

	window_instance := win.GetModuleHandleA(nil)
	assert(window_instance != nil)

	window_class := win.WNDCLASSEXA {
		cbSize = size_of(win.WNDCLASSEXA),
		style = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_proc,
		hInstance = win.HINSTANCE(window_instance),
		lpszClassName = cstring(raw_data(window_class_name)),
		hbrBackground = nil,
		hCursor = win.LoadCursorA(nil, win.IDC_ARROW),
	}


	assert(win.RegisterClassExA(&window_class) != 0)

	hwnd := win.CreateWindowExA(
		0,
		cstring(raw_data(window_class_name)),
		cstring(raw_data(window_name)),
		win.WS_OVERLAPPEDWINDOW,
		win.CW_USEDEFAULT,
		win.CW_USEDEFAULT,
		i32(window_dim.x),
		i32(window_dim.y),
		nil,
		nil,
		win.HINSTANCE(window_instance),
		nil,
	)
	assert(hwnd != nil)

	// NOTE(khvorov) To be able to access stuff in the callback
	win.SetWindowLongPtrA(hwnd, win.GWLP_USERDATA, win.LONG_PTR(uintptr(window)))

	// NOTE(khvorov) Resize so that dim corresponds to the client area
	decorations_dim: [2]int
	{
		client_rect: win.RECT
		win.GetClientRect(hwnd, &client_rect)
		window_rect: win.RECT
		win.GetWindowRect(hwnd, &window_rect)
		client_rect_dim := [2]int{
			int(client_rect.right - client_rect.left),
			int(client_rect.bottom - client_rect.top),
		}
		window_rect_dim := [2]int{
			int(window_rect.right - window_rect.left),
			int(window_rect.bottom - window_rect.top),
		}
		decorations_dim = window_rect_dim - client_rect_dim

		win.SetWindowPos(
			hwnd,
			nil,
			0,
			0,
			i32(width + decorations_dim.x),
			i32(height + decorations_dim.y),
			win.SWP_NOMOVE,
		)
	}

	// NOTE(khvorov) To avoid a white flash
	win.ShowWindow(hwnd, win.SW_SHOWMINIMIZED)
	win.ShowWindow(hwnd, win.SW_SHOWNORMAL)

	hdc := win.GetDC(hwnd)
	assert(hdc != nil)

	pixel_info := win.BITMAPINFO { bmiHeader = {
		biSize = size_of(win.BITMAPINFOHEADER),
		biWidth = i32(width),
		biHeight = -i32(height), // NOTE(khvorov) Negative means top-down
		biPlanes = 1,
		biBitCount = 32,
		biCompression = win.BI_RGB,
	}}

	previous_placement := win.WINDOWPLACEMENT {length = size_of(win.WINDOWPLACEMENT)}

	// NOTE(khvorov) Register raw input mouse
	{
		rid := win.RAWINPUTDEVICE {
			usUsagePage = win.HID_USAGE_PAGE_GENERIC,
			usUsage = win.HID_USAGE_GENERIC_MOUSE,
			dwFlags = win.RIDEV_INPUTSINK,
			hwndTarget = hwnd,
		}
		win.RegisterRawInputDevices(&rid, 1, size_of(rid))
	}

	window^ = Window{
		true,
		false,
		true,
		false,
		window_dim,
		{decorations_dim, hwnd, hdc, pixel_info, previous_placement, context},
	}
}

unclip_and_show_cursor :: proc(window: ^Window) {
	win.ClipCursor(nil)
	win.ShowCursor(win.TRUE)
}

clip_and_hide_cursor :: proc(window: ^Window) {

	hwnd := window.platform.hwnd

	client_topleft := win.POINT{0, 0}
	win.ClientToScreen(hwnd, &client_topleft)
	client_bottomright := win.POINT{i32(window.dim.x), i32(window.dim.y)}
	win.ClientToScreen(hwnd, &client_bottomright)

	confine := win.RECT {
		left = client_topleft.x,
		top = client_topleft.y,
		right = client_bottomright.x,
		bottom = client_bottomright.y,
	}
	win.ClipCursor(&confine)
	win.ShowCursor(win.FALSE)
}

poll_input :: proc(window: ^Window, input: ^Input) {

	hwnd := window.platform.hwnd

	input.cursor_delta = 0

	message: win.MSG
	for win.PeekMessageA(&message, hwnd, 0, 0, 1) != win.FALSE {

		switch message.message {

		case win.WM_KEYDOWN, win.WM_SYSKEYDOWN, win.WM_KEYUP, win.WM_SYSKEYUP:
			ended_down := (message.lParam & (1 << 31)) == 0

			switch message.wParam {

			case win.VK_RETURN:
				record_key(input, .Enter, ended_down)

			case win.VK_MENU:
				if message.lParam & (1 << 24) != 0 {
					record_key(input, .AltR, ended_down)
				} else {
					record_key(input, .AltL, ended_down)
				}

			case win.VK_SPACE:
				record_key(input, .Space, ended_down)

			case win.VK_CONTROL:
				record_key(input, .Ctrl, ended_down)

			case win.VK_SHIFT:
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

			case win.VK_F1:
				record_key(input, .F1, ended_down)

			case win.VK_F4:
				record_key(input, .F4, ended_down)

			}

		// NOTE(khvorov) Update mouse delta
		case win.WM_INPUT:
			if window.mouse_camera_control && window.is_focused {

				raw_size := win.DWORD(size_of(win.RAWINPUT))
				raw := win.RAWINPUT{header = win.RAWINPUTHEADER{dwSize = raw_size}}

				win.GetRawInputData(
					(cast(^win.HRAWINPUT)&message.lParam)^,
					win.RID_INPUT,
					&raw,
					&raw_size,
					size_of(win.RAWINPUTHEADER),
				)

				if raw.header.dwType == win.RIM_TYPEMOUSE {
					x_pos := raw.data.mouse.lLastX
					y_pos := raw.data.mouse.lLastY
					input.cursor_delta = [2]f32{f32(x_pos), f32(y_pos)}
				}
			}

		case win.WM_LBUTTONDOWN:
			record_key(input, .MouseLeft, true)

		case win.WM_MBUTTONDOWN:
			record_key(input, .MouseMiddle, true)

		case win.WM_RBUTTONDOWN:
			record_key(input, .MouseRight, true)

		case win.WM_LBUTTONUP:
			record_key(input, .MouseLeft, false)

		case win.WM_MBUTTONUP:
			record_key(input, .MouseMiddle, false)

		case win.WM_RBUTTONUP:
			record_key(input, .MouseRight, false)

		case:
			win.TranslateMessage(&message)
			win.DispatchMessageA(&message)
		}
	}

	// NOTE(khvorov) Update dim
	{
		rect: win.RECT
		win.GetClientRect(window.platform.hwnd, &rect)
		window.dim.y = int(rect.bottom - rect.top)
		window.dim.x = int(rect.right - rect.left)
	}

	// NOTE(khvorov) Update mouse position
	{
		cursor_screen: win.POINT
		win.GetCursorPos(&cursor_screen)
		win.ScreenToClient(window.platform.hwnd, &cursor_screen)
		cursor_client := [2]f32{f32(cursor_screen.x), f32(cursor_screen.y)}
		input.cursor_pos = cursor_client
	}

}

display_pixels :: proc(window: ^Window, pixels: []u32, pixels_dim: [2]int) {

	if window.is_running {

		result := win.StretchDIBits(
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
			win.DIB_RGB_COLORS,
			win.SRCCOPY,
		)
		assert(
			result == i32(pixels_dim.y),
			fmt.tprintf("expected {}, got {}\n", pixels_dim.y, result),
		)

	}

}

window_proc :: proc "stdcall" (
	hwnd: win.HWND,
	message: win.UINT,
	wparam: win.WPARAM,
	lparam: win.LPARAM,
) -> win.LRESULT {

	result: win.LRESULT

	window := cast(^Window)uintptr(win.GetWindowLongPtrA(hwnd, win.GWLP_USERDATA))

	if (window != nil) {
		context = window.platform.context_creation

		switch message {

		case win.WM_DESTROY:
			window.is_running = false

		case win.WM_KILLFOCUS:
			window.is_focused = false
			if window.mouse_camera_control {
				unclip_and_show_cursor(window)
			}
			result = win.DefWindowProcA(hwnd, message, wparam, lparam)

		case win.WM_SETFOCUS:
			window.is_focused = true
			if window.mouse_camera_control {
				clip_and_hide_cursor(window)
			}
			result = win.DefWindowProcA(hwnd, message, wparam, lparam)

		case:
			result = win.DefWindowProcA(hwnd, message, wparam, lparam)

		}

	} else {
		result = win.DefWindowProcA(hwnd, message, wparam, lparam)
	}

	return result
}

toggle_fullscreen :: proc(window: ^Window) {

	// NOTE(khvorov) Taken from https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353

	style := win.GetWindowLongPtrA(window.platform.hwnd, win.GWL_STYLE)

	if window.is_fullscreen {

		win.SetWindowLongPtrA(
			window.platform.hwnd,
			win.GWL_STYLE,
			win.LONG_PTR(uint(style) | uint(win.WS_OVERLAPPEDWINDOW)),
		)

		win.SetWindowPlacement(window.platform.hwnd, &window.platform.previous_placement)

		win.SetWindowPos(
			window.platform.hwnd,
			nil,
			0,
			0,
			0,
			0,
			win.SWP_NOMOVE |
			win.SWP_NOSIZE |
			win.SWP_NOZORDER |
			win.SWP_NOOWNERZORDER |
			win.SWP_FRAMECHANGED,
		)

	} else {

		mi := win.MONITORINFO{cbSize = size_of(win.MONITORINFO)}
		get_monitor_result := win.GetMonitorInfoA(
			win.MonitorFromWindow(window.platform.hwnd, win.MONITOR_DEFAULTTOPRIMARY),
			&mi,
		)
		assert(bool(get_monitor_result))

		get_window_placement_result := win.GetWindowPlacement(
			window.platform.hwnd,
			&window.platform.previous_placement,
		)
		assert(bool(get_window_placement_result))

		win.SetWindowLongPtrA(
			window.platform.hwnd,
			win.GWL_STYLE,
			win.LONG_PTR(uint(style) & ~uint(win.WS_OVERLAPPEDWINDOW)),
		)

		HWND_TOP: win.HWND = nil

		win.SetWindowPos(
			window.platform.hwnd,
			HWND_TOP,
			mi.rcMonitor.left,
			mi.rcMonitor.top,
			mi.rcMonitor.right - mi.rcMonitor.left,
			mi.rcMonitor.bottom - mi.rcMonitor.top,
			win.SWP_NOOWNERZORDER | win.SWP_FRAMECHANGED,
		)
	}

	window.is_fullscreen = !window.is_fullscreen
}
