#import "/typ/templates/blog.typ": *

#show: main-zh.with(
  title: "Graphic Basic 1 : Viewing Transformation with Matrix Multiplation",
  desc: [本人关于 MVP 矩阵变换及视口矩阵的一些记录。这篇文章并不会包含详细的数学推导，只是一些随笔。],
  date: "2024-10-25",
  tags: (
    blog-tags.gamedev,
  ),
  show-outline: true,
)

本人关于 MVP 矩阵变换及视口矩阵的一些记录。这篇文章并不会包含详细的数学推导，只是一些随笔。

== 3D齐次坐标(3D Homogeneous Coordinates)
一般地，现代计算机使用 齐次坐标 来表示三维空间中点的位置。以下是齐次坐标下点的表示，与 缩放（Scale），平移（Transation），旋转（Rotation），切变（Shear）这几种基本的变换操作对应的变换矩阵。
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-1.png")

原坐标  times  变换矩阵 = 变换后的坐标

列矩阵 `[x, y, z, w]` 表示的点坐标为 `[x/w, y/w, z/w]`  
== Model Transformation
MVP变换中的M，将点放置到世界空间（World Space）中。从整个世界（World）来看，这一步变换的功能是改变物体自身的位置。
具体的做法是，我们根据需求计算出一个 Model Matrix，将它作为变换矩阵乘物体（的每个点的坐标）上，进而实现物体位置的改变。
举个例子，作业一中 Model Transformation 的代码如下:
```c++
		//Model transformation
		{
			// Init model matrix
			static glm::mat4 model_mat = glm::mat4(1.0f);

			// Apply Rotation
				model_mat = glm::rotate(model_mat, (float)deltaTime * 0.0001f, glm::vec3(0, 1, 0))
										* model_mat;
			// Apply Scale
				static bool isScalingUp = true;  
				static float scaleFactor = 1.0f; 
				if (scaleFactor > 3.0f) {
					isScalingUp = false;
				} else if (scaleFactor < 1.0f) {
					isScalingUp = true;
				}
				scaleFactor += (isScalingUp ? 1.0f : -1.0f) * (float)deltaTime * 0.0003f;
				glm::vec3 scaleVec(scaleFactor, scaleFactor, scaleFactor);
				model_mat = glm::scale(glm::mat4(1.0f), scaleVec) * model_mat;

			// Set model matrix
			renderer->setModelMatrix(model_mat);
		}

```
初始化 `modelmat` 为四维单位矩阵，然后根据需求乘上旋转，缩放与平移的变换矩阵，最终应用到渲染器 `renderer` 上，直接操作每个点的坐标。

== View Transformation (Camera Transformation)
MVP变换中的V，可以翻译为相机变换。
相机变换的功能是通过计算一个 Camera Matrix，将物体按照需求移动到我们的眼前。
接下来描述如何计算这个 Camera Matrix，首先我们需要描述一个 Camera。
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-2.png")
我们用三个参数描述相机：
	- 坐标 e，可以认为是一个点，代表相机的位置 
	- 向量 g，代表相机的朝向
	- 向量 t，上方向。或者说是相机自身的倾斜角(比如设置为y轴正方向就是竖屏拍摄，设置为x轴正方向就是横屏拍摄)

	
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-3.png")
		Set t as (0, 1, 0) in Camera Matrix
	
	
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-4.png")
		Set t as (1, 0, 0) in Camera Matrix
	

在 OpenGL 中，我们默认的相机位于原点，上方向为y轴正方向，朝向为z轴负方向。

作业一中关于 Projection Transformation 的代码如下
```c++
	renderer->setViewMatrix(TRRenderer::calcViewMatrix(cameraPos, lookAtTarget, glm::vec3(0.0, 1.0, 0.0f)));
```
== Projection Transformation

	现在物体已经被摆在了相机前，我们接下来要“按下快门”，就能得到一张屏幕上的图像了。

“按下快门“的第一步就是投影，投影分为正交投影与透视投影两种。投影的功能就是把3D的模型变成一张2D的图像。（省流：3D → 2D）
这里我不再赘述投影矩阵的具体实现，网上很多资料。
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-5.png")
	                                       投影：将三维的变成二维的
投影矩阵的功能就是将我们上一步得到的矩阵映射到 [-1, 1]^3 的立方体内（之后屏幕渲染时会将这个立方体”拍扁“成 [-1,1]^2的正方形，毕竟屏幕是二维的）

作业一中关于 Projection Transformation 的代码如下
```c++
	// Set projection matrix
	{
		renderer->setProjectMatrix(TRRenderer::calcPerspProjectMatrix(45.0f, static_cast<float>(width) / height, 0.1f, 10.0f));	// 注意这里 near < far, 可推断出整个程序使用的是左手系，“看向” z 正半轴
		// renderer->setProjectMatrix(TRRenderer::calcOrthoProjectMatrix(-2.0f, +2.0f, -2.0f, +2.0f, 0.1f, 10.0f));
	}
```
可以看到，这里仅仅是 Set 了一下。没有做实际的计算。

== Viewport Transformation
“按下快门“的第二步即是视口变换：我们将相机屏幕外的东西”扔掉“。
可以认为，这一步所有的操作都是二维的：
	前一步的投影环节把所有点（的坐标）放到了 z=1 平面上的 [-1,1]^2正方形中，我们现在要把这个正方形变成一个 W H 的矩形图像（就是屏幕的尺寸）。
	
作业一中，关于 Viewport Transformation 的代码在初始化 Renderer 时执行
```c++
	TRRenderer::TRRenderer(int width, int height)
		: m_backBuffer(nullptr), m_frontBuffer(nullptr)
	{
		//Double buffer to avoid flickering
		m_backBuffer = std::make_shared<TRFrameBuffer>(width, height);
		m_frontBuffer = std::make_shared<TRFrameBuffer>(width, height);

		//Setup viewport matrix (ndc space -> screen space)
		m_viewportMatrix = calcViewPortMatrix(width, height);
	}
```

== Conclusion: from 3D Space to 2D Screen Space
#image("../../public/images/graphic-basic-1-viewing-transformation-with-matrix-multiplation/img-6.png")

总的来说，从 local space(object space) 到 screen space ,一个点的坐标经过了如下的变换: (注意矩阵乘法，这里我们从右往左进行我们的变换)

Vscreen = Mviewport times  Mprojection times  Mcamera times  Mmodel times  Vlocal


好吧，好麻烦，我们要经过这么多的手续才能计算出一个点在屏幕上的坐标。
但我们终究是得到了想要的东西。
