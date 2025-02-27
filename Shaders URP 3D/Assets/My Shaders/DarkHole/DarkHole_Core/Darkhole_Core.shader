Shader"MyShaders/Darkhole_Core"
{
    Properties
    {
        _NoiseTex1 ("_NoiseTex1", 2D) = "white" {}
        _NoiseTex2 ("_NoiseTex2", 2D) = "white" {}
        _TexScale("Texture Scale", Float) = 1
        _RotationSpeed("Rotation Speed", Float) = 1
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _HoleSize ("Hole Size", Range(0,1)) = 0.4
        _OutlineSize ("Outline Size", Range(0,1)) = 0.6
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

            sampler2D _NoiseTex1;
            sampler2D _NoiseTex2;
            float4 _NoiseTex1_ST;
            float4 _NoiseTex2_ST;

            float _TexScale;
            float _RotationSpeed;

            float4 _OutlineColor;

            float _HoleSize;
            float _OutlineSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            v2f vert(appdata data)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(data.vertex);
                o.normal = UnityObjectToWorldNormal(data.normal);
                o.uv1 = TRANSFORM_TEX(data.uv1, _NoiseTex1);
                o.uv2 = TRANSFORM_TEX(data.uv2, _NoiseTex2);
                o.worldPos = mul(unity_ObjectToWorld, data.vertex);
                o.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, data.normal));
                return o;
            }

            float2 RotateUV(float2 uv, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return mul(float2x2(c, -s, s, c), uv);
            }

            float4 LerpComputeUV(float2 uv)
            {
                float4 tex1 =  tex2D(_NoiseTex1, uv);
                float4 tex2 =  tex2D(_NoiseTex2, uv);

                return tex1 + tex2;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Fresnel
                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos); // View to cam Vector

                if (_HoleSize > _OutlineSize) _HoleSize = _OutlineSize;
                float4 fresnelEffect = smoothstep(_HoleSize, _OutlineSize, 1 - dot(V, N)) * _OutlineColor;

                // Triplanar
                float3 worldPos = i.worldPos * _TexScale;
                float angle = _Time.y * _RotationSpeed;
                
                float2 uvX = RotateUV(worldPos.yz, angle);
                float2 uvY = RotateUV(worldPos.xz, angle);
                float2 uvZ = RotateUV(worldPos.xy, angle);

                float3 blending = abs(i.worldNormal);
                blending /= (blending.x + blending.y + blending.z);

                float4 xProjection = LerpComputeUV(uvX);
                float4 yProjection = LerpComputeUV(uvY);
                float4 zProjection = LerpComputeUV(uvZ);

                float4 triplanarColor = xProjection * blending.x + yProjection * blending.y + zProjection * blending.z;

                return triplanarColor * fresnelEffect;
            }
            ENDCG
        }
    }
}