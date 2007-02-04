

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false




function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self.Entity:GetNetworkedBool( "On" )
end

function ENT:StartSound( filename, volume )
	util.PrecacheSound( filename )
	self.Entity:EmitSound( filename, volume or 100, 100)
end

function ENT:StopSound( filename )
	self.Entity:StopSound( filename )
end

