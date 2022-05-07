// 面片树叶
Shader "Learn/TreeLeaves"
{
    Properties 
    {
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        //_MaskTex ("Mask Tex", 2D) = "white"{}
        //_ShadowColor ("Shadow Color", Color) = (1, 1, 1, 1)
        //_EdgeLitRate ("Edge Lit Rate", Range(0, 2)) = 0.3
        _Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5

        //wind
        _OffsetGradientStrength ("Offset Gradient Strength", Range(0, 1)) = 0.7
        _ShakeWindSpeed("Shake Wind Speed", float) = 1
        _ShakeBlending("Shake Blending", float) = 1
        _WindDirRate("Wind Direction Rate", float) = 0.5
        _WindDirection("Wind Direction", Vector) = (0.5, 0.5, 0.5, 0)
        _WindStrength ("Wind Strength", float) = 1
    }
    
    SubShader {
        Tags { "RenderType" = "Opaque" }

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
                fixed3 diff : COLOR0;
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                LIGHTING_COORDS(3, 4)
            };

            sampler2D _MainTex;
            //sampler2D _MaskTex;
            float4 _MainTex_ST;
            //float4 _MaskTex_ST;
            float4 _MainColor;
            //float4 _ShadowColor;
            //float _EdgeLitRate;
            float _Cutoff;
            float _OffsetGradientStrength, _ShakeWindSpeed, _ShakeBlending, _WindDirRate;
            float4 _WindDirection;
            float _WindStrength;

            void FastSinCos (float4 val, out float4 s, out float4 c) 
            {
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

                //漫反射
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                o.diff = _LightColor0.xyz * saturate(dot(worldNormal, lightDirection));

                // 风吹效果算法 =====================================================
                const float _WindSpeed = _ShakeWindSpeed;
                const float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
                const float4 _waveZSize = float4 (0.024, .08, 0.08, 0.2);
                const float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);

                float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
                float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

                float4 waves;
                waves = v.vertex.x * _waveXSize;
                waves += v.vertex.z * _waveZSize;

                waves += _Time.x * waveSpeed * _WindSpeed + v.vertex.x + v.vertex.z;

                float4 s, c;
                waves = frac (waves);
                FastSinCos (waves, s, c);
                float waveAmount = v.uv.y * _ShakeBlending;
                s *= waveAmount;
                s *= normalize(waveSpeed);

                float3 waveMove = float3(0,0,0);
                float windDirX = _WindDirection.x * _WindStrength;
                float windDirZ = _WindDirection.z * _WindStrength;
                float windDirY = _WindDirection.y * _WindStrength;
                waveMove.x = dot (s, _waveXmove * windDirX);
                waveMove.y = dot (s, _waveZmove * windDirY);
                waveMove.z = dot (s, _waveZmove * windDirZ);

                float3 windDirOffset = float3(windDirX, windDirY, windDirZ) * _WindDirRate;
                float3 waveForce = -mul((float3x3)unity_WorldToObject, waveMove).xyz + windDirOffset;

                v.vertex.xyz += waveForce;
                // =================================================================

                UNITY_SETUP_INSTANCE_ID(v);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed4 ambient = _MainColor * albedo * UNITY_LIGHTMODEL_AMBIENT;
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
                V2F_SHADOW_CASTER; //申请阴影数据
                float2 uv : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            float _Cutoff;
            float _OffsetGradientStrength, _ShakeWindSpeed, _ShakeBlending, _WindDirRate;
            float4 _WindDirection;
            float _WindStrength;

            void FastSinCos (float4 val, out float4 s, out float4 c) 
            {
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
                const float _WindSpeed = _ShakeWindSpeed;
                const float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
                const float4 _waveZSize = float4 (0.024, .08, 0.08, 0.2);
                const float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);

                float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
                float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

                float4 waves;
                waves = v.vertex.x * _waveXSize;
                waves += v.vertex.z * _waveZSize;

                waves += _Time.x * waveSpeed * _WindSpeed + v.vertex.x + v.vertex.z;

                float4 s, c;
                waves = frac (waves);
                FastSinCos (waves, s, c);
                float waveAmount = v.uv.y * _ShakeBlending;
                s *= waveAmount;
                s *= normalize(waveSpeed);

                float3 waveMove = float3(0,0,0);
                float windDirX = _WindDirection.x * _WindStrength;
                float windDirZ = _WindDirection.z * _WindStrength;
                float windDirY = _WindDirection.y * _WindStrength;
                waveMove.x = dot (s, _waveXmove * windDirX);
                waveMove.y = dot (s, _waveZmove * windDirY);
                waveMove.z = dot (s, _waveZmove * windDirZ);

                float3 windDirOffset = float3(windDirX, windDirY, windDirZ) * _WindDirRate;
                float3 waveForce = -mul((float3x3)unity_WorldToObject, waveMove).xyz + windDirOffset;

                v.vertex.xyz += waveForce;
                // =================================================================

                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 texCol = tex2D(_MainTex, i.uv);
                fixed4 col = _MainColor * texCol;
                // 透明度测试
                clip(col.a - _Cutoff);

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }

    }
    
    FallBack "Transparent/VertexLit"
}