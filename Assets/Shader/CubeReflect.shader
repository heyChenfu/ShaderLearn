//立方体贴图反射 
Shader "Learn/CubeReflect"
{
    Properties{
            _Cube("Cubemap", Cube) = "" { /* used to be TexGen CubeReflect */ }
    }
        SubShader{
            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                struct v2f {
                    float4 pos : SV_POSITION;
                    float3 uv : TEXCOORD0;
                };

                v2f vert(float4 v : POSITION, float3 n : NORMAL)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v);

                    // TexGen CubeReflect：
                    // 反映视图空间中沿法线的
                    // 视图方向
                    float3 viewDir = normalize(ObjSpaceViewDir(v));
                    o.uv = reflect(-viewDir, n);
                    o.uv = mul(UNITY_MATRIX_MV, float4(o.uv,0));
                    return o;
                }

                samplerCUBE _Cube;
                half4 frag(v2f i) : SV_Target
                {
                    return texCUBE(_Cube, i.uv);
                }
                ENDCG
            }
    }
}
