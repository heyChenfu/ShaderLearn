using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public sealed class SobelFilerDepthOutlineRenderer : MonoBehaviour
{
    public Material _SobelOutlineMaterial;
    Material SobelOutlineMaterial
    {
        get
        {
            if (_SobelOutlineMaterial == null)
                _SobelOutlineMaterial = new Material(Shader.Find("Learn/SobelFilter"));
            return _SobelOutlineMaterial;
        }
    }

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (SobelOutlineMaterial != null)
        {
            //当你使用Blit函数时，Unity将source buffer的参数绑定到着色器的_MainTex属性上
            Graphics.Blit(sourceTexture, destTexture, SobelOutlineMaterial);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

}