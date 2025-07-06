#include <chrono>
#include <iomanip>
#include <iostream>
#include <vector>
#include <cmath>
#include <limits>
#include "tgaimage.h"
#include "model.h"
#include "geometry.h"

const int width = 800;
const int height = 800;
const int depth = 255;

Model *model = NULL;
int *zbuffer = NULL;
Vec3f light_dir(0, 0, -1);
Vec3f camera(0, 0, 3);

Vec3f m2v(Matrix m)
{
    return Vec3f(m[0][0] / m[3][0], m[1][0] / m[3][0], m[2][0] / m[3][0]);
}

Matrix v2m(Vec3f v)
{
    Matrix m(4, 1);
    m[0][0] = v.x;
    m[1][0] = v.y;
    m[2][0] = v.z;
    m[3][0] = 1.f;
    return m;
}

void print_vec3(const char *label, const Vec3f &v)
{
    std::cout << label << ""
              << std::setprecision(8) << int(v.x / 10) * 10 << ", "
              << std::setprecision(8) << int(v.y / 10) * 10 << ", "
              << std::setprecision(8) << int(v.z / 10) * 10 << std::endl;
}

void print_vec4(const char *label, const Matrix &m)
{
    std::cout << label << ": ["
              << std::setprecision(8) << m[0][0] << ", "
              << std::setprecision(8) << m[1][0] << ", "
              << std::setprecision(8) << m[2][0] << ", "
              << std::setprecision(8) << m[3][0] << "]" << std::endl;
}

void print_matrix(const char *label, const Matrix &m)
{
    std::cout << label << ": [" << std::endl;
    for (int i = 0; i < m.nrows(); ++i)
    {
        std::cout << "  ";
        for (int j = 0; j < m.ncols(); ++j)
        {
            std::cout << std::setprecision(8) << m[i][j];
            if (j < m.ncols() - 1)
                std::cout << ", ";
        }
        std::cout << std::endl;
    }
    std::cout << "]" << std::endl;
}

Matrix viewport(int x, int y, int w, int h)
{
    Matrix m = Matrix::identity(4);
    m[0][3] = x + w / 2.f;
    m[1][3] = y + h / 2.f;
    m[2][3] = depth / 2.f;

    m[0][0] = w / 2.f;
    m[1][1] = h / 2.f;
    m[2][2] = depth / 2.f;
    return m;
}

int tcount = 0;
void triangle(Vec3i t0, Vec3i t1, Vec3i t2, Vec2i uv0, Vec2i uv1, Vec2i uv2, TGAImage &image, float intensity, int *zbuffer)
{
    tcount += 1;

    if (t0.y == t1.y && t0.y == t2.y)
        return; // i dont care about degenerate triangles
    if (t0.y > t1.y)
    {
        std::swap(t0, t1);
        std::swap(uv0, uv1);
    }
    if (t0.y > t2.y)
    {
        std::swap(t0, t2);
        std::swap(uv0, uv2);
    }
    if (t1.y > t2.y)
    {
        std::swap(t1, t2);
        std::swap(uv1, uv2);
    }

    int total_height = t2.y - t0.y;
    for (int i = 0; i < total_height; i++)
    {
        bool second_half = i > t1.y - t0.y || t1.y == t0.y;
        int segment_height = second_half ? t2.y - t1.y : t1.y - t0.y;
        float alpha = (float)i / total_height;
        float beta = (float)(i - (second_half ? t1.y - t0.y : 0)) / segment_height; // be careful: with above conditions no division by zero here
        Vec3i A = t0 + Vec3f(t2 - t0) * alpha;
        Vec3i B = second_half ? t1 + Vec3f(t2 - t1) * beta : t0 + Vec3f(t1 - t0) * beta;
        Vec2i uvA = uv0 + (uv2 - uv0) * alpha;
        Vec2i uvB = second_half ? uv1 + (uv2 - uv1) * beta : uv0 + (uv1 - uv0) * beta;
        if (A.x > B.x)
        {
            std::swap(A, B);
            std::swap(uvA, uvB);
        }
        for (int j = A.x; j <= B.x; j++)
        {
            float phi = B.x == A.x ? 1. : (float)(j - A.x) / (float)(B.x - A.x);
            Vec3i P = Vec3f(A) + Vec3f(B - A) * phi;
            Vec2i uvP = uvA + (uvB - uvA) * phi;
            int idx = P.x + P.y * width;
            if (zbuffer[idx] < P.z)
            {
                zbuffer[idx] = P.z;
                TGAColor color = model->diffuse(uvP);
                image.set(P.x, P.y, TGAColor(color.r * intensity, color.g * intensity, color.b * intensity));

                // std::cout << tcount << " " << P.x << " " << P.y << " "
                //           << int(color.r) << ", "
                //           << int(color.g) << ", "
                //           << int(color.b) << ", " << intensity << std::endl;
            }
        }
    }
}

