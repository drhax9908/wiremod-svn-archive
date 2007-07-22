

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Vector Thruster"
ENT.Author			= "TAD2020"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= true
ENT.AdminSpawnable		= false




function ENT:SetEffect( name )
	self.Entity:SetNetworkedBeamString( "Effect", name )
end

function ENT:GetEffect( name )
	return self.Entity:GetNetworkedBeamString( "Effect" )
end


function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBeamBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self.Entity:GetNetworkedBeamBool( "On" )
end

function ENT:SetOffset( v )
	self.Entity:SetNetworkedBeamVector( "Offset", v, true )
end

function ENT:GetOffset( name )
	return self.Entity:GetNetworkedBeamVector( "Offset" )
end
