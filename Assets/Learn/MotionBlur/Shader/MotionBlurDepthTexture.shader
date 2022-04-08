//使用深度值计算像素速度制作运动模糊效果
//使用VP逆矩阵重建世界坐标, 但是会比较影响性能
Shader "Learn/MotionBlurDepthTexture"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		float4x4 _CurrentViewProjectionInverseMatrix;
		float4x4 _PreviousViewProjectionMatrix;
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1; //对深度纹理采样纹理坐标
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
            //处理平台差异导致图像翻转?
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
					 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 由于NDC中z范围[-1, 1], 需要存储在图像中, 所以深度纹理中的深度值 d = 0.5 * Z(ndc) + 0.5
            //计算NDC坐标, NDC的xy分量可以由纹理坐标映射而来
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// 如果按照正常思维来算，应该是先乘以w，然后进行逆变换，最后再把world中的w抛弃，即是最终的世界坐标，不过实际上投影变换是一个损失维度的变换，我们并不知道应该乘以哪个w，所以实际上上面的计算，并非按照理想的情况进行的计算，而是根据计算推导而来
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			float4 worldPos = D / D.w;
			
			// Current viewport position 
			float4 currentPos = H;
			// Use the world position, and transform by the previous view-projection matrix.  
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// Convert to nonhomogeneous points [-1,1] by dividing by w.
			previousPos /= previousPos.w;
			
			// 通过位置差得到当前片元的速度
			float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}
