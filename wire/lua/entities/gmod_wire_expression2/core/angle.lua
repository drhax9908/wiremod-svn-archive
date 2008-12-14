/******************************************************************************\
Angle support
\******************************************************************************/

// wow... this is basically just vector-support, but renamed angle-support :P
// pitch, yaw, roll
registerType("angle", "a", { 0, 0, 0 },
	function(self, input) return { input.p, input.y, input.r } end,
	function(self, output) return Angle(output[1], output[2], output[3]) end
)

/******************************************************************************/

registerFunction("ang", "", "a", function(self, args)
	return { 0, 0, 0 }
end)

registerFunction("ang", "nnn", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1, rv2, rv3 }
end)

/******************************************************************************/

registerOperator("ass", "a", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	local ret = { rv2[1], rv2[2], rv2[3] }
	self.vars[op1] = ret
	self.vclk[op1] = true
	return ret
end)

/******************************************************************************/

registerOperator("is", "a", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] != 0 || rv1[2] != 0 || rv1[3] != 0
	   then return 1 else return 0 end
end)

registerOperator("eq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("geq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] <= delta &&
	   rv2[2] - rv1[2] <= delta &&
	   rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("leq", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta &&
	   rv1[2] - rv2[2] <= delta &&
	   rv1[3] - rv2[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("gth", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta &&
	   rv1[2] - rv2[2] > delta &&
	   rv1[3] - rv2[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("lth", "aa", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] > delta &&
	   rv2[2] - rv1[2] > delta &&
	   rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("neg", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end)

registerOperator("add", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end)

registerOperator("sub", "aa", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("mul", "na", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end)

registerOperator("mul", "an", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end)

registerOperator("div", "av", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end)

registerOperator("div", "va", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end)

/******************************************************************************/

// TODO:  How should it angnorm pitch? -180 to 180 or -90 to 90 like a gyroscope.
registerFunction("angnorm", "a", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {(rv1[1] + 180) % 360 - 180,(rv1[2] + 180) % 360 - 180,(rv1[3] + 180) % 360 - 180}
end)

registerFunction("angnorm", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1 + 180) % 360 - 180
end)

registerFunction("pitch", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("yaw", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("roll", "a:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

// SET methods that returns angles
registerFunction("setPitch", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[1] = rv2
	return rv1
end)

registerFunction("setYaw", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[2] = rv2
	return rv1
end)

registerFunction("setRoll", "a:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[3] = rv2
	return rv1
end)

/******************************************************************************/

registerFunction("toString", "a:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "," .. tostring(rv1[3]) .. "]"
end)

registerFunction("toVector", "a:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[1],rv1[2],rv1[3]}
end)
