

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetOn( bOn )
	self.Entity:SetNetworkedBool( "OnOff", bOn, true )
end
function ENT:IsOn()
	return self.Entity:GetNetworkedBool( "OnOff" )
end
