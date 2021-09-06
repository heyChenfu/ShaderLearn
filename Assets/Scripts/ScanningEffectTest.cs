using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScanningEffectTest : MonoBehaviour
{
    private Material postEffectMat = null;
    private Camera currentCamera = null;

    private float fScanValue = 0;

    // Start is called before the first frame update
    void Awake()
    {
        currentCamera = GetComponent<Camera>();
    }

    private void Update()
    {
    }

    void OnEnable()
    {
        if (postEffectMat == null)
            postEffectMat = new Material(Shader.Find("Learn/ScanningEffect"));
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
