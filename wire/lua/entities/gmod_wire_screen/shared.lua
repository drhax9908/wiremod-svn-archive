ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetDisplayA( float )
	self.Entity:SetNetworkedFloat( "DisA", float )
end

function ENT:SetDisplayB( float )
	self.Entity:SetNetworkedFloat( "DisB", float )
end

function ENT:GetDisplayA( )
	return self.Entity:GetNetworkedFloat( "DisA" )
end

function ENT:GetDisplayB( )
	return self.Entity:GetNetworkedFloat( "DisB" )
end
