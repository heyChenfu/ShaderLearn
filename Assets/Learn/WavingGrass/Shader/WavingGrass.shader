//风吹草Shader
Shader "Learn/WavingGrass"
{
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _WaveTex ("Wave Tex", 2D) = "white" {} //波浪纹理
        _WindSpeed("Wind Speed", vector) = (1, 1, 1, 1)
        _WaveAmp("Wave Amp", Range(0.0, 1.0)) = 1.0 //波动幅度调整
        _HeightCutoff("Height Cutoff", Range(0.0, 1.0)) = 0.2 //高度限制, 低于此高度顶点不会运动
        _HeightFactor("Height Factor", float) = 1 //随高度增加波动幅度越大的次方函数
	}
	SubShader {
		Tags {"RenderType"="Opaque"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }

			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			
			#include "Lighting.cginc"
			
            sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveTex;
			float4 _WaveTex_ST;
            float4 _Color;
            float4 _WindSpeed;
            float _WaveAmp;
            float _HeightCutoff;
            float _HeightFactor;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float2 samplePos : TEXCOORD1; //波浪纹理采样点
			};

			v2f vert (a2v v) {
				v2f o;
				
				UNITY_SETUP_INSTANCE_ID(v);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                
                //使用世界坐标, 可以让草呈现整体飘动感觉
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.samplePos = worldPos.xz;
                o.samplePos += _Time.y * _WindSpeed.xy; //采样点随时间变化
                //对波浪纹理采样对顶点进行偏移 (顶点着色器中采样不能使用tex2D)
                fixed4 windSample = tex2Dlod(_WaveTex, float4(o.samplePos, 0, 0));
                float heightFactor = v.vertex.y > _HeightCutoff;
                //heightFactor = heightFactor * pow(v.vertex.y, _HeightFactor);
                o.pos.x += sin(windSample) * _WaveAmp * heightFactor;
                o.pos.z += cos(windSample) * _WaveAmp * heightFactor;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				return _Color;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
