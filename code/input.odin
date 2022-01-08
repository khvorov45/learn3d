package learn3d

Input :: struct {
	keys: [KeyID.Count]Key,
}

//odinfmt: disable
KeyID :: enum {
	AltR, Enter, Shift, Space, Ctrl,
	W, A, S, D, Q, E,
	Digit1, Digit2, Digit3, Digit4, Digit5, Digit6, Digit7, Digit8, Digit9, Digit0,
	Count,
}
//odinfmt: enable

Key :: struct {
	ended_down:            bool,
	half_transition_count: int,
}

clear_half_transitions :: proc(input: ^Input) {
	for key in &input.keys {
		key.half_transition_count = 0
	}
}

was_pressed :: proc(input: Input, key_id: KeyID) -> bool {
	key := input.keys[key_id]
	result := false
	if key.half_transition_count >= 2 {
		result = true
	} else if key.half_transition_count == 1 {
		result = key.ended_down
	}
	return result
}

record_key :: proc(input: ^Input, key_id: KeyID, ended_down: bool) {
	input.keys[key_id].ended_down = ended_down
	input.keys[key_id].half_transition_count += 1
}
