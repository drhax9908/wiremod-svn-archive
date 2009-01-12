AddCSLuaFile('globalvars.lua')

/******************************************************************************\
  Global variable support v1.34
\******************************************************************************/


//--------------//
//--Strings--//
//--------------//

registerFunction("gSetStr", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
	T["xs"] = rv1
end)

registerFunction("gGetStr", "", "s", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
		if T["xs"]==nil then return "" end
	return T["xs"]
end)

registerFunction("gDeleteStr", "", "s", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
		if T["xs"]==nil then return "" end
	local value = T["xs"]
	T["xs"] = nil
	return value
end)

registerFunction("gSetStr", "ss", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self.data['globavars'],self.player)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
		if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
		if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end)

registerFunction("gSetStr", "ns", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = math.floor(op1[1](self, op1)), op2[1](self, op2)
	local T = glTid(self.data['globavars'],self.player)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = math.floor(op1[1](self, op1))
	local T = glTid(self.data['globavars'],self.player)
		if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = math.floor(op1[1](self, op1))
	local T = glTid(self.data['globavars'],self.player)
		if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end)

//-----------------//
//--Numbers--//
//-----------------//

registerFunction("gSetNum", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
	T["xn"] = rv1
end)

registerFunction("gGetNum", "", "n", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
		if T["xn"]==nil then return 0 end
	return T["xn"]
end)

registerFunction("gDeleteNum", "", "n", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
		if T["xn"]==nil then return 0 end
	local value = T["xn"]
	T["xn"] = nil
	return value
end)

registerFunction("gSetNum", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self.data['globavars'],self.player)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
		if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self.data['globavars'],self.player)
		if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

registerFunction("gSetNum", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = math.floor(op1[1](self, op1)), op2[1](self, op2)
	local T = glTid(self.data['globavars'],self.player)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = math.floor(op1[1](self, op1))
	local T = glTid(self.data['globavars'],self.player)
		if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = math.floor(op1[1](self, op1))
	local T = glTid(self.data['globavars'],self.player)
		if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

//-----------------//
//--Clean Up--//
//-----------------//

registerFunction("gDeleteAll", "", "", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
	T["xs"] = nil
	T["xn"] = nil
	T["s"] = nil
	T["s"] = {}
	T["n"] = nil
	T["n"] = {}
end)

registerFunction("gDeleteAllStr", "", "", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
	T["s"] = nil
	T["s"] = {}
	T["xs"] = nil
end)

registerFunction("gDeleteAllNum", "", "", function(self, args)
	local T = glTid(self.data['globavars'],self.player)
	T["n"] = nil
	T["n"] = {}
	T["xn"] = nil
end)

//------------------------------//
//--Group Commands--//
//------------------------------//

registerFunction("gSetGroup", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if !self.data then self.data = {} end
	self.data['globavars'] = "T"..rv1
	local group = self.data['globavars']
	if _G[self.player:UniqueID()][group]==nil then _G[self.player:UniqueID()][group] = {} end
	local T = _G[self.player:UniqueID()][group]
	if T["s"]==nil then T["s"] = {} end
	if T["n"]==nil then T["n"] = {} end
end)

registerFunction("gGetGroup", "", "s", function(self, args)
	if !self.data then self.data = {} end
	local group = self.data['globavars']
	if _G[self.player:UniqueID()][group]==nil then
		_G[self.player:UniqueID()]["Tdefault"] = {}
		local T = _G[self.player:UniqueID()]["Tdefault"]
		T["s"] = {}
		T["n"] = {}
		return "default"
	end
	return string.Right(group, string.len(group)-1)
end)

registerFunction("gResetGroup", "", "", function(self, args)
	if !self.data then self.data = {} end
	self.data['globavars'] = "Tdefault"
	local group = self.data['globavars']
	if !_G[self.player:UniqueID()][group] then _G[self.player:UniqueID()][group] = {} end
	local T = _G[self.player:UniqueID()][group]
	if !T["s"] then T["s"] = {} end
	if !T["n"] then T["n"] = {} end
end)

/******************************************************************************/

registerCallback("construct", function(self)
	self.data['globavars'] = "Tdefault"
end)

registerCallback("postexecute", function(self)
	self.data['globavars'] = "Tdefault"
end)

//--------------------------//
//--Client Functions--//
//--------------------------//

function glTid(group, ply)
	if !_G[ply:UniqueID()][group] then
		_G[ply:UniqueID()]["Tdefault"] = {}
		local T = _G[ply:UniqueID()]["Tdefault"]
		T["s"] = {}
		T["n"] = {}
		return T
	end
	return _G[ply:UniqueID()][group]
end

//-----------------------//
//--Server Hooks--//
//-----------------------//

if(SERVER) then
function Egateglobalvardisconnect( ply )
	local T = _G[ply:UniqueID()]
	for i=0, table.Count(T)  do
		table.remove(T,table.Count(T)-i)
	end
end
hook.Add( "PlayerDisconnected", "e2_globalvars_playerdisconnect", Egateglobalvardisconnect );

function Egateglobalvarconnect( ply )
	_G[ply:UniqueID()] = {}
end
hook.Add( "PlayerInitialSpawn", "e2_globalvars_playerconnect", Egateglobalvarconnect );
end
