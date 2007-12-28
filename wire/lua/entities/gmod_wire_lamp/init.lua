
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Lamp"

local MODEL = Model( "models/props_wasteland/prison_lamp001c.mdl" )

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	--TODO: Fix for gmod2007
	self.flashlight = ents.Create("effect_flashlight")
	self.flashlight:SetPos( self.Entity:GetPos() )
	self.flashlight:SetAngles( self.Entity:GetAngles() )
	self.flashlight:SetParent( self.Entity )
	self.flashlight:SetColor( self.Entity:GetVar( "lightr", 255 ), self.Entity:GetVar( "lightg", 255 ), self.Entity:GetVar( "lightb", 255 ), 255 )
	self.flashlight:Spawn()
	
	local phys = self.Entity:GetPhysicsObject()
	
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	self.r = self.Entity:GetVar( "lightr", 255 )
	self.g = self.Entity:GetVar( "lightg", 255 )
	self.b = self.Entity:GetVar( "lightb", 255 )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Red", "Green", "Blue" })
	
end

function ENT:Setup( r, g, b )    

	self:SetOverlayText( "Red:" .. r .. " Green:" .. g .. " Blue" .. b )
	
end
	


/*---------------------------------------------------------
   Name: Sets the color of the light
---------------------------------------------------------*/
function ENT:SetLightColor( r, g, b )

	self.Entity:SetVar( "lightr", r )
	self.Entity:SetVar( "lightg", g )
	self.Entity:SetVar( "lightb", b )
	
	self.Entity:SetColor( r, g, b, 255 )

end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
	self.Entity:TakePhysicsDamage( dmginfo )
end


/*---------------------------------------------------------
   Name: Use
---------------------------------------------------------*/
function ENT:Use( activator, caller )

end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if (iname == "Red") then
		self.r = value
	elseif (iname == "Green") then
	    self.g = value
	elseif (iname == "Blue") then
		self.b = value
	end
	self:SetLightColor( self.r, self.g, self.b)
	self.flashlight:SetColor( self.Entity:GetVar( "lightr", 255 ), self.Entity:GetVar( "lightg", 255 ), self.Entity:GetVar( "lightb", 255 ), 255 )
	self:SetOverlayText( "Red:" .. self.r .. " Green:" .. self.g .. " Blue" .. self.b )
end
	


function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

include('shared.lua')


function MakeWireLamp( pl, Pos, Ang, r, g, b, Vel, aVel, frozen )

	if ( !pl:CheckLimit( "wire_lamps" ) ) then return false end

	local wire_lamp = ents.Create( "gmod_wire_lamp" )
	if (!wire_lamp:IsValid()) then return end
		wire_lamp:SetPos( Pos )
		wire_lamp:SetAngles( Ang )
		wire_lamp:SetLightColor( r, g, b )
	wire_lamp:Spawn()

	wire_lamp:Setup( r, g, b )
	wire_lamp:SetPlayer( pl )


	if (wire_lamp:GetPhysicsObject():IsValid()) then
		Phys = wire_lamp:GetPhysicsObject()
		if Vel then Phys:SetVelocity(Vel) end
		if Vel then Phys:AddAngleVelocity(aVel) end
		Phys:EnableMotion(frozen != true)
	end
	
	pl:AddCount( "wire_lamps", wire_lamp )
	pl:AddCleanup( "wire_lamp", wire_lamp )
	
	return wire_lamp
end

duplicator.RegisterEntityClass( "gmod_wire_lamp", MakeWireLamp, "Pos", "Ang", "lightr", "lightg", "lightb", "Vel", "aVel", "frozen" )
