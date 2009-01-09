AddCSLuaFile('array.lua')

/******************************************************************************\
  Array support
\******************************************************************************/

E2_MAX_ARRAY_SIZE = 1024*1024	// 1MB

/******************************************************************************/

registerType("array", "r", {},
	function(self, input)
		local ret = {}
		for k,v in ipairs(input) do ret[k] = v end
		return ret
	end,
	function(self, output) return output end
)

/******************************************************************************/

registerFunction("array", "", "r", function(self, args)
	return {}
end)

/******************************************************************************/

registerOperator("ass", "r", "r", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "r", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (type(rv1) == "table") and 1 or 0
end)

/******************************************************************************/

registerFunction("count", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return table.getn(rv1)
end)

/******************************************************************************/

registerFunction("clone", "r:", "r", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = {}
	for k,v in ipairs(rv1) do ret[k] = v end
	return ret
end)

/******************************************************************************/

registerFunction("number", "r:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tonumber(ret) end
	return 0
end)

registerFunction("setNumber", "r:nn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3 == 0 then rv3 = nil end
	rv1[rv2] = rv3
	//self.vclk[op1] = true
end)


registerFunction("vector", "r:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setVector", "r:nv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1[rv2] = rv3
	//self.vclk[op1] = true
end)


registerFunction("string", "r:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("setString", "r:ns", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	if rv3 == "" then rv3 = nil end
	rv1[rv2] = rv3
	//self.vclk[op1] = true
end)
