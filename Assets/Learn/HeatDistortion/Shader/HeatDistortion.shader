//热气扭曲效果
Shader "Unlit/HeatDistortion"
{
	Properties {
		//_MainTex ("Main Tex", 2D) = "white" {}
		_Noise("Noise Texture", 2D) = "white" {}
		_StrengthFilter("Strength Filter", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		[Toggle(ENABLE_BILLBOARD)]_ENABLE_BILLBOARD ("Enable billboard", Float) = 0
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 //是否固定向上方向
		_Speed("Speed", float) = 1.0
		_DistortStrength("Distort Strength", float) = 1.0

	}
	SubShader {
		// Need to disable batching because of the vertex animation
		//Tags {"IgnoreProjector"="True" "DisableBatching"="True"}
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "LightMode"="ForwardBase" }
        GrabPass { "_HeatDistortionBackgroundTexture" }

		Pass {
			Tags {"LightMode"="ForwardBase" }
			//ZWrite Off
			//Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#pragma shader_feature ENABLE_BILLBOARD

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			sampler2D _Noise;
			float4 _Noise_ST;
			sampler2D _StrengthFilter;
            sampler2D _HeatDistortionBackgroundTexture;
			fixed4 _Color;
			fixed _VerticalBillboarding;
			float _Speed;
			float _DistortStrength;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				//float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
			};

			v2f vert (a2v v) {
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                //o.uv = TRANSFORM_TEX(v.texcoord,_Noise);

#ifdef ENABLE_BILLBOARD
                //====================Billboard===================
                //物体空间原点
                float3 center = float3(0, 0, 0);
                //将相机位置转换至物体空间并计算相对原点朝向，物体旋转后的法向将与之平行，这里实现的是Viewpoint-oriented Billboard
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
                float3 normalDir = viewer - center;
                // _VerticalBillboarding为0到1，控制物体法线朝向向上的限制，实现Axial Billboard到World-Oriented Billboard的变换
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                //若原物体法线已经朝向上，这up为z轴正方向，否者默认为y轴正方向
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                //利用初步的upDir计算righDir，并以此重建准确的upDir，达到新建转向后坐标系的目的
                float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
                // 计算原物体各顶点相对位移，并加到新的坐标系上
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + normalDir * centerOffs.y + upDir * centerOffs.z;
                o.pos = UnityObjectToClipPos(float4(localPos, 1));
                //================================================
#else
				o.pos = UnityObjectToClipPos(v.vertex);
#endif

				//顶点动画
                o.grabPos = ComputeGrabScreenPos(o.pos);
				float noise = tex2Dlod(_Noise, v.texcoord);
				float filter = tex2Dlod(_StrengthFilter, v.texcoord);
				o.grabPos.x += cos(noise * _Time.y * _Speed) * _DistortStrength * filter;
				o.grabPos.y += sin(noise * _Time.y* _Speed) * _DistortStrength * filter;


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2Dproj(_HeatDistortionBackgroundTexture, i.grabPos);
				c.rgb *= _Color.rgb;
				return c;
				//return fixed4(1, 1, 1, 1);
			}
			
			ENDCG
		}
	} 
	//FallBack "Transparent/VertexLit"
}
