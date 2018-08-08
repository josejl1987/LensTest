//--------------------------------------------------------------------------------------
// File: Tutorial07.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------


SamplerState samLinear : register( s0 );

cbuffer cbNeverChanges : register( b0 )
{
    matrix View;
};

cbuffer cbChangeOnResize : register( b1 )
{
    matrix Projection;
};

cbuffer cbChangesEveryFrame : register( b2 )
{
    matrix World;
    float4 vMeshColor;
};


//--------------------------------------------------------------------------------------
struct VS_INPUT
{
    float4 Pos : POSITION;
    float2 TexCoord : TEXCOORD0;
    float Diffuse : COLOR;

};

struct VS_OUT
{
	float4	ProjPos		: SV_POSITION;
	float2	TexCoord	: TEXCOORD0;
	float4	ScreenPos	: TEXCOORD1;
    float4 Diffuse : COLOR;
};




//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUT VS( VS_INPUT In )
{
    VS_OUT output = (VS_OUT) 0;
    output.ProjPos = mul(In.Pos, World);
    output.TexCoord = In.TexCoord;
    output.ScreenPos = output.ProjPos;
    output.Diffuse = float4(1.0f, 1.0f, 1.0f, In.Diffuse);
    return output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------

struct PS_OUT
{
	float4	Color		: SV_TARGET;
};

struct PS_IN
{
	float4	ProjPos		: SV_POSITION;
	float2	UV	: TEXCOORD0;
	float4	ScreenPos	: TEXCOORD1;
	float4	Diffuse		: COLOR;
};
Texture2D TexMap : register(t0);
Texture2D TexRte : register(t1);
Texture2D TexBak : register(t2);



PS_OUT PSNormal(PS_IN In)
{
    PS_OUT Out;

    float4 t0, t1, t2, t3;
    

    t0 = TexBak.Sample(samLinear, In.UV);

    Out.Color = t0;
	
    Out.Color.a = 1.0f;
	
    return Out;
}

PS_OUT PSLens(PS_IN In) 
{
	PS_OUT	Out;
	float2	TransTexCoord;
	float2	fDelta;
	float2	fRte;
	float2	fItp;
	float4	t0, t1, t2, t3;
    
    fDelta.x = TexMap.Sample(samLinear, In.UV).g;
	fDelta.y = TexMap.Sample(samLinear, In.UV).r;
    if (TexMap.Sample(samLinear, In.UV).a == 1.0)
    {
		fDelta.x = -fDelta.x;
	}
    if (TexMap.Sample(samLinear, In.UV).b == 1.0)
    {
		fDelta.y = -fDelta.y;
	}
    fRte.x = TexRte.Sample(samLinear, In.UV).a;
    fRte.y = TexRte.Sample(samLinear, In.UV).b;
	
	fDelta.x = (fDelta.x * 128.0) / 1280.0;
	fDelta.y = (fDelta.y * 128.0) /  720.0;
	
	TransTexCoord.x = ((1.0f + In.ScreenPos.x / In.ScreenPos.w) * 0.5f) + fDelta.x;
	TransTexCoord.y = ((1.0f - In.ScreenPos.y / In.ScreenPos.w) * 0.5f) + fDelta.y;
	
	fItp.x = 1.0f / 1280.0f;
	fItp.y = 1.0f /  720.0f;
    t0 = TexBak.Sample(samLinear, TransTexCoord);
    t1 = TexBak.Sample(samLinear, TransTexCoord + float2(fItp.x, 0));
    t2 = TexBak.Sample(samLinear, TransTexCoord + float2(0, fItp.y));
    t3 = TexBak.Sample(samLinear, TransTexCoord + float2(fItp.x, fItp.y));

	Out.Color = lerp(lerp(t0, t1, fRte.x), lerp(t2, t3, fRte.x), fRte.y);
	
	Out.Color.a = 1.0f;
	
	return Out;
}

technique11 FeatureLevel11
{

    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0,
                                      VS()));
        SetPixelShader(CompileShader(ps_5_0,
                                     PSNormal()));
    }
    pass p1
    {
        SetVertexShader(CompileShader(vs_5_0,
                                      VS()));
        SetPixelShader(CompileShader(ps_5_0,
                                     PSLens()));
    }
}