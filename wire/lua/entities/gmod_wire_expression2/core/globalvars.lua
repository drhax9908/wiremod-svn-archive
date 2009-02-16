AddCSLuaFile('globalvars.lua')

/******************************************************************************\
  Global variable support v1.4
\******************************************************************************/

//--------------------------//
//--Client Functions--//
//--------------------------//

local function glTid(self)
	local group = self.data['globavars']
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	if !_G[uid][group] then
		_G[uid][group] = {}
		local T = _G[uid][group]
		T["s"] = {}
		T["n"] = {}
		return T
	end
	return _G[uid][group]
end

//--------------//
//--Strings--//
//--------------//

registerFunction("gSetStr", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
	T["xs"] = rv1
end)

registerFunction("gGetStr", "", "s", function(self, args)
	local T = glTid(self)
		if T["xs"]==nil then return "" end
	return T["xs"]
end)

registerFunction("gDeleteStr", "", "s", function(self, args)
	local T = glTid(self)
		if T["xs"]==nil then return "" end
	local value = T["xs"]
	T["xs"] = nil
	return value
end)

registerFunction("gSetStr", "ss", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
		if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "s", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
		if T["s"][rv1]==nil then return "" end
	local value = T["s"][rv1]
	T["s"][rv1] = nil
	return value
end)

registerFunction("gSetStr", "ns", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["s"][rv1] = rv2
end)

registerFunction("gGetStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
		if T["s"][rv1]==nil then return "" end
	return T["s"][rv1]
end)

registerFunction("gDeleteStr", "n", "s", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
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
	local T = glTid(self)
	T["xn"] = rv1
end)

registerFunction("gGetNum", "", "n", function(self, args)
	local T = glTid(self)
		if T["xn"]==nil then return 0 end
	return T["xn"]
end)

registerFunction("gDeleteNum", "", "n", function(self, args)
	local T = glTid(self)
		if T["xn"]==nil then return 0 end
	local value = T["xn"]
	T["xn"] = nil
	return value
end)

registerFunction("gSetNum", "sn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local T = glTid(self)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
		if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "s", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local T = glTid(self)
		if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

registerFunction("gSetNum", "nn", "", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
	T["n"][rv1] = rv2
end)

registerFunction("gGetNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
		if T["n"][rv1]==nil then return 0 end
	return T["n"][rv1]
end)

registerFunction("gDeleteNum", "n", "n", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	rv1 = rv1 - rv1 % 1
	local T = glTid(self)
		if T["n"][rv1]==nil then return 0 end
	local value = T["n"][rv1]
	T["n"][rv1] = nil
	return value
end)

//-----------------//
//--Clean Up--//
//-----------------//

registerFunction("gDeleteAll", "", "", function(self, args)
	local group = self.data['globavars']
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	if _G[uid][group] then
		_G[uid][group] = nil
	end
end)

registerFunction("gDeleteAllStr", "", "", function(self, args)
	local T = glTid(self)
	T["s"] = nil
	T["s"] = {}
	T["xs"] = nil
end)

registerFunction("gDeleteAllNum", "", "", function(self, args)
	local T = glTid(self)
	T["n"] = nil
	T["n"] = {}
	T["xn"] = nil
end)

//---------------//
//--Sharing--//
//---------------//

registerFunction("gShare", "n", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	if rv1==0 then self.data['globashare'] = 0
	else self.data['globashare'] = 1 end
end)

//------------------------------//
//--Group Commands--//
//------------------------------//

registerFunction("gSetGroup", "s", "", function(self, args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	self.data['globavars'] = rv1
	local group = self.data['globavars']
	if _G[uid][group]==nil then _G[uid][group] = {} end
	local T = _G[uid][group]
	if T["s"]==nil then T["s"] = {} end
	if T["n"]==nil then T["n"] = {} end
end)

registerFunction("gGetGroup", "", "s", function(self, args)
	return self.data['globavars']
end)

registerFunction("gResetGroup", "", "", function(self, args)
	local uid = "exp2globalshare"
	if self.data['globashare']==0 then uid = self.data['globaply'] end
	self.data['globavars'] = "default"
	local group = self.data['globavars']
	if !_G[uid][group] then _G[uid][group] = {} end
	local T = _G[uid][group]
	if !T["s"] then T["s"] = {} end
	if !T["n"] then T["n"] = {} end
end)

/******************************************************************************/

registerCallback("construct", function(self)
	if self.data['globavars'] != "default" then
	self.data['globavars'] = "default"
	end
	self.data['globaply'] = self.player:UniqueID()
	self.data['globashare'] = 0
end)

registerCallback("postexecute", function(self)
	if self.data['globavars'] != "default" then
	self.data['globavars'] = "default"
	end
end)

//-----------------------//
//--Server Hooks--//
//-----------------------//

if(SERVER) then
_G["exp2globalshare"] = {}
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
