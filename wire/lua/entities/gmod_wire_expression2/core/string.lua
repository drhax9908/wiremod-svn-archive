AddCSLuaFile('string.lua')

/******************************************************************************\
  String support
\******************************************************************************/

// TODO: is string.left() faster than s:left()?
// TODO: is string.sub faster than both left and right?
// TODO: these return bad results when used with negative numbers!
// TODO: benchmarks!
// TODO: find?
// TODO: byte/char for conversion?
// TODO: sprintf-style function for quick composition of strings? or rely on + for that?
// TODO: conversions from number, vector etc to string
// TODO: tostring! (for all)
// TODO: replacing!

/******************************************************************************/

registerType("string", "s", "")

/******************************************************************************/

registerOperator("ass", "s", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 != ""
	   then return 1 else return 0 end
end)

registerOperator("eq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 == rv2 then return 1 else return 0 end
end)

registerOperator("neq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 != rv2 then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("add", "ss", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) .. op2[1](self, op2)
end)

registerOperator("add", "sn", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) .. tostring(op2[1](self, op2))
end)

registerOperator("add", "ns", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return tostring(op1[1](self, op1)) .. op2[1](self, op2)
end)

/******************************************************************************/

registerFunction("toNumber", "s:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = tonumber(rv1)
	if ret == nil then return 0 end
	return ret
end)

registerFunction("toString", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return tostring(rv1)
end)

registerFunction("toChar", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 < 32 then return "" end
	if rv1 > 255 then return "" end
	return string.char(rv1)
end)

registerFunction("toByte", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == "" then return -1 end
	return string.byte(rv1)
end)

registerFunction("toByte", "sn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2 < 1 || rv2 > string.len(rv1) then return -1 end
	return string.byte(rv1, rv2)
end)

/******************************************************************************/

registerFunction("index", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:sub(rv2, rv2)
end)

registerFunction("left", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:Left(rv2)
end)

registerFunction("right", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:Right(rv2)
end)

registerFunction("sub", "s:nn", "s", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return rv1:sub(rv2, rv3)
end)

registerFunction("upper", "s:", "s", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:upper()
end)

registerFunction("lower", "s:", "s", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:lower()
end)

registerFunction("length", "s:", "n", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:len()
end)

/******************************************************************************/

registerFunction("repeat", "s:n", "s", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
	return string.rep(rv1,rv2)
end)

registerFunction("trim", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.Trim(rv1)
end)

registerFunction("trimLeft", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local find = string.find(rv1," ")
	while find == 1 do
		rv1 = string.Right(rv1,rv1:len()-1)
		find = string.find(rv1," ")
	end
	return rv1
end)

registerFunction("trimRight", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.TrimRight(rv1)
end)

/******************************************************************************/

registerFunction("find", "s:s", "n", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    return string.find(rv1,rv2) or 0
end)

registerFunction("find", "s:sn", "n", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    return string.find(rv1,rv2,rv3) or 0
end)

registerFunction("replace", "s:ss", "s", function(self, args)
    local op1, op2, op3 = args[2], args[3], args[4]
    local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
    return string.Replace(rv1,rv2,rv3)
end)

registerFunction("explode", "s:s", "r", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    return string.Explode(rv2,rv1)
end)
