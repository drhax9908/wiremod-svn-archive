AddCSLuaFile('player.lua')

/******************************************************************************\
  Player-Entity support
\******************************************************************************/

registerFunction("eye", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	if(rv1:IsPlayer()) then	return {rv1:GetAimVector().x,rv1:GetAimVector().y,rv1:GetAimVector().z} end
	return {rv1:GetForward().x,rv1:GetForward().y,rv1:GetForward().z}
end)

registerFunction("name", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(rv1:IsPlayer()) then return rv1:Name() else return "" end
end)

registerFunction("steamID", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(rv1:IsPlayer()) then return rv1:SteamID() else return "" end
end)

registerFunction("armor", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then return rv1:Armor() else return 0 end
end)

registerFunction("height", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		local pos = rv1:GetPos()
		local up = rv1:GetUp()
		return rv1:NearestPoint(Vector(pos.x+up.x*100,pos.y+up.y*100,pos.z+up.z*100)).z-rv1:NearestPoint(Vector(pos.x-up.x*100,pos.y-up.y*100,pos.z-up.z*100)).z
	else return 0 end
end)

registerFunction("width", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		local pos = rv1:GetPos()
		local right = rv1:GetRight()
		return rv1:NearestPoint(Vector(pos.x+right.x*100,pos.y+right.y*100,pos.z+right.z*100)).z-rv1:NearestPoint(Vector(pos.x-right.x*100,pos.y-right.y*100,pos.z-right.z*100)).z
	else return 0 end
end)

registerFunction("shootPos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	if(rv1:IsPlayer() or rv1:IsNPC()) then
		rv1 = rv1:GetShootPos()
		return {rv1.x,rv1.y,rv1.z}
	else return {0,0,0} end
end)

registerFunction("isCrouch", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() and rv1:Crouching()) then return 1 else return 0 end
end)

registerFunction("isAlive", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer() and rv1:Alive()) then return 1 end
	if(rv1:IsNPC() and rv1:Health() > 0) then return 1 end
	return 0
end)

registerFunction("frags", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Frags() else return 0 end
end)

registerFunction("team", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Team() else return 0 end
end)

registerFunction("teamname", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local str = team.GetName(rv1)
	if str == nil then return "" end
	return str
end)

registerFunction("weapon", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!rv1 or !rv1:IsValid()) then return nil end
	if(rv1:IsPlayer()) then return rv1:GetActiveWeapon() else return nil end
end)

registerFunction("deaths", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!rv1 or !rv1:IsValid()) then return 0 end
	if(rv1:IsPlayer()) then return rv1:Deaths() else return 0 end
end)

