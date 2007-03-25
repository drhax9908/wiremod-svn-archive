
include('shared.lua')

local matLight 		= Material( "sprites/light_ignorez" )
local matBeam		= Material( "effects/lamp_beam" )

ENT.RenderGroup 	= RENDERGROUP_BOTH

function ENT:Initialize()

	self.PixVis = util.GetPixelVisibleHandle()
	
end

/*---------------------------------------------------------
   Name: Draw
---------------------------------------------------------*/
function ENT:Draw()

	self.BaseClass.Draw( self )
	
	Wire_Render(self.Entity)
	
end

/*---------------------------------------------------------
   Name: DrawTranslucent
   Desc: Draw translucent
---------------------------------------------------------*/
function ENT:DrawTranslucent()
	
	local LightNrm = self.Entity:GetAngles():Up()
	local ViewDot = EyeVector():Dot( LightNrm )
	local r, g, b, a = self.Entity:GetColor()
	local LightPos = self.Entity:GetPos() + LightNrm * -6
	
	// glow sprite
	/*
	render.SetMaterial( matBeam )
	
	local BeamDot = BeamDot = 0.25
	
	render.StartBeam( 3 )
		render.AddBeam( LightPos + LightNrm * 1, 128, 0.0, Color( r, g, b, 255 * BeamDot) )
		render.AddBeam( LightPos - LightNrm * 100, 128, 0.5, Color( r, g, b, 64 * BeamDot) )
		render.AddBeam( LightPos - LightNrm * 200, 128, 1, Color( r, g, b, 0) )
	render.EndBeam()
	*/

	if ( ViewDot < 0 ) then return end
	
	render.SetMaterial( matLight )
	local Visibile	= util.PixelVisible( LightPos, 16, self.PixVis )	
	local Size = math.Clamp( 512 * (1 - Visibile*ViewDot),128, 512 )
	
	local Col = Color( r, g, b, 200*Visibile*ViewDot )
	
	render.DrawSprite( LightPos, Size, Size, Col, Visibile * ViewDot )
	
end