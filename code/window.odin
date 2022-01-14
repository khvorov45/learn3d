package learn3d

Window :: struct {
	is_running:     bool,
	is_fullscreen:  bool,
	camera_control: bool,
	dim:            [2]int,
	platform:       PlatformWindow,
}
