//屏幕后处理雾效, 使用噪声纹理模拟不均匀雾效, 并且让雾不断飘动
Shader "Learn/FogWithNoise"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _FogDensity ("Fog Density", Float) = 1.0
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogStart ("Fog Start", Float) = 0
        _FogEnd ("Fog End", Float) = 1
        _FogXSpeed ("Fog Horizental Speed", Float) = 0.1
        _FogYSpeed ("Fog Vertical Speed", Float) = 0.1
        _NoiseAmout ("Noise Amout", Float) = 1

	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
        sampler2D _NoiseTex;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
        float _FogXSpeed;
        float _FogYSpeed;
        float _NoiseAmout;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
            //根据纹理坐标判断使用哪个向量(屏幕后处理原理是使用特定材质渲染屏幕四边形面片, 四边形面片的四个顶点对应了近裁面四个角)
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];
				 	 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
            //根据深度纹理重建世界坐标位置
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			//噪声纹理采样
			float sampleSpeed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
			float noise = (tex2D(_NoiseTex, i.uv + sampleSpeed).r) * _NoiseAmout;
			noise += 0.5;
            //线性雾效, 使用高度模拟雾效
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity * noise);
			
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDCG
		
		Pass {
			ZTest Always ZWrite Off Cull Off
			     	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}