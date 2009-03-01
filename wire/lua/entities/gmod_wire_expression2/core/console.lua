AddCSLuaFile('console.lua')

/******************************************************************************\
  Console support
\******************************************************************************/

if (CLIENT) then
	CreateClientConVar("wire_expression2_concmd", 1, true, true)
end

local function validConCmd(self)
	if(!self.player:IsValid()) then return false end
	return self.player:GetInfoNum("wire_expression2_concmd") != 0
end

/*registerFunction("trace", "s", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	self.player:Msg(rv1 .. "\n")
end)*/

registerFunction("concmd", "s", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validConCmd(self)) then return end
	self.player:ConCommand(rv1)
end)

registerFunction("convar", "s", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validConCmd(self)) then return end
	local ret = self.player:GetInfo(rv1) 
	if ret == nil then return "" end
	return ret
end)

registerFunction("convarnum", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validConCmd(self)) then return end
	local ret = self.player:GetInfoNum(rv1)
	if ret == nil then return 0 end
	return ret
end)