Shader "MyShaders/CustomLit"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            float4 _BaseColor;
            float _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(appdata data)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(data.vertex);
                o.normal = UnityObjectToWorldNormal(data.normal);
                o.worldPos = mul(unity_ObjectToWorld, data.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Diffuse Light
                float3 N = normalize(i.normal); // Normal
                float3 L = _WorldSpaceLightPos0.xyz; // Light Dir
                float lambert = saturate(dot(N, L));
                float3 diffuseLight = lambert * _LightColor0;

                // Specular Light (Blinn-Phong)
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos); // View to cam Vector
                float3 H = normalize(L + V); // Half Vector
                float specularExponent = exp2(_Gloss * 11) + 10;
                float3 specularLight = pow(saturate(dot(H, N)) * (lambert > 0), specularExponent) * _Gloss;
                specularLight *= _LightColor0;

                return float4(diffuseLight * _BaseColor + specularLight, 1);
            }
            ENDCG
        }
    }
}