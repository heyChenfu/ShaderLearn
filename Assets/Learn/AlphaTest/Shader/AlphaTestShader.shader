// 透明度测试
Shader "Learn/AlphaTestShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" { }
        // 透明度
        _Cutoff("AlpheCutoff", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags {"Queue" = "AlphaTest" "RenderType" = "Opaque" }

        pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            // 应用传递给顶点着色器的数据
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 texcoord: TEXCOORD0;
            };

            // 顶点着色器传递给片元着色器的数据
            struct v2f
            {
                float4 pos: SV_POSITION;
                float3 worldNormal: TEXCOORD0;
                float worldPos : TEXCOORD1;
                float2 uv: TEXCOORD2;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                // 将顶点坐标从模型空间变换到裁剪空间
                // 等价于o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将法线从模型空间变换到时间空间
                // 等价于o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 将顶点坐标从模型空间变换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 获取纹理uv坐标
                // 等价于o.uv = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_TARGET
            {
                // 获得世界空间下光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 透明度测试
                clip(texColor.a - _Cutoff);
                // 等价于
                // if (texColor.a - _Cutoff < 0.0) {
                    //      discard;
                    //   }

                // 主纹理颜色
                fixed3 albedo = texColor.rgb * _Color.rgb;

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射
                // 兰伯特公式：Id = Ip * Kd * N * L
                // IP：入射光的光颜色；
                // Kd：漫反射系数 ( 0 ≤ Kd ≤ 1)；
                // N：单位法向量，
                // L：单位光向量
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(i.worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, 1.0);
                }

                ENDCG

            }
    }
}

