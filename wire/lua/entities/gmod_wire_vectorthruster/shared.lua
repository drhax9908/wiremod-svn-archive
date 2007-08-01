

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
	self.Entity:SetNetworkedString( "Effect", name )
end
function ENT:GetEffect()
	return self.Entity:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBool( "on", boolon, true )
end
function ENT:IsOn()
	return self.Entity:GetNetworkedBool( "on" )
end


/*function ENT:SetToWorld( b )
	self.Entity:SetNetworkedBool( 2, b, true )
end
function ENT:IsToWorld()
	return self.Entity:GetNetworkedBool( 2 )
end*/


function ENT:SetMode( v )
	self.Entity:SetNetworkedInt( 1, v, true )
end
function ENT:GetMode()
	return self.Entity:GetNetworkedInt( 1 )
end


function ENT:SetOffset( v )
	--self.Entity:SetNetworkedBeamVector( "Offset", v, true )
	self.Entity:SetNetworkedInt( "x", v.x * 100, true )
	self.Entity:SetNetworkedInt( "y", v.y * 100, true )
	self.Entity:SetNetworkedInt( "z", v.z * 100, true )
end
function ENT:GetOffset()
	--return self.Entity:GetNetworkedBeamVector( "Offset" )
	return Vector(
				self.Entity:GetNetworkedInt( "x" ) / 100,
				self.Entity:GetNetworkedInt( "y" ) / 100,
				self.Entity:GetNetworkedInt( "z" ) / 100
			)
end
