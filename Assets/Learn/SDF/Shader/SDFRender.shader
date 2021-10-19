// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// SDF 实现
Shader "Learn/SDFRender"
{
	Properties{
		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
		_DistanceMark("Distance Mark", float) = .5
		_OutlineDistanceMark("Outline Distance Mark", float) = .25
		_GlowDistanceMark("Glow Distance Mark", float) = .25
		_SmoothDelta("Smooth Delta", float) = .25
		_ShadowSmoothDelta("Shadow Smooth", float) = .1
		_GlowSmoothDelta("Glow Smooth", float) = .1
		_MainColor("Main Color", Color) = (1,1,1,1)
		_OutlineColor("Outline Color", Color) = (1,0,0,1)
		_GlowColor("Glow Color", Color) = (1,0,0,1)
		_ShadowColor("Shadow Color", Color) = (1,0,0,1)
		_ShadowOffsetX("Shadow Offset X", float) = 0
		_ShadowOffsetY("Shadow Offset Y", float) = 0
	}

		SubShader{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		LOD 100

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass{
		CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag

	#include "UnityCG.cginc"

		struct appdata_t {
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			half2 texcoord : TEXCOORD0;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _MainColor;
		float4 _OutlineColor;
		float4 _ShadowColor;
		float4 _GlowColor;
		float _SmoothDelta;
		float _ShadowSmoothDelta;
		float _GlowSmoothDelta;
		float _DistanceMark;
		float _OutlineDistanceMark;
		float _GlowDistanceMark;
		float _ShadowOffsetX;
		float _ShadowOffsetY;
		
		v2f vert(appdata_t v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.texcoord);
			float distance = col.r;

			fixed4 outlineCol;
			outlineCol.a = smoothstep(_OutlineDistanceMark - _SmoothDelta, _OutlineDistanceMark + _SmoothDelta, distance);
			outlineCol.rgb = _OutlineColor.rgb;

			fixed4 glowCol;
			glowCol.a = smoothstep(_GlowDistanceMark - _GlowSmoothDelta, _GlowDistanceMark + _GlowSmoothDelta, distance);
			glowCol.rgb = _GlowColor.rgb;

			float shadowDistance = tex2D(_MainTex, i.texcoord + half2(_ShadowOffsetX, _ShadowOffsetY));
			float shadowAlpha = smoothstep(_DistanceMark - _ShadowSmoothDelta, _DistanceMark + _ShadowSmoothDelta, shadowDistance);
			fixed4 shadowCol = fixed4(_ShadowColor.rgb, _ShadowColor.a * shadowAlpha);

			col.rgb = _MainColor.rgb;
			col.a = smoothstep(_DistanceMark - _SmoothDelta, _DistanceMark + _SmoothDelta, distance);
			//if (distance < _DistanceMark)
			//	col.a = 0.0;
			//else
			//	col.a = 1.0;
			//col.rgb = _MainColor.rgb;

			//return col;
			//return lerp(glowCol, col, col.a);
			return lerp(outlineCol, col, col.a);
			//return lerp(shadowCol, col, col.a);
		}
			ENDCG
		}
	}
}
