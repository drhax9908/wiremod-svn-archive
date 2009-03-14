AddCSLuaFile('number.lua')

/******************************************************************************\
  Numeric support
\******************************************************************************/

registerType("normal", "n", 0)

/******************************************************************************/

registerOperator("ass", "n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

registerOperator("inc", "n", "n", function(self, args)
	local op1 = args[2]
	self.vars[op1] = self.vars[op1] + 1
	self.vclk[op1] = true
end)

registerOperator("dec", "n", "n", function(self, args)
	local op1 = args[2]
	self.vars[op1] = self.vars[op1] - 1
	self.vclk[op1] = true
end)

/******************************************************************************/

registerOperator("eq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd <= delta && -rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd > delta || -rvd > delta
	   then return 1 else return 0 end
end)

registerOperator("geq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if -rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("leq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("gth", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd > delta
	   then return 1 else return 0 end
end)

registerOperator("lth", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if -rvd > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "n", "n", function(self, args)
	local op1 = args[2]
	return self.vars[op1] - self.vars["$" .. op1]
end)

registerOperator("neg", "n", "n", function(self, args)
	local op1 = args[2]
	return -op1[1](self, op1)
end)

registerOperator("add", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) + op2[1](self, op2)
end)

registerOperator("sub", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) - op2[1](self, op2)
end)

registerOperator("mul", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) * op2[1](self, op2)
end)

registerOperator("div", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) / op2[1](self, op2)
end)

registerOperator("exp", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) ^ op2[1](self, op2)
end)

registerOperator("mod", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) % op2[1](self, op2)
end)

/******************************************************************************/
// TODO: min, max, select, average
// TODO: is the shifting correct for rounding arbitrary decimals?
// TODO: ceil, floor etc does not adhere to DELTA, should they?

registerFunction("min", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 < rv2 then return rv1 else return rv2 end
end)

registerFunction("min", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local val
	if rv1 < rv2 then val = rv1 else val = rv2 end
	if rv3 < val then return rv3 else return val end
end)

registerFunction("min", "nnnn", "n", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local val
	if rv1 < rv2 then val = rv1 else val = rv2 end
	if rv3 < val then val = rv3 end
	if rv4 < val then return rv4 else return val end
end)

registerFunction("max", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 > rv2 then return rv1 else return rv2 end
end)

registerFunction("max", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local val
	if rv1 > rv2 then val = rv1 else val = rv2 end
	if rv3 > val then return rv3 else return val end
end)

registerFunction("max", "nnnn", "n", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local val
	if rv1 > rv2 then val = rv1 else val = rv2 end
	if rv3 > val then val = rv3 end
	if rv4 > val then return rv4 else return val end
end)

/******************************************************************************/

registerFunction("abs", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 >= 0 then return rv1 else return -rv1 end
end)

registerFunction("ceil", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 - rv1 % -1
end)

registerFunction("ceil", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	return rv1 - ((rv1 * shf) % -1) / shf
end)

registerFunction("floor", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 - rv1 % 1
end)

registerFunction("floor", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	return rv1 - ((rv1 * shf) % 1) / shf
end)

registerFunction("round", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 - (rv1 + 0.5) % 1 + 0.5
end)

registerFunction("round", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	return rv1 - ((rv1 * shf + 0.5) % 1 + 0.5) / shf
end)

registerFunction("int", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 >= 0 then return rv1 - rv1 % 1 else return rv1 - rv1 % -1 end
end)

registerFunction("frac", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 >= 0 then return rv1 % 1 else return rv1 % -1 end
end)

// TODO: what happens with negative modulo?
registerFunction("mod", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 >= 0 then return rv1 % rv2 else return rv1 % -rv2 end
end)

// TODO: change to a more suitable name? (cyclic modulo?)
//       add helpers for wrap90 wrap180, wrap90r wrap180r? or pointless?
//       wrap90(Pitch), wrap(Pitch, 90)
//       should be added...

registerFunction("wrap", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return (rv1 + rv2) % (rv2 * 2) - rv2
end)

registerFunction("clamp", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv1 < rv2 then return rv2 elseif rv1 > rv3 then return rv3 else return rv1 end
end)

registerFunction("sign", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 > delta then return 1
	elseif rv1 < -delta then return -1
	else return 0 end
end)

/******************************************************************************/

registerFunction("random", "", "n", function(self, args)
	return math.random()
end)

registerFunction("random", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.random() * rv1
end)

registerFunction("random", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1 + math.random() * (rv2 - rv1)
end)

registerFunction("randint", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.random(rv1)
end)

registerFunction("randint", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return math.random(rv1, rv2)
end)

/******************************************************************************/

registerFunction("sqrt", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 ^ (1 / 2)
end)

registerFunction("cbrt", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 ^ (1 / 3)
end)

registerFunction("root", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1 ^ (1 / rv2)
end)

// TODO: should it be called this?
registerFunction("e", "", "n", function(self, args)
	return math.exp(1)
end)

// TODO: should it be called this?
registerFunction("exp", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.exp(rv1)
end)

registerFunction("ln", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.log(rv1)
end)

registerFunction("log2", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.log(rv1) / math.log(2)
end)

registerFunction("log10", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.log10(rv1)
end)

registerFunction("log", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return math.log(rv1) / math.log(rv2)
end)

/******************************************************************************/

local deg2rad = math.pi / 180
local rad2deg = 180 / math.pi

// TODO: should it be called this?
registerFunction("pi", "", "n", function(self, args)
	return math.pi
end)

// TODO: should it be called this?
registerFunction("toRad", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 * deg2rad
end)

// TODO: should it be called this?
registerFunction("toDeg", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 * rad2deg
end)

registerFunction("acos", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.acos(rv1) * rad2deg
end)

registerFunction("asin", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.asin(rv1) * rad2deg
end)

registerFunction("atan", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.atan(rv1) * rad2deg
end)

registerFunction("atan", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return math.atan2(rv1, rv2) * rad2deg
end)

registerFunction("cos", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.cos(rv1 * deg2rad)
end)

registerFunction("sin", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.sin(rv1 * deg2rad)
end)

registerFunction("tan", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.tan(rv1 * deg2rad)
end)

registerFunction("cosh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.cosh(rv1 * deg2rad)
end)

registerFunction("sinh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.sinh(rv1 * deg2rad)
end)

registerFunction("tanh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.tanh(rv1 * deg2rad)
end)

registerFunction("acosr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.acos(rv1)
end)

registerFunction("asinr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.asin(rv1)
end)

registerFunction("atanr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.atan(rv1)
end)

registerFunction("atanr", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return math.atan2(rv1, rv2)
end)

registerFunction("cosr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.cos(rv1)
end)

registerFunction("sinr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.sin(rv1)
end)

registerFunction("tanr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.tan(rv1)
end)

registerFunction("coshr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.cosh(rv1)
end)

registerFunction("sinhr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.sinh(rv1)
end)

registerFunction("tanhr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return math.tanh(rv1)
end)
