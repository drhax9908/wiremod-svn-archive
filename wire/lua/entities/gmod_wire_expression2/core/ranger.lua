AddCSLuaFile('ranger.lua')

/******************************************************************************\
  Built-in Ranger support v1.7
\******************************************************************************/

//----------------//
//--Function--//
//----------------//

local function ranger(self, type, range, p1, p2)
	local trace = {}
	local default = self.data['rangerdefault']
	self.data['rangerdefault'] = 1
	local world = self.data['rangerworld']
	self.data['rangerworld']=0
	local water = self.data['rangerwater']
	self.data['rangerwater']=0
	trace.start = self.entity:GetPos()
	if (type==3) then
		trace.start = Vector( p1[1], p1[2], p1[3] )
		trace.endpos = trace.start + Vector( p2[1], p2[2], p2[3] )*range
	elseif (type==2) then
		if p1!=p2 then
		range = math.sqrt(math.pow(p1[1]-p2[1],2)+math.pow(p1[2]-p2[2],2)+math.pow(p1[3]-p2[3],2))
		else
		range = 0
		end
		trace.start = Vector( p1[1], p1[2], p1[3] )
		trace.endpos = Vector( p2[1], p2[2], p2[3] )
	elseif ((type==1 && p1!=0) || (type==1 && p2!=0)) then
		local zoff = math.cos(math.rad(p1))*range
		local yoff = math.sin(math.rad(p1))*range
		local xoff = math.cos(math.rad(p2+270))*zoff*(-1)
		zoff = math.sin(math.rad(p2+270))*zoff*(-1)
		trace.endpos = self.entity:LocalToWorld(Vector(xoff,yoff,zoff))
	elseif ((type==0 && p1!=0) || (type==0 && p2!=0)) then
		local skew = Vector(p1, p2, 1)
			print(skew)
		skew = skew*(range/skew:Length())
			print(skew)
		local beam_x = self.entity:GetRight()*skew.x
		local beam_y = self.entity:GetForward()*skew.y
		local beam_z = self.entity:GetUp()*skew.z
			print(beam_x) print(beam_y) print(beam_z)
		trace.endpos = trace.start + beam_x + beam_y + beam_z
	else
		trace.endpos = trace.start + self.entity:GetUp()*range
	end
	trace.filter = { self.entity }
	if water==1 then trace.mask = -1 end
	trace = util.TraceLine(trace)
	local Entity = nil
	local HitPos = trace.HitPos
	local Hit = 0
	local HitNormal = trace.HitNormal
	if (trace.Hit) then Hit=1 end
	if (!checkEntity(trace.Entity)) then
		if (world!=0) then
			range = range*default
		end
	else
		Entity=trace.Entity
	end
	if (trace.Hit) then
		return {trace.Fraction*range,HitPos,Entity,Hit,HitNormal}
	else
		return {range*default,HitPos,Entity,Hit,HitNormal}
	end
end

/******************************************************************************/

registerType("ranger", "xrd", {})

/******************************************************************************/

registerOperator("ass", "xrd", "xrd", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerFunction("rangerHitWater", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1!=0 then self.data['rangerwater']=1 end
end)

registerFunction("rangerIgnoreWorld", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1!=0 then self.data['rangerworld']=1 end
end)

registerFunction("rangerDefaultZero", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    if rv1!=0 then self.data['rangerdefault']=0 end
end)


registerFunction("ranger", "n", "xrd", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return ranger(self, 0, rv1, 0, 0)
end)

registerFunction("ranger", "nnn", "xrd", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    return ranger(self, 0, rv1, rv2, rv3)
end)

registerFunction("rangerAngle", "nnn", "xrd", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    return ranger(self, 1, rv1, rv2, rv3)
end)

registerFunction("rangerOffset", "vv", "xrd", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    return ranger(self, 2, 0, rv1, rv2)
end)

registerFunction("rangerOffset", "nvv", "xrd", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    return ranger(self, 3, rv1, rv2, rv3)
end)

registerFunction("distance","xrd:","n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return rv1[1]
end)

registerFunction("position", "xrd:", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return rv1[2]
end)

registerFunction("entity", "xrd:", "e", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return rv1[3]
end)

registerFunction("hit", "xrd:", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return rv1[4]
end)

registerFunction("hitNormal", "xrd:", "v", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
    return rv1[5]
end)

/******************************************************************************/

registerCallback("construct", function(self)
	self.data['rangerwater'] = 0
	self.data['rangerworld'] = 0
	self.data['rangerdefault'] = 1
end)

registerCallback("postexecute", function(self)
	if (self.data['rangerwater'] != 0) then self.data['rangerwater'] = 0 end
	if (self.data['rangerworld'] != 0) then self.data['rangerworld'] = 0 end
	if (self.data['rangerdefault'] != 1) then self.data['rangerdefault'] = 1 end
end)