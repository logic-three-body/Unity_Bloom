Shader "Unlit/BloomTest"
{
    Properties
    {
        //属性名要与C#脚本传递数据时用的属性名一样
        _MainTex ("Base(RGB)", 2D) = "white" {}//原图，src渲染纹理
        _Bloom ("Bloom(RGB)", 2D) = "black" {}//Bloom，模糊后的渲染纹理，会和原图（_MainTex）叠加
        _LuminanceThreshold ("Luminance Threshold", Float) = 0.5//模糊的亮度阈值
        _BlurSize ("Blur Size", Float) = 1.0//模糊范围
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

		struct v2fExtractBright {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};	
         
		v2fExtractBright vertExtractBright(appdata_img v) {//提取较亮区域顶点着色器
			v2fExtractBright o;
			o.pos = UnityObjectToClipPos(v.vertex);//坐标变换
			o.uv = v.texcoord;	 //纹理坐标获取
			return o;
		}

        fixed luminance(fixed4 color){//亮度计算函数，rgb -> Brightness
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        fixed4 fragExtractBright(v2fExtractBright i) : SV_TARGET0 {//提取较亮区域片元着色器
            fixed4 c = tex2D(_MainTex, i.uv);//原图纹理采样
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);//截取通过阈值的亮度

            return c * val;//原图与截取结果的乘积得到图像亮区（没通过的亮度都变0了，那原图中相应区域的像素×0=0）
        }

		struct v2fBlur {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;//5x5 二维高斯核（最终会拆成两个一维5元素高斯核）
		};

        v2fBlur vertBlurVertical(appdata_img v){
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;
            //由于是垂直运算，所以是y方向
            o.uv[0] = uv;//（0，0）
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;//(0,1) 向上
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;//(0,-1)向下
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;//(0,2) 向上
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;//(0,-2) 向下
            
            return o;
        }

        v2fBlur vertBlurHorizontal(appdata_img v){
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            //由于是水平运算，所以是x方向
            half2 uv = v.texcoord;
            o.uv[0] = uv;//（0，0）
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;//(1,0) 向右
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;//(-1,0) 向左
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;//(2,0) 向右
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;//(-2,0) 向左

            return o;
        }

		fixed4 fragBlur(v2fBlur i) : SV_Target {
            float weight[3] = {0.4026, 0.2442, 0.0545};//一维高斯函数的对称性{0.0545,0.0242,0.4026, 0.2442, 0.0545}
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];//存储模糊后像素值

            //卷积运算
            /*
            第一次循环：uv[1]*weight[1]  uv[2]*weight[1]
            第二次循环：uv[3]*weight[2]  uv[4]*weight[2]
            */
            for(int it = 1; it < 3; it++){
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
            }

            return fixed4(sum, 1.0);
        }

		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};

		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;
			o.pos = UnityObjectToClipPos (v.vertex);


            /*
            两个纹理坐标，储存在half4变量uv 
            xy分量：_MainTex 纹理
            zw分量：_Bloom 纹理
            */
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0)//平台差异处理，详见《入门精要》P115 5.6.1 
                o.uv.w = 1.0 - o.uv.w;
            #endif

            return o;
        }

		fixed4 fragBloom(v2fBloom i) : SV_Target {
            //return tex2D(_Bloom, i.uv.zw);//for debug 仅输出处理后图像
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);//原图与模糊图叠加
		} 

        ENDCG

        ZTest Always Cull Off ZWrite Off//定义用于屏幕后处理的相关渲染状态：开启深度测试（Always）关闭剔除 关闭深度写入
        Pass { //Pass 0 : 提取较亮区域
            CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
            ENDCG
        }

        Pass {//Pass 1 : 垂直方向高斯模糊
            CGPROGRAM
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
            ENDCG
        }

        Pass {//Pass 2 : 水平方向高斯模糊
            CGPROGRAM
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
            ENDCG
        }

        Pass {//Pass 3 : 原图和bloom图混合（叠加）
            CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom
            ENDCG
        }
    }
}
