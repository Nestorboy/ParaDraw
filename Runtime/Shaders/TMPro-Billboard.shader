// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Orchid Seal/ParaDraw/Distance Field-BillboardFacing"
{
	// Billboarding version for TextMeshPro (tested in 2018.3), based on default Distance Field shader. 
	// ** Important part is to DISABLE the dynamic batching! (happens in this shader) **
	// ...Took a while to figure out that one.
	// 
	// Use as you like! 
	// - Almar
	// 
	// https://gist.github.com/Spongert/b52a24aa110933a918cf47c777fea1c8

	Properties
	{
		_FaceTex("Face Texture", 2D) = "white" {}
		_FaceUVSpeedX("Face UV Speed X", Range(-5, 5)) = 0.0
		_FaceUVSpeedY("Face UV Speed Y", Range(-5, 5)) = 0.0
		_FaceColor("Face Color", Color) = (1,1,1,1)
		_FaceDilate("Face Dilate", Range(-1,1)) = 0

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineTex("Outline Texture", 2D) = "white" {}
		_OutlineUVSpeedX("Outline UV Speed X", Range(-5, 5)) = 0.0
		_OutlineUVSpeedY("Outline UV Speed Y", Range(-5, 5)) = 0.0
		_OutlineWidth("Outline Thickness", Range(0, 1)) = 0
		_OutlineSoftness("Outline Softness", Range(-1,1)) = 0

		_Bevel("Bevel", Range(0,1)) = 0.5
		_BevelOffset("Bevel Offset", Range(-0.5,0.5)) = 0
		_BevelWidth("Bevel Width", Range(-.5,0.5)) = 0
		_BevelClamp("Bevel Clamp", Range(0,1)) = 0
		_BevelRoundness("Bevel Roundness", Range(0,1)) = 0

		_LightAngle("Light Angle", Range(0.0, 6.2831853)) = 3.1416
		_SpecularColor("Specular", Color) = (1,1,1,1)
		_SpecularPower("Specular", Range(0,4)) = 2.0
		_Reflectivity("Reflectivity", Range(5.0,15.0)) = 10
		_Diffuse("Diffuse", Range(0,1)) = 0.5
		_Ambient("Ambient", Range(1,0)) = 0.5

		_BumpMap("Normal map", 2D) = "bump" {}
		_BumpOutline("Bump Outline", Range(0,1)) = 0
		_BumpFace("Bump Face", Range(0,1)) = 0

		_ReflectFaceColor("Reflection Color", Color) = (0,0,0,1)
		_ReflectOutlineColor("Reflection Color", Color) = (0,0,0,1)
		_Cube("Reflection Cubemap", Cube) = "black" { /* TexGen CubeReflect */ }
		_EnvMatrixRotation("Texture Rotation", vector) = (0, 0, 0, 0)


		_UnderlayColor("Border Color", Color) = (0,0,0, 0.5)
		_UnderlayOffsetX("Border OffsetX", Range(-1,1)) = 0
		_UnderlayOffsetY("Border OffsetY", Range(-1,1)) = 0
		_UnderlayDilate("Border Dilate", Range(-1,1)) = 0
		_UnderlaySoftness("Border Softness", Range(0,1)) = 0

		_GlowColor("Color", Color) = (0, 1, 0, 0.5)
		_GlowOffset("Offset", Range(-1,1)) = 0
		_GlowInner("Inner", Range(0,1)) = 0.05
		_GlowOuter("Outer", Range(0,1)) = 0.05
		_GlowPower("Falloff", Range(1, 0)) = 0.75

		_WeightNormal("Weight Normal", float) = 0
		_WeightBold("Weight Bold", float) = 0.5

		_ShaderFlags("Flags", float) = 0
		_ScaleRatioA("Scale RatioA", float) = 1
		_ScaleRatioB("Scale RatioB", float) = 1
		_ScaleRatioC("Scale RatioC", float) = 1

		_MainTex("Font Atlas", 2D) = "white" {}
		_TextureWidth("Texture Width", float) = 512
		_TextureHeight("Texture Height", float) = 512
		_GradientScale("Gradient Scale", float) = 5.0
		_ScaleX("Scale X", float) = 1.0
		_ScaleY("Scale Y", float) = 1.0
		_PerspectiveFilter("Perspective Correction", Range(0, 1)) = 0.875

		_VertexOffsetX("Vertex OffsetX", float) = 0
		_VertexOffsetY("Vertex OffsetY", float) = 0

		_MaskCoord("Mask Coordinates", vector) = (0, 0, 32767, 32767)
		_ClipRect("Clip Rect", vector) = (-32767, -32767, 32767, 32767)
		_MaskSoftnessX("Mask SoftnessX", float) = 0
		_MaskSoftnessY("Mask SoftnessY", float) = 0

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(SILHOUETTE_FADING_ON)] _SilhouetteFadingEnabled("Silhouette Fading", Float) = 1.0
		_SilhouetteFadeParams("Silhouette Fading Params", Vector) = (-0.5,1,0.51,0)
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"

			// Important to disable batching! Otherwise things will be offset
			"DisableBatching" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull[_CullMode]
		ZWrite Off
		Lighting Off
		Fog { Mode Off }
		Blend One OneMinusSrcAlpha
		ColorMask[_ColorMask]

		CGINCLUDE
        int _KeepConstantScaling;
        float _Scaling;

        #include "UnityCG.cginc"
        #include "UnityUI.cginc"
        #include "/Assets/TextMesh Pro/Shaders/TMPro_Properties.cginc"
        #include "/Assets/TextMesh Pro/Shaders/TMPro.cginc"

        struct vertex_t {
            float4	position		: POSITION;
            float3	normal			: NORMAL;
            fixed4	color : COLOR;
            float2	texcoord0		: TEXCOORD0;
            float2	texcoord1		: TEXCOORD1;
        };

        struct pixel_t {
            float4	position		: SV_POSITION;
            fixed4	color : COLOR;
            float2	atlas			: TEXCOORD0;		// Atlas
            float4	param			: TEXCOORD1;		// alphaClip, scale, bias, weight
            float4	mask			: TEXCOORD2;		// Position in object space(xy), pixel Size(zw)
            float3	viewDir			: TEXCOORD3;

        #if (UNDERLAY_ON || UNDERLAY_INNER)
            float4	texcoord2		: TEXCOORD4;		// u,v, scale, bias
            fixed4	underlayColor : COLOR1;
        #endif
            float4 textures			: TEXCOORD5;
        #if defined(SILHOUETTE_FADING_ON) || defined(SOFTPARTICLES_ON) || defined(_FADING_ON)
            float4 projectedPosition : TEXCOORD6;
        #endif
        };

        // Used by Unity internally to handle Texture Tiling and Offset.
        float4 _FaceTex_ST;
        float4 _OutlineTex_ST;
        UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

        float4 _SilhouetteFadeParams;

        #if (defined(SILHOUETTE_FADING_ON) || defined(SOFTPARTICLES_ON) || defined(_FADING_ON)) && defined(USING_STEREO_MATRICES)
            #define vertFading(o) \
            o.projectedPosition = ComputeScreenPos(vPosition); \
            o.projectedPosition.z = -mul(UNITY_MATRIX_V, float4(positionWs, 1.0)).z;
        #elif defined(SILHOUETTE_FADING_ON) || defined(SOFTPARTICLES_ON) || defined(_FADING_ON)
            #define vertFading(o) \
            o.projectedPosition = ComputeScreenPos(vPosition); \
            o.projectedPosition.z = -(positionVs.z / positionVs.w);
        #else
            #define vertFading(o)
        #endif

        #define SILHOUETTE_NEAR_FADE _SilhouetteFadeParams.x
        #define SILHOUETTE_FAR_FADE _SilhouetteFadeParams.y

        #if defined(SILHOUETTE_FADING_ON)
        #define fragSilhouetteCameraFading(i) \
        float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projectedPosition))); \
        float silhouetteFade = saturate((1.0 / (SILHOUETTE_FAR_FADE - SILHOUETTE_NEAR_FADE)) * ((sceneZ - SILHOUETTE_NEAR_FADE) - i.projectedPosition.z)); \
        finalColor *= silhouetteFade;
        #else
        #define fragSilhouetteCameraFading(i) \
        float silhouetteFade = 1.0f;
        #endif

        float3 GetCenterCameraPosition()
        {
        #if defined(USING_STEREO_MATRICES)
            float3 worldPosition = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2.0;
        #else
            float3 worldPosition = _WorldSpaceCameraPos.xyz;
        #endif
            return worldPosition;
        }

        float4x4 LookAtMatrix(float3 forward, float3 up)
        {
            float3 xAxis = normalize(cross(forward, up));
            float3 yAxis = up;
            float3 zAxis = forward;
            return float4x4(
                xAxis.x, yAxis.x, zAxis.x, 0,
                xAxis.y, yAxis.y, zAxis.y, 0,
                xAxis.z, yAxis.z, zAxis.z, 0,
                0, 0, 0, 1
                );
        }

        float _VRChatCameraMode;

        pixel_t VertShader(vertex_t input)
        {
            float bold = step(input.texcoord1.y, 0);

            float4 vert = input.position;
            vert.x += _VertexOffsetX;
            vert.y += _VertexOffsetY;

            // Display in the canvas normally.
            // float4 vPosition = UnityObjectToClipPos(vert);

        #if defined(USING_STEREO_MATRICES)
            // Face camera, but keep the text upright. Otherwise the text rolls as the player rocks their
            // head and it's sickening.
            float3 cameraPositionWs = GetCenterCameraPosition();
            float3 objectCenterWs = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
            float3 forward = mul(unity_ObjectToWorld, float4(0, 0, 1, 0)).xyz;
            float3 viewDirectionWs = cameraPositionWs - objectCenterWs;
            float3x3 rotation = LookAtMatrix(viewDirectionWs, float3(0, 1, 0));
            float3 positionWs = mul(rotation, length(forward) * vert.xyz) + objectCenterWs.xyz;
            float4 vPosition = mul(UNITY_MATRIX_VP, float4(positionWs, 1.0));
        #else
            // Face camera: based upon: https://en.wikibooks.org/wiki/Cg_Programming/Unity/Billboards
            float3 vScale = float3(length(unity_ObjectToWorld[0].xyz), length(unity_ObjectToWorld[1].xyz), length(unity_ObjectToWorld[2].xyz));
            float4 positionVs = mul(UNITY_MATRIX_MV, float4(0.0, 0.0, 0.0, 1.0 / vScale.x)) + vert;
            float4 vPosition = mul(UNITY_MATRIX_P, positionVs);
        #endif

            float2 pixelSize = vPosition.w;
            pixelSize /= float2(_ScaleX, _ScaleY) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));
            float scale = rsqrt(dot(pixelSize, pixelSize));
            scale *= abs(input.texcoord1.y) * _GradientScale * 1.5;
            // if (UNITY_MATRIX_P[3][3] == 0) scale = lerp(abs(scale) * (1 - _PerspectiveFilter), scale, abs(dot(UnityObjectToWorldNormal(input.normal.xyz), normalize(WorldSpaceViewDir(vert)))));

            float weight = lerp(_WeightNormal, _WeightBold, bold) / 4.0;
            weight = (weight + _FaceDilate) * _ScaleRatioA * 0.5;

            float bias = (.5 - weight) + (.5 / scale);
            float alphaClip = (1.0 - _OutlineWidth * _ScaleRatioA - _OutlineSoftness * _ScaleRatioA);

        #if GLOW_ON
            alphaClip = min(alphaClip, 1.0 - _GlowOffset * _ScaleRatioB - _GlowOuter * _ScaleRatioB);
        #endif

            alphaClip = alphaClip / 2.0 - (.5 / scale) - weight;

        #if (UNDERLAY_ON || UNDERLAY_INNER)
            float4 underlayColor = _UnderlayColor;
            underlayColor.rgb *= underlayColor.a;

            float bScale = scale;
            bScale /= 1 + ((_UnderlaySoftness * _ScaleRatioC) * bScale);
            float bBias = (0.5 - weight) * bScale - 0.5 - ((_UnderlayDilate * _ScaleRatioC) * 0.5 * bScale);

            float x = -(_UnderlayOffsetX * _ScaleRatioC) * _GradientScale / _TextureWidth;
            float y = -(_UnderlayOffsetY * _ScaleRatioC) * _GradientScale / _TextureHeight;
            float2 bOffset = float2(x, y);
        #endif

            // Generate UV for the Masking Texture
            float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
            float2 maskUV = (vert.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);

            // Support for texture tiling and offset
            float2 textureUV = UnpackUV(input.texcoord1.x);
            float2 faceUV = TRANSFORM_TEX(textureUV, _FaceTex);
            float2 outlineUV = TRANSFORM_TEX(textureUV, _OutlineTex);

            pixel_t output = {
                vPosition,
                input.color,
                input.texcoord0,
                float4(alphaClip, scale, bias, weight),
                half4(vert.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy)),
                mul((float3x3)_EnvMatrix, _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, vert).xyz),
            #if (UNDERLAY_ON || UNDERLAY_INNER)
                float4(input.texcoord0 + bOffset, bScale, bBias),
                underlayColor,
            #endif
                float4(faceUV, outlineUV),
            #if defined(SILHOUETTE_FADING_ON) || defined(SOFTPARTICLES_ON) || defined(_FADING_ON)
                float4(0, 0, 0, 0)
            #endif
            };

            vertFading(output);

            return output;
        }

        fixed4 PixShader(pixel_t input) : SV_Target
        {
            float c = tex2D(_MainTex, input.atlas).a;

        #ifndef UNDERLAY_ON
            clip(c - input.param.x);
        #endif

            float	scale = input.param.y;
            float	bias = input.param.z;
            float	weight = input.param.w;
            float	sd = (bias - c) * scale;

            float outline = (_OutlineWidth * _ScaleRatioA) * scale;
            float softness = (_OutlineSoftness * _ScaleRatioA) * scale;

            half4 faceColor = _FaceColor;
            half4 outlineColor = _OutlineColor;

            faceColor.rgb *= input.color.rgb;

            faceColor *= tex2D(_FaceTex, input.textures.xy + float2(_FaceUVSpeedX, _FaceUVSpeedY) * _Time.y);
            outlineColor *= tex2D(_OutlineTex, input.textures.zw + float2(_OutlineUVSpeedX, _OutlineUVSpeedY) * _Time.y);

            faceColor = GetColor(sd, faceColor, outlineColor, outline, softness);

        #if BEVEL_ON
            float3 dxy = float3(0.5 / _TextureWidth, 0.5 / _TextureHeight, 0);
            float3 n = GetSurfaceNormal(input.atlas, weight, dxy);

            float3 bump = UnpackNormal(tex2D(_BumpMap, input.textures.xy + float2(_FaceUVSpeedX, _FaceUVSpeedY) * _Time.y)).xyz;
            bump *= lerp(_BumpFace, _BumpOutline, saturate(sd + outline * 0.5));
            n = normalize(n - bump);

            float3 light = normalize(float3(sin(_LightAngle), cos(_LightAngle), -1.0));

            float3 col = GetSpecular(n, light);
            faceColor.rgb += col * faceColor.a;
            faceColor.rgb *= 1 - (dot(n, light) * _Diffuse);
            faceColor.rgb *= lerp(_Ambient, 1, n.z * n.z);

            fixed4 reflcol = texCUBE(_Cube, reflect(input.viewDir, -n));
            faceColor.rgb += reflcol.rgb * lerp(_ReflectFaceColor.rgb, _ReflectOutlineColor.rgb, saturate(sd + outline * 0.5)) * faceColor.a;
        #endif

        #if UNDERLAY_ON
            float d = tex2D(_MainTex, input.texcoord2.xy).a * input.texcoord2.z;
            faceColor += input.underlayColor * saturate(d - input.texcoord2.w) * (1 - faceColor.a);
        #endif

        #if UNDERLAY_INNER
            float d = tex2D(_MainTex, input.texcoord2.xy).a * input.texcoord2.z;
            faceColor += input.underlayColor * (1 - saturate(d - input.texcoord2.w)) * saturate(1 - sd) * (1 - faceColor.a);
        #endif

        #if GLOW_ON
            float4 glowColor = GetGlowColor(sd, scale);
            faceColor.rgb += glowColor.rgb * glowColor.a;
        #endif

            // Alternative implementation to UnityGet2DClipping with support for softness.
            #if UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
                faceColor *= m.x * m.y;
            #endif

            #if UNITY_UI_ALPHACLIP
                clip(faceColor.a - 0.001);
            #endif

            fixed4 finalColor = faceColor * input.color.a;
            fragSilhouetteCameraFading(input);

            return finalColor;
        }
		ENDCG

		Pass
		{
			ZTest Always

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VertShader
			#pragma fragment PixShader
			#pragma shader_feature __ UNDERLAY_ON UNDERLAY_INNER
			#pragma shader_feature_local SILHOUETTE_FADING_ON

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			ENDCG
		}

		Pass
		{
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VertShader
			#pragma fragment PixShader
			#pragma shader_feature __ BEVEL_ON
			#pragma shader_feature __ UNDERLAY_ON UNDERLAY_INNER
			#pragma shader_feature __ GLOW_ON

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			ENDCG
		}
	}

	Fallback "TextMeshPro/Mobile/Distance Field"
	CustomEditor "TMPro.EditorUtilities.TMP_SDFShaderGUI"
}
