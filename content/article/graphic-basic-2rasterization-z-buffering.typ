#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "Graphic Basic 2：Rasterization & Z-Buffering",
  desc: [本文是我关于图形学第二次作业（光栅化与深度缓冲）的一些随笔。],
  date: "2024-11-05",
  tags: (
    blog-tags.gamedev,
  ),
  show-outline: true,
)

本文是我关于图形学第二次作业（光栅化与深度缓冲）的一些随笔。


== Overview — 光栅化 Rasterization
在第一次作业中，我们通过MVP以及视口变换，对物体自身坐标进行了处理，得到了每个点在屏幕上的坐标。
以一个系统的视角，可以讲这个过程表述为：
local position → MVP&ViewPortTransformation→ screen space position
image here
#line()
但仅仅渲染点是不够的，我们需要的是渲染完整的模型。
> Rasterization，中译名为光栅化。这个词源自德语，其原意为“在屏幕上绘制”。 本文并不会深入讨论具体的成像原理，我们讨论的是一个更加基础而简单的问题：哪些点要被显示到屏幕上？   
我们这里对屏幕先做一些假设，或者说“抽象”：

	
+ 像素点是组成屏幕的基本单位，不可再分割
+ 屏幕是一个像素点的，大小为 screen width X screen height 的二维数组，每个屏幕上的像素点在数组中的位置成为其屏幕坐标(或者屏幕空间坐标) screen space position
+ 屏幕最左下角像素点坐标为 (0,0)，每个像素点的大小为 1 X 1
	
	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-1.png")
	


现在我们已经有了物体每个点的屏幕坐标，但也仅有这些点的屏幕坐标，这远远不够，我们需要一些方法计算得到另一些没有直接存储在模型中的点的屏幕坐标，已将这些点代表的线段或者三角形在屏幕上绘制出来。这就是所谓的 Rasterization。
这次作业我们实现两种经典的，也是最简单直观的三角形光栅化算法：
Bresenham直线光栅化算法与基于Edge-Function的三角形填充算法。

== 绘制直线 — Bresenham直线光栅化算法
首先来定义我们的问题：已知直线（线段）两个端点的坐标，求该直线（线段）上所有应被绘制的点的坐标。
```prolog
function line_rasterization {
	Input: two vectex (x1, y1), (x2, y2)
	Output: all vectex to be rasterized
}
```
这个问题其实不复杂，我们实际上就是要对函数 y-y1 = (x-x1) 在x1到x2之间以采样间隔为 1 的方式进行采样，采样得到的点就是我们应绘制的点的坐标。
当然，我们这里有个前提：所有点的坐标都是整数，而采样得到的点的纵坐标大多数都并非是整数，我们可以通过选取距离采样点最近的点进行绘制。
简单的用伪代码描述这个过程：
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-2.png")
```python
def line_rasterization((x1, y1), (x2, y2)):
	# Calculate the line: y = kx + b
	# Assume k <= 1 here, on case k > 1, we can simply exchange `x` and `y`
	k = (y1 - y2) / (x1 - x2)
	b = y1 - k * x1
	
	# Output
	rasterized_points = []
	
	# Sampling
	for x in range(x1, x2+1):
		y = k * x + b
		d_upper, d_lower = floor(y) + 1 - y, y - floor(y)
		if d_upper < d_lower:
			rasterized_points.append((x, floor(y) + 1))
		else:
			rasterized_points.append((x, floor(y)))
			
	return rasterized_points
```
看上去很简单，似乎这样就结束了，但还没有。
作为光栅化渲染过程的基础算法之一，对物体的每条线段都要调用，所以其效率是至关重要的。我们可以注意到上面的算法虽然简单，在逻辑上也很精简，但它涉及到了很多的浮点数运算。众所周知的，浮点运算相较于整数运算的速度慢很多，如果我们能避免浮点数运算，只使用整数运算，那么就可以大幅度的提高算法的执行速度，进而大幅优化渲染的效率。
Bresenham直线光栅化算法就是对上面这种最简单直白的算法的一种优化，其选择点的逻辑与上文算法相同，但（在经过严密的数学推导支撑下）精妙的避免了所有的浮点运算，将所有浮点预算都变为整数运算。
具体的数学推导网上有很多，这里我不再赘述，如 #link("https://www.cnblogs.com/heitao/p/8151487.html")[https://www.cnblogs.com/heitao/p/8151487.html]
在本次作业中，我们实现的 Bresenham直线光栅化算法如下:
```c++
	void TRShaderPipeline::rasterize_wire_aux(
		const VertexData &from, /// start point of the line	
		const VertexData &to,   /// end point of the line
		const unsigned int &screen_width,	/// width of the screen
		const unsigned int &screen_height,	/// height of the screen
		std::vector<VertexData> &rasterized_points	/// storage of the rasterized points
		)
	{
		// reference: 
		// http://yangwc.com/2019/05/01/SoftRenderer-Rasterization/
		auto dx = to.spos.x - from.spos.x;
		auto dy = to.spos.y - from.spos.y;
		int stepX = 1, stepY = 1;

		// judge the sign
		if (dx < 0) {
			stepX = -1;
			dx = -dx;
		}
		if (dy < 0) {
			stepY = -1;
			dy = -dy;
		}
	
		int d2x = dx << 1, d2y = dy << 1; // 2*dx, 2*dy
		int d2y_minus_d2x = d2y - d2x;
		int sx = from.spos.x, sy = from.spos.y;

		TRShaderPipeline::VertexData tmp;
		// slope < 1
		if (dy < dx) {
			int flag = d2y - dx;
			for (int i = 0; i <= dx; i++) {
				// linear interpolation
				tmp = VertexData::lerp(from, to, static_cast<double>(i) / dx);
				// rasterization
				// check if the point is in the screen
				if (tmp.spos.x >= 0 && tmp.spos.x <= screen_width &&
					tmp.spos.y >= 0 && tmp.spos.y <= screen_height
				) {
					rasterized_points.push_back(tmp);
				}
				
				sx += stepX;
				if (flag <= 0) {
					flag += d2y;
				} else {
					sy += stepY;
					flag += d2y_minus_d2x;
				}
			}
		} else {	// slope > 1
			int flag = d2x - dy;
			for (int i = 0; i <= dy; i++) {
				// linear interpolation
				tmp = VertexData::lerp(from, to, static_cast<double>(i) / dy);
				// rasterization
				// check if the point is in the screen
				if (tmp.spos.x >= 0 && tmp.spos.x <= screen_width &&
					tmp.spos.y >= 0 && tmp.spos.y <= screen_height
				) {
					rasterized_points.push_back(tmp);
				}
				
				sy += stepY;
				if (flag <= 0) {
					flag += d2x;
				} else {
					sx += stepX;
					flag -= d2y_minus_d2x;
				}				
			}
		}
	}
```
效果也很明显，我们的模型实现了 点→线 的进化。
#line()

	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-3.png")
		                                    Before
	
	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-4.png")
		                 After apply line rasteriztion
	


