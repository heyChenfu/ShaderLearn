//摄像机深度图展示, 如果看到的深度图是全黑的, 可能摄像机的Far Clip Plane设置太大
Shader "Learn/DepthTextureTest"
{


	SubShader
	{
		Tags{ "RenderType" = "Opaque" }

		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM

			#pragma vertex vert_img
			#pragma fragment frag_depth
			#include "UnityCG.cginc"
			sampler2D _CameraDepthTexture;

			float4 frag_depth(v2f_img i) : SV_Target{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			float lnr01Depth = Linear01Depth(depth); //线性变换

				return fixed4(lnr01Depth, lnr01Depth, lnr01Depth, 1);
			}


			ENDCG

		}
	}

	FallBack "Diffuse"
}