

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Vector Thruster"
ENT.Author			= "TAD2020"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
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


function ENT:NetSetForce( force )
	self.Entity:SetNetworkedInt(4, math.floor(force*100))
end
function ENT:NetGetForce()
	return self.Entity:GetNetworkedInt(4)/100
end


local Limit = .1
local LastTime = 0
function ENT:NetSetMul( mul )
	--self.Entity:SetNetworkedBeamInt(5, math.floor(mul*100))
	if (CurTime() > LastTime + Limit) then
		self.Entity:SetNetworkedInt(5, math.floor(mul*100))
		LastTime = CurTime()
	end
end
function ENT:NetGetMul()
	--return self.Entity:GetNetworkedBeamInt(5)/100
	return self.Entity:GetNetworkedInt(5)/100
end


function ENT:GetOverlayText()
	
	local txt = "Thrust = " 
	local force = self:NetGetForce()
	if (self:IsOn()) then
		txt = txt .. ( force * self:NetGetMul() )
	else
		txt = txt .. "off"
	end
	txt = txt .. "\nMul: " .. force .. "\nMode: "
	
	local mode = self:GetMode()
	if (self.Mode == 0) then
		txt = txt .. "XYZ Local"
	elseif (self.Mode == 1) then
		txt = txt .. "XYZ World"
	elseif (self.Mode == 2) then
		txt = txt .. "XY Local, Z World"
	end
	
	if (not SinglePlayer()) then
		local PlayerName = self:GetPlayerName()
		txt = txt .. "\n(" .. PlayerName .. ")"
	end
	
	return txt
end
