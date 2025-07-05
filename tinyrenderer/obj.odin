package main

import "core:fmt"
import "core:image/tga"
import "core:math"
import "core:math/linalg/glsl"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"

Face :: struct {
	verts:   [3]int,
	uvs:     [3]int,
	normals: [3]int,
}

Model :: struct {
	verts: [dynamic]Vec3f,
	uvs:   [dynamic]Vec2f,
	faces: [dynamic]Face,
}

load_model :: proc(filename: string) -> Model {
	verts: [dynamic]Vec3f
	uvs: [dynamic]Vec2f
	faces: [dynamic]Face

	data, ok := os.read_entire_file(filename)

	if !ok {
		fmt.println("Failed to open file")
		return Model{}
	}
	lines := strings.split(string(data), "\n")
	for line in lines {
		if strings.has_prefix(line, "v ") {
			parts := strings.fields(line)
			if len(parts) >= 4 {
				x, _ := strconv.parse_f32(parts[1])
				y, _ := strconv.parse_f32(parts[2])
				z, _ := strconv.parse_f32(parts[3])
				v := Vec3f{x, y, z}
				append(&verts, v)
			}
		} else if strings.has_prefix(line, "vt ") {
			parts := strings.fields(line)
			if len(parts) >= 3 {
				u, _ := strconv.parse_f32(parts[1])
				v, _ := strconv.parse_f32(parts[2])
				append(&uvs, Vec2f{u, v})
			}
		} else if strings.has_prefix(line, "f ") {
			parts := strings.fields(line)
			if len(parts) >= 4 {
				face_verts: [3]int
				face_uv: [3]int
				face_normals: [3]int
				for i in 0 ..< 3 {
					face := strings.split(parts[i + 1], "/")
					v_idx, _ := strconv.parse_int(face[0])
					vt_idx, _ := strconv.parse_int(face[1])
					vn_idx, _ := strconv.parse_int(face[2])
					face_verts[i] = v_idx - 1
					face_uv[i] = vt_idx - 1
					face_normals[i] = vn_idx - 1
				}
				append(&faces, Face{face_verts, face_uv, face_normals})
			}
		}
	}
	fmt.printf("# v# %d f# %d vt# %d\n", len(verts), len(faces), len(uvs))
	return Model{verts, uvs, faces}
}

world2screen :: proc(v: Vec3f, width, height: int, scale: Vec3f, offset: Vec3f) -> Vec3f {
	return Vec3f {
		f32(int((v.x + 1.0) * f32(width) * scale.x / 2.0 + 0.5 + offset.x)),
		f32(int((v.y + 1.0) * f32(height) * scale.y / 2.0 + 0.5 + offset.y)),
		v.z,
	}
}

renderModel :: proc(
	using model: Model,
	img: ^tga.Image,
	texture: ^tga.Image,
	zbuffer: ^[dynamic]f32,
	filled: bool,
	light_dir: ^Vec3f,
	scale: Vec3f,
	offset: Vec3f,
	color: ^Color,
) {
	for i in 0 ..< len(model.faces) {
		face := model.faces[i]
		pts := [3]Vec3f{}
		for j in 0 ..< 3 {
			pts[j] = world2screen(model.verts[face.verts[j]], img.width, img.height, scale, offset)
		}

		local0 := model.verts[face.verts[0]]
		local1 := model.verts[face.verts[1]]
		local2 := model.verts[face.verts[2]]

		uv0 := model.uvs[face.uvs[0]]
		uv1 := model.uvs[face.uvs[1]]
		uv2 := model.uvs[face.uvs[2]]

		intensity := f32(1)
		if (light_dir != nil) {
			// Compute face normal (cross product of two edges)
			edge1 := Vec3f{local1.x - local0.x, local1.y - local0.y, local1.z - local0.z}
			edge2 := Vec3f{local2.x - local0.x, local2.y - local0.y, local2.z - local0.z}
			normal := glsl.cross_vec3(edge1, edge2)
			normal = glsl.normalize(normal)

			intensity = glsl.dot(normal, light_dir^)
			if intensity < 0 {
				intensity = 0
			}
		}

		// Choose color: use provided or random, then scale by intensity
		c := Color{0, 0, 0}
		if color != nil {
			c = color^
		} else {
			c = Color{u8(rand.int63_max(255)), u8(rand.int63_max(255)), u8(rand.int63_max(255))}
		}

		if (filled) {
			if (zbuffer != nil) {
				drawTriangleFilled(
					pts,
					zbuffer,
					img,
					texture,
					&[3]Vec2f{uv0, uv1, uv2},
					intensity,
					c,
				)
			} else {
				drawTriangleFilled(pts, nil, img, texture, &[3]Vec2f{uv0, uv1, uv2}, intensity, c)
			}
		} else {
			drawTriangle(img, zbuffer, pts, c)
		}
	}
}
