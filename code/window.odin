package learn3d

Window :: struct {
	is_running:           bool,
	is_fullscreen:        bool,
	is_focused:           bool,
	mouse_camera_control: bool,
	dim:                  [2]int,
	platform:             PlatformWindow,
}

toggle_mouse_camera_control :: proc(window: ^Window) {

	if window.mouse_camera_control {
		unclip_and_show_cursor(window)
	} else {
		clip_and_hide_cursor(window)
	}

	window.mouse_camera_control = !window.mouse_camera_control
}
