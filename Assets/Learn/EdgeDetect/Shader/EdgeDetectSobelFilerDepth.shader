//边缘检测(outlined using depth only)
Shader "Learn/EdgeDetectSobelFilerDepth" {

	Properties {
		[HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		_Color("Outline Color", Color) = (1, 1, 1, 1)
		_DeltaX ("Delta X", Float) = 0.001
		_DeltaY ("Delta Y", Float) = 0.001
		_OutlineDepthPow ("Outline Depth Pow", Range(1, 50)) = 50
		[Toggle(RAW_OUTLINE)]_Raw ("Outline Only", Float) = 0
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		fixed4 _Color;
		float _DeltaX;
		float _DeltaY;
		fixed _OutlineDepthPow;
		texture2D _CameraDepthTexture;
		SamplerState sampler_CameraDepthTexture;
		
		//3x3卷积核
		// -1 -2 -1    -1  0  1
		// 0  0  0     -2  0  2
		// 1  2  1     -1  0  1
		// 梯度值越大, 越有可能是边缘
		float sobel (float2 uv) {
			float2 delta = float2(_DeltaX, _DeltaY);
			
			//分别得到水平和竖直方向上的梯度值
			float4 hr = float4(0, 0, 0, 0);
			float4 vt = float4(0, 0, 0, 0);
			
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
			//hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0, -1.0) * delta)) *  0.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0, -1.0) * delta)) * -1.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  0.0) * delta)) *  2.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  0.0) * delta)) * -2.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  1.0) * delta)) *  1.0;
			//hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0,  1.0) * delta)) *  0.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  1.0) * delta)) * -1.0;
			
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0, -1.0) * delta)) *  2.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0, -1.0) * delta)) *  1.0;
			//vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  0.0) * delta)) *  0.0;
			//vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  0.0) * delta)) *  0.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  1.0) * delta)) * -1.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0,  1.0) * delta)) * -2.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  1.0) * delta)) * -1.0;
			
			//获得整体梯度值, 出于性能考虑可以 G = |Gx| + |Gy|代替
			return sqrt(hr * hr + vt * vt);
			//return abs(hr) + abs(vt);
		}
		
		float4 frag (v2f_img i) : COLOR {
			//pow进行描边增强
			float s = pow(saturate(1- sobel(i.uv)), _OutlineDepthPow);
#ifdef RAW_OUTLINE
			return float4(s.xxx, 1);
#endif
			half4 col = tex2D(_MainTex, i.uv);
			col = lerp(_Color, col, s);
			return col;
		}
		
		ENDCG
		
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma shader_feature RAW_OUTLINE
			ENDCG
		}
		
	} 
	FallBack "Diffuse"
}