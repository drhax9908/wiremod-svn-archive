AddCSLuaFile('entity.lua')

/******************************************************************************\
  Entity support
\******************************************************************************/

registerType("entity", "e", nil)

/******************************************************************************/

function validEntity(entity)
	return (entity and type(entity)!="number" and entity:IsValid())
end

function validPhysics(entity)
	if (entity and type(entity)!="number" and entity:IsValid()) then
		local phys = entity:GetPhysicsObject()
		return (phys and phys:IsValid())
	end
	return false
end

function isOwner(self, entity)
	return (getOwner(self, entity) == self.player || GetConVarNumber("wire_expression2_restricted") == 0)
end

function getOwner(self, entity)
	if(entity == self.entity) then return self.player end
	if(entity.OnDieFunctions == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate.Args == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate.Args[1] != nil) then return entity.OnDieFunctions.GetCountUpdate.Args[1] end
	if(entity.OnDieFunctions.undo1 == nil) then return nil end
	if(entity.OnDieFunctions.undo1.Args == nil) then return nil end
	if(entity.OnDieFunctions.undo1.Args[2] != nil) then return entity.OnDieFunctions.undo1.Args[2] end
	return nil
end

// compatibility
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
	if validEntity(rv1) then return 1 else return 0 end
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
	local ent = ents.GetByIndex(rv1)
	if(!validEntity(ent)) then return nil end
	return ent
end)

registerFunction("id", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:EntIndex()
end)

/******************************************************************************/
// Functions getting string

registerFunction("type", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	return rv1:GetClass()
end)

registerFunction("model", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	return rv1:GetModel()
end)

registerFunction("owner", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return nil end
	return getOwner(self, rv1)
end)

/******************************************************************************/
// Functions getting vector
registerFunction("pos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:GetPos()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("forward", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:GetForward()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("right", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:GetRight()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("up", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:GetUp()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("vel", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:GetVelocity()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("velL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:WorldToLocal(rv1:GetVelocity() + rv1:GetPos())
	return {vec.x,vec.y,vec.z}
end)

registerFunction("angVel", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	local vec = phys:GetAngleVelocity()
	return {vec.y,vec.z,vec.x}
end)


/******************************************************************************/
// Functions  using vector getting vector
registerFunction("toWorld", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:LocalToWorld(Vector(rv2[1],rv2[2],rv2[3]))
	return {vec.x,vec.y,vec.z}
end)

registerFunction("toLocal", "e:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return {0,0,0} end
	local vec = rv1:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	return {vec.x,vec.y,vec.z}
end)

/******************************************************************************/
// Functions getting number
registerFunction("health", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:Health()
end)

registerFunction("radius", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	return rv1:BoundingRadius()
end)

// bearing & elevation thanks to Gwahir
registerFunction("bearing", "e:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self,op2)
	if(!validEntity(rv1)) then return 0 end
	rv1 = rv1:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	if(math.abs(rv1.x) < delta) then return 0 end
	local ret = math.atan(rv1.y / rv1.x)
	if(rv1.x < 0) then if(ret < 0) then ret = -math.pi - ret else ret = math.pi - ret end
	else ret = -ret end
	return math.deg(ret) //changed to degress because it is used by most things
end)

registerFunction("elevation", "e:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self,op2)
	if(!validEntity(rv1)) then return 0 end
	rv1 = rv1:WorldToLocal(Vector(rv2[1],rv2[2],rv2[3]))
	local len = math.sqrt(rv1.x*rv1.x + rv1.y*rv1.y + rv1.z*rv1.z)
	if(len < delta) then return 0 end
	return math.deg(math.asin(rv1.z / len)) //changed to degress because it is used by most things
end)

registerFunction("mass", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return 0 end
	local phys = rv1:GetPhysicsObject()
	return phys:GetMass()
end)

registerFunction("massCenter", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	local offset = phys:GetMassCenter()
	local vec = rv1:LocalToWorld(offset)
	return {vec.x,vec.y,vec.z}
end)

registerFunction("massCenterL", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validPhysics(rv1)) then return {0,0,0} end
	local phys = rv1:GetPhysicsObject()
	local vec = phys:GetMassCenter()
	return {vec.x,vec.y,vec.z}
end)

registerFunction("setMass", "n", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if(!validPhysics(self.entity)) then return end
	local mass = math.Clamp(rv1, 0.001, 50000)
	local phys = self.entity:GetPhysicsObject()
	phys:SetMass(mass)
end)

registerFunction("setMass", "e:n", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return end
	if(!isOwner(self, rv1)) then return end
	if(rv1:IsPlayer()) then return end
	local mass = math.Clamp(rv2, 0.001, 50000)
	local phys = rv1:GetPhysicsObject()
	phys:SetMass(mass)
end)

