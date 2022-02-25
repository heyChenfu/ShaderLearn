//广告牌效果(保持面朝摄像机)
// billboard主要有两种，第一种是固定向上方向的billboard，比如说草地，一个草地贴图向上的方向一定是(0,1,0)，
// unity自带的草地就是用的这种方法的，这种固定向上方向的billboard最后形成的结果就是图片绕着y轴进行旋转，毕竟俯视的时候如果看到草地法线朝着视角肯定会露馅的。
// 第二种billboard就是固定法线的billboard，这种就是让法线无时无刻都朝着摄像机，对于一般的例子效果是可以直接这样做的
Shader "Learn/BillboardWindTree"{
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 //是否固定向上方向

		//风算法
		_wind_dir ("Wind Direction", Vector) = (0.5,0.05,0.5,0)
        _wind_size ("Wind Wave Size", range(5,50)) = 15

        _tree_sway_stutter_influence("Tree Sway Stutter Influence", range(0,1)) = 0.2
        _tree_sway_stutter ("Tree Sway Stutter", range(0,10)) = 1.5
        _tree_sway_speed ("Tree Sway Speed", range(0,10)) = 1
        _tree_sway_disp ("Tree Sway Displacement", range(0,1)) = 0.3

        _branches_disp ("Branches Displacement", range(0,0.5)) = 0.3

        _leaves_wiggle_disp ("Leaves Wiggle Displacement", float) = 0.07
        _leaves_wiggle_speed ("Leaves Wiggle Speed", float) = 0.01

        _r_influence ("Red Vertex Influence", range(0,1)) = 1
        _b_influence ("Blue Vertex Influence", range(0,1)) = 1

	}
	SubShader {
		// Need to disable batching because of the vertex animation
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;

			float4 _wind_dir;
            float _wind_size;
            float _tree_sway_speed;
            float _tree_sway_disp;
            float _leaves_wiggle_disp;
            float _leaves_wiggle_speed;
            float _branches_disp;
            float _tree_sway_stutter;
            float _tree_sway_stutter_influence;
            float _r_influence;
            float _b_influence;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (a2v v) {
				v2f o;
				
				UNITY_SETUP_INSTANCE_ID(v);
				// Suppose the center in object space is fixed
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				
				float3 normalDir = viewer - center;
				// If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
				// Which means the normal dir is fixed
				// Or if _VerticalBillboarding equals 0, the y of normal is 0
				// Which means the up dir is fixed
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);
				// Get the approximate up dir
				// If normal dir is already towards up, then the up dir is towards front
                // 判断当前法向量是否平行上向量(发现归一化后如果y为1, 则认为和(0, 0, 1)平行)
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                //由于上向量和法向量不一定互相垂直, 所以重新计算一个和法向量垂直的上向量
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				
				// Use the three vectors to rotate the quad
				float3 centerOffs = v.vertex.xyz - center;
                //直接乘以新的三个坐标轴的方向向量就可以旋转了
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
              
				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				float3 worldPos = mul (unity_ObjectToWorld, v.vertex).xyz;
				o.pos.x += (cos(_Time.z * _tree_sway_speed + (worldPos.x/_wind_size) + (sin(_Time.z * _tree_sway_stutter * _tree_sway_speed + (worldPos.x/_wind_size)) * _tree_sway_stutter_influence) ) + 1)/2 * _tree_sway_disp * _wind_dir.x * (o.pos.y / 10) + 
				cos(_Time.w * o.pos.x * _leaves_wiggle_speed + (worldPos.x/_wind_size)) * _leaves_wiggle_disp * _wind_dir.x * _b_influence;

                o.pos.z += (cos(_Time.z * _tree_sway_speed + (worldPos.z/_wind_size) + (sin(_Time.z * _tree_sway_stutter * _tree_sway_speed + (worldPos.z/_wind_size)) * _tree_sway_stutter_influence) ) + 1)/2 * _tree_sway_disp * _wind_dir.z * (o.pos.y / 10) + 
                cos(_Time.w * o.pos.z * _leaves_wiggle_speed + (worldPos.x/_wind_size)) * _leaves_wiggle_disp * _wind_dir.z * _b_influence;
                o.pos.y += cos(_Time.z * _tree_sway_speed + (worldPos.z/_wind_size)) * _tree_sway_disp * _wind_dir.y * (o.pos.y / 10);
                //Branches Movement
                o.pos.y += sin(_Time.w * _tree_sway_speed + _wind_dir.x + (worldPos.z/_wind_size)) * _branches_disp * _r_influence;


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
