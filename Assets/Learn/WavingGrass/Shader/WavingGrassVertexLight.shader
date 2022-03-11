//风吹草Shader
Shader "Learn/WavingGrassVertexLight"
{
    Properties
    {
		_MainTex ("Main Tex", 2D) = "white" {}
	    _Color("Colour", Color) = (1.0, 1.0, 1.0, 1.0)
	    _WaveSize("WaveSize", Range(0.0, 2.0)) = 0.1
        _WaveLength("WaveLength", float) = 0.25
        _Frequency("Frequency", float) = 25
		_HeightCutoff("Height Cutoff", Range(0.0, 1.0)) = 0.2 //高度限制, 低于此高度顶点不会运动
		_HeightFactor("Height Factor", float) = 1 //随顶点高度增加波动幅度越大
		_Cutoff("AlphaCutoff", Range(0, 1)) = 0.5 //Alpha阈值
    }
    SubShader
    {
		Tags {"Queue" = "AlphaTest" "RenderType" = "Opaque" }
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

			#include "Lighting.cginc"

			//user defined variables
			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform float4 _Color;
			uniform float _WaveSize;
			uniform float _WaveLength;
			uniform float _Frequency;
			float _HeightCutoff;
			float _HeightFactor;
			float _Cutoff;

			//base input structs
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 col : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 col : COLOR;
				float2 uv : TEXCOORD0;
			};

			//vertex function
			vertexOutput vert(vertexInput v) {
				vertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);

				float heightFactor = v.vertex.y > _HeightCutoff;
				heightFactor = heightFactor * pow(v.vertex.y, 2); //波动幅度随高度增加
				//x, z方向运动
				v.vertex.x += sin(v.vertex.y + _Time * _Frequency) * _WaveSize * heightFactor;
				v.vertex.z += cos(v.vertex.y + _Time * _Frequency) * _WaveSize * heightFactor;

				//光照
				float3 normalDirection = normalize(mul(unity_WorldToObject, float4(v.normal, 0.0)).xyz);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float atten = 1.25;
				float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0 , dot(normalDirection, lightDirection));
				float3 lightFinal = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.xyz;

				o.col = float4(lightFinal * _Color.rgb, 1.0);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			//fragment function
			float4 frag(vertexOutput i) : COLOR
			{
				float4 color = tex2D(_MainTex, i.uv);
				clip(color.a - _Cutoff);
				color = color * i.col;
				return color;
			}
            
            ENDCG
        }
    }
    //FallBack "Diffuse"
}
