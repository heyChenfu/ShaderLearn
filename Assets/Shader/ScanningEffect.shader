Shader "Learn/ScanningEffect"
{
	Properties{
		_ScanValue("ScanValue", float) = 0
		_ScanLineWidth("ScanLineWidth", float) = 0.01
		_ScanLineColor("ScanLineColor", Color) = (1,0.2,0.2,0.2)
	}

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
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float _ScanValue;
			float _ScanLineWidth;
			fixed4 _ScanLineColor;

			float4 frag_depth(v2f_img i) : SV_Target{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float lnr01Depth = Linear01Depth(depth);
				fixed4 screenTexture = tex2D(_MainTex, i.uv);

				float near = smoothstep(_ScanValue, lnr01Depth, _ScanValue - .01); // _ScanValue 就是 控制值, 在 [0, 1] 区间
				float far = smoothstep(_ScanValue, lnr01Depth, _ScanValue + .01);
				fixed4 emissionClr = _ScanLineColor * near;
				fixed4 emissionClr1 = _ScanLineColor * far;
				return screenTexture + emissionClr + emissionClr1;
			}

			ENDCG

		}
	}

	FallBack "Diffuse"
}
