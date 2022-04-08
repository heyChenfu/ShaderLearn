using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
运动模糊, 通过计算像素速度
*/
[ExecuteInEditMode]
public class MotionBlurDepthTexture : MonoBehaviour
{
    public Material motionBlurMaterial = null;

    [Range(0.0f, 1.0f)] public float blurSize = 0.5f;

    private Camera m_camera;
    //上一帧的的视角*投影矩阵
    private Matrix4x4 previousViewProjectionMatrix;

    // Start is called before the first frame update
    void OnEnable()
    {
        m_camera = GetComponent<Camera>();
        if(m_camera)
            m_camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (motionBlurMaterial != null && m_camera != null)
        {
            motionBlurMaterial.SetFloat("_BlurSize", blurSize);

            motionBlurMaterial.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			Matrix4x4 currentViewProjectionMatrix = m_camera.projectionMatrix * m_camera.worldToCameraMatrix;
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			motionBlurMaterial.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit (src, dest, motionBlurMaterial);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

}
