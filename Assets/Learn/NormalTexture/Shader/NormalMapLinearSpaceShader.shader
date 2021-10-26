//凹凸映射(在切线空间计算法线)
Shader "Learn/NormalMapLinearSpaceShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("MainTex", 2D) = "white" { }
        // 法线纹理(凹凸贴图)，"bump"是Unity内置的法线纹理，当没有提供法线纹理时，
        // "bump"就对应了模型自带的法线信息
        _BumpMap("NormalMap", 2D) = "bump" { }
        // 控制凹凸程度，为0时意味着法线纹理不会对光照产生影响
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

            // 顶点传递给片元着色器的数据
            struct v2f
            {
                float4 pos: SV_POSITION;
                // 定义成float4类型，xy存储_MainTex的纹理坐标，zw存储_MainTex的纹理坐标
                float4 uv: TEXCOORD0;
                float3 lightDir: TEXCOORD1;
                float3 viewDir: TEXCOORD2;
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
                // zw存储_MainTex的纹理坐标
                // den等价于o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // TANGENT_SPACE_ROTATION(切线空间到模型空间的变换矩阵)等价于:
                // 使用模型空间下的法线方向和切线方向叉积得到副切线方向
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                //定义 3x3 变换矩阵 rotation，分别将切线方向、副切线方向和法线方向按行摆放组成了这个矩阵。
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                TANGENT_SPACE_ROTATION;

                // 获得模型空间下的光向量
                // 将光向量从模型空间变换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                // 获得模型空间下的观察向量
                // 将观察向量从模型空间变换到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 获得压缩后的纹理
                fixed4  packedNormal = tex2D(_BumpMap, i.uv.zw);

                fixed3 tangentNormal;
                // 若法线纹理Texture Type未设置成Normal map，
                // 要从像素映射回法线，即[0, 1]转化到[-1, 1]
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;

                // 如果设置了Normal map类型，Unity会根据平台使用不同的压缩方法，
                // _BumpMap.rbg值不是对应的切线空间的xyz值了，要用Unity内置函数
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;

                // 因为法线都是单位矢量。所以 x^2 + y^2+ z^2=1
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

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
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

                // 获得半角向量
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                // 计算高光反射
                // Blinn-Phong高光反射公式：
                // Cspecular=(Clight ⋅ Mspecular)max(0,n.h)^mgloss
                // Clight：入射光颜色；
                // Mspecular：高光反射颜色；
                // n: 单位法向量；
                // h: 半角向量：光线和视线夹角一半方向上的单位向量
                // h = (V + L)/(| V + L |)
                // mgloss：反射系数；
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1);
            }

            ENDCG

        }
    }
}
