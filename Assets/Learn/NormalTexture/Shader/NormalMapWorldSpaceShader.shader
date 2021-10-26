// 凹凸映射(在世界空间计算法线)
Shader "Learn/NormalMapWorldSpaceShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" { }
        // 法线纹理(凹凸贴图)，"bump"是Unity自带的法线纹理，当没有提供法线纹理时，
        // "bump"就对应了模型自带的法线信息
        _BumpMap("NormalMap", 2D) = "bump" { }
        // 控制凹凸程度，为0时法线纹理不会对光照产生影响
        _BumpScale("BumpScale", float) = 1.0
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include"UnityCG.cginc"
            #include"Lighting.cginc"


            fixed4 _Color;
            sampler2D _MainTex;
            // _MainTex纹理的缩放和偏移系数
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            // _BumpMap纹理的缩放和偏移系数
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            // 应用传递给顶点着色器的数据
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                float4 texcoord: TEXCOORD0;
            };

            // 顶点着色器传递给片元着色器的数据
            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 uv: TEXCOORD0;
                float4 TtoW0: TEXCOORD1;
                float4 TtoW1: TEXCOORD2;
                float4 TtoW2: TEXCOORD3;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                // 将顶点坐标从模型空间变换到裁剪空间
                // 等价于o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);

                // xy存储_MainTex的纹理坐标
                // 等价于o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                // zw存储_BumpMap的纹理坐标
                // 等价于o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // 将顶点坐标从模型空间变换到世界空间
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 将法线从模型空间变换到世界空间
                // 等价于fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);

                // 将切线从模型空间变换到世界空间
                // 等价于fixed3 worldTangent = normalize(mul(v.tangent.xyz, (float3x3)unity_WorldToObject));
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

                // 获得世界空间下副切线(副法线)：(法向量 x 切线向量) * w
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 将切线、副切线、法线按列摆放得到从切线空间到世界空间的变换矩阵
                // 把该矩阵的每一行分别存储在TtoW0、TtoW1、TtoW2中
                // 把世界空间下的顶点位置的xyz分量分别存储在这些变量的w分量中
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                // 获得世界空间下顶点坐标
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

                // 获得世界空间下单位光向量
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                // 获得世界空间下单位观察向量
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // 获得压缩后的法线像素
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                fixed3 bump;
                // 若法线纹理Texture Type未设置成Normal map，
                // 要从像素映射回法线，即[0, 1]转化到[-1, 1]
                // bump.xy = (packedNormal.xy * 2 - 1) * _BumpScale;

                // 如果设置了Normal map类型，Unity会根据平台使用不同的压缩方法，
                // _BumpMap.rbg值不是对应的切线空间的xyz值了，要用Unity内置函数
                bump = UnpackNormal(packedNormal);
                bump.xy *= _BumpScale;
                // 因为法线都是单位矢量。所以 z = 根号下（1 - (x*x + y*y) ）
                bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy)));
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                // 对主纹理采样
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

                // 获得环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射
                // 兰伯特公式：Id = Ip * Kd * N * L
                // IP：入射光的光颜色；
                // Kd：漫反射系数 ( 0 ≤ Kd ≤ 1)；
                // N：单位法向量，
                // L：单位光向量
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump, worldLightDir));

                // 获得半角向量
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);

                // 计算高光反射
                // Blinn-Phong高光反射公式：
                // Cspecular=(Clight ⋅ Mspecular)max(0,n.h)^mgloss
                // Clight：入射光颜色；
                // Mspecular：高光反射颜色；
                // n: 单位法向量；
                // h: 半角向量：光线和视线夹角一半方向上的单位向量
                // h = (V + L)/(| V + L |)
                // mgloss：反射系数；
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG

        }
    }
}

