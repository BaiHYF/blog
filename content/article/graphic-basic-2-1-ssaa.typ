#import "/typ/templates/blog.typ": *

#show: main-zh.with(
  title: "Graphic Basic 2 (1) : SSAA",
  desc: [续],
  date: "2024-11-07",
  tags: (
    blog-tags.gamedev,
  ),
  show-outline: true,
)

续  
== 锯齿 Aliasing

	
		本质上，在光栅化阶段中，用有限离散的数据想表示连续的（类似三角形的某一边），就可能存在采样点不够的问题，也就引申出了锯齿（ Aliasing）的这个概念。从信号采样定理的角度来看，锯齿产生的本质原因是由于采样频率不足，导致无法完整的重构（reconstruct）原信号。
		我们这里讨论的抗锯齿（Anti Aliasing）并不是指的完全消除锯齿，而是通过各种手段减少锯齿，使得图像的质量能符合我们的需求。
#line()
== 超采样抗锯齿 Super Sampling Anti Aliasing (SSAA)
		既然锯齿产生的原因是采样频率不足，那么我们最朴素的减少锯齿的方法自然就是增加采样频率。这就是超采样抗锯齿(SSAA)的基本思想。接下来我以 2x2 超采样为例进行说明。
		先来分析我们最基本的三角形渲染过程，如前文提及的那样，我们将一个像素视为屏幕的最小单位，每次将一个像素视作一个整体进行分析，这本质上就是对每个像素进行了一次采样。
		```python
def rasterize_triangle(...):
	'''Rasterize the triangle with single sampling'''
	# ...
	for x in range(minx, maxx):
		for y in range(miny, maxy):
			point = (x+0.5, y+0.5) # center point of the pixel
			if is_inside_triange(point):
				# ...
				set_pixel_color(x, y, color)
				rasterized_points.append((x, y))
		```
		在2x2超采样中，我们将一个像素点视为由2x2个子像素点组成，分别对这4个子像素进行采样操作，计算是否在三角形内，计算其重心插值等等。这本质上就相当于提高了屏幕的分辨率，图像自然就会更清晰。
		!#link("https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/ec49a5dd-5c40-439f-b870-99bfb9789837/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB4664H66FG5E%2F20260723%2Fus-west-2%2Fs3%2Faws4request&X-Amz-Date=20260723T120032Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjECQaCXVzLXdlc3QtMiJIMEYCIQCdU3%2FQEiK%2BIH76kdIIOiAOlF7pJfETH%2Bf5leI1jGs5SgIhAM9Nr%2BPsudcPzkz3xDBNEm0eW5%2BH1v6I2rmk2FyFwF4oKogECO3%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEQABoMNjM3NDIzMTgzODA1IgzG9YCQnXa6KwidoU4q3AOKlZfni2KRh0Yk9ufxyWuqXgUDRZjA6hgpvEWcZbXFmxrT%2BBXIQJJObv7FD7Uvtx%2Fu0tJTtnJ6kf0J%2FiR31sZN70UUOhj7YekvE1qMadegGsWk%2Fp2Qoaz40tlStYsen0SLNPIrMj%2B5Uie2EXSYSTb%2B2XMQanIPbNbUzPo4L5sgr%2BJ1BU3pdrfXQ5m6fW8a4iRacnWdr%2FEAQl95%2FTfxRgGt4ZQnhaybwFiNfX4Qzg4kOJkYc0ZpnuuXoaeBuRbFpCn%2Bb5VidOTLXNPx8JWFCU9f98XbQ3PFkwxHdqK2jkqYtQSNefOB%2BLS5bEciyD905iaJXEZ7o6Htc378Nm9sSMp4WS2jYpGpiB43cCZarWvhmtbylfkzM%2FzM7xLaejZzf1%2BqcWUvdaWpKfBeDUOzAPimPA7YDuPqkfgnzqTOo%2BV0YqhVnp%2FABTypAbmRv%2FcNAgrMaX%2BpP%2BkQEiMSQJGyMR5AOlHVo9bQe6EO4vTFn0fj4XGoxfBJxxTyVvscZesjlm4neUJcKRZ%2B1aqzx8ZBy62AKz9uR1Jk0HffuXvlCNRybJpg1Q90c9zcDUT%2F6xiJfLgXvNExfg4EYXNS2aHrHpHQIvCrEZFH45aB3lh0pL5LNxq6a9Qjgt7ukz%2BhQDCN%2B4fTBjqkAemi8WsvILDvyuavCw2ruOgt4HyJE1FIHSrjjxDY6L6ab%2FPaOSshP%2Fk%2F60B3mrsppLsXL7waG%2BHDrtRsP7JKa%2Bq47MTc3IkW41Jag4SUxLsFKgGAhFxGhC%2FxNQdzeArr69tVEL9gKj9vvXrJW8GuF2h8825RmcPGxYdHLD5Y%2B%2BfPDRxfPnhi6v7w%2BBH0S3L6ZWe%2FVkKHLSOYUYEIQgVb3yCGNo2%2B&X-Amz-Signature=bcdf2ca34e60d80593029a7b58103d142c47e144e67317bce9fea78475a96853&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject")[                                   将一个像素采样2x2次]
		但实际上我们屏幕的分辨率并没有改变，我们在最终绘制的时候，一个像素点也只有一个颜色（而不是4个）。这里SSAA的做法是将一个像素点的属性视为其4个子像素对应属性的平均值。以颜色为例，若一个像素中，有两个子像素在三角形内，两个子像素在三角形外，且我们将三角形内子像素的颜色设置为 color，三角形外子像素的颜色设置为 0，那么最终该像素的颜色就是 (color + color + 0+0) / 4= =50%color。这种对多个子像素属性值进行处理，得到原像素属性的过程也被称为降采样（down sampling）