== 绘制三角形 — 基于Edge-Function的三角形填充算法
依然是先来定义我们的问题：已知三角形两个顶点的坐标，求该三角形内所有应被绘制的点的坐标。
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-5.png")
这个算法也很直接：遍历每个点，若其在三角形内，则绘制；否则不绘制。
那么我们需要遍历哪些点呢？当然不需要遍历整个屏幕。我们可以通过计算三角形顶点坐标的最大和最小值得到该三角形的“范围”（这里用英文比较直观：三角形的 Bound Box）,我们只需要遍历 Bound Box 内的点即可。用伪代码简单的描述如下：
```python
def rasterize_triangle(v0, v1, v2):
	min_x, max_x = min(v0.x, v1.x, v2.x), max(v0.x, v1.x, v2.x)
	min_y, max_y = min(v0.y, v1.y, v2.y), max(v0.y, v1.y, v2.y)
	
	rasterized_points = []
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if is_inside_triangle(x,y, v0, v1, v2):
				rasterized_points.append(x, y)
	
	return rasterized_points			
```
很直观的逻辑，一点都不绕，非常好算法。
接下来我们来讨论其中的一个细节：怎样判断一个点是否在三角形内部？
方法有很多，本次作业中我们使用的是重心坐标。这里我只把重心坐标当作一个抽象：
> 重心坐标 Barycentric  Coordinates                       Point(x, y)→ →  Barycentric;Coordinates (ɑ, β, γ)如果点 (x, y) 与三角形在同一平面内， 那么 ɑ + β + γ = 1；如果点 (x, y) 在三角形内，那么 ɑ ，β ，γ  都非负；
对于 Bound Box 内的每个点，我们计算其关于三角形的重心坐标，如果重心坐标的三个分量都大于等于零，我们就认为该点在三角形内，将其绘制。
在本次作业中，我们实现的三角形光栅化算法如下:
```c++
	void TRShaderPipeline::rasterize_fill_edge_function(
		const VertexData &v0,
		const VertexData &v1,
		const VertexData &v2,
		const unsigned int &screen_width,
		const unsigned int &screen_height,
		std::vector<VertexData> &rasterized_points)
	{
		int min_x = std::min({v0.spos.x, v1.spos.x, v2.spos.x});
		int max_x = std::max({v0.spos.x, v1.spos.x, v2.spos.x});
		int min_y = std::min({v0.spos.y, v1.spos.y, v2.spos.y});
		int max_y = std::max({v0.spos.y, v1.spos.y, v2.spos.y});

		auto isInsideScreen = [screen_width, screen_height](int x, int y) {
			return x >= 0 && x <= screen_width && y >= 0 && y <= screen_height;
		};

		for (auto i = min_x; i <= max_x; i++) {
			for (auto j = min_y; j <= max_y; j++) {
				auto w = barycentric(v0, v1, v2, i, j);
				if ((w.x >= 0 && w.y >= 0 && w.z >= 0)) {
					auto tmp = VertexData::barycentricLerp(v0, v1, v2, w);
					if (isInsideScreen(tmp.spos.x, tmp.spos.y)) {
						// 去除这两行则会有“漏点” Why？
						tmp.spos.x = i;	// set screen space position
						tmp.spos.y = j;	// 确保插值后获取的顶点坐标与屏幕坐标一致
						rasterized_points.push_back(tmp);
					}
				}
			}
		}
	}
	
	glm::vec3 barycentric(
		const TinyRenderer::TRShaderPipeline::VertexData &v0,
		const TinyRenderer::TRShaderPipeline::VertexData &v1,
		const TinyRenderer::TRShaderPipeline::VertexData &v2,
		const int x, const int y
	) {
		// reference:
		// https://zhuanlan.zhihu.com/p/65495373
		auto s1 = glm::vec3(v1.spos.x - v0.spos.x, v2.spos.x - v0.spos.x, v0.spos.x - x);
		auto s2 = glm::vec3(v1.spos.y - v0.spos.y, v2.spos.y - v0.spos.y, v0.spos.y - y);

		auto u = glm::cross(s1, s2);
		
		return glm::vec3(1.f - float(u.x + u.y) / u.z, float(u.x) / u.z, float(u.y) / u.z);
	}
```

