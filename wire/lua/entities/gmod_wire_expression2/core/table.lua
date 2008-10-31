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
	function(self, output) return output end,
)

/******************************************************************************/

registerFunction("table", "", "t", function(self, args)
	return {}
end)

/******************************************************************************/

registerOperator("ass", "t", "t", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
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

registerFunction("clear", "t:", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	rv1 = {}
end)

registerFunction("count", "t:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return #rv1["n" .. rv2]
end)

/******************************************************************************/

registerFunction("setNumber", "t:sn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	rv1["n" .. rv2] = rv3
end)

registerFunction("getNumber", "t:s", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1["n" .. rv2]
end)

registerFunction("unsetNumber", "t:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	rv1["n" .. rv2] = nil
end)

registerFunction("issetNumber", "t:s", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv1["n" .. rv2] != nil
	   then return 1 else return 0 end
end)