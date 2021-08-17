using UnityEngine;
using System.Collections;

// 本c#用于屏幕后处理效果的基类，在实现各种屏幕特效时，只需要继承自该基类
// 再实现派生类中不同的操作即可

// 编辑器下可执行该脚本来查看后处理效果 
[ExecuteInEditMode]
// 所有的屏幕后处理效果都需要绑定在某个摄像机上
[RequireComponent (typeof(Camera))]

public class PostEffectsBase : MonoBehaviour {

	// 提前检查各种资源和条件是否满足，在Start函数中会调用此函数
	protected void CheckResources() {
		bool isSupported = CheckSupport();
		if (isSupported == false) {
			NotSupported();
		}
	}

    // CheckResources函数会调用此函数来检查目前平台是否支持后处理效果
    // 如果支持返回true，不支持返回false
    protected bool CheckSupport() {
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}
		
		return true;
	}

    // 如果目前平台不支持后处理效果的话，CheckResources函数会调用此函数
    protected void NotSupported() {
		enabled = false;
	}

    // 一些屏幕特效可能需要更多的设置，如一些默认值等
    // 可以重载Start、CheckResources、CheckSupport等函数
    protected void Start() {
		CheckResources();
	}

    // 每个屏幕后处理效果都需要指定一个Shader来创建一个用于处理渲染纹理的材质
    // 此函数接受两个参数，第一个参数制定了该特效需要使用的Shader
    // 第二个参数是用于后期处理的材质
    // 首先检查Shader是否可用，可用后会返回使用该Shader的材质，否则返回null
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
		if (shader == null) {
			return null;
		}
		
		if (shader.isSupported && material && material.shader == shader)
			return material;
		
		if (!shader.isSupported) {
			return null;
		}
		else {
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else 
				return null;
		}
	}
}
