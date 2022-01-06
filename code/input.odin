package learn3d

import "core:reflect"

//odinfmt: disable
Input :: struct {
	alt_r, enter, shift,
	W, A, S, D, Q, E,
	digit1, digit2, digit3, digit4, digit5, digit6, digit7, digit8, digit9, digit0: Key,
}
//odinfmt: enable

Key :: struct {
	ended_down:            bool,
	half_transition_count: int,
}

clear_half_transitions :: proc(input: ^Input) {
	for name in reflect.struct_field_names(Input) {
		val := reflect.struct_field_value_by_name(input^, name)
		switch v in &val {
		case Key:
			v.half_transition_count = 0
		}
	}
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
