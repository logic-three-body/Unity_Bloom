Shader "Unlit/Bloom"
{
    Properties
    {
		// _MainTex为渲染纹理，变量名固定不能改变
		// 其他三个属性分别为高斯模糊后较亮的区域、阈值、模糊半径
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
		CGINCLUDE
		#include "UnityCG.cginc"
		// 声明代码中需要使用的变量
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;

		// 提取较亮区域所使用顶点着色器输出结构体
		struct v2fExtractBright {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};	

		// 提取较亮区域所使用的顶点着色器函数
		v2fExtractBright vertExtractBright(appdata_img v) {
			v2fExtractBright o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;	 
			return o;
		}

		// 通过明亮度公式计算得到像素的亮度值
		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}

		// 提取较亮区域所使用的片元着色器函数
		fixed4 fragExtractBright(v2fExtractBright i) : SV_Target {
			// 贴图采样
			fixed4 c = tex2D(_MainTex, i.uv);
			// 调用luminance得到采样后像素的亮度值，再减去阈值
			// 并使用clamp函数将结果截取在[0,1]范围内
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			// 将val与原贴图采样得到的像素值相乘，得到提取后的亮部区域
			return c * val;
		}

		// 定义顶点着色器的输出结构体
		struct v2fBlur {
			float4 pos : SV_POSITION;
			// 由于卷积核大小为5x5的二维高斯核可以拆分两个大小为5的一维高斯核
			// 此处定义5维数组用来计算5个纹理坐标
			// uv[0]存储了当前的采样纹理，其他四个则为高斯模糊中对邻域采样时使用的纹理坐标
			half2 uv[5]: TEXCOORD0;
		};

		// 在顶点着色器中计算高斯模糊在竖直方向上需要的纹理坐标
		v2fBlur vertBlurVertical(appdata_img v) {
			// 将顶点从模型空间变换到裁剪空间下
			v2fBlur o;
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
		v2fBlur vertBlurHorizontal(appdata_img v) {
			v2fBlur o;
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
		fixed4 fragBlur(v2fBlur i) : SV_Target {
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


		// 混合亮部图像所使用顶点着色器输出结构体
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};

		// 混合亮部图像所使用的顶点着色器函数
		v2fBloom vertBloom(appdata_img v) {
			// 顶点变换
			v2fBloom o;
			o.pos = UnityObjectToClipPos (v.vertex);
			// xy分量为_MainTex的纹理坐标，zw分量为_Bloom的纹理坐标
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			// 平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
			return o; 
		}
		
		// 混合亮部图像所使用的片元着色器函数
		fixed4 fragBloom(v2fBloom i) : SV_Target {
		    // 把这两张纹理的采样结果相加即可得到最终效果
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		} 

		ENDCG

		// 开启深度测试，关闭剔除和深度写入
		ZTest Always Cull Off ZWrite Off

		// 第一个Pass，用来提取图像中较亮的区域
		Pass {
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			ENDCG
		}
		// 第二个Pass，实现竖直方向上的高斯模糊
		Pass {
			CGPROGRAM
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			ENDCG  
		}
		// 第三个Pass，实现水平方向上的高斯模糊
		Pass {  
			CGPROGRAM  
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			ENDCG
		}
		// 第四个Pass，将亮部图像与原图进行混合得到最终的Bloom效果
		Pass {
			CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom
			ENDCG
		}
	}
	FallBack Off
}
