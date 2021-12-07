using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RawShadowmapDepth : MonoBehaviour
{
    public Light m_Light;
    RenderTexture m_ShadowmapCopy;

    void Start()
    {
        CommandBuffer cb = new CommandBuffer();

        // Change shadow sampling mode for m_Light's shadowmap.
        cb.SetShadowSamplingMode(BuiltinRenderTextureType.CurrentActive, ShadowSamplingMode.RawDepth);

        // The shadowmap values can now be sampled normally - copy it to a different render texture.
        RenderTargetIdentifier rtID = new RenderTargetIdentifier(m_ShadowmapCopy);
        cb.Blit(BuiltinRenderTextureType.CurrentActive, rtID);

        // Execute after the shadowmap has been filled.
        m_Light.AddCommandBuffer(LightEvent.AfterShadowMap, cb);

        // Sampling mode is restored automatically after this command buffer completes, so shadows will render normally.
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(m_ShadowmapCopy, dest);
    }
}
