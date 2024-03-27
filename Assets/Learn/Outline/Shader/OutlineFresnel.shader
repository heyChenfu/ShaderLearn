//基础描边方案, 通过使用所谓的菲涅尔效应来实现
// Out=pow((1.0−saturate(dot(N,V))),P)
Shader "Learn/OutlineFresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
        _OutlineWidth ("Outline Width", Float) = 0.2
        _OutlineSoftness ("Outline Softness", Float) = 0.1
        _OutlinePower ("Outline Power", Float) = 1

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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _OutlineColor;
            float _OutlineWidth;
            float _OutlineSoftness;
            float _OutlinePower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(worldPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                //这种技术产生的轮廓始终是内轮廓线，在物体外部是不可见的，因此也许根本就不应该被称为轮廓线。
                //通过控制轮廓的宽度、力度和柔和度，可以创造出硬朗的线条或更加柔和/光亮的效果。
                //这种方法的特点是，对于球体和胶囊等边缘光滑圆润的物体效果很好，但对于立方体或边缘锋利的更复杂模型等物体，效果就会大打折扣。
                //对于一个立方体来说，轮廓看起来会非常糟糕，甚至不像轮廓。对于更复杂的模型，虽然整体轮廓效果看起来还可以，但会出现很多线宽不均匀的问题
                float edge1 = 1 - _OutlineWidth;
                float edge2 = edge1 + _OutlineSoftness;
                float fresnel = pow(1.0 - saturate(dot(i.worldNormal, i.worldViewDir)), _OutlinePower);
                half4 outlineColor = lerp(1, smoothstep(edge1, edge2, fresnel), step(0, edge1)) * _OutlineColor;
                col.rgb = lerp(col.rgb, outlineColor.rgb, outlineColor.a);

                return col;
            }
            ENDCG
        }
    }
}
