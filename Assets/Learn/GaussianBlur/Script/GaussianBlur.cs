using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GaussianBlur : MonoBehaviour
{
    public Material _gaussianBlurMaterial;
    public int downSample = 1;
    [Range(0, 4)]
    public int blurTimes = 3;
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (_gaussianBlurMaterial != null)
        {
            //降低分辨率像素
            int rtW = sourceTexture.width / downSample;
            int rtH = sourceTexture.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            
            Graphics.Blit(sourceTexture, buffer0, _gaussianBlurMaterial, 0);
            for (int i = 0; i < blurTimes; i++)
            {
                _gaussianBlurMaterial.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // Render the vertical pass
                Graphics.Blit(buffer0, buffer1, _gaussianBlurMaterial, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // Render the horizontal pass
                Graphics.Blit(buffer0, buffer1, _gaussianBlurMaterial, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            Graphics.Blit(buffer0, destTexture, _gaussianBlurMaterial, 1);

            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

}
