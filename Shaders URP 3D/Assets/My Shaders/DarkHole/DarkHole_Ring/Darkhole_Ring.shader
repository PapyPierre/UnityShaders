Shader "MyShaders/Darkhole_Ring"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RingInnerRadius ("Inner Radius", Range(0,1)) = 0.5
        _MinRingOuterRadius ("Min Outer Radius", Range(0,1)) = 0.6
        _MaxRingOuterRadius ("Max Outer Radius", Range(0,1)) = 0.8
        _RotationSpeed("Rotation Speed", Float) = 1
        _PulseSpeed("Pulse Speed", Float) = 1
        _InnerRingColor ("Inner Ring Color", Color) = (1,1,1,1)
        _OuterRingColor ("Outer Ring Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _RingInnerRadius;
            float _MinRingOuterRadius;
            float _MaxRingOuterRadius;

            float _RotationSpeed;
            float _PulseSpeed;

            float4 _InnerRingColor;
            float4 _OuterRingColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata data)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(data.vertex);
                o.normal = UnityObjectToWorldNormal(data.normal);
                o.uv = TRANSFORM_TEX(data.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, data.vertex);

                return o;
            }

            float2 RotateUV(float2 uv, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return mul(float2x2(c, -s, s, c), uv);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uvsCentered = i.uv * 2 - 1;
                float radialDistance = length(uvsCentered);
                float angle = _Time.y * _RotationSpeed;
                
               float _RingOuterRadius = lerp(_MinRingOuterRadius, _MaxRingOuterRadius, sin(_Time.y * _PulseSpeed));
                
                float4 ring = step(radialDistance, _RingOuterRadius) - step(radialDistance, _RingInnerRadius);
                
                float4 ringColor = smoothstep(_RingInnerRadius, _RingOuterRadius, radialDistance);
                ringColor *= lerp(_InnerRingColor, _OuterRingColor, ringColor);
                
                return ring * tex2D(_MainTex, RotateUV(i.uv, angle))* ringColor;
            }
            ENDCG
        }
    }
}