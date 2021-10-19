//画圆
Shader "Learn/DrawCircle"
{
    Properties
    {
        _Radius("Radius", float) = 10
        _Color("Color", Color) = (0, 0, 0, 0)
        _BackgroundColor("BackgroundColor", Color) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
            };

            float _Radius;
            fixed4 _Color;
            fixed4 _BackgroundColor;

            float sdfCircle(float2 coord, float2 center, float radius)
            {
                float2 offset = coord - center;
                return sqrt((offset.x * offset.x) + (offset.y * offset.y)) - radius;
            }

            float4 render(float d, float3 color, float stroke)
            {
                float anti = fwidth(d) * 1.0;
                float4 colorLayer = float4(color, 1.0 - smoothstep(-anti, anti, d));
                if (stroke < 0.000001) {
                    return colorLayer;
                }

                float4 strokeLayer = float4(float3(0.05, 0.05, 0.05), 1.0 - smoothstep(-anti, anti, d - stroke));
                return float4(lerp(strokeLayer.rgb, colorLayer.rgb, colorLayer.a), strokeLayer.a);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pixelPos = (i.scrPos.xy / i.scrPos.w) * _ScreenParams.xy;
                float a = sdfCircle(pixelPos, float2(0.5, 0.5) * _ScreenParams.xy, _Radius);
                float4 layer1 = render(a, _Color, fwidth(a) * 2.0);
                return lerp(_BackgroundColor, layer1, layer1.a);
            }
            ENDCG
        }
    }
}
