using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class FogWithNoise : MonoBehaviour
{

	public Material _fogMaterial;
	private Camera m_Camera;
	private Transform cameraTransform;

	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f; //雾效浓度

	public Color fogColor = Color.white; //雾效颜色

	public float fogStart = 0.0f; //雾效起始深度
	public float fogEnd = 2.0f; //雾效结束深度
	[Range(-0.5f, 0.5f)]
	public float fogXSpeed = 0.1f; //噪声纹理X方向移动速度
	[Range(-0.5f, 0.5f)]
	public float fogYSpeed = 0.1f; //噪声纹理Y方向移动速度
	[Range(0.0f, 3.0f)]
	public float noiseAmout = 1.0f; //噪声程度

	// Start is called before the first frame update
	void Start()
	{
		m_Camera = GetComponent<Camera>();
		if (m_Camera != null)
		{
			m_Camera.depthTextureMode |= DepthTextureMode.Depth;
			cameraTransform = m_Camera.transform;
		}
	}

	void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
	{
		if (_fogMaterial != null)
		{
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = m_Camera.fieldOfView; //竖直方向视角角度
			float near = m_Camera.nearClipPlane;
			float aspect = m_Camera.aspect;

			//近裁面一半高度
			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			//以近裁面中心为原点, 分别指向右和上方的向量
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;

			//计算摄像机为原点, 指向近裁面四个角的向量
			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			_fogMaterial.SetMatrix("_FrustumCornersRay", frustumCorners);

			_fogMaterial.SetFloat("_FogDensity", fogDensity);
			_fogMaterial.SetColor("_FogColor", fogColor);
			_fogMaterial.SetFloat("_FogStart", fogStart);
			_fogMaterial.SetFloat("_FogEnd", fogEnd);
			_fogMaterial.SetFloat("_FogXSpeed", fogXSpeed);
			_fogMaterial.SetFloat("_FogYSpeed", fogYSpeed);
			_fogMaterial.SetFloat("_NoiseAmout", noiseAmout);

			Graphics.Blit(sourceTexture, destTexture, _fogMaterial);
		}
		else
		{
			Graphics.Blit(sourceTexture, destTexture);
		}

	}

}
