A software 3d renderer I made for learning purposes. Initially followed the course ["3D graphics programming from scratch"](https://courses.pikuma.com/courses/learn-computer-graphics-programming), eventually added some features (UI, timings, bilinear filtering, normal/color interpolation across triangles).

None of the code is optimized and it all runs very slowly.

The triangle filling routine `draw_triangle_px` may occasionally crash due to fetching outside the texture. I tried to follow the top-left fill rule and make the routine such that the interpolated texture coordinates can never be out of bounds, but I can't guarantee that I ran into (or thought of) all edge cases. I intentionally let it crash there because interpolated texture coordinates being out of bounds is an indicator of the triangle filling logic being wrong.
