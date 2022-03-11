//简单水面
Shader "Learn/SimpleWater"
{
    Properties
    {
        _NoiseTex("Noise Texture", 2D) = "white" {}
        // color of the water
        _Color("Color", Color) = (1, 1, 1, 1)
        // color of the edge effect
        _EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        // width of the edge effect
        _DepthFactor("Depth Factor", float) = 1.0

        //波动速读控制
        _WaveSpeed("Wave Speed", float) = 1.0
        //波动大小缩放
        _WaveAmp("Wave Amp", float) = 1.0

    }

    SubShader
    {
        Tags{ "Queue" = "Transparent" }
        Pass
        {
            CGPROGRAM
            // required to use ComputeScreenPos()
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag
            
            // Unity built-in - NOT required in Properties
            sampler2D _CameraDepthTexture;

            sampler2D _NoiseTex;
            float4 _Color;
            float4 _EdgeColor;
            float _DepthFactor;
            float _WaveSpeed;
            float _WaveAmp;

            struct vertexInput
            {
                float4 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;

                // convert obj-space position to camera clip space
                output.pos = UnityObjectToClipPos(input.vertex);

                // compute depth (screenPos is a float4)
                output.screenPos = ComputeScreenPos(output.pos);
                output.uv = input.texcoord;

                // apply wave animation
                float noiseSample = tex2Dlod(_NoiseTex, float4(input.texcoord.xy, 0, 0));
                output.pos.y += sin(_Time.x * noiseSample * _WaveSpeed) * _WaveAmp;

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                // sample camera depth texture
                float depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
                float depth = LinearEyeDepth(depthSample.r);
                //float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv);
                //float depth = Linear01Depth(depthSample);

                // apply the DepthFactor to be able to tune at what depth values
                float4 foamLine = 1 - saturate(_DepthFactor * (depth - input.screenPos.w));
                float4 col = _Color + foamLine * _EdgeColor;
                return col;
            }

            ENDCG
        }
    }

    //FallBack "Diffuse" //去除自身的Shadowcaster, 自己不渲染到ScreenSpaceShadowMap
}