== Z Buffering 深度缓冲
> 为了体现正确的三维前后遮挡关系，我们实现的帧缓冲包含了一个深度缓冲，用于存储当前场景中最近物体的深度值，前后的。三角形的三个顶点经过一系列变换之后，其 z 存储了深度信息，取值为[-1,1] ，越大则越远。经过光栅化的线性插值，每个片元都有一个深度值，存储在 cpos.z 中。在着色阶段，我们可以用当前片元的 cpos.z 与当前深度缓冲的深度值进行比较，如果发现深度缓冲的取值更小（即更近），则应该直接不进行着色器并写入到帧缓冲。
省流：对于每个像素，我们存储其上距离屏幕最近的点的颜色，我们将每个像素离屏幕最近的距离存放在二维数据 depthbuffer 中。当该像素位置上有更近的点是，我们就更新最近距离，以及像素的颜色。
作业中，我们的实现是：渲染时，如果该点的“深度”大于该位置的深度缓冲，就不进行渲染（跳过）。
```c++
		  void TRRenderer::renderAllDrawableMeshes(){	
				  // .....
				  
					//Fragment shader & Depth testing
					{
						for (auto &points : rasterized_points)
						{
							// 3: Implement depth testing here
							// Note: You should use m_backBuffer->readDepth() and points.spos to read the depth in buffer
							//       points.cpos.z is the depth of current fragment
							if (m_backBuffer->readDepth(points.spos.x, points.spos.y) <= points.cpos.z ) {
								continue;
							}
							{
								//Perspective correction after rasterization
								TRShaderPipeline::VertexData::aftPrespCorrection(points);
								glm::vec4 fragColor;
								m_shader_handler->fragmentShader(points, fragColor);
								m_backBuffer->writeColor(points.spos.x, points.spos.y, fragColor);
								m_backBuffer->writeDepth(points.spos.x, points.spos.y, points.cpos.z);
							}
						}
					}
					
					// .......
				}
```
#line()

	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-6.png")
		                                    Before
		
	
	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-7.png")
		    After apply triangle rasteriztion and  z-buffering             
	


== 抗锯齿

	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-8.png")
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-9.png")
		                      Before apply SSAA
	
	
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-10.png")
#image("../../public/images/graphic-basic-2rasterization-z-buffering/img-11.png")
		                          After apply SSAA
	

== 参考资料:
#link("http://yangwc.com/2019/05/01/SoftRenderer-Rasterization/")[http://yangwc.com/2019/05/01/SoftRenderer-Rasterization/]
#link("https://www.cnblogs.com/heitao/p/8151487.html")[https://www.cnblogs.com/heitao/p/8151487.html]
#link("https://zh.wikipedia.org/wiki/%E7%BA%BF%E6%80%A7%E6%8F%92%E5%80%BC")[https://zh.wikipedia.org/wiki/线性插值]
#link("https://zhuanlan.zhihu.com/p/65495373")[https://zhuanlan.zhihu.com/p/65495373]
#link("https://en.wikipedia.org/wiki/Z-buffering")[https://en.wikipedia.org/wiki/Z-buffering]
#link("https://www.cnblogs.com/shadow-lr/p/MSAASSAA.html")[https://www.cnblogs.com/shadow-lr/p/MSAASSAA.html]
