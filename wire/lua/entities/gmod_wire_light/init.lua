
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Light"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.R, self.G, self.B = 0, 0, 0
	self.Entity:SetColor( 0, 0, 0, 255 )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Red", "Green", "Blue" } )
end

function ENT:OnRemove()
	if (!self.RadiantComponent) then return end
	if not self.RadiantComponent:IsValid() then return end
	self.RadiantComponent:Fire("TurnOff","","0")
end

function ENT:DirectionalOn()
	
	if (self.DirectionalComponent) then
		self:DirectionalOff()
	end

	local flashlight = ents.Create("effect_flashlight")
		flashlight:SetPos( self.Entity:GetPos() )
		flashlight:SetAngles( (self.Entity:GetAngles()+Vector( 0, 0, 180 )) )
		flashlight:SetParent( self.Entity )
		flashlight:SetColor( self.R, self.G, self.B, 255 )
	flashlight:Spawn()

	self.DirectionalComponent = flashlight
end

function ENT:DirectionalOff()

	if (!self.DirectionalComponent) then return end

	self.DirectionalComponent:Remove()
	self.DirectionalComponent = nil
end


function ENT:RadiantOn()
	
	if (self.RadiantComponent) then
		self.RadiantComponent:Fire("TurnOn","","0")
	else
		local dynlight = ents.Create( "light_dynamic" )
		dynlight:SetPos( self.Entity:GetPos() )
		local dynlightpos = dynlight:GetPos()+Vector( 0, 0, 10 )
		dynlight:SetPos( dynlightpos )
		dynlight:SetKeyValue( "_light", self.R .. " " .. self.G .. " " .. self.B .. " " .. 255 )
		dynlight:SetKeyValue( "style", 0 )
		dynlight:SetKeyValue( "distance", 255 )
		dynlight:SetKeyValue( "brightness", 5 )
		dynlight:SetParent( self.Entity )
		dynlight:Spawn()
		self.RadiantComponent = dynlight
	end
	self.RadiantState = 1

end

function ENT:RadiantOff()

	if (!self.RadiantComponent) then return end
	if not self.RadiantComponent:IsValid() then return end
	self.RadiantComponent:Fire("TurnOff","","0")

	self.RadiantState = 0
--	self.RadiantComponent:Remove()
--	self.RadiantComponent = nil
end


function ENT:TriggerInput(iname, value)
	local R,G,B = self.R, self.G, self.B
	if (iname == "Red") then
		R = value
	elseif (iname == "Green") then
		G = value
	elseif (iname == "Blue") then
		B = value
	end
	self:ShowOutput( R, G, B )
end

function ENT:Setup(directional, radiant)
	self.Directional = directional
	self.Radiant = radiant
	self.RadiantState = 0
	if (self.Directional) then
		if (!self.DirectionalComponent) then
			self:DirectionalOn()
		end
	else
		if (self.DirectionalComponent) then
			self:DirectionalOff()
		end
	end
	if (self.Radiant) then
		if (self.RadiantState == 0) then
			self:RadiantOn()
		end
	else
		if (self.RadiantState) then
			self:RadiantOff()
		end
	end

end

function ENT:ShowOutput( R, G, B )
	if ( R ~= self.R or G ~= self.G or B ~= self.B ) then
		if (((R + G) + B) != 0) then
			if (self.Directional) then
				if (!self.DirectionalComponent) then
					self:DirectionalOn()
				end
				self.DirectionalComponent:SetColor( R, G, B, 255 )
			end
			if (self.Radiant) then
				if (self.RadiantState == 0) then
					self:RadiantOn()
				end
				self.RadiantComponent:SetColor( R, G, B, 255 )
			end
		else
			self:DirectionalOff()
			self:RadiantOff()
		end
		self:SetOverlayText( "Light: Red=" .. R .. " Green:" .. G .. " Blue:" .. B )
		self.R, self.G, self.B = R, G, B
		self.Entity:SetColor( R, G, B, 255 )
	end
end
