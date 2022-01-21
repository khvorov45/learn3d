package learn3d

import "core:os"
import "core:fmt"

ModelImportOption :: enum {
	ConvertToLeftHanded,
	SwapZAndY,
}

read_mesh_and_texture :: proc(
	renderer: ^Renderer,
	name: string,
	translation: [3]f32,
	scale: f32 = 1,
	model_options: bit_set[ModelImportOption] = nil,
) -> (
	Mesh,
	Maybe(Texture),
) {

	mesh: Mesh
	mesh.scale = scale
	mesh.translation = translation

	mesh_contents, mesh_contents_ok := os.read_entire_file(
		fmt.tprintf("assets/{}.obj", name),
	)
	assert(mesh_contents_ok)

	mesh.vertices, mesh.normals, mesh.triangles = read_obj(
		mesh_contents,
		renderer.vertices[renderer.vertex_count:],
		renderer.normals[renderer.normal_count:],
		renderer.triangles[renderer.triangle_count:],
	)

	if .ConvertToLeftHanded in model_options {

		for vertex in &mesh.vertices {
			vertex.z *= -1
		}

		for normal in &mesh.normals {
			normal.z *= -1
		}

		for triangle in &mesh.triangles {
			ind := &triangle.indices
			tex := &triangle.texture
			norm := &triangle.normal_indices
			ind[1], ind[2] = ind[2], ind[1]
			tex[1], tex[2] = tex[2], tex[1]
			norm[1], norm[2] = norm[2], norm[1]
		}
	}

	if .SwapZAndY in model_options {
		for vertex in &mesh.vertices {
			vertex.y, vertex.z = -vertex.z, vertex.y
		}
		for normal in &mesh.normals {
			normal.y, normal.z = -normal.z, normal.y
		}
	}

	renderer.vertex_count += len(mesh.vertices)
	renderer.normal_count += len(mesh.normals)
	renderer.triangle_count += len(mesh.triangles)

	texture: Maybe(Texture)
	if texture_contents, ok := os.read_entire_file(fmt.tprintf("assets/{}.png", name)); ok {
		texture = read_image(texture_contents)
	}

	return mesh, texture
}
