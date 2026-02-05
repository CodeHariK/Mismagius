package main

import "core:fmt"
import "core:image/tga"
import "core:math"
import "core:math/linalg/glsl"
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

v2m :: proc(v: Vec3f) -> Vec4f {
	return Vec4f{v.x, v.y, v.z, 1.0}
}

m2v :: proc(m: Vec4f) -> Vec3f {
	if m.w <= 0.0001 {
		return Vec3f{math.INF_F32, math.INF_F32, math.INF_F32}
	}
	return Vec3f{m.x / m.w, m.y / m.w, m.z / m.w}
}

mul_mat4_vec4 :: proc(m: Mat4, v: Vec4f) -> Vec4f {
	return Vec4f {
		m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w,
		m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w,
		m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w,
		m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w,
	}
}

mul_mat4_mat4 :: proc(a, b: Mat4) -> Mat4 {
	result: Mat4

	for i := 0; i <= 3; i += 1 {
		for j := 0; j <= 3; j += 1 {
			sum: f32 = 0.0
			for k := 0; k <= 3; k += 1 {
				sum += a[i][k] * b[k][j]
			}
			result[i][j] = sum
		}
	}

	return result
}

/*

w/2    0     0    (x + (w/2))
0     h/2    0    (y + (h/2))
0      0    d/2    (d/2)
0      0     0       1

M * Vec{i,j,k,1}

*/
viewport :: proc(x, y, w, h, depth: f32) -> Mat4 {
	m := glsl.identity(Mat4)

	m[0][0] = w / 2.0
	m[1][1] = h / 2.0
	m[2][2] = depth / 2.0

	m[0][3] = x + w / 2.0
	m[1][3] = y + h / 2.0
	m[2][3] = depth / 2.0
	return m
}

lookat :: proc(eye, center, up: Vec3f) -> Mat4 {
	z := glsl.normalize_vec3(eye - center)
	x := glsl.normalize_vec3(glsl.cross_vec3(up, z))
	y := glsl.normalize_vec3(glsl.cross_vec3(z, x))

	res := glsl.identity(Mat4)

	for i := 0; i < 3; i += 1 {
		res[0][i] = x[i]
		res[1][i] = y[i]
		res[2][i] = z[i]
		res[i][3] = -center[i]
	}

	return res
}

projection :: proc(coeff: f32) -> Mat4 {
	m := glsl.identity(Mat4)
	m[3][2] = coeff // -1.0 / camera_z
	return m
}

world2screen :: proc(
	v: Vec3f,
	width, height: int,
	scale: Vec3f,
	offset: Vec3f,
	tanfov: f32,
	perspective: bool,
) -> Vec3f {

	px := v.x
	py := v.y
	z := v.z * scale.z + offset.z

	// if (perspective) {
	// 	aspect := f32(width) / f32(height)
	// 	if z == 0 {
	// 		z = 0.0001 // avoid division by zero
	// 	}
	// 	px = (v.x / (z * tanfov * aspect))
	// 	py = (v.y / (z * tanfov))
	// }

	return Vec3f {
		f32(int((px + 1.0) * f32(width) * scale.x / 2.0 + 0.5 + offset.x)),
		f32(int((py + 1.0) * f32(height) * scale.y / 2.0 + 0.5 + offset.y)),
		z,
	}
}

world2screen2 :: proc(v: Vec3f, MVP: Mat4) -> Vec3f {
	mv := v2m(v)
	sv := mul_mat4_vec4(MVP, mv)
	sc := m2v(sv)

	return sc
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
	perspective: bool,
) {
	width := f32(img.width)
	height := f32(img.height)

	tanfov := math.tan(f32(math.PI) / 3)

	fovy := f32(math.RAD_PER_DEG * 60.0) // vertical field of view in radians
	aspect := f32(img.width) / f32(img.height)
	znear := f32(1)
	zfar := f32(10.0)

	glslProjection := glsl.mat4Perspective(fovy, aspect, znear, zfar)

	depth := f32(255.0)

	eye := Vec3f{1, 1, 3}
	center := Vec3f{0, 0, 0}
	camera_z := glsl.length_vec3(eye - center)

	ModelView := lookat(eye, center, Vec3f{0, 1, 0})
	ViewPort := viewport(width / 8, height / 8, width * 3 / 4, height * 3 / 4, depth)
	Projection := projection(-1.0 / camera_z) // camera_z > 0

	MVP := mul_mat4_mat4(ViewPort, mul_mat4_mat4(Projection, ModelView))
	// MVP := ViewPort 
	// MVP := mul_mat4_mat4(ViewPort, Projection)

	fmt.printf("%v %v\n", width, height)
	printMatrix("ModelView", ModelView)
	printMatrix("Projection", Projection)
	printMatrix("ViewPort", ViewPort)
	printMatrix("PMV", mul_mat4_mat4(Projection, ModelView))
	printMatrix("MVP", MVP)

	for i in 0 ..< len(model.faces) {
		face := model.faces[i]
		screen_coords := [3]Vec3f{}

		for j in 0 ..< 3 {
			v := model.verts[face.verts[j]]

			if perspective {
				// screen_coords[j] = world2screen2(v, ViewPort, glslProjection)
				screen_coords[j] = world2screen2(v, MVP)
			} else {
				screen_coords[j] = world2screen(
					v,
					img.width,
					img.height,
					scale,
					offset,
					tanfov,
					perspective,
				)
			}
		}

		local0 := model.verts[face.verts[0]]
		local1 := model.verts[face.verts[1]]
		local2 := model.verts[face.verts[2]]

		uv0 := model.uvs[face.uvs[0]]
		uv1 := model.uvs[face.uvs[1]]
		uv2 := model.uvs[face.uvs[2]]

		intensity := f32(1)
		if (light_dir != nil) {
			normal := glsl.cross_vec3(local1 - local0, local2 - local0)
			normal = glsl.normalize(normal)

			intensity = glsl.dot(normal, light_dir^)
			if intensity < 0 {
				intensity = 0
			}
		}

		if intensity <= 0.00 {
			// fmt.println("Skipped")
			continue
		}

		uvs := &[3]Vec2f{uv0, uv1, uv2}
		if (filled) {
			if (zbuffer != nil) {
				drawTriangleFilled(zbuffer, img, texture, screen_coords, uvs, intensity, color)
				// neotriangle(zbuffer, img, texture, screen_coords, uvs, intensity, color)
			} else {
				drawTriangleFilled(nil, img, texture, screen_coords, uvs, intensity, color)
			}
		} else {
			drawTriangle(img, zbuffer, screen_coords, color^)
		}
	}
}

printMatrix :: proc(name: string, m: Mat4) {
	fmt.printf("%s : \n%v\n%v\n%v\n%v\n", name, m[0], m[1], m[2], m[3])
	// fmt.printf("%s : \n%v\n%v\n%v\n%v\n%v\n", name, m, m[0], m[1], m[2], m[3])
}
