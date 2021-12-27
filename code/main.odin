package main

import "core:sys/win32"

main :: proc() {

	window_class_name := "Learn3d"
	window_name := window_class_name
	window_dim := [2]int{1280, 720}

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

	SW_SHOWNORMAL :: 1
	SW_SHOWMINIMIZED :: 2

	win32.show_window(window, SW_SHOWMINIMIZED)
	win32.show_window(window, SW_SHOWNORMAL)

	for {

		message: win32.Msg
		for win32.peek_message_a(&message, window, 0, 0, 1) {
			win32.translate_message(&message)
			win32.dispatch_message_a(&message)
		}

	}

}

window_proc :: proc(
	window: win32.Hwnd,
	message: u32,
	wparam: win32.Wparam,
	lparam: win32.Lparam,
) -> win32.Lresult {
	result := win32.def_window_proc_a(window, message, wparam, lparam)
	return result
}
