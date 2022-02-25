// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//亮度饱和度对比度
Shader "Learn/BrightnessSaturationContrast"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1 //亮度
		_Saturation("Saturation", Float) = 1 //饱和度
		_Contrast("Contrast", Float) = 1 //对比度
	}
	SubShader {
        Tags { "RenderType"="Opaque" }
        
		Pass {
			ZTest Always Cull Off //ZWrite Off
			
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv = v.texcoord;
						 
				return o;
			}
		
			fixed4 frag(v2f i) : SV_Target {
				fixed4 renderTex = tex2D(_MainTex, i.uv);  
				  
				// Apply brightness
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				// Apply saturation
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b; //每个颜色分量乘以系数相加得到亮度值
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance); //饱和度为零的颜色
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
				
				// Apply contrast
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5); //对比度为零的颜色
				finalColor = lerp(avgColor, finalColor, _Contrast);
				
				return fixed4(finalColor, renderTex.a);  
			}
			  
			ENDCG
		}
	}
	
	Fallback Off
}
