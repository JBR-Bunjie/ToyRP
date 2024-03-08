Shader "ToyRP/lightPass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    
    SubShader
    {
        Cull Off Zwrite On ZTest Always

        CGINCLUDE
        #define PI 3.14159265359f

        // D
        float Trowbridge_Reitz_GGX(float NdotH, float a) {
            float a2 = a * a;
            float NdotH2 = NdotH * NdotH;

            float nom = a2;
            float denom = (NdotH2 * (a2 - 1.0) + 1.0);
            denom = PI * denom * denom;

            return nom / denom;
        }

        // F
        float3 SchlickFresnel(float HdotV, float3 F0) {
            float m = clamp(1 - HdotV, 0, 1);
            float m2 = m * m;
            float m5 = m2 * m2 * m; // pow(m,5)
            return F0 + (1.0 - F0) * m5;
        }

        // G
        float SchlickGGX(float NdotV, float k) {
            float nom = NdotV;
            float denom = NdotV * (1.0 - k) + k;

            return nom / denom;
        }

        float3 Cook_Torrance(float3 N, float3 V, float3 L, float3 albedo, float3 radiance, float metallic, float roughness) {
            // https://learnopengl-cn.github.io/07%20PBR/01%20Theory/

            roughness = max(roughness, 0.05); // 保证光滑物体也有高光

            float3 H = normalize(L + V);

            float NoH = dot(N, H);
            float HoV = dot(H, V);
            float NoV = dot(N, V);
            float NoL = dot(N, L);

            float3 diffuse = albedo / PI;

            float alpha = roughness * roughness;
            float k = ((alpha + 1) * (alpha + 1)) / 8.0;
            float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

            float D = Trowbridge_Reitz_GGX(NoH, alpha);
            float3 F = SchlickFresnel(HoV, F0);
            float G = SchlickGGX(NoV, k);
            float3 specular = (D * F * G) / (4 * NoV * NoL + 0.0001);

            float ks = F;
            float kd = (1 - ks) * (1 - metallic);

            diffuse *= PI;
            specular *= PI;

            float3 col = (diffuse * kd + specular) * radiance * NoL;

            return col;
        }
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct app {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            v2f vert(app v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _gdepth;
            sampler2D _GT0;
            sampler2D _GT1;
            sampler2D _GT2;
            sampler2D _GT3;
            float4x4 _vpMatrix;
            float4x4 _vpMatrixInv;

            void frag(v2f i, out float3 col : SV_Target, out float dout : SV_Depth) {
                float2 uv = i.uv;
                
                float4 GT1 = tex2D(_GT1, uv);
                float4 GT2 = tex2D(_GT2, uv);
                float4 GT3 = tex2D(_GT3, uv);

                float3 albedo = tex2D(_GT0, uv).rgb;
                float3 normal = GT1.rgb * 2 - 1;
                float2 motionVec = GT2.rg;
                float roughness = GT2.b;
                float metallic = GT2.a;
                float3 emission = GT3.rgb;
                float ao = GT3.a;

                float d = UNITY_SAMPLE_DEPTH(tex2D(_gdepth, uv));
                float d_lin = Linear01Depth(d);

                float4 ndcPos = float4(uv, d, 1);
                float4 worldPos = mul(_vpMatrixInv, ndcPos);
                worldPos /= worldPos.w;

                float3 N = normalize(normal);
                // float3 L = normalize(worldPos - _WorldSpaceLightPos0);
                float3 L = normalize(_WorldSpaceLightPos0);
                float3 V = normalize(_WorldSpaceCameraPos - worldPos);
                float3 radiance = _LightColor0.rgb;

                col = Cook_Torrance(N, V, L, albedo, radiance, metallic, roughness) + emission;
                dout = d;
            }
            ENDCG
        }
    }
} 