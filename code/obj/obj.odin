package obj

import "core:strings"
import "core:strconv"

import rdr "learn3d:renderer"

read_mesh :: proc(file_data: []u8, mesh: ^rdr.Mesh) {
	input_left := string(file_data)

	for len(input_left) > 0 {

		line_end := strings.index_any(input_left, "\r\n")
		line := input_left[:line_end]
		input_left = input_left[line_end + 1:]

		parse_f32 :: proc(input: string, one_past_end: int) -> (f32, string) {
			input_left := input
			assert(one_past_end != -1)
			num_string := input_left[:one_past_end]
			input_left = input_left[one_past_end:]
			if len(input_left) > 0 {
				input_left = input_left[1:]
			}
			num, ok := strconv.parse_f32(num_string)
			assert(ok)
			return num, input_left
		}

		read_face_entry :: proc(input: string, one_past_end: int) -> (int, string) {
			input_left := input
			assert(one_past_end != -1)
			entry := input_left[:one_past_end]
			input_left = input_left[one_past_end:]
			if len(input_left) > 0 {
				input_left = input_left[1:]
			}

			read_one_number :: proc(input: string) -> (int, string) {
				input_left := input
				one_past_end := strings.index_rune(input_left, '/')
				num_string: string
				if one_past_end != -1 {
					num_string = input_left[:one_past_end]
					input_left = input_left[one_past_end + 1:]
				} else {
					num_string = input_left
					input_left = input_left[len(input_left):]
				}
				num, ok := strconv.parse_int(num_string)
				assert(ok)
				return num, input_left
			}

			num: int
			num, entry = read_one_number(entry)

			return num, input_left
		}

		if len(line) >= 2 {
			first_2 := line[:2]
			line = line[2:]
			switch first_2 {
			case "v ":
				vertex: [3]f32
				vertex.x, line = parse_f32(line, strings.index_rune(line, ' '))
				vertex.y, line = parse_f32(line, strings.index_rune(line, ' '))
				vertex.z, line = parse_f32(line, len(line))
				append(&mesh.vertices, vertex)
			case "f ":
				face: [3]int
				face.x, line = read_face_entry(line, strings.index_rune(line, ' '))
				face.y, line = read_face_entry(line, strings.index_rune(line, ' '))
				face.z, line = read_face_entry(line, len(line))
				face -= 1
				append(&mesh.faces, face)
			}
		}

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

}