int main(int argc, char **argv)
{
    auto start = std::chrono::high_resolution_clock::now();

    if (2 == argc)
    {
        model = new Model(argv[1]);
    }
    else
    {
        model = new Model("../assets/diablo3_pose.obj");
    }

    zbuffer = new int[width * height];
    for (int i = 0; i < width * height; i++)
    {
        zbuffer[i] = std::numeric_limits<int>::min();
    }

    { // draw the model
        Matrix Projection = Matrix::identity(4);
        Matrix ViewPort = viewport(width / 8, height / 8, width * 3 / 4, height * 3 / 4);
        Projection[3][2] = -1.f / camera.z;

        print_matrix("Projection", Projection);
        print_matrix("ViewPort", ViewPort);

        TGAImage image(width, height, TGAImage::RGB);

        std::cout << model->nfaces() << " " << width << " " << height << std::endl;

        for (int i = 0; i < model->nfaces(); i++)
        {
            std::vector<int> face = model->face(i);
            Vec3i screen_coords[3];
            Vec3f world_coords[3];
            for (int j = 0; j < 3; j++)
            {
                Vec3f v = model->vert(face[j]);
                Matrix mv = v2m(v);
                Matrix pv = Projection * mv;
                Matrix sv = ViewPort * pv;
                Vec3i sc = m2v(sv);
                screen_coords[j] = sc;

                // print_vec3("v", v);
                // print_vec4("mv", mv);
                // print_vec4("pv", pv);
                // print_vec4("sv", sv);
                // print_vec3("screen_coords: ", sc);

                world_coords[j] = v;
            }
            Vec3f n = (world_coords[2] - world_coords[0]) ^ (world_coords[1] - world_coords[0]);
            n.normalize();
            float intensity = n * light_dir;
            if (intensity > 0)
            {
                Vec2i uv[3];
                for (int k = 0; k < 3; k++)
                {
                    uv[k] = model->uv(i, k);
                }
                triangle(screen_coords[0], screen_coords[1], screen_coords[2], uv[0], uv[1], uv[2], image, intensity, zbuffer);
            }
        }

        image.flip_vertically(); // i want to have the origin at the left bottom corner of the image
        image.write_tga_file("output.tga");
    }

    { // dump z-buffer (debugging purposes only)
        TGAImage zbimage(width, height, TGAImage::GRAYSCALE);
        for (int i = 0; i < width; i++)
        {
            for (int j = 0; j < height; j++)
            {
                zbimage.set(i, j, TGAColor(zbuffer[i + j * width], 1));
            }
        }
        zbimage.flip_vertically(); // i want to have the origin at the left bottom corner of the image
        zbimage.write_tga_file("zbuffer.tga");
    }
    delete model;
    delete[] zbuffer;

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    std::cout << "Main execution time: " << elapsed.count() << " seconds" << std::endl;
    return 0;
}
