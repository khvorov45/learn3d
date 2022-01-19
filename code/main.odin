package learn3d

import "core:time"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:math/linalg"

import mu "vendor:microui"

import bf "bitmap_font"

main :: proc() {

	window: Window
	init_window(&window, "learn3d", 1280, 720)

	renderer := create_renderer(
		window.dim.x,
		window.dim.y,
		65536,
		65536,
		to_radians(90),
		0.1,
		10,
	)

	read_mesh :: proc(renderer: ^Renderer, name: string, translation: [3]f32) -> (
		Mesh,
		Texture,
	) {
		mesh: Mesh
		mesh.scale = 1
		mesh.translation = translation
		mesh.vertices, mesh.triangles = read_obj(
			read_file(fmt.tprintf("assets/{}.obj", name)),
			renderer.vertices[renderer.vertex_count:],
			renderer.triangles[renderer.triangle_count:],
		)

		renderer.vertex_count += len(mesh.vertices)
		renderer.triangle_count += len(mesh.triangles)

		texture := read_image(read_file(fmt.tprintf("assets/{}.png", name)))

		return mesh, texture
	}

	mesh_f22, texture_f22 := read_mesh(&renderer, "f22", [3]f32{3, 0, 3.5})
	mesh_f117, texture_f117 := read_mesh(&renderer, "f117", [3]f32{-3, 0, 3.5})
	mesh_cube, texture_cube := read_mesh(&renderer, "cube", [3]f32{0, 0, 3.5})

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	input: Input

	ui: mu.Context
	mu.init(&ui)
	{
		text_width := proc(font: mu.Font, text: string) -> i32 {
			return i32(bf.GLYPH_WIDTH_PX * len(text))
		}
		ui.text_width = text_width
		ui.text_height = proc(font: mu.Font) -> i32 {return bf.GLYPH_HEIGHT_PX}
	}

	bitmap_font_tex := bf.get_texture_u8_slice()

	init_global_timings()

	for window.is_running {

		begin_timed_frame()

		time_frame_start := time.tick_now()

		//
		// SECTION Input
		//

		begin_timed_section(.Input)

		clear_half_transitions(&input)
		poll_input(&window, &input)

		end_timed_section(.Input)

		//
		// SECTION Update
		//

		begin_timed_section(.Update)

		if input.keys[KeyID.AltR].ended_down && was_pressed(input, .Enter) {
			toggle_fullscreen(&window)
		}

		speed: f32 = 0.02
		mouse_sensitivity: f32 = 0.01
		if input.keys[KeyID.Shift].ended_down {
			speed *= 5
		}

		if window.camera_control {

			// NOTE(khvorov) Rotate camera input
			{
				delta_z: f32 = 0
				if input.keys[KeyID.Q].ended_down {
					delta_z += speed
				}
				if input.keys[KeyID.E].ended_down {
					delta_z -= speed
				}
				camera_z_rotation := get_rotation3(renderer.camera_axes.z, delta_z)
				renderer.camera_axes.x = camera_z_rotation * renderer.camera_axes.x
				renderer.camera_axes.y = camera_z_rotation * renderer.camera_axes.y
			}

			{
				camera_y_rotation := get_rotation3(
					renderer.camera_axes.y,
					input.cursor_delta.x * mouse_sensitivity,
				)
				renderer.camera_axes.x = camera_y_rotation * renderer.camera_axes.x
				renderer.camera_axes.z = camera_y_rotation * renderer.camera_axes.z
			}

			{
				camera_x_rotation := get_rotation3(
					renderer.camera_axes.x,
					input.cursor_delta.y * mouse_sensitivity,
				)
				renderer.camera_axes.y = camera_x_rotation * renderer.camera_axes.y
				renderer.camera_axes.z = camera_x_rotation * renderer.camera_axes.z
			}

			// NOTE(khvorov) Move camera input
			if input.keys[KeyID.A].ended_down {
				renderer.camera_pos -= speed * renderer.camera_axes.x
			}
			if input.keys[KeyID.D].ended_down {
				renderer.camera_pos += speed * renderer.camera_axes.x
			}
			if input.keys[KeyID.W].ended_down {
				renderer.camera_pos += speed * renderer.camera_axes.z
			}
			if input.keys[KeyID.S].ended_down {
				renderer.camera_pos -= speed * renderer.camera_axes.z
			}
			if input.keys[KeyID.Space].ended_down {
				renderer.camera_pos += speed * renderer.camera_axes.y
			}
			if input.keys[KeyID.Ctrl].ended_down {
				renderer.camera_pos -= speed * renderer.camera_axes.y
			}

		}

		if was_pressed(input, .Digit1) {
			toggle_option(&renderer, .FilledTriangles)
		}
		if was_pressed(input, .Digit2) {
			toggle_option(&renderer, .Wireframe)
		}
		if was_pressed(input, .Digit3) {
			toggle_option(&renderer, .Vertices)
		}
		if was_pressed(input, .Digit4) {
			toggle_option(&renderer, .Normals)
		}
		if was_pressed(input, .Digit5) {
			toggle_option(&renderer, .Midpoints)
		}
		if was_pressed(input, .Digit6) {
			toggle_option(&renderer, .BackfaceCull)
		}

		if was_pressed(input, .F1) {
			toggle_camera_control(&window)
		}

		if !window.camera_control {

			mu.begin(&ui)

			if mu.begin_window(&ui, "Timings", mu.Rect{0, 0, 450, 300}) {

				row_widths := [4]i32{100, 100, 100, 100}
				mu.layout_row(&ui, row_widths[:])

				for timed_section, index in GlobalTimings.last_frame {
					mu.text(&ui, fmt.tprintf("{}", TimedSectionID(index)))
					mu.text(&ui, fmt.tprintf("%.2f", timed_section.total_ms))
					mu.text(&ui, fmt.tprintf("{}", timed_section.hit_count))
					mu.text(
						&ui,
						fmt.tprintf("%.2f", timed_section.total_ms / f64(timed_section.hit_count)),
					)
				}

				mu.end_window(&ui)

			}

			mu.end(&ui)

		}

		end_timed_section(.Update)

		//
		// SECTION Render
		//

		begin_timed_section(.Render)

		begin_timed_section(.Clear)

		clear(&renderer)

		end_timed_section(.Clear)

		draw_mesh(&renderer, mesh_f22, texture_f22)
		draw_mesh(&renderer, mesh_f117, texture_f117)
		draw_mesh(&renderer, mesh_cube, texture_cube)

		begin_timed_section(.UI)

		if !window.camera_control {

			ui_cmd: ^mu.Command = nil
			for mu.next_command(&ui, &ui_cmd) {

				switch cmd in ui_cmd.variant {

				case ^mu.Command_Text:
					coords := [2]f32{f32(cmd.pos.x), f32(cmd.pos.y)}
					color := mu_color_to_u32(cmd.color)
					draw_bitmap_string_px(&renderer, cmd.str, coords, color)

				case ^mu.Command_Rect:
					rect := Rect2d{
						[2]f32{f32(cmd.rect.x), f32(cmd.rect.y)},
						[2]f32{f32(cmd.rect.w), f32(cmd.rect.h)},
					}
					draw_rect_px(&renderer, rect, mu_color_to_u32(cmd.color))

				case ^mu.Command_Icon:

				case ^mu.Command_Clip:

				case ^mu.Command_Jump:

				}
			}

		}

		end_timed_section(.UI)

		begin_timed_section(.Display)

		display_pixels(&window, renderer.pixels, renderer.pixels_dim)

		end_timed_section(.Display)

		end_timed_section(.Render)

		//
		// SECTION Frame time
		//

		begin_timed_section(.Sleep)

		frame_work := time.tick_since(time_frame_start)
		frame_sleep := target_frame_duration - frame_work - time.Millisecond
		if frame_sleep > 0 {
			time.sleep(frame_sleep)
		}

		end_timed_section(.Sleep)

		begin_timed_section(.Spin)

		for time.tick_since(time_frame_start) < target_frame_duration {}

		end_timed_section(.Spin)

		end_timed_frame()

	}

}

mu_color_to_u32 :: proc(col: mu.Color) -> u32 {
	col := col
	result := (cast(^u32)&col)^
	return result
}