/******************************************************************************/
// Functions getting boolean/number
registerFunction("isPlayer", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsPlayer() then return 1 else return 0 end
end)

registerFunction("isNPC", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsNPC() then return 1 else return 0 end
end)

registerFunction("isVehicle", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsVehicle() then return 1 else return 0 end
end)

registerFunction("isWorld", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsWorld() then return 1 else return 0 end
end)

registerFunction("isOnGround", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:IsOnGround() then return 1 else return 0 end
end)

registerFunction("isUnderWater", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if rv1:WaterLevel() > 0 then return 1 else return 0 end
end)

/******************************************************************************/
// Functions getting angles

registerFunction("angles", "e:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	local ang = rv1:GetAngles()
	return {ang.p,ang.y,ang.r}
end)

/******************************************************************************/

registerFunction("setMaterial", "e:s", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2)
    local entity = checkEntity(rv1)
    if(!entity || !rv1:IsValid()) then return end
        rv1:SetMaterial(rv2)
    return
end)

/******************************************************************************/

registerFunction("isPlayerHolding", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if rv1:IsPlayerHolding() then return 1 else return 0 end
end)
 
registerFunction("isOnFire", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if rv1:IsOnFire() then return 1 else return 0 end
end)
 
registerFunction("isOnGround", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if rv1:IsOnGround() then return 1 else return 0 end
end)
 
registerFunction("isWeapon", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if rv1:IsWeapon() then return 1 else return 0 end
end)
 
registerFunction("inVehicle", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if(rv1:IsPlayer() and rv1:InVehicle()) then return 1 else return 0 end
end)
 
registerFunction("timeConnected", "e:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1)) then return 0 end
    if(rv1:IsPlayer()) then return rv1:TimeConnected() else return 0 end
end)

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
	phys:ApplyForceOffset(Vector(rv1[1],rv1[2],rv1[3]), Vector(rv2[1],rv2[2],rv2[3]))
end)

registerFunction("applyForce", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if(!validPhysics(rv1)) then return nil end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()
	phys:ApplyForceCenter(Vector(rv2[1],rv2[2],rv2[3]))
end)

registerFunction("applyOffsetForce", "e:vv", "", function(self,args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
	if(!validPhysics(rv1)) then return nil end
	if(!isOwner(self, rv1)) then return nil end
	local phys = rv1:GetPhysicsObject()
	phys:ApplyForceOffset(Vector(rv2[1],rv2[2],rv2[3]), Vector(rv3[1],rv3[2],rv3[3]))
end)

/******************************************************************************/

registerFunction("lockPod", "e:n", "", function(self,args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
    if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
    if(rv2 != 0) then
		rv1:Fire("Lock", "", 0)
    else
		rv1:Fire("Unlock", "", 0)
    end
end)

registerFunction("killPod", "e:", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
    local ply = rv1:GetDriver()
    if(ply:IsValid()) then ply:Kill() end
end)

registerFunction("ejectPod", "e:", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if(!validEntity(rv1) || !rv1:IsVehicle()) then return end
    local ply = rv1:GetDriver()
    if(ply:IsValid()) then ply:ExitVehicle() end
end)

/******************************************************************************/

registerFunction("aimEntity", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return nil end
	if(rv1:IsPlayer()) then
		local ent = rv1:GetEyeTrace().Entity
		if (ent:IsValid()) then return ent end
	else return nil end
end)

registerFunction("aimPos", "e:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return {0,0,0} end
	if(rv1:IsPlayer()) then
		local vec = rv1:GetEyeTrace().HitPos
		return vec
	else return {0,0,0} end
end)


/******************************************************************************/

registerFunction("driver", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return nil end
	return rv1:GetDriver()
end)

registerFunction("passenger", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1) || !rv1:IsVehicle()) then return nil end
	return rv1:GetPassenger()
end)

registerFunction("hint", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(string.find(rv1,string.char(34)) != nil) then return end
	self.player:SendLua("GAMEMODE:AddNotify(\"" .. rv1 .. "\", NOTIFY_GENERIC ," .. math.Clamp(rv2,0.7,7) .. ");")
end)

registerFunction("hintDriver", "e:sn", "n", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if (string.find(rv2,string.char(34)) != nil) then return 0 end
	if(!validEntity(rv1)) then return nil end
	if(!rv1:IsVehicle()) then return 0 end
	if(!isOwner(self, rv1)) then return 0 end
	local driver = rv1:GetDriver()
	if(!validEntity(driver)) then return nil end
	driver:SendLua("GAMEMODE:AddNotify(\"" .. rv2 .. "\", NOTIFY_GENERIC ," .. math.Clamp(rv3,0.7,7) .. ");")
    return 1
end)