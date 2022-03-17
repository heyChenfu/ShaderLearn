using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
运动模糊的后处理实现方法
*/
[ExecuteInEditMode]
public class MotionBlur : MonoBehaviour
{
    public Material motionBlurMaterial = null;
    private RenderTexture accumulationTexture;

    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    void OnDisable()
    {
        DestroyImmediate(accumulationTexture);
    }

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (motionBlurMaterial != null)
            {
                // Create the accumulation texture
                if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
                {
                    DestroyImmediate(accumulationTexture);
                    accumulationTexture = new RenderTexture(src.width, src.height, 0);
                    accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                    Graphics.Blit(src, accumulationTexture);
                }

                //恢复操作, 表示渲染到该纹理, 但是该纹理未被清空的情况
                accumulationTexture.MarkRestoreExpected();

                motionBlurMaterial.SetFloat("_BlurAmount", blurAmount);

                Graphics.Blit(src, accumulationTexture, motionBlurMaterial);
                Graphics.Blit(accumulationTexture, dest);
            }
            else
            {
                Graphics.Blit(src, dest);
            }

        }

}
