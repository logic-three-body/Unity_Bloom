# 4.1 Bloom

课程链接：[【技术美术百人计划】图形 4.1 Bloom算法 游戏中的辉光效果实现_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1a3411z7LC?p=2)

项目地址：[logic-three-body/Unity_Bloom: Unity Post procession about bloom (github.com)](https://github.com/logic-three-body/Unity_Bloom)

## 4.1.1 前置知识

### 什么是bloom

辉光效果，模拟摄像机图像效果。让舞台有真实明亮效果

![image-20210817114202656](https://i.loli.net/2021/08/17/wsSWulrIYaVEFUH.png)

bloom算法：

1.提取原图较量区域（阈值设定亮度）

2.模糊（提取后）图像

3.与**原图**混合

![image-20210817114350073](https://i.loli.net/2021/08/17/9WjgN1BI26Dd7Uq.png)

wiki部分总结：

该效果会在**高亮度物体周围**产生条纹或羽毛状的光芒，以**模糊图像细节**。如果物体**背光**，从第三人称观察，光线会表现得更加真实，并在某种程度上与遮挡物体产生交叠。

在现实世界中，透镜无法完美聚焦是高光的物理成因；理想透镜也会在成像时由于衍射而产生[**艾里斑**](https://zh.wikipedia.org/wiki/%E8%89%BE%E9%87%8C%E6%96%91)通常情况下难以察觉这些不完美的瑕疵，除非有强烈亮光源存在：这时，图像中的亮光部分会渗出其真实边界。

![440px-Elephants_Dream_-_Emo_and_Proog](https://i.loli.net/2021/08/17/dBcI9YPSHLZjRyD.jpg)

阅读链接：[here](https://zh.wikipedia.org/wiki/%E9%AB%98%E5%85%89)

### HDR

LDR（Low Dynamic Range,低动态范围） RGB range in [0,1]

JPG PNG等格式图片

![image-20210817115111650](https://i.loli.net/2021/08/17/MqumEFwB2iJcoNe.png)

HDR（High Dynamic Range,高动态范围） RGB range 可超过 [0,1]

这样可以提取更高亮度（超过1）的区域产生bloom效果

HDR、EXR格式图片

![image-20210817115235769](https://i.loli.net/2021/08/17/RikXV9pUQTnS3oB.png)

wiki部分总结：

现实中，当人由黑暗的地方走到光亮的地方，会眯起眼睛。人在黑暗的地方，为了看清楚对象，瞳孔会放大，以吸收更多光线；当突然走到光亮的地方，瞳孔来不及收缩，所以眯起眼睛，保护视网膜上的视神经。

而电脑无法判断光线明暗，唯有靠HDRR技术模拟这效果——**人眼自动适应光线变化**的能力。方法是快速将光线渲染得非常光亮，然后将亮度逐渐降低。而HDRR的最终效果是亮处的效果是鲜亮，而黑暗处的效果是能分辨物体的轮廓和深度，而不是以往的一团黑。

HDRR技术的使用场景举例如下：

例一场景： 阳光普照下，水旁有一道墙壁。当阳光由水面反射到墙上，晴朗而明亮的天空会稍微暗一些，这样能有助表现出水面的反光效果。当人们低头看水面，阳光会反射到人眼中，整个画面会非常光亮，并逐渐减弱，因为人眼适应了从水面反射的光。

例二场景： 阳光直射到一块光亮的石头。若你紧盯着它，石头表面的泛光会逐渐淡出，显示出更多细节。

例三场景： 枪支的反射效果。

阅读链接：[here](https://zh.wikipedia.org/wiki/%E9%AB%98%E5%8A%A8%E6%80%81%E5%85%89%E7%85%A7%E6%B8%B2%E6%9F%93)

推荐阅读：[Bloom是什么 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/76505536) ：本文部分从生物（光子）角度阐述

### 卷积

数学运算如下：

（请注意Kernel卷积核在**运算时**实际已经水平旋转180度，比如第一行第二列的“2”两侧的1实际已经颠倒位置，但因为值一样所以没有表现出来，PS：如果仅从获得运算结果的角度下，可以暂时理解为一种步骤）

![image-20210817121348952](https://i.loli.net/2021/08/17/ht7ZJU1IPcpHof4.png)

动图演示：

![fire0](https://i.loli.net/2021/08/17/vWP92lXru1RDHKA.gif)

再来一张加深理解：

![卷饼王挺好吃的](https://i.loli.net/2021/08/17/e4Q3No7yGtCSBju.gif)

辅助阅读：[卷积究竟卷了啥？——17分钟了解什么是卷积_哔哩哔哩_bilibili](https://www.bilibili.com/video/av713651125)

[什么！卷积要旋转180度？！ - 简书 (jianshu.com)](https://www.jianshu.com/p/8dfe02b61686) 

减少图像噪声、降低细节层次的方法。

![image-20210817145408045](https://i.loli.net/2021/08/17/eV3JAd8E5Yn7OXW.png)

高斯核

![image-20210817145620293](https://i.loli.net/2021/08/17/9zvfi3I6Nw4Suh1.png)

二维高斯函数特点：可分离性，将二维高斯函数拆成两个一维高斯函数以降低计算量

二维高斯核运算：N * N * W * H 次纹理采样

两次一维高斯核运算：2 * N * W * H 次纹理采样

![image-20210817150211423](https://i.loli.net/2021/08/17/2NVy37hzUoSiXJl.png)

《unity shader入门精要》对应页数：P253-254

## 4.1.2 算法演示

C#脚本部分（详情请见注释，结合老师的注释加了些总结，建议配合视频或《入门精要》P259-260阅读）

```c#
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BloomTest : PostEffectsBase
{
    public Shader bloomShader;//bloom test shader 需要用cs脚本给shader传数据
    private Material bloomMaterial = null;
    public Material material
    {
        get
        {
                    //《入门精要》P245-246 //检查shader可用性，通过后返回使用该shader的材质，否则为null
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    /* 《入门精要》P259-262 */

    [Range(0, 4)]
    public int iterations = 3;//高斯模糊迭代次数，数值越大越模糊
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;//高斯模糊范围，数值越大越模糊
    [Range(1, 8)]
    public int downSample = 2;//降采样系数，控制渲染纹理的大小（render texture）,
                              //数值越大，渲染纹理越小，处理模糊像素越少，但过大可能使图像像素化（渲染纹理太小）
    [Range(0.0f, 4.0f)]//由于开启HDR，亮度范围可以超过1.0f
    public float luminanceThreshold = 0.6f;//亮度阈值范围

    //获取当前渲染图像（渲染纹理）     source原图         dest目标图像即模糊后图像
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(material != null)//检查材质是否可用
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);//向材质传入亮度阈值
            int rtW = src.width / downSample;//渲染纹理宽
            int rtH = src.height / downSample;//渲染纹理高

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;//滤波（模糊）模式为双线性滤波

            Graphics.Blit(src, buffer0, material, 0);//调用shader中第0个pass【程序中从0开始计数，其实就是第一个pass】
                                                     //提取图像较亮区域，将结果保存在buffer0

            for(int i=0; i < iterations; i++)//高斯模糊操作
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);//高斯模糊范围
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);//调用pass1,垂直方向高斯模糊，渲染结果存入buffer1

                RenderTexture.ReleaseTemporary(buffer0);//释放缓存,模糊后结果存入buffer1
                buffer0 = buffer1;//buffer1结果存入(覆盖)buffer0
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);//重新分配buffer1
                Graphics.Blit(buffer0, buffer1, material, 2);//调用pass2,水平方向高斯模糊，渲染结果存入buffer1

                RenderTexture.ReleaseTemporary(buffer0);//释放缓存,模糊后结果存入buffer1
                buffer0 = buffer1;//重新分配buffer1

                /*
                 * 每次模糊使用结果为上次模糊的结果
                 */
            }
            
            //for debug
            // Graphics.Blit(buffer0,dest);//将高斯模糊循环注释，取消本行注释，可以观察pass0效果即截取亮度
            
            material.SetTexture("_Bloom", buffer0);//将buffer0（渲染纹理）数据传给shader
            Graphics.Blit(src, dest, material, 3);// 调用pass3,将模糊结果与原图混合,并输出给dest最终结果
            RenderTexture.ReleaseTemporary(buffer0);//释放缓存
        }
        else
        {
            Graphics.Blit(src, dest);//其他异常情况直接输出原图
        }
    }
}

```

shader部分（详情请见注释，建议配合视频或《入门精要》阅读P261-262阅读）：

```glsl
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

```

bloom shader挂到材质上是这样，但是我们并不将它挂到具体材质，而是利用脚本生成材质并给材质传递数据（所用的纹理是渲染纹理，是渲染管线生成的也不是具体的纹理图片）

![image-20210817165155299](https://i.loli.net/2021/08/17/riCT2sVOyfRGM6q.png)

downsample：

![fire1](https://i.loli.net/2021/08/17/6Q7OCqEybTtgl53.gif)

pass 0 threshold截取阈值：

![fire0](https://static01.imgkr.com/temp/23d2ae1bb024416a88c743bd8d6f1a86.gif)

pass0+pass1+pass2+pass3(仅输出处理后Bloom)

![example](https://static01.imgkr.com/temp/9490ad4dd513442d852fc3f5b871d3d8.gif)

pass0+pass1+pass2+pass3(仅输出处理后Bloom+原图)

![example](https://static01.imgkr.com/temp/2cca283cea514fe68ec67af10bfd7bae.gif)

## 4.1.3 Demo演示

### bloom mask

思路：利用alpha值（0或1）来选取bloom的区域

在原shader的基础上，增加这个mask函数，并修改pass 3即最终叠加图像的片元着色器：

```glsl
		//src为原图颜色 color为叠加后颜色        
		//for bloom mask
        fixed4 mask(fixed4 src,fixed4 color)
        {
            return lerp(src,color,1.0-src.a);
        }

		fixed4 fragBloom(v2fBloom i) : SV_Target {
            //return tex2D(_Bloom, i.uv.zw);//for debug 仅输出处理后图像
            fixed4 orgin_img = tex2D(_MainTex, i.uv.xy); 
            fixed4 blur_img = tex2D(_Bloom, i.uv.zw);
            fixed4 result=orgin_img+blur_img;
			return mask(orgin_img,result);//原图与模糊图叠加
		} 
```

lerp(a,b,w) 根据w返回a到b之间的插值相当于 fixed4 lerp(fixed4 a, fixed4 b, fixed4 w) { return a + w*(b-a); } 由此可见 当 w=0时返回a.当w = 1时 返回b.

即渲染纹理中，alpha=1的部分将输出原图像，而alpha=0的部分将输出叠加后的bloom图像

下图为测试场景（红胶囊alpha=1，蓝胶囊alpha=0）

![fire3](https://i.loli.net/2021/08/17/C2rZuMwKgnSp9vR.gif)

下图为一幅图片，设置alpha蒙版，用笔刷将天空部分alpha修改至半透明

![image-20210818113010685](https://i.loli.net/2021/08/18/d4ycUIoSKphnvNJ.png)

无mask bloom（整体均受bloom效果影响）：

![image-20210817223159179](https://i.loli.net/2021/08/17/7qH98ZhUWfJ6yFO.png)

针对半透明部分，设置一个1-alpha的阈值（这里设为1e-1即0.1），具体请见下方

```glsl
       //src为原图颜色 color为叠加后颜色
	   fixed4 mask_chose1(fixed4 src,fixed4 color)//alpha=1时bloon有效
        {
            if(1e-1>1.0-src.a)
            {                
                return color;  
            }
            else
            {
                return src;
                         
            }
        }

        fixed4 mask_chose0(fixed4 src,fixed4 color)//alpha<1.0时bloom有效
        {
            if(1e-1>1.0-src.a)
            {                
                return src;  
            }
            else
            {
                return color;
                         
            }
        }

		fixed4 fragBloom(v2fBloom i) : SV_Target {
            //return tex2D(_Bloom, i.uv.zw);//for debug 仅输出处理后图像
            fixed4 orgin_img = tex2D(_MainTex, i.uv.xy); 
            fixed4 blur_img = tex2D(_Bloom, i.uv.zw);
            fixed4 result=orgin_img+blur_img;
            //return result;
			//return mask(orgin_img,result);//原图与模糊图叠加 lerp
			return mask_chose1(orgin_img,result);//原图与模糊图叠加 带alpha阈值判断
			//return mask_chose0(orgin_img,result);//原图与模糊图叠加 带alpha阈值判断
		} 
```

使用mask_chose0，让半透明部分bloom

![fire2](https://i.loli.net/2021/08/18/4zYMRB9qIwQ3pa1.gif)

使用mask_chose1,让不透明部分bloom

![fire1](https://i.loli.net/2021/08/18/2OCfeRLrUpSGPWu.gif)

（项目中的路径：[Assets/Packages/MaskBloom/Demo](https://github.com/logic-three-body/Unity_Bloom/tree/master/Assets/Packages/MaskBloom/Demo)）

参考：[mattatz/unity-mask-bloom: Mask by alpha channel bloom effect for Unity. (github.com)](https://github.com/mattatz/unity-mask-bloom)

[Unity3D Shader 之 lerp 函 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/73487722)

### Gold Ray

![image-20210818161352870](https://i.loli.net/2021/08/18/7dVmRAbEajUh9uS.png)

算法步骤：

1.提取原图较量区域（阈值设定亮度）

2.模糊（提取后）图像【**径向模糊** ： 模拟光线往某方向的扩散效果】

3.与**原图**混合

演示：

调节Light Transform 改变散射光线方向

<video src=".\Vedio\lighttransform.webm"></video>

其他参数的调节

<video src=".\Vedio\others.webm"></video>

cs部分：

```c#
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GodRay : PostEffectsBase
{
    // 声明GodRay效果需要的Shader，并创建相应的材质
    public Shader godRayShader;
    private Material godRayMaterial = null;
    public Material material
    {
        get
        {
            // 调用PostEffectsBase基类中检查Shader和创建材质的函数
            godRayMaterial = CheckShaderAndCreateMaterial(godRayShader, godRayMaterial);
            return godRayMaterial;
        }
    }

    // 高亮部分提取阈值
    public Color colorThreshold = Color.gray;
    // 光颜色
    public Color lightColor = Color.white;
    // 光强度
    [Range(0.0f, 20.0f)]
    public float lightFactor = 0.5f;
    // 径向模糊uv采样偏移值
    [Range(0.0f, 10.0f)]
    public float samplerScale = 1;
    // 迭代次数
    [Range(1, 5)]
    public int blurIteration = 2;
    // 分辨率缩放系数
    [Range(1, 5)]
    public int downSample = 1;
    // 光源位置
    public Transform lightTransform;
    // 光源范围
    [Range(0.0f, 5.0f)]
    public float lightRadius = 2.0f;
    // 提取高亮结果Pow系数，用于适当降低颜色过亮的情况
    [Range(1.0f, 4.0f)]
    public float lightPowFactor = 3.0f;

    private Camera targetCamera = null;

    void Awake()
    {
        targetCamera = GetComponent<Camera>();
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material && targetCamera)
        {
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            // 创建一块大小小于原屏幕分辨率的缓冲区buffer0
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0, src.format);

            //计算光源位置从世界空间转化到视口空间
            Vector3 viewPortLightPos = lightTransform == null ? new Vector3(.5f, .5f, 0) : targetCamera.WorldToViewportPoint(lightTransform.position);

            // 参数传给材质
            material.SetVector("_ColorThreshold", colorThreshold);
            material.SetVector("_ViewPortLightPos", new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
            material.SetFloat("_LightRadius", lightRadius);
            material.SetFloat("_PowFactor", lightPowFactor);
            // 根据阈值提取高亮部分,使用pass0进行高亮提取，比Bloom多一步计算光源距离剔除光源范围外的部分
            Graphics.Blit(src, buffer0, material, 0);

            material.SetVector("_ViewPortLightPos", new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
            material.SetFloat("_LightRadius", lightRadius);
            // 径向模糊的采样uv偏移值
            float samplerOffset = samplerScale / src.width;
            // 通过循环迭代径向模糊
            for (int i = 0; i < blurIteration; i++)
            {
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, src.format);
                float offset = samplerOffset * (i * 2 + 1);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(buffer0, buffer1, material, 1);

                offset = samplerOffset * (i * 2 + 2);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(buffer1, buffer0, material, 1);
                RenderTexture.ReleaseTemporary(buffer1);
            }

            material.SetTexture("_BlurTex", buffer0);
            material.SetVector("_LightColor", lightColor);
            material.SetFloat("_LightFactor", lightFactor);
            // 将径向模糊结果与原图进行混合
            Graphics.Blit(src, dest, material, 2);
            RenderTexture.ReleaseTemporary(buffer0);
        } else {
            Graphics.Blit(src, dest);
        }
    }

}

```

shader部分：

```glsl
Shader "Unlit/GodRay"
{
    Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
	}
 
	CGINCLUDE
	#define RADIAL_SAMPLE_COUNT 6
	#include "UnityCG.cginc"
	
	// 提取亮部图像
	struct v2fExtractBright
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
 
	// 径向模糊
	struct v2fRadialBlur
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 blurOffset : TEXCOORD1;
	};
 
	// 混合
	struct v2fGodRay
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};
 
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	float4 _BlurTex_TexelSize;
	float4 _ViewPortLightPos;
	
	float4 _offsets;
	float4 _ColorThreshold;
	float4 _LightColor;
	float _LightFactor;
	float _PowFactor;
	float _LightRadius;
 
	// 提取亮部图像VS
	v2fExtractBright vertExtractBright(appdata_img v)
	{
		v2fExtractBright o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		// 平台差异化处理
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
		#endif	
		return o;
	}
 
	// 提取亮部图像PS
	fixed4 fragExtractBright(v2fExtractBright i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv);
		float distFromLight = length(_ViewPortLightPos.xy - i.uv);
		float distanceControl = saturate(_LightRadius - distFromLight);
		// 仅当color大于设置的阈值的时候才输出
		float4 thresholdColor = saturate(color - _ColorThreshold) * distanceControl;
		float luminanceColor = Luminance(thresholdColor.rgb);
		luminanceColor = pow(luminanceColor, _PowFactor);
		return fixed4(luminanceColor, luminanceColor, luminanceColor, 1);
	}
 
	// 径向模糊VS
	v2fRadialBlur vertRadialBlur(appdata_img v)
	{
		v2fRadialBlur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		// 径向模糊采样偏移值*沿光的方向权重
		o.blurOffset = _offsets * (_ViewPortLightPos.xy - o.uv);
		return o;
	}
 
	// 径向模拟PS
	fixed4 fragRadialBlur(v2fRadialBlur i) : SV_Target
	{
		half4 color = half4(0,0,0,0);
		for(int j = 0; j < RADIAL_SAMPLE_COUNT; j++)   
		{	
			color += tex2D(_MainTex, i.uv.xy);
			i.uv.xy += i.blurOffset; 	
		}
		return color / RADIAL_SAMPLE_COUNT;
	}
 
	// 混合VS
	v2fGodRay vertGodRay(appdata_img v)
	{
		v2fGodRay o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
		#endif	
		return o;
	}

 	// 混合PS
	fixed4 fragGodRay(v2fGodRay i) : SV_Target
	{
		fixed4 ori = tex2D(_MainTex, i.uv1);
		fixed4 blur = tex2D(_BlurTex, i.uv);
		return ori + _LightFactor * blur * _LightColor;
	}
 
	ENDCG
 
	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		// 提取高亮部分
		Pass
		{
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			ENDCG
		}
 
		// 径向模糊
		Pass
		{
			CGPROGRAM
			#pragma vertex vertRadialBlur
			#pragma fragment fragRadialBlur
			ENDCG
		}
 
		// 将亮部图像与原图进行混合得到最终的GodRay效果
		Pass
		{
			CGPROGRAM
			#pragma vertex vertGodRay
			#pragma fragment fragGodRay
			ENDCG
		}
	}
}

```

其他

待补充...