using UnityEngine;

[ExecuteInEditMode]
public class EdgeDetectRobertsNormalsAndDepth : MonoBehaviour
{
    public Material _robertsOutlineMaterial;

    void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (_robertsOutlineMaterial != null)
        {
            Graphics.Blit(sourceTexture, destTexture, _robertsOutlineMaterial);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

}
