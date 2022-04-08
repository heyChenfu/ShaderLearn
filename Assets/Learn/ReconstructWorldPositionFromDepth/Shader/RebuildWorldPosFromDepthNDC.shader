//使用深度值重建世界坐标, NDC方法
Shader "Learn/RebuildWorldPosFromDepthNDC"
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
                float3 viewVec : TEXCOORD1;
            };

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);

                // 屏幕空间坐标转换到NDC空间中
                float4 ndcPos = (o.screenPos / o.screenPos.w) * 2 - 1;

                // 将屏幕像素对应在摄像机远平面(Far plane)的点转换到剪裁空间(Clip space)。
                //因为在NDC空间中远平面上的点的z分量为1，所以可以直接乘以摄像机的Far值来将其转换到剪裁空间
                float far = _ProjectionParams.z;
                float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * far;
                //通过逆投影矩阵(Inverse Projection Matrix)将点转换到观察空间
                o.viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //观察空间中摄像机的位置一定为(0，0，0)，所以从摄像机指向远平面上的点的向量就是其在观察空间中的位置
                //将向量乘以线性深度值，得到在深度缓冲中储存的值的观察空间位置
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);
                depth = Linear01Depth(depth);
                float3 viewPos = i.viewVec * depth;
                float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos, 1)).xyz;
                return fixed4(worldPos, 1);
            }
            ENDCG
        }
    }
}
