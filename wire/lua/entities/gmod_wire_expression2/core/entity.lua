AddCSLuaFile('entity.lua')

/******************************************************************************\
  Entity support
\******************************************************************************/

registerType("entity", "e", nil)

/******************************************************************************/

function checkEntity(entity)
	if(!entity or type(entity)=="number" or !entity:IsValid()) then return nil end
	return entity
end

/******************************************************************************/
// Functions using operators

registerOperator("ass", "e", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "e", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if checkEntity(rv1) then return 1 else return 0 end
end)

registerOperator("eq", "ee", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 == rv2 then return 1 else return 0 end
end)

registerOperator("neq", "ee", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 != rv2 then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("entity", "n", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local entity = checkEntity(ents.GetByIndex(rv1))
	if !entity then return nil end
	return entity
end)

registerFunction("id", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local entity = checkEntity(rv1)
	if !entity then return 0 end
	return rv1:EntIndex()
end)

/******************************************************************************/
// Functions getting string

registerFunction("type", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return "" end
	return rv1:GetClass()
end)

registerFunction("model", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return "" end
	return rv1:GetModel()
end)

registerFunction("owner", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return nil end
	return rv1.OnDieFunctions.GetCountUpdate.Args[1]
end)

/******************************************************************************/
// Functions getting vector
registerFunction("pos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:GetPos()
	return {entity.x,entity.y,entity.z}
end)

registerFunction("forward", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:GetForward()
	return {entity.x,entity.y,entity.z}
end)

registerFunction("right", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = rv1:GetRight()
	return {entity.x,entity.y,entity.z}
end)

registerFunction("up", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:GetUp()
	return {entity.x,entity.y,entity.z}
end)

registerFunction("vel", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() end
	entity = entity:GetVelocity()
	return {entity.x,entity.y,entity.z}
end)

registerFunction("velL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() end
	local vel = entity:GetVelocity()
	local angle = entity:GetAngles()
	vel = Vector(vel.x,vel.y,vel.z)
	vel:Rotate(Angle(-angle.p,-angle.y,-angle.r))
	return {vel.x,vel.y,vel.z}
end)

registerFunction("angVel", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() else return {0,0,0} end
	local entity = entity:GetAngleVelocity()
	return {entity.y,entity.z,entity.x}
end)


/******************************************************************************/
// Functions  using vector getting vector
registerFunction("toWorld", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:LocalToWorld(Vector(rv2[1],rv2[2],rv2[3]))
	return {entity.x,entity.y,entity.z}
end)

registerFunction("toLocal", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	return {entity.x,entity.y,entity.z}
end)

/******************************************************************************/
// Functions getting number
registerFunction("health", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	return rv1:Health()
end)

registerFunction("radius", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	return rv1:BoundingRadius( )
end)

// bearing & elevation thanks to Gwahir
registerFunction("bearing", "e:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self,op2)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	entity = entity:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	if(math.abs(entity.x) < delta) then return 0 end
	local ret = math.atan(entity.y / entity.x)
	if(entity.x < 0) then if(ret < 0) then ret = -math.pi - ret else ret = math.pi - ret end
	else ret = -ret end
	return math.deg(ret) //changed to degress because it is used by most things
end)

registerFunction("elevation", "e:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self,op2)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	local len = math.sqrt(entity.x*entity.x + entity.y*entity.y + entity.z*entity.z)
	if(len < delta) then return 0 end
	return math.deg(math.asin(entity.z / len)) //changed to degress because it is used by most things
end)

registerFunction("mass", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	local phys = entity:GetPhysicsObject()
	if phys == nil then return 0 end
	return phys:GetMass()
end)

registerFunction("massCenter", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() end
	local offset = entity:GetMassCenter()
	local pos = entity:LocalToWorld(offset)
	return {pos.x,pos.y,pos.z}
end)

registerFunction("massCenterL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() end
	entity = entity:GetMassCenter()
	return {entity.x,entity.y,entity.z}
end)

/******************************************************************************/
// Functions getting boolean/number
registerFunction("isPlayer", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:IsPlayer() then return 1 else return 0 end
end)

registerFunction("isNPC", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:IsNPC() then return 1 else return 0 end
end)

registerFunction("isVehicle", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:IsVehicle() then return 1 else return 0 end
end)

registerFunction("isWorld", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:IsWorld() then return 1 else return 0 end
end)

registerFunction("isOnGround", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:IsOnGround() then return 1 else return 0 end
end)

registerFunction("isUnderWater", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return 0 end
	if rv1:WaterLevel() > 0 then return 1 else return 0 end
end)

/******************************************************************************/
// Functions getting angles

registerFunction("angles", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local entity = checkEntity(rv1)
	if(!entity) then return {0,0,0} end
	entity = entity:GetAngles()
	return {entity.p,entity.y,entity.r}
end)

/******************************************************************************/

registerFunction("setColor", "e:nnn", "", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	if self.player != rv1:GetOwner() then return end
	rv1:SetColor(math.Clamp(rv2, 0, 255), math.Clamp(rv3, 0, 255), math.Clamp(rv4, 0, 255), 255)
end)

/*
// Functions getting color
registerFunction("getColor", "e:", "c", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!rv1 or !rv1:IsValid()) then return 0 end
	return rv1:GetColor()
end)
*/

/******************************************************************************/

registerFunction("applyForce", "v", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	local phys = self.entity:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(rv1[1],rv1[2],rv1[3]))
end)

registerFunction("applyOffsetForce", "vv", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	local phys = self.entity:GetPhysicsObject()
	entity:ApplyForceOffset(Vector(rv1[1],rv1[2],rv1[3]), Vector(rv2[1],rv2[2],rv2[3]))
end)

/*registerFunction("applyForce", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if(entity != self.entity) then return end
	if(entity:GetMoveType() != 6) then return end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() else return end
	local Vec = Vector(rv2[1],rv2[2],rv2[3])
	entity:ApplyForceCenter(Vec)
end)

registerFunction("applyOffsetForce", "e:vv", "", function(self,args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
	local entity = checkEntity(rv1)
	if(!entity) then return end
	if(entity != self.entity) then return end
	if(entity:GetMoveType() != 6) then return end
	if(entity:GetPhysicsObject()) then entity = entity:GetPhysicsObject() else return end
	local Vec1 = Vector(rv2[1],rv2[2],rv2[3])
	local Vec2 = Vector(rv3[1],rv3[2],rv3[3])
	entity:ApplyForceOffset(Vec1,Vec2)
end)*/
