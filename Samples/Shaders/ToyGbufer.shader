Shader "ToyRP/gbuffer" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}

        [Space(25)]
        _Metallic_global ("Metallic", Range(0, 1)) = 0.5
        _Roughness_global ("Roughness", Range(0, 1)) = 0.5

        [Toggle] _Use_Metal_Map ("Use Matal Map", Float) = 1
        _MetallicGlossMap ("Metallic Map", 2D) = "white" {}

        [Space(25)]
        _EmissionMap("Emission Map", 2D) = "black" {}

        [Space(25)]
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}

        [Space(25)]
        [Toggle] _Use_Normal_Map ("Use Normal Map", Float) = 1
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
    }
    SubShader {
        Tags {
            "LightMode"="gbuffer"
        }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Metallic_global;
            float _Roughness_global;
            float _Use_Metal_Map;
            sampler2D _MetallicGlossMap;
            sampler2D _EmissionMap;
            sampler2D _OcclusionMap;
            float _Use_Normal_Map;
            sampler2D _BumpMap;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            void frag(
                v2f i,
                out float4 GT0 : SV_Target0,
                out float4 GT1 : SV_Target1,
                out float4 GT2 : SV_Target2,
                out float4 GT3 : SV_Target3
            ) {
                float3 color = tex2D(_MainTex, i.uv).rgb;
                float3 emission = tex2D(_EmissionMap, i.uv).rgb;
                float3 normal = i.normal;
                float metallic = _Metallic_global;
                float roughness = _Roughness_global;
                float ao = tex2D(_OcclusionMap, i.uv).g;

                if (_Use_Metal_Map) {
                    float4 metal = tex2D(_MetallicGlossMap, i.uv);
                    metallic = metal.r;
                    roughness = 1.0 - metal.a;
                }

                float2 motionVec;

                GT0 = float4(color, 1);
                // GT0 = pow(dot(normal));
                GT1 = float4(normal * 0.5 + 0.5, 0);
                // GT2 = float4(motionVec, metallic, roughness);
                GT2 = float4(0,0, metallic, roughness);
                GT3 = float4(emission, ao);
            }
            ENDCG
        }
    }
}