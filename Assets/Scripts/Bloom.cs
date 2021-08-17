using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase
{
    // 声明Bloom效果需要的Shader，并创建相应的材质
    public Shader bloomShader;
    private Material bloomMaterial = null;
    public Material material
    {
        get
        {
            // 调用PostEffectsBase基类中检查Shader和创建材质的函数
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    // 因为Bloom效果是建立在高斯模糊的基础上完成的
    // 所以增加luminanceThreshold变量来控制并提取图像较亮区域时所使用的阈值
    // 高斯模糊迭代次数，次数越多越模糊
    [Range(0, 4)]
    public int iterations = 3;
    // 高斯模糊范围，范围越大越模糊
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    // 缩放系数
    [Range(1, 8)]
    public int downSample = 2;
    // 阈值，与HDR有关
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    // 调用OnRenderImage函数实现Bloom效果
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // 先检查材质是否可用，如果可用，则将参数传递给材质后
        // 再调用Graphics.Blit进行处理，否则不作处理
        if (material != null)
        {
            // 先将阈值传给材质
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            // src.width和src.height分别为屏幕图像的宽度与高度
            // 除以下采样得到的rtW和rtH分别为渲染纹理的宽度和高度
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;

            // 创建一块大小小于原屏幕分辨率的缓冲区buffer0
            // 设置该临时渲染纹理的滤波模式为双线性
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            // 调用Shader中第一个Pass来提取图像中较亮的区域
            // 结果存储在buffer0并输出
            Graphics.Blit(src, buffer0, material, 0);

            // 通过循环迭代高斯模糊
            for (int i = 0; i < iterations; i++)
            {
                // 将模糊半径传入Shader
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                // 定义第二个缓存buffer1
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                // 通过Blit调用Shader中第二个Pass完成竖直方向上的高斯模糊
                Graphics.Blit(buffer0, buffer1, material, 1);
                // 接着释放buffer0，把结果重新赋给buffer0，并重新分配一次buffer1
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 执行第三个Pass，完成水平方向上的高斯模糊
                Graphics.Blit(buffer0, buffer1, material, 2);
                // 接着释放buffer0，把结果重新赋给buffer0
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            // 将完成高斯模糊后的结果buffer0传递给材质中的_Bloom纹理属性
            // 再次调用Graphics.Blit使用第四个Pass完成混合，dest作为最终结果输出
            // 最后释放临时缓存
            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(src, dest, material, 3);
            RenderTexture.ReleaseTemporary(buffer0);
        } else {
            Graphics.Blit(src, dest);
        }
    }
}
