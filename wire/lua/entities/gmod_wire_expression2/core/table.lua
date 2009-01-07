AddCSLuaFile('table.lua')

/******************************************************************************\
  Table support
\******************************************************************************/

// should number not have suffix? for convenience
// copy?
// add/sub (kind of not the same thing?)
// shallow copy instead? or even do not copy by default? perhaps option on create?

/******************************************************************************/

registerType("table", "t", {},
	function(self, input)
		local ret = {}
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	function(self, output) return output end
)

/******************************************************************************/

registerFunction("table", "", "t", function(self, args)
	return {}
end)

/******************************************************************************/

registerOperator("ass", "t", "t", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "t", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if #rv1 != 0
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerFunction("count", "t:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return #rv1
end)

/******************************************************************************/

registerFunction("clone", "t:", "t", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = {}
	for k,v in pairs(rv1) do ret[k] = v end
	return ret
end)

/******************************************************************************/

registerFunction("number", "t:s", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1["n" .. rv2]
	if ret then return ret end
	return 0
end)

registerFunction("setNumber", "t:sn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv3 == 0 then rv3 = nil end
	rv1["n" .. rv2] = rv3
	//self.vclk[op1] = true
end)


registerFunction("vector", "t:s", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1["v" .. rv2]
	if ret then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setVector", "t:sv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1["v" .. rv2] = rv3
	//self.vclk[op1] = true
end)


registerFunction("string", "t:s", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1["s" .. rv2]
	if ret then return ret end
	return ""
end)

registerFunction("setString", "t:ss", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv3 == "" then rv3 = nil end
	rv1["s" .. rv2] = rv3
	//self.vclk[op1] = true
end)
