//风吹草Shader
Shader "Learn/WavingGrassVertexLightShadow"
{
    Properties
    {
	    _Color("Colour", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	    _WaveSize("WaveSize", Range(0.0, 2.0)) = 0.1 //运动大小缩放
        _Frequency("Frequency", float) = 2 //运动频率
		_Cutoff("AlphaCutoff", Range(0, 1)) = 0.5 //Alpha阈值
		_HeightCutoff("Height Cutoff", Range(0.0, 1.0)) = 0.1 //高度限制, 低于此高度顶点不会运动
        _Direction("Direction", Vector) = (1, 1, 1, 0) //运动的方向
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
            #pragma multi_compile_fwdbase
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform float4 _Color;
			uniform float _WaveSize;
			uniform float _Frequency;
			float _Cutoff, _HeightCutoff;
            fixed4 _Direction;

			//base input structs
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 col : COLOR;
				float4 texcoord : TEXCOORD0;
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
                fixed4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //====================风吹算法=======================
				float heightFactor = v.vertex.y > _HeightCutoff;
                heightFactor = heightFactor * v.vertex.y; //根据高度放大运动幅度, 也可以采用UV的高度来做
                half time = _Time.y * _Frequency;
                v.vertex.xyz += heightFactor * (sin(time + worldPos.x) * cos(time * 2 / 3) + 0.3)* _Direction.xyz * _WaveSize;
                //==================================================

				//=====================顶点漫反射====================
				float3 normalDirection = normalize(mul(unity_WorldToObject, float4(v.normal, 0.0)).xyz);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 diffuseReflection = _LightColor0.xyz * max(0.0 , dot(normalDirection, lightDirection));
				float3 lightFinal = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.xyz;
                // =================================================

				o.col = float4(lightFinal * _Color.rgb, 1.0);
				o.pos = UnityObjectToClipPos(v.vertex);
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

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform float4 _Color;
			uniform float _WaveSize;
			uniform float _Frequency;
			float _Cutoff, _HeightCutoff;
            fixed4 _Direction;

			struct v2f {
				V2F_SHADOW_CASTER;
				half2 uv : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				fixed4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				//====================风吹算法=======================
				float heightFactor = v.vertex.y > _HeightCutoff;
                heightFactor = heightFactor * v.vertex.y; //根据高度放大运动幅度, 也可以采用UV的高度来做
                half time = _Time.y * _Frequency;
                v.vertex.xyz += heightFactor * (sin(time + worldPos.x) * cos(time * 2 / 3) + 0.3)* _Direction.xyz * _WaveSize;
                //==================================================

				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				float4 color = tex2D(_MainTex, i.uv);
				clip(color.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

    }

	Fallback "Mobile/Diffuse"
}
