package learn3d

import "core:strings"
import "core:strconv"

read_mesh :: proc(file_data: []u8, mesh: ^Mesh) {
	input_left := string(file_data)

	tex_coords := make([dynamic][2]f32, context.temp_allocator)

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

		read_face_entry :: proc(input: string, one_past_end: int) -> ([2]int, string) {
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

			num1, num2: int
			num1, entry = read_one_number(entry)
			num2, entry = read_one_number(entry)

			return [2]int{num1, num2}, input_left
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

			case "vt":
				line := line[1:]
				tex: [2]f32
				tex.x, line = parse_f32(line, strings.index_rune(line, ' '))
				tex.y, line = parse_f32(line, len(line))
				append(&tex_coords, tex)

			case "f ":
				face_entries: [3][2]int
				face_entries[0], line = read_face_entry(line, strings.index_rune(line, ' '))
				face_entries[1], line = read_face_entry(line, strings.index_rune(line, ' '))
				face_entries[2], line = read_face_entry(line, len(line))

				face: Face

				face.indices[0] = face_entries[0][0] - 1
				face.indices[1] = face_entries[1][0] - 1
				face.indices[2] = face_entries[2][0] - 1

				face.texture[0] = tex_coords[face_entries[0][1] - 1]
				face.texture[1] = tex_coords[face_entries[1][1] - 1]
				face.texture[2] = tex_coords[face_entries[2][1] - 1]

				face.color = 0.2
				face.color.a = 1

				append(&mesh.faces, face)
			}

		}

		for len(input_left) > 0 && (input_left[0] == '\r' || input_left[0] == '\n') {
			input_left = input_left[1:]
		}

	}

}
