
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Output"

local MODEL = Model("models/jaanus/wiretool/wiretool_output.mdl")


function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self:SetOn( false )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end


function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if ((value > 0) ~= self:IsOn()) then
			self:Switch(not self:IsOn(), self:GetPlayer())
		end
	end
end


function ENT:Switch( on, ply )
	local plyindex 	= self:GetPlayerIndex()
	local key 		= self:GetKey()
	
	if (not key) then return end
	
	if (on) then
		numpad.Activate( ply, _, {key}, plyindex )
	else
		numpad.Deactivate( ply, _, {key}, plyindex )
	end

	self:SetOn(on)
end


function ENT:SetKey( key )
	self.Key = key
end

function ENT:GetKey()
	return self.Key
end

function ENT:SetOn( on )
	self.On = on
end

function ENT:IsOn()
	return self.On
end
