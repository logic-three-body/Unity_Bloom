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
            buffer0.filterMode = FilterMode.Bilinear;//滤波模式为双线性滤波

            Graphics.Blit(src, buffer0, material, 0);//调用shader中第0个pass【程序中从0开始计数，其实就是第一个pass】
                                                     //提取图像较亮区域，将结果保存在buffer0

            for (int i = 0; i < iterations; i++)//高斯模糊操作
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

            material.SetTexture("_Bloom", buffer0);//将buffer0（渲染纹理）数据传给shader
            Graphics.Blit(src, dest, material, 3);// 调用pass3,将模糊结果与原图混合,并输出给dest最终结果

            //for debug
            // Graphics.Blit(buffer0,dest);

            RenderTexture.ReleaseTemporary(buffer0);//释放缓存
        }
        else
        {
            Graphics.Blit(src, dest);//其他异常情况直接输出原图
        }
    }
}
