Shader "Unlit/Chapter12/GaussianBlur"
{
    Properties
    {
		// _MainTex为渲染纹理，变量名固定不能改变
		// _BlurSize为模糊半径
        _MainTex ("Base(RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
    }
	SubShader {
		// 使用CGINCLUDE和ENDCG组织代码(类似头文件)
		// 在Pass中直接指定需要使用的顶点着色器和片元着色器函数名即可
		// 因为高斯模糊需要用到两个Pass，而且片元着色器完全一致
		// 所以使用CGINCLUDE可以避免重复写一样的代码
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		// 分别定义渲染纹理、纹素大小、模糊半径等变量
		// 其中_MainTex_TexelSize用来计算相邻像素的纹理坐标偏移量
		sampler2D _MainTex;  
		half4 _MainTex_TexelSize;
		float _BlurSize;
		
		// 定义顶点着色器的输出结构体
		struct v2f {
			float4 pos : SV_POSITION;
			// 由于卷积核大小为5x5的二维高斯核可以拆分两个大小为5的一维高斯核
			// 此处定义5维数组用来计算5个纹理坐标
			// uv[0]存储了当前的采样纹理，其他四个则为高斯模糊中对邻域采样时使用的纹理坐标
			half2 uv[5]: TEXCOORD0;
		};
		  
		// 在顶点着色器中计算高斯模糊在竖直方向上需要的纹理坐标
		v2f vertBlurVertical(appdata_img v) {
			// 将顶点从模型空间变换到裁剪空间下
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			// 在顶点着色器中计算纹理坐标可以减少运算提高性能
			// 而且由于顶点到片元的插值是线性的，因此不会影响纹理坐标的计算结果
			o.uv[0] = uv;
			// o.uv[1]到[4]分别对应(0, 1)、(0, -1)、(0, 2)、(0, -2)
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}

		// 在顶点着色器中计算高斯模糊在水平方向上需要的纹理坐标
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			// o.uv[1]到[4]分别对应(1, 0)、(-1, 0)、(2, 0)、(-2, 0)
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		// 在片元着色器中完成高斯模糊
		fixed4 fragBlur(v2f i) : SV_Target {
			// 因为二维高斯核具有可分离性，而分离得到的一维高斯核具有对称性
			// 所以只需要在数组存放三个高斯权重即可
			float weight[3] = {0.4026, 0.2442, 0.0545};
			// 结果值sum初始化为当前的像素值乘以它对应的权重值
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			// 根据对称性完成两次循环
			// 第一次循环计算第二个和第三个格子内的结果
			// 第二次循环计算第四个和第五个格子内的结果
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			// 返回滤波后的结果
			return fixed4(sum, 1.0);
		}
		    
		ENDCG
		
		// 开启深度测试，关闭剔除和深度写入
		ZTest Always Cull Off ZWrite Off
		
		// 第一个Pass用来进行竖直方向上的高斯模糊
		// 通过设置NAME，在后续实现Bloom效果的时候可以通过NAME直接使用该Pass，而无需重复写代码
		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"
			CGPROGRAM
			  
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		// 第二个Pass用来进行水平方向上的高斯模糊
		Pass {  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			CGPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}
	} 
	// 设置FallBack为Diffuse
	FallBack "Diffuse"
}
