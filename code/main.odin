package learn3d

import "core:time"
import "core:fmt"
import "core:math"

import mu "vendor:microui"

import bf "bitmap_font"

main :: proc() {

	// TODO(khvorov) Better shading with normal maps
	// TODO(khvorov) Texture filtering
	// TODO(khvorov) Alpha blending (transparent UI)

	window: Window
	init_window(&window, "learn3d", 1280, 720)

	renderer: Renderer
	init_renderer(
		&renderer,
		window.dim.x,
		window.dim.y,
		65536,
		65536,
		math.RAD_PER_DEG * 90,
		0.1,
		10,
	)

	mesh_milk, texture_milk := read_mesh_and_texture(
		&renderer,
		"milk",
		[3]f32{3, 0, 3.5},
		0.1,
		{.ConvertToLeftHanded},
	)

	mesh_wheel, texture_wheel := read_mesh_and_texture(
		&renderer,
		"wheel",
		[3]f32{-3, 0, 3.5},
		0.01,
		{.ConvertToLeftHanded},
	)

	mesh_box, texture_box := read_mesh_and_texture(
		&renderer,
		"box",
		[3]f32{0, 0, 3.5},
		1,
		{.ConvertToLeftHanded, .SwapZAndY},
	)

	mesh_sphere, texture_sphere := read_mesh_and_texture(
		&renderer,
		"sphere",
		[3]f32{0, -1.5, 3.5},
		1,
		{.ConvertToLeftHanded, .SwapZAndY},
	)

	target_frame_duration: time.Duration
	{
		target_framerate := 30
		target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
		target_frame_duration = time.Duration(target_frame_ns)
	}

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

	draw_reference_lines := false

	init_global_timings()

	// NOTE(khvorov) Use this for speed adjustments since I won't be hitting
	// consistent framerate any time soon
	last_frame_s := f32(time.duration_seconds(target_frame_duration))

	for window.is_running {

		begin_timed_frame()

		time_frame_start := time.tick_now()

		//
		// SECTION Input
		//

		begin_timed_section(.Input)

		clear_half_transitions(&input)
		if !window.is_focused {
			clear_ended_down(&input)
		}
		poll_input(&window, &input)

		end_timed_section(.Input)

		//
		// SECTION Update
		//

		begin_timed_section(.Update)

		alt_held := input.keys[.AltL].ended_down || input.keys[.AltR].ended_down
		if alt_held && was_pressed(input, .F4) {
			window.is_running = false
		}

		if input.keys[.AltR].ended_down && was_pressed(input, .Enter) {
			toggle_fullscreen(&window)
		}

		if was_pressed(input, .F1) {
			toggle_mouse_camera_control(&window)
		}

		speed_coef: f32 = 1
		if input.keys[.Shift].ended_down {
			speed_coef *= 5
		}

		// NOTE(khvorov) Rotate camera input
		{
			angular_vel: f32 = 30 * speed_coef // NOTE(khvorov) Degrees per second
			abs_delta := math.RAD_PER_DEG * angular_vel * last_frame_s
			delta_z: f32 = 0
			if input.keys[.Q].ended_down {
				delta_z += abs_delta
			}
			if input.keys[.E].ended_down {
				delta_z -= abs_delta
			}
			camera_z_rotation := get_rotation3(renderer.camera_axes.z, delta_z)
			renderer.camera_axes.x = camera_z_rotation * renderer.camera_axes.x
			renderer.camera_axes.y = camera_z_rotation * renderer.camera_axes.y
		}

		if window.mouse_camera_control && window.is_focused {

			mouse_sensitivity: f32 = 0.3
			{
				camera_y_rotation := get_rotation3(
					renderer.camera_axes.y,
					input.cursor_delta.x * mouse_sensitivity * last_frame_s,
				)
				renderer.camera_axes.x = camera_y_rotation * renderer.camera_axes.x
				renderer.camera_axes.z = camera_y_rotation * renderer.camera_axes.z
			}

			{
				camera_x_rotation := get_rotation3(
					renderer.camera_axes.x,
					input.cursor_delta.y * mouse_sensitivity * last_frame_s,
				)
				renderer.camera_axes.y = camera_x_rotation * renderer.camera_axes.y
				renderer.camera_axes.z = camera_x_rotation * renderer.camera_axes.z
			}

		}

		// NOTE(khvorov) Move camera input
		move_speed: f32 = 1 * speed_coef // NOTE(khvorov) World units per second
		abs_move_delta := move_speed * last_frame_s
		if input.keys[.A].ended_down {
			renderer.camera_pos -= abs_move_delta * renderer.camera_axes.x
		}
		if input.keys[.D].ended_down {
			renderer.camera_pos += abs_move_delta * renderer.camera_axes.x
		}
		if input.keys[.W].ended_down {
			renderer.camera_pos += abs_move_delta * renderer.camera_axes.z
		}
		if input.keys[.S].ended_down {
			renderer.camera_pos -= abs_move_delta * renderer.camera_axes.z
		}
		if input.keys[.Space].ended_down {
			renderer.camera_pos += abs_move_delta * renderer.camera_axes.y
		}
		if input.keys[.Ctrl].ended_down {
			renderer.camera_pos -= abs_move_delta * renderer.camera_axes.y
		}

		// NOTE(khvorov) UI
		if !window.mouse_camera_control {

			mu.input_mouse_move(&ui, i32(input.cursor_pos.x), i32(input.cursor_pos.y))

			if was_pressed(input, .MouseLeft) {
				mu.input_mouse_down(&ui, i32(input.cursor_pos.x), i32(input.cursor_pos.y), .LEFT)
			} else if was_unpressed(input, .MouseLeft) {
				mu.input_mouse_up(&ui, i32(input.cursor_pos.x), i32(input.cursor_pos.y), .LEFT)
			}

			mu.begin(&ui)

			if mu.begin_window(&ui, "Timings", mu.Rect{0, 0, 450, 350}) {

				row_widths := [4]i32{100, 100, 100, 100}
				mu.layout_row(&ui, row_widths[:])

				for timed_section, index in global_timings.last_frame {
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

			if mu.begin_window(&ui, "Controls", mu.Rect{0, 350, 400, 700}) {

				row_widths := [1]i32{400}
				mu.layout_row(&ui, row_widths[:])

				mu.text(&ui, "F1 - toggle UI")
				mu.text(&ui, "WS - move camera in Z")
				mu.text(&ui, "AD - move camera in X")
				mu.text(&ui, "Ctrl,Space - move camera in Y")
				mu.text(&ui, "Q,W - rotate camera in Z")
				mu.text(&ui, "Mouse - rotate camera in XY (UI off)")

				mu.end_window(&ui)
			}

			if mu.begin_window(&ui, "View options", mu.Rect{400, 350, 200, 700}) {

				for option in DisplayOption {
					cur_state := option in renderer.options
					new_state := cur_state
					mu.checkbox(&ui, fmt.tprintf("{}", option), &new_state)
					if new_state != cur_state {
						toggle_option(&renderer, option)
					}
				}

				mu.checkbox(&ui, "-5..5 reference lines", &draw_reference_lines)

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

		clear_buffers(&renderer)

		end_timed_section(.Clear)

		if draw_reference_lines {

			for x in -5 .. 5 {
				draw_line_world_space(
					&renderer,
					LineSegment3d{[3]f32{f32(x), 0, -5}, [3]f32{f32(x), 0, 5}},
					0xFF111111,
				)

				draw_line_world_space(
					&renderer,
					LineSegment3d{[3]f32{f32(x), -5, 0}, [3]f32{f32(x), 5, 0}},
					0xFF111111,
				)
			}

		}

		draw_mesh(&renderer, mesh_milk, texture_milk)
		draw_mesh(&renderer, mesh_wheel, texture_wheel)
		draw_mesh(&renderer, mesh_box, texture_box)
		draw_mesh(&renderer, mesh_sphere, texture_sphere)

		begin_timed_section(.UI)

		if !window.mouse_camera_control {

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
					draw_rect_px(
						&renderer,
						clip_to_px_buffer_rect(rect, renderer.pixels_dim),
						mu_color_to_u32(cmd.color),
					)

				case ^mu.Command_Icon:
					color := mu_color_to_u32(cmd.color)
					topleft := [2]f32{f32(cmd.rect.x), f32(cmd.rect.y)}
					bottomright := topleft + [2]f32{f32(cmd.rect.w), f32(cmd.rect.h)}

					empty := bottomright - (topleft + [2]f32{bf.GLYPH_WIDTH_PX, bf.GLYPH_HEIGHT_PX})
					topleft += empty * 0.5

					#partial switch cmd.id {

					case .CLOSE, .CHECK:
						draw_bitmap_glyph_px(&renderer, 'x', topleft, color)

					}

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
		last_frame_s = f32(time.duration_seconds(frame_work + frame_sleep))
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
