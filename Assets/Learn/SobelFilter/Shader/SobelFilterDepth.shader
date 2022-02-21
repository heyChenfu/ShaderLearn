//边缘检测(outlined using depth only)
Shader "Learn/SobelFilterDepth" {

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
		
		//边缘检测算法
		float sobel (float2 uv) {
			float2 delta = float2(_DeltaX, _DeltaY);
			
			float4 hr = float4(0, 0, 0, 0);
			float4 vt = float4(0, 0, 0, 0);
			
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0, -1.0) * delta)) *  0.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0, -1.0) * delta)) * -1.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  0.0) * delta)) *  2.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  0.0) * delta)) * -2.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  1.0) * delta)) *  1.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0,  1.0) * delta)) *  0.0;
			hr += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  1.0) * delta)) * -1.0;
			
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0, -1.0) * delta)) *  2.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0, -1.0) * delta)) *  1.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  0.0) * delta)) *  0.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  0.0) * delta)) *  0.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2(-1.0,  1.0) * delta)) * -1.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 0.0,  1.0) * delta)) * -2.0;
			vt += _CameraDepthTexture.Sample(sampler_CameraDepthTexture, (uv + float2( 1.0,  1.0) * delta)) * -1.0;
			
			return sqrt(hr * hr + vt * vt);
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