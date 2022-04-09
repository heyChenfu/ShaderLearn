using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public sealed class EdgeDetectSobelFilerDepth : MonoBehaviour
{
    public Material _sobelOutlineMaterial;

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (_sobelOutlineMaterial != null)
        {
            //当你使用Blit函数时，Unity将source buffer的参数绑定到着色器的_MainTex属性上
            Graphics.Blit(sourceTexture, destTexture, _sobelOutlineMaterial);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

}