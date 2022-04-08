//使用深度值重建世界坐标, 在世界空间下重建
Shader "Unlit/RebuildWorldPosFromDepth"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 worldSpaceDir : TEXCOORD1;
                float viewSpaceZ : TEXCOORD2;
            };

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldSpaceDir = WorldSpaceViewDir(v.vertex);
                // 将向量转换到观察空间，存储其z分量的值。注意向量和位置的空间转换是不同的，当w分量为0的时候Unity会将其视为向量，而当w分量为1的时候Unity将其视为位置
                o.viewSpaceZ = mul(UNITY_MATRIX_V, float4(o.worldSpaceDir, 0.0)).z;
                // Compute texture coordinate
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the depth texture to get the linear eye depth
                float eyeDepth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);
                eyeDepth = LinearEyeDepth(eyeDepth);

                // 根据向量的z分量计算其缩放因子，将向量缩放到实际的长度
                i.worldSpaceDir *= -eyeDepth / i.viewSpaceZ;

                // 最后以摄像机为起点，缩放后的向量为指向向量，得到像素点在世界空间中位置
                float3 worldPos = _WorldSpaceCameraPos + i.worldSpaceDir;

                return float4(worldPos, 1.0);
            }
            ENDCG
        }
    }
}
