// 风吹树
Shader "Learn/WavingTree"
{
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _ShakeWindspeed ("Shake Windspeed", float) = 1.0
        _ShakeBending ("Shake Bending", float) = 1.0
    }
    
    SubShader {
        Tags {"RenderType"="TransparentCutout"}
    
        Pass
        {
            Tags { "Queue" = "AlphaTest" "LightMode" = "ForwardBase" }
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //apply fog
            #pragma multi_compile_fog
            //apply light
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 diff : COLOR;
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                LIGHTING_COORDS(3, 4)
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff, _ShakeWindspeed, _ShakeBending;

            void FastSinCos (float4 val, out float4 s, out float4 c) {
                val = val * 6.408849 - 3.1415927;
                float4 r5 = val * val;
                float4 r6 = r5 * r5;
                float4 r7 = r6 * r5;
                float4 r8 = r6 * r5;
                float4 r1 = r5 * val;
                float4 r2 = r1 * r5;
                float4 r3 = r2 * r5;
                float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841} ;
                float4 cos8  = {-0.5, 0.041666666, -0.0013888889, 0.000024801587} ;
                s =  val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
                c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //======================风吹效果算法========================
                const float _WindSpeed  = _ShakeWindspeed;
            
                const float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
                const float4 _waveZSize = float4 (0.024, 0.08, 0.08, 0.2);
                const float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);
            
                float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
                float4 _waveYmove = float4 (0.01, 0.03, -0.04, 0.08);
                float4 _waveZmove = float4 (0.006, 0.02, -0.02, 0.1);
            
                float4 waves;
                waves = v.vertex.x * _waveXSize;
                waves += v.vertex.z * _waveZSize;
            
                waves += _Time.x * waveSpeed * _WindSpeed + v.vertex.x + v.vertex.z;

                float4 s, c;
                waves = frac (waves);
                FastSinCos (waves, s, c);
                s *= _ShakeBending;
                s *= normalize (waveSpeed);

                float3 waveMove = float3 (0, 0, 0);
                //waveMove.x = dot (s, _waveXmove);
                waveMove.y = dot (s, _waveYmove);
                waveMove.z = dot (s, _waveZmove);
                v.vertex.xyz += mul ((float3x3)unity_WorldToObject, waveMove);
                // =========================================================

                //=====================顶点漫反射====================
				float3 normalDirection = normalize(mul(unity_WorldToObject, v.normal.xyz));
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 diffuseReflection = _LightColor0.xyz * max(0.0 , dot(normalDirection, lightDirection));
                // =================================================

                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.diff = diffuseReflection;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_FOG(o, o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed4 ambient = _Color * albedo * UNITY_LIGHTMODEL_AMBIENT;
                // 透明度测试
                clip(albedo.a - _Cutoff);

                fixed4 diffuse = fixed4(albedo.rgb * i.diff, 1);
                UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
                fixed4 col = ambient + diffuse * atten;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, albedo);

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
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff, _ShakeWindspeed, _ShakeBending;

            void FastSinCos (float4 val, out float4 s, out float4 c) {
                val = val * 6.408849 - 3.1415927;
                float4 r5 = val * val;
                float4 r6 = r5 * r5;
                float4 r7 = r6 * r5;
                float4 r8 = r6 * r5;
                float4 r1 = r5 * val;
                float4 r2 = r1 * r5;
                float4 r3 = r2 * r5;
                float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841} ;
                float4 cos8  = {-0.5, 0.041666666, -0.0013888889, 0.000024801587} ;
                s =  val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
                c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 风吹效果算法 =====================================================
                const float _WindSpeed  = _ShakeWindspeed;
            
                const float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
                const float4 _waveZSize = float4 (0.024, 0.08, 0.08, 0.2);
                const float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);
            
                float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
                float4 _waveYmove = float4 (0.01, 0.03, -0.04, 0.08);
                float4 _waveZmove = float4 (0.006, 0.02, -0.02, 0.1);
            
                float4 waves;
                waves = v.vertex.x * _waveXSize;
                waves += v.vertex.z * _waveZSize;
            
                waves += _Time.x * waveSpeed * _WindSpeed + v.vertex.x + v.vertex.z;

                float4 s, c;
                waves = frac (waves);
                FastSinCos (waves, s, c);
                s *= _ShakeBending;
                s *= normalize (waveSpeed);

                float3 waveMove = float3 (0, 0, 0);
                //waveMove.x = dot (s, _waveXmove);
                waveMove.y = dot (s, _waveYmove);
                waveMove.z = dot (s, _waveZmove);
                v.vertex.xyz += mul ((float3x3)unity_WorldToObject, waveMove);
                // ===================================================================

                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 texCol = tex2D(_MainTex, i.uv);
                fixed4 col = _Color * texCol;
                // 透明度测试
                clip(col.a - _Cutoff);

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
        
    }
    
    //FallBack "Transparent/VertexLit"
    Fallback "Transparent/Cutout/VertexLit"
}