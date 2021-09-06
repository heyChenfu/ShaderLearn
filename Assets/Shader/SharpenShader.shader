//边缘突出-锐化
Shader "Learn/SharpenShader"
{
    Properties
    {
        [KeywordEnum(IncreaseEdgeAdj, BrightEdgeAdj)] _EADJ("Edge Adj type", Float) = 0
        _Tex("Tex", 2D) = "white" {}
        _Intensity("Intensity", Range(0, 20)) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _EADJ_INCREASEEDGEADJ _EADJ_BRIGHTEDGEADJ
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Tex;
            float4 _Tex_ST;
            float _Intensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Tex); //就是将模型顶点的uv和Tiling,Offset两个变量进行运算，计算出实际显示用的顶点uv
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed a = 0.5;
                fixed3 c = tex2D(_Tex, i.uv).rgb;
                #if _EADJ_INCREASEEDGEADJ // 边缘调整：增加边缘差异调整
                // 类似两个3x3的卷积核处理
                /*
                one:
                | 0| 0| 0|
                | 0|-1| 1|
                | 0| 0| 0|
                two:
                | 0| 0| 0|
                | 0|-1| 0|
                | 0| 1| 0|
                */
                //使用(ddx(c) + ddy(c))，没有绝对值，会然边缘的像素亮度差异变大，即：加强边缘突出
                c += (ddx(c) + ddy(c)) * _Intensity;
                #else //_EADJ_BRIGHTEDGEADJ // 边缘调整：增加边缘亮度调整
                c += fwidth(c) * _Intensity; // fwidth(c) ==> abs(ddx(c)) + abs(ddy(c))
                //使用fwidth函数，可以看出，会是边缘变亮，突出边缘
                // fwidth func in HLSL: https://docs.microsoft.com/zh-cn/windows/desktop/direct3dhlsl/dx-graphics-hlsl-fwidth
                #endif
                return fixed4(c, a);
            }
            ENDCG
        }
    }
}
