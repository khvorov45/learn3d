package window

Window :: struct {
	is_running:    bool,
	is_fullscreen: bool,
	dim:           [2]int,
}

Input :: struct {
	alt_r, enter, W, A, S, D, Q, E: Key,
}

Key :: struct {
	ended_down:            bool,
	half_transition_count: int,
}

clear_half_transitions :: proc(input: ^Input) {
	using input
	alt_r.half_transition_count = 0
	enter.half_transition_count = 0
}

was_pressed :: proc(key: Key) -> bool {
	result := false
	if key.half_transition_count >= 2 {
		result = true
	} else if key.half_transition_count == 1 {
		result = key.ended_down
	}
	return result
}
