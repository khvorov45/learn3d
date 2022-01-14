package learn3d

import "core:time"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:math/linalg"

import mu "vendor:microui"

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

	target_framerate := 30
	target_frame_ns := 1.0 / f64(target_framerate) * f64(time.Second)
	target_frame_duration := time.Duration(target_frame_ns)

	input: Input

	ui: mu.Context
	mu.init(&ui)
	ui.text_width = mu.default_atlas_text_width
	ui.text_height = mu.default_atlas_text_height

	for window.is_running {

		time_frame_start := time.now()

		//
		// SECTION Input
		//

		clear_half_transitions(&input)
		poll_input(&window, &input)

		//
		// SECTION Update
		//

		if input.keys[KeyID.AltR].ended_down && was_pressed(input, .Enter) {
			toggle_fullscreen(&window)
		}

		speed: f32 = 0.02
		mouse_sensitivity: f32 = 0.01
		if input.keys[KeyID.Shift].ended_down {
			speed *= 5
		}

		// NOTE(sen) Rotate camera input
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

		// NOTE(sen) Move camera input
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

		mu.begin(&ui)
		mu.begin_window(&ui, "Test window", mu.Rect{0, 0, 100, 100})
		mu.end_window(&ui)
		mu.end(&ui)

		//
		// SECTION Render
		//

		clear(&renderer)

		draw_mesh(&renderer, mesh_f22, texture_f22)
		draw_mesh(&renderer, mesh_f117, texture_f117)

		if !window.camera_control {

			ui_cmd: ^mu.Command = nil
			for mu.next_command(&ui, &ui_cmd) {

				switch cmd in ui_cmd.variant {

				case ^mu.Command_Text:

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

		display_pixels(&window, renderer.pixels, renderer.pixels_dim)

		//
		// SECTION Frame time
		//

		work_done_duration := time.since(time_frame_start)
		to_sleep_duration := target_frame_duration - work_done_duration
		if to_sleep_duration > 0 {
			time.sleep(to_sleep_duration)
		}

	}

}

mu_color_to_u32 :: proc(col: mu.Color) -> u32 {
	col := col
	result := (cast(^u32)&col)^
	return result
}
