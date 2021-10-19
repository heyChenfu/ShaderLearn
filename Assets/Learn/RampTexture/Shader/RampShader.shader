//渐变贴图
Shader "Learn/RampShader"
{
	Properties
	{
		_BaseTex("Base Texture", 2D) = "white" {}
		_RampTex("Ramp Texture", 2D) = "white" {}
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
		SubShader
		{
			Pass
			{
				Tags {"LightMode" = "ForwardBase"}

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				sampler2D _BaseTex;
				float4 _BaseTex_ST;
				sampler2D _RampTex;
				float4 _RampTex_ST;
				fixed4 _Specular;
				float _Gloss;

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 worldPos : TEXCOORD1;
					float3 worldNormal : TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.worldNormal = UnityObjectToWorldNormal(v.normal);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

					fixed halfLambert = dot(worldNormal, lightDir) * 0.5 + 0.5;
					/*
					fixed2(halfLambert, halfLambert) 这句其实我们只关心其x坐标，y坐标没意义。
					那么halfLambert为什么可以与纹理坐标联系起来呢，我们从漫反射的公式中看出，法线与光照方向的夹角决定了光照系数，
					夹角越小，光照系数越大，漫反射越强，反之，系数越小，漫反射越弱，那么我们用渐变纹理的x轴表示其系数变化，
					x轴也就是系数越小，就采样越黑的颜色，表示漫反射越弱，系数越大也就是x越大，就采样越白的颜色，表示漫反射越强，
					所以我们的渐变纹理是从左到右从黑到白，就是这个原理
					*/
					fixed3 color = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * tex2D(_BaseTex, i.uv).rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

					fixed3 diffuse = _LightColor0.rgb * color;

					fixed3 halfDir = normalize(viewDir + lightDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

					return fixed4(ambient + diffuse + specular, 1.0);
				}
				ENDCG
			}
		}

			FallBack "Specular"
}