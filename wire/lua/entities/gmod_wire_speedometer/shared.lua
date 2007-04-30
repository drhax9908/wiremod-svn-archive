ENT.Type 		= "anim"
ENT.Base 		= "base_wire_entity"

ENT.PrintName	= "Speedometer (Wire)"
ENT.Author		= "Erkle"
ENT.Contact		= "ErkleMad@hotmail.com"


function ENT:GetXYZMode()
	return self.Entity:GetNetworkedBool( 0 )
end

function ENT:SetXYZMode( XYZMode )
	return self.Entity:SetNetworkedBool( 0, XYZMode )
end
