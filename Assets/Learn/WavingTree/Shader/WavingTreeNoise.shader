// 风吹树, 使用噪点纹理
Shader "Learn/WavingTreeNoise"
{
    Properties 
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
        _WaveSpeed ("Wave Speed", float) = 1
        _WaveScale("Wave Scale", float) = 1

    }

    SubShader
    {
        Pass
        {
            Tags { "Queue" = "AlphaTest" "RenderType"="Opaque" "LightMode" = "ForwardBase" }
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            //#pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Assets/Shader/SimplexNoise3D.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 color : COLOR;
                float2 texcood : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                LIGHTING_COORDS(3, 4)

            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            float _WaveSpeed, _WaveScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.texcood = TRANSFORM_TEX(v.uv, _MainTex);
                // 风吹效果算法=======================================================
                //3D噪声 世界坐标运算
                float timeScale = _Time.y * _WaveSpeed;
                o.posWorld.xyz += timeScale;
                float noiseSample = SimplexNoise(o.posWorld);
                //3D噪声 uv运算
                // float2 uv = v.uv * 4 + float2(0.2, 1) * _Time.y;
                // float3 coord = float3(uv, _Time.y);
                // float noiseSample = SimplexNoise(coord);

                noiseSample = noiseSample * _WaveScale * _MainTex_ST.xy * 0.01 * 30;
                v.vertex += noiseSample;
                // ==================================================================

                UNITY_SETUP_INSTANCE_ID(v);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcood);
                col *= _Color;
                // 透明度测试
                clip(col.a - _Cutoff);

                UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
                col *= atten;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            //#include "AutoLight.cginc"
            #include "Assets/Shader/SimplexNoise3D.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 color : COLOR;
                float2 texcood : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                //LIGHTING_COORDS(3, 4)

            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            float _WaveSpeed, _WaveScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.texcood = TRANSFORM_TEX(v.uv, _MainTex);
                // 风吹效果算法=======================================================
                //3D噪声 世界坐标运算
                float timeScale = _Time.y * _WaveSpeed;
                o.posWorld.xyz += timeScale;
                float noiseSample = SimplexNoise(o.posWorld);
                noiseSample = noiseSample * _WaveScale * _MainTex_ST.xy * 0.01 * 30;
                v.vertex += noiseSample;
                // ==================================================================

                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_SHADOW_CASTER(o)

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcood);
                col *= _Color;
                // 透明度测试
                clip(col.a - _Cutoff);

                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

    }

    Fallback "Mobile/VertexLit"
}