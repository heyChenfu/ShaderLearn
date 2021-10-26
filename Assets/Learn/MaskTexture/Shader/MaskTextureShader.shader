// 遮罩纹理
//遮罩运行我们可以保护某些区域，使它们免于某些修改。
//常见使用
//1. 在之前的实现中，我们都是把高光反射应用到模型表面的所有地方，即所有的像素都使用同样大小的高光强度和高光指数。但有时，我们希望模型表面某些区域的反光强烈一些，某些区域弱一些。可以使用一张遮罩纹理来控制光照。
//2. 在制作地形材质时需要混合多张图片，例如表现草地的纹理，表现石子的纹理等，使用遮罩纹理可以控制如何混合这些纹理
Shader "Learn/MaskTexture"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex("MainTex", 2D) = "white" { }
        // 凹凸纹理(法线纹理)
        _BumpMap("NormalMap", 2D) = "bump" { }
        // 凹凸程度
        _BumpScale("BumpScale", float) = 1.0
        // 高光反射遮罩纹理
        _SpecularMask("SpecularMask", 2D) = "white" { }
        _SpecularScale("SpecularScale", float) = 1.0
        // 高光反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1)
        // 高光区域大小
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

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpMap;
                float _BumpScale;
                sampler2D _SpecularMask;
                float _SpecularScale;
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
                    float2 uv: TEXCOORD0;
                    float3 lightDir: TEXCOORD1;
                    float3 viewDir: TEXCOORD2;
                };

                // 顶点着色器函数
                v2f vert(a2v v)
                {
                    v2f o;

                    // 将顶点坐标从模型空间转换到裁剪空间
                    // 等价于o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 存储_MainTex的纹理坐标
                    // 等价于o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);


                    // TANGENT_SPACE_ROTATION(切线空间到模型空间的变换矩阵)等价于：
                    // 使用模型空间下的法线和切线叉积得到副切线方向, v.tangent.w的值是1或-1
                    // Unity遵循的是OpenGL规范，在导入模型的时候uv走向是+y, 所以如果在windows上Unity用DirectX的情况下, 叉乘得到的B'刚好反向了. 所以Unity存储了一个手性信息在tangent.w里，在正交化最后得到切线T'的时候计算当前平台的手性值并存在tangent.w中
                    // float3 binormal = cross(normalize(v.normal), normalize(v.tangent)) * normalize(v.tangent.w)
                    // 定义 3x3 变换矩阵 rotation，分别将切线方向、副切线方向和法线方向按行摆放组成了这个矩阵。
                    // float3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                    TANGENT_SPACE_ROTATION;

                    // 获得切线空间下光照方向
                    o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                    // 获得切线空间下视角方向
                    o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET
                {
                    fixed3 tangentLightDir = normalize(i.lightDir);
                    fixed3 tangentViewDir = normalize(i.viewDir);

                    // 获得压缩后法线
                    fixed4 packedNormal = tex2D(_BumpMap, i.uv);

                    fixed3 tangentNormal;
                    // 若法线纹理Texture Type未设置成Normal map
                    // 要从像素映射回法线，即[0, 1]转化到[-1, 1]
                    // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;

                    // 如果设置了Normal map类型，Unity会根据平台使用不同的压缩方法
                    // _BumpMap.rbg值不是对应的切线空间的xyz值了，要用Unity内置函数
                    tangentNormal = UnpackNormal(packedNormal);
                    tangentNormal.xy *= _BumpScale;

                    // 因为法线都是单位矢量。所以 z = 根号下（1 - x*x + y*y ）
                    tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                    // 对主纹理采样
                    fixed3 albedo = tex2D(_MainTex, i.uv).rgg * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                    // 计算漫反射
                    // 兰伯特公式：Id = Ip * Kd * N * L
                    // IP：入射光的光颜色；
                    // Kd：漫反射系数 ( 0 ≤ Kd ≤ 1)；
                    // N：单位法向量，
                    // L：单位光向量
                    fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

                    // 获得半角向量
                    fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                    // 对遮罩纹理采样
                    fixed3 specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;

                    // 计算高光反射
                    // Blinn-Phong高光反射公式：
                    // Cspecular=(Clight ⋅ Mspecular)max(0,n.h)^mgloss
                    // Clight：入射光颜色；
                    // Mspecular：高光反射颜色；
                    // n: 单位法向量；
                    // h: 半角向量：光线和视线夹角一半方向上的单位向量
                    // h = (V + L)/(| V + L |)
                    // mgloss：反射系数；
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss) * specularMask;

                    return fixed4(ambient + diffuse + specular, 1);
                }

                ENDCG

            }
        }
}
