//风吹草表面着色器, 添加阴影
Shader "Learn/WavingGrassSurface"
{
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
	    _Color("Colour", Color) = (1.0, 1.0, 1.0, 1.0)
	    _WaveSize("WaveSize", Range(0.0, 2.0)) = 0.00125
        _WaveLength("WaveLength", float) = 0.25
        _Frequency("Frequency", float) = 25
		_HeightCutoff("Height Cutoff", Range(0.0, 1.0)) = 0.2 //高度限制, 低于此高度顶点不会运动
		_HeightFactor("Height Factor", float) = 1 //随顶点高度增加波动幅度越大
		_AlphaCutoff("AlphaCutoff", Range(0, 1)) = 0.5 //Alpha阈值
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
        CGPROGRAM
        #pragma surface surf Lambert alphatest:_Cutoff vertex:vert addshadow
		
		sampler2D _MainTex;
		uniform float4 _Color;
		uniform float _WaveSize;
		uniform float _WaveLength;
		uniform float _Frequency;
		float _HeightCutoff;
		float _HeightFactor;
		float _AlphaCutoff;
		
        struct Input {
            float2 uv_MainTex : TEXCOORD0;
        };

        void vert (inout appdata_full v) {
			float heightFactor = v.vertex.y > _HeightCutoff;
			heightFactor = heightFactor * pow(v.vertex.y, 2); //波动幅度随高度增加
			//x, z方向运动
			v.vertex.x += sin(v.vertex.y + _Time * _Frequency) * _WaveSize * heightFactor;
			v.vertex.z += cos(v.vertex.y + _Time * _Frequency) * _WaveSize * heightFactor;

        }
		
        void surf (Input IN, inout SurfaceOutput o){
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }

		ENDCG
	} 
	FallBack "Transparent/VertexLit"
}