#image("../../public/images/graphic-basic-2-1-ssaa/img-1.png")
	
	
		> 采样定理（Sampling Theorem），也称为奈奎斯特-香农采样定理（Nyquist-Shannon sampling theorem），是信号处理领域的一个基本原理。它指出，要想从采样信号中完整地重建原始连续时间信号，采样频率必须至少是信号最高频率的两倍。
			
	

这里我尝试用伪代码描述其中的逻辑，（只是二维的情况，且没有考虑深度缓冲等其他属性）
```python
def rasterize_triangle_ssaa(...):
	'''Rasterize the triangle with 2x2 super sampling'''
	# ...
	for x in range(minx, maxx):
		for y in range(miny, maxy):
			pixel_color = (0, 0, 0)
			# super sampling -- center of 4 sub pixels
			for (subx, suby) in [(x+0.25, y+0.25), (x+0.75, y+0.25), (x+0.25, y+0.75), (x+0.75, y+0.75)]:
				if is_inside_triangle(subx, suby):
					pixel_color += color
			
			# down sampling
			pixel_color /= 4
			set_pixel_color(x, y, pixel_color)
```
#line()

实践中，及本次作业的提升任务（单采样）代码如下。在上文伪代码的基础上增加了三维空间下重心插值的计算与深度缓冲的处理
```c++
//Screen space rasterization
void rst::rasterizer::rasterize_triangle(const Triangle& t) {
    auto v = t.toVector4();
    
    // Bounding Box
    auto min_x = static_cast<int>(std::floor(std::min({t.v[0].x(), t.v[1].x(), t.v[2].x()})));
    auto max_x = static_cast<int>(std::ceil(std::max({t.v[0].x(), t.v[1].x(), t.v[2].x()})));
    auto min_y = static_cast<int>(std::floor(std::min({t.v[0].y(), t.v[1].y(), t.v[2].y()})));
    auto max_y = static_cast<int>(std::ceil(std::max({t.v[0].y(), t.v[1].y(), t.v[2].y()})));

    auto color = t.getColor();

		// Helper variables
    float inv_w0 = 1.0f / v[0].w();
    float inv_w1 = 1.0f / v[1].w();
    float inv_w2 = 1.0f / v[2].w();
    float z0 = v[0].z() * inv_w0;
    float z1 = v[1].z() * inv_w1;
    float z2 = v[2].z() * inv_w2;

    for (int x = min_x; x <= max_x; x++) {
        for (int y = min_y; y <= max_y; y++) {
            // center of the pixel
            float px = x + 0.5;
            float py = y + 0.5;
            if (insideTriangle(px, py, t.v)) {
                // If the point is inside the triangle, get the interpolated z value
                auto [alpha, beta, gamma] = computeBarycentric2D(px, py, t.v);
                float w_reciprocal = 1.0f / (alpha * inv_w0 + beta * inv_w1 + gamma * inv_w2);
                float z_interpolated = (alpha * z0 + beta * z1 + gamma * z2) * w_reciprocal;

                int index = get_index(x, y);
                if (z_interpolated <= depth_buf[index]) {
                    // set depth buffer
                    set_pixel(Vector3f(x, y, z_interpolated), color);
                    depth_buf[index] = z_interpolated;
                }
            }
        }
    }
}

```
#line()
应用了2x2SSAA抗锯齿的光栅化代码如下。此处在处理像素颜色时，我直接选择 `pcolor += color / 4.f` ，这样颜色值就不用最后再除以4了。
```c++
//Screen space rasterization
void rst::rasterizer::rasterize_triangle(const Triangle& t) {
    auto v = t.toVector4();

		// Bounding Box
    auto min_x = static_cast<int>(std::floor(std::min({t.v[0].x(), t.v[1].x(), t.v[2].x()})));
    auto max_x = static_cast<int>(std::ceil(std::max({t.v[0].x(), t.v[1].x(), t.v[2].x()})));
    auto min_y = static_cast<int>(std::floor(std::min({t.v[0].y(), t.v[1].y(), t.v[2].y()})));
    auto max_y = static_cast<int>(std::ceil(std::max({t.v[0].y(), t.v[1].y(), t.v[2].y()})));

    auto color = t.getColor();

		// Helper variables
    float inv_w0 = 1.0f / v[0].w();
    float inv_w1 = 1.0f / v[1].w();
    float inv_w2 = 1.0f / v[2].w();
    float z0 = v[0].z() * inv_w0;
    float z1 = v[1].z() * inv_w1;
    float z2 = v[2].z() * inv_w2;

    for (int x = min_x; x <= max_x; x++) {
        for (int y = min_y; y <= max_y; y++) {
            // 2x2 SSAA
            const int ss_sz = 2; // super sampling size
            int in_sample_count = 0;
            float z_interpolated = INTMAX_MAX;
            Vector3f pcolor = Vector3f(0.0f, 0.0f, 0.0f);
            for (int i = 0; i < ss_sz; i++) {
                for (int j = 0; j < ss_sz; j++){
                    // super sample point
                    float subx = x + (i + 0.5f) / ss_sz;
                    float suby = y + (j + 0.5f) / ss_sz;

                    if (insideTriangle(subx, suby, t.v)) {
                        in_sample_count++;
                        auto [alpha, beta, gamma] = computeBarycentric2D(subx, suby, t.v);
                        float w_reciprocal = 1.0f / (alpha * inv_w0 + beta * inv_w1 + gamma * inv_w2);
                        float sample_z_interpolated = (alpha * z0 + beta * z1 + gamma * z2) * w_reciprocal;

                        int sux = x * ss_sz + i;
                        int suy = y * ss_sz + j;
                        int su_index = get_super_index(sux, suy);
                        if (sample_z_interpolated <= depth_buf_sample_list[su_index]) {
                            depth_buf_sample_list[su_index] = sample_z_interpolated;
                        }
                        z_interpolated = std::min(z_interpolated, sample_z_interpolated);
                        pcolor += color / 4.f;
                    }
                    
                }
            }
            
            if (z_interpolated < depth_buf[get_index(x, y)]) {
                depth_buf[get_index(x, y)] = z_interpolated;
                frame_buf[get_index(x, y)] = pcolor;
            }
        }
    }
}
```
注意在处理像素的深度缓冲时，我的处理方法时另使用一个 `depthbufsamplelist` 存储并处理每个子像素的深度，并使用4个子像素深度的最小值（而不是平均值）来作为父像素的深度值。关于 `depthbufsamplelist` 的定义与初始化代码如下：
```c++
class rasterizer {
		private:
				// ...
				std::vector<float> depth_buf_sample_list;
				// ...
}

// ...

void rst::rasterizer::clear(rst::Buffers buff)
{
		// ...
    if ((buff & rst::Buffers::Depth) == rst::Buffers::Depth)
    {
        std::fill(depth_buf.begin(), depth_buf.end(), std::numeric_limits<float>::infinity());
        std::fill(depth_buf_sample_list.begin(), depth_buf_sample_list.end(), std::numeric_limits<float>::infinity());
    }
}

// ...

rst::rasterizer::rasterizer(int w, int h) : width(w), height(h)
{
		// ...
    depth_buf_sample_list.resize(w * h * 4);
}

```

最终效果如下

	
#image("../../public/images/graphic-basic-2-1-ssaa/img-2.png")
#image("../../public/images/graphic-basic-2-1-ssaa/img-3.png")
		                      Before apply SSAA
		锯齿稍微减缓了一点点。
	
	
#image("../../public/images/graphic-basic-2-1-ssaa/img-4.png")
#image("../../public/images/graphic-basic-2-1-ssaa/img-5.png")
		                          After apply SSAA
	

== 参考资料:
#link("https://www.cnblogs.com/shadow-lr/p/MSAASSAA.html")[https://www.cnblogs.com/shadow-lr/p/MSAASSAA.html]
