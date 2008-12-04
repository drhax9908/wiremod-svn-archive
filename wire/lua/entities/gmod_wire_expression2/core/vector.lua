/******************************************************************************\
  Vector support
\******************************************************************************/

// TODO: add angles!
// TODO: add reflect?
// TODO: add rotate?
// TODO: add absdotproduct?
// TODO: add helper for angle and dotproduct? (just strange?)

/******************************************************************************/

registerType("vector", "v", { 0, 0, 0 },
	function(self, input) return { input.x, input.y, input.z } end,
	function(self, output) return Vector(output[1], output[2], output[3]) end
)

/******************************************************************************/

registerFunction("vec", "", "v", function(self, args)
	return { 0, 0, 0 }
end)

registerFunction("vec", "nnn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1, rv2, rv3 }
end)

/******************************************************************************/
// TODO: do we want it this way? right now we are never allowed to modify vectors
//       hence, A=B, modifying A will modify B, easy to fix, but "costly"

registerOperator("ass", "v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	local ret = { rv2[1], rv2[2], rv2[3] }
	self.vars[op1] = ret
	self.vclk[op1] = true
	return ret
end)

/******************************************************************************/

registerOperator("is", "v", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("geq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] <= delta &&
	   rv2[2] - rv1[2] <= delta &&
	   rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("leq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta &&
	   rv1[2] - rv2[2] <= delta &&
	   rv1[3] - rv2[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("gth", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta &&
	   rv1[2] - rv2[2] > delta &&
	   rv1[3] - rv2[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("lth", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2[1] - rv1[1] > delta &&
	   rv2[2] - rv1[2] > delta &&
	   rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("neg", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end)

registerOperator("add", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 + rv2[1], rv1 + rv2[2], rv1 + rv2[3] }
end)

registerOperator("add", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2, rv1[2] + rv2, rv1[3] + rv2 }
end)

registerOperator("add", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end)

registerOperator("sub", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 - rv2[1], rv1 - rv2[2], rv1 - rv2[3] }
end)

registerOperator("sub", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2, rv1[2] - rv2, rv1[3] - rv2 }
end)

registerOperator("sub", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("mul", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end)

registerOperator("mul", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end)

registerOperator("mul", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] }
end)

registerOperator("div", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end)

registerOperator("div", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end)

registerOperator("div", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3] }
end)

/******************************************************************************/
// TODO: should these functions round off to zero at DELTA?

registerFunction("length", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ (1 / 2)
end)

registerFunction("length2", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]
end)

registerFunction("distance", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return (rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3) ^ (1 / 2)
end)

registerFunction("distance2", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3
end)

registerFunction("normalized", "v:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ (1 / 2)
	if len > delta then return { rv1[1] / len, rv1[2] / len, rv1[3] / len }
	               else return { 0, 0, 0 } end
end)

// TODO: map these are EXP (dot) and MOD (cross) or something?
registerFunction("dot", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3]
end)

registerFunction("cross", "v:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[2] * rv2[3] - rv1[3] * rv2[2],
	         rv1[3] * rv2[1] - rv1[1] * rv2[3],
		     rv1[1] * rv2[2] - rv1[2] * rv2[1] }
end)

registerFunction("rotate", "v:a", "v", function(self, args)
    local op1, op2 = args[2], args[3]
    local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local v = Vector(rv1[1], rv1[2], rv1[3])
    v:Rotate(Angle(rv2[1], rv2[2], rv2[3]))
    return { v.x, v.y, v.z }
end)
 
registerFunction("rotate", "v:nnn", "v", function(self, args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op2[1](self, op3), op2[1](self, op4)
    local v = Vector(rv1[1], rv1[2], rv1[3])
    v:Rotate(Angle(rv2, rv3, rv4))
    return { v.x, v.y, v.z }
end)

/******************************************************************************/

// clamps the length of the vector, remember that the length will always be positive
registerFunction("clamp", "vnn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local length = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ (1 / 2)
	if length < rv2 then
		return {rv1[1]*rv2/length,rv1[2]*rv2/length,rv1[3]*rv2/length}
	elseif length > rv3 then
		return {rv1[1]*rv3/length,rv1[2]*rv3/length,rv1[3]*rv3/length}
	else return rv1 end
end)
/******************************************************************************/

registerFunction("x", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("z", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

// SET methods that returns vectors
registerFunction("setX", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[1] = rv2
	return rv1
end)

registerFunction("setY", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[2] = rv2
	return rv1
end)

registerFunction("setZ", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	rv1[3] = rv2
	return rv1
end)

/******************************************************************************/

registerFunction("toString", "v:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "," .. tostring(rv1[3]) .. "]"
end)
