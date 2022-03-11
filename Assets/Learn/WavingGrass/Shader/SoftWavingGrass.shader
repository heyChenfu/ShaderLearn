//优秀的抖动算法草
Shader "Learn/SoftWavingGrass"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _GradientTex ("Gradient Texture", 2D) = "white" {}
        _GrassColorTop("Grass Color Top", Color) = (1, 1, 1, 1)
        _GrassColorBottom("Grass Color Bottom", Color) = (1, 1, 1, 1)
        _ShadowColor("Shadow Color", Color) = (1, 1, 1, 1)

        _ShakeWaveSize("Wave Size", float) = 1
        _ShakeWindSpeed("Shake Wind Speed", float) = 1.0
        _ShakeBending ("Shake Bending", Range (0, 1.0)) = 1.0

        _HeightCutoff("Height Cutoff", Range(0.0, 1.0)) = 0.1 //高度限制, 低于此高度顶点不会运动

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
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
            //#include "AutoLight.cginc"

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
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                //LIGHTING_COORDS(3, 4)

            };

            sampler2D _GradientTex;
            float4 _GradientTex_ST;
            float4 _GrassColorTop, _GrassColorBottom, _ShadowColor;
            float _ShakeWaveSize, _ShakeWindSpeed, _ShakeBending;
            float _HeightCutoff;

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
                UNITY_SETUP_INSTANCE_ID(v);
                o.uv = TRANSFORM_TEX(v.uv, _GradientTex);
                // 摆动的高度裁剪以及高度放大 ========================================
				float heightFactor = v.vertex.y > _HeightCutoff;
				heightFactor = heightFactor * pow(v.vertex.y, 2); //波动幅度随高度增加

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
                s *= _ShakeBending;
                s *= normalize (waveSpeed);
            
                float3 waveMove = float3(0,0,0);
                waveMove.x = dot (s, _waveXmove) * _ShakeWaveSize * heightFactor;
                waveMove.z = dot (s, _waveZmove) * _ShakeWaveSize * heightFactor;

                float3 waveForce = mul ((float3x3)unity_WorldToObject, waveMove).xyz;
                v.vertex.xyz += waveForce;
                // ==================================================================

                // 顶点光照 ==========================================================
                float3 normalDirection = normalize(mul(unity_WorldToObject, float4(v.normal, 0.0)).xyz);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float atten = 1.25;
				float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0 , dot(normalDirection, lightDirection));
				float3 lightFinal = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.xyz;
                // ===================================================================

                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.color = lightFinal;

                UNITY_TRANSFER_FOG(o, o.pos);
                //TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 Gradient = tex2D(_GradientTex, i.uv);
                fixed4 GradientColor = lerp(_GrassColorBottom, _GrassColorTop, Gradient.g);
                fixed4 col = float4(i.color, 1) * GradientColor;

                //UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }

    Fallback "Mobile/VertexLit"
}
