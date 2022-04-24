//有单独Pass顶点外扩描边的卡通渲染Shader
Shader "Learn/ToonShading"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _Outline("Outline", Range(0, 1)) = 0.1 //控制轮廓宽度
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1) //轮廓颜色
        _Specular("Specular", Color) = (1, 1, 1, 1) //高光反射颜色
        _SpecularScale("Specular Scale", Range(0, 1)) = 0.01 //高光反射阈值

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            //渲染轮廓pass
            NAME "OUTLINE"
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Outline;
            float4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 worldNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                worldNormal.z = -0.5; //扩张背面顶点之前对法线Z处理使之为一个定值, 扩展后的背面更加扁平化降低遮挡正面可能
                pos = pos + float4(normalize(worldNormal), 0) * _Outline;

                o.pos = mul(UNITY_MATRIX_P, pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull Back

            CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Color, _Specular;
            fixed _SpecularScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = mul(v.normal, unity_WorldToObject);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 albedo = c.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); //计算阴影
				
                //使用漫反射系数对渐变纹理采样
				fixed diff =  dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;

				fixed spec = dot(worldNormal, worldHalfDir);
                //fwidth进行边界抗锯齿处理
				fixed w = fwidth(spec) * 2.0; //fwidth 计算出领域像素之间的导数值，用于作为阈值
                //在[-w, w]区间得到0到1的平滑差值
				fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1));// * step(0.0001, _SpecularScale);
				
				return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG

        }
        
    }
}
