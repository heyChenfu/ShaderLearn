using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 显示深度贴图
/// </summary>
[ExecuteInEditMode]
public class DepthTextureTest : MonoBehaviour
{
    private Material postEffectMat = null;
    private Camera currentCamera = null;

    void Awake()
    {
        currentCamera = GetComponent<Camera>();
    }

    void OnEnable()
    {
        if (postEffectMat == null)
            postEffectMat = new Material(Shader.Find("Learn/DepthTextureTest"));
        currentCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnDisable()
    {
        currentCamera.depthTextureMode &= ~DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (postEffectMat == null)
        {
            Graphics.Blit(source, destination);
        }
        else
        {
            Graphics.Blit(source, destination, postEffectMat);
        }
    }
}
